import SwiftUI

enum AquaSection: String, CaseIterable, Identifiable, Hashable {
    case pulse = "Pulse"
    case markets = "Markets"
    case radar = "Radar"
    case network = "Network"
    case toolkit = "Toolkit"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .pulse: "waveform.path.ecg"
        case .markets: "chart.xyaxis.line"
        case .radar: "scope"
        case .network: "point.3.connected.trianglepath.dotted"
        case .toolkit: "shippingbox.and.arrow.backward"
        }
    }

    func localizedTitle(languageCode: String) -> String {
        let index = AquaSection.allCases.firstIndex(of: self) ?? 0
        let labels: [String]
        switch languageCode {
        case "zh-Hans": labels = ["脉动", "行情", "雷达", "网络", "工具"]
        case "zh-Hant": labels = ["脈動", "行情", "雷達", "網路", "工具"]
        case "es": labels = ["Pulso", "Mercados", "Radar", "Red", "Herramientas"]
        case "fr": labels = ["Pouls", "Marchés", "Radar", "Réseau", "Outils"]
        case "de": labels = ["Puls", "Märkte", "Radar", "Netzwerk", "Werkzeuge"]
        case "ja": labels = ["動向", "市場", "レーダー", "ネットワーク", "ツール"]
        case "ko": labels = ["동향", "시장", "레이더", "네트워크", "도구"]
        case "pt-BR": labels = ["Pulso", "Mercados", "Radar", "Rede", "Ferramentas"]
        case "id": labels = ["Denyut", "Pasar", "Radar", "Jaringan", "Alat"]
        case "hi": labels = ["पल्स", "बाज़ार", "रडार", "नेटवर्क", "टूल"]
        case "ar": labels = ["نبض", "الأسواق", "الرادار", "الشبكة", "الأدوات"]
        default: labels = AquaSection.allCases.map(\.rawValue)
        }
        return labels[index]
    }
}

struct AquaShellView: View {
    @State private var selection: AquaSection
    @State private var showsSettings = false
    @State private var toolkitDestination = CommerceDestination.snapshot
    @StateObject private var commerce = CommerceStore()
    @AppStorage("maritimeRiskNoticeAcceptedVersion") private var acceptedRiskVersion = ""
    @AppStorage("appLanguage") private var appLanguage = AquaAppLanguage.english.rawValue

    init() {
        #if DEBUG
        let screenshotStore = ProcessInfo.processInfo.arguments.contains(
            "--aquahunter-screenshot-store"
        )
        _selection = State(initialValue: screenshotStore ? .toolkit : .pulse)
        #else
        _selection = State(initialValue: .pulse)
        #endif
    }

    private var requiresRiskAcceptance: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains(
            "--aquahunter-screenshot-store"
        ) {
            return false
        }
        #endif
        return acceptedRiskVersion != maritimeRiskNoticeVersion
    }

    var body: some View {
        ZStack {
            appShell
                .disabled(requiresRiskAcceptance)
                .accessibilityHidden(requiresRiskAcceptance)
                .environmentObject(commerce)

            if requiresRiskAcceptance {
                MaritimeRiskGateView {
                    acceptedRiskVersion = maritimeRiskNoticeVersion
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: requiresRiskAcceptance)
        .environment(\.locale, Locale(identifier: appLanguage))
        .environment(
            \.layoutDirection,
            appLanguage == AquaAppLanguage.arabic.rawValue ? .rightToLeft : .leftToRight
        )
        .sheet(isPresented: $showsSettings) {
            NavigationStack {
                AquaSettingsView()
            }
        }
        .task {
            await commerce.start()
        }
    }

    @ViewBuilder
    private var appShell: some View {
        #if os(iOS)
        TabView(selection: $selection) {
            ForEach(AquaSection.allCases) { section in
                NavigationStack {
                    screen(for: section)
                        .toolbar {
                            BrandToolbar(
                                showsSettings: section == .pulse,
                                onOpenSettings: { showsSettings = true }
                            )
                        }
                }
                .tabItem {
                    Label(section.localizedTitle(languageCode: appLanguage), systemImage: section.symbol)
                }
                .tag(section)
            }
        }
        .tint(AquaTheme.signalBlue)
        .toolbarBackground(AquaTheme.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .preferredColorScheme(.dark)
        #else
        NavigationSplitView {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    AquaBrandMark(size: 42)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("AQUA")
                            .font(.headline.weight(.black))
                            .tracking(1.2)
                        Text("HUNTER")
                            .font(.caption2.weight(.bold))
                            .tracking(2)
                            .foregroundStyle(AquaTheme.signalBlue)
                    }
                    Spacer()
                }
                .padding(16)

                List(AquaSection.allCases, selection: $selection) { section in
                    Label(section.localizedTitle(languageCode: appLanguage), systemImage: section.symbol)
                        .tag(section)
                        .foregroundStyle(selection == section ? AquaTheme.signalBlue : AquaTheme.textSecondary)
                }
                .scrollContentBackground(.hidden)
            }
            .background(AquaTheme.deepOcean)
            .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 260)
        } detail: {
            screen(for: selection)
                .toolbar {
                    BrandToolbar(
                        showsSettings: selection == .pulse,
                        onOpenSettings: { showsSettings = true }
                    )
                }
        }
        .tint(AquaTheme.signalBlue)
        .preferredColorScheme(.dark)
        #endif
    }

    @ViewBuilder
    private func screen(for section: AquaSection) -> some View {
        switch section {
        case .pulse: PulseView()
        case .markets: MarketsView()
        case .radar: RadarView()
        case .network: NetworkView()
        case .toolkit:
            CommerceToolkitView(destination: $toolkitDestination)
        }
    }
}

private struct BrandToolbar: ToolbarContent {
    let showsSettings: Bool
    let onOpenSettings: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if showsSettings {
                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape.fill")
                }
                .accessibilityLabel("Settings")
                .help("Settings")
            }
        }
    }
}
