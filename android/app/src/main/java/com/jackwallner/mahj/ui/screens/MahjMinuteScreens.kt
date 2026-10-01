package com.jackwallner.mahj.ui.screens

import androidx.compose.foundation.background
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
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
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.mahj.content.MahjMinuteCategory
import com.jackwallner.mahj.content.MahjMinuteContent
import com.jackwallner.mahj.data.MahjMinuteResult
import com.jackwallner.mahj.ui.LocalAppActions
import com.jackwallner.mahj.ui.LocalGraph
import com.jackwallner.mahj.ui.components.ConfettiBurst
import com.jackwallner.mahj.ui.components.symbol
import com.jackwallner.mahj.ui.nav.LocalNavigator
import com.jackwallner.mahj.ui.nav.Route
import com.jackwallner.mahj.ui.nav.SessionPurpose
import com.jackwallner.mahj.ui.shareText
import com.jackwallner.mahj.ui.theme.Eyebrow
import com.jackwallner.mahj.ui.theme.Haptics
import com.jackwallner.mahj.ui.theme.IconBadge
import com.jackwallner.mahj.ui.theme.Mahj
import com.jackwallner.mahj.ui.theme.MahjScreen
import com.jackwallner.mahj.ui.theme.MahjType
import com.jackwallner.mahj.ui.theme.PrimaryCTA
import com.jackwallner.mahj.ui.theme.QuietButton
import com.jackwallner.mahj.ui.theme.Readable
import com.jackwallner.mahj.ui.theme.SoundPlayer
import com.jackwallner.mahj.ui.theme.navBarPadding
import com.jackwallner.mahj.ui.theme.pressable
import com.jackwallner.mahj.ui.theme.themedCard
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
fun MahjMinuteScreen() {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val colors = Mahj.colors
    val today = LocalDate.now()
    val todayResult = graph.minutes.result(today)
    MahjScreen("Mahj Minute", onBack = { navigator.pop() }) {
        Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            Column(Modifier.padding(16.dp).padding(navBarPadding()), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Column(
                    Modifier.fillMaxWidth().themedCard().padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    val tint = if (todayResult == null) colors.coral else colors.jade
                    IconBadge(if (todayResult == null) "calendar.badge.clock" else "checkmark.seal.fill", tint, size = 68.dp, iconSize = 30.dp)
                    Text("Today's Mahj Minute", style = MahjType.display(27.sp), color = colors.ink, textAlign = TextAlign.Center)
                    Text(
                        "The same five original questions for every member: two rack reads, one Charleston call, and two table judgments.",
                        style = MahjType.subheadline,
                        color = colors.inkSecondary,
                        textAlign = TextAlign.Center,
                    )
                    if (todayResult != null) {
                        PrimaryCTA("View Today's ${todayResult.score}/${todayResult.total}") { navigator.push(Route.MinuteResult(todayResult)) }
                    } else {
                        PrimaryCTA("Start Today's Challenge", Modifier.testTag("start-minute"), color = colors.coral) {
                            val challenge = MahjMinuteContent.challenge(today)
                            navigator.push(Route.Session(challenge.items, SessionPurpose.Minute(challenge)))
                        }
                    }
                }
                WeeklyRhythm(minOf(graph.minutes.completedThisWeek(), 5))
                Eyebrow("ARCHIVE", modifier = Modifier.padding(horizontal = 4.dp))
                val dates = graph.minutes.archiveDates()
                Column(Modifier.fillMaxWidth().themedCard(16.dp)) {
                    dates.forEachIndexed { index, date ->
                        ArchiveRow(date, graph.minutes.result(date))
                        if (index < dates.lastIndex) Box(Modifier.fillMaxWidth().height(1.dp).background(colors.rule))
                    }
                }
            }
        }
    }
}

@Composable
private fun WeeklyRhythm(completed: Int) {
    val colors = Mahj.colors
    Column(Modifier.fillMaxWidth().themedCard(16.dp).padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Eyebrow("YOUR WEEK")
                Text(if (completed >= 5) "Weekly goal complete" else "$completed of 5 practiced", style = MahjType.headline, color = colors.ink)
            }
            Icon(
                symbol(if (completed >= 5) "checkmark.seal.fill" else "calendar"),
                null,
                tint = if (completed >= 5) colors.jade else colors.coral,
                modifier = Modifier.size(22.dp),
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            repeat(5) { index ->
                val done = index < completed
                Box(Modifier.size(34.dp).background(if (done) colors.coral else colors.well, CircleShape), contentAlignment = Alignment.Center) {
                    if (done) Icon(symbol("checkmark.circle.fill"), null, tint = Color.White, modifier = Modifier.size(16.dp))
                }
            }
        }
        Text("Any five days count. Miss one, catch up from the archive, and keep the week alive.", style = MahjType.caption, color = colors.inkSecondary)
    }
}

private val archiveFormat = DateTimeFormatter.ofPattern("EEEE, MMM d", Locale.getDefault())

