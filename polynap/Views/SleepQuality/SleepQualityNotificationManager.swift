import SwiftUI
import UserNotifications

class SleepQualityNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = SleepQualityNotificationManager()
    static let ratingCategoryIdentifier = "SLEEP_RATING_CATEGORY"
    
    @Published var pendingRatings: [(startTime: Date, endTime: Date)] = []
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let ratingActions = ["😩", "😪", "😐", "😊", "😄"]
    private let analyticsManager = AnalyticsManager.shared
    
    private override init() {
        super.init()
        setupNotificationCategories()
        notificationCenter.delegate = self
    }
    
    private func setupNotificationCategories() {
        var actions: [UNNotificationAction] = []
        
        // Her emoji için bir aksiyon oluştur
        for (index, emoji) in ratingActions.enumerated() {
            let action = UNNotificationAction(
                identifier: "RATE_\(index)",
                title: emoji,
                options: .foreground
            )
            actions.append(action)
        }
        
        // Kategoriyi oluştur ve kaydet
        let category = UNNotificationCategory(
            identifier: Self.ratingCategoryIdentifier,
            actions: actions,
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([category])
    }
    
    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    func addPendingRating(startTime: Date, endTime: Date) {
        pendingRatings.append((startTime: startTime, endTime: endTime))
        showNotification(startTime: startTime, endTime: endTime)
    }
    
    func removePendingRating(startTime: Date, endTime: Date) {
        pendingRatings.removeAll { rating in
            Calendar.current.isDate(rating.startTime, inSameDayAs: startTime) &&
            Calendar.current.isDate(rating.endTime, inSameDayAs: endTime)
        }
    }
    
    private func showNotification(startTime: Date, endTime: Date) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("sleepQuality.notification.title", tableName: "MainScreen", comment: "")
        content.body = NSLocalizedString("sleepQuality.question", tableName: "MainScreen", comment: "")
        content.sound = .default
        content.categoryIdentifier = Self.ratingCategoryIdentifier
        
        // Bildirim için özel veri ekle
        content.userInfo = [
            "startTime": startTime.timeIntervalSince1970,
            "endTime": endTime.timeIntervalSince1970,
            "nudgeType": "sleep_quality_prompt"
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    // Bildirim aksiyonlarını işle
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotificationResponse(response)
        completionHandler()
    }

    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        
        guard let startTimeInterval = userInfo["startTime"] as? TimeInterval,
              let endTimeInterval = userInfo["endTime"] as? TimeInterval else {
            return
        }
        
        let startTime = Date(timeIntervalSince1970: startTimeInterval)
        let endTime = Date(timeIntervalSince1970: endTimeInterval)
        analyticsManager.logNotificationOpened(notificationType: "sleep_quality")
        analyticsManager.logNudgeOpened(type: "sleep_quality_prompt")
        
        if response.actionIdentifier.starts(with: "RATE_"),
           let ratingString = response.actionIdentifier.split(separator: "_").last,
           let rating = Int(ratingString) {
            let normalizedRating = min(max(rating + 1, 1), ratingActions.count)
            analyticsManager.logNudgeActionTapped(
                type: "sleep_quality_prompt",
                action: "rate_\(normalizedRating)"
            )
            saveSleepQuality(rating: normalizedRating, startTime: startTime, endTime: endTime)
        } else if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            analyticsManager.logNudgeActionTapped(
                type: "sleep_quality_prompt",
                action: "dismiss"
            )
            analyticsManager.logNudgeOutcome(
                type: "sleep_quality_prompt",
                outcome: "dismissed",
                completionDelayMinutes: nil
            )
        }
    }
    
    private func saveSleepQuality(rating: Int, startTime: Date, endTime: Date) {
        Task { @MainActor in
            do {
                let isCoreBlock = endTime.timeIntervalSince(startTime) >= 90 * 60
                try SleepQualityPersistenceService.shared.saveRating(
                    rating: Double(rating),
                    startTime: startTime,
                    endTime: endTime,
                    isCore: isCoreBlock,
                    blockId: nil,
                    source: "notification_prompt"
                )
                print("Sleep quality saved from notification: \(rating)")
                removePendingRating(startTime: startTime, endTime: endTime)
            } catch {
                print("❌ Sleep quality notification save failed: \(error.localizedDescription)")
            }
        }
    }
}
