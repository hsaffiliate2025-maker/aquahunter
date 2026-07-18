import SwiftUI

enum AquaTheme {
    static let deepOcean = Color(red: 4 / 255, green: 26 / 255, blue: 56 / 255)
    static let surface = Color(red: 8 / 255, green: 37 / 255, blue: 74 / 255)
    static let surfaceHigh = Color(red: 13 / 255, green: 50 / 255, blue: 96 / 255)
    static let signalBlue = Color(red: 22 / 255, green: 141 / 255, blue: 1)
    static let radarCyan = Color(red: 32 / 255, green: 200 / 255, blue: 1)
    static let positive = Color(red: 49 / 255, green: 209 / 255, blue: 124 / 255)
    static let negative = Color(red: 1, green: 116 / 255, blue: 108 / 255)
    static let textPrimary = Color(red: 243 / 255, green: 249 / 255, blue: 1)
    static let textSecondary = Color(red: 167 / 255, green: 190 / 255, blue: 216 / 255)
    static let divider = Color(red: 27 / 255, green: 79 / 255, blue: 122 / 255)
}

enum AquaBackgroundStyle: String, CaseIterable, Identifiable {
    case ocean
    case midnight
    case teal
    case black

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ocean: "Ocean Blue"
        case .midnight: "Midnight Navy"
        case .teal: "Deep Teal"
        case .black: "True Black"
        }
    }

    var colors: [Color] {
        switch self {
        case .ocean:
            [AquaTheme.deepOcean, Color(red: 3 / 255, green: 20 / 255, blue: 43 / 255)]
        case .midnight:
            [Color(red: 13 / 255, green: 18 / 255, blue: 43 / 255), Color(red: 5 / 255, green: 8 / 255, blue: 24 / 255)]
        case .teal:
            [Color(red: 2 / 255, green: 40 / 255, blue: 48 / 255), Color(red: 1 / 255, green: 20 / 255, blue: 29 / 255)]
        case .black:
            [.black, Color(red: 4 / 255, green: 8 / 255, blue: 13 / 255)]
        }
    }
}

struct AquaCard<Content: View>: View {
    private let emphasized: Bool
    private let content: Content

    init(emphasized: Bool = false, @ViewBuilder content: () -> Content) {
        self.emphasized = emphasized
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(emphasized ? AquaTheme.surfaceHigh : AquaTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(emphasized ? AquaTheme.signalBlue.opacity(0.42) : AquaTheme.divider.opacity(0.74), lineWidth: 1)
            }
    }
}

struct AquaBrandMark: View {
    var size: CGFloat = 40

