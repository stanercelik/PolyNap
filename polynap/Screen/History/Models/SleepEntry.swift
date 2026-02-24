import SwiftData
import Foundation

// Eğer global olarak tanımlanmadıysa SleepType enum'ı
enum SleepTypeEnum: String, Codable, CaseIterable {
    case core = "Core"
    case powerNap = "Power Nap"
    // Gerekirse diğer türler eklenebilir
}

// Sleep adjustment types
enum SleepAdjustmentType: String, Codable, CaseIterable {
    case asScheduled = "as_scheduled"
    case differentTime = "different_time"
    case custom = "custom"
    case skipped = "skipped"
}

@Model
final class SleepEntry {
    @Attribute(.unique) var id: UUID = UUID()
    var user: User? // User ile ilişki (Supabase: user_id)
    
    var date: Date = Date() // Genellikle uyku bloğunun başladığı gün/tarih
    
    var blockId: String? // Hangi schedule block'una ait olduğu (opsiyonel)
    var emoji: String?
    var rating: Double = 0.0 // 1-5 arası (0.5 increment'li buçuklu puanlar)
    var source: String = "manual" // "manual" veya "health" - veri kaynağını belirtir
    
    // Sleep adjustment metadata
    var adjustmentType: String? // Adjustment type as string for SwiftData compatibility
    var adjustmentMinutes: Int? // For different_time adjustments (+5, -15, etc.)
    var originalScheduledStartTime: Date? // Original scheduled start time
    var originalScheduledEndTime: Date? // Original scheduled end time

    // Supabase'deki user_sleep_blocks tablosundan gelen alanlar:
    var startTime: Date = Date() // Bloğun kesin başlangıç zamanı (saat ve dakika dahil)
    var endTime: Date = Date()   // Bloğun kesin bitiş zamanı
    var durationMinutes: Int = 0 // Dakika cinsinden süre
    var isCore: Bool = false    // Ana uyku mu, şekerleme mi?

    var type: SleepType { // isCore'a göre hesaplanır
        isCore ? .core : .powerNap
    }
    
    var adjustmentInfo: SleepAdjustmentType? {
        guard let adjustmentType = adjustmentType else { return nil }
        return SleepAdjustmentType(rawValue: adjustmentType)
    }
    
    var duration: TimeInterval { // Saniye cinsinden süre (hesaplanmış)
        Double(durationMinutes * 60)
    }

    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var syncId: String?

    // HistoryModel ile ters ilişki (bir uyku kaydı bir günlük geçmişe ait olabilir)
    var historyDay: HistoryModel?

    init(id: UUID = UUID(),
         user: User? = nil,
         date: Date, // Bloğun ait olduğu gün
         startTime: Date,
         endTime: Date,
         durationMinutes: Int,
         isCore: Bool,
         blockId: String? = nil,
         emoji: String? = nil,
         rating: Double = 0.0,
         source: String = "manual",
         adjustmentType: String? = nil,
         adjustmentMinutes: Int? = nil,
         originalScheduledStartTime: Date? = nil,
         originalScheduledEndTime: Date? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         syncId: String? = UUID().uuidString,
         historyDay: HistoryModel? = nil) {
        self.id = id
        self.user = user
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.isCore = isCore
        self.blockId = blockId
        self.emoji = emoji
        self.rating = rating
        self.source = source
        self.adjustmentType = adjustmentType
        self.adjustmentMinutes = adjustmentMinutes
        self.originalScheduledStartTime = originalScheduledStartTime
        self.originalScheduledEndTime = originalScheduledEndTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncId = syncId
        self.historyDay = historyDay
    }
} 
