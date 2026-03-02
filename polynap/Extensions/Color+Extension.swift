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

    // Hero & Metric Renkleri
    static let heroTop = Color(hex: "0D1B3E")
    static let heroBottom = Color(hex: "1A3366")
    static let metricAmber = Color(hex: "F59E0B")
    static let metricTeal = Color(hex: "0EA5E9")
    static let metricPurple = Color(hex: "8B5CF6")
    static let metricEmerald = Color(hex: "10B981")
}
