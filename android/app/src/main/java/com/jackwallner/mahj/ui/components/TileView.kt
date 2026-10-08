package com.jackwallner.mahj.ui.components

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.LineHeightStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.jackwallner.mahj.model.Dragon
import com.jackwallner.mahj.model.Suit
import com.jackwallner.mahj.model.Tile
import com.jackwallner.mahj.ui.theme.Mahj
import com.jackwallner.mahj.ui.theme.pressable

/**
 * One American mahj tile. Text-forward on purpose: US sets print N/E/W/S, F
 * and J, so beginners learn the real markings. Sizes are in dp, not sp: a
 * tile is a picture of an object and must not grow with the font scale.
 */
@Composable
fun TileView(
    tile: Tile,
    width: Dp = 44.dp,
    modifier: Modifier = Modifier,
    tag: String? = null,
    selected: Boolean = false,
    onClick: (() -> Unit)? = null,
) {
    val colors = Mahj.colors
    val height = width * 1.35f
    val shape = RoundedCornerShape(width * 0.16f)
    var base = modifier
        .size(width, height)
        // A drawn drop shadow rather than an elevation one: elevation shadows on many
        // small, re-laid-out tiles render as grey boxes on some GPUs.
        .drawBehind {
            val radius = CornerRadius(width.toPx() * 0.16f)
            drawRoundRect(Color.Black.copy(alpha = 0.10f), topLeft = Offset(0f, 2.dp.toPx()), size = size, cornerRadius = radius)
            drawRoundRect(Color.Black.copy(alpha = 0.08f), topLeft = Offset(0f, 1.dp.toPx()), size = size, cornerRadius = radius)
        }
        .background(colors.tileIvory, shape)
        .border(1.dp, colors.tileEdge, shape)
        .semantics {
            contentDescription = tile.spokenName
            this.selected = selected
            if (onClick != null) role = Role.Button
        }
    if (tag != null) base = base.testTag(tag)
    if (onClick != null) base = base.pressable(onClick = onClick)
    Box(base, contentAlignment = Alignment.Center) { TileFace(tile, width) }
}

@Composable
private fun glyph(size: Dp, weight: FontWeight, serif: Boolean = false): TextStyle {
    val sp = with(LocalDensity.current) { size.toSp() }
    return TextStyle(
        fontFamily = if (serif) FontFamily.Serif else FontFamily.Default,
        fontWeight = weight,
        fontSize = sp,
        lineHeight = sp,
        lineHeightStyle = LineHeightStyle(LineHeightStyle.Alignment.Center, LineHeightStyle.Trim.Both),
    )
}

@Composable
private fun TileFace(tile: Tile, width: Dp) {
    val colors = Mahj.colors
    val ink = Color.Black.copy(alpha = 0.85f)
    when (tile) {
        is Tile.Suited -> if (tile.suit == Suit.CRAK) {
            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(width * 0.04f)) {
                Text("${tile.rank}", style = glyph(width * 0.5f, FontWeight.Bold, serif = true), color = colors.crakRed)
                Text("萬", style = glyph(width * 0.3f, FontWeight.SemiBold), color = colors.crakRed)
            }
        } else {
            val color = if (tile.suit == Suit.BAM) colors.bamGreen else colors.dotBlue
            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(width * 0.07f)) {
                Text("${tile.rank}", style = glyph(width * 0.3f, FontWeight.Bold, serif = true), color = color)
                PipBlock(tile.rank, tile.suit, width, color)
            }
        }
        is Tile.WindTile -> Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(width * 0.04f)) {
            Text(tile.wind.letter, style = glyph(width * 0.52f, FontWeight.Bold, serif = true), color = ink)
            Caption("WIND", Color.Black.copy(alpha = 0.5f), width)
        }
        is Tile.DragonTile -> when (tile.dragon) {
            Dragon.RED -> Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(width * 0.04f)) {
                Text("中", style = glyph(width * 0.5f, FontWeight.Bold), color = colors.crakRed)
                Caption("RED", colors.crakRed, width)
            }
            Dragon.GREEN -> Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(width * 0.04f)) {
                Text("發", style = glyph(width * 0.5f, FontWeight.Bold), color = colors.bamGreen)
                Caption("GREEN", colors.bamGreen, width)
            }
            Dragon.SOAP -> Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(width * 0.07f)) {
                val blue = colors.dotBlue
                Canvas(Modifier.size(width * 0.5f, width * 0.62f)) {
                    val stroke = width.toPx() * 0.055f
                    drawRoundRect(
                        blue,
                        topLeft = Offset(stroke / 2, stroke / 2),
                        size = Size(size.width - stroke, size.height - stroke),
                        cornerRadius = CornerRadius(width.toPx() * 0.06f),
                        style = Stroke(stroke),
                    )
                }
                Caption("SOAP", blue, width)
            }
        }
        Tile.Flower -> Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(width * 0.04f)) {
            Icon(symbol("camera.macro"), null, tint = colors.flowerPink, modifier = Modifier.size(width * 0.46f))
            Caption("FLOWER", colors.flowerPink, width)
        }
        Tile.Joker -> Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(width * 0.04f)) {
            Icon(symbol("theatermasks.fill"), null, tint = colors.jokerPurple, modifier = Modifier.size(width * 0.44f))
            Caption("JOKER", colors.jokerPurple, width)
        }
    }
}

