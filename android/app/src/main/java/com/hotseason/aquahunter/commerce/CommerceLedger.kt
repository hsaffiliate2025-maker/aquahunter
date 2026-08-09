package com.hotseason.aquahunter.commerce

import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.ZoneOffset

data class CommerceLedgerState(
    val purchasedBalances: MutableMap<CommerceDestination, Int> = mutableMapOf(),
    val processedTransactionIds: MutableSet<String> = mutableSetOf(),
    val activeSubscriptionProductIds: MutableSet<String> = mutableSetOf(),
    val monthlyUsage: MutableMap<String, MutableMap<CommerceDestination, Int>> =
        mutableMapOf(),
) {
    fun grant(
        transactionId: String,
        product: CommerceProductDefinition,
    ): Boolean {
        if (!processedTransactionIds.add(transactionId)) return false
        if (product.isSubscription) {
            activeSubscriptionProductIds += product.id
            return true
        }
        val quantity = requireNotNull(product.quantity)
        require(quantity > 0)
        purchasedBalances[product.destination] =
            purchasedBalances.getOrDefault(product.destination, 0) + quantity
        return true
    }

    fun replaceActiveSubscriptions(productIds: Set<String>) {
        activeSubscriptionProductIds.clear()
        activeSubscriptionProductIds.addAll(productIds)
    }

    fun historyWeeks(catalog: CommerceCatalog): Int =
        activeSubscriptions(catalog)
            .mapNotNull { it.grant?.historyWeeks }
            .maxOrNull() ?: 52

    fun available(
        destination: CommerceDestination,
        catalog: CommerceCatalog,
        nowEpochMillis: Long = System.currentTimeMillis(),
    ): Int {
        val purchased = purchasedBalances.getOrDefault(destination, 0)
        val included = activeSubscriptions(catalog)
            .mapNotNull { it.grant?.monthlyAllowances?.get(destination) }
            .maxOrNull() ?: 0
        val used = monthlyUsage[monthKey(nowEpochMillis)]
            ?.get(destination) ?: 0
        return purchased + (included - used).coerceAtLeast(0)
    }

    fun consumeSuccessfulResult(
        destination: CommerceDestination,
        catalog: CommerceCatalog,
        nowEpochMillis: Long = System.currentTimeMillis(),
    ): Boolean {
        val purchased = purchasedBalances.getOrDefault(destination, 0)
        if (purchased > 0) {
            purchasedBalances[destination] = purchased - 1
            return true
        }
        val allowance = activeSubscriptions(catalog)
            .mapNotNull { it.grant?.monthlyAllowances?.get(destination) }
            .maxOrNull() ?: 0
        val month = monthKey(nowEpochMillis)
        val usage = monthlyUsage.getOrPut(month) { mutableMapOf() }
        val used = usage.getOrDefault(destination, 0)
        if (used >= allowance) return false
        usage[destination] = used + 1
        return true
    }

    fun toJson(): String {
        val balances = JSONObject()
        purchasedBalances.forEach { (key, value) ->
            balances.put(key.wireValue, value)
        }
        val usage = JSONObject()
        monthlyUsage.forEach { (month, values) ->
            val monthObject = JSONObject()
            values.forEach { (key, value) ->
                monthObject.put(key.wireValue, value)
            }
            usage.put(month, monthObject)
        }
        return JSONObject()
            .put("purchasedBalances", balances)
            .put(
                "processedTransactionIds",
                JSONArray(processedTransactionIds.toList()),
            )
            .put(
                "activeSubscriptionProductIds",
                JSONArray(activeSubscriptionProductIds.toList()),
            )
            .put("monthlyUsage", usage)
            .toString()
    }

    private fun activeSubscriptions(
        catalog: CommerceCatalog,
    ): List<CommerceProductDefinition> =
        catalog.products.filter {
            it.isSubscription && activeSubscriptionProductIds.contains(it.id)
        }

    companion object {
        fun fromJson(raw: String?): CommerceLedgerState {
            if (raw.isNullOrBlank()) return CommerceLedgerState()
            return runCatching {
                val json = JSONObject(raw)
                val balances = json.getJSONObject("purchasedBalances")
                val processed = json.getJSONArray("processedTransactionIds")
                val active = json.getJSONArray(
                    "activeSubscriptionProductIds",
                )
                val usageObject = json.getJSONObject("monthlyUsage")
                CommerceLedgerState(
                    purchasedBalances = balances.keys().asSequence().associate {
                        CommerceDestination.from(it) to balances.getInt(it)
                    }.toMutableMap(),
                    processedTransactionIds = List(processed.length()) {
                        processed.getString(it)
                    }.toMutableSet(),
                    activeSubscriptionProductIds = List(active.length()) {
                        active.getString(it)
                    }.toMutableSet(),
                    monthlyUsage = usageObject.keys().asSequence().associate {
                        month ->
                        val monthObject = usageObject.getJSONObject(month)
                        month to monthObject.keys().asSequence().associate {
                            CommerceDestination.from(it) to
                                monthObject.getInt(it)
                        }.toMutableMap()
                    }.toMutableMap(),
                )
            }.getOrElse { CommerceLedgerState() }
        }

        private fun monthKey(epochMillis: Long): String =
            Instant.ofEpochMilli(epochMillis)
                .atOffset(ZoneOffset.UTC)
                .toLocalDate()
                .let { "%04d-%02d".format(it.year, it.monthValue) }
    }
}