@Composable
private fun ArchiveRow(date: LocalDate, result: MahjMinuteResult?) {
    val navigator = LocalNavigator.current
    val colors = Mahj.colors
    val tint = if (result == null) colors.coral else colors.jade
    Row(
        Modifier.fillMaxWidth().pressable {
            if (result != null) {
                navigator.push(Route.MinuteResult(result))
            } else {
                val challenge = MahjMinuteContent.challenge(date)
                navigator.push(Route.Session(challenge.items, SessionPurpose.Minute(challenge)))
            }
        }.padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(symbol(if (result == null) "play.circle" else "checkmark.circle.fill"), null, tint = tint, modifier = Modifier.width(28.dp).size(22.dp))
        Text(date.format(archiveFormat), style = MahjType.subheadline.copy(fontWeight = FontWeight.Medium), color = colors.ink, modifier = Modifier.weight(1f))
        Text(result?.let { "${it.score}/${it.total}" } ?: "Play", style = MahjType.subheadline.copy(fontWeight = FontWeight.SemiBold), color = tint)
        Icon(symbol("chevron.right"), null, tint = colors.inkTertiary, modifier = Modifier.size(16.dp))
    }
}

@Composable
fun MahjMinuteResultScreen(result: MahjMinuteResult, recordsCompletion: Boolean = false, onDone: (() -> Unit)? = null) {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val actions = LocalAppActions.current
    val context = LocalContext.current
    val colors = Mahj.colors
    val done = onDone ?: { navigator.pop(); Unit }
    var recorded by rememberSaveable { mutableStateOf(false) }
    var confetti by remember { mutableIntStateOf(0) }
    LaunchedEffect(Unit) {
        if (!recordsCompletion || recorded) return@LaunchedEffect
        recorded = true
        confetti += 1
        Haptics.success()
        SoundPlayer.play(SoundPlayer.Effect.COMPLETE)
        graph.progress.recordSession(MahjMinuteContent.drill.id)
        actions.positiveMoment()
    }
    MahjScreen("Mahj Minute", onBack = if (recordsCompletion) null else done) {
        Box(Modifier.fillMaxSize()) {
            Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState()), maxWidth = 620.dp) {
                Column(Modifier.padding(16.dp).padding(navBarPadding()), verticalArrangement = Arrangement.spacedBy(18.dp)) {
                    Column(
                        Modifier.fillMaxWidth().themedCard().padding(20.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Box(Modifier.size(122.dp).background(colors.jade.copy(alpha = 0.12f), CircleShape), contentAlignment = Alignment.Center) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text("${result.score}/${result.total}", style = MahjType.display(34.sp), color = colors.jade, modifier = Modifier.testTag("minute-score"))
                                Text("right", style = MahjType.caption.copy(fontWeight = FontWeight.SemiBold), color = colors.inkSecondary)
                            }
                        }
                        Text(if (result.score == result.total) "Perfect minute!" else "Minute complete", style = MahjType.display(28.sp), color = colors.ink)
                        Text("Mahj Minute ${result.shortDate}", style = MahjType.subheadline, color = colors.inkSecondary)
                    }
                    Column(Modifier.fillMaxWidth().themedCard(16.dp).padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                        Eyebrow("BY SKILL")
                        MahjMinuteCategory.entries.forEach { category ->
                            val correct = result.correct(category)
                            val total = result.total(category)
                            val tint = when {
                                correct == total -> colors.jade
                                correct > 0 -> colors.gold
                                else -> colors.coral
                            }
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                                Icon(symbol(category.icon), null, tint = tint, modifier = Modifier.width(30.dp).size(22.dp))
                                Text(category.title, style = MahjType.subheadline.copy(fontWeight = FontWeight.SemiBold), color = colors.ink, modifier = Modifier.weight(1f))
                                Text("$correct/$total", style = MahjType.subheadline.copy(fontWeight = FontWeight.Bold), color = tint)
                            }
                        }
                    }
                    val completed = minOf(graph.minutes.completedThisWeek(), 5)
                    Row(
                        Modifier.fillMaxWidth().themedCard(16.dp).padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        val tint = if (completed >= 5) colors.jade else colors.coral
                        IconBadge(if (completed >= 5) "checkmark.seal.fill" else "calendar.badge.checkmark", tint, alpha = 0.12f)
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Text(if (completed >= 5) "Weekly goal complete" else "$completed of 5 this week", style = MahjType.headline, color = colors.ink)
                            Text("Any five days keep the rhythm going.", style = MahjType.caption, color = colors.inkSecondary)
                        }
                    }
                    PrimaryCTA("Share Result", color = colors.coral, icon = symbol("square.and.arrow.up")) { context.shareText(result.shareText) }
                    QuietButton("Done", Modifier.fillMaxWidth().testTag("minute-done"), onClick = done)
                    Spacer(Modifier.height(4.dp))
                }
            }
            ConfettiBurst(confetti, origin = Offset(0.5f, 0.22f), particleCount = 44)
        }
    }
}
