package com.jackwallner.mahj.data

internal object TrialPolicy {
    fun available(plan: PaywallPlan, hasSubscriptionHistory: Boolean): Boolean =
        plan != PaywallPlan.LIFETIME && !hasSubscriptionHistory

    fun cta(plan: PaywallPlan, hasSubscriptionHistory: Boolean, onboarding: Boolean = false): String = when {
        plan == PaywallPlan.LIFETIME -> plan.ctaTitle
        !available(plan, hasSubscriptionHistory) -> "Subscribe"
        onboarding -> "Start 7-day free trial"
        else -> plan.ctaTitle
    }

    fun detail(plan: PaywallPlan, hasSubscriptionHistory: Boolean): String {
        if (plan == PaywallPlan.LIFETIME) return "One payment. No subscription, nothing renews."
        val period = if (plan == PaywallPlan.MONTHLY) "monthly" else "yearly"
        return if (hasSubscriptionHistory) "Billed $period. Auto-renews."
        else "7 days free, then billed $period. Auto-renews."
    }

    fun terms(plan: PaywallPlan, amount: String?, hasSubscriptionHistory: Boolean): String = when {
        plan == PaywallPlan.LIFETIME && amount == null -> "One-time purchase. Not a subscription, nothing renews."
        plan == PaywallPlan.LIFETIME -> "$amount one-time. Not a subscription, nothing renews."
        hasSubscriptionHistory && amount == null -> "Auto-renews until canceled in Google Play."
        hasSubscriptionHistory -> "$amount. Auto-renews until canceled in Google Play."
        amount == null -> "Includes 7 days free. Auto-renews until canceled."
        else -> "7 days free, then $amount. Auto-renews until canceled in Google Play."
    }
}
