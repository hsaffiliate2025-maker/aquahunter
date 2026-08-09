package com.hotseason.aquahunter.commerce

import com.hotseason.aquahunter.data.AuthorizedMarketSeries
import java.util.Locale
import java.util.UUID

sealed class CommerceAnalyticsException(message: String) : Exception(message) {
    data object InsufficientData :
        CommerceAnalyticsException("The authorized source does not contain enough observations.")

    data object IncomparableSeries :
        CommerceAnalyticsException("The selected official series are not comparable.")

    data object InvalidAssumption :
        CommerceAnalyticsException("Enter finite, nonnegative cost assumptions.")
}

data class MarketSnapshotResult(
    val seriesId: String,
    val commodityCode: String,
    val periodCode: String,
    val pricePerKg: Double,
    val changePercent: Double?,
    val average12Week: Double,
    val low12Week: Double,
    val high12Week: Double,
    val sourceId: String,
    val attribution: String,
    val retrievedAt: String,
)

data class MarketComparisonResult(
    val periodCode: String,
    val firstCommodityCode: String,
    val secondCommodityCode: String,
    val firstPricePerKg: Double,
    val secondPricePerKg: Double,
    val absoluteSpreadPerKg: Double,
    val spreadPercentOfSecond: Double,
    val currencyCode: String,
    val unit: String,
    val sourceId: String,
)

data class SeasonalityResult(
    val seriesId: String,
    val commodityCode: String,
    val weekOfYear: Int,
    val sampleYears: Int,
    val historicalAverage: Double,
    val latestPrice: Double,
    val differencePercent: Double,
    val sourceId: String,
)

data class LandedCostInput(
    val sourcePricePerKg: Double,
    val sourceCurrencyCode: String,
    val targetCurrencyCode: String,
    val targetCurrencyPerSourceCurrency: Double,
    val freightPerKgTargetCurrency: Double,
    val tariffPercent: Double,
    val lossPercent: Double,
)

data class LandedCostResult(
    val convertedSourcePricePerKg: Double,
    val subtotalBeforeLoss: Double,
    val landedCostPerSaleableKg: Double,
    val targetCurrencyCode: String,
)

data class PriceAlertRule(
    val id: String = UUID.randomUUID().toString(),
    val seriesId: String,
    val threshold: Double,
    val direction: Direction,
    val currencyCode: String,
    val unit: String,
    val lastDeliveredPeriodCode: String? = null,
) {
    enum class Direction {
        Above,
        Below,
    }

    fun matches(series: AuthorizedMarketSeries): Boolean {
        val latest = series.latest ?: return false
        if (series.id != seriesId ||
            series.currencyCode != currencyCode ||
            series.unit != unit ||
            latest.periodCode == lastDeliveredPeriodCode
        ) {
            return false
        }
        return when (direction) {
            Direction.Above -> latest.pricePerKg >= threshold
            Direction.Below -> latest.pricePerKg <= threshold
        }
    }
}

object CommerceAnalytics {
    fun snapshot(series: AuthorizedMarketSeries): MarketSnapshotResult {
        val latest = series.latest ?: throw CommerceAnalyticsException.InsufficientData
        val window = series.points.takeLast(12)
        if (window.isEmpty()) throw CommerceAnalyticsException.InsufficientData
        val prices = window.map { it.pricePerKg }
        return MarketSnapshotResult(
            seriesId = series.id,
            commodityCode = series.commodityCode,
            periodCode = latest.periodCode,
            pricePerKg = latest.pricePerKg,
            changePercent = series.changePercent,
            average12Week = prices.average(),
            low12Week = prices.min(),
            high12Week = prices.max(),
            sourceId = series.sourceId,
            attribution = series.attribution,
            retrievedAt = series.retrievedAt,
        )
    }

