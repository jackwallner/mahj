package com.jackwallner.mahj.data

import android.app.Activity
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.jackwallner.mahj.BuildConfig
import com.revenuecat.purchases.CustomerInfo
import com.revenuecat.purchases.LogLevel
import com.revenuecat.purchases.Offering
import com.revenuecat.purchases.Package
import com.revenuecat.purchases.PurchaseParams
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesConfiguration
import com.revenuecat.purchases.PurchasesErrorCode
import com.revenuecat.purchases.PurchasesTransactionException
import com.revenuecat.purchases.awaitCustomerInfo
import com.revenuecat.purchases.awaitOfferings
import com.revenuecat.purchases.awaitPurchase
import com.revenuecat.purchases.awaitRestore
import com.revenuecat.purchases.interfaces.UpdatedCustomerInfoListener
import com.revenuecat.purchases.paywalls.events.CustomPaywallImpressionParams
import java.math.BigDecimal
import java.math.RoundingMode
import java.text.NumberFormat
import java.util.Currency
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.delay

/** The membership brand. The RevenueCat entitlement is still `pro`. */
object Membership {
    const val NAME = "Mahj+"
}

enum class PaywallPlan(val ctaTitle: String) {
    YEARLY("Start 7-Day Free Trial"),
    LIFETIME("Unlock ${Membership.NAME} Forever"),
    MONTHLY("Start 7-Day Free Trial"),
}

/** A store price: the localized label plus the amount for arithmetic. */
data class PaywallPrice(val amount: BigDecimal, val localized: String, val currencyCode: String)

enum class PurchaseOutcome { PURCHASED, PENDING, CANCELLED }

internal fun purchaseOutcome(code: PurchasesErrorCode, userCancelled: Boolean): PurchaseOutcome? = when {
    userCancelled || code == PurchasesErrorCode.PurchaseCancelledError -> PurchaseOutcome.CANCELLED
    code == PurchasesErrorCode.PaymentPendingError -> PurchaseOutcome.PENDING
    else -> null
}

class PurchaseException(message: String) : Exception(message)

/**
 * RevenueCat behind the single `pro` entitlement. Debug builds use the Test
 * Store key and release builds the Play key; neither ever runs on the other.
 */
