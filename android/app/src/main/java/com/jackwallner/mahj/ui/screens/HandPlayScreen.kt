package com.jackwallner.mahj.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.scaleIn
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.mahj.content.HandPlayEngine
import com.jackwallner.mahj.content.PracticeSkill
import com.jackwallner.mahj.data.HandPlayStore
import com.jackwallner.mahj.data.Membership
import com.jackwallner.mahj.model.HandCategory
import com.jackwallner.mahj.model.Tile
import com.jackwallner.mahj.model.racked
import com.jackwallner.mahj.ui.LocalAppActions
import com.jackwallner.mahj.ui.LocalGraph
import com.jackwallner.mahj.ui.components.ConfettiBurst
import com.jackwallner.mahj.ui.components.TileRack
import com.jackwallner.mahj.ui.components.symbol
import com.jackwallner.mahj.ui.nav.LocalNavigator
import com.jackwallner.mahj.ui.theme.CenteringScroll
import com.jackwallner.mahj.ui.theme.Eyebrow
import com.jackwallner.mahj.ui.theme.Haptics
import com.jackwallner.mahj.ui.theme.Mahj
import com.jackwallner.mahj.ui.theme.MahjScreen
import com.jackwallner.mahj.ui.theme.MahjType
import com.jackwallner.mahj.ui.theme.PrimaryCTA
import com.jackwallner.mahj.ui.theme.QuietButton
import com.jackwallner.mahj.ui.theme.Readable
import com.jackwallner.mahj.ui.theme.pressable
import com.jackwallner.mahj.ui.theme.rounded
import com.jackwallner.mahj.ui.theme.screenPadding
import com.jackwallner.mahj.ui.theme.themedCard
import java.util.UUID

private enum class Phase { CHOOSING, COMMITTED, PLAYING, FINISHED }

/**
 * Play a Hand: commit to a section, then draw and discard twelve times while
 * a coach grades every throw. No opponents, on purpose: the wall is random,
 * the rack is yours, and the coach's answer is arithmetic you can check.
 */
