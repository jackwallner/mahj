package com.jackwallner.mahj

import com.jackwallner.mahj.data.PurchaseOutcome
import com.jackwallner.mahj.data.purchaseOutcome
import com.jackwallner.mahj.data.restoreFailureMessage
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

    @Test
    fun restoreExplainsPendingPaymentsWithoutCallingThemFailures() {
        assertEquals(
            "Google Play is still processing your payment. Mahj+ unlocks as soon as it completes.",
            restoreFailureMessage(PurchasesErrorCode.PaymentPendingError),
        )
    }

    @Test
    fun realRestoreErrorsStillOfferARetry() {
        assertEquals("Couldn't restore purchases. Try again.", restoreFailureMessage(PurchasesErrorCode.NetworkError))
        assertEquals("Couldn't restore purchases. Try again.", restoreFailureMessage(PurchasesErrorCode.StoreProblemError))
    }
}
