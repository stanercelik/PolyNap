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
    
    init(hasCompletedOnboarding: Bool = false, hasCompletedQuestions: Bool = false, hasSkippedOnboarding: Bool = false, reminderLeadTimeInMinutes: Int = 15, onboardingRestartCount: Int = 0, hasSeenSkippedOnboardingCard: Bool = false, userName: String = "") {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasCompletedQuestions = hasCompletedQuestions
        self.hasSkippedOnboarding = hasSkippedOnboarding
        self.reminderLeadTimeInMinutes = reminderLeadTimeInMinutes
        self.onboardingRestartCount = onboardingRestartCount
        self.hasSeenSkippedOnboardingCard = hasSeenSkippedOnboardingCard
        self.userName = userName
    }
    
    /// Kullanıcı tercihlerini sıfırlar
    func resetPreferences() {
        self.hasCompletedOnboarding = false
        self.hasCompletedQuestions = false
        self.hasSkippedOnboarding = false
        self.reminderLeadTimeInMinutes = 15
        self.hasSeenSkippedOnboardingCard = false
        // onboardingRestartCount'ı sıfırlamıyoruz çünkü bu kullanıcının geçmişi
    }
}
