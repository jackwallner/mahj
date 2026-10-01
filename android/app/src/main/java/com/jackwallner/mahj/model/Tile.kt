package com.jackwallner.mahj.model

// Case order matches the iOS `allCases` order. The seeded generators walk
// these lists, so reordering a case changes every shared daily challenge.

enum class Suit(val raw: String, val displayName: String) {
    CRAK("crak", "Crak"),
    BAM("bam", "Bam"),
    DOT("dot", "Dot"),
}

enum class Wind(val raw: String) {
    NORTH("north"),
    EAST("east"),
    WEST("west"),
    SOUTH("south");

    val letter: String get() = raw.take(1).uppercase()
    val displayName: String get() = raw.replaceFirstChar { it.uppercase() }
}

enum class Dragon(val raw: String, val displayName: String) {
    RED("red", "Red Dragon"),
    GREEN("green", "Green Dragon"),
    SOAP("soap", "Soap");

    /** The suit this dragon belongs with on the card. */
    val matchingSuit: Suit
        get() = when (this) {
            RED -> Suit.CRAK
            GREEN -> Suit.BAM
            SOAP -> Suit.DOT
        }
}

sealed interface Tile {
    data class Suited(val rank: Int, val suit: Suit) : Tile
    data class WindTile(val wind: Wind) : Tile
    data class DragonTile(val dragon: Dragon) : Tile
    data object Flower : Tile
    data object Joker : Tile

    /** Also the tile's code in the exported content. */
    val shortLabel: String
        get() = when (this) {
            is Suited -> "$rank${suit.raw.take(1).uppercase()}"
            is WindTile -> wind.letter
            is DragonTile -> when (dragon) {
                Dragon.RED -> "RD"
                Dragon.GREEN -> "GD"
                Dragon.SOAP -> "SO"
            }
            Flower -> "F"
            Joker -> "J"
        }

    val spokenName: String
        get() = when (this) {
            is Suited -> "$rank ${suit.displayName}"
            is WindTile -> "${wind.displayName} Wind"
            is DragonTile -> dragon.displayName
            Flower -> "Flower"
            Joker -> "Joker"
        }

    /** Sort key so hands display grouped the way players rack them. */
    val sortKey: Int
        get() = when (this) {
            is Suited -> suit.ordinal * 10 + rank
            is DragonTile -> 30 + dragon.ordinal
            is WindTile -> 40 + wind.ordinal
            Flower -> 50
            Joker -> 60
        }

    val isHonor: Boolean get() = this is WindTile || this is DragonTile

    companion object {
        fun c(rank: Int): Tile = Suited(rank, Suit.CRAK)
        fun b(rank: Int): Tile = Suited(rank, Suit.BAM)
        fun d(rank: Int): Tile = Suited(rank, Suit.DOT)

        val allSuited: List<Tile> = (1..9).flatMap { rank -> Suit.entries.map { Suited(rank, it) } }
        val allHonors: List<Tile> = Wind.entries.map { WindTile(it) } + Dragon.entries.map { DragonTile(it) }

        fun suited(ranks: List<Int>): List<Tile> = ranks.flatMap { rank -> Suit.entries.map { Suited(rank, it) } }

        private val byCode: Map<String, Tile> =
            (allSuited + allHonors + listOf(Flower, Joker)).associateBy { it.shortLabel }

        fun fromCode(code: String): Tile = byCode[code] ?: error("Unknown tile code $code")
    }
}

/** Sorted the way players rack them. Stable, like Swift's `sorted`. */
val List<Tile>.racked: List<Tile> get() = sortedBy { it.sortKey }
