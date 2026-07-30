import Combine
import Foundation

struct MarketDataPoint: Identifiable, Hashable {
    let periodCode: String
    let pricePerKg: Double
    let volumeTonnes: Double?

    var id: String { periodCode }
}

struct ProductionMarketSeries: Identifiable, Hashable {
    let id: String
    let species: String
    let scientificName: String
    let geography: String
    let countryCode: String
    let benchmark: String
    let commodityCode: String
    let commodityForm: String
    let currencyCode: String
    let unit: String
    let sourceID: String
    let sourceURL: URL
    let licenseName: String
    let licenseURL: URL
    let attribution: String
    let providerUpdatedAt: Date?
    let retrievedAt: Date
    let latency: String
    let points: [MarketDataPoint]

    var latest: MarketDataPoint? { points.last }
    var previous: MarketDataPoint? { points.dropLast().last }

    var changePercent: Double? {
        guard
            let latest,
            let previous,
            previous.pricePerKg != 0
        else { return nil }
        return (latest.pricePerKg - previous.pricePerKg) / previous.pricePerKg * 100
    }
}

enum ProductionMarketLoadState: Equatable {
    case idle
    case loading
    case loaded([ProductionMarketSeries])
    case unavailable(String)
}

@MainActor
final class ProductionMarketsStore: ObservableObject {
    @Published private(set) var state: ProductionMarketLoadState = .idle

    private let client: StatisticsNorwayMarketClient
    private let historyWeeks: Int

    init(
        client: StatisticsNorwayMarketClient = .init(),
        historyWeeks: Int = 52
    ) {
        self.client = client
        self.historyWeeks = historyWeeks
    }

    func loadIfNeeded() async {
        guard case .idle = state else { return }
        await reload()
    }

    func reload() async {
        state = .loading
        do {
            let series = try await client.fetchSalmonSeries(historyWeeks: historyWeeks)
            state = .loaded(series)
        } catch {
            state = .unavailable(
                "No authorized market data is available right now. \(error.localizedDescription)"
            )
        }
    }
}

struct StatisticsNorwayMarketClient {
    private static let endpointBase =
        "https://data.ssb.no/api/pxwebapi/v2/tables/03024/data"
    private static let sourceURL = URL(
        string: "https://www.ssb.no/en/statbank1/table/03024"
    )!
    private static let licenseURL = URL(
        string: "https://creativecommons.org/licenses/by/4.0/"
    )!

    private let session: URLSession
    private let now: () -> Date

    init(session: URLSession = .shared, now: @escaping () -> Date = Date.init) {
        self.session = session
        self.now = now
    }

