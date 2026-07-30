import Foundation

enum CommerceAnalyticsError: LocalizedError, Equatable {
    case insufficientData
    case incomparableSeries
    case invalidAssumption

    var errorDescription: String? {
        switch self {
        case .insufficientData:
            "The authorized source does not contain enough observations for this result."
        case .incomparableSeries:
            "The selected series do not share a comparable official period and unit."
        case .invalidAssumption:
            "Enter finite, nonnegative cost assumptions and an exchange rate above zero."
        }
    }
}

struct MarketSnapshotResult: Equatable {
    let seriesID: String
    let commodityCode: String
    let periodCode: String
    let pricePerKg: Double
    let changePercent: Double?
    let average12Week: Double
    let low12Week: Double
    let high12Week: Double
    let sourceID: String
    let attribution: String
    let retrievedAt: Date
}

struct MarketComparisonResult: Equatable {
    let periodCode: String
    let firstCommodityCode: String
    let secondCommodityCode: String
    let firstPricePerKg: Double
    let secondPricePerKg: Double
    let absoluteSpreadPerKg: Double
    let spreadPercentOfSecond: Double
    let currencyCode: String
    let unit: String
    let sourceID: String
}

struct SeasonalityResult: Equatable {
    let seriesID: String
    let commodityCode: String
    let weekOfYear: Int
    let sampleYears: Int
    let historicalAverage: Double
    let latestPrice: Double
    let differencePercent: Double
    let sourceID: String
}

struct LandedCostInput: Equatable {
    let sourcePricePerKg: Double
    let sourceCurrencyCode: String
    let targetCurrencyCode: String
    let targetCurrencyPerSourceCurrency: Double
    let freightPerKgTargetCurrency: Double
    let tariffPercent: Double
    let lossPercent: Double
}

struct LandedCostResult: Equatable {
    let convertedSourcePricePerKg: Double
    let subtotalBeforeLoss: Double
    let landedCostPerSaleableKg: Double
    let targetCurrencyCode: String
}

struct PriceAlertRule: Codable, Equatable, Identifiable {
    enum Direction: String, Codable, CaseIterable {
        case above
        case below
    }

    let id: UUID
    let seriesID: String
    let threshold: Double
    let direction: Direction
    let currencyCode: String
    let unit: String
    var lastDeliveredPeriodCode: String?

    func matches(_ series: ProductionMarketSeries) -> Bool {
        guard
            series.id == seriesID,
            series.currencyCode == currencyCode,
            series.unit == unit,
            let latest = series.latest,
            latest.periodCode != lastDeliveredPeriodCode
        else { return false }
        switch direction {
        case .above: return latest.pricePerKg >= threshold
        case .below: return latest.pricePerKg <= threshold
        }
    }
}

enum CommerceAnalytics {
    static func snapshot(
        series: ProductionMarketSeries
    ) throws -> MarketSnapshotResult {
        let window = Array(series.points.suffix(12))
        guard
            let latest = series.latest,
            !window.isEmpty
        else {
            throw CommerceAnalyticsError.insufficientData
        }
        let prices = window.map(\.pricePerKg)
        return MarketSnapshotResult(
            seriesID: series.id,
            commodityCode: series.commodityCode,
            periodCode: latest.periodCode,
            pricePerKg: latest.pricePerKg,
            changePercent: series.changePercent,
            average12Week: prices.reduce(0, +) / Double(prices.count),
            low12Week: prices.min()!,
            high12Week: prices.max()!,
            sourceID: series.sourceID,
            attribution: series.attribution,
            retrievedAt: series.retrievedAt
        )
    }

