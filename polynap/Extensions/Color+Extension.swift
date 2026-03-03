import SwiftUI

extension Color {
    // Temel Eylemler
    static let appPrimary = Color("PrimaryColor")
    static let appPrimaryVariant = Color("PrimaryVariantColor")
    static let appSecondary = Color("SecondaryColor")
    static let appSecondaryVariant = Color("SecondaryVariantColor")

    // Arka Planlar ve Yüzeyler
    static let appBackground = Color("BackgroundColor")
    static let appCardBackground = Color("CardBackground")
    static let appElevatedSurface = Color("ElevatedSurfaceColor")
    static let appSecondaryBackground = Color("ElevatedSurfaceColor") // Secondary background for buttons
    static let appBorder = Color("BorderColor")
    static let appOverlay = Color("OverlayColor")

    // Metin Renkleri
    static let appTextOnPrimary = Color("TextOnPrimaryColor")
    static let appText = Color("TextColor")
    static let appTextSecondary = Color("SecondaryTextColor")
    static let appSecondaryText = Color("SecondaryTextColor") // Alias for consistency
    static let appTextTertiary = Color("TextTertiaryColor")

    // Durum Renkleri
    static let appSuccess = Color("SuccessColor")
    static let appWarning = Color("WarningColor")
    static let appError = Color("ErrorColor")
    static let appInfo = Color("InfoColor")

    // Grafik Renkleri
    static let appGraphSleepMain = Color("GraphSleepMainColor")
    static let appGraphNap = Color("GraphNapColor")
    static let appGraphGoalLine = Color("GraphGoalLineColor")

    // Diğer Renkler
    static let appDisabled = Color("DisabledColor")
    static let appAccent = Color("AccentColor") // Önceden AccentColor.colorset olarak adlandırılmıştı

    // Hero & Metric Renkleri (adaptive dark navy gradient)
    static let heroTop = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0x0D/255, green: 0x1B/255, blue: 0x3E/255, alpha: 1)
            : UIColor(red: 0x1A/255, green: 0x33/255, blue: 0x66/255, alpha: 1)
    })
    static let heroBottom = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0x1A/255, green: 0x33/255, blue: 0x66/255, alpha: 1)
            : UIColor(red: 0x28/255, green: 0x51/255, blue: 0xA3/255, alpha: 1)
    })
    static let metricAmber = Color(hex: "F59E0B")
    static let metricTeal = Color(hex: "0EA5E9")
    static let metricPurple = Color(hex: "8B5CF6")
    static let metricEmerald = Color(hex: "10B981")
}