    func fetchSalmonSeries(historyWeeks: Int) async throws -> [ProductionMarketSeries] {
        guard (1 ... 1_386).contains(historyWeeks) else {
            throw MarketDataError.invalidHistoryWindow
        }
        var components = URLComponents(string: Self.endpointBase)!
        components.queryItems = [
            URLQueryItem(name: "lang", value: "en"),
            URLQueryItem(name: "valueCodes[VareGrupper2]", value: "*"),
            URLQueryItem(name: "valueCodes[ContentsCode]", value: "*"),
            URLQueryItem(name: "valueCodes[Tid]", value: "top(\(historyWeeks))"),
            URLQueryItem(name: "outputFormat", value: "json-stat2"),
        ]
        guard let endpoint = components.url else {
            throw MarketDataError.invalidRequest
        }

        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 20
        request.setValue(
            "AquaHunter/1.0 (contact@hotseason.app)",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard
            let httpResponse = response as? HTTPURLResponse,
            (200 ..< 300).contains(httpResponse.statusCode)
        else {
            throw MarketDataError.invalidResponse
        }

        let payload = try JSONDecoder().decode(JSONStatDataset.self, from: data)
        guard
            payload.id == ["VareGrupper2", "ContentsCode", "Tid"],
            payload.size.count == 3,
            payload.size[0] == 2,
            payload.size[1] == 2,
            let commodityDimension = payload.dimension["VareGrupper2"],
            let timeDimension = payload.dimension["Tid"],
            let contentDimension = payload.dimension["ContentsCode"],
            let commodityCodes = commodityDimension.orderedCodes,
            let timeCodes = timeDimension.orderedCodes,
            let priceIndex = contentDimension.position(for: "Kilopris"),
            let weightIndex = contentDimension.position(for: "Vekt")
        else {
            throw MarketDataError.unsupportedSchema
        }

        let timeCount = payload.size[2]
        guard timeCodes.count == timeCount else {
            throw MarketDataError.unsupportedSchema
        }

        guard commodityCodes == ["01", "02"] else {
            throw MarketDataError.unsupportedSchema
        }

        let contentCount = payload.size[1]
        let series = try commodityCodes.enumerated().map { commodityIndex, commodityCode in
            var points: [MarketDataPoint] = []
            for (timeIndex, periodCode) in timeCodes.enumerated() {
                let commodityOffset = commodityIndex * contentCount * timeCount
                let priceOffset = commodityOffset + priceIndex * timeCount + timeIndex
                let weightOffset = commodityOffset + weightIndex * timeCount + timeIndex
                guard
                    payload.value.indices.contains(priceOffset),
                    let price = payload.value[priceOffset],
                    price.isFinite,
                    price > 0
                else {
                    continue
                }
                let weight = payload.value.indices.contains(weightOffset)
                    ? payload.value[weightOffset]
                    : nil
                points.append(
                    MarketDataPoint(
                        periodCode: periodCode,
                        pricePerKg: price,
                        volumeTonnes: weight
                    )
                )
            }

            guard !points.isEmpty else {
                throw MarketDataError.noPublishedValues
            }

            let isFresh = commodityCode == "01"
            return ProductionMarketSeries(
                id: isFresh
                    ? "ssb-03024-fresh-salmon"
                    : "ssb-03024-frozen-salmon",
                species: "Atlantic Salmon",
                scientificName: "Salmo salar",
                geography: "Norway",
                countryCode: "NO",
                benchmark: isFresh
                    ? "Norway fresh/chilled farmed salmon export benchmark"
                    : "Norway frozen farmed salmon export benchmark",
                commodityCode: commodityCode,
                commodityForm: isFresh
                    ? "Fresh or chilled, farmed"
                    : "Frozen, farmed",
                currencyCode: "NOK",
                unit: "kg",
                sourceID: "ssb-statbank-03024",
                sourceURL: Self.sourceURL,
                licenseName: "CC BY 4.0",
                licenseURL: Self.licenseURL,
                attribution: "Source: Statistics Norway, table 03024, commodity \(commodityCode)",
                providerUpdatedAt: ISO8601DateFormatter().date(from: payload.updated ?? ""),
                retrievedAt: now(),
                latency: "Weekly official statistic",
                points: points
            )
        }
        return series
    }
}

private enum MarketDataError: LocalizedError {
    case invalidHistoryWindow
    case invalidRequest
    case invalidResponse
    case unsupportedSchema
    case noPublishedValues

    var errorDescription: String? {
        switch self {
        case .invalidHistoryWindow:
            "The requested history window is outside the official dataset."
        case .invalidRequest:
            "The official data request could not be created."
        case .invalidResponse:
            "The official data service returned an invalid response."
        case .unsupportedSchema:
            "The official dataset structure changed and requires review."
        case .noPublishedValues:
            "The official dataset contains no publishable values."
        }
    }
}

private struct JSONStatDataset: Decodable {
    let updated: String?
    let id: [String]
    let size: [Int]
    let dimension: [String: JSONStatDimension]
    let value: [Double?]
}

private struct JSONStatDimension: Decodable {
    let category: JSONStatCategory

    var orderedCodes: [String]? {
        let ordered = category.index.sorted { lhs, rhs in lhs.value < rhs.value }
        guard ordered.map(\.value) == Array(0 ..< ordered.count) else { return nil }
        return ordered.map(\.key)
    }

    func position(for code: String) -> Int? {
        category.index[code]
    }
}

private struct JSONStatCategory: Decodable {
    let index: [String: Int]
}