class SubscriptionService(
    private val context: Context,
    private val defaults: KeyValueStore,
    private val diagnostics: ConversionDiagnostics,
) {
    private val reviewAccess = ReviewAccess(defaults, BuildConfig.PLAY_REVIEW_CODE_SHA256)
    var isPro by mutableStateOf(reviewAccess.isGranted || (BuildConfig.DEBUG && defaults.getBoolean(LOCAL_OVERRIDE)))
        private set
    var offering by mutableStateOf<Offering?>(null)
        private set

    private var isConfigured = false
    private var forcePro = false
    private val impressionsThisSession = mutableSetOf<String>()

    /** Debug-only: open the paid boundary for screenshots and tests. */
    fun forceProForDebug(value: Boolean = true) {
        if (!BuildConfig.DEBUG) return
        forcePro = value
        isPro = value
    }

    /** Debug-only Settings switch, like the iOS local override. */
    fun setLocalOverride(value: Boolean) {
        if (!BuildConfig.DEBUG) return
        defaults.putBoolean(LOCAL_OVERRIDE, value)
        isPro = value || reviewAccess.isGranted
    }

    fun activateReviewAccess(code: String): Boolean {
        if (!reviewAccess.activate(code)) return false
        isPro = true
        return true
    }

    suspend fun start() {
        if (!configureIfNeeded()) return
        refreshCustomerInfo()
        loadOfferings()
    }

    suspend fun refreshCustomerInfo() {
        if (!configureIfNeeded()) return
        runCatching { Purchases.sharedInstance.awaitCustomerInfo() }
            .onSuccess(::apply)
            .onFailure { if (it is CancellationException) throw it }
    }

    suspend fun loadOfferings() {
        if (!configureIfNeeded()) return
        try {
            val offerings = Purchases.sharedInstance.awaitOfferings()
            // Android owns its offering; the live iOS default stays untouched.
            offering = if (BuildConfig.DEBUG) offerings.current else offerings.all[ANDROID_OFFERING_ID]
        } catch (error: CancellationException) {
            throw error
        } catch (_: Throwable) {
            // Leave the previous offering; the paywall shows its retry line.
        }
    }

    /** One more chance for offerings to land before calling the products missing. */
    suspend fun ensureOfferings(): Boolean {
        if (!configureIfNeeded()) return false
        if (offering != null) return true
        loadOfferings()
        return offering != null
    }

    fun packageFor(plan: PaywallPlan): Package? = when (plan) {
        PaywallPlan.YEARLY -> offering?.annual
        PaywallPlan.MONTHLY -> offering?.monthly
        PaywallPlan.LIFETIME -> offering?.lifetime
    }

    fun paywallPrice(plan: PaywallPlan): PaywallPrice? {
        val price = packageFor(plan)?.product?.price ?: return null
        return PaywallPrice(BigDecimal.valueOf(price.amountMicros, 6), price.formatted, price.currencyCode)
    }

    /** Feeds RevenueCat's paywall encounters; a custom paywall emits none of its own. */
    fun trackPaywallImpression(id: String, oncePerSession: Boolean = false) {
        if (!configureIfNeeded()) return
        if (oncePerSession && !impressionsThisSession.add(id)) return
        diagnostics.recordPitchView(id)
        syncConversionAttributes()
        runCatching { Purchases.sharedInstance.trackCustomPaywallImpression(CustomPaywallImpressionParams(id)) }
    }

    private fun syncConversionAttributes() {
        if (!isConfigured) return
        val attributes = diagnostics.subscriberAttributes.toMutableMap()
        if (attributes.isEmpty()) return
        offering?.identifier?.let { attributes["offering_id"] = it }
        runCatching { Purchases.sharedInstance.setAttributes(attributes) }
    }

    /** A cancel is an outcome, not an error. Throws only with a player-facing message. */
    suspend fun purchase(activity: Activity, pkg: Package?): PurchaseOutcome {
        if (!configureIfNeeded() || pkg == null) throw PurchaseException(UNAVAILABLE)
        val startedTrial = pkg.product.defaultOption?.freePhase != null
        return try {
            val result = Purchases.sharedInstance.awaitPurchase(PurchaseParams.Builder(activity, pkg).build())
            apply(result.customerInfo)
            if (!isPro) return PurchaseOutcome.PENDING
            diagnostics.recordConversion(pkg.product.id, startedTrial, pkg.presentedOfferingContext.offeringIdentifier)
            syncConversionAttributes()
            PurchaseOutcome.PURCHASED
        } catch (error: PurchasesTransactionException) {
            purchaseOutcome(error.code, error.userCancelled)
                ?: throw PurchaseException("Couldn't complete the purchase. Please try again.")
        }
    }

    /** Play says the money moved; the entitlement can take a beat to catch up. */
    suspend fun confirmEntitlement(attempts: Int = 3): Boolean {
        if (!isConfigured) return isPro
        repeat(attempts) { attempt ->
            refreshCustomerInfo()
            if (isPro) return true
            if (attempt < attempts - 1) delay(1_200)
        }
        return isPro
    }

    suspend fun restore() {
        if (!configureIfNeeded()) throw PurchaseException(UNAVAILABLE)
        try {
            apply(Purchases.sharedInstance.awaitRestore())
        } catch (error: CancellationException) {
            throw error
        } catch (_: Throwable) {
            throw PurchaseException("Couldn't restore purchases. Try again.")
        }
    }

    /** The active subscription's product id, for the Play manage-subscription link. */
    var activeProductId by mutableStateOf<String?>(null)
        private set

    private fun apply(info: CustomerInfo) {
        if (forcePro) return
        val entitlement = info.entitlements["pro"]
        activeProductId = entitlement?.productIdentifier?.substringBefore(":")
        val override = BuildConfig.DEBUG && defaults.getBoolean(LOCAL_OVERRIDE)
        isPro = entitlement?.isActive == true || override || reviewAccess.isGranted
    }

    private fun configureIfNeeded(): Boolean {
        if (isConfigured) return true
        if (forcePro) return false
        val key = BuildConfig.REVENUECAT_API_KEY
        if (key.isBlank()) return false
        // Never the production Play key in a debug build, and never a test key in release.
        if (BuildConfig.DEBUG && key.startsWith("goog_")) return false
        if (!BuildConfig.DEBUG && !key.startsWith("goog_")) return false
        Purchases.logLevel = if (BuildConfig.DEBUG) LogLevel.DEBUG else LogLevel.ERROR
        Purchases.configure(PurchasesConfiguration.Builder(context, key).build())
        Purchases.sharedInstance.updatedCustomerInfoListener = UpdatedCustomerInfoListener { apply(it) }
        isConfigured = true
        return true
    }

    companion object {
        private const val ANDROID_OFFERING_ID = "android"
        private const val LOCAL_OVERRIDE = "subscription.localProOverride"
        private const val UNAVAILABLE = "Google Play isn't reachable right now. Check your connection and try again."
    }
}

