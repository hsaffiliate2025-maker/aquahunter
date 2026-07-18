import SwiftUI

private let dashboardColumns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

struct PulseView: View {
    @StateObject private var marketsStore = ProductionMarketsStore()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                SectionTitle(
                    "Global seafood pulse",
                    eyebrow: "Ocean intelligence",
                    subtitle: "Prices, probability, ports and trade signals in one operational view."
                )

                switch marketsStore.state {
                case .idle, .loading:
                    AquaCard {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Loading authorized intelligence…")
                                .font(.subheadline)
                                .foregroundStyle(AquaTheme.textSecondary)
                        }
                    }

                case let .unavailable(message):
                    AquaCard {
                        Text("Authorized intelligence unavailable")
                            .font(.headline)
                            .foregroundStyle(AquaTheme.textPrimary)
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(AquaTheme.textSecondary)
                        Button("Retry") {
                            Task { await marketsStore.reload() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AquaTheme.signalBlue)
                    }

                case let .loaded(series):
                    let first = series.first
                    LazyVGrid(columns: dashboardColumns, spacing: 12) {
                        MetricTile(
                            label: "Markets",
                            value: "\(series.count)",
                            detail: "Authorized benchmark",
                            accent: AquaTheme.signalBlue
                        )
                        MetricTile(
                            label: "Radar",
                            value: "—",
                            detail: "Awaiting approved inputs",
                            accent: AquaTheme.textSecondary
                        )
                        MetricTile(
                            label: "Price move",
                            value: first?.changePercent.map { String(format: "%+.1f%%", $0) } ?? "—",
                            detail: "Weekly official series",
                            accent: (first?.changePercent ?? 0) >= 0 ? AquaTheme.positive : AquaTheme.negative
                        )
                        MetricTile(
                            label: "Latest",
                            value: first?.latest?.periodCode ?? "—",
                            detail: "Provider period",
                            accent: AquaTheme.radarCyan
                        )
                    }

                    if let first, let latest = first.latest {
                        AquaCard(emphasized: true) {
                            Text("AUTHORIZED MARKET PULSE")
                                .font(.caption2.weight(.bold))
                                .tracking(1.2)
                                .foregroundStyle(AquaTheme.signalBlue)
                            Text(first.benchmark)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(AquaTheme.textPrimary)
                            Text(
                                String(
                                    format: "%.2f %@ / %@ · %@",
                                    latest.pricePerKg,
                                    first.currencyCode,
                                    first.unit,
                                    latest.periodCode
                                )
                            )
                            .font(.headline)
                            .foregroundStyle(AquaTheme.positive)
                            Text(first.attribution)
                                .font(.caption)
                                .foregroundStyle(AquaTheme.textSecondary)
                            Text("National weekly export statistic; not an executable quote.")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                    }
                }

                LicensedWorldMap(
                    markers: [
                        LicensedMapMarker(
                            id: "norway-market-benchmark",
                            title: "Norway",
                            subtitle: "Licensed national salmon export benchmark",
                            latitude: 61.0,
                            longitude: 8.0,
                            kind: .market
                        ),
                    ],
                    centerLatitude: 54,
                    centerLongitude: 8,
                    zoomLevel: 2.0
                )

                Text("The map stays available offline. The green marker shows geographic coverage of the licensed Norway national benchmark; it is not an Oslo spot price.")
                    .font(.caption)
                    .foregroundStyle(AquaTheme.textSecondary)

                AquaCard {
                    Label("Source-controlled intelligence", systemImage: "checkmark.shield")
                        .font(.headline)
                        .foregroundStyle(AquaTheme.textPrimary)
                    Text("AquaHunter shows no value when an approved source is missing or unavailable. Radar, vessel and buyer overlays remain disabled until their exact datasets pass the commercial-reuse allowlist; the licensed offline base map remains visible.")
                        .font(.subheadline)
                        .foregroundStyle(AquaTheme.textSecondary)
                }
            }
            .padding(18)
        }
        .navigationTitle("AquaHunter")
        .aquaPageBackground()
        .task {
            await marketsStore.loadIfNeeded()
        }
    }
}

struct MarketsView: View {
    @StateObject private var store = ProductionMarketsStore()
    @State private var query = ""

