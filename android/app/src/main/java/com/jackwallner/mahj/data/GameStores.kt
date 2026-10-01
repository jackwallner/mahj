package com.jackwallner.mahj.data

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.jackwallner.mahj.content.MahjContent
import com.jackwallner.mahj.content.MahjMinuteCategory
import com.jackwallner.mahj.content.MahjMinuteChallenge
import com.jackwallner.mahj.content.MahjMinuteContent
import com.jackwallner.mahj.content.WhatsNewRelease
import com.jackwallner.mahj.model.HandCategory
import com.jackwallner.mahj.model.Tile
import java.time.Instant
import java.time.LocalDate
import java.time.temporal.WeekFields
import java.util.Locale
import org.json.JSONArray
import org.json.JSONObject

data class MahjMinuteResult(
    val dayKey: String,
    val shortDate: String,
    val completedAt: Long,
    val answers: List<Boolean>,
    val correctByCategory: Map<String, Int>,
    val totalByCategory: Map<String, Int>,
) {
    val score: Int get() = answers.count { it }
    val total: Int get() = answers.size

    fun correct(category: MahjMinuteCategory) = correctByCategory[category.raw] ?: 0
    fun total(category: MahjMinuteCategory) = totalByCategory[category.raw] ?: 0

    val shareText: String
        get() {
            val grid = answers.joinToString("") { if (it) "🟩" else "⬜️" }
            return "Mahj Minute $shortDate: $score/$total\n$grid\nCan you beat me? ${StoreLinks.PLAY_LISTING_URL}"
        }

    fun toJson(): JSONObject = JSONObject().apply {
        put("dayKey", dayKey)
        put("shortDate", shortDate)
        put("completedAt", completedAt)
        put("answers", JSONArray(answers))
        put("correctByCategory", JSONObject(correctByCategory as Map<*, *>))
        put("totalByCategory", JSONObject(totalByCategory as Map<*, *>))
    }

    companion object {
        fun fromJson(json: JSONObject): MahjMinuteResult {
            val answers = json.getJSONArray("answers")
            fun counts(key: String): Map<String, Int> {
                val obj = json.getJSONObject(key)
                return obj.keys().asSequence().associateWith { obj.getInt(it) }
            }
            return MahjMinuteResult(
                dayKey = json.getString("dayKey"),
                shortDate = json.getString("shortDate"),
                completedAt = json.getLong("completedAt"),
                answers = (0 until answers.length()).map { answers.getBoolean(it) },
                correctByCategory = counts("correctByCategory"),
                totalByCategory = counts("totalByCategory"),
            )
        }
    }
}

class MahjMinuteStore(private val defaults: KeyValueStore, private val clock: AppClock) {
    var results by mutableStateOf(load())
        private set

    fun result(day: LocalDate): MahjMinuteResult? = results[MahjMinuteContent.key(day)]

    /** Only the first attempt on a day counts. */
    fun record(challenge: MahjMinuteChallenge, answers: List<Boolean>): MahjMinuteResult {
        results[challenge.dayKey]?.let { return it }
        val correct = mutableMapOf<String, Int>()
        val total = mutableMapOf<String, Int>()
        challenge.questions.zip(answers).forEach { (question, right) ->
            total[question.category.raw] = (total[question.category.raw] ?: 0) + 1
            if (right) correct[question.category.raw] = (correct[question.category.raw] ?: 0) + 1
        }
        val result = MahjMinuteResult(challenge.dayKey, challenge.shortDate, clock.millis(), answers, correct, total)
        results = results + (challenge.dayKey to result)
        persist()
        return result
    }

    fun completedThisWeek(): Int {
        val fields = WeekFields.of(Locale.getDefault())
        val today = clock.today()
        val start = today.with(fields.dayOfWeek(), 1)
        val end = start.plusDays(7)
        return results.values.count {
            val day = Instant.ofEpochMilli(it.completedAt).atZone(clock.zone).toLocalDate()
            !day.isBefore(start) && day.isBefore(end)
        }
    }

    fun archiveDates(count: Int = 30): List<LocalDate> = (1..count).map { clock.today().minusDays(it.toLong()) }

    fun resetAll() {
        results = emptyMap()
        defaults.remove(KEY)
    }

    private fun persist() {
        val json = JSONObject()
        results.forEach { (key, value) -> json.put(key, value.toJson()) }
        defaults.putString(KEY, json.toString())
    }

    private fun load(): Map<String, MahjMinuteResult> {
        val raw = defaults.getString(KEY) ?: return emptyMap()
        val json = runCatching { JSONObject(raw) }.getOrNull() ?: return emptyMap()
        return json.keys().asSequence().associateWith { MahjMinuteResult.fromJson(json.getJSONObject(it)) }
    }

    private companion object {
        const val KEY = "mahjMinute.results"
    }
}

/** Play a Hand's local state: hands played, best verdict, the one free hand a day, and a saved hand. */
class HandPlayStore(private val defaults: KeyValueStore, private val clock: AppClock) {
    data class ThrowGrade(val discard: Tile, val wasBest: Boolean, val note: String)

