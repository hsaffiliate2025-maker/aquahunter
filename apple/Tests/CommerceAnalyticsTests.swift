import Foundation
import XCTest

#if os(iOS)
@testable import AquaHunterIOS
#elseif os(macOS)
@testable import AquaHunterMac
#endif

final class CommerceAnalyticsTests: XCTestCase {
    func testSnapshotUsesOnlyAuthorizedObservations() throws {
        let series = makeSeries(
            commodityCode: "01",
            prices: Array(10 ... 21).map(Double.init)
        )
        let result = try CommerceAnalytics.snapshot(series: series)

        XCTAssertEqual(result.pricePerKg, 21)
        XCTAssertEqual(result.average12Week, 15.5, accuracy: 0.000001)
        XCTAssertEqual(result.low12Week, 10)
        XCTAssertEqual(result.high12Week, 21)
        XCTAssertEqual(result.sourceID, "ssb-statbank-03024")
    }

    func testComparisonUsesLatestCommonOfficialPeriod() throws {
        let fresh = makeSeries(
            commodityCode: "01",
            prices: [60, 70, 80]
        )
        let frozen = makeSeries(
            commodityCode: "02",
            prices: [50, 55, 64]
        )
        let result = try CommerceAnalytics.compare(
            first: fresh,
            second: frozen
        )

        XCTAssertEqual(result.periodCode, "2026U03")
        XCTAssertEqual(result.absoluteSpreadPerKg, 16, accuracy: 0.000001)
        XCTAssertEqual(result.spreadPercentOfSecond, 25, accuracy: 0.000001)
        XCTAssertEqual(result.firstCommodityCode, "01")
        XCTAssertEqual(result.secondCommodityCode, "02")
    }

    func testSeasonalityRequiresAndUsesMultipleYears() throws {
        let series = makeSeries(
            commodityCode: "01",
            explicitPoints: [
                .init(periodCode: "2023U30", pricePerKg: 50, volumeTonnes: 1),
                .init(periodCode: "2024U30", pricePerKg: 60, volumeTonnes: 1),
                .init(periodCode: "2025U30", pricePerKg: 70, volumeTonnes: 1),
                .init(periodCode: "2026U30", pricePerKg: 72, volumeTonnes: 1),
            ]
        )
        let result = try CommerceAnalytics.seasonality(series: series)

        XCTAssertEqual(result.sampleYears, 3)
        XCTAssertEqual(result.historicalAverage, 60, accuracy: 0.000001)
        XCTAssertEqual(result.differencePercent, 20, accuracy: 0.000001)
    }

    func testLandedCostIncludesFreightTariffAndLoss() throws {
        let result = try CommerceAnalytics.landedCost(
            input: .init(
                sourcePricePerKg: 100,
                sourceCurrencyCode: "NOK",
                targetCurrencyCode: "USD",
                targetCurrencyPerSourceCurrency: 0.1,
                freightPerKgTargetCurrency: 2,
                tariffPercent: 10,
                lossPercent: 10
            )
        )

        XCTAssertEqual(result.convertedSourcePricePerKg, 10, accuracy: 0.000001)
        XCTAssertEqual(result.subtotalBeforeLoss, 13.2, accuracy: 0.000001)
        XCTAssertEqual(result.landedCostPerSaleableKg, 14.666666, accuracy: 0.000001)
    }

    func testCSVContainsProvenanceAndEveryPoint() throws {
        let data = try CommerceAnalytics.csvData(
            series: makeSeries(commodityCode: "02", prices: [60, 61])
        )
        let csv = String(decoding: data, as: UTF8.self)

        XCTAssertTrue(csv.contains("source_id,commodity_code,period"))
        XCTAssertTrue(csv.contains("ssb-statbank-03024,02,2026U01"))
        XCTAssertEqual(csv.split(separator: "\n").count, 3)
    }

    private func makeSeries(
        commodityCode: String,
        prices: [Double] = [],
        explicitPoints: [MarketDataPoint]? = nil
    ) -> ProductionMarketSeries {
        let points = explicitPoints ?? prices.enumerated().map { index, price in
            MarketDataPoint(
                periodCode: String(format: "2026U%02d", index + 1),
                pricePerKg: price,
                volumeTonnes: 1
            )
        }
        return ProductionMarketSeries(
            id: commodityCode == "01" ? "fresh" : "frozen",
            species: "Atlantic Salmon",
            scientificName: "Salmo salar",
            geography: "Norway",
            countryCode: "NO",
            benchmark: "Official benchmark",
            commodityCode: commodityCode,
            commodityForm: commodityCode == "01" ? "Fresh" : "Frozen",
            currencyCode: "NOK",
            unit: "kg",
            sourceID: "ssb-statbank-03024",
            sourceURL: URL(string: "https://www.ssb.no/en/statbank1/table/03024")!,
            licenseName: "CC BY 4.0",
            licenseURL: URL(string: "https://creativecommons.org/licenses/by/4.0/")!,
            attribution: "Source: Statistics Norway, table 03024",
            providerUpdatedAt: nil,
            retrievedAt: Date(timeIntervalSince1970: 0),
            latency: "Weekly",
            points: points
        )
    }
}