@Composable
fun HandPlayScreen() {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val actions = LocalAppActions.current
    val store = graph.handPlay
    val isPro = graph.subscriptions.isPro

    var phase by remember { mutableStateOf(Phase.CHOOSING) }
    var rack by remember { mutableStateOf(emptyList<Tile>()) }
    var wall by remember { mutableStateOf(emptyList<Tile>()) }
    var wallIndex by remember { mutableIntStateOf(0) }
    var target by remember { mutableStateOf<HandCategory?>(null) }
    var turn by remember { mutableIntStateOf(0) }
    var drawn by remember { mutableStateOf<Tile?>(null) }
    var grade by remember { mutableStateOf<HandPlayStore.ThrowGrade?>(null) }
    var cleanDiscards by remember { mutableIntStateOf(0) }
    var verdict by remember { mutableStateOf<HandPlayEngine.Verdict?>(null) }
    var confetti by remember { mutableIntStateOf(0) }

    fun save() {
        val chosen = target ?: return
        store.saveInProgress(HandPlayStore.InProgressHand(rack, wall, wallIndex, chosen, turn, cleanDiscards, drawn, grade))
    }

    fun deal() {
        val fresh = HandPlayEngine.deal()
        rack = fresh.rack
        wall = fresh.wall
    }

    // A hand already started is picked back up where it was left: the free hand was spent when it began.
    LaunchedEffect(Unit) {
        if (rack.isNotEmpty()) return@LaunchedEffect
        val saved = store.inProgress
        if (saved != null) {
            rack = saved.rack
            wall = saved.wall
            wallIndex = saved.wallIndex
            target = saved.target
            turn = saved.turn
            cleanDiscards = saved.cleanDiscards
            drawn = saved.drawn
            grade = saved.grade
            phase = Phase.PLAYING
        } else {
            deal()
        }
    }

    fun finish() {
        val chosen = target ?: return
        val result = HandPlayEngine.verdict(rack, chosen, cleanDiscards, turn)
        verdict = result
        store.clearInProgress()
        store.recordVerdict(result.stars)
        graph.progress.recordSession("hand-play")
        if (result.stars >= 2) {
            confetti += 1
            celebrateCorrect()
        }
        phase = Phase.FINISHED
    }

    fun draw() {
        if (wallIndex >= wall.size) {
            finish()
            return
        }
        val tile = wall[wallIndex]
        wallIndex += 1
        turn += 1
        drawn = tile
        rack = (rack + tile).racked
        save()
    }

    fun throwTile(index: Int) {
        val chosen = target ?: return
        if (grade != null || index !in rack.indices) return
        val tile = rack[index]
        val wasBest = tile in HandPlayEngine.bestDiscards(rack, chosen)
        val note = HandPlayEngine.coachNote(tile, rack, chosen, wasBest)
        rack = rack.toMutableList().also { it.removeAt(index) }
        grade = HandPlayStore.ThrowGrade(tile, wasBest, note)
        if (wasBest) {
            cleanDiscards += 1
            celebrateCorrect()
        } else {
            consoleMiss()
        }
        // One rollup row for the whole mode, never one per throw.
        graph.records.record(PracticeSkill.HAND_PLAY.itemPrefix + UUID.randomUUID(), PracticeSkill.HAND_PLAY.roomID, wasBest, isReviewable = false)
        save()
    }

    MahjScreen("Play a Hand", onBack = { navigator.pop() }) {
        Box(Modifier.fillMaxSize()) {
            when (phase) {
                Phase.CHOOSING, Phase.COMMITTED -> SetupPhase(
                    rack = rack,
                    committed = if (phase == Phase.COMMITTED) target else null,
                    onChoose = { category ->
                        Haptics.light()
                        target = category
                        phase = Phase.COMMITTED
                    },
                    onPlay = {
                        store.recordStart(isPro)
                        phase = Phase.PLAYING
                        draw()
                    },
                )
                Phase.PLAYING -> PlayPhase(
                    rack = rack,
                    target = target,
                    turn = turn,
                    drawn = drawn,
                    grade = grade,
                    onThrow = ::throwTile,
                    onNext = {
                        grade = null
                        if (turn >= HandPlayEngine.TURN_COUNT) finish() else draw()
                    },
                )
                Phase.FINISHED -> verdict?.let { result ->
                    VerdictPhase(
                        result = result,
                        rack = rack,
                        canPlayAgain = store.canPlay(isPro),
                        onPlayAgain = {
                            deal()
                            wallIndex = 0
                            turn = 0
                            drawn = null
                            grade = null
                            cleanDiscards = 0
                            verdict = null
                            target = null
                            phase = Phase.CHOOSING
                        },
                        onUpgrade = { actions.openPaywall("mahj_hand_play") },
                        onDone = { navigator.pop() },
                    )
                }
            }
            ConfettiBurst(confetti, origin = Offset(0.5f, 0.4f))
        }
    }
}