    private func results(from series: [ProductionMarketSeries]) -> [ProductionMarketSeries] {
        guard !query.isEmpty else { return series }
        return series.filter {
            $0.species.localizedCaseInsensitiveContains(query)
                || $0.geography.localizedCaseInsensitiveContains(query)
                || $0.benchmark.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                SectionTitle(
                    "Global markets",
                    eyebrow: "Licensed official data",
                    subtitle: "Only authorized observations are shown. Cadence, unit and source semantics are preserved."
                )

                TextField("Search species, country or benchmark", text: $query)
                    .textFieldStyle(.plain)
                    .padding(13)
                    .background(AquaTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay { RoundedRectangle(cornerRadius: 13).stroke(AquaTheme.divider, lineWidth: 1) }

                switch store.state {
                case .idle, .loading:
                    AquaCard {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Loading authorized market data…")
                                .font(.subheadline)
                                .foregroundStyle(AquaTheme.textSecondary)
                        }
                    }

                case let .unavailable(message):
                    AquaCard {
                        Label("Market data unavailable", systemImage: "externaldrive.badge.xmark")
                            .font(.headline)
                            .foregroundStyle(AquaTheme.textPrimary)
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(AquaTheme.textSecondary)
                        Button("Retry") {
                            Task { await store.reload() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AquaTheme.signalBlue)
                        .padding(.top, 4)
                    }

                case let .loaded(series):
                    let filtered = results(from: series)
                    HStack {
                        Text("\(filtered.count) authorized benchmark")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AquaTheme.textPrimary)
                        Spacer()
                        Text("SOURCE UNITS")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AquaTheme.positive)
                    }
                    .padding(12)
                    .background(AquaTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                    if filtered.isEmpty {
                        AquaCard {
                            Text("No authorized matching data")
                                .font(.headline)
                                .foregroundStyle(AquaTheme.textPrimary)
                            Text("AquaHunter does not insert a fictional fallback for unavailable species or cities.")
                                .font(.subheadline)
                                .foregroundStyle(AquaTheme.textSecondary)
                        }
                    } else {
                        ForEach(filtered) { marketSeries in
                            NavigationLink {
                                ProductionMarketDetailView(series: marketSeries)
                            } label: {
                                ProductionMarketCard(series: marketSeries)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                AquaCard {
                    Text("DATA INTERPRETATION")
                        .font(.caption2.weight(.bold))
                        .tracking(1.1)
                        .foregroundStyle(.yellow)
                    Text("Statistics Norway table 03024 is a weekly national export statistic. It is not an Oslo spot price, auction result or executable quote. OHLC candles are not shown because this source does not publish open, high, low and close values.")
                        .font(.caption)
                        .foregroundStyle(AquaTheme.textSecondary)
                }
            }
            .padding(18)
        }
        .navigationTitle("Markets")
        .aquaPageBackground()
        .task {
            await store.loadIfNeeded()
        }
    }
}

private struct ProductionMarketCard: View {
    let series: ProductionMarketSeries

    private var positive: Bool { (series.changePercent ?? 0) >= 0 }
    private var preview: [Double] {
        series.points.suffix(12).map(\.pricePerKg)
    }

    var body: some View {
        AquaCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(series.geography) · \(series.countryCode)")
                        .font(.headline)
                        .foregroundStyle(AquaTheme.textPrimary)
                    Text("\(series.benchmark) · \(series.species)")
                        .font(.caption)
                        .foregroundStyle(AquaTheme.textSecondary)
                }
                Spacer()
                if let change = series.changePercent {
                    Text(String(format: "%+.1f%%", change))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(positive ? AquaTheme.positive : AquaTheme.negative)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background((positive ? AquaTheme.positive : AquaTheme.negative).opacity(0.10))
                        .clipShape(Capsule())
                }
            }

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    if let latest = series.latest {
                        Text(String(format: "%.2f", latest.pricePerKg))
                            .font(.system(.title, design: .rounded, weight: .semibold))
                            .foregroundStyle(AquaTheme.textPrimary)
                        Text("\(series.currencyCode) / \(series.unit) · \(latest.periodCode)")
                            .font(.caption2)
                            .foregroundStyle(AquaTheme.textSecondary)
                    }
                }
                Spacer()
                Sparkline(values: preview, color: positive ? AquaTheme.positive : AquaTheme.negative)
                    .frame(width: 130, height: 44)
                    .accessibilityLabel("Official weekly price trend")
            }
            .padding(.top, 12)

            HStack {
                Text("View official weekly history")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AquaTheme.signalBlue)
                Spacer()
                Text("CC BY 4.0")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AquaTheme.positive)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AquaTheme.textSecondary)
            }
            .padding(.top, 10)
        }
    }
}

private enum OfficialHistoryRange: String, CaseIterable, Identifiable {
    case sixWeeks = "6W"
    case thirtyWeeks = "30W"
    case oneYear = "1Y"

    var id: String { rawValue }

    var pointCount: Int {
        switch self {
        case .sixWeeks: 6
        case .thirtyWeeks: 30
        case .oneYear: 52
        }
    }
}

private struct ProductionMarketDetailView: View {
    let series: ProductionMarketSeries
    @State private var range: OfficialHistoryRange = .thirtyWeeks

    private var visiblePoints: [MarketDataPoint] {
        Array(series.points.suffix(range.pointCount))
    }

    private var providerUpdatedText: String {
        guard let date = series.providerUpdatedAt else { return "Not supplied" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                SectionTitle(
                    series.geography,
                    eyebrow: series.species.uppercased(),
                    subtitle: "\(series.benchmark) · \(series.latency)"
                )

                AquaCard(emphasized: true) {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 3) {
                            if let latest = series.latest {
                                Text(String(format: "%.2f", latest.pricePerKg))
                                    .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                                    .foregroundStyle(AquaTheme.textPrimary)
                                Text("\(series.currencyCode) / \(series.unit) · \(latest.periodCode)")
                                    .font(.caption)
                                    .foregroundStyle(AquaTheme.textSecondary)
                            }
                        }
                        Spacer()
                        if let change = series.changePercent {
                            Text(String(format: "%+.1f%% WoW", change))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(change >= 0 ? AquaTheme.positive : AquaTheme.negative)
                        }
                    }
                }

                Picker("History range", selection: $range) {
                    ForEach(OfficialHistoryRange.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                AquaCard {
                    HStack {
                        Text("OFFICIAL WEEKLY SERIES")
                            .font(.caption2.weight(.bold))
                            .tracking(1.1)
                            .foregroundStyle(AquaTheme.signalBlue)
                        Spacer()
                        Text("NO SYNTHETIC OHLC")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.yellow)
                    }

                    Sparkline(
                        values: visiblePoints.map(\.pricePerKg),
                        color: (series.changePercent ?? 0) >= 0 ? AquaTheme.positive : AquaTheme.negative
                    )
                    .frame(minHeight: 230)
                    .padding(.top, 10)
                    .accessibilityLabel("\(visiblePoints.count) official weekly price observations")

                    HStack {
                        Text("\(visiblePoints.count) published weekly points")
                        Spacer()
                        Text("\(series.currencyCode) / \(series.unit)")
                    }
                    .font(.caption2)
                    .foregroundStyle(AquaTheme.textSecondary)
                    .padding(.top, 6)
                }

                if let latest = series.latest {
                    AquaCard {
                        Text("LATEST PUBLISHED OBSERVATION")
                            .font(.caption2.weight(.bold))
                            .tracking(1.1)
                            .foregroundStyle(AquaTheme.signalBlue)
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("PERIOD")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(AquaTheme.textSecondary)
                                Text(latest.periodCode)
                                    .font(.headline)
                                    .foregroundStyle(AquaTheme.textPrimary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 3) {
                                Text("EXPORT WEIGHT")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(AquaTheme.textSecondary)
                                Text(latest.volumeTonnes.map { String(format: "%.0f t", $0) } ?? "Not supplied")
                                    .font(.headline)
                                    .foregroundStyle(AquaTheme.textPrimary)
                            }
                        }
                    }
                }

