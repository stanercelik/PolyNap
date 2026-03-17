import SwiftUI
import Charts
import Foundation

// MARK: - Chart Utilities

// MARK: - Chart Formatting Helpers
struct ChartFormatUtils {
    
    // MARK: - X-Axis Formatting
    static func getXAxisStride(for timeRange: TimeRange) -> Int {
        switch timeRange {
        case .Week: return 1        // Her gün
        case .Month: return 5       // 5 günde bir
        case .Quarter: return 14    // 2 haftada bir
        case .Year: return 60       // 2 ayda bir
        }
    }
    
    static func getDateFormat(for timeRange: TimeRange) -> Date.FormatStyle {
        switch timeRange {
        case .Week, .Month: 
            return .dateTime.day().month(.abbreviated)
        case .Quarter: 
            return .dateTime.day().month(.abbreviated)
        case .Year: 
            return .dateTime.month(.abbreviated).year(.twoDigits)
        }
    }
    
    // MARK: - Components Chart Specific Formatting
    static func getXAxisStrideForComponents(for timeRange: TimeRange) -> Int {
        switch timeRange {
        case .Week: return 1        // Her gün
        case .Month: return 4       // 4 günde bir
        case .Quarter: return 14    // 2 haftada bir
        case .Year: return 60       // 2 ayda bir
        }
    }
    
    static func getDateFormatForComponents(for timeRange: TimeRange) -> Date.FormatStyle {
        switch timeRange {
        case .Week: 
            return .dateTime.weekday(.narrow)
        case .Month: 
            return .dateTime.day().month(.abbreviated)
        case .Quarter: 
            return .dateTime.day().month(.abbreviated)
        case .Year: 
            return .dateTime.month(.abbreviated)
        }
    }
    
    // MARK: - Consistency Chart Formatting
    static func getConsistencyXAxisStride(for timeRange: TimeRange) -> Int {
        switch timeRange {
        case .Week: return 1        // Her gün
        case .Month: return 5       // 5 günde bir
        case .Quarter: return 14    // 2 haftada bir
        case .Year: return 60       // 2 ayda bir
        }
    }
    
    static func getConsistencyDateFormat(for timeRange: TimeRange) -> Date.FormatStyle {
        switch timeRange {
        case .Week, .Month: 
            return .dateTime.day().month(.abbreviated)
        case .Quarter: 
            return .dateTime.day().month(.abbreviated)
        case .Year: 
            return .dateTime.month(.abbreviated).year(.twoDigits)
        }
    }
    
    // MARK: - Quality Chart Formatting
    static func getQualityXAxisStride(for timeRange: TimeRange) -> Int {
        switch timeRange {
        case .Week: return 1        // Her gün
        case .Month: return 5       // 5 günde bir
        case .Quarter: return 14    // 2 haftada bir
        case .Year: return 60       // 2 ayda bir
        }
    }
    
    static func getQualityDateFormat(for timeRange: TimeRange) -> Date.FormatStyle {
        switch timeRange {
        case .Week, .Month: 
            return .dateTime.day().month(.abbreviated)
        case .Quarter: 
            return .dateTime.day().month(.abbreviated)
        case .Year: 
            return .dateTime.month(.abbreviated).year(.twoDigits)
        }
    }
}

// MARK: - Chart Color Utilities
struct ChartColorUtils {
    
    static func scoreColor(for score: Double) -> Color {
        let category = SleepQualityCategory.fromRating(score)
        return category.color
    }
    
    static func getSleepStateColor(for day: SleepTrendData, hour: Int) -> Color {
        // ⚠️ DİKKAT: Bu algoritma varsayımsal veriler kullanıyor
        // Gerçek uyku saatleri SleepEntry'lerden alınmalı
        
        // Temel uyku dönemlerini tahmin et
        let nightSleepStart = 22 // Gece uykusu başlangıcı
        let nightSleepEnd = 8    // Gece uykusu bitişi
        let afternoonNap = 13    // Öğle şekerlemesi
        let eveningNap = 17      // Akşam şekerlemesi
        
        // Veri varsa renklendir, yoksa açık gri
        if day.totalHours == 0 {
            return .appBackground.opacity(0.1) // Veri yok
        }
        
        // Gece uykusu saatleri (ana uyku)
        if (hour >= nightSleepStart || hour <= nightSleepEnd) && day.coreHours > 0 {
            let intensity = min(1.0, day.coreHours / 8.0) // 8 saate kadar yoğunluk
            return Color.appPrimary.opacity(0.3 + intensity * 0.5)
        }
        
        // Şekerleme saatleri
        if (hour == afternoonNap || hour == eveningNap) && day.napHours > 0 {
            let intensity = min(1.0, day.napHours / 2.0) // 2 saate kadar yoğunluk
            return Color.appSecondary.opacity(0.3 + intensity * 0.4)
        }
        
        // Uyanık zamanlar
        return .appBackground.opacity(0.15)
    }
    
    static func getPreviewSleepColor(day: Int, hour: Int) -> Color {
        if (hour >= 23 || hour <= 7) {
            return Color.appPrimary.opacity(0.8)
        } else if hour == 13 || hour == 17 {
            return Color.appSecondary.opacity(0.6)
        }
        return Color.appBackground.opacity(0.2)
    }
}

// MARK: - Chart Data Utilities
struct ChartDataUtils {
    
    static func getDisplayData(from sleepTrendData: [SleepTrendData], for timeRange: TimeRange) -> [SleepTrendData] {
        switch timeRange {
        case .Week:
            // Son 7 gün
            return Array(sleepTrendData.suffix(7))
        case .Month:
            // Son 30 gün (tüm verileri göster ama daha sık stride kullan)
            return sleepTrendData
        case .Quarter:
            // Son 90 gün
            return sleepTrendData
        case .Year:
            // Tüm veriler
            return sleepTrendData
        }
    }
    
    static func findSelectedItem(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy, in sleepBreakdownData: [SleepBreakdownData]) -> SleepBreakdownData? {
        guard let plotFrameAnchor = proxy.plotFrame else {
            return nil
        }

        let plotFrame = geometry[plotFrameAnchor]
        let center = CGPoint(x: plotFrame.midX, y: plotFrame.midY)
        
        let dx = location.x - center.x
        let dy = location.y - center.y
        
        var angle = atan2(dy, dx)
        if angle < 0 { angle += 2 * .pi }
        
        let anglePercentage = angle / (2 * .pi)
        
        var cumulativePercentage: Double = 0
        for item in sleepBreakdownData {
            let itemPercentage = item.percentage / 100.0
            if anglePercentage <= cumulativePercentage + itemPercentage {
                return item
            }
            cumulativePercentage += itemPercentage
        }
        
        return sleepBreakdownData.last
    }
} 
