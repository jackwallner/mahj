package com.jackwallner.mahj.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.BasicTextField
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
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.ClipboardManager
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.mahj.BuildConfig
import com.jackwallner.mahj.data.Appearance
import com.jackwallner.mahj.data.Membership
import com.jackwallner.mahj.data.PurchaseException
import com.jackwallner.mahj.data.StoreLinks
import com.jackwallner.mahj.ui.LocalAppActions
import com.jackwallner.mahj.ui.LocalGraph
import com.jackwallner.mahj.ui.components.symbol
import com.jackwallner.mahj.ui.nav.LocalNavigator
import com.jackwallner.mahj.ui.nav.Route
import com.jackwallner.mahj.ui.openFeedbackMail
import com.jackwallner.mahj.ui.openPlayListing
import com.jackwallner.mahj.ui.openUrl
import com.jackwallner.mahj.ui.theme.BarTextButton
import com.jackwallner.mahj.ui.theme.FormDivider
import com.jackwallner.mahj.ui.theme.FormRow
import com.jackwallner.mahj.ui.theme.FormSection
import com.jackwallner.mahj.ui.theme.Haptics
import com.jackwallner.mahj.ui.theme.IconBadge
import com.jackwallner.mahj.ui.theme.Mahj
import com.jackwallner.mahj.ui.theme.MahjAlert
import com.jackwallner.mahj.ui.theme.MahjBar
import com.jackwallner.mahj.ui.theme.MahjScreen
import com.jackwallner.mahj.ui.theme.MahjSwitch
import com.jackwallner.mahj.ui.theme.MahjType
import com.jackwallner.mahj.ui.theme.PrimaryCTA
import com.jackwallner.mahj.ui.theme.PlusBadge
import com.jackwallner.mahj.ui.theme.Readable
import com.jackwallner.mahj.ui.theme.Segmented
import com.jackwallner.mahj.ui.theme.TimePickerRow
import com.jackwallner.mahj.ui.theme.navBarPadding
import com.jackwallner.mahj.ui.theme.pressable
import com.jackwallner.mahj.ui.theme.QuietButton
import com.jackwallner.mahj.ui.theme.themedCard
import kotlinx.coroutines.launch