                AquaCard {
                    Text("SOURCE & LICENSE")
                        .font(.caption2.weight(.bold))
                        .tracking(1.1)
                        .foregroundStyle(AquaTheme.signalBlue)
                    Text(series.attribution)
                        .font(.headline)
                        .foregroundStyle(AquaTheme.textPrimary)
                    Text("Provider updated: \(providerUpdatedText)")
                        .font(.caption)
                        .foregroundStyle(AquaTheme.textSecondary)
                    Text("Retrieved: \(series.retrievedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(AquaTheme.textSecondary)
                    Text("\(series.commodityForm) · \(series.scientificName)")
                        .font(.caption)
                        .foregroundStyle(AquaTheme.textSecondary)
                    HStack(spacing: 16) {
                        Link("Open source table", destination: series.sourceURL)
                        Link(series.licenseName, destination: series.licenseURL)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AquaTheme.signalBlue)
                    .padding(.top, 5)
                    Text("National export unit value; not a city spot price, auction quote or executable offer.")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                        .padding(.top, 6)
                }
            }
            .padding(18)
        }
        .navigationTitle(series.geography)
        .aquaPageBackground()
    }
}

#if AQUAHUNTER_INTERNAL_FIXTURES
private struct PriceCard: View {
    let price: MarketPrice

    private var positive: Bool { price.changePercent >= 0 }
    private var preview: [Double] { price.candles(for: .sevenDays).map(\.close) }

    var body: some View {
        AquaCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(price.city) · \(price.countryCode)")
                        .font(.headline)
                        .foregroundStyle(AquaTheme.textPrimary)
                    Text("\(price.market) · \(price.species)")
                        .font(.caption)
                        .foregroundStyle(AquaTheme.textSecondary)
                }
                Spacer()
                Text(String(format: "%+.1f%%", price.changePercent))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(positive ? AquaTheme.positive : AquaTheme.negative)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background((positive ? AquaTheme.positive : AquaTheme.negative).opacity(0.10))
                    .clipShape(Capsule())
            }

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "$%.2f", price.priceUSDPerKg))
                        .font(.system(.title, design: .rounded, weight: .semibold))
                        .foregroundStyle(AquaTheme.textPrimary)
                    Text("USD / kg · \(price.freshness)")
                        .font(.caption2)
                        .foregroundStyle(AquaTheme.textSecondary)
                }
                Spacer()
                Sparkline(values: preview, color: positive ? AquaTheme.positive : AquaTheme.negative)
                    .frame(width: 130, height: 44)
                    .accessibilityLabel("Seven day price trend")
            }
            .padding(.top, 12)

            HStack {
                Text("View 7D · 30D · 1Y K-line")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AquaTheme.signalBlue)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AquaTheme.textSecondary)
            }
            .padding(.top, 10)
        }
    }
}

private struct MarketDetailView: View {
    let price: MarketPrice
    @State private var range: MarketChartRange = .thirtyDays

    private var candles: [PriceCandle] { price.candles(for: range) }
    private var latest: PriceCandle? { candles.last }
    private var periodLow: Double { candles.map(\.low).min() ?? price.priceUSDPerKg }
    private var periodHigh: Double { candles.map(\.high).max() ?? price.priceUSDPerKg }
    private var positive: Bool { price.changePercent >= 0 }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                SectionTitle(
                    "\(price.city) market",
                    eyebrow: price.species.uppercased(),
                    subtitle: "\(price.market) · \(price.countryCode) · \(price.freshness)"
                )

                AquaCard(emphasized: true) {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(String(format: "$%.2f", price.priceUSDPerKg))
                                .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                                .foregroundStyle(AquaTheme.textPrimary)
                            Text("Normalized USD / kg")
                                .font(.caption)
                                .foregroundStyle(AquaTheme.textSecondary)
                        }
                        Spacer()
                        Text(String(format: "%+.1f%%", price.changePercent))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(positive ? AquaTheme.positive : AquaTheme.negative)
                    }
                }

                Picker("K-line range", selection: $range) {
                    ForEach(MarketChartRange.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                AquaCard {
                    HStack {
                        Text("PRICE K-LINE")
                            .font(.caption2.weight(.bold))
                            .tracking(1.1)
                            .foregroundStyle(AquaTheme.signalBlue)
                        Spacer()
                        Text("DEMO OHLC")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.yellow)
                    }

                    CandlestickChart(candles: candles)
                        .frame(minHeight: 230)
                        .padding(.top, 10)

                    HStack {
                        Text(range.cadenceLabel)
                        Spacer()
                        Text("Green up · Red down")
                    }
                    .font(.caption2)
                    .foregroundStyle(AquaTheme.textSecondary)
                    .padding(.top, 6)
                }

                if let latest {
                    AquaCard {
                        Text("LATEST CANDLE")
                            .font(.caption2.weight(.bold))
                            .tracking(1.1)
                            .foregroundStyle(AquaTheme.signalBlue)
                        HStack(spacing: 8) {
                            CandleMetric(label: "OPEN", value: latest.open)
                            CandleMetric(label: "HIGH", value: latest.high)
                            CandleMetric(label: "LOW", value: latest.low)
                            CandleMetric(label: "CLOSE", value: latest.close)
                        }
                        .padding(.top, 10)
                    }
                }

                AquaCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("PERIOD LOW")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(AquaTheme.textSecondary)
                            Text(String(format: "$%.2f", periodLow))
                                .font(.headline)
                                .foregroundStyle(AquaTheme.textPrimary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text("PERIOD HIGH")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(AquaTheme.textSecondary)
                            Text(String(format: "$%.2f", periodHigh))
                                .font(.headline)
                                .foregroundStyle(AquaTheme.textPrimary)
                        }
                    }
                    Text("This build uses deterministic offline demonstration candles. Production K-lines will preserve market, grade, form, currency, unit, timestamp and source provenance.")
                        .font(.caption)
                        .foregroundStyle(AquaTheme.textSecondary)
                        .padding(.top, 10)
                }
            }
            .padding(18)
        }
        .navigationTitle(price.city)
        .aquaPageBackground()
    }
}

