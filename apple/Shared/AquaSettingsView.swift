import SwiftUI

enum AquaAppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case japanese = "ja"
    case korean = "ko"
    case portuguese = "pt-BR"
    case indonesian = "id"
    case hindi = "hi"
    case arabic = "ar"

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .english: "English"
        case .simplifiedChinese: "简体中文"
        case .traditionalChinese: "繁體中文"
        case .spanish: "Español"
        case .french: "Français"
        case .german: "Deutsch"
        case .japanese: "日本語"
        case .korean: "한국어"
        case .portuguese: "Português"
        case .indonesian: "Bahasa Indonesia"
        case .hindi: "हिन्दी"
        case .arabic: "العربية"
        }
    }
}

struct AquaSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage("appBackgroundStyle") private var backgroundStyle = AquaBackgroundStyle.ocean.rawValue
    @AppStorage("appLanguage") private var appLanguage = AquaAppLanguage.english.rawValue
    @State private var showsRiskNotice = false

    private var selectedBackground: Binding<AquaBackgroundStyle> {
        Binding(
            get: { AquaBackgroundStyle(rawValue: backgroundStyle) ?? .ocean },
            set: { backgroundStyle = $0.rawValue }
        )
    }

    private var selectedLanguage: Binding<AquaAppLanguage> {
        Binding(
            get: { AquaAppLanguage(rawValue: appLanguage) ?? .english },
            set: { appLanguage = $0.rawValue }
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                SectionTitle(
                    "Settings",
                    eyebrow: "AquaHunter",
                    subtitle: "Appearance, language, safety notice and support."
                )

                AquaCard {
                    Label("Background color", systemImage: "paintpalette.fill")
                        .font(.headline)
                        .foregroundStyle(AquaTheme.textPrimary)
                    Picker("Background color", selection: selectedBackground) {
                        ForEach(AquaBackgroundStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 6)

                    HStack(spacing: 8) {
                        ForEach(AquaBackgroundStyle.allCases) { style in
                            LinearGradient(colors: style.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                .frame(height: 28)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(backgroundStyle == style.rawValue ? AquaTheme.signalBlue : AquaTheme.divider, lineWidth: backgroundStyle == style.rawValue ? 2 : 1)
                                }
                                .onTapGesture { backgroundStyle = style.rawValue }
                                .accessibilityLabel(style.title)
                        }
                    }
                }

                AquaCard {
                    Label("Interface language", systemImage: "globe")
                        .font(.headline)
                        .foregroundStyle(AquaTheme.textPrimary)
                    Picker("Language", selection: selectedLanguage) {
                        ForEach(AquaAppLanguage.allCases) { language in
                            Text(language.nativeName).tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.top, 6)
                    Text("12 languages, matching the Railingo launch-language set. Language choice is stored on this device.")
                        .font(.caption)
                        .foregroundStyle(AquaTheme.textSecondary)
                }

                AquaCard {
                    Label("Safety & legal", systemImage: "checkmark.shield.fill")
                        .font(.headline)
                        .foregroundStyle(AquaTheme.textPrimary)
                    Text("You can review the notice accepted on first launch at any time.")
                        .font(.caption)
                        .foregroundStyle(AquaTheme.textSecondary)
                    Button {
                        showsRiskNotice = true
                    } label: {
                        HStack {
                            Text("View Maritime Operations & Legal Risk Notice")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AquaTheme.signalBlue)
                        .padding(.top, 8)
                    }
                    .buttonStyle(.plain)
                }

                AquaCard(emphasized: true) {
                    Label("Report a bug", systemImage: "ladybug.fill")
                        .font(.headline)
                        .foregroundStyle(AquaTheme.textPrimary)
                    Text("Create a pre-addressed email with device and app context. Please do not include passwords, payment data or confidential catch coordinates.")
                        .font(.caption)
                        .foregroundStyle(AquaTheme.textSecondary)
                    Button(action: composeBugEmail) {
                        Label("Email contact@hotseason.app", systemImage: "envelope.fill")
                            .font(.subheadline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AquaTheme.deepOcean)
                    .background(AquaTheme.signalBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.top, 6)
                }

                Text("AquaHunter 1.0 · © 2026 Hot Season Enterprise, Inc.")
                    .font(.caption2)
                    .foregroundStyle(AquaTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(18)
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .aquaPageBackground()
        .sheet(isPresented: $showsRiskNotice) {
            NavigationStack {
                ScrollView {
                    MaritimeRiskDisclaimerView()
                        .padding(18)
                }
                .navigationTitle("Risk Notice")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showsRiskNotice = false }
                    }
                }
                .aquaPageBackground()
            }
        }
    }

    private func composeBugEmail() {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "contact@hotseason.app"
        components.queryItems = [
            URLQueryItem(name: "subject", value: "AquaHunter bug report"),
            URLQueryItem(
                name: "body",
                value: "Please describe the problem:\n\nSteps to reproduce:\n1. \n2. \n3. \n\nExpected result:\n\nActual result:\n\nApp: AquaHunter 1.0\nPlatform: Apple\nRisk notice: \(maritimeRiskNoticeVersion)\n"
            ),
        ]
        if let url = components.url {
            openURL(url)
        }
    }
}
