package com.jackwallner.mahj.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.scaleIn
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.mahj.content.DrillLibrary
import com.jackwallner.mahj.model.CharlestonScenario
import com.jackwallner.mahj.model.Drill
import com.jackwallner.mahj.model.Tile
import com.jackwallner.mahj.model.racked
import com.jackwallner.mahj.ui.LocalGraph
import com.jackwallner.mahj.ui.components.DrillProgress
import com.jackwallner.mahj.ui.components.DrillStage
import com.jackwallner.mahj.ui.components.TileRack
import com.jackwallner.mahj.ui.components.TileView
import com.jackwallner.mahj.ui.components.shine
import com.jackwallner.mahj.ui.components.symbol
import com.jackwallner.mahj.ui.nav.LocalNavigator
import com.jackwallner.mahj.ui.theme.CenteringScroll
import com.jackwallner.mahj.ui.theme.Haptics
import com.jackwallner.mahj.ui.theme.Mahj
import com.jackwallner.mahj.ui.theme.MahjScreen
import com.jackwallner.mahj.ui.theme.MahjType
import com.jackwallner.mahj.ui.theme.PrimaryCTA
import com.jackwallner.mahj.ui.theme.Readable
import com.jackwallner.mahj.ui.theme.SoundPlayer
import com.jackwallner.mahj.ui.theme.rounded
import com.jackwallner.mahj.ui.theme.screenPadding
import com.jackwallner.mahj.ui.theme.themedCard
import kotlinx.coroutines.delay

/** Grade a pass by tile multiset, so equivalent duplicates count as matches. */
fun matchCount(selected: Collection<Int>, rack: List<Tile>, recommended: List<Tile>): Int {
    val pool = recommended.toMutableList()
    return selected.count { index -> pool.indexOf(rack[index]).takeIf { it >= 0 }?.let { pool.removeAt(it) } != null }
}

@Composable
fun CharlestonDrillScreen(drill: Drill, scenarios: List<CharlestonScenario>) {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val colors = Mahj.colors
    var index by rememberSaveable { mutableIntStateOf(0) }
    var selected by rememberSaveable { mutableStateOf(listOf<Int>()) }
    var submitted by rememberSaveable { mutableStateOf(false) }
    var score by rememberSaveable { mutableIntStateOf(0) }
    var finished by rememberSaveable { mutableStateOf(false) }
    var confetti by remember { mutableIntStateOf(0) }
    var shineTrigger by remember { mutableIntStateOf(0) }

    if (finished) {
        DrillCompleteScreen(drill, score, scenarios.size * 3) { navigator.pop() }
        return
    }
    val scenario = scenarios[index]
    val rack = remember(scenario.id) { scenario.deal.racked }
    val matches = matchCount(selected, rack, scenario.recommendedPass)

    LaunchedEffect(submitted, index) {
        if (submitted && matches == 3) {
            delay(350)
            shineTrigger += 1
        }
    }

    MahjScreen(drill.title, onBack = { navigator.pop() }) {
        DrillStage(confetti) {
            Readable(Modifier.fillMaxSize()) {
                Column(Modifier.fillMaxSize().screenPadding(), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    DrillProgress(index, scenarios.size)
                    CenteringScroll(Modifier.weight(1f)) {
                        Column(
                            Modifier.fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(18.dp),
                        ) {
                            Text(
                                scenario.situation,
                                style = MahjType.display(20.sp, FontWeight.SemiBold),
                                color = colors.ink,
                                textAlign = TextAlign.Center,
                                modifier = Modifier.padding(top = 8.dp),
                            )
                            TileRack(rack, Modifier.padding(vertical = 6.dp), highlighted = selected.toSet()) { tapped ->
                                if (submitted) return@TileRack
                                selected = when {
                                    tapped in selected -> selected - tapped
                                    selected.size >= 3 -> selected
                                    // Jokers may never be passed. The drill enforces the real rule.
                                    rack[tapped] == Tile.Joker -> selected
                                    else -> selected + tapped
                                }
                            }
                            AnimatedVisibility(submitted, enter = fadeIn() + scaleIn(initialScale = 0.94f)) {
                                CoachCard(scenario, matches, shineTrigger)
                            }
                            if (!submitted) {
                                Text("Selected ${selected.size} of 3", style = MahjType.subheadline, color = colors.inkSecondary)
                            }
                        }
                    }
                    if (submitted) {
                        PrimaryCTA(if (index + 1 < scenarios.size) "Next Deal" else "Finish", Modifier.testTag("next")) {
                            if (index + 1 < scenarios.size) {
                                selected = emptyList()
                                submitted = false
                                index += 1
                            } else {
                                finished = true
                            }
                        }
                    } else {
                        PrimaryCTA("Pass These 3", Modifier.testTag("pass"), enabled = selected.size == 3) {
                            submitted = true
                            score += matches
                            graph.recordAnswer(scenario.id, DrillLibrary.roomID(drill.id), matches >= 2)
                            when (matches) {
                                3 -> {
                                    confetti += 1
                                    celebrateCorrect()
                                }
                                // Two of three is partial credit: the chime without the full landing.
                                2 -> {
                                    Haptics.success()
                                    SoundPlayer.play(SoundPlayer.Effect.SUCCESS)
                                }
                                else -> consoleMiss()
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun CoachCard(scenario: CharlestonScenario, matches: Int, shineTrigger: Int) {
    val colors = Mahj.colors
    val headline = when (matches) {
        3 -> "Perfect pass! 3 of 3"
        2 -> "Close! 2 of 3 match"
        1 -> "1 of 3 matched the coach"
        else -> "The coach saw it differently"
    }
    Column(
        Modifier
            .fillMaxWidth()
            .shadow(if (matches == 3) 16.dp else 0.dp, rounded(16.dp), ambientColor = colors.gold, spotColor = colors.gold)
            .themedCard(16.dp)
            .shine(shineTrigger, 16.dp)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Icon(symbol(if (matches == 3) "star.fill" else "graduationcap.fill"), null, tint = colors.gold, modifier = Modifier.size(20.dp))
            Text(headline, style = MahjType.headline, color = colors.ink, modifier = Modifier.testTag("coach-headline"))
        }
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text("Coach would pass:", style = MahjType.subheadline.copy(fontWeight = FontWeight.SemiBold), color = colors.ink)
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                scenario.recommendedPass.forEach { TileView(it, 40.dp) }
            }
        }
        Text(scenario.reasoning, style = MahjType.subheadline, color = colors.ink)
        Row(
            Modifier.fillMaxWidth().background(colors.gold.copy(alpha = 0.12f), rounded(10.dp)).padding(10.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Icon(symbol("lightbulb.fill"), null, tint = colors.gold, modifier = Modifier.size(18.dp))
            Text(scenario.tip, style = MahjType.footnote.copy(fontWeight = FontWeight.Medium), color = colors.ink)
        }
    }
}
