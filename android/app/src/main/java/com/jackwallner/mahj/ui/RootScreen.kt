package com.jackwallner.mahj.ui

import android.Manifest
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.viewmodel.compose.viewModel
import com.google.android.play.core.review.ReviewManagerFactory
import com.jackwallner.mahj.AppGraph
import com.jackwallner.mahj.data.AlarmReminderScheduler
import com.jackwallner.mahj.ui.nav.LocalNavigator
import com.jackwallner.mahj.ui.nav.NavStack
import com.jackwallner.mahj.ui.nav.NavigationViewModel
import com.jackwallner.mahj.ui.nav.Route
import com.jackwallner.mahj.ui.nav.SessionPurpose
import com.jackwallner.mahj.ui.screens.DrillScreen
import com.jackwallner.mahj.ui.screens.EndlessPickerScreen
import com.jackwallner.mahj.ui.screens.FeedbackSheet
import com.jackwallner.mahj.ui.screens.GameNightPrepScreen
import com.jackwallner.mahj.ui.screens.HandPlayScreen
import com.jackwallner.mahj.ui.screens.HomeScreen
import com.jackwallner.mahj.ui.screens.HowToPlayScreen
import com.jackwallner.mahj.ui.screens.MahjMinuteResultScreen
import com.jackwallner.mahj.ui.screens.MahjMinuteScreen
import com.jackwallner.mahj.ui.screens.OnboardingScreen
import com.jackwallner.mahj.ui.screens.PaywallSheet
import com.jackwallner.mahj.ui.screens.PracticeRunScreen
import com.jackwallner.mahj.ui.screens.ReferenceScreen
import com.jackwallner.mahj.ui.screens.RoomScreen
import com.jackwallner.mahj.ui.screens.SessionScreen
import com.jackwallner.mahj.ui.screens.SettingsScreen
import com.jackwallner.mahj.ui.screens.StatsScreen
import com.jackwallner.mahj.ui.screens.WhatsNewSheet
import com.jackwallner.mahj.ui.screens.gameNightPrepItems
import com.jackwallner.mahj.ui.theme.MahjAlert
import com.jackwallner.mahj.ui.theme.MahjSheet
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Branches onboarding vs Home on `hasOnboarded` (a branch, never a cover, so
 * Home never flashes behind onboarding), and owns the app-wide sheets.
 */