    var body: some View {
        Canvas { context, canvas in
            let center = CGPoint(x: canvas.width / 2, y: canvas.height / 2)
            let outer = canvas.width * 0.42
            let inner = canvas.width * 0.25

            context.fill(Path(ellipseIn: CGRect(x: 0, y: 0, width: canvas.width, height: canvas.height)), with: .color(AquaTheme.signalBlue.opacity(0.12)))
            context.stroke(Path(ellipseIn: CGRect(x: center.x - outer, y: center.y - outer, width: outer * 2, height: outer * 2)), with: .color(AquaTheme.signalBlue), lineWidth: 2)
            context.stroke(Path(ellipseIn: CGRect(x: center.x - inner, y: center.y - inner, width: inner * 2, height: inner * 2)), with: .color(AquaTheme.radarCyan.opacity(0.8)), lineWidth: 1.2)

            var sweep = Path()
            sweep.move(to: center)
            sweep.addLine(to: CGPoint(x: canvas.width * 0.24, y: canvas.height * 0.23))
            context.stroke(sweep, with: .color(AquaTheme.radarCyan.opacity(0.8)), lineWidth: 1.8)

            let ticks = [
                (CGPoint(x: center.x, y: canvas.height * 0.04), CGPoint(x: center.x, y: canvas.height * 0.20)),
                (CGPoint(x: center.x, y: canvas.height * 0.80), CGPoint(x: center.x, y: canvas.height * 0.96)),
                (CGPoint(x: canvas.width * 0.04, y: center.y), CGPoint(x: canvas.width * 0.20, y: center.y)),
                (CGPoint(x: canvas.width * 0.80, y: center.y), CGPoint(x: canvas.width * 0.96, y: center.y)),
            ]
            for tick in ticks {
                var path = Path()
                path.move(to: tick.0)
                path.addLine(to: tick.1)
                context.stroke(path, with: .color(AquaTheme.signalBlue), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }

            var trend = Path()
            trend.move(to: CGPoint(x: canvas.width * 0.13, y: canvas.height * 0.72))
            trend.addLine(to: CGPoint(x: canvas.width * 0.34, y: canvas.height * 0.55))
            trend.addLine(to: CGPoint(x: canvas.width * 0.49, y: canvas.height * 0.64))
            trend.addLine(to: CGPoint(x: canvas.width * 0.76, y: canvas.height * 0.34))
            trend.addLine(to: CGPoint(x: canvas.width * 0.86, y: canvas.height * 0.39))
            context.stroke(trend, with: .color(AquaTheme.positive), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))

            for point in [CGPoint(x: 0.61, y: 0.67), CGPoint(x: 0.72, y: 0.76), CGPoint(x: 0.56, y: 0.80)] {
                let fishCenter = CGPoint(x: canvas.width * point.x, y: canvas.height * point.y)
                let body = CGRect(x: fishCenter.x - canvas.width * 0.055, y: fishCenter.y - canvas.height * 0.025, width: canvas.width * 0.11, height: canvas.height * 0.05)
                context.fill(Path(ellipseIn: body), with: .color(AquaTheme.textPrimary))
                var tail = Path()
                tail.move(to: CGPoint(x: fishCenter.x - canvas.width * 0.045, y: fishCenter.y))
                tail.addLine(to: CGPoint(x: fishCenter.x - canvas.width * 0.085, y: fishCenter.y - canvas.height * 0.035))
                tail.addLine(to: CGPoint(x: fishCenter.x - canvas.width * 0.085, y: fishCenter.y + canvas.height * 0.035))
                tail.closeSubpath()
                context.fill(tail, with: .color(AquaTheme.textPrimary))
            }

            context.fill(Path(ellipseIn: CGRect(x: center.x - 2.5, y: center.y - 2.5, width: 5, height: 5)), with: .color(AquaTheme.signalBlue))
        }
        .frame(width: size, height: size)
        .accessibilityLabel("AquaHunter")
    }
}

#if AQUAHUNTER_INTERNAL_FIXTURES
struct DemoBadge: View {
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(.yellow).frame(width: 5, height: 5)
            Text("DEMO")
        }
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(.yellow)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.yellow.opacity(0.10))
            .clipShape(Capsule())
            .overlay { Capsule().stroke(.yellow.opacity(0.28), lineWidth: 1) }
    }
}
#endif

struct SectionTitle: View {
    let eyebrow: String
    let title: String
    let subtitle: String?

    init(_ title: String, eyebrow: String, subtitle: String? = nil) {
        self.title = title
        self.eyebrow = eyebrow
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1.4)
                .foregroundStyle(AquaTheme.signalBlue)
            Text(title)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(AquaTheme.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AquaTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MetricTile: View {
    let label: String
    let value: String
    let detail: String
    let accent: Color

    var body: some View {
        AquaCard {
            HStack(spacing: 7) {
                Circle().fill(accent).frame(width: 7, height: 7)
                Text(label.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(0.7)
                    .foregroundStyle(AquaTheme.textSecondary)
            }
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(AquaTheme.textPrimary)
                .padding(.top, 6)
            Text(detail)
                .font(.caption.weight(.medium))
                .foregroundStyle(accent)
        }
    }
}

extension View {
    func aquaPageBackground() -> some View {
        modifier(AquaPageBackgroundModifier())
    }
}

private struct AquaPageBackgroundModifier: ViewModifier {
    @AppStorage("appBackgroundStyle") private var rawStyle = AquaBackgroundStyle.ocean.rawValue

    private var style: AquaBackgroundStyle {
        AquaBackgroundStyle(rawValue: rawStyle) ?? .ocean
    }

    func body(content: Content) -> some View {
        content.background(
            LinearGradient(
                colors: style.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}