@Composable
private fun SetupPhase(rack: List<Tile>, committed: HandCategory?, onChoose: (HandCategory) -> Unit, onPlay: () -> Unit) {
    val colors = Mahj.colors
    Readable(Modifier.fillMaxSize()) {
        CenteringScroll(Modifier.fillMaxSize()) {
            Column(
                Modifier.fillMaxWidth().padding(horizontal = 16.dp).padding(bottom = 28.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                Column(Modifier.padding(top = 10.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("Your deal", style = MahjType.display(24.sp), color = colors.ink)
                    Text(
                        "Thirteen tiles, straight off the wall. Pick the family you are going to chase, then everything you keep should serve it.",
                        style = MahjType.subheadline,
                        color = colors.inkSecondary,
                        textAlign = TextAlign.Center,
                    )
                }
                TileRack(rack, tileWidth = 40.dp)
                if (committed != null) {
                    CoachRead(rack, committed, onPlay)
                } else {
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Eyebrow("COMMIT TO A SECTION", modifier = Modifier.align(Alignment.CenterHorizontally).padding(top = 6.dp))
                        HandPlayEngine.playableTargets.forEach { category ->
                            Row(
                                Modifier.fillMaxWidth().testTag("target-${category.raw}").pressable { onChoose(category) }.themedCard(16.dp).padding(14.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(12.dp),
                            ) {
                                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                                    Text(category.displayName, style = MahjType.headline, color = colors.ink)
                                    Text(category.howToSpot, style = MahjType.caption, color = colors.inkSecondary)
                                }
                                Icon(symbol("chevron.right"), null, tint = colors.inkTertiary, modifier = Modifier.size(18.dp))
                            }
                        }
                    }
                }
            }
        }
    }
}

/** What the coach would have committed to. Shown after the pick, so it teaches rather than answers. */
@Composable
private fun CoachRead(rack: List<Tile>, chosen: HandCategory, onPlay: () -> Unit) {
    val colors = Mahj.colors
    val ranked = remember(rack) { HandPlayEngine.rankedTargets(rack) }
    val coachPick = ranked.firstOrNull()?.target
    val agrees = coachPick == chosen
    Column(Modifier.fillMaxWidth().themedCard(18.dp).padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Icon(
                symbol(if (agrees) "checkmark.seal.fill" else "graduationcap.fill"),
                null,
                tint = if (agrees) colors.bamGreen else colors.gold,
                modifier = Modifier.size(20.dp),
            )
            Text(if (agrees) "The coach agrees" else "The coach reads it differently", style = MahjType.headline, color = colors.ink)
        }
        Text(
            if (agrees) "${chosen.displayName} is where most of this rack already points. Play it out."
            else "The coach would have started ${(coachPick ?: chosen).displayName} with this deal. You are not wrong to try ${chosen.displayName}, and a hand you have committed to beats a hand you keep changing your mind about, so that is what these twelve turns will be graded against.",
            style = MahjType.subheadline,
            color = colors.inkSecondary,
        )
        Column(Modifier.fillMaxWidth().background(colors.well, rounded(12.dp)).padding(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            ranked.forEach { entry ->
                val fitting = HandPlayEngine.fittingTiles(rack, entry.target)
                val mine = entry.target == chosen
                Row(Modifier.fillMaxWidth().padding(vertical = 3.dp)) {
                    Text(
                        entry.target.shortName,
                        style = MahjType.footnote.copy(fontWeight = if (mine) FontWeight.Bold else FontWeight.Normal),
                        color = if (mine) colors.ink else colors.inkSecondary,
                    )
                    Spacer(Modifier.weight(1f))
                    Text("$fitting tile${if (fitting == 1) "" else "s"} fit", style = MahjType.caption, color = colors.inkTertiary)
                }
            }
            Text(
                "Ordered by how strong the rack is, not by the raw count: a pair or a pung is worth more than the same tiles scattered.",
                style = MahjType.caption2,
                color = colors.inkTertiary,
                modifier = Modifier.padding(top = 4.dp),
            )
        }
        PrimaryCTA("Play it out", Modifier.testTag("play-it-out"), onClick = onPlay)
    }
}

@Composable
private fun PlayPhase(
    rack: List<Tile>,
    target: HandCategory?,
    turn: Int,
    drawn: Tile?,
    grade: HandPlayStore.ThrowGrade?,
    onThrow: (Int) -> Unit,
    onNext: () -> Unit,
) {
    val colors = Mahj.colors
    // Before the throw, the tile just drawn is marked; after it nothing is.
    val highlighted = if (grade == null && drawn != null) rack.indexOf(drawn).takeIf { it >= 0 }?.let { setOf(it) } ?: emptySet() else emptySet()
    val fitting = target?.let { HandPlayEngine.fittingTiles(rack, it) } ?: 0
    Readable(Modifier.fillMaxSize()) {
        Column(Modifier.fillMaxSize().screenPadding(), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(
                    "Turn ${minOf(turn, HandPlayEngine.TURN_COUNT)} of ${HandPlayEngine.TURN_COUNT}",
                    style = MahjType.caption.copy(fontWeight = FontWeight.SemiBold),
                    color = colors.inkSecondary,
                    modifier = Modifier.testTag("turn-counter"),
                )
                Spacer(Modifier.weight(1f))
                if (target != null) {
                    Row(
                        Modifier.background(colors.jade.copy(alpha = 0.12f), CircleShape).padding(horizontal = 9.dp, vertical = 5.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(5.dp),
                    ) {
                        Icon(symbol("target"), null, tint = colors.jade, modifier = Modifier.size(12.dp))
                        Text(target.shortName, style = MahjType.caption.copy(fontWeight = FontWeight.Bold), color = colors.jade)
                    }
                    Text("$fitting fit", style = MahjType.caption.copy(fontWeight = FontWeight.SemiBold), color = colors.inkSecondary)
                }
            }
            CenteringScroll(Modifier.weight(1f)) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    if (drawn != null) {
                        Text(
                            if (grade == null) "You drew the ${drawn.spokenName}. What goes?" else "You threw the ${grade.discard.spokenName}.",
                            style = MahjType.display(21.sp),
                            color = colors.ink,
                            textAlign = TextAlign.Center,
                        )
                    }
                    TileRack(rack, tileWidth = 40.dp, highlighted = highlighted, onTap = if (grade == null) onThrow else null)
                    AnimatedVisibility(grade != null, enter = fadeIn() + scaleIn(initialScale = 0.96f)) {
                        grade?.let { GradeCard(it) }
                    }
                    if (grade == null) Text("Tap the tile you want to throw", style = MahjType.caption, color = colors.inkTertiary)
                }
            }
            if (grade != null) {
                PrimaryCTA(if (turn >= HandPlayEngine.TURN_COUNT) "See how you did" else "Next turn", Modifier.testTag("next-turn"), onClick = onNext)
            }
        }
    }
}

