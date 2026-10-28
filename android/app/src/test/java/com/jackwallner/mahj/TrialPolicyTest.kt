package com.jackwallner.mahj

import com.jackwallner.mahj.data.PaywallPlan
import com.jackwallner.mahj.data.PaywallPricing
import com.jackwallner.mahj.data.TrialPolicy
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class TrialPolicyTest {
    @Test
    fun newSubscribersWithAPlayOfferGetTheTrial() {
        for (plan in listOf(PaywallPlan.MONTHLY, PaywallPlan.YEARLY)) {
            assertTrue(TrialPolicy.offered(plan, hasSubscriptionHistory = false, playFreePhase = true))
            assertEquals("Start 7-Day Free Trial", plan.ctaTitle(true))
            assertTrue(PaywallPricing.terms("$9.99/month", plan, freeTrial = true).startsWith("7 days free"))
        }
    }

    @Test
    fun anyPastSubscriptionDisablesBothTrials() {
        for (plan in listOf(PaywallPlan.MONTHLY, PaywallPlan.YEARLY)) {
            val offered = TrialPolicy.offered(plan, hasSubscriptionHistory = true, playFreePhase = true)
            assertFalse(offered)
            assertEquals("Subscribe", plan.ctaTitle(offered))
            assertFalse(PaywallPricing.terms("$9.99/month", plan, offered).contains("free"))
        }
    }

    @Test
    fun noPlayOfferMeansNoTrialPromise() {
        assertFalse(TrialPolicy.offered(PaywallPlan.MONTHLY, hasSubscriptionHistory = false, playFreePhase = false))
    }

    @Test
    fun lifetimeAlwaysRemainsOnePayment() {
        for (history in listOf(false, true)) {
            assertFalse(TrialPolicy.offered(PaywallPlan.LIFETIME, history, playFreePhase = true))
            assertEquals("Unlock Mahj+ Forever", PaywallPlan.LIFETIME.ctaTitle(false))
            assertEquals(
                "$89.99 one-time. Not a subscription, nothing renews.",
                PaywallPricing.terms("$89.99", PaywallPlan.LIFETIME, freeTrial = false),
            )
        }
    }
}
