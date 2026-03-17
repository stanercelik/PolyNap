import SwiftUI
import SwiftData

@Model
final class UserPreferences {
    var hasCompletedOnboarding: Bool = false
    var hasCompletedQuestions: Bool = false
    var hasSkippedOnboarding: Bool = false
    var reminderLeadTimeInMinutes: Int = 15
    var onboardingRestartCount: Int = 0
    var hasSeenSkippedOnboardingCard: Bool = false
    var userName: String = ""
    var preferredNudgeTone: String = NudgeTone.supportive.rawValue
    var notificationCadence: String = NudgeCadence.balanced.rawValue
    var quietHoursStartMinutes: Int = 23 * 60
    var quietHoursEndMinutes: Int = 7 * 60
    var motivationTrigger: String = MotivationTrigger.stability.rawValue
    var lastNudgeResponse: String = NudgeResponseState.none.rawValue
    var fatigueScore: Double = 0.35
    
    init(
        hasCompletedOnboarding: Bool = false,
        hasCompletedQuestions: Bool = false,
        hasSkippedOnboarding: Bool = false,
        reminderLeadTimeInMinutes: Int = 15,
        onboardingRestartCount: Int = 0,
        hasSeenSkippedOnboardingCard: Bool = false,
        userName: String = "",
        preferredNudgeTone: String = NudgeTone.supportive.rawValue,
        notificationCadence: String = NudgeCadence.balanced.rawValue,
        quietHoursStartMinutes: Int = 23 * 60,
        quietHoursEndMinutes: Int = 7 * 60,
        motivationTrigger: String = MotivationTrigger.stability.rawValue,
        lastNudgeResponse: String = NudgeResponseState.none.rawValue,
        fatigueScore: Double = 0.35
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasCompletedQuestions = hasCompletedQuestions
        self.hasSkippedOnboarding = hasSkippedOnboarding
        self.reminderLeadTimeInMinutes = reminderLeadTimeInMinutes
        self.onboardingRestartCount = onboardingRestartCount
        self.hasSeenSkippedOnboardingCard = hasSeenSkippedOnboardingCard
        self.userName = userName
        self.preferredNudgeTone = preferredNudgeTone
        self.notificationCadence = notificationCadence
        self.quietHoursStartMinutes = quietHoursStartMinutes
        self.quietHoursEndMinutes = quietHoursEndMinutes
        self.motivationTrigger = motivationTrigger
        self.lastNudgeResponse = lastNudgeResponse
        self.fatigueScore = fatigueScore
    }

    var nudgeTone: NudgeTone {
        get { NudgeTone(rawValue: preferredNudgeTone) ?? .supportive }
        set { preferredNudgeTone = newValue.rawValue }
    }

    var nudgeCadence: NudgeCadence {
        get { NudgeCadence(rawValue: notificationCadence) ?? .balanced }
        set { notificationCadence = newValue.rawValue }
    }

    var nudgeTrigger: MotivationTrigger {
        get { MotivationTrigger(rawValue: motivationTrigger) ?? .stability }
        set { motivationTrigger = newValue.rawValue }
    }

    var lastNudgeResponseState: NudgeResponseState {
        get { NudgeResponseState(rawValue: lastNudgeResponse) ?? .none }
        set { lastNudgeResponse = newValue.rawValue }
    }
    
    /// Kullanıcı tercihlerini sıfırlar
    func resetPreferences() {
        self.hasCompletedOnboarding = false
        self.hasCompletedQuestions = false
        self.hasSkippedOnboarding = false
        self.reminderLeadTimeInMinutes = 15
        self.hasSeenSkippedOnboardingCard = false
        self.nudgeTone = .supportive
        self.nudgeCadence = .balanced
        self.nudgeTrigger = .stability
        self.lastNudgeResponseState = .none
        self.quietHoursStartMinutes = 23 * 60
        self.quietHoursEndMinutes = 7 * 60
        self.fatigueScore = 0.35
        // onboardingRestartCount'ı sıfırlamıyoruz çünkü bu kullanıcının geçmişi
    }
}
