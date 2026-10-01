package com.jackwallner.mahj.ui.screens

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionInParent
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.mahj.content.DrillLibrary
import com.jackwallner.mahj.content.SessionBuilder
import com.jackwallner.mahj.data.MasteryLevel
import com.jackwallner.mahj.data.Membership
import com.jackwallner.mahj.data.RoomMastery
import com.jackwallner.mahj.model.Room
import com.jackwallner.mahj.ui.LocalAppActions
import com.jackwallner.mahj.ui.LocalGraph
import com.jackwallner.mahj.ui.components.symbol
import com.jackwallner.mahj.ui.nav.LocalNavigator
import com.jackwallner.mahj.ui.nav.PracticeMode
import com.jackwallner.mahj.ui.nav.Route
import com.jackwallner.mahj.ui.nav.SessionPurpose
import com.jackwallner.mahj.ui.theme.BarIconButton
import com.jackwallner.mahj.ui.theme.Eyebrow
import com.jackwallner.mahj.ui.theme.IconBadge
import com.jackwallner.mahj.ui.theme.Mahj
import com.jackwallner.mahj.ui.theme.MahjColors
import com.jackwallner.mahj.ui.theme.MahjGeo
import com.jackwallner.mahj.ui.theme.MahjType
import com.jackwallner.mahj.ui.theme.PlusBadge
import com.jackwallner.mahj.ui.theme.jadeGradient
import com.jackwallner.mahj.ui.theme.navBarPadding
import com.jackwallner.mahj.ui.theme.pressable
import com.jackwallner.mahj.ui.theme.rounded
import com.jackwallner.mahj.ui.theme.themedCard
import java.time.LocalDate
import kotlinx.coroutines.delay

/** Room identity: each room keeps its own accent so the doors feel like places. */
fun Room.accent(colors: MahjColors): Color = when (id) {
    "tile-room" -> colors.jade
    "card-room" -> colors.coral
    "charleston-room" -> colors.plum
    else -> colors.gold
}

/**
 * Home is the lobby: Get Started, the training modes, then the rooms as
 * doors. Everything that is not a room earns its space or leaves.
 */
@Composable
fun HomeScreen() {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val actions = LocalAppActions.current
    val colors = Mahj.colors
    val progress = graph.progress
    val isPro = graph.subscriptions.isPro
    val scroll = rememberScrollState()
    var highlightedRoom by remember { mutableStateOf<String?>(null) }
    val roomOffsets = remember { mutableMapOf<String, Int>() }

    // The one-shot hint the primer leaves: scroll to and briefly ring the recommended room.
    LaunchedEffect(Unit) {
        val hint = graph.defaults.getString(RECOMMENDED_ROOM_HINT).orEmpty()
        if (hint.isEmpty()) return@LaunchedEffect
        graph.defaults.remove(RECOMMENDED_ROOM_HINT)
        if (DrillLibrary.room(hint) == null) return@LaunchedEffect
        delay(400)
        roomOffsets[hint]?.let { scroll.animateScrollTo((it - 200).coerceAtLeast(0)) }
        highlightedRoom = hint
        delay(2_200)
        highlightedRoom = null
    }

    Column(Modifier.fillMaxSize().background(colors.background)) {
        Row(
            Modifier.fillMaxWidth().statusBarsPadding().height(52.dp).padding(horizontal = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            BarIconButton("book", "Reference and glossary") { navigator.push(Route.Reference) }
            Spacer(Modifier.weight(1f))
            BarIconButton("gearshape", "Settings") { navigator.push(Route.Settings) }
        }
        Column(
            Modifier.fillMaxSize().verticalScroll(scroll).padding(horizontal = 16.dp).padding(navBarPadding()),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Header(progress.streakCount, progress.totalSessions) { navigator.push(Route.Stats) }
            if (progress.quickSessionCompletedToday()) GetStartedDoneCard() else GetStartedCard {
                val items = SessionBuilder.quickSession(seen = progress.seenItems, missed = progress.missedItems, includePro = isPro)
                navigator.push(Route.Session(items, SessionPurpose.Quick(isDaily = true)))
            }
            val skillLevel = graph.defaults.getString(SKILL_LEVEL).orEmpty()
            if (skillLevel == "new" && !graph.defaults.getBoolean(HAS_READ_PRIMER)) {
                HowToPlayCard { navigator.push(Route.HowToPlay) }
            }
            TrainingSection(isPro, onLocked = { actions.openPaywall("mahj_home_sheet") })
            Row(Modifier.padding(top = 6.dp, start = 4.dp)) { Eyebrow("THE ROOMS") }
            DrillLibrary.rooms.forEach { room ->
                Box(Modifier.onGloballyPositioned { roomOffsets[room.id] = it.positionInParent().y.toInt() }) {
                    RoomCard(
                        room = room,
                        locked = !room.isFree && !isPro,
                        mastery = graph.records.mastery(room, isPro),
                        highlighted = highlightedRoom == room.id,
                    ) { navigator.push(Route.Room(room.id)) }
                }
            }
            if (!isPro) UpgradeCard { actions.openPaywall("mahj_home_sheet") }
            Text(
                "Mahj Trainer teaches skills for American Mah Jongg with original practice hands. It is not affiliated with the National Mah Jongg League. For official hands and values, get the current NMJL card.",
                style = MahjType.caption2,
                color = colors.inkTertiary,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
            )
        }
    }
}

const val SKILL_LEVEL = "mahj.skillLevel"
const val HAS_READ_PRIMER = "mahj.hasReadPrimer"
const val RECOMMENDED_ROOM_HINT = "mahj.recommendedRoomHint"

@Composable
private fun Header(streak: Int, sessions: Int, onStats: () -> Unit) {
    val colors = Mahj.colors
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text("Mahj Trainer", style = MahjType.display(32.sp), color = colors.ink)
            Text("Your seat at the table.", style = MahjType.subheadline, color = colors.inkSecondary)
        }
        Row(
            Modifier.pressable(label = "Opens your progress breakdown", onClick = onStats),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            StatChip(streak, "flame.fill", colors.coral, "$streak day streak")
            StatChip(sessions, "checkmark.seal.fill", colors.jade, "$sessions drills done")
        }
    }
}

