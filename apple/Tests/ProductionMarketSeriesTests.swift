import Foundation
import XCTest

#if os(iOS)
@testable import AquaHunterIOS
#elseif os(macOS)
@testable import AquaHunterMac
#endif

final class ProductionMarketSeriesTests: XCTestCase {
    func testChangePercentUsesTwoLatestPublishedObservations() {
        let series = makeSeries(
            points: [
                .init(periodCode: "2026U27", pricePerKg: 67.31, volumeTonnes: 25_000),
                .init(periodCode: "2026U28", pricePerKg: 69.54, volumeTonnes: 26_117),
            ]
        )

        XCTAssertNotNil(series.changePercent)
        XCTAssertEqual(series.changePercent!, 3.313029, accuracy: 0.000001)
    }

    func testChangePercentIsUnavailableWithOneObservation() {
        let series = makeSeries(
            points: [
                .init(periodCode: "2026U28", pricePerKg: 69.54, volumeTonnes: 26_117),
            ]
        )

        XCTAssertNil(series.changePercent)
    }

    func testLatestObservationPreservesOfficialPeriodAndUnits() {
        let series = makeSeries(
            points: [
                .init(periodCode: "2026U28", pricePerKg: 69.54, volumeTonnes: 26_117),
            ]
        )

        XCTAssertEqual(series.latest?.periodCode, "2026U28")
        XCTAssertEqual(series.currencyCode, "NOK")
        XCTAssertEqual(series.unit, "kg")
        XCTAssertEqual(series.sourceID, "ssb-statbank-03024")
    }

    private func makeSeries(points: [MarketDataPoint]) -> ProductionMarketSeries {
        ProductionMarketSeries(
            id: "ssb-03024-fresh-salmon",
            species: "Atlantic Salmon",
            scientificName: "Salmo salar",
            geography: "Norway",
            countryCode: "NO",
            benchmark: "Norway farmed salmon export benchmark",
            commodityForm: "Fresh or chilled, farmed",
            currencyCode: "NOK",
            unit: "kg",
            sourceID: "ssb-statbank-03024",
            sourceURL: URL(string: "https://www.ssb.no/en/statbank1/table/03024")!,
            licenseName: "CC BY 4.0",
            licenseURL: URL(string: "https://creativecommons.org/licenses/by/4.0/")!,
            attribution: "Source: Statistics Norway, table 03024",
            providerUpdatedAt: nil,
            retrievedAt: Date(timeIntervalSince1970: 0),
            latency: "Weekly official statistic",
            points: points
        )
    }
}
