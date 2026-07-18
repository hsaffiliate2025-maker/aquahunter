import CoreLocation
import Foundation

struct MarketPrice: Identifiable, Hashable {
    let id: String
    let species: String
    let market: String
    let city: String
    let countryCode: String
    let priceUSDPerKg: Double
    let changePercent: Double
    let freshness: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func candles(for range: MarketChartRange) -> [PriceCandle] {
        let count = range.sampleCount
        let seed = id.unicodeScalars.enumerated().reduce(0) { partial, item in
            partial + Int(item.element.value) * (item.offset + 1)
        }
        let volatility = max(priceUSDPerKg * 0.018, 0.08)
        let start = priceUSDPerKg * (1 - changePercent / 100 * 0.72)

        var previousClose = start
        return (0 ..< count).map { index in
            let progress = Double(index + 1) / Double(count)
            let wave = sin(Double(index + seed % 17) * 0.91) * volatility
                + cos(Double(index + seed % 11) * 0.37) * volatility * 0.42
            let target = start + (priceUSDPerKg - start) * progress + wave
            let open = previousClose
            let close = max(target, 0.01)
            let wick = volatility * (0.45 + Double((seed + index * 7) % 9) / 10)
            let high = max(open, close) + wick
            let low = max(min(open, close) - wick * 0.78, 0.01)
            previousClose = close

            return PriceCandle(
                id: "\(id)-\(range.rawValue)-\(index)",
                label: range == .oneYear ? "W\(index + 1)" : "D\(index + 1)",
                open: open,
                high: high,
                low: low,
                close: close
            )
        }
    }
}

enum MarketChartRange: String, CaseIterable, Identifiable {
    case sevenDays = "7D"
    case thirtyDays = "30D"
    case oneYear = "1Y"

    var id: String { rawValue }

    var sampleCount: Int {
        switch self {
        case .sevenDays: 7
        case .thirtyDays: 30
        case .oneYear: 52
        }
    }

    var cadenceLabel: String {
        switch self {
        case .sevenDays: "7 daily candles"
        case .thirtyDays: "30 daily candles"
        case .oneYear: "52 weekly candles"
        }
    }
}

struct PriceCandle: Identifiable, Hashable {
    let id: String
    let label: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
}

struct RadarZone: Identifiable {
    let id: String
    let species: String
    let zone: String
    let probability: Int
    let confidence: String
    let modelVersion: String
    let dataCompleteness: Int
    let latitude: Double
    let longitude: Double
    let factors: [RadarFactor]
    let sources: [RadarDataSource]

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct RadarFactor: Identifiable, Hashable {
    let id: String
    let label: String
    let value: String
    let impact: Int
}

struct RadarDataSource: Identifiable, Hashable {
    let id: String
    let provider: String
    let signal: String
    let cadence: String
}

struct TradeNode: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let detail: String
    let status: String
}

#if AQUAHUNTER_INTERNAL_FIXTURES
enum DemoData {
    static let radarSources: [RadarDataSource] = [
        .init(id: "copernicus", provider: "Copernicus Marine", signal: "SST · ocean current", cadence: "Daily target"),
        .init(id: "nasa", provider: "NASA OceanColor", signal: "Chlorophyll-a", cadence: "Daily target"),
        .init(id: "gebco", provider: "GEBCO", signal: "Bathymetry · depth", cadence: "Static grid"),
        .init(id: "catch", provider: "NOAA / FAO / licensed feeds", signal: "Historical catch · seasonality", cadence: "Source dependent"),
    ]

    static let prices: [MarketPrice] = [
        .init(id: "toy-bluefin", species: "Bluefin Tuna", market: "Toyosu", city: "Tokyo", countryCode: "JP", priceUSDPerKg: 42.80, changePercent: 3.4, freshness: "18 min ago", latitude: 35.6762, longitude: 139.6503),
        .init(id: "busan-cod", species: "Pacific Cod", market: "Busan Cooperative", city: "Busan", countryCode: "KR", priceUSDPerKg: 8.40, changePercent: 1.7, freshness: "42 min ago", latitude: 35.1796, longitude: 129.0756),
        .init(id: "oslo-salmon", species: "Atlantic Salmon", market: "Oslo Seafood Index", city: "Oslo", countryCode: "NO", priceUSDPerKg: 9.72, changePercent: -1.2, freshness: "1 h ago", latitude: 59.9139, longitude: 10.7522),
        .init(id: "seattle-crab", species: "King Crab", market: "Seattle Wholesale", city: "Seattle", countryCode: "US", priceUSDPerKg: 31.60, changePercent: 2.1, freshness: "2 h ago", latitude: 47.6062, longitude: -122.3321),
        .init(id: "sydney-lobster", species: "Rock Lobster", market: "Sydney Fish Market", city: "Sydney", countryCode: "AU", priceUSDPerKg: 38.10, changePercent: -0.8, freshness: "3 h ago", latitude: -33.8688, longitude: 151.2093),
        .init(id: "shanghai-shrimp", species: "Whiteleg Shrimp", market: "Shanghai Jiangyang", city: "Shanghai", countryCode: "CN", priceUSDPerKg: 7.95, changePercent: 0.9, freshness: "3 h ago", latitude: 31.2304, longitude: 121.4737),
        .init(id: "taipei-cucumber", species: "Sea Cucumber", market: "Taipei First Market", city: "Taipei", countryCode: "TW", priceUSDPerKg: 26.40, changePercent: 4.6, freshness: "4 h ago", latitude: 25.0330, longitude: 121.5654),
    ]