@Composable
private fun StatChip(value: Int, icon: String, color: Color, label: String) {
    Row(
        Modifier.background(color.copy(alpha = 0.12f), CircleShape).padding(horizontal = 9.dp, vertical = 6.dp).semantics(mergeDescendants = true) {
            contentDescription = label
        },
        horizontalArrangement = Arrangement.spacedBy(5.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(symbol(icon), null, tint = color, modifier = Modifier.size(14.dp))
        Text("$value", style = MahjType.subheadline.copy(fontWeight = FontWeight.Bold), color = Mahj.colors.ink)
    }
}

@Composable
private fun GetStartedCard(onClick: () -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .testTag("get-started")
            .pressable(onClick = onClick)
            .background(jadeGradient(), rounded(MahjGeo.cardCorner))
            .padding(20.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text("Get Started", style = MahjType.display(24.sp), color = Color.White)
            Text("A five-minute mix of what you need next", style = MahjType.subheadline, color = Color.White.copy(alpha = 0.85f))
        }
        Icon(symbol("play.circle.fill"), null, tint = Color.White, modifier = Modifier.size(44.dp))
    }
}

/** Today's Get Started is spent; the card rests until tomorrow. */
@Composable
private fun GetStartedDoneCard() {
    val colors = Mahj.colors
    Row(
        Modifier.fillMaxWidth().themedCard().padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        IconBadge("checkmark.circle.fill", colors.jade, size = 44.dp, iconSize = 28.dp, alpha = 0.12f)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text("Today's session is done", style = MahjType.headline, color = colors.ink)
            Text("A fresh mix lands tomorrow. Keep going in any room below.", style = MahjType.subheadline, color = colors.inkSecondary)
        }
    }
}

@Composable
private fun HowToPlayCard(onClick: () -> Unit) {
    val colors = Mahj.colors
    Row(
        Modifier.fillMaxWidth().pressable(onClick = onClick).themedCard(16.dp).padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        IconBadge("book.fill", colors.gold, corner = 12.dp)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text("How to Play", style = MahjType.headline, color = colors.ink)
            Text("New here? Start with the five-minute primer", style = MahjType.caption, color = colors.inkSecondary)
        }
        Icon(symbol("chevron.right"), null, tint = colors.inkTertiary, modifier = Modifier.size(18.dp))
    }
}