    data class InProgressHand(
        val rack: List<Tile>,
        val wall: List<Tile>,
        val wallIndex: Int,
        val target: HandCategory,
        val turn: Int,
        val cleanDiscards: Int,
        val drawn: Tile?,
        /** Set only while a graded throw waits for Next turn. */
        val grade: ThrowGrade?,
    ) {
        fun toJson(): JSONObject = JSONObject().apply {
            put("rack", JSONArray(rack.map { it.shortLabel }))
            put("wall", JSONArray(wall.map { it.shortLabel }))
            put("wallIndex", wallIndex)
            put("target", target.raw)
            put("turn", turn)
            put("cleanDiscards", cleanDiscards)
            drawn?.let { put("drawn", it.shortLabel) }
            grade?.let {
                put("grade", JSONObject().put("discard", it.discard.shortLabel).put("wasBest", it.wasBest).put("note", it.note))
            }
        }

        companion object {
            fun fromJson(json: JSONObject): InProgressHand {
                fun tiles(key: String) = json.getJSONArray(key).let { list -> (0 until list.length()).map { Tile.fromCode(list.getString(it)) } }
                return InProgressHand(
                    rack = tiles("rack"),
                    wall = tiles("wall"),
                    wallIndex = json.getInt("wallIndex"),
                    target = HandCategory.fromRaw(json.getString("target")),
                    turn = json.getInt("turn"),
                    cleanDiscards = json.getInt("cleanDiscards"),
                    drawn = if (json.has("drawn")) Tile.fromCode(json.getString("drawn")) else null,
                    grade = json.optJSONObject("grade")?.let {
                        ThrowGrade(Tile.fromCode(it.getString("discard")), it.getBoolean("wasBest"), it.getString("note"))
                    },
                )
            }
        }
    }

    var handsPlayed by mutableStateOf(defaults.getInt(Keys.HANDS_PLAYED))
        private set
    var bestStars by mutableStateOf(defaults.getInt(Keys.BEST_STARS))
        private set
    var lastFreeHandDay by mutableStateOf(defaults.getString(Keys.LAST_FREE_DAY) ?: "")
        private set
    var inProgress by mutableStateOf(
        defaults.getString(Keys.IN_PROGRESS)?.let { raw -> runCatching { InProgressHand.fromJson(JSONObject(raw)) }.getOrNull() },
    )
        private set

    private fun dayKey() = MahjMinuteContent.key(clock.today())

    /** A hand already started is always playable; otherwise members always, free players once a day. */
    fun canPlay(isMember: Boolean): Boolean = inProgress != null || isMember || lastFreeHandDay != dayKey()

    /** Called when a hand actually starts, not when the screen opens. */
    fun recordStart(isMember: Boolean) {
        handsPlayed += 1
        defaults.putInt(Keys.HANDS_PLAYED, handsPlayed)
        if (isMember) return
        lastFreeHandDay = dayKey()
        defaults.putString(Keys.LAST_FREE_DAY, lastFreeHandDay)
    }

    fun saveInProgress(hand: InProgressHand) {
        inProgress = hand
        defaults.putString(Keys.IN_PROGRESS, hand.toJson().toString())
    }

    fun clearInProgress() {
        inProgress = null
        defaults.remove(Keys.IN_PROGRESS)
    }

    fun recordVerdict(stars: Int) {
        if (stars <= bestStars) return
        bestStars = stars
        defaults.putInt(Keys.BEST_STARS, stars)
    }

    fun resetAll() {
        handsPlayed = 0
        bestStars = 0
        lastFreeHandDay = ""
        clearInProgress()
        defaults.remove(Keys.HANDS_PLAYED)
        defaults.remove(Keys.BEST_STARS)
        defaults.remove(Keys.LAST_FREE_DAY)
    }

    private object Keys {
        const val HANDS_PLAYED = "handplay.handsPlayed"
        const val BEST_STARS = "handplay.bestStars"
        const val LAST_FREE_DAY = "handplay.lastFreeDay"
        const val IN_PROGRESS = "handplay.inProgress"
    }
}

/**
 * The post-update notes, once. A fresh install never sees them: onboarding
 * marks the running version as the baseline.
 */
class WhatsNewTracker(private val defaults: KeyValueStore, val currentVersion: String) {
    val currentRelease: WhatsNewRelease?
        get() = MahjContent.library.whatsNew.firstOrNull { it.version == currentVersion }

    fun shouldPresent(hasOnboarded: Boolean): Boolean {
        if (!hasOnboarded || currentRelease == null) return false
        return (defaults.getString(KEY) ?: "") != currentVersion
    }

    fun markSeen() = defaults.putString(KEY, currentVersion)

    fun markCurrentAsBaseline() = defaults.putString(KEY, currentVersion)

    private companion object {
        const val KEY = "whatsnew.lastSeenVersion"
    }
}