/** The tile's word has a legibility floor so it stays readable on small tiles. */
@Composable
private fun Caption(text: String, color: Color, width: Dp) {
    val size = maxOf(9.5.dp, width * 0.16f)
    Text(text, style = glyph(size, FontWeight.ExtraBold), color = color, maxLines = 1, softWrap = false)
}

private fun pipRows(rank: Int): List<Int> = when (rank) {
    1 -> listOf(1)
    2 -> listOf(2)
    3 -> listOf(3)
    4 -> listOf(2, 2)
    5 -> listOf(2, 1, 2)
    6 -> listOf(3, 3)
    7 -> listOf(2, 3, 2)
    8 -> listOf(3, 2, 3)
    else -> listOf(3, 3, 3)
}

/** Rank-accurate pips: a 9 shows 9 marks. */
@Composable
private fun PipBlock(rank: Int, suit: Suit, width: Dp, color: Color) {
    val rows = pipRows(rank)
    val pip = width * when (rows.size) {
        1 -> 0.24f
        2 -> 0.19f
        else -> 0.145f
    }
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(pip * 0.28f)) {
        rows.forEach { count ->
            Row(horizontalArrangement = Arrangement.spacedBy(pip * 0.32f)) {
                repeat(count) {
                    if (suit == Suit.DOT) {
                        Canvas(Modifier.size(pip)) {
                            val stroke = size.width * 0.28f
                            drawCircle(color, radius = (size.width - stroke) / 2, style = Stroke(stroke))
                        }
                    } else {
                        Box(Modifier.size(pip * 0.45f, pip * 1.3f).background(color, CircleShape))
                    }
                }
            }
        }
    }
}

/**
 * A wrapping row of tiles. Rows are balanced rather than filled: eight tiles
 * split 4 and 4, not 7 and a lone tile. A 13-tile rack reads 7 and 6.
 *
 * Tiles shrink to fit the width they are given: seven 44dp tiles need 344dp,
 * and a 360dp phone has 328dp inside the screen padding, so without this the
 * seventh tile of every rack question was cut off at the edge.
 */
@Composable
fun TileRack(
    tiles: List<Tile>,
    modifier: Modifier = Modifier,
    tileWidth: Dp = 44.dp,
    highlighted: Set<Int> = emptySet(),
    onTap: ((Int) -> Unit)? = null,
) {
    val columns = 7
    val gap = 6.dp
    val rowCount = maxOf(1, (tiles.size + columns - 1) / columns)
    val perRow = maxOf(1, (tiles.size + rowCount - 1) / rowCount)
    val rows = tiles.withIndex().chunked(perRow)
    val gold = Mahj.colors.gold
    BoxWithConstraints(modifier, contentAlignment = Alignment.Center) {
        val fitted = if (maxWidth.value.isFinite()) minOf(tileWidth, (maxWidth - gap * (perRow - 1)) / perRow) else tileWidth
        val width = maxOf(fitted, 24.dp)
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
            rows.forEach { row ->
                Row(horizontalArrangement = Arrangement.spacedBy(gap)) {
                    row.forEach { (index, tile) ->
                        val selected = index in highlighted
                        val lift by animateDpAsState(if (selected) (-8).dp else 0.dp, spring(dampingRatio = 0.7f, stiffness = 500f), label = "lift")
                        Box(Modifier.offset(y = lift)) {
                            TileView(
                                tile,
                                width,
                                tag = "rack-tile-$index",
                                selected = selected,
                                onClick = onTap?.let { tap -> { tap(index) } },
                            )
                            if (selected) {
                                Box(Modifier.size(width, width * 1.35f).border(3.dp, gold, RoundedCornerShape(width * 0.16f)))
                            }
                        }
                    }
                }
            }
        }
    }
}
