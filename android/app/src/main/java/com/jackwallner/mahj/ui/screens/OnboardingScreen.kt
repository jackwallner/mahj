package com.jackwallner.mahj.ui.screens

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.togetherWith
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
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.mahj.data.Membership
import com.jackwallner.mahj.data.PaywallPlan
import com.jackwallner.mahj.data.PaywallPricing
import com.jackwallner.mahj.data.PurchaseException
import com.jackwallner.mahj.data.PurchaseOutcome
import com.jackwallner.mahj.data.StoreLinks
import com.jackwallner.mahj.data.TrialPolicy
import com.jackwallner.mahj.model.Dragon
import com.jackwallner.mahj.model.Tile
import com.jackwallner.mahj.ui.LocalGraph
import com.jackwallner.mahj.ui.components.TileRack
import com.jackwallner.mahj.ui.components.symbol
import com.jackwallner.mahj.ui.findActivity
import com.jackwallner.mahj.ui.openUrl
import com.jackwallner.mahj.ui.theme.Haptics
import com.jackwallner.mahj.ui.theme.IconBadge
import com.jackwallner.mahj.ui.theme.Mahj
import com.jackwallner.mahj.ui.theme.MahjAlert
import com.jackwallner.mahj.ui.theme.MahjSheet
import com.jackwallner.mahj.ui.theme.MahjType
import com.jackwallner.mahj.ui.theme.PrimaryCTA
import com.jackwallner.mahj.ui.theme.Readable
import com.jackwallner.mahj.ui.theme.pressable
import com.jackwallner.mahj.ui.theme.rounded
import kotlinx.coroutines.launch

private enum class Stage { PAGES, HOW_TO_PLAY, TOUR }

private const val LAST_PAGE = 4
private const val SKILL_PAGE = 3

private data class SkillOption(val id: String, val title: String, val detail: String)

private val skillOptions = listOf(
    SkillOption("new", "Brand new", "Still learning what the tiles even are"),
    SkillOption("basics", "Know the basics", "Met the tiles, still slow on the card"),
    SkillOption("played", "Played real games", "Comfortable, want sharper instincts"),
)

/**
 * Three value pages, the skill question, then the trial step. The primary
 * button keeps identical geometry on every page, so on the last page the
 * same button becomes the trial CTA: one tap straight to Google Play. The
 * plan-picker paywall is only a fallback for products that failed to load.
 * Afterwards brand-new players get the primer, then everyone gets the tour.
 */
@Composable
fun OnboardingScreen() {
    val graph = LocalGraph.current
    var stage by rememberSaveable { mutableStateOf(Stage.PAGES) }
    var skillLevel by rememberSaveable { mutableStateOf(graph.defaults.getString(SKILL_LEVEL).orEmpty()) }

    fun finish() {
        // A new player has never run an older version, so there is nothing "new" to tell them.
        graph.whatsNew.markCurrentAsBaseline()
        graph.progress.setOnboarded(true)
    }

    fun startTour() {
        stage = if (skillLevel == "new") Stage.HOW_TO_PLAY else Stage.TOUR
    }

    AnimatedContent(
        stage,
        transitionSpec = { (slideInHorizontally(tween(350)) { it } + fadeIn()) togetherWith fadeOut(tween(250)) },
        label = "onboarding",
    ) { current ->
        when (current) {
            Stage.PAGES -> OnboardingPages(skillLevel, onSkill = {
                skillLevel = it
                graph.defaults.putString(SKILL_LEVEL, it)
            }, onDone = ::startTour)
            // Skip lands on Home: the escape hatch escapes.
            Stage.HOW_TO_PLAY -> HowToPlayScreen(onDone = { stage = Stage.TOUR }, onSkip = ::finish)
            Stage.TOUR -> FeatureTourScreen(onDone = ::finish)
        }
    }
}

