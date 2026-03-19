import SwiftUI

// MARK: - Onboarding Color Palette
enum OBColors {
    static let darkNavy = Color(hex: "0D1B3E")
    static let accentBlue = Color(hex: "4A90D9")
    static let softGray = Color.appBackground
    static let cardGray = Color(hex: "EBEBEB")
    
    static let textPrimary = Color(hex: "1A1A1A")
    static let textSecondary = Color(hex: "6B7280")
    static let textMuted = Color(hex: "9CA3AF")
    
    static let starGold = Color.metricAmber
    static let successGreen = Color.metricEmerald
    static let warningRed = Color.appError
    
    static let primaryColor = Color.appGraphNap
}

// MARK: - Onboarding Typography (SF Pro Rounded, lowercase)
enum OBFont {
    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded).weight(weight)
    }
    
    static var heroTitle: Font { .system(size: 34, weight: .bold, design: .rounded) }
    static var largeTitle: Font { .system(size: 30, weight: .bold, design: .rounded) }
    static var title: Font { .system(size: 26, weight: .bold, design: .rounded) }
    static var subtitle: Font { .system(size: 22, weight: .semibold, design: .rounded) }
    static var body: Font { .system(size: 17, weight: .regular, design: .rounded) }
    static var bodyBold: Font { .system(size: 17, weight: .semibold, design: .rounded) }
    static var caption: Font { .system(size: 14, weight: .regular, design: .rounded) }
    static var captionBold: Font { .system(size: 14, weight: .semibold, design: .rounded) }
    static var small: Font { .system(size: 12, weight: .regular, design: .rounded) }
    static var button: Font { .system(size: 17, weight: .semibold, design: .rounded) }
    static var bigNumber: Font { .system(size: 36, weight: .bold, design: .rounded) }
}

// MARK: - Onboarding Spacing
enum OBSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
