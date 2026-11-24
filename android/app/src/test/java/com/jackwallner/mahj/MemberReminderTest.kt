package com.jackwallner.mahj

import com.jackwallner.mahj.data.AppSettings
import com.jackwallner.mahj.data.InMemoryStore
import com.jackwallner.mahj.data.ReminderScheduler
import com.jackwallner.mahj.data.SubscriptionService
import java.time.DayOfWeek
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Reminders say what Android will deliver, and only a fresh "not a member" ends a member's reminder. */
class MemberReminderTest {
    private class FakeScheduler : ReminderScheduler {
        val laid = mutableListOf<String>()
        override fun scheduleDaily(hour: Int, minute: Int) { laid += "daily" }
        override fun cancelDaily() { laid += "cancel daily" }
        override fun scheduleGameNight(day: DayOfWeek, hour: Int, minute: Int) { laid += "game night" }
        override fun cancelGameNight() { laid += "cancel game night" }
    }

    @Test
    fun onlyAFreshNonMemberRecordConfirmsALapse() {
        val now = 1_000_000_000L
        assertTrue(SubscriptionService.confirmsLapse(isMember = false, answeredAt = now - 60_000, now = now))
        assertFalse("A cached record from before a renewal is not proof", SubscriptionService.confirmsLapse(false, now - 3_600_000, now))
        assertFalse(SubscriptionService.confirmsLapse(isMember = true, answeredAt = now, now = now))
    }

    @Test
    fun notificationsSwitchedOffTurnTheTogglesOff() {
        val defaults = InMemoryStore()
        val scheduler = FakeScheduler()
        val settings = AppSettings(defaults, scheduler)
        settings.updateReminderEnabled(true)
        settings.updateGameNightReminderEnabled(true)
        scheduler.laid.clear()

        settings.reconcileReminders(canNotify = true)
        assertEquals("Allowed: everything on is laid again", listOf("daily", "game night"), scheduler.laid)

        settings.reconcileReminders(canNotify = false)
        assertFalse(settings.reminderEnabled)
        assertFalse(settings.gameNightReminderEnabled)
        assertFalse("The toggles stay off after a relaunch", AppSettings(defaults, null).reminderEnabled)
    }
}