@Composable
fun RootScreen(graph: AppGraph, pendingRoute: String?, onRouteConsumed: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val navigation: NavigationViewModel = viewModel()
    val navigator = navigation.navigator
    var paywallSource by rememberSaveable { mutableStateOf<String?>(null) }
    var showWhatsNew by rememberSaveable { mutableStateOf(false) }
    var showFeedback by rememberSaveable { mutableStateOf(false) }
    var prepAfterUpgrade by rememberSaveable { mutableStateOf(false) }
    var pendingGrant by remember { mutableStateOf<(() -> Unit)?>(null) }
    val isPro = graph.subscriptions.isPro

    val permissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) pendingGrant?.invoke() else graph.settings.reminderPermissionDenied = true
        pendingGrant = null
    }
    val requestNotifications: (() -> Unit) -> Unit = { onGranted ->
        AlarmReminderScheduler.ensureChannel(context)
        if (AlarmReminderScheduler.canNotify(context)) {
            onGranted()
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pendingGrant = onGranted
            permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    val actions = remember(graph) {
        object : AppActions {
            override fun openPaywall(source: String) {
                paywallSource = source
            }

            override fun openFeedback() {
                showFeedback = true
            }

            override fun openWhatsNew() {
                showWhatsNew = true
            }

            override fun positiveMoment() {
                graph.review.recordPositiveMoment()
                if (!graph.review.shouldShowAfterPositiveMoment()) return
                // Spent when requested, not when answered: Play may show nothing at all.
                graph.review.markStoreCardRequested()
                val activity = context.findActivity() ?: return
                scope.launch {
                    // Let the celebration land first.
                    delay(1_400)
                    val manager = ReviewManagerFactory.create(activity)
                    manager.requestReviewFlow().addOnCompleteListener { request ->
                        if (request.isSuccessful) manager.launchReviewFlow(activity, request.result)
                    }
                }
            }
        }
    }

    // The game-night notification opens the prep session; a lapsed member gets the paywall first.
    LaunchedEffect(pendingRoute, graph.progress.hasOnboarded) {
        if (pendingRoute != AlarmReminderScheduler.GAME_NIGHT_PREP_VALUE || !graph.progress.hasOnboarded) return@LaunchedEffect
        onRouteConsumed()
        if (isPro) {
            navigator.popToRoot()
            navigator.push(Route.Session(gameNightPrepItems(graph), SessionPurpose.GameNightPrep))
        } else {
            prepAfterUpgrade = true
            paywallSource = "mahj_home_sheet"
        }
    }
    LaunchedEffect(isPro) {
        if (isPro && prepAfterUpgrade) {
            prepAfterUpgrade = false
            navigator.push(Route.Session(gameNightPrepItems(graph), SessionPurpose.GameNightPrep))
        } else if (!isPro && graph.settings.gameNightReminderEnabled) {
            graph.settings.updateGameNightReminderEnabled(false)
        }
    }
    LaunchedEffect(graph.progress.hasOnboarded) {
        if (!graph.whatsNew.shouldPresent(graph.progress.hasOnboarded)) return@LaunchedEffect
        delay(500)
        showWhatsNew = true
    }

    CompositionLocalProvider(LocalAppActions provides actions, LocalNavigator provides navigator) {
        AnimatedContent(
            graph.progress.hasOnboarded,
            transitionSpec = { fadeIn(tween(350)) togetherWith fadeOut(tween(350)) },
            label = "root",
        ) { onboarded ->
            if (!onboarded) {
                OnboardingScreen()
            } else {
                NavStack(navigator, enabled = paywallSource == null && !showWhatsNew && !showFeedback) { route ->
                    when (route) {
                        Route.Home -> HomeScreen()
                        is Route.Room -> RoomScreen(route.roomId)
                        is Route.Drill -> DrillScreen(route.roomId, route.drillId)
                        is Route.Session -> SessionScreen(route.items, route.purpose)
                        is Route.Practice -> PracticeRunScreen(route.mode, route.items)
                        Route.HandPlay -> HandPlayScreen()
                        Route.MahjMinute -> MahjMinuteScreen()
                        is Route.MinuteResult -> MahjMinuteResultScreen(route.result)
                        Route.GameNightPrep -> GameNightPrepScreen(requestNotifications)
                        Route.EndlessPicker -> EndlessPickerScreen()
                        Route.Reference -> ReferenceScreen()
                        Route.Stats -> StatsScreen()
                        Route.HowToPlay -> HowToPlayScreen(onDone = { navigator.pop() }, onBack = { navigator.pop() })
                        Route.Settings -> SettingsScreen(requestNotifications)
                    }
                }
            }
        }
        MahjSheet(paywallSource != null, onDismiss = { paywallSource = null; prepAfterUpgrade = false }) {
            PaywallSheet(paywallSource ?: "mahj_paywall_sheet", onClose = { paywallSource = null })
        }
        MahjSheet(showWhatsNew, onDismiss = { graph.whatsNew.markSeen(); showWhatsNew = false }) {
            WhatsNewSheet(
                onClose = { showWhatsNew = false },
                onUpgrade = {
                    showWhatsNew = false
                    scope.launch {
                        delay(350)
                        paywallSource = "mahj_home_sheet"
                    }
                },
            )
        }
        MahjSheet(showFeedback, onDismiss = { showFeedback = false }) {
            FeedbackSheet(onClose = { showFeedback = false })
        }
        // Both reminder toggles (Settings and Game Night Prep) can trip this, so it
        // lives here and shows wherever the player is, as on iOS.
        if (graph.settings.reminderPermissionDenied) {
            MahjAlert(
                "Notifications are off",
                "Mahj Trainer cannot send reminders until notifications are turned on in Android settings.",
                confirmTitle = "Open Settings",
                dismissTitle = "Not now",
                onConfirm = {
                    graph.settings.reminderPermissionDenied = false
                    context.startActivity(
                        Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName),
                    )
                },
                onDismiss = { graph.settings.reminderPermissionDenied = false },
            )
        }
    }
}
