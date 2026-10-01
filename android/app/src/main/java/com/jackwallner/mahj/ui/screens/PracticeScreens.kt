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
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.mahj.content.DrillLibrary
import com.jackwallner.mahj.content.PracticeSkill
import com.jackwallner.mahj.content.SessionBuilder
import com.jackwallner.mahj.data.MasteryLevel
import com.jackwallner.mahj.data.PracticeRecordStore
import com.jackwallner.mahj.data.RoomMastery
import com.jackwallner.mahj.ui.LocalGraph
import com.jackwallner.mahj.ui.components.symbol
import com.jackwallner.mahj.ui.nav.LocalNavigator
import com.jackwallner.mahj.ui.nav.PracticeMode
import com.jackwallner.mahj.ui.nav.Route
import com.jackwallner.mahj.ui.nav.SessionPurpose
import com.jackwallner.mahj.ui.theme.CapsuleBar
import com.jackwallner.mahj.ui.theme.DayPickerRow
import com.jackwallner.mahj.ui.theme.MahjSwitch
import com.jackwallner.mahj.ui.theme.TimePickerRow
import com.jackwallner.mahj.ui.theme.Eyebrow
import com.jackwallner.mahj.ui.theme.IconBadge
import com.jackwallner.mahj.ui.theme.Mahj
import com.jackwallner.mahj.ui.theme.MahjScreen
import com.jackwallner.mahj.ui.theme.MahjType
import com.jackwallner.mahj.ui.theme.PrimaryCTA
import com.jackwallner.mahj.ui.theme.Readable
import com.jackwallner.mahj.ui.theme.navBarPadding
import com.jackwallner.mahj.ui.theme.pressable
import com.jackwallner.mahj.ui.theme.rounded
import com.jackwallner.mahj.ui.theme.themedCard
import kotlin.math.roundToInt

private fun percent(fraction: Double) = "${(fraction * 100).roundToInt()}%"

/** One tap between Home and the first dealt hand. */
@Composable
fun EndlessPickerScreen() {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val colors = Mahj.colors
    MahjScreen("Endless Practice", onBack = { navigator.pop() }) {
        Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            Column(Modifier.padding(horizontal = 16.dp).padding(navBarPadding()), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(
                    Modifier.fillMaxWidth().padding(top = 12.dp).background(colors.jade.copy(alpha = 0.10f), rounded(16.dp)).padding(14.dp),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Icon(symbol("infinity"), null, tint = colors.jade, modifier = Modifier.size(20.dp))
                    Text(
                        "Every hand here is dealt fresh the moment you see it, so you can practise for as long as you like without repeating a question.",
                        style = MahjType.subheadline,
                        color = colors.inkSecondary,
                    )
                }
                PracticeSkill.endlessCases.forEach { skill ->
                    val record = graph.records.records[skill.raw]
                    Row(
                        Modifier.fillMaxWidth().testTag("skill-${skill.raw}").pressable {
                            navigator.push(Route.Practice(PracticeMode.Endless(skill)))
                        }.themedCard().padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(14.dp),
                    ) {
                        IconBadge(skill.icon, colors.jade, size = 48.dp, iconSize = 24.dp, corner = 14.dp, alpha = 0.12f)
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                            Text(skill.title, style = MahjType.headline, color = colors.ink)
                            Text(skill.subtitle, style = MahjType.subheadline, color = colors.inkSecondary)
                            if (record != null && record.attempts > 0) {
                                Text("${percent(record.accuracy)} across ${record.attempts} answered", style = MahjType.caption2, color = colors.inkTertiary)
                            }
                        }
                        Icon(symbol("chevron.right"), null, tint = colors.inkTertiary, modifier = Modifier.size(18.dp))
                    }
                }
            }
        }
    }
}

