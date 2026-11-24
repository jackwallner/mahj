package com.jackwallner.mahj.ui.components

import kotlin.math.max
import kotlin.math.min

/**
 * How big a tile draws and how a rack wraps, kept free of Compose so the JVM tests can check it.
 * Port of iOS `TileView.scale(for:)`, `TileView.scaled` and `BalancedRowsLayout` (1.4.7).
 */
object TileSizing {
    /** No tile draws wider than this, so the big onboarding and flashcard tiles do not turn a rack into a wall. */
    const val MAXIMUM_WIDTH = 72f
    const val SPACING = 6f
    const val ROW_SPACING = 10f
    const val MINIMUM_SPACING = 2f
    const val COLUMNS = 7

    /**
     * Tiles follow the system font size. 1x up to the default (smaller text never shrinks a tile),
     * then 1.1, 1.2, 1.3 and 1.4 at the largest sizes. Android's steps (1.15, 1.3, 1.5, 1.8, 2.0)
     * are not Apple's, so each band is cut at the midpoint between them.
     */
    fun scale(fontScale: Float): Float = when {
        fontScale <= 1.05f -> 1f
        fontScale < 1.22f -> 1.1f
        fontScale < 1.4f -> 1.2f
        fontScale < 1.65f -> 1.3f
        else -> 1.4f
    }

    fun scaled(width: Float, fontScale: Float): Float = max(width, min(width * scale(fontScale), MAXIMUM_WIDTH))

    /** Rows sized from tile counts, longest first; `gap` is the space between tiles in a row. */
    data class Arrangement(val rows: List<Int>, val gap: Float)

    /** The designed tiles per row: at most seven, balanced (eight split 4 and 4, thirteen 7 and 6). */
    fun designedPerRow(count: Int): Int {
        val rowCount = max(1, (count + COLUMNS - 1) / COLUMNS)
        return max(1, (count + rowCount - 1) / rowCount)
    }

    /**
     * The designed rows with the designed gap where they fit `width`, else the most tiles per row
     * that fit with gaps no tighter than [MINIMUM_SPACING]. A null width is the design.
     */
    fun arrangement(count: Int, tileWidth: Float, width: Float?): Arrangement {
        val designed = designedPerRow(count)
        if (width == null || !width.isFinite() || count == 0) return Arrangement(rows(count, designed), SPACING)
        for (limit in designed downTo 1) {
            val rowCount = (count + limit - 1) / limit
            val balanced = (count + rowCount - 1) / rowCount
            val gap = if (balanced > 1) min(SPACING, (width - balanced * tileWidth) / (balanced - 1)) else SPACING
            if (gap >= MINIMUM_SPACING || balanced == 1) {
                return Arrangement(rows(count, balanced), max(gap, if (balanced == 1) SPACING else MINIMUM_SPACING))
            }
        }
        return Arrangement(rows(count, 1), SPACING)
    }

    /**
     * A row that must stay one line (the onboarding info pages): the tile width, shrunk until
     * `count` tiles and their gaps fit `width`. At the largest font on a narrow phone four big
     * tiles otherwise broke 2 and 2 and the second row sat under the page dots.
     */
    fun oneRowWidth(count: Int, tileWidth: Float, width: Float?): Float {
        if (width == null || !width.isFinite() || count <= 0) return tileWidth
        val fit = (width - (count - 1) * SPACING) / count
        return max(1f, min(tileWidth, fit))
    }

    /** The fewest rows of at most `perRow`, differing by at most one tile: 13 four a row read 4, 3, 3, 3. */
    fun rows(count: Int, perRow: Int): List<Int> {
        if (count == 0) return emptyList()
        val rowCount = max(1, (count + perRow - 1) / perRow)
        val base = count / rowCount
        val extra = count % rowCount
        return (0 until rowCount).map { base + if (it < extra) 1 else 0 }.filter { it > 0 }
    }
}
