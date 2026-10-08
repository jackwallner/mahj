package com.jackwallner.mahj.ui.screens

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.mahj.content.QuickItem
import com.jackwallner.mahj.content.SessionBuilder
import com.jackwallner.mahj.data.Membership
import com.jackwallner.mahj.ui.LocalGraph
import com.jackwallner.mahj.ui.components.ConfettiBurst
import com.jackwallner.mahj.ui.components.shine
import com.jackwallner.mahj.ui.components.symbol
import com.jackwallner.mahj.ui.nav.SessionPurpose
import com.jackwallner.mahj.ui.theme.CenteringScroll
import com.jackwallner.mahj.ui.theme.Haptics
import com.jackwallner.mahj.ui.theme.IconBadge
import com.jackwallner.mahj.ui.theme.Mahj
import com.jackwallner.mahj.ui.theme.MahjType
import com.jackwallner.mahj.ui.theme.PrimaryCTA
import com.jackwallner.mahj.ui.theme.QuietButton
import com.jackwallner.mahj.ui.theme.Readable
import com.jackwallner.mahj.ui.theme.jadeGradient
import com.jackwallner.mahj.ui.theme.pressable
import com.jackwallner.mahj.ui.theme.rounded
import com.jackwallner.mahj.ui.theme.themedCard
import kotlinx.coroutines.delay

private data class TourPage(val eyebrow: String, val title: String, val body: String, val gold: Boolean = false, val hero: @Composable (compact: Boolean) -> Unit)

/**
 * The post-trial tour of where things live. Its finale runs a real Quick
 * Session, and every page offers the escape hatch straight to the app.
 */
