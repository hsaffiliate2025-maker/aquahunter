package com.hotseason.aquahunter.commerce

import android.content.Context
import org.json.JSONObject

enum class CommerceDestination(val wireValue: String) {
    History("history"),
    Export("export"),
    Compare("compare"),
    Snapshot("snapshot"),
    Seasonality("seasonality"),
    LandedCost("landedCost"),
    Alerts("alerts");

    companion object {
        fun from(value: String): CommerceDestination =
            entries.firstOrNull { it.wireValue == value }
                ?: error("Unknown commerce destination: $value")
    }
}

data class CommerceSubscriptionGrant(
    val historyWeeks: Int,
    val watchlistSlots: Int,
    val monthlyAllowances: Map<CommerceDestination, Int>,
)

data class CommerceProductDefinition(
    val id: String,
    val storeType: String,
    val family: String,
    val tier: String?,
    val billingPeriod: String?,
    val destination: CommerceDestination,
    val quantity: Int?,
    val grant: CommerceSubscriptionGrant?,
) {
    val isSubscription: Boolean
        get() = storeType == "autoRenewableSubscription"
}

data class CommerceProductText(
    val name: String,
    val description: String,
)

data class CommerceSubscriptionText(
    val name: String,
    val description: String,
)

data class CommerceFamilyText(
    val name: String,
    val description: String,
)

data class CommerceStoreText(
    val title: String,
    val plansTitle: String,
    val optionsEyebrow: String,
    val allowanceDisclosure: String,
    val subscriptionsTitle: String,
    val oneTimeTitle: String,
    val unavailable: String,
    val done: String,
    val later: String,
    val storeButton: String,
    val legalDisclosure: String,
)

data class CommerceLocaleText(
    val thankYouTitle: String,
    val thankYouMessage: String,
    val openDestination: String,
    val purchase: String,
    val restore: String,
    val restored: String,
    val balance: String,
    val pending: String,
    val failed: String,
    val noCharge: String,
    val toolkit: Map<String, String>,
    val store: CommerceStoreText,
    val destinations: Map<CommerceDestination, String>,
    val periods: Map<String, String>,
    val subscriptions: Map<String, CommerceSubscriptionText>,
    val families: Map<String, CommerceFamilyText>,
) {
    fun replace(template: String, values: Map<String, String>): String =
        values.entries.fold(template) { output, entry ->
            output.replace("{${entry.key}}", entry.value)
        }

    fun tool(key: String, fallback: String): String = toolkit[key] ?: fallback
}