@Composable
fun SettingsScreen(requestNotifications: (onGranted: () -> Unit) -> Unit) {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val actions = LocalAppActions.current
    val context = LocalContext.current
    val colors = Mahj.colors
    val scope = rememberCoroutineScope()
    val settings = graph.settings
    val service = graph.subscriptions
    var restoreMessage by remember { mutableStateOf<String?>(null) }
    var confirmReset by remember { mutableStateOf(false) }

    MahjScreen("Settings", onBack = { navigator.pop() }) {
        Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            Column(Modifier.padding(16.dp).padding(navBarPadding()), verticalArrangement = Arrangement.spacedBy(22.dp)) {
                FormSection("Appearance") {
                    Box(Modifier.padding(12.dp)) {
                        Segmented(Appearance.entries, settings.appearance, { it.displayName }) { settings.updateAppearance(it) }
                    }
                }
                FormSection("Practice") {
                    FormRow("Haptics") { MahjSwitch(settings.hapticsEnabled, "Haptics") { settings.updateHaptics(it) } }
                    FormDivider()
                    FormRow("Sound Effects") { MahjSwitch(settings.soundEnabled, "Sound Effects") { settings.updateSound(it) } }
                    FormDivider()
                    FormRow("Daily Reminder") {
                        MahjSwitch(settings.reminderEnabled, "Daily Reminder") { on ->
                            if (on) requestNotifications { settings.updateReminderEnabled(true) } else settings.updateReminderEnabled(false)
                        }
                    }
                    if (settings.reminderEnabled) {
                        FormDivider()
                        Box(Modifier.padding(horizontal = 16.dp, vertical = 4.dp)) {
                            TimePickerRow("Reminder Time", settings.reminderHour, settings.reminderMinute) { h, m -> settings.updateReminderTime(h, m) }
                        }
                    }
                    if (service.isPro) {
                        FormDivider()
                        FormRow("Game Night Prep", icon = "person.2.fill", onClick = { navigator.push(Route.GameNightPrep) }) { Chevron() }
                    }
                }
                FormSection("Membership") {
                    if (service.isPro) {
                        FormRow("${Membership.NAME} unlocked", icon = "checkmark.seal.fill", tint = colors.jade)
                        FormDivider()
                        FormRow("Manage Subscription", onClick = { context.openUrl(StoreLinks.manageSubscriptionURL(service.activeProductId)) }) { Chevron() }
                    } else {
                        FormRow("Get ${Membership.NAME}", icon = "sparkles", onClick = { actions.openPaywall("mahj_settings_sheet") }) { PlusBadge() }
                    }
                    FormDivider()
                    FormRow("Restore Purchases", tint = colors.jade, onClick = {
                        scope.launch {
                            restoreMessage = try {
                                service.restore()
                                if (service.isPro) "${Membership.NAME} restored!" else "No previous purchase found on this Google account."
                            } catch (error: PurchaseException) {
                                error.message
                            }
                        }
                    })
                }
                FormSection("Your Practice History") {
                    FormRow("Your Progress", icon = "chart.bar.fill", onClick = { navigator.push(Route.Stats) }) { Chevron() }
                    FormDivider()
                    FormRow("Reset Progress", tint = colors.crakRed, onClick = { confirmReset = true })
                }
                FormSection("Support") {
                    FormRow("Reference & Glossary", icon = "book.closed.fill", onClick = { navigator.push(Route.Reference) }) { Chevron() }
                    FormDivider()
                    FormRow("How to Play", icon = "book.fill", onClick = { navigator.push(Route.HowToPlay) }) { Chevron() }
                    if (graph.whatsNew.currentRelease != null) {
                        FormDivider()
                        FormRow("What's New", icon = "sparkle", onClick = { actions.openWhatsNew() })
                    }
                    FormDivider()
                    FormRow("Rate Mahj Trainer", icon = "star.fill", onClick = {
                        graph.review.markOpenedWriteReview()
                        context.openPlayListing()
                    })
                    FormDivider()
                    FormRow("Send Feedback", icon = "envelope.fill", onClick = { actions.openFeedback() })
                }
                FormSection("About") {
                    FormRow("Version") { Text(BuildConfig.VERSION_NAME, style = MahjType.body, color = colors.inkSecondary) }
                    FormDivider()
                    Text(
                        "Mahj Trainer teaches American Mah Jongg skills with original practice hands. It is not affiliated with or endorsed by the National Mah Jongg League. For official hands and values, pick up the current NMJL card.",
                        style = MahjType.footnote,
                        color = colors.inkSecondary,
                        modifier = Modifier.padding(16.dp),
                    )
                }
                if (BuildConfig.DEBUG) {
                    FormSection("Developer") {
                        FormRow("Local ${Membership.NAME} override") {
                            MahjSwitch(service.isPro, "Local override") { service.setLocalOverride(it) }
                        }
                    }
                }
            }
        }
    }

    restoreMessage?.let { MahjAlert("Restore", it, onConfirm = { restoreMessage = null }) }
    if (confirmReset) {
        MahjAlert(
            "Reset all progress?",
            "Your streak, completed drills, and practice history will be cleared. Purchases are not affected.",
            confirmTitle = "Reset",
            destructive = true,
            dismissTitle = "Cancel",
            onConfirm = {
                confirmReset = false
                graph.resetProgress()
            },
            onDismiss = { confirmReset = false },
        )
    }
    if (settings.reminderPermissionDenied) {
        MahjAlert(
            "Notifications are off",
            "Mahj Trainer cannot send reminders until notifications are turned on in Android settings.",
            confirmTitle = "Open Settings",
            dismissTitle = "Not now",
            onConfirm = {
                settings.reminderPermissionDenied = false
                context.startActivity(
                    android.content.Intent(android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, context.packageName),
                )
            },
            onDismiss = { settings.reminderPermissionDenied = false },
        )
    }
}

@Composable
private fun Chevron() {
    Icon(symbol("chevron.right"), null, tint = Mahj.colors.inkTertiary, modifier = Modifier.size(18.dp))
}

/**
 * Shown once on the first launch after an update: what a member already owns,
 * or what the membership would add. One dismiss, at most one soft upgrade.
 */
