package com.jackwallner.mahj.data

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.jackwallner.mahj.content.DrillLibrary
import com.jackwallner.mahj.content.MahjContent
import com.jackwallner.mahj.content.QuickItem
import com.jackwallner.mahj.content.SessionBuilder
import com.jackwallner.mahj.content.objects
import com.jackwallner.mahj.content.strings
import com.jackwallner.mahj.content.tiles
import com.jackwallner.mahj.model.Drill
import com.jackwallner.mahj.model.DrillKind
import org.json.JSONArray
import org.json.JSONObject

/** One ordinary run, including the held answer, saved at each interaction boundary. */
data class OrdinaryRun(
    val drill: Drill,
    val items: List<QuickItem> = emptyList(),
    val index: Int = 0,
    val score: Int = 0,
    val selection: Int? = null,
    val answers: List<Boolean> = emptyList(),
    val selected: List<Int> = emptyList(),
    val submitted: Boolean = false,
    val queue: List<String> = emptyList(),
    val flipped: Boolean = false,
    val pendingAnswer: AnswerSnapshot? = null,
    val undoCardID: String? = null,
    val undoGotIt: Boolean = false,
    val undoAnswer: AnswerSnapshot? = null,
) {
    data class AnswerSnapshot(val progress: ProgressStore.ItemSnapshot, val practice: PracticeRecordStore.AnswerSnapshot) {
        fun toJson(): JSONObject = JSONObject().apply {
            put("id", progress.id)
            put("seen", progress.seen)
            put("missed", progress.missed)
            put("itemID", practice.itemID)
            practice.record?.let { put("record", it.toJson()) }
        }

        companion object {
            fun fromJson(json: JSONObject) = AnswerSnapshot(
                ProgressStore.ItemSnapshot(json.getString("id"), json.getBoolean("seen"), json.getBoolean("missed")),
                PracticeRecordStore.AnswerSnapshot(json.getString("itemID"), json.optJSONObject("record")?.let(PracticeRecord::fromJson)),
            )
        }
    }

    val id: String get() = drill.id
    val isQuickSession: Boolean get() = id == SessionBuilder.sessionDrill.id
    val hasAnswers: Boolean get() = answers.isNotEmpty()

    /**
     * A lapsed member keeps the run on disk but never replays it: a room drill locks through
     * `Room.isLocked`, a Get Started on the Mahj+ questions it was built with.
     */
    fun isLocked(isMember: Boolean): Boolean {
        if (isMember) return false
        if (isQuickSession) return items.any { SessionBuilder.isMemberOnly(it.id) }
        val room = DrillLibrary.room(DrillLibrary.roomID(id)) ?: return false
        return room.isLocked(drill, isMember)
    }

    fun toJson(): JSONObject = JSONObject().apply {
        put("drill", drill.toJson())
        put("items", JSONArray(items.map { item ->
            JSONObject().apply {
                put("id", item.id)
                put("prompt", item.prompt)
                put("tiles", JSONArray(item.tiles.map { it.shortLabel }))
                put("choices", JSONArray(item.choices))
                put("answerIndex", item.answerIndex)
                put("explanation", item.explanation)
                put("sourceLabel", item.sourceLabel)
                put("roomID", item.roomID)
                put("trackingID", item.trackingID)
                put("isReviewable", item.isReviewable)
                put("choiceNotes", JSONArray(item.paddedNotes))
            }
        }))
        put("index", index)
        put("score", score)
        selection?.let { put("selection", it) }
        put("answers", JSONArray(answers))
        put("selected", JSONArray(selected))
        put("submitted", submitted)
        put("queue", JSONArray(queue))
        put("flipped", flipped)
        pendingAnswer?.let { put("pendingAnswer", it.toJson()) }
        undoCardID?.let { put("undoCardID", it) }
        put("undoGotIt", undoGotIt)
        undoAnswer?.let { put("undoAnswer", it.toJson()) }
    }

    companion object {
        fun fromJson(json: JSONObject): OrdinaryRun = OrdinaryRun(
            drill = MahjContent.drill(json.getJSONObject("drill")),
            items = json.getJSONArray("items").objects().map { item ->
                val notes = item.getJSONArray("choiceNotes")
                QuickItem(item.getString("id"), item.getString("prompt"), item.getJSONArray("tiles").tiles(),
                    item.getJSONArray("choices").strings(), item.getInt("answerIndex"), item.getString("explanation"),
                    item.getString("sourceLabel"), item.getString("roomID"), item.getString("trackingID"),
                    item.getBoolean("isReviewable"), (0 until notes.length()).map { if (notes.isNull(it)) null else notes.getString(it) })
            },
            index = json.getInt("index"), score = json.getInt("score"),
            selection = if (json.has("selection")) json.getInt("selection") else null,
            answers = json.getJSONArray("answers").let { list -> (0 until list.length()).map { list.getBoolean(it) } },
            selected = json.getJSONArray("selected").let { list -> (0 until list.length()).map { list.getInt(it) } },
            submitted = json.getBoolean("submitted"), queue = json.getJSONArray("queue").strings(), flipped = json.getBoolean("flipped"),
            pendingAnswer = json.optJSONObject("pendingAnswer")?.let(AnswerSnapshot::fromJson),
            undoCardID = if (json.has("undoCardID")) json.getString("undoCardID") else null,
            undoGotIt = json.optBoolean("undoGotIt"), undoAnswer = json.optJSONObject("undoAnswer")?.let(AnswerSnapshot::fromJson),
        )
    }
}

