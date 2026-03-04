import Foundation
import SwiftUI
import RevenueCat
import SuperwallKit
import Combine

// MARK: - Paywall Trigger Types

enum PaywallTrigger {
    case onboardingComplete
    case premiumFeatureAccess
    case manualTrigger
}

// MARK: - Superwall Placement Names

private enum SuperwallPlacement {
    static let onboardingComplete = "onboarding_complete"
    static let featurePaywall = "feature_paywall"
}

// MARK: - Paywall Manager

final class PaywallManager: ObservableObject {
    
    static let shared = PaywallManager()
    
    private let userDefaults = UserDefaults.standard
    private let paywallCountKey = "paywall_presentation_count"
    private let lastPaywallDateKey = "last_paywall_presentation_date"
    private var userStateObserver: AnyCancellable?
    
    private init() {
        userStateObserver = RevenueCatManager.shared.$userState
            .dropFirst()
            .sink { [weak self] userState in
                self?.handleUserStateChange(userState)
            }
    }
    
    // MARK: - Public Methods
    
    /// Presents a Superwall paywall based on the trigger type.
    func presentPaywall(trigger: PaywallTrigger) {
        let currentCount = getPaywallPresentationCount()
        let placement = placementName(for: trigger)
        
        print("\n📱 ========== SUPERWALL PAYWALL ==========")
        print("📱 PaywallManager: Superwall placement register")
        print("   Trigger: \(trigger)")
        print("   Placement: \(placement)")
        print("   Count: \(currentCount)")
        
        incrementPaywallCount()
        
        print("   New count: \(getPaywallPresentationCount())")
        print("📱 =========================================\n")
        
        // Superwall handles presentation, dismiss, and purchase flow
        Superwall.shared.register(placement: placement)
    }
    
    /// Resets paywall presentation history (debug/test).
    func resetPaywallHistory() {
        let oldCount = getPaywallPresentationCount()
        userDefaults.removeObject(forKey: paywallCountKey)
        userDefaults.removeObject(forKey: lastPaywallDateKey)
        UserDefaults.standard.removeObject(forKey: "has_triggered_onboarding_paywall")
        
        print("🔄 PaywallManager: History reset (was \(oldCount) → 0)")
    }
    
    /// Prints debug status.
    func printPaywallStatus() {
        let count = getPaywallPresentationCount()
        let lastDate = getLastPaywallDate()
        
        print("\n📊 ========== PAYWALL STATUS ==========")
        print("📊 Total presentations: \(count)")
        print("📊 Last presented: \(lastDate?.description ?? "Never")")
        print("📊 Placements:")
        print("   onboarding_complete → 2-page paywall (info → free trial)")
        print("   feature_paywall → free trial paywall")
        print("📊 ======================================\n")
    }
    
    // MARK: - Private Methods
    
    /// Maps trigger to Superwall placement name.
    private func placementName(for trigger: PaywallTrigger) -> String {
        switch trigger {
        case .onboardingComplete:
            return SuperwallPlacement.onboardingComplete
        case .premiumFeatureAccess, .manualTrigger:
            return SuperwallPlacement.featurePaywall
        }
    }
    
    private func getPaywallPresentationCount() -> Int {
        return userDefaults.integer(forKey: paywallCountKey)
    }
    
    private func incrementPaywallCount() {
        let currentCount = getPaywallPresentationCount()
        userDefaults.set(currentCount + 1, forKey: paywallCountKey)
        userDefaults.set(Date(), forKey: lastPaywallDateKey)
    }
    
    private func getLastPaywallDate() -> Date? {
        return userDefaults.object(forKey: lastPaywallDateKey) as? Date
    }
    
    private func handleUserStateChange(_ userState: UserState) {
        if userState == .premium {
            print("📱 PaywallManager: User became premium")
        }
    }
}

// MARK: - View Extension (Superwall no longer needs sheet-based presentation)

extension View {
    /// No-op modifier kept for backward compatibility.
    /// Superwall manages its own presentation layer.
    func managePaywalls() -> some View {
        self
    }
}