/**
 * Price and terms strings, live from the store. An unresolved product shows a
 * placeholder, never an invented amount.
 */
object PaywallPricing {
    const val PLACEHOLDER = "Loading price…"

    fun price(service: SubscriptionService, plan: PaywallPlan): String? {
        val base = service.paywallPrice(plan)?.localized ?: return null
        return when (plan) {
            PaywallPlan.YEARLY -> "$base/year"
            PaywallPlan.MONTHLY -> "$base/month"
            PaywallPlan.LIFETIME -> base
        }
    }

    fun priceText(service: SubscriptionService, plan: PaywallPlan): String = price(service, plan) ?: PLACEHOLDER

    fun perMonthEquivalent(service: SubscriptionService): String? {
        val yearly = service.paywallPrice(PaywallPlan.YEARLY) ?: return null
        val monthly = yearly.amount.divide(BigDecimal(12), 2, RoundingMode.HALF_UP)
        val format = NumberFormat.getCurrencyInstance().apply {
            runCatching { currency = Currency.getInstance(yearly.currencyCode) }
        }
        return "${format.format(monthly)}/mo"
    }

    fun monthlyAnchor(service: SubscriptionService): String? =
        service.paywallPrice(PaywallPlan.MONTHLY)?.let { "${it.localized}/mo" }

    fun savingsPercent(service: SubscriptionService): Int? {
        val yearly = service.paywallPrice(PaywallPlan.YEARLY) ?: return null
        val monthly = service.paywallPrice(PaywallPlan.MONTHLY) ?: return null
        val twelve = monthly.amount.multiply(BigDecimal(12))
        if (twelve.signum() <= 0 || yearly.amount >= twelve) return null
        val percent = twelve.subtract(yearly.amount).divide(twelve, 6, RoundingMode.HALF_UP)
            .multiply(BigDecimal(100)).setScale(0, RoundingMode.HALF_UP).toInt()
        return percent.takeIf { it > 0 }
    }

    fun savingsBadge(service: SubscriptionService): String =
        savingsPercent(service)?.let { "SAVE $it%" } ?: "BEST VALUE"

    fun terms(service: SubscriptionService, plan: PaywallPlan): String {
        val amount = price(service, plan)
        return when {
            plan == PaywallPlan.LIFETIME && amount == null -> "One-time purchase. Not a subscription, nothing renews."
            plan == PaywallPlan.LIFETIME -> "$amount one-time. Not a subscription, nothing renews."
            amount == null -> "Includes 7 days free. Auto-renews until canceled."
            else -> "7 days free, then $amount. Auto-renews until canceled in Google Play."
        }
    }
}