/** Practice history: accuracy, mastery, and the room worth working on next. Free for everyone. */
@Composable
fun StatsScreen() {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val colors = Mahj.colors
    val records = graph.records
    val isPro = graph.subscriptions.isPro
    val roomStats = records.roomStats()
    MahjScreen("Your Progress", onBack = { navigator.pop() }) {
        Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            Column(Modifier.padding(horizontal = 16.dp).padding(navBarPadding()), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                if (records.totalAttempts == 0) {
                    Column(
                        Modifier.fillMaxWidth().padding(top = 12.dp).themedCard().padding(28.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        Icon(symbol("chart.bar.fill"), null, tint = colors.jade.copy(alpha = 0.5f), modifier = Modifier.size(40.dp))
                        Text("No practice yet", style = MahjType.headline, color = colors.ink)
                        Text(
                            "Answer a few questions and your accuracy for every room shows up here.",
                            style = MahjType.subheadline,
                            color = colors.inkSecondary,
                            textAlign = TextAlign.Center,
                        )
                    }
                } else {
                    Row(Modifier.fillMaxWidth().padding(top = 12.dp).themedCard().padding(vertical = 18.dp), verticalAlignment = Alignment.CenterVertically) {
                        StatMetric(percent(records.overallAccuracy), "accuracy", colors.jade, Modifier.weight(1f))
                        Divider()
                        StatMetric("${records.totalAttempts}", "answered", colors.ink, Modifier.weight(1f))
                        Divider()
                        StatMetric("${records.bestChallengeScore}", "best challenge", colors.coral, Modifier.weight(1f))
                    }
                    val focus = records.roomToWorkOn(isPro)
                    val weakest = records.weakestRoom()
                    if (focus != null) {
                        val room = DrillLibrary.room(focus.roomID)
                        FocusCard("Work on ${room?.name ?: "this room"}", "${focus.known} of ${focus.total} questions are holding. ${focus.level.nextStep}")
                    } else if (weakest != null && roomStats.size > 1) {
                        FocusCard("Work on ${weakest.name}", "${percent(weakest.accuracy)} right across ${weakest.attempts} questions, your lowest so far.")
                    }
                    MasteryBreakdown(records.masteryByRoom(isPro).filter { it.total > 0 })
                    AccuracyBreakdown(roomStats)
                }
                Row(
                    Modifier.fillMaxWidth().themedCard(16.dp).padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    IconBadge("flame.fill", colors.coral)
                    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Text("${graph.progress.streakCount}-day streak", style = MahjType.headline, color = colors.ink)
                        val sessions = graph.progress.totalSessions
                        Text("$sessions drill${if (sessions == 1) "" else "s"} finished", style = MahjType.caption, color = colors.inkSecondary)
                    }
                }
            }
        }
    }
}

@Composable
private fun Divider() {
    Box(Modifier.width(1.dp).height(34.dp).background(Mahj.colors.rule))
}

@Composable
private fun StatMetric(value: String, caption: String, color: Color, modifier: Modifier) {
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Text(value, style = MahjType.display(26.sp), color = color)
        Text(caption, style = MahjType.caption, color = Mahj.colors.inkSecondary, textAlign = TextAlign.Center)
    }
}

@Composable
private fun FocusCard(title: String, body: String) {
    val colors = Mahj.colors
    Row(
        Modifier.fillMaxWidth().themedCard(16.dp).padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        IconBadge("target", colors.coral)
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(title, style = MahjType.headline, color = colors.ink)
            Text(body, style = MahjType.caption, color = colors.inkSecondary)
        }
    }
}

@Composable
private fun levelColor(level: MasteryLevel): Color {
    val colors = Mahj.colors
    return when (level) {
        MasteryLevel.UNTOUCHED -> colors.inkTertiary
        MasteryLevel.LEARNING -> colors.coral
        MasteryLevel.SOLID -> colors.gold
        MasteryLevel.SHARP -> colors.bamGreen
    }
}

@Composable
private fun MasteryBreakdown(masteries: List<RoomMastery>) {
    val colors = Mahj.colors
    Column(Modifier.fillMaxWidth().themedCard().padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Eyebrow("WHAT IS HOLDING")
        Text(
            "A question counts here once you have answered it right twice in a row, and drops off if you leave it long enough to go rusty.",
            style = MahjType.caption,
            color = colors.inkTertiary,
        )
        masteries.forEach { mastery ->
            val room = DrillLibrary.room(mastery.roomID) ?: return@forEach
            val tint = levelColor(mastery.level)
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(room.name, style = MahjType.subheadline.copy(fontWeight = FontWeight.SemiBold), color = colors.ink, modifier = Modifier.weight(1f))
                    Icon(symbol(mastery.level.icon), null, tint = tint, modifier = Modifier.size(12.dp))
                    Text(" ${mastery.level.title}", style = MahjType.caption.copy(fontWeight = FontWeight.Bold), color = tint)
                }
                CapsuleBar(mastery.fraction.toFloat(), tint)
                Text("${mastery.known} of ${mastery.total} questions solid", style = MahjType.caption2, color = colors.inkTertiary)
            }
        }
    }
}

