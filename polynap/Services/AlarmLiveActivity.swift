import Foundation
import ActivityKit

// MARK: - Alarm Live Activity Attributes

/// Alarm Live Activity için gerekli attributes yapısı
/// Bu, Lock Screen'de alarm countdown'unu göstermek için kullanılır
struct AlarmActivityAttributes: ActivityAttributes {
    
    /// Dinamik içerik verileri
    public struct ContentState: Codable, Hashable {
        var alarmTime: Date
        var isSnoozed: Bool
        var snoozeEndTime: Date?
        var remainingMinutes: Int
        var remainingSeconds: Int
    }
    
    /// Statik attributes
    var alarmTitle: String
    var scheduleName: String
    var blockId: String
    var soundName: String?
}

// MARK: - Alarm Live Activity Manager

/// Alarm Live Activity'lerini yöneten yardımcı sınıf
@MainActor
final class AlarmLiveActivityManager: ObservableObject {
    static let shared = AlarmLiveActivityManager()
    
    private var currentActivity: Activity<AlarmActivityAttributes>?
    
    private init() {}
    
    // MARK: - Live Activity Yönetimi
    
    /// Yeni bir alarm Live Activity başlatır
    func startAlarmActivity(
        alarmTime: Date,
        scheduleName: String,
        blockId: String,
        soundName: String? = nil
    ) async {
        // Live Activity desteğini kontrol et
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("ℹ️ AlarmLiveActivity: Live Activity'ler etkin değil")
            return
        }
        
        // Mevcut activity'i sonlandır
        await endAlarmActivity()
        
        let attributes = AlarmActivityAttributes(
            alarmTitle: L("alarm.wake.title", table: "Alarms"),
            scheduleName: scheduleName,
            blockId: blockId,
            soundName: soundName
        )
        
        let remainingSeconds = Int(alarmTime.timeIntervalSinceNow)
        let remainingMinutes = remainingSeconds / 60
        
        let initialState = AlarmActivityAttributes.ContentState(
            alarmTime: alarmTime,
            isSnoozed: false,
            snoozeEndTime: nil,
            remainingMinutes: remainingMinutes,
            remainingSeconds: remainingSeconds
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            print("✅ AlarmLiveActivity: Başlatıldı - \(activity.id)")
        } catch {
            print("🚨 AlarmLiveActivity: Başlatılamadı - \(error.localizedDescription)")
        }
    }
    
    /// Alarm Live Activity'yi günceller
    func updateAlarmActivity(
        isSnoozed: Bool = false,
        snoozeEndTime: Date? = nil,
        newAlarmTime: Date? = nil
    ) async {
        guard let activity = currentActivity else { return }
        
        let alarmTime = newAlarmTime ?? activity.content.state.alarmTime
        let remainingSeconds = Int(alarmTime.timeIntervalSinceNow)
        let remainingMinutes = remainingSeconds / 60
        
        let updatedState = AlarmActivityAttributes.ContentState(
            alarmTime: alarmTime,
            isSnoozed: isSnoozed,
            snoozeEndTime: snoozeEndTime,
            remainingMinutes: remainingMinutes,
            remainingSeconds: remainingSeconds
        )
        
        await activity.update(
            ActivityContent(state: updatedState, staleDate: nil)
        )
        
        print("🔄 AlarmLiveActivity: Güncellendi")
    }
    
    /// Alarm Live Activity'yi sonlandırır
    func endAlarmActivity() async {
        guard let activity = currentActivity else { return }
        
        let finalState = AlarmActivityAttributes.ContentState(
            alarmTime: Date(),
            isSnoozed: false,
            snoozeEndTime: nil,
            remainingMinutes: 0,
            remainingSeconds: 0
        )
        
        await activity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: .immediate
        )
        
        currentActivity = nil
        print("✅ AlarmLiveActivity: Sonlandırıldı")
    }
    
    /// Tüm alarm Live Activity'lerini sonlandırır
    func endAllAlarmActivities() async {
        for activity in Activity<AlarmActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivity = nil
        print("🗑️ AlarmLiveActivity: Tüm aktiviteler sonlandırıldı")
    }
    
    /// Mevcut aktiviteyi döndürür
    var hasActiveActivity: Bool {
        return currentActivity != nil
    }
}

// MARK: - Alarm Service Entegrasyonu

extension AlarmLiveActivityManager {
    
    /// Alarm tetiklendiğinde Live Activity başlatır
    func triggerForAlarm(
        scheduleName: String,
        blockId: String,
        alarmTime: Date,
        soundName: String? = nil
    ) {
        Task {
            await startAlarmActivity(
                alarmTime: alarmTime,
                scheduleName: scheduleName,
                blockId: blockId,
                soundName: soundName
            )
        }
    }
    
    /// Alarm ertelendiğinde Live Activity'yi günceller
    func snoozeAlarm(newAlarmTime: Date) {
        Task {
            await updateAlarmActivity(
                isSnoozed: true,
                snoozeEndTime: newAlarmTime,
                newAlarmTime: newAlarmTime
            )
        }
    }
    
    /// Alarm durdurulduğunda Live Activity'yi sonlandırır
    func stopAlarm() {
        Task {
            await endAlarmActivity()
        }
    }
}
