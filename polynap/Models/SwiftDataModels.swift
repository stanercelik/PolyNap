import Foundation
import SwiftData

// MARK: - User Model
@Model
final class User {
    @Attribute(.unique) var id: UUID = UUID()
    var email: String?
    var displayName: String?
    var avatarUrl: String?
    var isAnonymous: Bool = false
    var preferences: String? // JSONB için String veya Data kullanılabilir, sonra parse edilir
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isPremium: Bool = false

    // İlişkiler
    @Relationship(deleteRule: .cascade, inverse: \UserSchedule.user)
    var schedules: [UserSchedule]? = []

    // OnboardingAnswerData.swift dosyası güncellenerek User ilişkisi eklendi
    @Relationship(deleteRule: .cascade, inverse: \OnboardingAnswerData.user)
    var onboardingAnswers: [OnboardingAnswerData]? = []

    @Relationship(deleteRule: .cascade, inverse: \SleepEntry.user)
    var sleepEntries: [SleepEntry]? = []

    init(id: UUID = UUID(),
         email: String? = nil,
         displayName: String? = nil,
         avatarUrl: String? = nil,
         isAnonymous: Bool = false,
         preferences: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         isPremium: Bool = false) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.isAnonymous = isAnonymous
        self.preferences = preferences
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPremium = isPremium
    }
}

// MARK: - UserSchedule Model
@Model
final class UserSchedule {
    @Attribute(.unique) var id: UUID = UUID()
    var user: User? // İlişki: User'a ait
    var name: String = ""
    var scheduleDescription: String? // JSONB için String veya Data, 'description' Swift'te özel bir anlam taşıdığı için 'scheduleDescription'
    var totalSleepHours: Double? = 0
    var adaptationPhase: Int? = 0
    var adaptationStartDate: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isActive: Bool = false

    // İlişkiler
    @Relationship(deleteRule: .cascade, inverse: \UserSleepBlock.schedule)
    var sleepBlocks: [UserSleepBlock]? = []

    init(id: UUID = UUID(),
         user: User? = nil,
         name: String,
         scheduleDescription: String? = nil, // JSON string
         totalSleepHours: Double? = nil,
         adaptationPhase: Int? = nil,
         adaptationStartDate: Date? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         isActive: Bool = false) {
        self.id = id
        self.user = user
        self.name = name
        self.scheduleDescription = scheduleDescription
        self.totalSleepHours = totalSleepHours
        self.adaptationPhase = adaptationPhase
        self.adaptationStartDate = adaptationStartDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isActive = isActive
    }
}

// MARK: - UserSleepBlock Model
@Model
final class UserSleepBlock {
    @Attribute(.unique) var id: UUID = UUID()
    var schedule: UserSchedule? // İlişki: UserSchedule'a ait
    var startTime: Date = Date() // TIME tipi için Date kullanılabilir, sadece saat/dakika kısmı relevant olacak
    var endTime: Date = Date()   // TIME tipi için Date kullanılabilir, sadece saat/dakika kısmı relevant olacak
    var durationMinutes: Int = 0
    var isCore: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var syncId: String?

    init(id: UUID = UUID(),
         schedule: UserSchedule? = nil,
         startTime: Date,
         endTime: Date,
         durationMinutes: Int,
         isCore: Bool = false,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         syncId: String? = nil) {
        self.id = id
        self.schedule = schedule
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.isCore = isCore
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncId = syncId
    }
}

// MARK: - ScheduleEntity Model
@Model
final class ScheduleEntity {
    @Attribute(.unique) var id: UUID = UUID()
    var userId: UUID = UUID()
    var name: String = ""
    var descriptionJson: String = "{}" // JSON formatında lokalize açıklamalar
    var totalSleepHours: Double = 0.0
    var isActive: Bool = false
    var isDeleted: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var syncId: String? = UUID().uuidString

    @Relationship(deleteRule: .cascade, inverse: \SleepBlockEntity.schedule)
    var sleepBlocks: [SleepBlockEntity] = []

    init(id: UUID = UUID(),
         userId: UUID,
         name: String = "",
         descriptionJson: String = "{}",
         totalSleepHours: Double = 0.0,
         isActive: Bool = false,
         isDeleted: Bool = false,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         syncId: String? = UUID().uuidString) {
        self.id = id
        self.userId = userId
        self.name = name
        self.descriptionJson = descriptionJson
        self.totalSleepHours = totalSleepHours
        self.isActive = isActive
        self.isDeleted = isDeleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncId = syncId
    }
}

// MARK: - SleepBlockEntity Model
@Model
final class SleepBlockEntity {
    @Attribute(.unique) var id: UUID = UUID()
    var schedule: ScheduleEntity?
    var startTime: String = "00:00" // Saat formatı: "23:00"
    var endTime: String = "00:00"   // Saat formatı: "01:00"
    var durationMinutes: Int = 0
    var isCore: Bool = false
    var isDeleted: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var syncId: String? = UUID().uuidString

