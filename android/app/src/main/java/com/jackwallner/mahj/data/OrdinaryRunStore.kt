package com.jackwallner.mahj.data

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
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
    var inProgress by mutableStateOf(defaults.getString(KEY)?.let { runCatching { OrdinaryRun.fromJson(JSONObject(it)) }.getOrNull() })
        private set

    fun run(id: String): OrdinaryRun? = inProgress?.takeIf { it.id == id }

    fun save(run: OrdinaryRun) {
        if (run == inProgress) return
        if (run.drill.kind.itemCount == 0 && run.items.isEmpty()) return
        defaults.putString(KEY, run.toJson().toString())
        inProgress = run
    }

    fun clear(id: String) {
        if (inProgress?.id != id) return
        defaults.remove(KEY)
        inProgress = null
    }

    companion object {
        const val KEY = "practice.ordinaryRun"
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
