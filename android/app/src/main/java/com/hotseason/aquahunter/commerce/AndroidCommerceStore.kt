package com.hotseason.aquahunter.commerce

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.ConsumeParams
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.security.MessageDigest

data class CommerceThankYou(
    val title: String,
    val message: String,
    val actionTitle: String,
    val destination: CommerceDestination,
)

class AndroidCommerceStore(
    private val activity: Activity,
) : PurchasesUpdatedListener {
    val catalog: CommerceCatalog = CommerceCatalog.load(activity)

    private val preferences = activity.getSharedPreferences(
        "aquahunter_commerce",
        Context.MODE_PRIVATE,
    )
    private val ledger = CommerceLedgerState.fromJson(
        preferences.getString(LEDGER_KEY, null),
    )
    private val _productDetails =
        MutableStateFlow<Map<String, ProductDetails>>(emptyMap())
    val productDetails = _productDetails.asStateFlow()
    private val _statusMessage = MutableStateFlow<String?>(null)
    val statusMessage = _statusMessage.asStateFlow()
    private val _thankYou = MutableStateFlow<CommerceThankYou?>(null)
    val thankYou = _thankYou.asStateFlow()
    private val _ledgerRevision = MutableStateFlow(0)
    val ledgerRevision = _ledgerRevision.asStateFlow()

    private var pendingPurchaseLanguage = "en"
    private var showThanksForNextPurchase = false
    private var connected = false

    private val billingClient = BillingClient.newBuilder(activity)
        .setListener(this)
        .enablePendingPurchases(
            PendingPurchasesParams.newBuilder()
                .enableOneTimeProducts()
                .build(),
        )
        .enableAutoServiceReconnection()
        .build()

    fun start() {
        if (connected || billingClient.isReady) {
            queryProducts()
            refreshPurchases(showRestoredMessage = false, languageCode = "en")
            return
        }
        billingClient.startConnection(
            object : BillingClientStateListener {
                override fun onBillingSetupFinished(
                    billingResult: BillingResult,
                ) {
                    connected =
                        billingResult.responseCode == BillingClient.BillingResponseCode.OK
                    if (connected) {
                        queryProducts()
                        refreshPurchases(
                            showRestoredMessage = false,
                            languageCode = "en",
                        )
                    } else {
                        _statusMessage.value = billingResult.debugMessage
                    }
                }

                override fun onBillingServiceDisconnected() {
                    connected = false
                }
            },
        )
    }

    fun close() {
        billingClient.endConnection()
        connected = false
    }

    fun formattedPrice(productId: String): String? {
        val details = _productDetails.value[productId] ?: return null
        return details.oneTimePurchaseOfferDetails?.formattedPrice
            ?: details.subscriptionOfferDetails
                ?.firstOrNull()
                ?.pricingPhases
                ?.pricingPhaseList
                ?.lastOrNull()
                ?.formattedPrice
    }

    fun purchase(productId: String, languageCode: String) {
        val definition = catalog.definition(productId)
        val details = _productDetails.value[productId]
        if (definition == null || details == null) {
            _statusMessage.value =
                "This store product is not available in the current storefront."
            return
        }
        val productParams = BillingFlowParams.ProductDetailsParams.newBuilder()
            .setProductDetails(details)
        if (definition.isSubscription) {
            val offerToken = details.subscriptionOfferDetails
                ?.firstOrNull()
                ?.offerToken
            if (offerToken.isNullOrBlank()) {
                _statusMessage.value =
                    "No eligible subscription base plan is available."
                return
            }
            productParams.setOfferToken(offerToken)
        }
        pendingPurchaseLanguage = languageCode
        showThanksForNextPurchase = true
        val result = billingClient.launchBillingFlow(
            activity,
            BillingFlowParams.newBuilder()
                .setProductDetailsParamsList(listOf(productParams.build()))
                .build(),
        )
        if (result.responseCode != BillingClient.BillingResponseCode.OK) {
            showThanksForNextPurchase = false
            _statusMessage.value = result.debugMessage
        }
    }

    fun restore(languageCode: String) {
        refreshPurchases(
            showRestoredMessage = true,
            languageCode = languageCode,
        )
    }

    fun clearThankYou() {
        _thankYou.value = null
    }

    fun available(destination: CommerceDestination): Int =
        ledger.available(destination, catalog)

    fun historyWeeks(): Int = ledger.historyWeeks(catalog)

    fun consumeSuccessfulResult(destination: CommerceDestination): Boolean {
        val consumed = ledger.consumeSuccessfulResult(destination, catalog)
        if (consumed) persist()
        return consumed
    }

    override fun onPurchasesUpdated(
        billingResult: BillingResult,
        purchases: MutableList<Purchase>?,
    ) {
        when (billingResult.responseCode) {
            BillingClient.BillingResponseCode.OK ->
                purchases.orEmpty().forEach {
                    processPurchase(
                        purchase = it,
                        showThankYou = showThanksForNextPurchase,
                        languageCode = pendingPurchaseLanguage,
                    )
                }
            BillingClient.BillingResponseCode.USER_CANCELED ->
                _statusMessage.value = null
            else ->
                _statusMessage.value = billingResult.debugMessage
        }
        showThanksForNextPurchase = false
    }

    private fun queryProducts() {
        queryProductType(
            BillingClient.ProductType.SUBS,
            catalog.products.filter { it.isSubscription }.map { it.id },
        )
        queryProductType(
            BillingClient.ProductType.INAPP,
            catalog.products.filter { !it.isSubscription }.map { it.id },
        )
    }

    private fun queryProductType(type: String, productIds: List<String>) {
        val products = productIds.map {
            QueryProductDetailsParams.Product.newBuilder()
                .setProductId(it)
                .setProductType(type)
                .build()
        }
        billingClient.queryProductDetailsAsync(
            QueryProductDetailsParams.newBuilder()
                .setProductList(products)
                .build(),
        ) { billingResult, queryResult ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                _productDetails.value =
                    _productDetails.value + queryResult.productDetailsList
                        .associateBy { it.productId }
            } else {
                _statusMessage.value = billingResult.debugMessage
            }
        }
    }

    private fun refreshPurchases(
        showRestoredMessage: Boolean,
        languageCode: String,
    ) {
        val activeSubscriptions = mutableSetOf<String>()
        var completedQueries = 0

        fun completeQuery() {
            completedQueries += 1
            if (completedQueries == 2) {
                ledger.replaceActiveSubscriptions(activeSubscriptions)
                persist()
                if (showRestoredMessage) {
                    _statusMessage.value =
                        catalog.locale(languageCode).restored
                }
            }
        }

        billingClient.queryPurchasesAsync(
            QueryPurchasesParams.newBuilder()
                .setProductType(BillingClient.ProductType.SUBS)
                .build(),
        ) { result, purchases ->
            if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                purchases.forEach { purchase ->
                    if (purchase.purchaseState == Purchase.PurchaseState.PURCHASED) {
                        activeSubscriptions.addAll(purchase.products)
                        processPurchase(
                            purchase,
                            showThankYou = false,
                            languageCode = languageCode,
                        )
                    }
                }
            }
            completeQuery()
        }

        billingClient.queryPurchasesAsync(
            QueryPurchasesParams.newBuilder()
                .setProductType(BillingClient.ProductType.INAPP)
                .build(),
        ) { result, purchases ->
            if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                purchases.forEach { purchase ->
                    processPurchase(
                        purchase,
                        showThankYou = false,
                        languageCode = languageCode,
                    )
                }
            }
            completeQuery()
        }
    }

    private fun processPurchase(
        purchase: Purchase,
        showThankYou: Boolean,
        languageCode: String,
    ) {
        if (purchase.purchaseState == Purchase.PurchaseState.PENDING) {
            _statusMessage.value = catalog.locale(languageCode).pending
            return
        }
        if (purchase.purchaseState != Purchase.PurchaseState.PURCHASED) return
        val productId = purchase.products.firstOrNull() ?: return
        val definition = catalog.definition(productId) ?: return

        runCatching {
            ledger.grant(
                transactionId = purchase.purchaseToken.sha256(),
                product = definition,
            )
            persist()
        }.onFailure {
            _statusMessage.value = it.localizedMessage
            return
        }

        if (definition.isSubscription) {
            if (!purchase.isAcknowledged) {
                billingClient.acknowledgePurchase(
                    AcknowledgePurchaseParams.newBuilder()
                        .setPurchaseToken(purchase.purchaseToken)
                        .build(),
                ) { result ->
                    if (result.responseCode != BillingClient.BillingResponseCode.OK) {
                        _statusMessage.value = result.debugMessage
                    }
                }
            }
        } else {
            billingClient.consumeAsync(
                ConsumeParams.newBuilder()
                    .setPurchaseToken(purchase.purchaseToken)
                    .build(),
            ) { result, _ ->
                if (result.responseCode != BillingClient.BillingResponseCode.OK) {
                    _statusMessage.value = result.debugMessage
                }
            }
        }

        if (showThankYou) {
            val locale = catalog.locale(languageCode)
            val productText = catalog.text(definition, languageCode)
            val destinationText = checkNotNull(
                locale.destinations[definition.destination],
            )
            _thankYou.value = CommerceThankYou(
                title = locale.thankYouTitle,
                message = locale.replace(
                    locale.thankYouMessage,
                    mapOf("product" to productText.name),
                ),
                actionTitle = locale.replace(
                    locale.openDestination,
                    mapOf("destination" to destinationText),
                ),
                destination = definition.destination,
            )
        }
    }

    private fun persist() {
        preferences.edit().putString(LEDGER_KEY, ledger.toJson()).apply()
        _ledgerRevision.value += 1
    }

    private companion object {
        const val LEDGER_KEY = "ledger_v1"
    }
}

private fun String.sha256(): String =
    MessageDigest.getInstance("SHA-256")
        .digest(toByteArray(Charsets.UTF_8))
        .joinToString(separator = "") { byte -> "%02x".format(byte) }
