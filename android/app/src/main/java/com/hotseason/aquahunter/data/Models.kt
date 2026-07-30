package com.hotseason.aquahunter.data

data class MarketPrice(
    val id: String,
    val species: String,
    val scientificName: String,
    val market: String,
    val city: String,
    val countryCode: String,
    val averageUsdKg: Double,
    val lowUsdKg: Double,
    val highUsdKg: Double,
    val changePercent: Double,
    val volumeTons: Int,
    val grade: String,
    val freshness: String,
    val source: String,
    val updatedAt: String,
    val trend: List<Float>,
)

data class PriceCandle(
    val id: String,
    val label: String,
    val open: Double,
    val high: Double,
    val low: Double,
    val close: Double,
)

data class MarketDataPoint(
    val periodCode: String,
    val pricePerKg: Double,
    val volumeTonnes: Double?,
)

data class AuthorizedMarketSeries(
    val id: String,
    val species: String,
    val scientificName: String,
    val geography: String,
    val countryCode: String,
    val benchmark: String,
    val commodityCode: String,
    val commodityForm: String,
    val currencyCode: String,
    val unit: String,
    val sourceId: String,
    val sourceUrl: String,
    val licenseName: String,
    val licenseUrl: String,
    val attribution: String,
    val providerUpdatedAt: String?,
    val retrievedAt: String,
    val latency: String,
    val points: List<MarketDataPoint>,
) {
    val latest: MarketDataPoint?
        get() = points.lastOrNull()

    val previous: MarketDataPoint?
        get() = points.dropLast(1).lastOrNull()

    val changePercent: Double?
        get() {
            val latestValue = latest?.pricePerKg ?: return null
            val previousValue = previous?.pricePerKg ?: return null
            if (previousValue == 0.0) return null
            return (latestValue - previousValue) / previousValue * 100
        }
}

sealed interface AuthorizedMarketLoadState {
    data object Loading : AuthorizedMarketLoadState
    data class Loaded(val series: List<AuthorizedMarketSeries>) : AuthorizedMarketLoadState
    data class Unavailable(val message: String) : AuthorizedMarketLoadState
}

data class Buyer(
    val id: String,
    val name: String,
    val city: String,
    val countryCode: String,
    val type: String,
    val products: List<String>,
    val importShipments: Int,
    val lastActive: String,
    val website: String,
    val emailMasked: String,
    val verified: Boolean,
    val source: String,
)

data class PortLanding(
    val id: String,
    val port: String,
    val countryCode: String,
    val species: String,
    val landingTons: Int,
    val vesselCount: Int,
    val averageUsdKg: Double,
    val changePercent: Double,
    val observedDate: String,
    val source: String,
)

data class TradeFlow(
    val id: String,
    val origin: String,
    val destination: String,
    val species: String,
    val volumeTons: Int,
    val valueMillionUsd: Double,
    val growthPercent: Double,
    val hsCode: String,
    val period: String,
    val source: String,
)

data class Vessel(
    val id: String,
    val name: String,
    val mmsiMasked: String,
    val flagCode: String,
    val type: String,
    val zone: String,
    val latitude: Double,
    val longitude: Double,
    val speedKnots: Double,
    val courseDegrees: Int,
    val lastPort: String,
    val lastSignal: String,
    val visibility: String,
    val source: String,
)

data class RadarPrediction(
    val species: String,
    val zone: String,
    val probability: Int,
    val confidence: String,
    val validWindow: String,
    val modelVersion: String,
    val dataCompleteness: Int,
    val factors: List<RadarFactor>,
    val sources: List<RadarDataSource>,
)

data class RadarFactor(
    val label: String,
    val value: String,
    val impact: Int,
)

data class RadarDataSource(
    val provider: String,
    val signal: String,
    val cadence: String,
)

data class AquaAnswer(
    val title: String,
    val body: String,
    val metrics: List<Pair<String, String>>,
    val citations: List<String>,
)