class OrdinaryRunStore(private val defaults: KeyValueStore) {
    /** Every run with answers, one per drill id, the most recently answered last. */
    var runs by mutableStateOf(load())
        private set

    /** The most recently answered run. */
    val inProgress: OrdinaryRun? get() = runs.lastOrNull()

    fun run(id: String): OrdinaryRun? = runs.firstOrNull { it.id == id }

    /**
     * Each drill keeps its own run, so answering in one never drops the place in another (a Tile
     * Check answer wiped a half-done Get Started). An unanswered run never takes a slot, and the
     * same run undone back to nothing drops out.
     */
    fun save(run: OrdinaryRun) {
        if (run.drill.kind.itemCount == 0 && run.items.isEmpty()) return
        if (!run.hasAnswers) return clear(run.id)
        if (run(run.id) == run) return
        persist(runs.filter { it.id != run.id } + run)
    }

    /** Home's Resume choices, most recent first, leaving out runs locked to this player. */
    fun resumable(isMember: Boolean): List<OrdinaryRun> =
        runs.asReversed().filter { it.hasAnswers && !it.isLocked(isMember) }

    /** The run behind Home's Resume card: the latest room drill. A saved Get Started resumes from its own card. */
    fun resumableRoomRun(isMember: Boolean): OrdinaryRun? = resumable(isMember).firstOrNull { !it.isQuickSession }

    fun hasResumableQuickSession(isMember: Boolean): Boolean = resumable(isMember).any { it.isQuickSession }

    fun clear(id: String) {
        if (runs.none { it.id == id }) return
        persist(runs.filter { it.id != id })
    }

    fun clearAll() = persist(emptyList())

    private fun persist(updated: List<OrdinaryRun>) {
        if (updated.isEmpty()) defaults.remove(RUNS_KEY)
        else defaults.putString(RUNS_KEY, JSONArray(updated.map { it.toJson() }).toString())
        defaults.remove(KEY)
        runs = updated
    }

    private fun load(): List<OrdinaryRun> {
        defaults.getString(RUNS_KEY)?.let { raw ->
            val list = runCatching { JSONArray(raw) }.getOrNull() ?: return emptyList()
            // One damaged run must not cost the others.
            return (0 until list.length())
                .mapNotNull { runCatching { OrdinaryRun.fromJson(list.getJSONObject(it)) }.getOrNull() }
                .filter { it.hasAnswers }
        }
        val legacy = defaults.getString(KEY)?.let { runCatching { OrdinaryRun.fromJson(JSONObject(it)) }.getOrNull() }
        return listOfNotNull(legacy?.takeIf { it.hasAnswers })
    }

    companion object {
        /** The single-slot key of 1.4.x. Still read once, so a run saved before the update survives it. */
        const val KEY = "practice.ordinaryRun"

        /** One saved run per drill, oldest first. */
        const val RUNS_KEY = "practice.ordinaryRuns"
    }
}

private fun Drill.toJson(): JSONObject {
    val entries: List<JSONObject>
    val name: String
    when (val content = kind) {
        is DrillKind.Flashcards -> {
            name = "flashcards"
            entries = content.cards.map { card -> JSONObject().apply {
                put("id", card.id)
                put("frontTitle", card.frontTitle)
                put("frontTiles", JSONArray(card.frontTiles.map { it.shortLabel }))
                put("frontSubtitle", card.frontSubtitle)
                put("backTitle", card.backTitle)
                put("backBody", card.backBody)
                card.choice?.let { put("choice", JSONObject().put("options", JSONArray(it.options)).put("answerIndex", it.answerIndex)) }
            } }
        }
        is DrillKind.Quiz -> {
            name = "quiz"
            entries = content.questions.map { question -> JSONObject().apply {
                put("id", question.id)
                put("prompt", question.prompt)
                put("tiles", JSONArray(question.tiles.map { it.shortLabel }))
                put("choices", JSONArray(question.choices))
                put("answerIndex", question.answerIndex)
                put("explanation", question.explanation)
            } }
        }
        is DrillKind.HandMatch -> {
            name = "handMatch"
            entries = content.questions.map { question -> JSONObject().apply {
                put("id", question.id)
                put("tiles", JSONArray(question.tiles.map { it.shortLabel }))
                put("choices", JSONArray(question.choices.map { it.raw }))
                put("answer", question.answer.raw)
                put("explanation", question.explanation)
            } }
        }
        is DrillKind.Charleston -> {
            name = "charleston"
            entries = content.scenarios.map { scenario -> JSONObject().apply {
                put("id", scenario.id)
                put("situation", scenario.situation)
                put("deal", JSONArray(scenario.deal.map { it.shortLabel }))
                put("recommendedPass", JSONArray(scenario.recommendedPass.map { it.shortLabel }))
                put("reasoning", scenario.reasoning)
                put("tip", scenario.tip)
            } }
        }
    }
    return JSONObject().put("id", id).put("title", title).put("subtitle", subtitle).put("isPlus", isPlus)
        .put("kind", name).put("items", JSONArray(entries))
}
