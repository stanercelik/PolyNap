import SwiftUI
import StoreKit

// MARK: - Tour Step Definition
enum TourStep: Int, CaseIterable {
    case overview = 0
    case editButton
    case changeSchedule
    case history
    case analytics
    case profileAdaptation
    case profileBadges
    case settingsButton
    case settingsNotifications
    case settingsAlarms
    case settingsRestartTour
    case settingsHealth

    var requiredTab: Int {
        switch self {
        case .overview, .editButton, .changeSchedule: return 0
        case .history: return 1
        case .analytics: return 2
        default: return 3
        }
    }

    var requiresSettingsNav: Bool {
        switch self {
        case .settingsNotifications, .settingsAlarms, .settingsRestartTour, .settingsHealth:
            return true
        default:
            return false
        }
    }

    var anchorId: String {
        switch self {
        case .overview:              return "tour.main.chartCard"
        case .editButton:            return "tour.main.chartCard"   // edit btn hides in edit mode; highlight whole card
        case .changeSchedule:        return "tour.main.scheduleButton"
        case .history:               return "tour.history.content"
        case .analytics:             return "tour.analytics.content"
        case .profileAdaptation:     return "tour.profile.adaptation"
        case .profileBadges:         return "tour.profile.badges"
        case .settingsButton:        return "tour.profile.settingsButton"
        case .settingsNotifications: return "tour.settings.notifications"
        case .settingsAlarms:        return "tour.settings.alarms"
        case .settingsRestartTour:   return "tour.settings.restartTour"
        case .settingsHealth:        return "tour.settings.health"
        }
    }

    var isLastStep: Bool { rawValue == TourStep.allCases.count - 1 }

    /// Delay before the spotlight becomes visible when transitioning to this step
    var transitionDelay: Double {
        switch self {
        case .history, .analytics: return 0.5
        case .profileAdaptation: return 0.9   // needs extra time for tab switch + scroll
        case .profileBadges: return 0.6
        case .settingsNotifications: return 0.7
        default: return 0.3
        }
    }
}

// MARK: - AppTourManager
final class AppTourManager: ObservableObject {
    static let shared = AppTourManager()

    @Published var isShowingTour: Bool = false
    @Published var currentStepIndex: Int = 0
    @Published var navigateToSettingsForTour: Bool = false
    @Published var spotlightVisible: Bool = false

    private let completedKey = "hasCompletedAppTour"

    private init() {}

    var currentStep: TourStep {
        TourStep(rawValue: currentStepIndex) ?? .overview
    }

    var hasCompletedTour: Bool {
        get { UserDefaults.standard.bool(forKey: completedKey) }
        set { UserDefaults.standard.set(newValue, forKey: completedKey) }
    }

    func startTourIfNeeded() {
        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.startTour()
        }
        #else
        if !hasCompletedTour {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.startTour()
            }
        }
        #endif
    }

    func startTour() {
        currentStepIndex = 0
        navigateToSettingsForTour = false
        spotlightVisible = false
        withAnimation(.easeIn(duration: 0.3)) {
            isShowingTour = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.spotlightVisible = true
            }
        }
    }

    func nextStep() {
        guard !currentStep.isLastStep else {
            completeTour()
            return
        }
        withAnimation(.easeOut(duration: 0.2)) {
            spotlightVisible = false
        }
        currentStepIndex += 1
        updateSettingsNav()
        let delay = currentStep.transitionDelay
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.spotlightVisible = true
            }
        }
    }

    func skipTour() {
        completeTour()
    }

    func restartTour() {
        hasCompletedTour = false
        isShowingTour = false
        navigateToSettingsForTour = false
        spotlightVisible = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.startTour()
        }
    }

    private func completeTour() {
        hasCompletedTour = true
        withAnimation(.easeOut(duration: 0.25)) {
            spotlightVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.2)) {
                self.isShowingTour = false
            }
            self.navigateToSettingsForTour = false
        }
        // Trigger native App Store review after tour completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            self.requestNativeReview()
        }
    }

    @MainActor
    private func requestNativeReview() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }
        SKStoreReviewController.requestReview(in: windowScene)
    }

    private func updateSettingsNav() {
        navigateToSettingsForTour = currentStep.requiresSettingsNav
    }
}