@Composable
private fun GradeCard(grade: HandPlayStore.ThrowGrade) {
    val colors = Mahj.colors
    val tint = if (grade.wasBest) colors.bamGreen else colors.gold
    Row(
        Modifier.fillMaxWidth().background(tint.copy(alpha = 0.12f), rounded(14.dp)).padding(14.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Icon(symbol(if (grade.wasBest) "checkmark.circle.fill" else "lightbulb.fill"), null, tint = tint, modifier = Modifier.size(20.dp))
        Text(grade.note, style = MahjType.subheadline, color = colors.ink, modifier = Modifier.testTag("grade-note"))
    }
}

@Composable
private fun VerdictPhase(
    result: HandPlayEngine.Verdict,
    rack: List<Tile>,
    canPlayAgain: Boolean,
    onPlayAgain: () -> Unit,
    onUpgrade: () -> Unit,
    onDone: () -> Unit,
) {
    val colors = Mahj.colors
    Readable(Modifier.fillMaxSize()) {
        CenteringScroll(Modifier.fillMaxSize()) {
            Column(
                Modifier.fillMaxWidth().padding(horizontal = 16.dp).padding(bottom = 28.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                Row(Modifier.padding(top = 18.dp), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    repeat(3) { index ->
                        val earned = index < result.stars
                        Icon(
                            symbol(if (earned) "star.fill" else "star"),
                            null,
                            tint = if (earned) colors.gold else colors.inkTertiary.copy(alpha = 0.4f),
                            modifier = Modifier.size(28.dp),
                        )
                    }
                }
                Text(result.headline, style = MahjType.display(26.sp), color = colors.ink, textAlign = TextAlign.Center)
                Row(Modifier.fillMaxWidth().themedCard().padding(vertical = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Metric("${result.fitting}/${result.total}", "tiles fit", colors.jade, Modifier.weight(1f))
                    Box(Modifier.width(1.dp).height(34.dp).background(colors.rule))
                    Metric("${result.cleanDiscards}/${result.discards}", "clean throws", colors.coral, Modifier.weight(1f))
                }
                Text(
                    result.body,
                    style = MahjType.subheadline,
                    color = colors.inkSecondary,
                    modifier = Modifier.fillMaxWidth().background(colors.gold.copy(alpha = 0.12f), rounded(14.dp)).padding(14.dp),
                )
                Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Eyebrow("YOUR FINAL RACK", colors.inkTertiary)
                    TileRack(rack, tileWidth = 34.dp)
                }
                if (canPlayAgain) {
                    PrimaryCTA("Deal another hand", onClick = onPlayAgain)
                } else {
                    // The free hand is spent: the one moment the upsell is actually welcome.
                    Column(
                        Modifier
                            .fillMaxWidth()
                            .testTag("hand-upsell")
                            .pressable(onClick = onUpgrade)
                            .background(colors.gold.copy(alpha = 0.10f), rounded(16.dp))
                            .border(1.dp, colors.gold.copy(alpha = 0.35f), rounded(16.dp))
                            .padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(6.dp),
                    ) {
                        Text("That was today's free hand", style = MahjType.headline, color = colors.ink)
                        Text(
                            "${Membership.NAME} deals as many as you want, whenever you want them.",
                            style = MahjType.subheadline,
                            color = colors.inkSecondary,
                            textAlign = TextAlign.Center,
                        )
                    }
                }
                QuietButton("Done", onClick = onDone)
            }
        }
    }
}

@Composable
private fun Metric(value: String, caption: String, color: androidx.compose.ui.graphics.Color, modifier: Modifier) {
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Text(value, style = MahjType.display(24.sp), color = color)
        Text(caption, style = MahjType.caption, color = Mahj.colors.inkSecondary)
    }
}