private struct CandleMetric: View {
    let label: String
    let value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(AquaTheme.textSecondary)
            Text(String(format: "$%.2f", value))
                .font(.caption.weight(.semibold))
                .foregroundStyle(AquaTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CandlestickChart: View {
    let candles: [PriceCandle]

    var body: some View {
        Canvas { context, size in
            guard !candles.isEmpty else { return }
            let minValue = candles.map(\.low).min() ?? 0
            let maxValue = candles.map(\.high).max() ?? 1
            let spread = max(maxValue - minValue, 0.001)
            let topInset: CGFloat = 10
            let bottomInset: CGFloat = 10
            let plotHeight = max(size.height - topInset - bottomInset, 1)

            func y(_ value: Double) -> CGFloat {
                topInset + (1 - CGFloat((value - minValue) / spread)) * plotHeight
            }

            for index in 0 ... 3 {
                let gridY = topInset + plotHeight * CGFloat(index) / 3
                var grid = Path()
                grid.move(to: CGPoint(x: 0, y: gridY))
                grid.addLine(to: CGPoint(x: size.width, y: gridY))
                context.stroke(grid, with: .color(AquaTheme.divider.opacity(0.55)), lineWidth: 1)
            }

            let slot = size.width / CGFloat(candles.count)
            let bodyWidth = max(1.4, min(8, slot * 0.56))
            for (index, candle) in candles.enumerated() {
                let x = slot * (CGFloat(index) + 0.5)
                let color = candle.close >= candle.open ? AquaTheme.positive : AquaTheme.negative
                var wick = Path()
                wick.move(to: CGPoint(x: x, y: y(candle.high)))
                wick.addLine(to: CGPoint(x: x, y: y(candle.low)))
                context.stroke(wick, with: .color(color), lineWidth: max(1, bodyWidth * 0.22))

                let openY = y(candle.open)
                let closeY = y(candle.close)
                let bodyTop = min(openY, closeY)
                let bodyHeight = max(abs(closeY - openY), 2)
                let rect = CGRect(x: x - bodyWidth / 2, y: bodyTop, width: bodyWidth, height: bodyHeight)
                context.fill(Path(roundedRect: rect, cornerRadius: 0.8), with: .color(color))
            }
        }
        .padding(10)
        .background(AquaTheme.deepOcean.opacity(0.66))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .accessibilityLabel("\(candles.count) candle OHLC price chart")
    }
}
#endif

private struct Sparkline: View {
    let values: [Double]
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let minValue = values.min() ?? 0
            let maxValue = values.max() ?? 1
            let spread = max(maxValue - minValue, 0.001)
            Path { path in
                for (index, value) in values.enumerated() {
                    let x = proxy.size.width * CGFloat(index) / CGFloat(max(values.count - 1, 1))
                    let normalized = (value - minValue) / spread
                    let y = proxy.size.height * (1 - CGFloat(normalized) * 0.76 - 0.12)
                    if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
        }
    }
}

#if AQUAHUNTER_INTERNAL_FIXTURES
struct RadarView: View {
    @State private var forecastHour = 24.0
    @State private var selectedLayer = "Probability"
    @State private var selectedZoneID = DemoData.radarZones[0].id
    @State private var mapPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41, longitude: 155),
            span: MKCoordinateSpan(latitudeDelta: 46, longitudeDelta: 95)
        )
    )

    private var selectedZone: RadarZone {
        DemoData.radarZones.first { $0.id == selectedZoneID } ?? DemoData.radarZones[0]
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                SectionTitle("AI Fish Radar", eyebrow: "Fish probability", subtitle: "Environmental and historical signals, not sonar detection.")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(DemoData.radarZones) { zone in
                            Button {
                                selectedZoneID = zone.id
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(selectedZoneID == zone.id ? AquaTheme.positive : AquaTheme.textSecondary)
                                        .frame(width: 6, height: 6)
                                    Text(zone.species)
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(selectedZoneID == zone.id ? AquaTheme.deepOcean : AquaTheme.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(selectedZoneID == zone.id ? AquaTheme.signalBlue : AquaTheme.surface)
                                .clipShape(Capsule())
                                .overlay { Capsule().stroke(selectedZoneID == zone.id ? AquaTheme.signalBlue : AquaTheme.divider, lineWidth: 1) }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Picker("Layer", selection: $selectedLayer) {
                    ForEach(["Probability", "SST", "Chlorophyll", "Current"], id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)

                AquaCard(emphasized: true) {
                    Map(position: $mapPosition) {
                        ForEach(DemoData.radarZones) { zone in
                            Annotation(zone.species, coordinate: zone.coordinate) {
                                ZStack {
                                    Circle()
                                        .fill(probabilityColor(zone.probability).opacity(zone.id == selectedZoneID ? 0.25 : 0.10))
                                        .frame(
                                            width: zone.id == selectedZoneID ? CGFloat(zone.probability) : 42,
                                            height: zone.id == selectedZoneID ? CGFloat(zone.probability) : 42
                                        )
                                    Circle()
                                        .stroke(probabilityColor(zone.probability), lineWidth: 2)
                                        .frame(width: zone.id == selectedZoneID ? 46 : 34, height: zone.id == selectedZoneID ? 46 : 34)
                                    Text("\(zone.probability)%")
                                        .font(.caption2.weight(.black))
                                        .foregroundStyle(.white)
                                }
                                .opacity(zone.id == selectedZoneID ? 1 : 0.66)
                                .onTapGesture { selectedZoneID = zone.id }
                                .accessibilityLabel("\(zone.species), \(zone.probability) percent probability")
                            }
                        }
                    }
                    .frame(minHeight: 330)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    HStack {
                        HStack(spacing: 5) {
                            Circle().fill(AquaTheme.positive).frame(width: 6, height: 6)
                            Text("DEMO MODEL")
                        }
                        .foregroundStyle(AquaTheme.positive)
                        Spacer()
                        Text("\(selectedZone.species.uppercased()) · \(Int(forecastHour))H")
                            .foregroundStyle(AquaTheme.signalBlue)
                    }
                    .font(.caption2.weight(.bold))
                    .padding(.top, 10)
                }

                AquaCard {
                    Text("Forecast horizon")
                        .font(.headline)
                        .foregroundStyle(AquaTheme.textPrimary)
                    Slider(value: $forecastHour, in: 6 ... 72, step: 6)
                        .tint(AquaTheme.signalBlue)
                    HStack {
                        Text("6 hours")
                        Spacer()
                        Text("72 hours")
                    }
                    .font(.caption2)
                    .foregroundStyle(AquaTheme.textSecondary)
                }

                AquaCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(selectedZone.species)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(AquaTheme.textPrimary)
                            Text("\(selectedZone.zone) · \(selectedZone.confidence) confidence")
                                .font(.caption)
                                .foregroundStyle(AquaTheme.textSecondary)
                        }
                        Spacer()
                        Text("\(selectedZone.probability)%")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(probabilityColor(selectedZone.probability))
                    }

                    ForEach(selectedZone.factors) { factor in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(factor.label)
                                Spacer()
                                Text(factor.value)
                            }
                            .font(.caption)
                            .foregroundStyle(AquaTheme.textSecondary)
                            ProgressView(value: Double(factor.impact), total: 100)
                                .tint(factor.impact >= 78 ? AquaTheme.positive : AquaTheme.signalBlue)
                        }
                        .padding(.top, 9)
                    }

                    HStack {
                        Text(selectedZone.modelVersion)
                        Spacer()
                        Text("Data completeness \(selectedZone.dataCompleteness)%")
                    }
                    .font(.caption2)
                    .foregroundStyle(AquaTheme.textSecondary.opacity(0.82))
                    .padding(.top, 8)
                }

                AquaCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("AGGREGATED SOURCE PLAN")
                                .font(.caption2.weight(.bold))
                                .tracking(1.1)
                                .foregroundStyle(AquaTheme.signalBlue)
                            Text("Data lineage")
                                .font(.headline)
                                .foregroundStyle(AquaTheme.textPrimary)
                        }
                        Spacer()
                        Text("OFFLINE DEMO")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.yellow)
                    }

                    ForEach(selectedZone.sources) { source in
                        HStack(alignment: .top, spacing: 10) {
                            Circle().fill(AquaTheme.radarCyan).frame(width: 6, height: 6).padding(.top, 5)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(source.provider)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AquaTheme.textPrimary)
                                Text("\(source.signal) · \(source.cadence)")
                                    .font(.caption2)
                                    .foregroundStyle(AquaTheme.textSecondary)
                            }
                        }
                        .padding(.top, 7)
                    }

                    Text("This build uses offline fixtures. Production ingestion will normalize time, coordinates, units, quality flags and licenses before model scoring.")
                        .font(.caption2)
                        .foregroundStyle(AquaTheme.textSecondary.opacity(0.82))
                        .padding(.top, 8)
                }

                Text("AquaHunter does not detect fish and does not guarantee catch. Check protected areas, weather, regulations and vessel safety before operating.")
                    .font(.caption)
                    .foregroundStyle(AquaTheme.textSecondary)
                    .padding(.horizontal, 4)
            }
            .padding(18)
        }
        .navigationTitle("Radar")
        .aquaPageBackground()
        .onChange(of: selectedZoneID) { _, _ in
            withAnimation(.easeInOut(duration: 0.35)) {
                mapPosition = .region(
                    MKCoordinateRegion(
                        center: selectedZone.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 52)
                    )
                )
            }
        }
    }

    private func probabilityColor(_ probability: Int) -> Color {
        probability >= 75 ? AquaTheme.positive : probability >= 65 ? AquaTheme.radarCyan : AquaTheme.signalBlue
    }
}
#else
struct RadarView: View {
    private let species = [
        "Bluefin Tuna",
        "Atlantic Salmon",
        "Pacific Cod",
        "Whiteleg Shrimp",
    ]
    @State private var selectedSpecies = "Bluefin Tuna"

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                SectionTitle(
                    "AI Fish Radar",
                    eyebrow: "Fish probability",
                    subtitle: "Environmental suitability estimates—not sonar detection or a catch guarantee."
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(species, id: \.self) { item in
                            Button {
                                selectedSpecies = item
                            } label: {
                                Text(item)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(
                                        selectedSpecies == item
                                            ? AquaTheme.deepOcean
                                            : AquaTheme.textSecondary
                                    )
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 9)
                                    .background(
                                        selectedSpecies == item
                                            ? AquaTheme.signalBlue
                                            : AquaTheme.surface
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                LicensedWorldMap(
                    markers: [],
                    centerLatitude: 30,
                    centerLongitude: 155,
                    zoomLevel: 1.1
                )

                Text("Offline base map available. No probability heat layer is drawn until the selected species has a complete approved input bundle.")
                    .font(.caption)
                    .foregroundStyle(AquaTheme.textSecondary)

                AquaCard(emphasized: true) {
                    Image(systemName: "scope")
                        .font(.system(size: 42, weight: .light))
                        .foregroundStyle(AquaTheme.signalBlue)
                    Text("Probability unavailable")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AquaTheme.textPrimary)
                    Text("No complete, commercially reusable and product-level approved environmental bundle is enabled for \(selectedSpecies).")
                        .font(.subheadline)
                        .foregroundStyle(AquaTheme.textSecondary)
                    Text("AquaHunter will not create a probability, heat map or fishing recommendation from missing or unlicensed inputs.")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }

                AquaCard {
                    Text("REQUIRED APPROVED INPUTS")
                        .font(.caption2.weight(.bold))
                        .tracking(1.1)
                        .foregroundStyle(AquaTheme.signalBlue)
                    ForEach(
                        [
                            "Sea-surface temperature and observation time",
                            "Chlorophyll concentration and quality flags",
                            "Ocean current, depth and model validity",
                            "Species-specific seasonality and lawful catch history",
                            "Protected areas, closures and jurisdiction boundaries",
                        ],
                        id: \.self
                    ) { item in
                        Label(item, systemImage: "circle")
                            .font(.caption)
                            .foregroundStyle(AquaTheme.textSecondary)
                            .padding(.top, 5)
                    }
                }

                Text("AquaHunter does not detect fish and must never be the sole basis for navigation, departure, route, fishing, safety or emergency decisions.")
                    .font(.caption)
                    .foregroundStyle(AquaTheme.textSecondary)
                    .padding(.horizontal, 4)
            }
            .padding(18)
        }
        .navigationTitle("Radar")
        .aquaPageBackground()
    }
}
#endif