    fun compare(
        first: AuthorizedMarketSeries,
        second: AuthorizedMarketSeries,
    ): MarketComparisonResult {
        if (first.id == second.id ||
            first.sourceId != second.sourceId ||
            first.currencyCode != second.currencyCode ||
            first.unit != second.unit
        ) {
            throw CommerceAnalyticsException.IncomparableSeries
        }
        val secondByPeriod = second.points.associateBy { it.periodCode }
        val firstPoint = first.points.asReversed().firstOrNull {
            secondByPeriod.containsKey(it.periodCode)
        } ?: throw CommerceAnalyticsException.IncomparableSeries
        val secondPoint = secondByPeriod[firstPoint.periodCode]
            ?: throw CommerceAnalyticsException.IncomparableSeries
        if (secondPoint.pricePerKg == 0.0) {
            throw CommerceAnalyticsException.IncomparableSeries
        }
        val spread = firstPoint.pricePerKg - secondPoint.pricePerKg
        return MarketComparisonResult(
            periodCode = firstPoint.periodCode,
            firstCommodityCode = first.commodityCode,
            secondCommodityCode = second.commodityCode,
            firstPricePerKg = firstPoint.pricePerKg,
            secondPricePerKg = secondPoint.pricePerKg,
            absoluteSpreadPerKg = spread,
            spreadPercentOfSecond = spread / secondPoint.pricePerKg * 100,
            currencyCode = first.currencyCode,
            unit = first.unit,
            sourceId = first.sourceId,
        )
    }

    fun seasonality(series: AuthorizedMarketSeries): SeasonalityResult {
        val latest = series.latest ?: throw CommerceAnalyticsException.InsufficientData
        val week = weekNumber(latest.periodCode)
            ?: throw CommerceAnalyticsException.InsufficientData
        val comparable = series.points.filter { weekNumber(it.periodCode) == week }
        if (comparable.size < 3) throw CommerceAnalyticsException.InsufficientData
        val historical = comparable.dropLast(1)
        if (historical.size < 2) throw CommerceAnalyticsException.InsufficientData
        val average = historical.map { it.pricePerKg }.average()
        if (average == 0.0 || !average.isFinite()) {
            throw CommerceAnalyticsException.InsufficientData
        }
        return SeasonalityResult(
            seriesId = series.id,
            commodityCode = series.commodityCode,
            weekOfYear = week,
            sampleYears = historical.size,
            historicalAverage = average,
            latestPrice = latest.pricePerKg,
            differencePercent = (latest.pricePerKg - average) / average * 100,
            sourceId = series.sourceId,
        )
    }

    fun landedCost(input: LandedCostInput): LandedCostResult {
        val values = listOf(
            input.sourcePricePerKg,
            input.targetCurrencyPerSourceCurrency,
            input.freightPerKgTargetCurrency,
            input.tariffPercent,
            input.lossPercent,
        )
        if (values.any { !it.isFinite() || it < 0 } ||
            input.targetCurrencyPerSourceCurrency <= 0 ||
            input.lossPercent >= 100
        ) {
            throw CommerceAnalyticsException.InvalidAssumption
        }
        val converted = input.sourcePricePerKg * input.targetCurrencyPerSourceCurrency
        val withFreight = converted + input.freightPerKgTargetCurrency
        val subtotal = withFreight * (1 + input.tariffPercent / 100)
        val landed = subtotal / (1 - input.lossPercent / 100)
        if (!landed.isFinite()) throw CommerceAnalyticsException.InvalidAssumption
        return LandedCostResult(
            convertedSourcePricePerKg = converted,
            subtotalBeforeLoss = subtotal,
            landedCostPerSaleableKg = landed,
            targetCurrencyCode = input.targetCurrencyCode,
        )
    }

    fun csv(series: AuthorizedMarketSeries): ByteArray {
        if (series.points.isEmpty()) throw CommerceAnalyticsException.InsufficientData
        val rows = mutableListOf(
            "source_id,commodity_code,period,price_per_kg,currency,unit,volume_tonnes",
        )
        series.points.forEach { point ->
            rows += listOf(
                series.sourceId,
                series.commodityCode,
                point.periodCode,
                "%.4f".format(Locale.US, point.pricePerKg),
                series.currencyCode,
                series.unit,
                point.volumeTonnes?.let { "%.4f".format(Locale.US, it) }.orEmpty(),
            ).joinToString(",") { csvEscape(it) }
        }
        return (rows.joinToString("\n") + "\n").toByteArray(Charsets.UTF_8)
    }

    private fun weekNumber(periodCode: String): Int? =
        periodCode.substringAfterLast("U", missingDelimiterValue = "")
            .toIntOrNull()

    private fun csvEscape(value: String): String {
        if (value.none { it == ',' || it == '"' || it == '\n' }) return value
        return "\"${value.replace("\"", "\"\"")}\""
    }
}
