package com.hotseason.aquahunter.commerce

import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CommerceLedgerTest {
    private val catalog = CommerceCatalog(
        catalogVersion = "test",
        supportedLocales = listOf("en"),
        paidSourceIds = listOf("ssb-statbank-03024"),
        products = listOf(
            CommerceProductDefinition(
                id = "aquahunter.snapshot.5",
                storeType = "consumable",
                family = "snapshot",
                tier = null,
                billingPeriod = null,
                destination = CommerceDestination.Snapshot,
                quantity = 5,
                grant = null,
            ),
            CommerceProductDefinition(
                id = "aquahunter.markets.plus.monthly",
                storeType = "autoRenewableSubscription",
                family = "markets",
                tier = "plus",
                billingPeriod = "P1M",
                destination = CommerceDestination.History,
                quantity = null,
                grant = CommerceSubscriptionGrant(
                    historyWeeks = 156,
                    watchlistSlots = 10,
                    monthlyAllowances = mapOf(
                        CommerceDestination.Snapshot to 5,
                    ),
                ),
            ),
        ),
        localizations = emptyMap(),
    )

    @Test
    fun consumableGrantIsIdempotentAndOnlyExplicitSuccessConsumes() {
        val ledger = CommerceLedgerState()
        val product = checkNotNull(catalog.definition("aquahunter.snapshot.5"))

        assertTrue(ledger.grant("token-1", product))
        assertFalse(ledger.grant("token-1", product))
        assertEquals(5, ledger.available(CommerceDestination.Snapshot, catalog))
        assertTrue(
            ledger.consumeSuccessfulResult(
                CommerceDestination.Snapshot,
                catalog,
            ),
        )
        assertEquals(4, ledger.available(CommerceDestination.Snapshot, catalog))
    }

    @Test
    fun subscriptionAllowanceIsFinite() {
        val ledger = CommerceLedgerState()
        val product = checkNotNull(
            catalog.definition("aquahunter.markets.plus.monthly"),
        )
        ledger.grant("token-2", product)
        ledger.replaceActiveSubscriptions(setOf(product.id))
        val now = 1_782_864_000_000

        assertEquals(156, ledger.historyWeeks(catalog))
        repeat(5) {
            assertTrue(
                ledger.consumeSuccessfulResult(
                    CommerceDestination.Snapshot,
                    catalog,
                    now,
                ),
            )
        }
        assertFalse(
            ledger.consumeSuccessfulResult(
                CommerceDestination.Snapshot,
                catalog,
                now,
            ),
        )
    }

    @Test
    fun ledgerRoundTripPreservesPurchasedCredits() {
        val ledger = CommerceLedgerState()
        ledger.grant(
            "token-3",
            checkNotNull(catalog.definition("aquahunter.snapshot.5")),
        )
        val restored = CommerceLedgerState.fromJson(ledger.toJson())
        assertEquals(
            5,
            restored.available(CommerceDestination.Snapshot, catalog),
        )
    }

    @Test
    fun releaseCatalogHasAllPaidToolTranslations() {
        val releaseCatalog = loadReleaseCatalog()
        val expectedKeys = releaseCatalog.locale("en").toolkit.keys

        assertEquals(52, expectedKeys.size)
        assertEquals(12, releaseCatalog.supportedLocales.size)
        releaseCatalog.supportedLocales.forEach { languageCode ->
            assertEquals(
                expectedKeys,
                releaseCatalog.locale(languageCode).toolkit.keys,
            )
        }
    }

    @Test
    fun everyProductHasARealGrantAndLocalizedPostPurchaseRoute() {
        val releaseCatalog = loadReleaseCatalog()

        assertEquals(
            CommerceDestination.entries.toSet(),
            releaseCatalog.products.map { it.destination }.toSet(),
        )

        releaseCatalog.products.forEach { product ->
            if (product.isSubscription) {
                val grant = checkNotNull(product.grant)
                assertTrue(grant.historyWeeks > 52)
                assertTrue(grant.monthlyAllowances.values.any { it > 0 })
            } else {
                assertTrue(checkNotNull(product.quantity) > 0)
            }

            releaseCatalog.supportedLocales.forEach { languageCode ->
                val locale = releaseCatalog.locale(languageCode)
                val productText = releaseCatalog.text(product, languageCode)
                val destinationText = checkNotNull(
                    locale.destinations[product.destination],
                )
                val thankYou = locale.replace(
                    locale.thankYouMessage,
                    mapOf("product" to productText.name),
                )
                val openAction = locale.replace(
                    locale.openDestination,
                    mapOf("destination" to destinationText),
                )

                assertTrue(locale.thankYouTitle.isNotBlank())
                assertTrue(thankYou.isNotBlank())
                assertTrue(openAction.isNotBlank())
                assertFalse(thankYou.contains("{product}"))
                assertFalse(openAction.contains("{destination}"))
                assertTrue(thankYou.contains(productText.name))
                assertTrue(openAction.contains(destinationText))
            }
        }
    }

    private fun loadReleaseCatalog(): CommerceCatalog {
        val commerceDirectory = generateSequence(
            File(requireNotNull(System.getProperty("user.dir"))).absoluteFile,
        ) { it.parentFile }
            .map { it.resolve("commerce") }
            .first { it.resolve("product-catalog.json").isFile }
        return CommerceCatalog.decode(
            catalogJson = commerceDirectory.resolve("product-catalog.json")
                .readText(),
            localizationJson = commerceDirectory.resolve("localizations.json")
                .readText(),
        )
    }
}
