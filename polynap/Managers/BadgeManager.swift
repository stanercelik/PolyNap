import Foundation
import UserNotifications
import SwiftUI

// MARK: - Badge Notification Name
extension Notification.Name {
    static let badgeEarned = Notification.Name("badgeEarned")
}

// MARK: - BadgeManager
final class BadgeManager {
    static let shared = BadgeManager()

    private let earnedKey = "earnedBadgeIds"
    private let hasBrokenStreakKey = "badgeHadBrokenStreak"

    private init() {}

    // MARK: - Persistence

    var earnedBadgeIds: Set<String> {
        get {
            let arr = UserDefaults.standard.stringArray(forKey: earnedKey) ?? []
            return Set(arr)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: earnedKey)
        }
    }

    // MARK: - Broken Streak Tracking

    /// Called when a streak is broken (current streak resets to 0 after previously > 0)
    func recordStreakBroken() {
        UserDefaults.standard.set(true, forKey: hasBrokenStreakKey)
    }

    var hadBrokenStreak: Bool {
        UserDefaults.standard.bool(forKey: hasBrokenStreakKey)
    }

    // MARK: - Badge Evaluation

    struct EvaluationContext {
        let hasSchedule: Bool
        let longestStreak: Int
        let currentStreak: Int
        let adaptationPhase: Int
        let currentAdaptationDay: Int
        let adaptationDuration: Int
        let isAdaptationComplete: Bool
        let isPremium: Bool
    }

    /// Evaluates all badges and returns newly earned ones.
    @discardableResult
    func evaluateBadges(context: EvaluationContext) -> [String] {
        var newlyEarned: [String] = []
        let alreadyEarned = earnedBadgeIds

        let conditions: [(id: String, earned: Bool)] = [
            ("badge-starter",        context.hasSchedule),
            ("badge-first-log",      context.longestStreak >= 1),
            ("badge-streak-3",       context.longestStreak >= 3),
            ("badge-bounce-back",    hadBrokenStreak && context.currentStreak >= 1),
            ("badge-one-week",       context.longestStreak >= 7),
            ("badge-night-owl",      context.longestStreak >= 7 && context.adaptationPhase >= 2),
            ("badge-halfway",        context.adaptationPhase >= 2 && context.currentAdaptationDay >= context.adaptationDuration / 2),
            ("badge-adaptation-done", context.isAdaptationComplete),
            ("badge-one-month",      context.longestStreak >= 30),
            ("badge-premium",        context.isPremium),
        ]

        var updated = alreadyEarned
        for (id, earned) in conditions {
            if earned && !alreadyEarned.contains(id) {
                updated.insert(id)
                newlyEarned.append(id)
            }
        }

        if !newlyEarned.isEmpty {
            earnedBadgeIds = updated
            notifyForNewBadges(newlyEarned)
        }

        return newlyEarned
    }

    // MARK: - Notifications

    /// Grants the starter badge immediately (e.g. at onboarding completion).
    /// No-op if already earned.
    func grantStarterBadge() {
        let id = "badge-starter"
        guard !earnedBadgeIds.contains(id) else { return }
        var updated = earnedBadgeIds
        updated.insert(id)
        earnedBadgeIds = updated
        notifyForNewBadges([id])
    }

    private func notifyForNewBadges(_ ids: [String]) {
        let state = UIApplication.shared.applicationState

        for id in ids {
            if state == .active {
                // App is in foreground — post internal notification for modal
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .badgeEarned,
                        object: nil,
                        userInfo: ["badgeId": id]
                    )
                }
            } else {
                // App is in background — send local push notification
                scheduleLocalNotification(for: id)
            }
        }
    }

    private func scheduleLocalNotification(for badgeId: String) {
        let content = UNMutableNotificationContent()
        content.title = badgeNotificationTitle(for: badgeId)
        content.body = badgeNotificationBody(for: badgeId)
        content.sound = .default
        content.userInfo = ["badgeId": badgeId, "type": "badge_earned"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "badge_earned_\(badgeId)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("BadgeManager: Bildirim gönderilemedi: \(error.localizedDescription)")
            }
        }
    }

    private func badgeNotificationTitle(for badgeId: String) -> String {
        let lang = LanguageManager.shared.currentLanguage
        switch badgeId {
        case "badge-starter":         return lang == "tr" ? "🌱 Yeni rozet!" : "🌱 New badge!"
        case "badge-first-log":       return lang == "tr" ? "😴 Yeni rozet!" : "😴 New badge!"
        case "badge-streak-3":        return lang == "tr" ? "🔥 Yeni rozet!" : "🔥 New badge!"
        case "badge-bounce-back":     return lang == "tr" ? "💪 Yeni rozet!" : "💪 New badge!"
        case "badge-one-week":        return lang == "tr" ? "⭐️ Yeni rozet!" : "⭐️ New badge!"
        case "badge-night-owl":       return lang == "tr" ? "🦉 Yeni rozet!" : "🦉 New badge!"
        case "badge-halfway":         return lang == "tr" ? "🧘 Yeni rozet!" : "🧘 New badge!"
        case "badge-adaptation-done": return lang == "tr" ? "🎉 Yeni rozet!" : "🎉 New badge!"
        case "badge-one-month":       return lang == "tr" ? "👑 Yeni rozet!" : "👑 New badge!"
        case "badge-premium":         return lang == "tr" ? "✨ Nimmy Pro rozeti!" : "✨ Nimmy Pro badge!"
        default:                      return lang == "tr" ? "🏅 Yeni rozet kazandın!" : "🏅 You earned a new badge!"
        }
    }

    private func badgeNotificationBody(for badgeId: String) -> String {
        let lang = LanguageManager.shared.currentLanguage
        switch badgeId {
        case "badge-starter":         return lang == "tr" ? "Çok fazlı uyku yolculuğuna başladın! Nimmy seninle gurur duyuyor." : "You started your polyphasic sleep journey! Nimmy is proud of you."
        case "badge-first-log":       return lang == "tr" ? "İlk uyku kaydını yaptın. Küçük bir adım, büyük bir başlangıç." : "You logged your first sleep. A small step, a big beginning."
        case "badge-streak-3":        return lang == "tr" ? "3 gün arka arkaya! Alışkanlık oluşmaya başlıyor." : "3 days in a row! The habit is starting to form."
        case "badge-bounce-back":     return lang == "tr" ? "Bir gün kaçırdın ama geri döndün. Asıl güç bu." : "You missed a day but came back. That's real strength."
        case "badge-one-week":        return lang == "tr" ? "Bir haftayı tamamladın! Buradan sonrası daha iyi." : "One full week done! It gets better from here."
        case "badge-night-owl":       return lang == "tr" ? "Gece programına uyum sağlıyorsun. Karanlıkta bile tutarlısın." : "You're adapting to your night schedule. Consistent even in the dark."
        case "badge-halfway":         return lang == "tr" ? "Adaptasyonun tam ortasındasın. En kritik kısımdan geçtin!" : "You're halfway through adaptation. You've crossed the hardest threshold!"
        case "badge-adaptation-done": return lang == "tr" ? "Adaptasyon sürecini tamamladın! Vücudun yeni ritmine alıştı." : "Adaptation complete! Your body has adapted to its new rhythm."
        case "badge-one-month":       return lang == "tr" ? "30 gün! Gerçek bir çok fazlı uyku ustasısın." : "30 days! You are a true polyphasic sleep master."
        case "badge-premium":         return lang == "tr" ? "Nimmy Pro üyesisin. Tüm özellikler açık." : "You're a Nimmy Pro member. All features unlocked."
        default:                      return lang == "tr" ? "Profil ekranından rozeti görüntüleyebilirsin." : "Check your profile to see the badge."
        }
    }
}
