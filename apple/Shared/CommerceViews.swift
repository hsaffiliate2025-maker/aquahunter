import SwiftUI
import UniformTypeIdentifiers

struct CommerceCSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct CommerceToolkitView: View {
    @EnvironmentObject private var commerce: CommerceStore
    @AppStorage("appLanguage") private var languageCode =
        AquaAppLanguage.english.rawValue
    @Binding var destination: CommerceDestination

    @StateObject private var marketsStore = ProductionMarketsStore(
        historyWeeks: 520
    )
    @State private var showsStore = false
    @State private var resultTitle: String?
    @State private var resultBody: String?
    @State private var isExporting = false
    @State private var exportDocument: CommerceCSVDocument?
    @State private var exportSeriesID = ""
    @State private var exchangeRate = "0.095"
    @State private var freightPerKg = "1.20"
    @State private var tariffPercent = "0"
    @State private var lossPercent = "2"
    @State private var alertThreshold = "70"
    @State private var alertDirection = PriceAlertRule.Direction.above

    private var locale: CommerceLocaleText? {
        commerce.catalog?.locale(for: languageCode)
    }

    private func tool(
        _ key: String,
        fallback: String,
        values: [String: String] = [:]
    ) -> String {
        let template = locale?.tool(key, fallback: fallback) ?? fallback
        return values.reduce(template) { output, item in
            output.replacingOccurrences(
                of: "{\(item.key)}",
                with: item.value
            )
        }
    }

