package com.jackwallner.mahj

import android.content.Context
import com.jackwallner.mahj.data.AlarmReminderScheduler
import com.jackwallner.mahj.data.AppClock
import com.jackwallner.mahj.data.AppSettings
import com.jackwallner.mahj.data.ConversionDiagnostics
import com.jackwallner.mahj.data.HandPlayStore
import com.jackwallner.mahj.data.MahjMinuteStore
import com.jackwallner.mahj.data.PracticeRecordStore
import com.jackwallner.mahj.data.ProgressStore
import com.jackwallner.mahj.data.ReviewPromptTracker
import com.jackwallner.mahj.data.SharedPreferencesStore
import com.jackwallner.mahj.data.SubscriptionService
import com.jackwallner.mahj.data.WhatsNewTracker
import kotlinx.coroutines.MainScope

/** Every long-lived object the screens share, built once per process. */
class AppGraph(context: Context) {
    val appContext: Context = context.applicationContext
    val scope = MainScope()
    val clock = AppClock()
    val defaults = SharedPreferencesStore(appContext)
    val settings = AppSettings(defaults, AlarmReminderScheduler(appContext))
    val progress = ProgressStore(defaults, clock)
    val records = PracticeRecordStore(defaults, clock)
    val minutes = MahjMinuteStore(defaults, clock)
    val handPlay = HandPlayStore(defaults, clock)
    val review = ReviewPromptTracker(defaults, clock)
    val diagnostics = ConversionDiagnostics(defaults, clock)
    val subscriptions = SubscriptionService(appContext, defaults, diagnostics)
    val whatsNew = WhatsNewTracker(defaults, BuildConfig.VERSION_NAME)

    /** Settings' Reset Progress: every practice stat, never onboarding or purchases. */
    fun resetProgress() {
        progress.resetAll()
        records.resetAll()
        minutes.resetAll()
        handPlay.resetAll()
    }
}