@Composable
fun FeatureTourScreen(onDone: () -> Unit) {
    val graph = LocalGraph.current
    val colors = Mahj.colors
    val isPro = graph.subscriptions.isPro
    var index by rememberSaveable { mutableIntStateOf(0) }
    var shineTrigger by remember { mutableIntStateOf(0) }
    var confetti by remember { mutableIntStateOf(0) }
    var session by remember { mutableStateOf<List<QuickItem>?>(null) }

    session?.let { items ->
        SessionScreen(items, SessionPurpose.Quick(isDaily = false), onClose = onDone)
        return
    }

    fun startSession() {
        Haptics.success()
        session = SessionBuilder.quickSession(seen = graph.progress.seenItems, missed = graph.progress.missedItems, includePro = isPro)
    }

    val pages = listOf(
        TourPage(
            "THE ROOMS",
            "Four rooms, four skills",
            "Home is the lobby. Each room holds its own drills: meet the tiles, read the card, run the Charleston, play the table. All four beginner rooms are free, forever.",
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                IconBadge("square.grid.3x3.fill", colors.jade, size = 54.dp, iconSize = 24.dp, corner = 14.dp, alpha = 0.12f)
                IconBadge("menucard.fill", colors.coral, size = 54.dp, iconSize = 24.dp, corner = 14.dp, alpha = 0.12f)
                IconBadge("arrow.left.arrow.right", colors.plum, size = 54.dp, iconSize = 24.dp, corner = 14.dp, alpha = 0.12f)
                IconBadge("person.3.fill", colors.gold, size = 54.dp, iconSize = 24.dp, corner = 14.dp, alpha = 0.12f)
            }
        },
        TourPage(
            "KEEP IT LIT",
            "Streaks make it stick",
            "Finish a drill a day and your streak grows. Anything you miss quietly returns until you own it.",
        ) {
            Row(
                Modifier.background(colors.coral.copy(alpha = 0.10f), CircleShape).padding(horizontal = 18.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Icon(symbol("flame.fill"), null, tint = colors.coral, modifier = Modifier.size(30.dp))
                Text("7-day streak", style = MahjType.display(20.sp), color = colors.ink)
            }
        },
        if (isPro) {
            TourPage(
                "YOURS NOW",
                "${Membership.NAME} is open",
                "Your trial already includes Mahj Minute, personalized Game Night Prep, Endless Practice, the timed challenge, the extra sets in every room, and the Master Tables.",
                gold = true,
            ) { compact -> ProHero(locked = false, compact = compact) }
        } else {
            TourPage(
                "BEHIND THE GOLD DOOR",
                "${Membership.NAME} adds more of it",
                "Mahj Minute gives every member the same daily challenge, Game Night Prep targets your weak spots before you play, and Endless Practice never runs out. Nothing you have now goes away. Unlock any time from Home or Settings.",
                gold = true,
            ) { compact -> ProHero(locked = true, compact = compact) }
        },
        TourPage(
            "YOUR TURN",
            "Let's try a real one",
            "Get Started builds this same five-minute mix any time from Home: exactly what you need next, misses first. Let's run your first one now.",
        ) {
            Row(
                Modifier.fillMaxWidth().pressable { startSession() }.background(jadeGradient(), rounded(16.dp)).padding(16.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text("Get Started", style = MahjType.display(20.sp), color = Color.White)
                    Text("A five-minute mix of what you need next", style = MahjType.caption, color = Color.White.copy(alpha = 0.85f))
                }
                Icon(symbol("play.circle.fill"), null, tint = Color.White, modifier = Modifier.size(34.dp))
            }
        },
    )
    val isLast = index == pages.lastIndex

    LaunchedEffect(index) {
        delay(350)
        shineTrigger += 1
    }

    Box(Modifier.fillMaxSize().background(colors.background)) {
        Readable(Modifier.fillMaxSize()) {
            Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding().padding(16.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
                Dots(pages.size, index, Modifier.align(Alignment.CenterHorizontally).padding(top = 10.dp))
                // Centred when the card fits, scrolling when it does not. Under
                // 420dp (a 640dp phone) the card draws its compact variant so the
                // Mahj+ page is never cut off behind the buttons.
                BoxWithConstraints(Modifier.fillMaxWidth().weight(1f)) {
                    val compact = maxHeight < 460.dp
                    CenteringScroll(Modifier.fillMaxSize()) {
                        AnimatedContent(
                            index,
                            transitionSpec = {
                                (slideInHorizontally(tween(320)) { it } + fadeIn(tween(320))) togetherWith
                                    (slideOutHorizontally(tween(320)) { -it } + fadeOut(tween(320)))
                            },
                            label = "tour",
                        ) { shown ->
                            val page = pages[shown]
                            Column(
                                Modifier.fillMaxWidth().padding(vertical = 12.dp).themedCard(22.dp).shine(shineTrigger, 22.dp).padding(if (compact) 18.dp else 24.dp),
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(if (compact) 12.dp else 16.dp),
                            ) {
                                Text(
                                    page.eyebrow,
                                    style = MahjType.caption.copy(fontWeight = FontWeight.ExtraBold, letterSpacing = 2.sp),
                                    color = if (page.gold) colors.gold else colors.jade,
                                )
                                page.hero(compact)
                                Text(page.title, style = MahjType.display(if (compact) 23.sp else 27.sp), color = colors.ink, textAlign = TextAlign.Center)
                                Text(page.body, style = if (compact) MahjType.subheadline else MahjType.body, color = colors.inkSecondary, textAlign = TextAlign.Center)
                            }
                        }
                    }
                }
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    PrimaryCTA(if (isLast) "Start my first session" else "Show me", Modifier.testTag("tour-primary")) {
                        if (isLast) {
                            startSession()
                        } else {
                            Haptics.soft()
                            index += 1
                            if (pages[index].gold) confetti += 1
                        }
                    }
                    QuietButton(if (isLast) "Skip it, take me to the app" else "Skip the tour", Modifier.testTag("tour-skip")) {
                        Haptics.light()
                        onDone()
                    }
                }
            }
        }
        ConfettiBurst(confetti, origin = Offset(0.5f, 0.35f))
    }
}

@Composable
private fun ProHero(locked: Boolean, compact: Boolean = false) {
    val colors = Mahj.colors
    Column(
        Modifier
            .fillMaxWidth()
            .background(colors.gold.copy(alpha = 0.10f), rounded(16.dp))
            .border(1.5.dp, colors.gold.copy(alpha = 0.4f), rounded(16.dp))
            .padding(if (compact) 12.dp else 16.dp),
        verticalArrangement = Arrangement.spacedBy(if (compact) 6.dp else 8.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Icon(symbol(if (locked) "lock.fill" else "sparkles"), null, tint = colors.gold, modifier = Modifier.size(16.dp))
            Text(Membership.NAME.uppercase(), style = MahjType.caption.copy(fontWeight = FontWeight.ExtraBold, letterSpacing = 1.6.sp), color = colors.gold)
            Spacer(Modifier.weight(1f))
            if (!locked) Icon(symbol("checkmark.seal.fill"), null, tint = colors.jade, modifier = Modifier.size(18.dp))
        }
        listOf(
            "Mahj Minute, one shared daily challenge",
            "Game Night Prep, built around your weak spots",
            "Endless Practice, never repeats",
        ).forEach { line ->
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Icon(symbol(if (locked) "sparkles" else "checkmark.circle.fill"), null, tint = if (locked) colors.gold else colors.jade, modifier = Modifier.size(14.dp))
                Text(line, style = MahjType.subheadline.copy(fontWeight = FontWeight.Medium), color = colors.ink)
            }
        }
    }
}