    static func compare(
        first: ProductionMarketSeries,
        second: ProductionMarketSeries
    ) throws -> MarketComparisonResult {
        guard
            first.id != second.id,
            first.sourceID == second.sourceID,
            first.currencyCode == second.currencyCode,
            first.unit == second.unit
        else {
            throw CommerceAnalyticsError.incomparableSeries
        }

        let secondByPeriod = Dictionary(
            uniqueKeysWithValues: second.points.map { ($0.periodCode, $0) }
        )
        guard
            let firstPoint = first.points.reversed().first(
                where: { secondByPeriod[$0.periodCode] != nil }
            ),
            let secondPoint = secondByPeriod[firstPoint.periodCode],
            secondPoint.pricePerKg != 0
        else {
            throw CommerceAnalyticsError.incomparableSeries
        }
        let spread = firstPoint.pricePerKg - secondPoint.pricePerKg
        return MarketComparisonResult(
            periodCode: firstPoint.periodCode,
            firstCommodityCode: first.commodityCode,
            secondCommodityCode: second.commodityCode,
            firstPricePerKg: firstPoint.pricePerKg,
            secondPricePerKg: secondPoint.pricePerKg,
            absoluteSpreadPerKg: spread,
            spreadPercentOfSecond: spread / secondPoint.pricePerKg * 100,
            currencyCode: first.currencyCode,
            unit: first.unit,
            sourceID: first.sourceID
        )
    }

    static func seasonality(
        series: ProductionMarketSeries
    ) throws -> SeasonalityResult {
        guard
            let latest = series.latest,
            let week = weekNumber(from: latest.periodCode)
        else {
            throw CommerceAnalyticsError.insufficientData
        }
        let comparable = series.points.filter {
            weekNumber(from: $0.periodCode) == week
        }
        guard comparable.count >= 3 else {
            throw CommerceAnalyticsError.insufficientData
        }
        let historical = comparable.dropLast()
        guard historical.count >= 2 else {
            throw CommerceAnalyticsError.insufficientData
        }
        let average = historical.map(\.pricePerKg).reduce(0, +)
            / Double(historical.count)
        guard average != 0 else {
            throw CommerceAnalyticsError.insufficientData
        }
        return SeasonalityResult(
            seriesID: series.id,
            commodityCode: series.commodityCode,
            weekOfYear: week,
            sampleYears: historical.count,
            historicalAverage: average,
            latestPrice: latest.pricePerKg,
            differencePercent: (latest.pricePerKg - average) / average * 100,
            sourceID: series.sourceID
        )
    }

    static func landedCost(
        input: LandedCostInput
    ) throws -> LandedCostResult {
        let values = [
            input.sourcePricePerKg,
            input.targetCurrencyPerSourceCurrency,
            input.freightPerKgTargetCurrency,
            input.tariffPercent,
            input.lossPercent,
        ]
        guard
            values.allSatisfy({ $0.isFinite && $0 >= 0 }),
            input.targetCurrencyPerSourceCurrency > 0,
            input.lossPercent < 100
        else {
            throw CommerceAnalyticsError.invalidAssumption
        }
        let converted =
            input.sourcePricePerKg * input.targetCurrencyPerSourceCurrency
        let withFreight = converted + input.freightPerKgTargetCurrency
        let subtotal = withFreight * (1 + input.tariffPercent / 100)
        let landed = subtotal / (1 - input.lossPercent / 100)
        guard landed.isFinite else {
            throw CommerceAnalyticsError.invalidAssumption
        }
        return LandedCostResult(
            convertedSourcePricePerKg: converted,
            subtotalBeforeLoss: subtotal,
            landedCostPerSaleableKg: landed,
            targetCurrencyCode: input.targetCurrencyCode
        )
    }

    static func csvData(
        series: ProductionMarketSeries
    ) throws -> Data {
        guard !series.points.isEmpty else {
            throw CommerceAnalyticsError.insufficientData
        }
        var rows = [
            "source_id,commodity_code,period,price_per_kg,currency,unit,volume_tonnes",
        ]
        rows.append(contentsOf: series.points.map { point in
            [
                series.sourceID,
                series.commodityCode,
                point.periodCode,
                String(format: "%.4f", point.pricePerKg),
                series.currencyCode,
                series.unit,
                point.volumeTonnes.map { String(format: "%.4f", $0) } ?? "",
            ]
            .map(csvEscape)
            .joined(separator: ",")
        })
        guard let data = (rows.joined(separator: "\n") + "\n").data(
            using: .utf8
        ) else {
            throw CommerceAnalyticsError.insufficientData
        }
        return data
    }

    private static func weekNumber(from periodCode: String) -> Int? {
        guard
            let marker = periodCode.range(of: "U", options: .backwards),
            marker.upperBound < periodCode.endIndex
        else { return nil }
        return Int(periodCode[marker.upperBound...])
    }

    private static func csvEscape(_ value: String) -> String {
        guard value.contains(where: { ",\"\n".contains($0) }) else {
            return value
        }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
