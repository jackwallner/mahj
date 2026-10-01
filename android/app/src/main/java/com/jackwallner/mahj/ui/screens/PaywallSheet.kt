package com.jackwallner.mahj.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
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
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.mahj.data.Membership
import com.jackwallner.mahj.data.PaywallPlan
import com.jackwallner.mahj.data.PaywallPricing
import com.jackwallner.mahj.data.PurchaseException
import com.jackwallner.mahj.data.PurchaseOutcome
import com.jackwallner.mahj.data.StoreLinks
import com.jackwallner.mahj.data.SubscriptionService
import com.jackwallner.mahj.ui.LocalGraph
import com.jackwallner.mahj.ui.components.symbol
import com.jackwallner.mahj.ui.findActivity
import com.jackwallner.mahj.ui.openUrl
import com.jackwallner.mahj.ui.theme.BarTextButton
import com.jackwallner.mahj.ui.theme.Haptics
import com.jackwallner.mahj.ui.theme.Mahj
import com.jackwallner.mahj.ui.theme.MahjAlert
import com.jackwallner.mahj.ui.theme.MahjBar
import com.jackwallner.mahj.ui.theme.MahjType
import com.jackwallner.mahj.ui.theme.PrimaryCTA
import com.jackwallner.mahj.ui.theme.Readable
import com.jackwallner.mahj.ui.theme.pressable
import com.jackwallner.mahj.ui.theme.rounded
import kotlinx.coroutines.launch

/**
 * The plan-picker paywall (locked drills and rooms, Settings, the onboarding
 * fallback). The purchase screen always states the membership name, each
 * plan's price and period, that it renews and how to cancel, Restore, Terms
 * and Privacy. Yearly leads; monthly sits directly under it so the discount
 * reads as one.
 */
@Composable
fun PaywallSheet(source: String, onClose: () -> Unit) {
    val graph = LocalGraph.current
    val service = graph.subscriptions
    val context = LocalContext.current
    val colors = Mahj.colors
    val scope = rememberCoroutineScope()
    var plan by remember { mutableStateOf(PaywallPlan.YEARLY) }
    var purchasing by remember { mutableStateOf(false) }
    var restoring by remember { mutableStateOf(false) }
    var loading by remember { mutableStateOf(false) }
    var attempted by remember { mutableStateOf(false) }
    var message by remember { mutableStateOf<String?>(null) }
    val priceReady = PaywallPricing.price(service, plan) != null

    suspend fun loadPrices() {
        if (loading) return
        loading = true
        service.loadOfferings()
        loading = false
        attempted = true
    }

    LaunchedEffect(Unit) {
        service.trackPaywallImpression(source)
        if (!priceReady) loadPrices() else attempted = true
    }
    LaunchedEffect(service.isPro) { if (service.isPro) onClose() }

    Column(Modifier.fillMaxSize()) {
        MahjBar("", onBack = null, leading = { BarTextButton("Close", colors.inkSecondary, onClick = onClose) }, inSheet = true)
        Readable(Modifier.weight(1f).verticalScroll(rememberScrollState()), maxWidth = 680.dp) {
            PaywallContent(service, plan) { plan = it }
        }
        Column(
            Modifier.fillMaxWidth().background(colors.card).navigationBarsPadding().padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            if (attempted && !priceReady && !loading) {
                Text(
                    "Prices aren't available right now. Check your connection and try again.",
                    style = MahjType.caption,
                    color = colors.inkSecondary,
                    textAlign = TextAlign.Center,
                )
                Text(
                    "Retry loading prices",
                    style = MahjType.subheadline.copy(fontWeight = FontWeight.SemiBold),
                    color = colors.jade,
                    modifier = Modifier.pressable { scope.launch { loadPrices() } }.padding(4.dp),
                )
            }
            Text(PaywallPricing.terms(service, plan), style = MahjType.caption, color = colors.inkSecondary, textAlign = TextAlign.Center)
            PrimaryCTA(
                plan.ctaTitle,
                Modifier.testTag("paywall-cta"),
                enabled = priceReady && !purchasing && !restoring,
                loading = purchasing || loading || (!attempted && !priceReady),
                dimmed = !priceReady,
            ) {
                val activity = context.findActivity() ?: return@PrimaryCTA
                purchasing = true
                scope.launch {
                    try {
                        service.ensureOfferings()
                        val outcome = service.purchase(activity, service.packageFor(plan))
                        if (outcome == PurchaseOutcome.PURCHASED) {
                            Haptics.success()
                            if (!service.confirmEntitlement()) {
                                message = "Your purchase went through, but ${Membership.NAME} hasn't unlocked yet. Give it a moment, then tap Restore. You will not be charged twice."
                            }
                        } else if (outcome == PurchaseOutcome.PENDING) {
                            message = "Google Play is still processing your payment. ${Membership.NAME} unlocks as soon as it completes."
                        }
                    } catch (error: PurchaseException) {
                        message = error.message
                    } finally {
                        purchasing = false
                    }
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                FooterLink("Restore", enabled = !restoring && !purchasing) {
                    restoring = true
                    scope.launch {
                        try {
                            service.restore()
                            if (!service.isPro) message = "No previous purchase found on this Google account."
                        } catch (error: PurchaseException) {
                            message = error.message
                        } finally {
                            restoring = false
                        }
                    }
                }
                FooterLink("Terms of Use") { context.openUrl(StoreLinks.TERMS_URL) }
                FooterLink("Privacy Policy") { context.openUrl(StoreLinks.PRIVACY_URL) }
            }
        }
    }
    message?.let { MahjAlert("Mahj Trainer", it, onConfirm = { message = null }) }
}

@Composable
private fun FooterLink(text: String, enabled: Boolean = true, onClick: () -> Unit) {
    Text(
        text,
        style = MahjType.caption,
        color = Mahj.colors.inkSecondary,
        modifier = Modifier.pressable(enabled = enabled, onClick = onClick).padding(vertical = 6.dp),
    )
}

/** The benefits and the three plan cards. */
@Composable
fun PaywallContent(service: SubscriptionService, selected: PaywallPlan, onSelect: (PaywallPlan) -> Unit) {
    val colors = Mahj.colors
    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text("Get ${Membership.NAME}", style = MahjType.display(28.sp), color = colors.ink)
            Text(
                "Everything you have stays free. ${Membership.NAME} adds a smarter practice rhythm that never runs out.",
                style = MahjType.subheadline,
                color = colors.inkSecondary,
                textAlign = TextAlign.Center,
            )
        }
        Column(verticalArrangement = Arrangement.spacedBy(9.dp)) {
            listOf(
                "Play a Hand: deal, commit, and play it out as often as you like",
                "Mahj Minute: the shared five-question daily challenge",
                "Game Night Prep: five minutes built around your weak spots",
                "Endless Practice: fresh racks, passes and defensive calls, forever",
                "Fix My Mistakes: misses come back until they stick",
                "Timed Challenge: 90 seconds, chase your best",
                "Extra practice sets in every room, plus the Master Tables",
            ).forEach { benefit ->
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(symbol("checkmark.circle.fill"), null, tint = colors.jade, modifier = Modifier.size(20.dp))
                    Text(benefit, style = MahjType.subheadline, color = colors.ink)
                }
            }
        }
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            PlanCard(
                PaywallPlan.YEARLY, "Yearly", PaywallPricing.priceText(service, PaywallPlan.YEARLY),
                perMonth = PaywallPricing.perMonthEquivalent(service), anchor = PaywallPricing.monthlyAnchor(service),
                detail = "7 days free, then billed yearly. Auto-renews.", badge = PaywallPricing.savingsBadge(service),
                selected = selected == PaywallPlan.YEARLY, onSelect = onSelect,
            )
            PlanCard(
                PaywallPlan.MONTHLY, "Monthly", PaywallPricing.priceText(service, PaywallPlan.MONTHLY),
                perMonth = null, anchor = null, detail = "7 days free, then billed monthly. Auto-renews.", badge = null,
                selected = selected == PaywallPlan.MONTHLY, onSelect = onSelect,
            )
            PlanCard(
                PaywallPlan.LIFETIME, "Lifetime", PaywallPricing.priceText(service, PaywallPlan.LIFETIME),
                perMonth = null, anchor = null, detail = "One payment. No subscription, nothing renews.", badge = "NO SUBSCRIPTION",
                selected = selected == PaywallPlan.LIFETIME, onSelect = onSelect,
            )
        }
    }
}

