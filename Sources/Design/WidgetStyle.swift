import SwiftUI

enum WidgetStyle {
    static let blue = Color(red: 0.12, green: 0.48, blue: 1)
    static let secondary = Color.white.opacity(0.53)
    static let background = LinearGradient(
        colors: [Color(red: 0.16, green: 0.19, blue: 0.23), Color(red: 0.085, green: 0.105, blue: 0.135)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static func eventColor(_ identifier: String) -> Color {
        switch identifier {
        case "2", "10": .green
        case "3": .purple
        case "4", "11": .red
        case "5": .yellow
        case "6": .orange
        case "7": .cyan
        case "8": .gray
        default: blue
        }
    }
}

enum WidgetSize: CaseIterable, Identifiable {
    case small, medium, large, wide

    var id: Self { self }
    var dimensions: CGSize {
        switch self {
        case .small: CGSize(width: 170, height: 170)
        case .medium: CGSize(width: 360, height: 170)
        case .large: CGSize(width: 360, height: 360)
        case .wide: CGSize(width: 720, height: 360)
        }
    }
    var title: String {
        switch self {
        case .small: "Petit carré"
        case .medium: "Rectangle moyen"
        case .large: "Grand carré"
        case .wide: "Grand rectangle"
        }
    }
    var compact: Bool { self == .small || self == .medium }
}

struct CalendarMark: View {
    var size: CGFloat = 22

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.13).fill(.white)
            VStack(spacing: 0) {
                Rectangle().fill(Color.blue).frame(height: size * 0.24)
                Spacer(minLength: 0)
                HStack(spacing: 0) {
                    Rectangle().fill(.green)
                    Rectangle().fill(.yellow)
                }.frame(height: size * 0.23)
            }
            HStack(spacing: 0) {
                Rectangle().fill(.blue).frame(width: size * 0.15)
                Spacer(minLength: 0)
                Rectangle().fill(.yellow).frame(width: size * 0.15)
            }
            Text("31").font(.system(size: size * 0.48, weight: .semibold)).foregroundStyle(.blue)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.13))
        .accessibilityHidden(true)
    }
}

struct WidgetNotice: View {
    var message: String?
    var updatedAt: Date?

    var body: some View {
        if let message {
            Label(message, systemImage: "exclamationmark.circle")
                .font(.system(size: 10)).foregroundStyle(.orange).lineLimit(2)
        } else if let updatedAt, updatedAt.timeIntervalSinceNow < -3600 {
            Text("Mis à jour \(updatedAt, style: .relative)")
                .font(.system(size: 10)).foregroundStyle(WidgetStyle.secondary)
        }
    }
}