    static let radarZones: [RadarZone] = [
        .init(
            id: "north-pacific-bluefin",
            species: "Bluefin Tuna",
            zone: "Northwest Pacific · Cell 8A2F",
            probability: 78,
            confidence: "Medium-high",
            modelVersion: "tuna-demo-v0.3",
            dataCompleteness: 86,
            latitude: 36.8,
            longitude: 148.0,
            factors: [
                .init(id: "sst", label: "Sea surface temperature", value: "19.8 °C", impact: 88),
                .init(id: "chlorophyll", label: "Chlorophyll", value: "0.42 mg/m³", impact: 76),
                .init(id: "current", label: "Ocean current", value: "1.4 kn", impact: 71),
                .init(id: "season", label: "Seasonality", value: "Strong", impact: 83),
            ],
            sources: radarSources
        ),
        .init(
            id: "norwegian-salmon",
            species: "Atlantic Salmon",
            zone: "Norwegian Sea · Cell 4B19",
            probability: 64,
            confidence: "Medium",
            modelVersion: "salmon-demo-v0.1",
            dataCompleteness: 79,
            latitude: 67.1,
            longitude: 8.3,
            factors: [
                .init(id: "salmon-sst", label: "Sea surface temperature", value: "10.8 °C", impact: 76),
                .init(id: "salmon-chlorophyll", label: "Chlorophyll", value: "1.12 mg/m³", impact: 66),
                .init(id: "salmon-current", label: "Ocean current", value: "0.5 kn", impact: 63),
                .init(id: "salmon-season", label: "Seasonality", value: "July", impact: 71),
            ],
            sources: radarSources
        ),
        .init(
            id: "bering-cod",
            species: "Pacific Cod",
            zone: "Bering Sea · Cell 6D12",
            probability: 69,
            confidence: "Medium",
            modelVersion: "cod-demo-v0.1",
            dataCompleteness: 75,
            latitude: 56.2,
            longitude: -171.5,
            factors: [
                .init(id: "cod-sst", label: "Bottom temperature proxy", value: "3.8 °C", impact: 79),
                .init(id: "cod-depth", label: "Depth band", value: "92–180 m", impact: 82),
                .init(id: "cod-current", label: "Shelf current", value: "0.4 kn", impact: 61),
                .init(id: "cod-history", label: "Historical catch", value: "Strong", impact: 74),
            ],
            sources: radarSources
        ),
        .init(
            id: "south-china-shrimp",
            species: "Whiteleg Shrimp",
            zone: "South China Sea · Cell 7C03",
            probability: 71,
            confidence: "Low",
            modelVersion: "shrimp-demo-v0.1",
            dataCompleteness: 62,
            latitude: 16.2,
            longitude: 112.1,
            factors: [
                .init(id: "shrimp-sst", label: "Sea surface temperature", value: "27.6 °C", impact: 82),
                .init(id: "shrimp-depth", label: "Depth", value: "34 m", impact: 70),
                .init(id: "shrimp-current", label: "Ocean current", value: "0.3 kn", impact: 57),
                .init(id: "shrimp-history", label: "Historical catch", value: "Sparse", impact: 42),
            ],
            sources: radarSources
        ),
    ]

    static let buyers: [TradeNode] = [
        .init(id: "buyer-1", title: "Pacific Crown Seafood", subtitle: "Seattle, United States", detail: "King Crab · Cod · Salmon", status: "Verified demo"),
        .init(id: "buyer-2", title: "Hoshino Marine Trading", subtitle: "Tokyo, Japan", detail: "Bluefin Tuna · Uni", status: "Contact gated"),
        .init(id: "buyer-3", title: "Nordic Fresh Imports", subtitle: "Rotterdam, Netherlands", detail: "Salmon · Cod", status: "Import activity"),
    ]

    static let tradeFlows: [TradeNode] = [
        .init(id: "flow-1", title: "Norway → China", subtitle: "Atlantic Salmon", detail: "18.4K t · +8.2% YoY", status: "June 2026 demo"),
        .init(id: "flow-2", title: "Chile → United States", subtitle: "Salmon", detail: "12.8K t · +3.7% YoY", status: "June 2026 demo"),
        .init(id: "flow-3", title: "Canada → Japan", subtitle: "Snow Crab", detail: "4.1K t · −1.9% YoY", status: "June 2026 demo"),
    ]

    static let ports: [TradeNode] = [
        .init(id: "port-1", title: "Busan Cooperative Port", subtitle: "Today’s landing", detail: "1,280 t · 14 species", status: "Delayed demo"),
        .init(id: "port-2", title: "Seattle Fishermen’s Terminal", subtitle: "Today’s landing", detail: "640 t · 9 species", status: "Delayed demo"),
        .init(id: "port-3", title: "Qingdao Port", subtitle: "Today’s landing", detail: "2,110 t · 21 species", status: "Delayed demo"),
    ]

    static let vessels: [TradeNode] = [
        .init(id: "vessel-1", title: "Ocean Star 17", subtitle: "North Pacific", detail: "12.4 kn · heading 084°", status: "Last known 38 min"),
        .init(id: "vessel-2", title: "Nordlys", subtitle: "Norwegian Sea", detail: "8.9 kn · heading 216°", status: "Last known 1 h"),
        .init(id: "vessel-3", title: "Haixing 806", subtitle: "Yellow Sea", detail: "10.1 kn · heading 031°", status: "Last known 2 h"),
    ]

}
#endif
