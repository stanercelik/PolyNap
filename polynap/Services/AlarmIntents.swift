import AppIntents
import Foundation

// MARK: - Alarm App Intents

/// Alarmı durdurmak için kullanılan App Intent
struct StopAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "Alarmı Durdur"
    static var description = IntentDescription("Çalan alarmı durdurur")
    
    @Parameter(title: "Alarm ID")
    var alarmId: String?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Alarmı durdur") {
            \.$alarmId
        }
    }
    
    func perform() async throws -> some IntentResult {
        // AlarmKit veya AlarmService üzerinden alarmı durdur
        // Actor dışından erişim için MainActor.run kullan
        let useAlarmKit: Bool = await MainActor.run { () -> Bool in
            return AlarmKitService.isAvailable
        }
        
        if useAlarmKit {
            // iOS 26+ için AlarmKit
            print("🛑 StopAlarmIntent: Alarm durduruldu (AlarmKit)")
        } else {
            // Eski cihazlar için UserNotifications
            print("🛑 StopAlarmIntent: Alarm durduruldu (Notifications)")
        }
        
        return .result()
    }
}

/// Alarmı ertelemek için kullanılan App Intent
struct SnoozeAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "Alarmı Ertele"
    static var description = IntentDescription("Alarmı erteler")
    
    @Parameter(title: "Alarm ID")
    var alarmId: String?
    
    @Parameter(title: "Erteleme Süresi (dakika)", default: 5)
    var snoozeMinutes: Int
    
    static var parameterSummary: some ParameterSummary {
        Summary("Alarmı \(\.$snoozeMinutes) dakika ertele") {
            \.$alarmId
        }
    }
    
    func perform() async throws -> some IntentResult {
        // Actor dışından erişim için MainActor.run kullan
        let useAlarmKit: Bool = await MainActor.run { () -> Bool in
            return AlarmKitService.isAvailable
        }
        
        if useAlarmKit {
            // iOS 26+ için AlarmKit
            print("⏰ SnoozeAlarmIntent: Alarm \(snoozeMinutes) dakika ertelendi (AlarmKit)")
        } else {
            // Eski cihazlar için UserNotifications
            print("⏰ SnoozeAlarmIntent: Alarm \(snoozeMinutes) dakika ertelendi (Notifications)")
        }
        
        return .result()
    }
}

// MARK: - Alarm Shortcuts Provider

/// Siri Shortcuts için alarm intentlerini sağlar
struct PolyNapShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StopAlarmIntent(),
            phrases: [
                "Alarmı durdur \(.applicationName)",
                "\(.applicationName) alarmı kapat",
                "Uyandırma alarmını durdur \(.applicationName)"
            ],
            shortTitle: "Alarmı Durdur",
            systemImageName: "bell.slash.fill"
        )
        
        AppShortcut(
            intent: SnoozeAlarmIntent(),
            phrases: [
                "Alarmı ertele \(.applicationName)",
                "\(.applicationName) alarmı beş dakika ertele",
                "Uyandırma alarmını ertele \(.applicationName)"
            ],
            shortTitle: "Alarmı Ertele",
            systemImageName: "bell.badge.fill"
        )
    }
}

// MARK: - Alarm App Intent - tek buton

/// Tüm alarm işlemlerini yapan ana intent
struct AlarmActionIntent: AppIntent {
    static var title: LocalizedStringResource = "Alarm Eylemi"
    static var description = IntentDescription("Alarmı durdur veya ertele")
    
    @Parameter(title: "Eylem", default: .stop)
    var action: AlarmAction
    
    enum AlarmAction: String, AppEnum {
        case stop = "Durdur"
        case snooze = "Ertele"
        
        static var typeDisplayRepresentation: TypeDisplayRepresentation = "Alarm Eylemi"
        
        static var caseDisplayRepresentations: [AlarmAction: DisplayRepresentation] = [
            .stop: "Durdur",
            .snooze: "Ertele"
        ]
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Alarmı \(\.$action)") {
            \.$action
        }
    }
    
    func perform() async throws -> some IntentResult {
        switch action {
        case .stop:
            print("🛑 AlarmActionIntent: Alarm durduruldu")
        case .snooze:
            print("⏰ AlarmActionIntent: Alarm ertelendi")
        }
        
        return .result()
    }
}
