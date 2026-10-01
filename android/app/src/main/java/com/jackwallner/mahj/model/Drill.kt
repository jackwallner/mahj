package com.jackwallner.mahj.model

import com.jackwallner.mahj.content.MahjContent

/**
 * The stable category families that appear on the NMJL card year after year.
 * Their copy lives in the exported content so it cannot drift from iOS.
 */
enum class HandCategory(val raw: String) {
    YEAR("year"),
    EVENS_2468("evens2468"),
    LIKE_NUMBERS("likeNumbers"),
    QUINTS("quints"),
    CONSECUTIVE_RUN("consecutiveRun"),
    ODDS_13579("odds13579"),
    WINDS_DRAGONS("windsDragons"),
    THREE_SIX_NINE("threeSixNine"),
    SINGLES_AND_PAIRS("singlesAndPairs");

    val displayName: String get() = MahjContent.library.categoryText.getValue(this).displayName
    val shortName: String get() = MahjContent.library.categoryText.getValue(this).shortName
    val howToSpot: String get() = MahjContent.library.categoryText.getValue(this).howToSpot

    /** The one thing this section demands, used to explain a wrong pick. */
    val requires: String get() = MahjContent.library.categoryText.getValue(this).requires

    companion object {
        fun fromRaw(raw: String): HandCategory = entries.first { it.raw == raw }

        /** Nothing for the right answer; for every wrong one, what that section would have needed. */
        fun missNotes(choices: List<HandCategory>, answer: HandCategory): List<String?> =
            choices.map { if (it == answer) null else "${it.displayName}: ${it.requires}." }
    }
}

data class CategoryText(val displayName: String, val shortName: String, val howToSpot: String, val requires: String)

/** A two-option self-test on a card's front ("Keep" / "Throw"). */
data class CardChoice(val options: List<String>, val answerIndex: Int)

data class Flashcard(
    val id: String,
    val frontTitle: String,
    val frontTiles: List<Tile> = emptyList(),
    val frontSubtitle: String? = null,
    val backTitle: String,
    val backBody: String,
    val choice: CardChoice? = null,
)

data class QuizQuestion(
    val id: String,
    val prompt: String,
    val tiles: List<Tile> = emptyList(),
    val choices: List<String>,
    val answerIndex: Int,
    val explanation: String,
)

data class HandMatchQuestion(
    val id: String,
    val tiles: List<Tile>,
    val choices: List<HandCategory>,
    val answer: HandCategory,
    val explanation: String,
)

data class CharlestonScenario(
    val id: String,
    val situation: String,
    val deal: List<Tile>,
    val recommendedPass: List<Tile>,
    val reasoning: String,
    val tip: String,
)

sealed interface DrillKind {
    data class Flashcards(val cards: List<Flashcard>) : DrillKind
    data class Quiz(val questions: List<QuizQuestion>) : DrillKind
    data class HandMatch(val questions: List<HandMatchQuestion>) : DrillKind
    data class Charleston(val scenarios: List<CharlestonScenario>) : DrillKind

    val itemCount: Int
        get() = when (this) {
            is Flashcards -> cards.size
            is Quiz -> questions.size
            is HandMatch -> questions.size
            is Charleston -> scenarios.size
        }

    val unitName: String
        get() = when (this) {
            is Flashcards -> "cards"
            is Quiz -> "questions"
            is HandMatch -> "racks"
            is Charleston -> "deals"
        }
}

data class Drill(
    val id: String,
    val title: String,
    val subtitle: String,
    val kind: DrillKind,
    /** Extra practice sets inside an otherwise free room, locked behind Mahj+. */
    val isPlus: Boolean = false,
)

data class Room(
    val id: String,
    val name: String,
    val tagline: String,
    val icon: String,
    /** A free room opens for everyone; its `isPlus` drills are the locked extras. */
    val isFree: Boolean,
    val drills: List<Drill>,
) {
    /** Drills a member unlocks here: the whole room if it is paid, otherwise the extra sets. */
    val plusDrillCount: Int get() = if (isFree) drills.count { it.isPlus } else drills.size

    fun isLocked(drill: Drill, isMember: Boolean): Boolean = !isMember && (!isFree || drill.isPlus)
}