@Composable
private fun PlanCard(
    plan: PaywallPlan,
    title: String,
    price: String,
    perMonth: String?,
    anchor: String?,
    detail: String,
    badge: String?,
    selected: Boolean,
    onSelect: (PaywallPlan) -> Unit,
) {
    val colors = Mahj.colors
    val shape = rounded(14.dp)
    Row(
        Modifier
            .fillMaxWidth()
            .testTag("plan-${plan.name.lowercase()}")
            .semantics(mergeDescendants = true) {
                contentDescription = "$title, $price. $detail"
                this.selected = selected
            }
            .pressable {
                Haptics.light()
                onSelect(plan)
            }
            .background(if (selected) colors.jade.copy(alpha = 0.08f) else colors.card, shape)
            .border(if (selected) 2.dp else 1.dp, if (selected) colors.jade else colors.rule, shape)
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(title, style = MahjType.headline, color = colors.ink)
                if (badge != null) {
                    Text(
                        badge,
                        style = MahjType.caption2.copy(fontWeight = FontWeight.Bold),
                        color = colors.gold,
                        modifier = Modifier.background(colors.gold.copy(alpha = 0.18f), CircleShape).padding(horizontal = 6.dp, vertical = 2.dp),
                    )
                }
            }
            Text(detail, style = MahjType.caption, color = colors.inkSecondary)
        }
        Spacer(Modifier.size(8.dp))
        Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(1.dp)) {
            Text(price, style = MahjType.subheadline.copy(fontWeight = FontWeight.SemiBold), color = colors.ink)
            if (perMonth != null) {
                Row(horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                    if (anchor != null) {
                        Text(anchor, style = MahjType.caption2.copy(textDecoration = TextDecoration.LineThrough), color = colors.inkTertiary)
                    }
                    Text(perMonth, style = MahjType.caption2, color = colors.inkSecondary)
                }
            }
        }
    }
}
