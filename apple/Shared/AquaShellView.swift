import SwiftUI

enum AquaSection: String, CaseIterable, Identifiable, Hashable {
    case pulse = "Pulse"
    case markets = "Markets"
    case radar = "Radar"
    case network = "Network"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .pulse: "waveform.path.ecg"
        case .markets: "chart.xyaxis.line"
        case .radar: "scope"
        case .network: "point.3.connected.trianglepath.dotted"
        }
    }

    func localizedTitle(languageCode: String) -> String {
        let index = AquaSection.allCases.firstIndex(of: self) ?? 0
        let labels: [String]
        switch languageCode {
        case "zh-Hans": labels = ["脉动", "行情", "雷达", "网络"]
        case "zh-Hant": labels = ["脈動", "行情", "雷達", "網路"]
        case "es": labels = ["Pulso", "Mercados", "Radar", "Red"]
        case "fr": labels = ["Pouls", "Marchés", "Radar", "Réseau"]
        case "de": labels = ["Puls", "Märkte", "Radar", "Netzwerk"]
        case "ja": labels = ["動向", "市場", "レーダー", "ネットワーク"]
        case "ko": labels = ["동향", "시장", "레이더", "네트워크"]
        case "pt-BR": labels = ["Pulso", "Mercados", "Radar", "Rede"]
        case "id": labels = ["Denyut", "Pasar", "Radar", "Jaringan"]
        case "hi": labels = ["पल्स", "बाज़ार", "रडार", "नेटवर्क"]
        case "ar": labels = ["نبض", "الأسواق", "الرادار", "الشبكة"]
        default: labels = AquaSection.allCases.map(\.rawValue)
        }
        return labels[index]
    }
}

struct AquaShellView: View {
    @State private var selection: AquaSection = .pulse
    @State private var showsSettings = false
    @AppStorage("maritimeRiskNoticeAcceptedVersion") private var acceptedRiskVersion = ""
    @AppStorage("appLanguage") private var appLanguage = AquaAppLanguage.english.rawValue

    private var requiresRiskAcceptance: Bool {
        acceptedRiskVersion != maritimeRiskNoticeVersion
    }

    var body: some View {
        ZStack {
            appShell
                .disabled(requiresRiskAcceptance)
                .accessibilityHidden(requiresRiskAcceptance)

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
