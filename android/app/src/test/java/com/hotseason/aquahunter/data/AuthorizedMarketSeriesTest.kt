package com.hotseason.aquahunter.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class AuthorizedMarketSeriesTest {
    @Test
    fun `change percent uses the two latest official observations`() {
        val series = authorizedSeries(
            listOf(
                MarketDataPoint("2026U27", 67.31, 25_000.0),
                MarketDataPoint("2026U28", 69.54, 26_117.0),
            ),
        )

        assertEquals(3.313029, series.changePercent!!, 0.000001)
    }

    @Test
    fun `change percent is absent with one observation`() {
        val series = authorizedSeries(
            listOf(MarketDataPoint("2026U28", 69.54, 26_117.0)),
        )

        assertNull(series.changePercent)
    }

    private fun authorizedSeries(points: List<MarketDataPoint>) = AuthorizedMarketSeries(
        id = "ssb-03024-fresh-salmon",
        species = "Atlantic Salmon",
        scientificName = "Salmo salar",
        geography = "Norway",
        countryCode = "NO",
        benchmark = "Norway farmed salmon export benchmark",
        commodityForm = "Fresh or chilled, farmed",
        currencyCode = "NOK",
        unit = "kg",
        sourceId = "ssb-statbank-03024",
        sourceUrl = "https://www.ssb.no/en/statbank1/table/03024",
        licenseName = "CC BY 4.0",
        licenseUrl = "https://creativecommons.org/licenses/by/4.0/",
        attribution = "Source: Statistics Norway, table 03024",
        providerUpdatedAt = null,
        retrievedAt = "2026-07-19T00:00:00Z",
        latency = "Weekly official statistic",
        points = points,
    )
}