/** The cross-cutting practice modes in one scrolling row of compact tiles. */
@Composable
private fun TrainingSection(isPro: Boolean, onLocked: () -> Unit) {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val colors = Mahj.colors
    val handPlay = graph.handPlay
    val records = graph.records
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 4.dp), verticalAlignment = Alignment.CenterVertically) {
            Eyebrow("TRAINING")
            Spacer(Modifier.weight(1f))
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(3.dp)) {
                Text("SWIPE FOR MORE", style = MahjType.caption2.copy(fontWeight = FontWeight.ExtraBold, letterSpacing = 1.1.sp), color = colors.inkTertiary)
                Icon(symbol("chevron.right"), null, tint = colors.inkTertiary, modifier = Modifier.size(12.dp))
            }
        }
        Row(
            Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 4.dp, vertical = 2.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            // Play a Hand is the one mode a free player can open, once a day.
            val canPlay = handPlay.canPlay(isPro)
            val handBadge = when {
                !canPlay -> "Back tomorrow"
                handPlay.inProgress != null -> "Resume"
                !isPro -> "1 free today"
                handPlay.handsPlayed == 0 -> null
                handPlay.bestStars > 0 -> "Best ${handPlay.bestStars}/3"
                else -> "${handPlay.handsPlayed} played"
            }
            TrainingTile("Play a\nHand", "hand.draw.fill", colors.jade, handBadge, locked = !canPlay, tag = "tile-hand-play") {
                if (canPlay) navigator.push(Route.HandPlay) else onLocked()
            }
            TrainingTile("Endless\nPractice", "infinity", colors.jade, null, locked = !isPro, tag = "tile-endless") {
                if (isPro) navigator.push(Route.EndlessPicker) else onLocked()
            }
            val minute = graph.minutes.result(LocalDate.now())
            TrainingTile(
                "Mahj\nMinute", "calendar.badge.clock", colors.coral,
                minute?.let { "${it.score}/${it.total} today" } ?: "Daily", locked = !isPro, tag = "tile-minute",
            ) { if (isPro) navigator.push(Route.MahjMinute) else onLocked() }
            TrainingTile(
                "Game Night\nPrep", "person.2.fill", colors.plum,
                if (graph.settings.gameNightReminderEnabled) graph.settings.gameNightDay.displayName else "Weekly",
                locked = !isPro, tag = "tile-game-night",
            ) { if (isPro) navigator.push(Route.GameNightPrep) else onLocked() }
            TrainingTile(
                "Timed\nChallenge", "timer", colors.coral,
                if (records.bestChallengeScore > 0) "Best ${records.bestChallengeScore}" else null, locked = !isPro, tag = "tile-timed",
            ) { if (isPro) navigator.push(Route.Practice(PracticeMode.Timed)) else onLocked() }
            // Only offered when there is something the runner can actually ask.
            val reviewable = SessionBuilder.reviewableIDs(isPro)
            val due = records.dueCount(reviewable)
            if (due > 0) {
                TrainingTile("Fix My\nMistakes", "arrow.trianglehead.counterclockwise", colors.plum, "$due due", locked = !isPro, tag = "tile-review") {
                    if (!isPro) {
                        onLocked()
                    } else {
                        val items = SessionBuilder.reviewSession(records.reviewQueue(presentable = reviewable), isPro)
                        navigator.push(Route.Practice(PracticeMode.Review, items))
                    }
                }
            }
        }
    }
}