#if AQUAHUNTER_INTERNAL_FIXTURES
struct NetworkView: View {
    private enum Segment: String, CaseIterable, Identifiable {
        case buyers = "Buyers"
        case trade = "Trade"
        case ports = "Ports"
        case vessels = "Vessels"
        var id: String { rawValue }
    }

    @State private var segment: Segment = .buyers
    @State private var showsHelp = false

    private var rows: [TradeNode] {
        switch segment {
        case .buyers: DemoData.buyers
        case .trade: DemoData.tradeFlows
        case .ports: DemoData.ports
        case .vessels: DemoData.vessels
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                SectionTitle("Global network", eyebrow: "Trade intelligence", subtitle: "Buyers, trade lanes, ports and delayed vessel signals.")

                Picker("Network", selection: $segment) {
                    ForEach(Segment.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                HStack(spacing: 12) {
                    MetricTile(label: "Records", value: "\(rows.count)", detail: "Visible demo rows", accent: AquaTheme.signalBlue)
                    MetricTile(label: "Status", value: "Demo", detail: "No licensed contacts", accent: AquaTheme.positive)
                }

                ForEach(rows) { row in
                    AquaCard {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: symbol(for: segment))
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(AquaTheme.signalBlue)
                                .frame(width: 38, height: 38)
                                .background(AquaTheme.signalBlue.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.title)
                                    .font(.headline)
                                    .foregroundStyle(AquaTheme.textPrimary)
                                Text(row.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(AquaTheme.textSecondary)
                                Text(row.detail)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(AquaTheme.signalBlue)
                                Text(row.status)
                                    .font(.caption2)
                                    .foregroundStyle(AquaTheme.textSecondary.opacity(0.8))
                                    .padding(.top, 3)
                                if segment == .vessels {
                                    Text("Commercial availability · Tracking only")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.yellow)
                                        .padding(.top, 3)
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
            .padding(18)
        }
        .navigationTitle("Network")
        .aquaPageBackground()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showsHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                }
                .help("Explain Network features")
                .accessibilityLabel("Network help")
            }
        }
        .sheet(isPresented: $showsHelp) {
            NetworkHelpView()
        }
    }

    private func symbol(for segment: Segment) -> String {
        switch segment {
        case .buyers: "building.2"
        case .trade: "arrow.triangle.swap"
        case .ports: "ferry"
        case .vessels: "location.north.circle"
        }
    }
}
#else
struct NetworkView: View {
    private enum Segment: String, CaseIterable, Identifiable {
        case buyers = "Buyers"
        case trade = "Trade"
        case ports = "Ports"
        case vessels = "Vessels"
        var id: String { rawValue }
    }