    private func commodityName(_ code: String) -> String {
        tool(
            "commodity.\(code)",
            fallback: code == "01"
                ? "Fresh or chilled, farmed"
                : "Frozen, farmed"
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                SectionTitle(
                    tool("title", fallback: "Research toolkit"),
                    eyebrow: tool(
                        "eyebrow",
                        fallback: "Licensed market intelligence"
                    ),
                    subtitle: tool(
                        "subtitle",
                        fallback: "Every delivered result cites its official source. Failed or empty results never use a credit."
                    )
                )

                destinationPicker

                if destination == .history {
                    historyView
                } else {
                    meteredToolView
                }

                sourceDisclosure
            }
            .padding(18)
        }
        .navigationTitle(
            locale?.destinations[destination]
                ?? tool("title", fallback: "Research toolkit")
        )
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showsStore = true
                } label: {
                    Label(
                        locale?.store.storeButton ?? "Store",
                        systemImage: "cart.fill"
                    )
                }
            }
        }
        .aquaPageBackground()
        .sheet(isPresented: $showsStore) {
            NavigationStack {
                CommerceStorefrontView(
                    initialDestination: destination,
                    onClose: { showsStore = false },
                    onOpenDestination: {
                        destination = $0
                        showsStore = false
                    }
                )
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .commaSeparatedText,
            defaultFilename: "AquaHunter-\(exportSeriesID)"
        ) { result in
            switch result {
            case let .success(url):
                if commerce.consumeSuccessfulResult(.export) {
                    resultTitle = tool(
                        "result.exportDelivered",
                        fallback: "CSV delivered"
                    )
                    resultBody = tool(
                        "body.export",
                        fallback: "{file}\nStatistics Norway · 03024 · CC BY 4.0",
                        values: ["file": url.lastPathComponent]
                    )
                }
            case .failure:
                resultTitle = tool(
                    "result.exportFailed",
                    fallback: "Export not delivered"
                )
                resultBody = locale?.noCharge
                    ?? "No result was delivered, so no credit was used."
            }
            exportDocument = nil
        }
        .task {
            await marketsStore.loadIfNeeded()
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains(
                "--aquahunter-screenshot-store"
            ) {
                showsStore = true
            }
            #endif
        }
    }

    private var destinationPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CommerceDestination.allCases) { item in
                    Button {
                        destination = item
                        resultTitle = nil
                        resultBody = nil
                    } label: {
                        Text(locale?.destinations[item] ?? item.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                destination == item
                                    ? AquaTheme.deepOcean
                                    : AquaTheme.textSecondary
                            )
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(
                                destination == item
                                    ? AquaTheme.signalBlue
                                    : AquaTheme.surface
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var historyView: some View {
        let weeks = commerce.historyWeeks()
        if weeks <= 52 {
            AquaCard(emphasized: true) {
                Label(
                    tool(
                        "historyLockedTitle",
                        fallback: "Extended history requires Markets Plus, Pro or Max"
                    ),
                    systemImage: "lock.fill"
                )
                .font(.headline)
                .foregroundStyle(AquaTheme.textPrimary)
                Text(
                    tool(
                        "historyLockedBody",
                        fallback: "The free market screen keeps 52 official weekly observations. A subscription unlocks a finite 3-, 5- or 10-year licensed history window."
                    )
                )
                .font(.subheadline)
                .foregroundStyle(AquaTheme.textSecondary)
                storeButton
            }
        } else {
            loadedSeries { series in
                ForEach(series) { item in
                    AquaCard {
                        Text(commodityName(item.commodityCode))
                            .font(.headline)
                            .foregroundStyle(AquaTheme.textPrimary)
                        CommerceSparkline(
                            values: Array(
                                item.points.suffix(weeks)
                            ).map(\.pricePerKg),
                            color: AquaTheme.positive
                        )
                        .frame(minHeight: 210)
                        Text(
                            tool(
                                "observationSummary",
                                fallback: "{count} official weekly observations · {currency}/{unit}",
                                values: [
                                    "count": String(
                                        min(item.points.count, weeks)
                                    ),
                                    "currency": item.currencyCode,
                                    "unit": item.unit,
                                ]
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(AquaTheme.textSecondary)
                        Text(
                            "Statistics Norway · 03024 · "
                                + "\(item.commodityCode) · CC BY 4.0"
                        )
                            .font(.caption2)
                            .foregroundStyle(AquaTheme.positive)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var meteredToolView: some View {
        AquaCard(emphasized: true) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(locale?.destinations[destination] ?? destination.rawValue)
                        .font(.headline)
                        .foregroundStyle(AquaTheme.textPrimary)
                    Text(
                        locale?.replacing(
                            locale?.balance ?? "{count} remaining",
                            values: [
                                "count": String(commerce.available(destination)),
                            ]
                        ) ?? "\(commerce.available(destination)) remaining"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AquaTheme.signalBlue)
                }
                Spacer()
                Button {
                    showsStore = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AquaTheme.signalBlue)
            }

            if destination == .landedCost {
                landedCostFields
            } else if destination == .alerts {
                alertFields
            }

            Button(action: runSelectedTool) {
                Label(actionTitle, systemImage: actionSymbol)
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AquaTheme.deepOcean)
            .background(AquaTheme.signalBlue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(commerce.available(destination) == 0)
            .opacity(commerce.available(destination) == 0 ? 0.45 : 1)
            .padding(.top, 8)

            if commerce.available(destination) == 0 {
                Text(
                    tool(
                        "creditPrompt",
                        fallback: "Choose a finite credit pack or subscription allowance."
                    )
                )
                    .font(.caption)
                    .foregroundStyle(.yellow)
                storeButton
            }
        }

        if let resultTitle, let resultBody {
            AquaCard {
                Label(resultTitle, systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(AquaTheme.positive)
                Text(resultBody)
                    .font(.subheadline)
                    .foregroundStyle(AquaTheme.textPrimary)
                    .textSelection(.enabled)
            }
        }
    }

    private var landedCostFields: some View {
        VStack(spacing: 8) {
            inputField(
                tool("exchangeRate", fallback: "Target currency per NOK"),
                text: $exchangeRate
            )
            inputField(
                tool("freight", fallback: "Freight per kg"),
                text: $freightPerKg
            )
            inputField(
                tool("tariff", fallback: "Tariff %"),
                text: $tariffPercent
            )
            inputField(
                tool("loss", fallback: "Loss %"),
                text: $lossPercent
            )
            Text(
                tool(
                    "assumptionNotice",
                    fallback: "The exchange rate and costs are your assumptions; AquaHunter does not supply or guarantee them."
                )
            )
            .font(.caption2)
            .foregroundStyle(.yellow)
        }
        .padding(.top, 10)
    }

    private var alertFields: some View {
        VStack(spacing: 8) {
            Picker(
                tool("direction", fallback: "Direction"),
                selection: $alertDirection
            ) {
                Text(tool("above", fallback: "At or above"))
                    .tag(PriceAlertRule.Direction.above)
                Text(tool("below", fallback: "At or below"))
                    .tag(PriceAlertRule.Direction.below)
            }
            .pickerStyle(.segmented)
            inputField(
                tool("threshold", fallback: "Threshold in NOK/kg"),
                text: $alertThreshold
            )
            Text(
                tool(
                    "alertNotice",
                    fallback: "A credit is used only when the latest official period matches and the alert is delivered in this app."
                )
            )
            .font(.caption2)
            .foregroundStyle(AquaTheme.textSecondary)
        }
        .padding(.top, 10)
    }

    private func inputField(
        _ title: String,
        text: Binding<String>
    ) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(AquaTheme.textSecondary)
            Spacer()
            TextField("0", text: text)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 150)
            #if os(iOS)
                .keyboardType(.decimalPad)
            #endif
        }
    }

    private var storeButton: some View {
        Button {
            showsStore = true
        } label: {
            Label(
                tool(
                    "viewPlans",
                    fallback: "View plans and credit packs"
                ),
                systemImage: "cart"
            )
                .font(.subheadline.weight(.semibold))
        }
        .buttonStyle(.bordered)
        .tint(AquaTheme.signalBlue)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var sourceDisclosure: some View {
        AquaCard {
            Label(
                tool(
                    "reuseTitle",
                    fallback: "Commercial reuse verified"
                ),
                systemImage: "checkmark.shield"
            )
                .font(.headline)
                .foregroundStyle(AquaTheme.positive)
            Text(
                tool(
                    "reuseBody",
                    fallback: "Paid results in this release use Statistics Norway Statbank table 03024 under CC BY 4.0. Commercial use, derivative analysis and attributed redistribution are enabled by the release license registry."
                )
            )
            .font(.caption)
            .foregroundStyle(AquaTheme.textSecondary)
            Text(
                tool(
                    "benchmarkLimit",
                    fallback: "National weekly export unit values; not city prices, auction quotes or executable offers."
                )
            )
            .font(.caption)
            .foregroundStyle(.yellow)
        }
    }

    @ViewBuilder
    private func loadedSeries<Content: View>(
        @ViewBuilder content: @escaping ([ProductionMarketSeries]) -> Content
    ) -> some View {
        switch marketsStore.state {
        case .idle, .loading:
            AquaCard {
                ProgressView(
                    tool(
                        "loading",
                        fallback: "Loading licensed observations…"
                    )
                )
            }
        case let .unavailable(message):
            AquaCard {
                Text(message)
                    .foregroundStyle(AquaTheme.textSecondary)
                Text(locale?.noCharge ?? "No credit was used.")
                    .font(.caption)
                    .foregroundStyle(.yellow)
            }
        case let .loaded(series):
            content(series)
        }
    }

    private var actionTitle: String {
        tool(
            "action.\(destination.rawValue)",
            fallback: [
                .history: "Open history",
                .export: "Prepare CSV",
                .compare: "Create comparison",
                .snapshot: "Create snapshot",
                .seasonality: "Create seasonality report",
                .landedCost: "Calculate landed cost",
                .alerts: "Save and evaluate alert",
            ][destination]!
        )
    }

    private var actionSymbol: String {
        switch destination {
        case .export: "square.and.arrow.up"
        case .compare: "arrow.left.arrow.right"
        case .snapshot: "camera.metering.center.weighted"
        case .seasonality: "calendar"
        case .landedCost: "shippingbox"
        case .alerts: "bell"
        case .history: "chart.xyaxis.line"
        }
    }

    private func runSelectedTool() {
        guard
            commerce.available(destination) > 0,
            case let .loaded(series) = marketsStore.state,
            let first = series.first
        else {
            resultTitle = tool("noResult", fallback: "No result")
            resultBody = locale?.noCharge
            return
        }

        do {
            switch destination {
            case .history:
                return
            case .export:
                exportDocument = CommerceCSVDocument(
                    data: try CommerceAnalytics.csvData(series: first)
                )
                exportSeriesID = first.id
                isExporting = true
                return
            case .compare:
                guard series.count >= 2 else {
                    throw CommerceAnalyticsError.incomparableSeries
                }
                let output = try CommerceAnalytics.compare(
                    first: series[0],
                    second: series[1]
                )
                resultTitle = tool(
                    "result.compare",
                    fallback: "Official market comparison"
                )
                resultBody = tool(
                    "body.compare",
                    fallback: "Period {period}\n{first}: {firstPrice}\n{second}: {secondPrice}\nSpread: {spread} {currency}/{unit} ({spreadPercent})\nStatistics Norway · 03024 · CC BY 4.0",
                    values: [
                        "period": output.periodCode,
                        "first": commodityName(output.firstCommodityCode),
                        "firstPrice": String(
                            format: "%.2f",
                            output.firstPricePerKg
                        ),
                        "second": commodityName(output.secondCommodityCode),
                        "secondPrice": String(
                            format: "%.2f",
                            output.secondPricePerKg
                        ),
                        "spread": String(
                            format: "%+.2f",
                            output.absoluteSpreadPerKg
                        ),
                        "currency": output.currencyCode,
                        "unit": output.unit,
                        "spreadPercent": String(
                            format: "%+.1f%%",
                            output.spreadPercentOfSecond
                        ),
                    ]
                )
            case .snapshot:
                let output = try CommerceAnalytics.snapshot(series: first)
                resultTitle = tool(
                    "result.snapshot",
                    fallback: "Sourced market snapshot"
                )
                resultBody = tool(
                    "body.snapshot",
                    fallback: "{period}: {price} NOK/kg\nChange: {change}\n12-week average: {average}\nRange: {low}–{high}\nStatistics Norway · 03024 · {commodity} · CC BY 4.0",
                    values: [
                        "period": output.periodCode,
                        "price": String(format: "%.2f", output.pricePerKg),
                        "change": output.changePercent.map {
                            String(format: "%+.1f%%", $0)
                        } ?? tool("unavailable", fallback: "Unavailable"),
                        "average": String(
                            format: "%.2f",
                            output.average12Week
                        ),
                        "low": String(format: "%.2f", output.low12Week),
                        "high": String(format: "%.2f", output.high12Week),
                        "commodity": commodityName(output.commodityCode),
                    ]
                )
            case .seasonality:
                let output = try CommerceAnalytics.seasonality(series: first)
                resultTitle = tool(
                    "result.seasonality",
                    fallback: "Seasonality report"
                )
                resultBody = tool(
                    "body.seasonality",
                    fallback: "Week {week} · {years} historical years\nHistorical average: {average} NOK/kg\nLatest: {latest} NOK/kg\nDifference: {difference}\nStatistics Norway · 03024 · CC BY 4.0",
                    values: [
                        "week": String(output.weekOfYear),
                        "years": String(output.sampleYears),
                        "average": String(
                            format: "%.2f",
                            output.historicalAverage
                        ),
                        "latest": String(
                            format: "%.2f",
                            output.latestPrice
                        ),
                        "difference": String(
                            format: "%+.1f%%",
                            output.differencePercent
                        ),
                    ]
                )
            case .landedCost:
                guard let latest = first.latest else {
                    throw CommerceAnalyticsError.insufficientData
                }
                let output = try CommerceAnalytics.landedCost(
                    input: LandedCostInput(
                        sourcePricePerKg: latest.pricePerKg,
                        sourceCurrencyCode: first.currencyCode,
                        targetCurrencyCode: "USD",
                        targetCurrencyPerSourceCurrency: try numeric(exchangeRate),
                        freightPerKgTargetCurrency: try numeric(freightPerKg),
                        tariffPercent: try numeric(tariffPercent),
                        lossPercent: try numeric(lossPercent)
                    )
                )
                resultTitle = tool(
                    "result.landedCost",
                    fallback: "Landed-cost calculation"
                )
                resultBody = tool(
                    "body.landedCost",
                    fallback: "Source {period}: {sourcePrice} NOK/kg\nConverted source: {converted} USD/kg\nBefore loss: {subtotal} USD/kg\nLanded cost: {landed} USD/saleable kg\nUser assumptions: FX {fx} · freight {freight} · tariff {tariff}% · loss {loss}%",
                    values: [
                        "period": latest.periodCode,
                        "sourcePrice": String(
                            format: "%.2f",
                            latest.pricePerKg
                        ),
                        "converted": String(
                            format: "%.2f",
                            output.convertedSourcePricePerKg
                        ),
                        "subtotal": String(
                            format: "%.2f",
                            output.subtotalBeforeLoss
                        ),
                        "landed": String(
                            format: "%.2f",
                            output.landedCostPerSaleableKg
                        ),
                        "fx": exchangeRate,
                        "freight": freightPerKg,
                        "tariff": tariffPercent,
                        "loss": lossPercent,
                    ]
                )
            case .alerts:
                let rule = PriceAlertRule(
                    id: UUID(),
                    seriesID: first.id,
                    threshold: try numeric(alertThreshold),
                    direction: alertDirection,
                    currencyCode: first.currencyCode,
                    unit: first.unit,
                    lastDeliveredPeriodCode: nil
                )
                guard rule.matches(first), let latest = first.latest else {
                    resultTitle = tool(
                        "result.alertNoMatch",
                        fallback: "Alert saved; no matching event"
                    )
                    resultBody = locale?.noCharge
                    return
                }
                resultTitle = tool(
                    "result.alertDelivered",
                    fallback: "Price alert delivered"
                )
                resultBody = tool(
                    "body.alert",
                    fallback: "{commodity}: {price} {currency}/{unit} · official period {period}\nStatistics Norway · 03024 · CC BY 4.0",
                    values: [
                        "commodity": commodityName(first.commodityCode),
                        "price": String(
                            format: "%.2f",
                            latest.pricePerKg
                        ),
                        "currency": first.currencyCode,
                        "unit": first.unit,
                        "period": latest.periodCode,
                    ]
                )
            }
            guard commerce.consumeSuccessfulResult(destination) else {
                resultTitle = tool(
                    "noCredit",
                    fallback: "No credit available"
                )
                resultBody = locale?.noCharge
                return
            }
        } catch {
            resultTitle = tool("noResult", fallback: "No result")
            resultBody = locale?.noCharge
                ?? "No result was delivered, so no credit was used."
        }
    }

    private func numeric(_ value: String) throws -> Double {
        guard
            let output = Double(
                value.replacingOccurrences(of: ",", with: ".")
            ),
            output.isFinite
        else {
            throw CommerceAnalyticsError.invalidAssumption
        }
        return output
    }
}

struct CommerceStorefrontView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var commerce: CommerceStore
    @AppStorage("appLanguage") private var languageCode =
        AquaAppLanguage.english.rawValue

    let initialDestination: CommerceDestination
    let onClose: () -> Void
    let onOpenDestination: (CommerceDestination) -> Void

    private var locale: CommerceLocaleText? {
        commerce.catalog?.locale(for: languageCode)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                SectionTitle(
                    locale?.store.plansTitle ?? "Plans & credit packs",
                    eyebrow: locale?.store.optionsEyebrow
                        ?? "24 purchase options",
                    subtitle: locale?.store.allowanceDisclosure
                        ?? "Finite allowances only. A credit is used after a valid result or file is successfully delivered."
                )

                if let message = commerce.statusMessage {
                    AquaCard {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }

                if let catalog = commerce.catalog {
                    productSection(
                        title: locale?.store.subscriptionsTitle
                            ?? "Subscriptions",
                        products: catalog.products.filter(\.isSubscription)
                    )
                    productSection(
                        title: locale?.store.oneTimeTitle
                            ?? "One-time credit packs",
                        products: catalog.products.filter { !$0.isSubscription }
                    )
                } else {
                    AquaCard {
                        Text("The signed commerce catalog is unavailable.")
                            .foregroundStyle(.yellow)
                    }
                }

                Button {
                    Task { await commerce.restore(languageCode: languageCode) }
                } label: {
                    Label(
                        locale?.restore ?? "Restore purchases",
                        systemImage: "arrow.clockwise"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .tint(AquaTheme.signalBlue)

                Text(
                    locale?.store.legalDisclosure
                        ?? "Subscriptions auto-renew unless cancelled in your store account. Consumable credits stay on this device and are lost if app data is cleared or the app is uninstalled."
                )
                .font(.caption2)
                .foregroundStyle(AquaTheme.textSecondary)
            }
            .padding(18)
        }
        .navigationTitle(locale?.store.title ?? "Store")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(locale?.store.done ?? "Done") {
                    onClose()
                    dismiss()
                }
            }
        }
        .alert(item: $commerce.thankYou) { thankYou in
            Alert(
                title: Text(thankYou.title),
                message: Text(thankYou.message),
                primaryButton: .default(
                    Text(thankYou.actionTitle)
                ) {
                    commerce.thankYou = nil
                    onOpenDestination(thankYou.destination)
                },
                secondaryButton: .cancel(
                    Text(locale?.store.later ?? "Later")
                ) {
                    commerce.thankYou = nil
                }
            )
        }
        .aquaPageBackground()
    }

    @ViewBuilder
    private func productSection(
        title: String,
        products: [CommerceProductDefinition]
    ) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.bold))
            .tracking(1.1)
            .foregroundStyle(AquaTheme.signalBlue)
            .padding(.top, 6)

        ForEach(products) { definition in
            CommerceProductCard(
                definition: definition,
                languageCode: languageCode
            )
        }
    }
}

private struct CommerceProductCard: View {
    @EnvironmentObject private var commerce: CommerceStore
    let definition: CommerceProductDefinition
    let languageCode: String

    private var text: CommerceProductText? {
        try? commerce.catalog?.text(
            for: definition,
            languageCode: languageCode
        )
    }

    var body: some View {
        AquaCard(emphasized: definition.destination == .history) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(text?.name ?? definition.id)
                        .font(.headline)
                        .foregroundStyle(AquaTheme.textPrimary)
                    Text(text?.description ?? "")
                        .font(.caption)
                        .foregroundStyle(AquaTheme.textSecondary)
                    Text(
                        commerce.catalog?.locale(
                            for: languageCode
                        ).destinations[definition.destination]
                            ?? definition.destination.rawValue
                    )
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AquaTheme.positive)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text(
                        commerce.storeProducts[definition.id]?.displayPrice
                            ?? commerce.catalog?.locale(
                                for: languageCode
                            ).store.unavailable
                            ?? "Unavailable"
                    )
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AquaTheme.textPrimary)
                    Button {
                        Task {
                            await commerce.purchase(
                                productID: definition.id,
                                languageCode: languageCode
                            )
                        }
                    } label: {
                        Text(
                            commerce.catalog?.locale(
                                for: languageCode
                            ).purchase ?? "Purchase"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AquaTheme.signalBlue)
                    .disabled(commerce.storeProducts[definition.id] == nil)
                }
            }
        }
    }
}

private struct CommerceSparkline: View {
    let values: [Double]
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let low = values.min() ?? 0
            let high = values.max() ?? 1
            let spread = max(high - low, 0.000_001)
            Path { path in
                for (index, value) in values.enumerated() {
                    let x = values.count <= 1
                        ? proxy.size.width / 2
                        : proxy.size.width
                            * CGFloat(index) / CGFloat(values.count - 1)
                    let normalized = (value - low) / spread
                    let y = proxy.size.height
                        * (1 - CGFloat(normalized))
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: 2.2,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        }
        .accessibilityLabel(
            "\(values.count) official weekly price observations"
        )
    }
}
