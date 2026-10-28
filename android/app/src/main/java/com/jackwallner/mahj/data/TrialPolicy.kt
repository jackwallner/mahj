package com.jackwallner.mahj.data

internal object TrialPolicy {
    /**
     * The free week is promised only to someone who never subscribed in this
     * app and whose Play offer actually carries a free phase. Lifetime has none.
     */
    fun offered(plan: PaywallPlan, hasSubscriptionHistory: Boolean, playFreePhase: Boolean): Boolean =
        plan != PaywallPlan.LIFETIME && !hasSubscriptionHistory && playFreePhase
}
