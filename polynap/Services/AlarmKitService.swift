#if canImport(AlarmKit)
import AlarmKit
import ActivityKit
import SwiftUI
#endif
import Foundation
import SwiftData
import UIKit

// MARK: - AlarmKit Metadata

#if canImport(AlarmKit)
@available(iOS 26.0, *)
struct PolyNapAlarmMetadata: AlarmMetadata {
    var scheduleId: String?
    var blockId: String?
    var soundName: String?
    var isTestAlarm: Bool
    
    init(
        scheduleId: String? = nil,
        blockId: String? = nil,
        soundName: String? = nil,
        isTestAlarm: Bool = false
    ) {
        self.scheduleId = scheduleId
        self.blockId = blockId
        self.soundName = soundName
        self.isTestAlarm = isTestAlarm
    }
}
#endif

// MARK: - AlarmKit Service

/// iOS 26+ AlarmKit API'sini kullanarak alarm yönetimi sağlayan servis.
/// Daha eski iOS sürümleri için bu servis pasif kalır.
@MainActor
final class AlarmKitService: ObservableObject {
    static let shared = AlarmKitService()
    
    /// AlarmKit'in kullanılabilir olup olmadığını kontrol eder (iOS 26.0+)
    static var isAvailable: Bool {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            return true
        }
        #endif
        return false
    }
    
    enum AuthorizationState {
        case notDetermined
        case authorized
        case denied
        case unsupported
    }
    
    private init() {}
    
    // MARK: - Yetkilendirme
    
    /// Kullanıcıdan alarm izni ister.
    func requestAuthorization() async -> AuthorizationState {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return .unsupported }
        
        do {
            let state = try await AlarmKit.AlarmManager.shared.requestAuthorization()
            switch state {
            case .authorized:
                print("✅ AlarmKitService: Alarm izni verildi.")
                return .authorized
            case .denied:
                print("⚠️ AlarmKitService: Alarm izni reddedildi.")
                return .denied
            case .notDetermined:
                return .notDetermined
            @unknown default:
                return .denied
            }
        } catch {
            print("🚨 AlarmKitService: İzin istenirken hata: \(error.localizedDescription)")
            return .denied
        }
        #else
        return .unsupported
        #endif
    }
    
    /// Mevcut izin durumunu kontrol eder.
    func checkAuthorizationStatus() async -> AuthorizationState {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return .unsupported }
        
        let state = AlarmKit.AlarmManager.shared.authorizationState
        switch state {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
        #else
        return .unsupported
        #endif
    }
    
    // MARK: - Alarm Planlama
    
    /// Belirtilen tarih ve ayarlarla bir alarm kurar.
    #if canImport(AlarmKit)
    @available(iOS 26.0, *)
    func scheduleAlarm(
        at date: Date,
        title: String,
        soundName: String? = nil,
        scheduleId: String? = nil,
        blockId: String? = nil,
        isTestAlarm: Bool = false
    ) async throws -> Alarm {
        let metadata = PolyNapAlarmMetadata(
            scheduleId: scheduleId,
            blockId: blockId,
            soundName: soundName,
            isTestAlarm: isTestAlarm
        )
        
        let localizedTitle = LocalizedStringResource(stringLiteral: title)
        let stopButton = AlarmButton(text: "Stop", textColor: .red, systemImageName: "stop.fill")
        let alertPresentation = AlarmPresentation.Alert(
            title: localizedTitle,
            stopButton: stopButton
        )
        let presentation = AlarmPresentation(alert: alertPresentation)
        
        let attributes = AlarmAttributes<PolyNapAlarmMetadata>(
            presentation: presentation,
            metadata: metadata,
            tintColor: .blue
        )
        
        let sound: AlertConfiguration.AlertSound
        if let soundName = soundName, !soundName.isEmpty {
            sound = .named(soundName)
        } else {
            sound = .default
        }
        
        let alarmId = UUID()
        let configuration = AlarmKit.AlarmManager.AlarmConfiguration<PolyNapAlarmMetadata>.alarm(
            schedule: .fixed(date),
            attributes: attributes,
            sound: sound
        )
        
        let alarm: Alarm = try await AlarmKit.AlarmManager.shared.schedule(id: alarmId, configuration: configuration)
        print("✅ AlarmKitService: Alarm planlandı - \(date.formatted(date: .abbreviated, time: .shortened))")
        return alarm
    }
    #endif
    
    /// Bir uyku bloğu için alarm kurar.
    func scheduleSleepBlockAlarm(
        at date: Date,
        scheduleId: UUID,
        blockId: UUID,
        scheduleName: String
    ) async throws {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return }
        
        let title = L("alarm.wake.scheduled.title", table: "Alarms")
        
        _ = try await scheduleAlarm(
            at: date,
            title: title,
            scheduleId: scheduleId.uuidString,
            blockId: blockId.uuidString
        )
        #endif
    }
    
    // MARK: - Alarm Yönetimi
    
    /// Belirtilen ID'ye sahip alarmı iptal eder.
    func cancelAlarm(id: UUID) async throws {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return }
        try await AlarmKit.AlarmManager.shared.cancel(id: id)
        print("✅ AlarmKitService: Alarm iptal edildi - \(id)")
        #endif
    }
    
    /// Tüm alarmları iptal eder.
    func cancelAllAlarms() async {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return }
        
        do {
            let alarms = try await AlarmKit.AlarmManager.shared.alarms
            for alarm in alarms {
                try await AlarmKit.AlarmManager.shared.cancel(id: alarm.id)
            }
            print("🗑️ AlarmKitService: Tüm alarmlar iptal edildi.")
        } catch {
            print("🚨 AlarmKitService: Alarmlar iptal edilemedi: \(error.localizedDescription)")
        }
        #endif
    }
    
    // MARK: - Erteleme (Snooze)
    
    /// Alarmı belirtilen süre kadar erteler.
    func snoozeAlarm(id: UUID, minutes: Int = 5) async throws {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return }
        
        let snoozeDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        let title = L("alarm.snoozed.title", table: "Alarms")
        
        _ = try await scheduleAlarm(
            at: snoozeDate,
            title: title
        )
        print("✅ AlarmKitService: Alarm \(minutes) dakika ertelendi.")
        #endif
    }
    
    // MARK: - Test Alarmı
    
    /// Test alarmı kurar (5 saniye içinde tetiklenir).
    func scheduleTestAlarm() async throws {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return }
        
        let testDate = Date().addingTimeInterval(5)
        let title = L("alarm.test.title", table: "Alarms")
        
        _ = try await scheduleAlarm(
            at: testDate,
            title: title,
            isTestAlarm: true
        )
        #endif
    }
}
