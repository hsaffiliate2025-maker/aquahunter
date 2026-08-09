package com.hotseason.aquahunter.commerce

import com.hotseason.aquahunter.data.AuthorizedMarketSeries
import com.hotseason.aquahunter.data.MarketDataPoint
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class CommerceAnalyticsTest {
    @Test
    fun `snapshot uses authorized observations`() {
        val result = CommerceAnalytics.snapshot(
            series("01", (10..21).map(Int::toDouble)),
        )

        assertEquals(21.0, result.pricePerKg, 0.000001)
        assertEquals(15.5, result.average12Week, 0.000001)
        assertEquals(10.0, result.low12Week, 0.000001)
        assertEquals(21.0, result.high12Week, 0.000001)
        assertEquals("ssb-statbank-03024", result.sourceId)
    }

    @Test
    fun `comparison uses latest common official period`() {
        val result = CommerceAnalytics.compare(
            series("01", listOf(60.0, 70.0, 80.0)),
            series("02", listOf(50.0, 55.0, 64.0)),
        )

        assertEquals("2026U03", result.periodCode)
        assertEquals(16.0, result.absoluteSpreadPerKg, 0.000001)
        assertEquals(25.0, result.spreadPercentOfSecond, 0.000001)
    }

    @Test
    fun `seasonality uses multiple historical years`() {
        val result = CommerceAnalytics.seasonality(
            series(
                commodityCode = "01",
                points = listOf(
                    MarketDataPoint("2023U30", 50.0, 1.0),
                    MarketDataPoint("2024U30", 60.0, 1.0),
                    MarketDataPoint("2025U30", 70.0, 1.0),
                    MarketDataPoint("2026U30", 72.0, 1.0),
                ),
            ),
        )

        assertEquals(3, result.sampleYears)
        assertEquals(60.0, result.historicalAverage, 0.000001)
        assertEquals(20.0, result.differencePercent, 0.000001)
    }

    @Test
    fun `landed cost includes freight tariff and loss`() {
        val result = CommerceAnalytics.landedCost(
            LandedCostInput(
                sourcePricePerKg = 100.0,
                sourceCurrencyCode = "NOK",
                targetCurrencyCode = "USD",
                targetCurrencyPerSourceCurrency = 0.1,
                freightPerKgTargetCurrency = 2.0,
                tariffPercent = 10.0,
                lossPercent = 10.0,
            ),
        )

        assertEquals(10.0, result.convertedSourcePricePerKg, 0.000001)
        assertEquals(13.2, result.subtotalBeforeLoss, 0.000001)
        assertEquals(14.666666, result.landedCostPerSaleableKg, 0.000001)
    }

    @Test
    fun `csv contains provenance and every point`() {
        val csv = CommerceAnalytics.csv(
            series("02", listOf(60.0, 61.0)),
        ).toString(Charsets.UTF_8)

        assertTrue(csv.contains("source_id,commodity_code,period"))
        assertTrue(csv.contains("ssb-statbank-03024,02,2026U01"))
        assertEquals(3, csv.trim().lines().size)
    }

    private fun series(
        commodityCode: String,
        prices: List<Double> = emptyList(),
        points: List<MarketDataPoint>? = null,
    ) = AuthorizedMarketSeries(
        id = if (commodityCode == "01") "fresh" else "frozen",
        species = "Atlantic Salmon",
        scientificName = "Salmo salar",
        geography = "Norway",
        countryCode = "NO",
        benchmark = "Official benchmark",
        commodityCode = commodityCode,
        commodityForm = if (commodityCode == "01") "Fresh" else "Frozen",
        currencyCode = "NOK",
        unit = "kg",
        sourceId = "ssb-statbank-03024",
        sourceUrl = "https://www.ssb.no/en/statbank1/table/03024",
        licenseName = "CC BY 4.0",
        licenseUrl = "https://creativecommons.org/licenses/by/4.0/",
        attribution = "Source: Statistics Norway, table 03024",
        providerUpdatedAt = null,
        retrievedAt = "2026-07-30T00:00:00Z",
        latency = "Weekly",
        points = points ?: prices.mapIndexed { index, price ->
            MarketDataPoint(
                periodCode = "2026U%02d".format(index + 1),
                pricePerKg = price,
                volumeTonnes = 1.0,
            )
        },
    )
}