data class CommerceCatalog(
    val catalogVersion: String,
    val supportedLocales: List<String>,
    val paidSourceIds: List<String>,
    val products: List<CommerceProductDefinition>,
    val localizations: Map<String, CommerceLocaleText>,
) {
    fun definition(productId: String): CommerceProductDefinition? =
        products.firstOrNull { it.id == productId }

    fun locale(languageCode: String): CommerceLocaleText =
        localizations[languageCode]
            ?: localizations[languageCode.substringBefore("-")]
            ?: checkNotNull(localizations["en"])

    fun text(
        product: CommerceProductDefinition,
        languageCode: String,
    ): CommerceProductText {
        val locale = locale(languageCode)
        if (product.isSubscription) {
            val tier = requireNotNull(product.tier)
            val period = requireNotNull(product.billingPeriod)
            val block = checkNotNull(locale.subscriptions[tier])
            return CommerceProductText(
                name = "${block.name} — ${checkNotNull(locale.periods[period])}",
                description = block.description,
            )
        }
        val quantity = requireNotNull(product.quantity)
        val block = checkNotNull(locale.families[product.family])
        val values = mapOf("quantity" to quantity.toString())
        return CommerceProductText(
            name = locale.replace(block.name, values),
            description = locale.replace(block.description, values),
        )
    }

    companion object {
        fun load(context: Context): CommerceCatalog =
            decode(
                catalogJson = context.assets.open("product-catalog.json")
                    .bufferedReader().use { it.readText() },
                localizationJson = context.assets.open("localizations.json")
                    .bufferedReader().use { it.readText() },
            )

        fun decode(
            catalogJson: String,
            localizationJson: String,
        ): CommerceCatalog {
            val catalog = JSONObject(catalogJson)
            val localizationPayload = JSONObject(localizationJson)
            val catalogVersion = catalog.getString("catalogVersion")
            require(
                catalogVersion == localizationPayload.getString("catalogVersion"),
            ) {
                "Commerce catalog and localizations must have the same version."
            }
            val supportedLocales = catalog.getJSONArray("supportedLocales")
                .toStringList()
            val paidSourceIds = catalog.getJSONArray("paidSourceIds")
                .toStringList()
            val products = catalog.getJSONArray("products").let { array ->
                List(array.length()) { index ->
                    parseProduct(array.getJSONObject(index))
                }
            }
            val localizationObject = localizationPayload.getJSONObject("locales")
            val localizations = localizationObject.keys().asSequence()
                .associateWith { code ->
                    parseLocale(localizationObject.getJSONObject(code))
                }
            return CommerceCatalog(
                catalogVersion = catalogVersion,
                supportedLocales = supportedLocales,
                paidSourceIds = paidSourceIds,
                products = products,
                localizations = localizations,
            )
        }

        private fun parseProduct(json: JSONObject): CommerceProductDefinition {
            val grant = json.optJSONObject("grant")?.let { grantJson ->
                val allowances = grantJson.getJSONObject("monthlyAllowances")
                CommerceSubscriptionGrant(
                    historyWeeks = grantJson.getInt("historyWeeks"),
                    watchlistSlots = grantJson.getInt("watchlistSlots"),
                    monthlyAllowances = CommerceDestination.entries
                        .filter { it != CommerceDestination.History }
                        .associateWith {
                            allowances.getInt(it.wireValue)
                        },
                )
            }
            return CommerceProductDefinition(
                id = json.getString("id"),
                storeType = json.getString("storeType"),
                family = json.getString("family"),
                tier = json.optString("tier").ifBlank { null },
                billingPeriod = json.optString("billingPeriod").ifBlank { null },
                destination = CommerceDestination.from(
                    json.getString("destination"),
                ),
                quantity = if (json.has("quantity")) {
                    json.getInt("quantity")
                } else {
                    null
                },
                grant = grant,
            )
        }

        private fun parseLocale(json: JSONObject): CommerceLocaleText {
            val destinationsObject = json.getJSONObject("destinations")
            val storeObject = json.getJSONObject("store")
            val periodsObject = json.getJSONObject("periods")
            val subscriptionsObject = json.getJSONObject("subscriptions")
            val familiesObject = json.getJSONObject("families")
            val toolkitObject = json.getJSONObject("toolkit")
            return CommerceLocaleText(
                thankYouTitle = json.getString("thankYouTitle"),
                thankYouMessage = json.getString("thankYouMessage"),
                openDestination = json.getString("openDestination"),
                purchase = json.getString("purchase"),
                restore = json.getString("restore"),
                restored = json.getString("restored"),
                balance = json.getString("balance"),
                pending = json.getString("pending"),
                failed = json.getString("failed"),
                noCharge = json.getString("noCharge"),
                toolkit = toolkitObject.keys().asSequence().associateWith {
                    toolkitObject.getString(it)
                },
                store = CommerceStoreText(
                    title = storeObject.getString("title"),
                    plansTitle = storeObject.getString("plansTitle"),
                    optionsEyebrow = storeObject.getString("optionsEyebrow"),
                    allowanceDisclosure = storeObject.getString(
                        "allowanceDisclosure",
                    ),
                    subscriptionsTitle = storeObject.getString(
                        "subscriptionsTitle",
                    ),
                    oneTimeTitle = storeObject.getString("oneTimeTitle"),
                    unavailable = storeObject.getString("unavailable"),
                    done = storeObject.getString("done"),
                    later = storeObject.getString("later"),
                    storeButton = storeObject.getString("storeButton"),
                    legalDisclosure = storeObject.getString(
                        "legalDisclosure",
                    ),
                ),
                destinations = CommerceDestination.entries.associateWith {
                    destinationsObject.getString(it.wireValue)
                },
                periods = periodsObject.keys().asSequence().associateWith {
                    periodsObject.getString(it)
                },
                subscriptions = subscriptionsObject.keys().asSequence()
                    .associateWith {
                        val item = subscriptionsObject.getJSONObject(it)
                        CommerceSubscriptionText(
                            name = item.getString("name"),
                            description = item.getString("description"),
                        )
                    },
                families = familiesObject.keys().asSequence().associateWith {
                    val item = familiesObject.getJSONObject(it)
                    CommerceFamilyText(
                        name = item.getString("name"),
                        description = item.getString("description"),
                    )
                },
            )
        }
    }
}

private fun org.json.JSONArray.toStringList(): List<String> =
    List(length()) { getString(it) }