@Composable
fun WhatsNewSheet(onClose: () -> Unit, onUpgrade: () -> Unit) {
    val graph = LocalGraph.current
    val colors = Mahj.colors
    val release = graph.whatsNew.currentRelease ?: return
    val isPro = graph.subscriptions.isPro
    val hasLocked = !isPro && release.items.any { it.isPlus }
    fun close() {
        graph.whatsNew.markSeen()
        onClose()
    }
    Column(Modifier.fillMaxSize()) {
        MahjBar("", onBack = null, trailing = { BarTextButton("Done", colors.inkSecondary) { close() } }, inSheet = true)
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 20.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("WHAT'S NEW", style = MahjType.eyebrow, color = colors.inkSecondary)
                Text(release.headline, style = MahjType.display(30.sp), color = colors.ink)
                Text("Version ${release.version}", style = MahjType.footnote, color = colors.inkTertiary)
            }
            release.items.forEach { item ->
                val locked = item.isPlus && !isPro
                Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    IconBadge(item.icon, if (locked) colors.gold else colors.jade, size = 42.dp, iconSize = 22.dp, corner = 13.dp)
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text(item.title, style = MahjType.headline, color = colors.ink)
                            if (locked) PlusBadge()
                        }
                        Text(item.body, style = MahjType.subheadline, color = colors.inkSecondary)
                    }
                }
            }
        }
        Column(Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 10.dp).padding(navBarPadding(0.dp)), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            if (hasLocked) {
                PrimaryCTA("Unlock with ${Membership.NAME}", color = colors.gold) {
                    graph.whatsNew.markSeen()
                    onUpgrade()
                }
                QuietButton("Keep practising free", Modifier.fillMaxWidth()) { close() }
            } else {
                PrimaryCTA("Start practising") { close() }
            }
        }
    }
}

/** Feedback goes to a real person through the mail app, and only claims success if one opened. */
@Composable
fun FeedbackSheet(onClose: () -> Unit) {
    val graph = LocalGraph.current
    val context = LocalContext.current
    val clipboard: ClipboardManager = LocalClipboardManager.current
    val colors = Mahj.colors
    var text by remember { mutableStateOf("") }
    var mailFailed by remember { mutableStateOf(false) }
    val focus = remember { FocusRequester() }
    LaunchedEffect(Unit) { focus.requestFocus() }
    val trimmed = text.trim()
    Column(Modifier.fillMaxSize()) {
        MahjBar("Help us improve", onBack = null, leading = { BarTextButton("Not now", colors.inkSecondary, onClick = onClose) }, inSheet = true)
        Column(Modifier.weight(1f).padding(24.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Text("What would make Mahj Trainer better for you?", style = MahjType.headline, color = colors.ink)
            BasicTextField(
                text,
                { text = it },
                textStyle = MahjType.body.copy(color = colors.ink),
                cursorBrush = SolidColor(colors.jade),
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f, fill = false)
                    .testTag("feedback-text")
                    .focusRequester(focus)
                    .themedCard(14.dp)
                    .padding(12.dp),
                minLines = 6,
            )
            if (mailFailed) {
                // Plenty of people have no mail app set up; say so rather than claim it sent.
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("Your mail app didn't open. You can email us directly:", style = MahjType.caption, color = colors.ink)
                    Row(
                        Modifier.testTag("copy-email").pressable {
                            clipboard.setText(AnnotatedString(StoreLinks.FEEDBACK_EMAIL))
                            Haptics.success()
                        }.padding(vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                    ) {
                        Icon(symbol("doc.on.doc"), null, tint = colors.jade, modifier = Modifier.size(14.dp))
                        Text("Copy ${StoreLinks.FEEDBACK_EMAIL}", style = MahjType.caption.copy(fontWeight = FontWeight.SemiBold), color = colors.jade)
                    }
                }
            } else {
                Text("Opens your mail app with a draft to the developer. It goes to a real person.", style = MahjType.caption, color = colors.inkSecondary)
            }
            PrimaryCTA("Send feedback", Modifier.testTag("send-feedback"), enabled = trimmed.isNotEmpty()) {
                if (context.openFeedbackMail(trimmed)) {
                    graph.review.markFeedbackSubmitted()
                    onClose()
                } else {
                    mailFailed = true
                }
            }
        }
    }
}