    @State private var segment: Segment = .buyers
    @State private var showsHelp = false

    private var unavailableMessage: String {
        switch segment {
        case .buyers:
            "No buyer directory with approved commercial contact-display and redistribution rights is connected."
        case .trade:
            "No approved customs trade-flow dataset is connected."
        case .ports:
            "No approved port landing feed is connected."
        case .vessels:
            "No contracted AIS provider is connected. No vessel position or availability is inferred."
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                SectionTitle(
                    "Global network",
                    eyebrow: "Trade intelligence",
                    subtitle: "Buyers, trade lanes, ports and vessels appear only when their exact source permits the product use."
                )

                Picker("Network", selection: $segment) {
                    ForEach(Segment.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                LicensedWorldMap(
                    markers: segment == .ports ? Self.portReferenceMarkers : [],
                    centerLatitude: 28,
                    centerLongitude: 20,
                    zoomLevel: 0.7
                )

                Text(
                    segment == .ports
                        ? "Port markers are reference locations only. No landing, price or ship activity is implied."
                        : "The offline base map remains available. No business, trade or vessel overlay is fabricated when licensed records are missing."
                )
                .font(.caption)
                .foregroundStyle(AquaTheme.textSecondary)

                AquaCard(emphasized: true) {
                    Image(systemName: symbol(for: segment))
                        .font(.system(size: 38, weight: .light))
                        .foregroundStyle(AquaTheme.signalBlue)
                    Text("\(segment.rawValue) data unavailable")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AquaTheme.textPrimary)
                    Text(unavailableMessage)
                        .font(.subheadline)
                        .foregroundStyle(AquaTheme.textSecondary)
                    Text("AquaHunter does not insert fabricated companies, shipments, landings or vessel positions.")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }

                AquaCard {
                    Text("SOURCE REQUIREMENT")
                        .font(.caption2.weight(.bold))
                        .tracking(1.1)
                        .foregroundStyle(AquaTheme.signalBlue)
                    Text("A source must pass commercial-use, derivative-use, caching, contact-display and redistribution review before records are enabled.")
                        .font(.caption)
                        .foregroundStyle(AquaTheme.textSecondary)
                }
            }
            .padding(18)
        }
        .navigationTitle("Network")
        .aquaPageBackground()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showsHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                }
                .help("Explain Network features")
                .accessibilityLabel("Network help")
            }
        }
        .sheet(isPresented: $showsHelp) {
            NetworkHelpView()
        }
    }

    private func symbol(for segment: Segment) -> String {
        switch segment {
        case .buyers: "building.2"
        case .trade: "arrow.triangle.swap"
        case .ports: "ferry"
        case .vessels: "location.north.circle"
        }
    }

    private static let portReferenceMarkers = [
        LicensedMapMarker(id: "seattle", title: "Seattle", subtitle: "Reference port location", latitude: 47.61, longitude: -122.33, kind: .port),
        LicensedMapMarker(id: "tokyo", title: "Tokyo", subtitle: "Reference port location", latitude: 35.68, longitude: 139.76, kind: .port),
        LicensedMapMarker(id: "busan", title: "Busan", subtitle: "Reference port location", latitude: 35.18, longitude: 129.08, kind: .port),
        LicensedMapMarker(id: "qingdao", title: "Qingdao", subtitle: "Reference port location", latitude: 36.07, longitude: 120.38, kind: .port),
        LicensedMapMarker(id: "rotterdam", title: "Rotterdam", subtitle: "Reference port location", latitude: 51.92, longitude: 4.48, kind: .port),
    ]
}
#endif