@Composable
private fun OnboardingPages(skillLevel: String, onSkill: (String) -> Unit, onDone: () -> Unit) {
    // Read through state so the button handlers never act on a stale choice.
    val currentSkill by rememberUpdatedState(skillLevel)
    val graph = LocalGraph.current
    val service = graph.subscriptions
    val context = LocalContext.current
    val colors = Mahj.colors
    val scope = rememberCoroutineScope()
    val pager = rememberPagerState { LAST_PAGE + 1 }
    var purchasing by remember { mutableStateOf(false) }
    var restoring by remember { mutableStateOf(false) }
    var showFallback by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val page = pager.currentPage
    val onTrialPage = page == LAST_PAGE
    val isPro = service.isPro

    LaunchedEffect(page) {
        if (page == LAST_PAGE) service.trackPaywallImpression("mahj_onboarding_trial", oncePerSession = true)
    }
    // A purchase in the fallback paywall rejoins onboarding rather than stranding the player.
    LaunchedEffect(isPro, showFallback) { if (isPro && showFallback) { showFallback = false; onDone() } }

    fun primaryAction() {
        // targetPage, not currentPage: a quick second tap mid-animation must still advance.
        val target = pager.targetPage
        if (target < LAST_PAGE) {
            if (target == SKILL_PAGE && currentSkill.isEmpty()) return
            scope.launch { pager.animateScrollToPage(target + 1) }
            return
        }
        // Already a member (a reinstall, or another device on the same account): nothing to sell.
        if (isPro) {
            onDone()
            return
        }
        val activity = context.findActivity() ?: return
        purchasing = true
        scope.launch {
            try {
                service.ensureOfferings()
                // Monthly here on purpose; the paywall still leads with yearly. The disclosure names this same plan.
                val monthly = service.packageFor(PaywallPlan.MONTHLY)
                if (monthly == null) {
                    showFallback = true
                    return@launch
                }
                when (service.purchase(activity, monthly)) {
                    PurchaseOutcome.PURCHASED -> if (service.confirmEntitlement()) onDone()
                    else error = "Your purchase went through, but ${Membership.NAME} hasn't unlocked yet. Give it a moment, then tap Restore."
                    PurchaseOutcome.PENDING -> error = "Google Play is still processing your payment. ${Membership.NAME} unlocks as soon as it completes."
                    // They said no to Google Play, not to the app. Stay put.
                    PurchaseOutcome.CANCELLED -> Unit
                }
            } catch (failure: PurchaseException) {
                error = failure.message
            } finally {
                purchasing = false
            }
        }
    }

    fun restore() {
        if (restoring || purchasing) return
        restoring = true
        scope.launch {
            try {
                service.restore()
                if (service.isPro) onDone() else error = "No previous purchase found on this Google account."
            } catch (failure: PurchaseException) {
                error = failure.message
            } finally {
                restoring = false
            }
        }
    }

    Column(Modifier.fillMaxSize().background(colors.background).statusBarsPadding().navigationBarsPadding()) {
        HorizontalPager(
            pager,
            modifier = Modifier.fillMaxWidth().weight(1f),
            userScrollEnabled = !(page == SKILL_PAGE && skillLevel.isEmpty()),
        ) { index ->
            Readable(Modifier.fillMaxSize()) {
                when (index) {
                    0 -> InfoPage(
                        "square.grid.3x3.fill",
                        "Make it stick between games",
                        "Mah Jongg fades fast between games. Mahj Trainer gives you five-minute drills you can run anywhere, whether you are still meeting the tiles or sharpening instincts you already have.",
                        listOf(Tile.c(2), Tile.DragonTile(Dragon.SOAP), Tile.c(2), Tile.b(6)),
                    )
                    1 -> InfoPage(
                        "rectangle.stack.fill",
                        "Practice, not pressure",
                        "Swipe through flashcards, read racks, make keep-or-throw calls, and pick your Charleston pass, with the why behind every answer.",
                        listOf(Tile.b(4), Tile.b(5), Tile.b(6), Tile.Joker),
                    )
                    2 -> InfoPage(
                        "figure.walk",
                        "Walk in confident",
                        "Know which dragon matches which suit, spot your section fast, and stop dreading the Charleston. Practice at your own pace, with no opponents and no required timers.",
                        listOf(Tile.DragonTile(Dragon.RED), Tile.DragonTile(Dragon.GREEN), Tile.Flower),
                    )
                    3 -> SkillPage(skillLevel, onSkill)
                    else -> TrialPage(service.hasSubscriptionHistory)
                }
            }
        }
        Readable {
            Column(
                Modifier.padding(horizontal = 24.dp).padding(bottom = 10.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Dots(LAST_PAGE + 1, page, Modifier.padding(bottom = 2.dp))
                // Soft free exit above the primary, reserved on every page so nothing shifts.
                Box(Modifier.height(30.dp).graphicsLayer { alpha = if (onTrialPage && !isPro) 1f else 0f }, contentAlignment = Alignment.Center) {
                    Text(
                        "Get Started",
                        style = MahjType.subheadline.copy(fontWeight = FontWeight.Medium),
                        color = colors.inkSecondary,
                        modifier = Modifier.testTag("soft-exit").pressable(enabled = onTrialPage && !isPro && !purchasing && !restoring) { onDone() }.padding(horizontal = 12.dp, vertical = 4.dp),
                    )
                }
                // The billed amount is the most conspicuous pricing element; the slot is reserved on every page.
                Column(
                    Modifier.heightIn(min = 48.dp).graphicsLayer { alpha = if (onTrialPage) 1f else 0f },
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(2.dp),
                ) {
                    Text(if (isPro) "" else PaywallPricing.priceText(service, PaywallPlan.MONTHLY), style = MahjType.display(22.sp), color = colors.ink)
                    Text(
                        if (isPro) "" else PaywallPricing.terms(service, PaywallPlan.MONTHLY),
                        style = MahjType.caption2,
                        color = colors.inkTertiary,
                        textAlign = TextAlign.Center,
                    )
                }
                PrimaryCTA(
                    if (onTrialPage) (if (isPro) "Continue" else TrialPolicy.cta(PaywallPlan.MONTHLY, service.hasSubscriptionHistory, onboarding = true)) else "Continue",
                    Modifier.testTag("onboarding-primary"),
                    enabled = !purchasing && !restoring && !(page == SKILL_PAGE && skillLevel.isEmpty()),
                    loading = purchasing || restoring,
                    dimmed = page == SKILL_PAGE && skillLevel.isEmpty(),
                    onClick = { primaryAction() },
                )
                Row(
                    Modifier.height(24.dp).graphicsLayer { alpha = if (onTrialPage && !isPro) 1f else 0f },
                    horizontalArrangement = Arrangement.spacedBy(14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    val active = onTrialPage && !isPro && !purchasing && !restoring
                    LegalLink("Terms", active) { context.openUrl(StoreLinks.TERMS_URL) }
                    LegalLink("Privacy", active) { context.openUrl(StoreLinks.PRIVACY_URL) }
                    LegalLink("Restore", active) { restore() }
                }
            }
        }
    }
    MahjSheet(showFallback, onDismiss = { showFallback = false }) {
        PaywallSheet("mahj_onboarding_fallback", onClose = { showFallback = false })
    }
    error?.let { MahjAlert("Mahj Trainer", it, onConfirm = { error = null }) }
}

@Composable
private fun LegalLink(text: String, enabled: Boolean, onClick: () -> Unit) {
    Text(text, style = MahjType.caption2, color = Mahj.colors.inkTertiary, modifier = Modifier.pressable(enabled = enabled, onClick = onClick).padding(4.dp))
}

@Composable
private fun InfoPage(icon: String, title: String, body: String, tiles: List<Tile>) {
    val colors = Mahj.colors
    Column(
        Modifier.fillMaxSize().padding(horizontal = 28.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(26.dp, Alignment.CenterVertically),
    ) {
        IconBadge(icon, colors.jade, size = 92.dp, iconSize = 42.dp, alpha = 0.12f)
        Text(title, style = MahjType.display(32.sp), color = colors.ink, textAlign = TextAlign.Center)
        TileRack(tiles, tileWidth = 54.dp)
        Text(body, style = MahjType.body, color = colors.inkSecondary, textAlign = TextAlign.Center)
        Spacer(Modifier.height(40.dp))
    }
}

@Composable
private fun SkillPage(selected: String, onSelect: (String) -> Unit) {
    val colors = Mahj.colors
    Column(
        Modifier.fillMaxSize().padding(horizontal = 28.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(22.dp, Alignment.CenterVertically),
    ) {
        Text("Where are you starting from?", style = MahjType.display(30.sp), color = colors.ink, textAlign = TextAlign.Center)
        Text("We'll point you at the right drills.", style = MahjType.subheadline, color = colors.inkSecondary)
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            skillOptions.forEach { option ->
                val isSelected = selected == option.id
                val shape = rounded(16.dp)
                Row(
                    Modifier
                        .fillMaxWidth()
                        .testTag("skill-${option.id}")
                        .semantics { this.selected = isSelected }
                        .pressable {
                            Haptics.light()
                            onSelect(option.id)
                        }
                        .background(if (isSelected) colors.jade.copy(alpha = 0.08f) else colors.card, shape)
                        .border(if (isSelected) 2.dp else 1.dp, if (isSelected) colors.jade else colors.rule, shape)
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                        Text(option.title, style = MahjType.headline, color = colors.ink)
                        Text(option.detail, style = MahjType.subheadline, color = colors.inkSecondary)
                    }
                    Icon(
                        symbol(if (isSelected) "checkmark.circle.fill" else "circle"),
                        null,
                        tint = if (isSelected) colors.jade else colors.inkTertiary,
                        modifier = Modifier.size(24.dp),
                    )
                }
            }
        }
        Text(if (selected.isEmpty()) "Pick one to continue." else " ", style = MahjType.footnote, color = colors.inkSecondary)
        Spacer(Modifier.height(40.dp))
    }
}

@Composable
private fun TrialPage(hasSubscriptionHistory: Boolean) {
    val colors = Mahj.colors
    Column(
        Modifier.fillMaxSize().padding(horizontal = 28.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(22.dp, Alignment.CenterVertically),
    ) {
        IconBadge("sparkles", colors.gold, size = 92.dp, iconSize = 42.dp, alpha = 0.14f)
        Text(if (hasSubscriptionHistory) "Get ${Membership.NAME}" else "Try ${Membership.NAME} free", style = MahjType.display(30.sp), color = colors.ink, textAlign = TextAlign.Center)
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            listOf(
                "Every beginner room is free, forever",
                "Mahj Minute and a personalized Game Night Prep",
                "Endless Practice deals a fresh rack every time",
                "Fix My Mistakes brings back what you miss",
                "Extra sets in all four rooms, plus the Master Tables",
            ).forEach { line ->
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(symbol("checkmark.circle.fill"), null, tint = colors.jade, modifier = Modifier.size(20.dp))
                    Text(line, style = MahjType.subheadline, color = colors.ink)
                }
            }
        }
        Spacer(Modifier.height(40.dp))
    }
}
