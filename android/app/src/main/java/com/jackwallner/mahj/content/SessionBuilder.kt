package com.jackwallner.mahj.content

import com.jackwallner.mahj.model.ChoiceShuffle
import com.jackwallner.mahj.model.Drill
import com.jackwallner.mahj.model.DrillKind
import com.jackwallner.mahj.model.HandCategory
import com.jackwallner.mahj.model.Tile
import com.jackwallner.mahj.model.racked

/**
 * One normalized, single-select item inside a session, built from whichever
 * choice-gradeable content is behind it.
 */
data class QuickItem(
    val id: String,
    val prompt: String,
    val tiles: List<Tile>,
    val choices: List<String>,
    val answerIndex: Int,
    val explanation: String,
    /** e.g. "The Tile Room", shown as a small tag above the prompt. */
    val sourceLabel: String,
    val roomID: String,
    /** The persistence row this answer contributes to. */
    val trackingID: String = id,
    /** False for one-off generated prompts that can never come back in review. */
    val isReviewable: Boolean = true,
    /** Parallel to `choices`: why that answer is wrong, shown only when picked. */
    val choiceNotes: List<String?> = emptyList(),
) {
    /** Padded so a caller can never index past the end of a short list. */
    val paddedNotes: List<String?>
        get() = if (choiceNotes.size == choices.size) choiceNotes
        else choices.indices.map { choiceNotes.getOrNull(it) }

    fun note(forPick: Int): String? = paddedNotes.getOrNull(forPick)?.takeIf { it.isNotEmpty() }
}

/**
 * Builds the choice sessions: missed items first, unseen next, review last.
 * Plain flip cards and Charleston scenarios stay out; they are not right or
 * wrong in one tap.
 */
object SessionBuilder {
    val sessionDrill = Drill("quick-session", "Quick Session", "A short mix of what you need next", DrillKind.Flashcards(emptyList()))
    val reviewDrill = Drill("review-session", "Fix My Mistakes", "The questions you keep getting wrong", DrillKind.Flashcards(emptyList()))
    val gameNightPrepDrill = Drill("game-night-prep", "Game Night Prep", "A five-minute mix for your next table", DrillKind.Flashcards(emptyList()))

    fun quickSession(count: Int = 10, seen: Set<String>, missed: Set<String>, includePro: Boolean): List<QuickItem> {
        fun tier(item: QuickItem) = when {
            item.id in missed -> 0
            item.id !in seen -> 1
            else -> 2
        }
        return choicePool(includePro).shuffled().sortedBy(::tier).take(count).map(::prepared)
    }

    /** Exactly the items the scheduler says are due, in its order. Never padded. */
    fun reviewSession(ids: List<String>, includePro: Boolean): List<QuickItem> {
        val pool = choicePool(includePro).associateBy { it.id }
        return ids.mapNotNull { pool[it] }.map(::prepared)
    }

    /** The ids Fix My Mistakes can actually put on screen. */
    fun reviewableIDs(includePro: Boolean): Set<String> = if (includePro) memberReviewable else freeReviewable

    private val freeReviewable by lazy { choicePool(false).map { it.id }.toSet() }
    private val memberReviewable by lazy { choicePool(true).map { it.id }.toSet() }

    /** Due mistakes lead, then misses, then the weakest room, then unseen material. */
    fun gameNightPrep(
        count: Int = 10,
        seen: Set<String>,
        missed: Set<String>,
        dueIDs: List<String>,
        weakestRoomID: String?,
    ): List<QuickItem> {
        val due = dueIDs.toSet()
        fun tier(item: QuickItem) = when {
            item.id in due -> 0
            item.id in missed -> 1
            item.roomID == weakestRoomID -> 2
            item.id !in seen -> 3
            else -> 4
        }
        return choicePool(true).shuffled().sortedBy(::tier).take(count).map(::prepared)
    }

    fun choiceItems(roomID: String, includePro: Boolean): List<QuickItem> =
        choicePool(includePro).filter { it.roomID == roomID }

    /** Answer-position variety, stable per item id. Notes ride the same permutation. */
    fun prepared(item: QuickItem): QuickItem {
        val permutation = ChoiceShuffle.permutation(item.choices.size, item.id)
        val labels = permutation.map { item.choices[it] }
        val answer = permutation.indexOf(item.answerIndex).takeIf { it >= 0 } ?: item.answerIndex
        val notes = permutation.map { item.choiceNotes.getOrNull(it) }
        return item.copy(choices = labels, answerIndex = answer, choiceNotes = notes)
    }

    private fun choicePool(includePro: Boolean): List<QuickItem> {
        val pool = mutableListOf<QuickItem>()
        for (room in DrillLibrary.rooms) {
            if (!room.isFree && !includePro) continue
            for (drill in room.drills) {
                if (room.isLocked(drill, includePro)) continue
                when (val kind = drill.kind) {
                    is DrillKind.Quiz -> pool += kind.questions.map { question ->
                        QuickItem(
                            id = question.id,
                            prompt = question.prompt,
                            tiles = question.tiles,
                            choices = question.choices,
                            answerIndex = question.answerIndex,
                            explanation = question.explanation,
                            sourceLabel = room.name,
                            roomID = room.id,
                        )
                    }
                    is DrillKind.HandMatch -> pool += kind.questions.map { question ->
                        QuickItem(
                            id = question.id,
                            prompt = "Which section is this rack chasing?",
                            tiles = question.tiles.racked,
                            choices = question.choices.map { it.displayName },
                            answerIndex = question.choices.indexOf(question.answer).coerceAtLeast(0),
                            explanation = question.explanation,
                            sourceLabel = room.name,
                            roomID = room.id,
                            choiceNotes = HandCategory.missNotes(question.choices, question.answer),
                        )
                    }
                    is DrillKind.Flashcards -> pool += kind.cards.mapNotNull { card ->
                        val choice = card.choice ?: return@mapNotNull null
                        QuickItem(
                            id = card.id,
                            prompt = card.frontSubtitle?.let { "${card.frontTitle}\n$it" } ?: card.frontTitle,
                            tiles = card.frontTiles,
                            choices = choice.options,
                            answerIndex = choice.answerIndex,
                            explanation = card.backBody,
                            sourceLabel = room.name,
                            roomID = room.id,
                        )
                    }
                    is DrillKind.Charleston -> Unit
                }
            }
        }
        return pool
    }
}