@Composable
private fun TrainingTile(title: String, icon: String, color: Color, badge: String?, locked: Boolean, tag: String, onClick: () -> Unit) {
    val colors = Mahj.colors
    Column(
        Modifier
            .width(128.dp)
            .height(118.dp)
            .testTag(tag)
            .pressable(label = if (locked) "Included with ${Membership.NAME}" else null, onClick = onClick)
            .themedCard(16.dp)
            .padding(12.dp),
    ) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Icon(symbol(icon), null, tint = color, modifier = Modifier.size(24.dp))
            Spacer(Modifier.weight(1f))
            if (locked) Icon(symbol("lock.fill"), null, tint = colors.gold, modifier = Modifier.size(12.dp))
        }
        Spacer(Modifier.weight(1f))
        Text(title, style = MahjType.subheadline.copy(fontWeight = FontWeight.Bold), color = colors.ink)
        Text(
            badge ?: if (locked) Membership.NAME else " ",
            style = MahjType.caption2.copy(fontWeight = FontWeight.SemiBold),
            color = if (badge != null) color else colors.gold,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

@Composable
private fun RoomCard(room: Room, locked: Boolean, mastery: RoomMastery, highlighted: Boolean, onClick: () -> Unit) {
    val colors = Mahj.colors
    val accent = room.accent(colors)
    Row(
        Modifier
            .fillMaxWidth()
            .testTag("room-${room.id}")
            .pressable(
                label = if (locked) "Locked. ${room.drills.size} drills, included with ${Membership.NAME}"
                else "${mastery.level.title}. ${mastery.known} of ${mastery.total} questions solid",
                onClick = onClick,
            )
            .themedCard()
            .border(2.5.dp, if (highlighted) accent else Color.Transparent, rounded(MahjGeo.cardCorner))
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        IconBadge(room.icon, accent, size = 48.dp, iconSize = 24.dp, corner = 14.dp, alpha = 0.12f)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(room.name, style = MahjType.headline, color = colors.ink)
                if (locked) PlusBadge()
            }
            Text(room.tagline, style = MahjType.subheadline, color = colors.inkSecondary, maxLines = 2)
        }
        if (locked) Icon(symbol("lock.fill"), null, tint = colors.gold, modifier = Modifier.size(16.dp))
        else MasteryRing(mastery, accent)
    }
}

/** Room mastery at a glance: a ring that fills as questions start holding. */
@Composable
fun MasteryRing(mastery: RoomMastery, color: Color) {
    val colors = Mahj.colors
    val fraction by animateFloatAsState(mastery.fraction.toFloat(), spring(dampingRatio = 0.8f, stiffness = 200f), label = "ring")
    Column(Modifier.width(46.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Box(Modifier.size(32.dp), contentAlignment = Alignment.Center) {
            Canvas(Modifier.fillMaxSize()) {
                val stroke = 3.dp.toPx()
                val inset = stroke / 2
                val arcSize = Size(size.width - stroke, size.height - stroke)
                drawArc(color.copy(alpha = 0.18f), 0f, 360f, false, Offset(inset, inset), arcSize, style = Stroke(stroke))
                if (fraction > 0f) {
                    drawArc(color, -90f, 360f * fraction, false, Offset(inset, inset), arcSize, style = Stroke(stroke, cap = StrokeCap.Round))
                }
            }
            when (mastery.level) {
                MasteryLevel.SHARP -> Icon(symbol("star.fill"), null, tint = color, modifier = Modifier.size(12.dp))
                MasteryLevel.UNTOUCHED -> Unit
                else -> Text(
                    "${(mastery.fraction * 100).toInt()}",
                    style = MahjType.caption2.copy(fontSize = 10.sp, fontWeight = FontWeight.Bold),
                    color = colors.inkSecondary,
                )
            }
        }
        Text(
            if (mastery.level == MasteryLevel.UNTOUCHED) "New" else mastery.level.title,
            style = MahjType.caption2.copy(fontSize = 9.sp, fontWeight = FontWeight.SemiBold),
            color = colors.inkTertiary,
        )
    }
}

@Composable
private fun UpgradeCard(onClick: () -> Unit) {
    val colors = Mahj.colors
    val locked = DrillLibrary.rooms.sumOf { it.plusDrillCount }
    Row(
        Modifier
            .fillMaxWidth()
            .padding(top = 2.dp)
            .pressable(onClick = onClick)
            .themedCard(16.dp)
            .border(1.dp, colors.gold.copy(alpha = 0.35f), rounded(16.dp))
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        IconBadge("sparkles", colors.gold, alpha = 0.14f)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text("Get ${Membership.NAME}", style = MahjType.headline, color = colors.ink)
            Text(
                "Mahj Minute, Game Night Prep, endless modes, and $locked more drills across every room",
                style = MahjType.caption,
                color = colors.inkSecondary,
            )
        }
        Icon(symbol("chevron.right"), null, tint = colors.inkTertiary, modifier = Modifier.size(18.dp))
    }
}
