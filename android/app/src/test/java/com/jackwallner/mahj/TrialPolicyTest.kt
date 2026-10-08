package com.jackwallner.mahj

import com.jackwallner.mahj.data.PaywallPlan
import com.jackwallner.mahj.data.TrialPolicy
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class TrialPolicyTest {
    @Test
    fun newSubscribersKeepTheTrialCopy() {
        for (plan in listOf(PaywallPlan.MONTHLY, PaywallPlan.YEARLY)) {
            assertTrue(TrialPolicy.available(plan, false))
            assertEquals("Start 7-Day Free Trial", TrialPolicy.cta(plan, false))
            assertTrue(TrialPolicy.detail(plan, false).startsWith("7 days free"))
            assertTrue(TrialPolicy.terms(plan, "$9.99/month", false).startsWith("7 days free"))
        }
        assertEquals("Start 7-day free trial", TrialPolicy.cta(PaywallPlan.MONTHLY, false, onboarding = true))
    }

    @Test
    fun anyPastSubscriptionDisablesBothTrials() {
        for (plan in listOf(PaywallPlan.MONTHLY, PaywallPlan.YEARLY)) {
            assertFalse(TrialPolicy.available(plan, true))
            assertEquals("Subscribe", TrialPolicy.cta(plan, true))
            assertFalse(TrialPolicy.detail(plan, true).contains("free"))
            assertFalse(TrialPolicy.terms(plan, "$9.99/month", true).contains("free"))
        }
        assertEquals("Subscribe", TrialPolicy.cta(PaywallPlan.MONTHLY, true, onboarding = true))
        assertEquals("Billed yearly. Auto-renews.", TrialPolicy.detail(PaywallPlan.YEARLY, true))
    }

    @Test
    fun lifetimeAlwaysRemainsOnePayment() {
        for (history in listOf(false, true)) {
            assertFalse(TrialPolicy.available(PaywallPlan.LIFETIME, history))
            assertEquals("Unlock Mahj+ Forever", TrialPolicy.cta(PaywallPlan.LIFETIME, history))
            assertEquals(
                "$89.99 one-time. Not a subscription, nothing renews.",
                TrialPolicy.terms(PaywallPlan.LIFETIME, "$89.99", history),
            )
        }
    }

    @Test
    fun missingPricesDoNotPromiseReturningSubscribersATrial() {
        assertEquals(
            "Auto-renews until canceled in Google Play.",
            TrialPolicy.terms(PaywallPlan.MONTHLY, null, true),
        )
        assertEquals(
            "Includes 7 days free. Auto-renews until canceled.",
            TrialPolicy.terms(PaywallPlan.MONTHLY, null, false),
        )
    }
}
