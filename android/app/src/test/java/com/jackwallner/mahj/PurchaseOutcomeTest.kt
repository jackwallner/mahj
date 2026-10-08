package com.jackwallner.mahj

import com.jackwallner.mahj.data.PurchaseOutcome
import com.jackwallner.mahj.data.purchaseOutcome
import com.revenuecat.purchases.PurchasesErrorCode
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class PurchaseOutcomeTest {
    @Test
    fun pendingPaymentIsNotAnErrorOrACompletedPurchase() {
        assertEquals(PurchaseOutcome.PENDING, purchaseOutcome(PurchasesErrorCode.PaymentPendingError, false))
    }

    @Test
    fun cancellationStaysAnOutcomeAndRealErrorsStillSurface() {
        assertEquals(PurchaseOutcome.CANCELLED, purchaseOutcome(PurchasesErrorCode.PurchaseCancelledError, false))
        assertEquals(PurchaseOutcome.CANCELLED, purchaseOutcome(PurchasesErrorCode.UnknownError, true))
        assertNull(purchaseOutcome(PurchasesErrorCode.NetworkError, false))
        assertNull(purchaseOutcome(PurchasesErrorCode.StoreProblemError, false))
    }
}