@Composable
private fun AccuracyBreakdown(stats: List<PracticeRecordStore.RoomStat>) {
    val colors = Mahj.colors
    Column(Modifier.fillMaxWidth().themedCard().padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Eyebrow("ACCURACY BY ROOM")
        stats.forEach { stat ->
            val tint = when {
                stat.accuracy >= 0.8 -> colors.bamGreen
                stat.accuracy >= 0.6 -> colors.gold
                else -> colors.coral
            }
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Row {
                    Text(stat.name, style = MahjType.subheadline.copy(fontWeight = FontWeight.SemiBold), color = colors.ink, modifier = Modifier.weight(1f))
                    Text(percent(stat.accuracy), style = MahjType.subheadline.copy(fontWeight = FontWeight.Bold), color = tint)
                }
                CapsuleBar(stat.accuracy.toFloat(), tint)
                Text("${stat.correct} of ${stat.attempts} right", style = MahjType.caption2, color = colors.inkTertiary)
            }
        }
    }
}

/** The weekly game-night reminder and the personalised prep session. */
@Composable
fun GameNightPrepScreen(requestNotifications: (onGranted: () -> Unit) -> Unit) {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val colors = Mahj.colors
    val settings = graph.settings
    val records = graph.records
    val reviewable = SessionBuilder.reviewableIDs(true)
    MahjScreen("Game Night Prep", onBack = { navigator.pop() }) {
        Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            Column(Modifier.padding(16.dp).padding(navBarPadding()), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Column(
                    Modifier.fillMaxWidth().themedCard().padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    IconBadge("person.2.fill", colors.plum, size = 68.dp, iconSize = 30.dp)
                    Text("Walk in ready", style = MahjType.display(28.sp), color = colors.ink)
                    Text(
                        "Set your usual game night. The reminder opens a fresh session built from your mistakes, weakest room, and material you have not seen yet.",
                        style = MahjType.subheadline,
                        color = colors.inkSecondary,
                        textAlign = TextAlign.Center,
                    )
                }
                Column(Modifier.fillMaxWidth().themedCard(16.dp).padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Eyebrow("WEEKLY REMINDER")
                            Text(
                                if (settings.gameNightReminderEnabled) "Prep is scheduled" else "Choose your game night",
                                style = MahjType.headline,
                                color = colors.ink,
                            )
                        }
                        MahjSwitch(settings.gameNightReminderEnabled, "Weekly game night reminder") { on ->
                            if (on) requestNotifications { settings.updateGameNightReminderEnabled(true) }
                            else settings.updateGameNightReminderEnabled(false)
                        }
                    }
                    Box(Modifier.fillMaxWidth().height(1.dp).background(colors.rule))
                    DayPickerRow(settings.gameNightDay) { settings.updateGameNightDay(it) }
                    TimePickerRow("Prep Reminder", settings.gameNightHour, settings.gameNightMinute) { hour, minute ->
                        settings.updateGameNightTime(hour, minute)
                    }
                    Text(
                        "At that time each ${settings.gameNightDay.displayName}, the notification opens directly into your personalized practice session.",
                        style = MahjType.caption,
                        color = colors.inkSecondary,
                    )
                }
                val weakest = records.weakestRoom()
                val due = records.dueCount(reviewable)
                val copy = when {
                    due > 0 && weakest != null -> "$due due mistake${if (due == 1) "" else "s"} first, then extra work in ${weakest.name}."
                    due > 0 -> "$due due mistake${if (due == 1) "" else "s"} first, followed by material you have not seen yet."
                    weakest != null -> "Extra work in ${weakest.name}, followed by a balanced mix from the other rooms."
                    else -> "A balanced member mix now. As you answer more questions, this session will zero in on your real weak spots."
                }
                Row(Modifier.fillMaxWidth().themedCard(16.dp).padding(16.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    IconBadge("scope", colors.coral, size = 40.dp)
                    Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                        Text("What today's prep targets", style = MahjType.headline, color = colors.ink)
                        Text(copy, style = MahjType.subheadline, color = colors.inkSecondary)
                    }
                }
                PrimaryCTA("Start My Five-Minute Prep", Modifier.testTag("start-prep"), color = colors.plum) {
                    navigator.push(Route.Session(gameNightPrepItems(graph), SessionPurpose.GameNightPrep))
                }
                Spacer(Modifier.height(4.dp))
            }
        }
    }
}

fun gameNightPrepItems(graph: com.jackwallner.mahj.AppGraph) = SessionBuilder.gameNightPrep(
    seen = graph.progress.seenItems,
    missed = graph.progress.missedItems,
    dueIDs = graph.records.reviewQueue(presentable = SessionBuilder.reviewableIDs(true)),
    weakestRoomID = graph.records.weakestRoom()?.id,
)