private struct NetworkHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    SectionTitle(
                        "What Network means",
                        eyebrow: "Help",
                        subtitle: "How to interpret buyers, trade lanes, ports and vessel records."
                    )

                    NetworkHelpRow(symbol: "building.2", title: "Buyers", body: "Importer, wholesaler, restaurant or supermarket profiles. Contact and import history require source and license checks.")
                    NetworkHelpRow(symbol: "arrow.triangle.swap", title: "Trade", body: "Aggregated country-to-country seafood volume and growth. It is a market flow, not a live shipment booking.")
                    NetworkHelpRow(symbol: "ferry", title: "Ports", body: "Landing, species and price observations tied to a port and timestamp. Missing updates are not treated as zero landings.")
                    NetworkHelpRow(symbol: "location.north.circle", title: "Vessels", body: "AIS or last-known intelligence records. Unless explicitly verified and labeled otherwise, a vessel record is tracking-only—not a boat offered for sale, rent or employment.")

                    AquaCard(emphasized: true) {
                        Text("VESSEL AVAILABILITY LABELS")
                            .font(.caption2.weight(.bold))
                            .tracking(1.1)
                            .foregroundStyle(AquaTheme.signalBlue)
                        Text("Tracking only")
                            .font(.headline)
                            .foregroundStyle(AquaTheme.textPrimary)
                            .padding(.top, 8)
                        Text("Position and operating context only; no commercial availability is implied.")
                            .font(.caption)
                            .foregroundStyle(AquaTheme.textSecondary)
                        Text("Charter available")
                            .font(.headline)
                            .foregroundStyle(AquaTheme.textPrimary)
                            .padding(.top, 10)
                        Text("A future verified listing where the vessel/operator accepts rental or voyage charter inquiries.")
                            .font(.caption)
                            .foregroundStyle(AquaTheme.textSecondary)
                        Text("Fleet service available")
                            .font(.headline)
                            .foregroundStyle(AquaTheme.textPrimary)
                            .padding(.top, 10)
                        Text("A future verified operator service that can be hired for a contract. It does not mean hiring individual crew through AquaHunter.")
                            .font(.caption)
                            .foregroundStyle(AquaTheme.textSecondary)
                    }

                    MaritimeRiskDisclaimerView()

                    Text("AquaHunter must show one explicit availability label before exposing any inquiry action. No label means no rental or hire offer.")
                        .font(.caption)
                        .foregroundStyle(AquaTheme.textSecondary)
                }
                .padding(18)
            }
            .navigationTitle("Network Help")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .aquaPageBackground()
        }
    }
}

private struct MaritimeDisclaimerSection: Identifiable {
    let id: String
    let title: String
    let body: String
}

let maritimeRiskNoticeVersion = "2026-07-19"

private let maritimeDisclaimerSections: [MaritimeDisclaimerSection] = [
    .init(
        id: "information",
        title: "1. Intelligence service—not navigation, detection or professional advice",
        body: "AquaHunter provides market, environmental, probability, port, trade, buyer and vessel intelligence. It is not a nautical chart, collision-avoidance system, fish finder, weather-routing service, distress service, coast-guard instruction, legal opinion, insurance advice or substitute for the professional judgment of a licensed master, skipper, operator, fleet manager or competent authority. Fish Probability and Ocean Intelligence scores are statistical estimates only. They do not mean fish are present, catchable, lawful to harvest or commercially viable. Never use AquaHunter as the sole basis for navigation, departure, route, fishing, safety or emergency decisions."
    ),
    .init(
        id: "environment",
        title: "2. Weather, ocean and fish movement risk",
        body: "Marine conditions can change rapidly and without notice. Wind, waves, swell, fog, ice, storms, typhoons, hurricanes, lightning, visibility, tides, temperature fronts, chlorophyll, salinity, oxygen, depth, seabed conditions and ocean currents may differ from observations or forecasts. Satellite coverage, cloud cover, sensor failure, model error and transmission delay can create gaps or inaccuracies. Fish schools may move, disperse, dive, migrate or disappear before a vessel arrives because of currents, weather, predators, food availability, vessel activity, seasonality or other biological factors. AquaHunter does not guarantee a sighting, catch, catch volume, species, quality, price, revenue, fuel efficiency or return on a voyage."
    ),
    .init(
        id: "vessel",
        title: "3. Vessel charter, fleet service and hiring",
        body: "Unless a record is expressly marked “Charter available” or “Fleet service available” and separately verified, a vessel card is tracking-only information and is not an offer to sell, rent, charter, crew or hire a vessel. AquaHunter is not the owner, operator, employer, crewing agency, broker, carrier or insurer of third-party vessels and is not a party to agreements made between users and vessel or fleet providers. Users must independently verify identity, authority, beneficial ownership, flag, registration, class, seaworthiness, maintenance, equipment, crew competence, labor conditions, safety management, insurance, pollution cover, liens, sanctions exposure, permits and contract terms. Any deposit, charter party, employment, service agreement or voyage instruction is entered into at the parties’ own risk unless separate written AquaHunter marketplace terms state otherwise."
    ),
    .init(
        id: "operations",
        title: "4. Master, operator and user responsibility",
        body: "The master and operator retain sole authority and responsibility for the vessel, crew, passengers, cargo, route and operational decisions. They must obtain current official charts, Notices to Mariners, meteorological and ocean warnings, port instructions, security advisories, navigational warnings and emergency communications; maintain a proper lookout; carry required safety and communications equipment; assess crew fatigue and competence; and comply with flag-state, coastal-state, port-state and international requirements. No AquaHunter prediction, alert, map, route, message or commercial request overrides the master’s professional judgment or duty to protect life, the vessel and the marine environment."
    ),
    .init(
        id: "security",
        title: "5. Piracy, armed robbery, conflict and security",
        body: "Sea voyages may expose vessels and people to piracy, armed robbery, kidnapping, theft, smuggling, sabotage, terrorism, civil unrest, war, mines, detention, embargoes, sanctions, communications disruption and port closure. Threat reports may be incomplete, delayed or unavailable. AquaHunter does not provide armed security, convoy protection, evacuation, rescue or real-time threat assurance. Owners, operators and masters must conduct their own voyage-specific security assessment, use current official and industry guidance, report through applicable maritime security channels, maintain required security plans and decide whether a voyage should proceed. The absence of an alert in AquaHunter does not mean an area is safe."
    ),
    .init(
        id: "ais",
        title: "6. AIS and vessel-position limitations",
        body: "AIS and other vessel data may be delayed, incomplete, inaccurate, intentionally disabled, incorrectly entered, duplicated, spoofed, obstructed by coverage limits or restricted by a provider or law. A displayed point may be historical rather than current and may not represent ownership, activity, destination, fishing behavior or commercial availability. Do not use AquaHunter AIS displays for collision avoidance, search and rescue, law-enforcement action, border decisions or proof that a vessel committed or did not commit an act. Verify material facts with licensed providers, vessel operators and competent authorities."
    ),
    .init(
        id: "lawful-fishing",
        title: "7. Fishing law, borders, closed areas and IUU fishing",
        body: "Users are solely responsible for determining whether any voyage and fishing activity is lawful. Before operating, users must verify the current location and boundaries of territorial seas, exclusive economic zones, disputed waters, marine protected areas, no-take zones, seasonal closures, spawning closures, port restrictions and other controlled areas. Users must obtain and comply with all licenses, vessel authorizations, quotas, catch limits, species rules, size limits, gear restrictions, bycatch rules, protected-species requirements, observer or monitoring duties, transshipment rules, landing requirements, catch documentation, customs, labor, environmental and reporting obligations. AquaHunter does not authorize fishing in another country’s waters or any prohibited area. Illegal, unreported or unregulated fishing is forbidden. A map, probability cell, vessel track or missing boundary does not create a right to enter, fish, land or trade."
    ),
    .init(
        id: "commercial",
        title: "8. Market, buyer and transaction risk",
        body: "Prices, volumes, buyer profiles, import history, certificates, licenses and contact details may be normalized, estimated, delayed, incomplete or supplied by third parties. They are not binding quotations, credit decisions or guarantees of identity, solvency, capacity, legality, product quality, payment or delivery. Users must perform sanctions, anti-money-laundering, counterparty, food-safety, traceability, certificate, export-control, tax, customs and contract due diligence. AquaHunter is not responsible for losses caused by price movement, failed negotiations, non-payment, fraud, spoiled cargo, cold-chain failure, detention, rejection, recall, demurrage or other transaction events, except where liability cannot lawfully be excluded."
    ),
    .init(
        id: "emergency",
        title: "9. Emergencies and loss reporting",
        body: "AquaHunter is not monitored as an emergency channel. Do not send distress calls, medical emergencies, piracy alerts, pollution reports or rescue requests only through the app. Use the vessel’s approved distress and safety systems and immediately contact the relevant coast guard, maritime rescue coordination center, port, flag-state or local emergency service. Connectivity and app availability are not guaranteed offshore. Users should maintain independent communications, offline charts, contingency plans, emergency contacts and backups."
    ),
    .init(
        id: "liability",
        title: "10. Assumption of risk and limitation of liability",
        body: "To the maximum extent permitted by applicable law, users assume the risks of relying on marine, fisheries, vessel and commercial information and remain responsible for their decisions, acts, omissions, compliance, contracts and operations. AquaHunter and its providers do not warrant uninterrupted access, completeness, accuracy, timeliness, fitness for a particular purpose, safety, legality, catch success or commercial outcome, and are not liable for indirect, incidental, special, exemplary, punitive or consequential loss, including loss of life or injury where exclusion is lawful, vessel or equipment damage, lost catch, lost profit, fuel cost, delay or reputational loss arising from use of or reliance on the service. Nothing in this notice excludes or limits liability that applicable law does not permit to be excluded or limited, including liability arising from fraud, willful misconduct, gross negligence or mandatory consumer and safety rights where applicable. Separate signed marketplace, charter or enterprise terms may impose additional obligations and will control if they expressly conflict with this general notice."
    ),
]