    init(id: UUID = UUID(),
         schedule: ScheduleEntity? = nil,
         startTime: String,
         endTime: String,
         durationMinutes: Int,
         isCore: Bool = false,
         isDeleted: Bool = false,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         syncId: String? = UUID().uuidString) {
        self.id = id
        self.schedule = schedule
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.isCore = isCore
        self.isDeleted = isDeleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncId = syncId
    }
}

// MARK: - SleepEntryEntity Model
@Model
final class SleepEntryEntity {
    @Attribute(.unique) var id: UUID = UUID()
    var userId: UUID = UUID()
    var date: Date = Date()
    var blockId: String?
    var emoji: String?
    var rating: Double = 0.0
    var isDeleted: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var syncId: String? = UUID().uuidString

    init(id: UUID = UUID(),
         userId: UUID,
         date: Date = Date(),
         blockId: String? = nil,
         emoji: String? = nil,
         rating: Double = 0.0,
         isDeleted: Bool = false,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         syncId: String? = UUID().uuidString) {
        self.id = id
        self.userId = userId
        self.date = date
        self.blockId = blockId
        self.emoji = emoji
        self.rating = rating
        self.isDeleted = isDeleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncId = syncId
    }
}

// MARK: - PendingChange Model
@Model
final class PendingChange {
    @Attribute(.unique) var id: UUID = UUID()
    var entityName: String = ""
    var entityId: String = ""
    var operationType: String = "create" // "create", "update", "delete"
    var payload: String? // JSON formatında veri
    var createdAt: Date = Date()
    var attempts: Int = 0
    var lastAttemptAt: Date?
    var errorInfo: String?

    init(id: UUID = UUID(),
         entityName: String,
         entityId: String,
         operationType: String,
         payload: String? = nil,
         createdAt: Date = Date(),
         attempts: Int = 0,
         lastAttemptAt: Date? = nil,
         errorInfo: String? = nil) {
        self.id = id
        self.entityName = entityName
        self.entityId = entityId
        self.operationType = operationType
        self.payload = payload
        self.createdAt = createdAt
        self.attempts = attempts
        self.lastAttemptAt = lastAttemptAt
        self.errorInfo = errorInfo
    }
}

// MARK: - AlarmSettings Model
@Model
final class AlarmSettings {
    @Attribute(.unique) var id: UUID = UUID()
    var userId: UUID = UUID()
    var isEnabled: Bool = true
    var soundName: String = "Alarm 1.caf"
    var volume: Double = 0.8 // 0.0 - 1.0
    var vibrationEnabled: Bool = true
    var snoozeEnabled: Bool = true
    var snoozeDurationMinutes: Int = 5
    var maxSnoozeCount: Int = 3
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(id: UUID = UUID(),
         userId: UUID,
         isEnabled: Bool = true,
         soundName: String = "Alarm 1.caf",
         volume: Double = 0.8,
         vibrationEnabled: Bool = true,
         snoozeEnabled: Bool = true,
         snoozeDurationMinutes: Int = 5,
         maxSnoozeCount: Int = 3,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.isEnabled = isEnabled
        self.soundName = soundName
        self.volume = volume
        self.vibrationEnabled = vibrationEnabled
        self.snoozeEnabled = snoozeEnabled
        self.snoozeDurationMinutes = snoozeDurationMinutes
        self.maxSnoozeCount = maxSnoozeCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - AlarmNotification Model
@Model
final class AlarmNotification {
    @Attribute(.unique) var id: UUID = UUID()
    var userId: UUID = UUID()
    var scheduleId: UUID = UUID()
    var blockId: UUID = UUID()
    var notificationIdentifier: String = ""
    var scheduledTime: Date = Date()
    var isActive: Bool = true
    var createdAt: Date = Date()
    var firedAt: Date?
    var snoozedCount: Int = 0
    
    init(id: UUID = UUID(),
         userId: UUID,
         scheduleId: UUID,
         blockId: UUID,
         notificationIdentifier: String,
         scheduledTime: Date,
         isActive: Bool = true,
         createdAt: Date = Date(),
         firedAt: Date? = nil,
         snoozedCount: Int = 0) {
        self.id = id
        self.userId = userId
        self.scheduleId = scheduleId
        self.blockId = blockId
        self.notificationIdentifier = notificationIdentifier
        self.scheduledTime = scheduledTime
        self.isActive = isActive
        self.createdAt = createdAt
        self.firedAt = firedAt
        self.snoozedCount = snoozedCount
    }
}

// MARK: - HealthKit Rating Model
@Model
final class HealthKitSleepRating {
    @Attribute(.unique) var id: UUID = UUID()
    var healthKitIdentifier: String = "" // HealthKit sample'ın unique identifier'ı
    var startDate: Date = Date() // HealthKit sample'ın start date'i (ek identifier olarak)
    var endDate: Date = Date() // HealthKit sample'ın end date'i (ek identifier olarak) 
    var rating: Double = 0.0 // Kullanıcının verdiği puan (1-5)
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(id: UUID = UUID(),
         healthKitIdentifier: String,
         startDate: Date,
         endDate: Date,
         rating: Double,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.healthKitIdentifier = healthKitIdentifier
        self.startDate = startDate
        self.endDate = endDate
        self.rating = rating
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
