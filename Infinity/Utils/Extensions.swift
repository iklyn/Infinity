import SwiftUI

// MARK: - Theme  (single source of truth for color)

enum Theme {
    static let bg       = Color(hex: "1C1C1E")
    static let bgRaised = Color(hex: "2C2C2E")
    static let divider  = Color.white.opacity(0.08)
    static let danger   = Color(hex: "FF453A")

    /// The one accent — warm gold — used across the whole app.
    static let accent: [Color] = [Color(hex: "F2C879"), Color(hex: "E6A953")]
    static let accentSolid = Color(hex: "E6A953")

    static var accentGradient: LinearGradient {
        LinearGradient(colors: accent, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Color from hex

extension Color {
    init(hex: String) {
        var h = hex.trimmingCharacters(in: .alphanumerics.inverted)
        if h.count == 3 { h = h.map { "\($0)\($0)" }.joined() }
        var value: UInt64 = 0
        Scanner(string: h).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >>  8) & 0xFF) / 255
        let b = Double( value        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - OnePlus Sans font helper

extension Font {
    static func onePlus(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .light:  return .custom("OnePlusSans-Light",   size: size)
        case .medium: return .custom("OnePlusSans-Medium",  size: size)
        default:      return .custom("OnePlusSans-Regular", size: size)
        }
    }

    // Back-compat alias (older call sites use `.onePlus(size:weight:)`)
    static func onePlus(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        onePlus(size, weight)
    }
}