struct MaritimeRiskDisclaimerView: View {
    var body: some View {
        AquaCard {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 3) {
                    Text("MARITIME OPERATIONS & LEGAL RISK NOTICE")
                        .font(.caption2.weight(.bold))
                        .tracking(1.0)
                        .foregroundStyle(.yellow)
                    Text("Version \(maritimeRiskNoticeVersion)")
                        .font(.caption2)
                        .foregroundStyle(AquaTheme.textSecondary)
                }
            }

            Text("Read this notice before using vessel, radar, route, port or fleet features. Review current official information and obtain qualified legal advice for each operating jurisdiction before live charter, hiring or fishing operations.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AquaTheme.textPrimary)
                .padding(.top, 10)

            ForEach(maritimeDisclaimerSections) { section in
                VStack(alignment: .leading, spacing: 5) {
                    Text(section.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AquaTheme.textPrimary)
                    Text(section.body)
                        .font(.caption2)
                        .foregroundStyle(AquaTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 12)
            }

            Text("By continuing to use operational features, the user confirms that AquaHunter is a decision-support tool only and that the user will independently verify safety, legality and commercial suitability. Opening this notice is not a substitute for a signed marketplace, charter or enterprise agreement.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AquaTheme.textPrimary)
                .padding(.top, 14)
        }
    }
}

struct MaritimeRiskGateView: View {
    let onAccept: () -> Void
    @State private var confirmsReading = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    AquaBrandMark(size: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AquaHunter")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AquaTheme.textPrimary)
                        Text("Required before first use")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 14) {
                    SectionTitle(
                        "Maritime operations & legal risk notice",
                        eyebrow: "Required acknowledgement",
                        subtitle: "Review this notice before entering any AquaHunter feature."
                    )
                    MaritimeRiskDisclaimerView()
                }

                Toggle(isOn: $confirmsReading) {
                    Text("I have read and understand the Maritime Operations & Legal Risk Notice, including safety, fish-probability, vessel, piracy and lawful-fishing limitations.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AquaTheme.textPrimary)
                }
                .tint(AquaTheme.signalBlue)

                Button {
                    onAccept()
                } label: {
                    Text("Accept and enter AquaHunter")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .foregroundStyle(confirmsReading ? AquaTheme.deepOcean : AquaTheme.textSecondary)
                .background(confirmsReading ? AquaTheme.signalBlue : AquaTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .disabled(!confirmsReading)

                Text("Acceptance is stored on this device for notice version \(maritimeRiskNoticeVersion).")
                    .font(.caption2)
                    .foregroundStyle(AquaTheme.textSecondary)
            }
            .padding(18)
        }
        .scrollIndicators(.visible)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AquaTheme.deepOcean.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

private struct NetworkHelpRow: View {
    let symbol: String
    let title: String
    let detail: String

    init(symbol: String, title: String, body: String) {
        self.symbol = symbol
        self.title = title
        detail = body
    }

    var body: some View {
        AquaCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: symbol)
                    .font(.headline)
                    .foregroundStyle(AquaTheme.signalBlue)
                    .frame(width: 34, height: 34)
                    .background(AquaTheme.signalBlue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AquaTheme.textPrimary)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(AquaTheme.textSecondary)
                }
            }
        }
    }
}
