import Foundation
import SwiftUI
import RevenueCat
#if canImport(SuperwallKit)
import SuperwallKit
#endif
import Combine

// MARK: - Paywall Trigger Types

enum PaywallTrigger {
    case onboardingComplete
    case premiumFeatureAccess
    case manualTrigger
}

// MARK: - Superwall Placement Names

// These names MUST match placements created in the Superwall dashboard.
private enum SuperwallPlacement {
    static let onboardingComplete = "free-trail-campaign"
    static let featurePaywall = "free-trial-paywall"
    static let discountDrawer = "discount-drawer"
}

// MARK: - Paywall Manager

final class PaywallManager: ObservableObject {
    
    static let shared = PaywallManager()
    
    private let userDefaults = UserDefaults.standard
    private let paywallCountKey = "paywall_presentation_count"
    private let lastPaywallDateKey = "last_paywall_presentation_date"
    // Total number of times the paywall has been *opened* (used for every-3rd logic)
    private let paywallOpenCountKey = "paywall_open_count"
    // Tracks whether this day's first paywall open has already been registered
    private let lastDailyPaywallOpenKey = "last_daily_paywall_open_date"
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
    /// Sets two attributes before presenting:
    /// - `is_first_daily_open`: controls Lottie vs Static X button visibility
    /// - `is_discount_eligible`: controls drawer vs close on every 3rd open (3rd, 6th, 9th…)
    func presentPaywall(trigger: PaywallTrigger, onComplete: (() -> Void)? = nil) {
        let placement = placementName(for: trigger)
        
        // Determine both attributes BEFORE incrementing so isFirstPaywallOpenToday()
        // still reflects the current open (not yet recorded as today's open).
        let isFirstDaily = isFirstPaywallOpenToday()
        let openCount = getPaywallOpenCount()
        let isEveryThird = openCount > 0 && (openCount + 1) % 3 == 0
        setPaywallAttributes(isFirstDaily: isFirstDaily, isEveryThird: isEveryThird)

        incrementPaywallOpenCount()
        incrementPaywallCount()

        print("\n📱 ========== SUPERWALL PAYWALL ==========")
        print("📱 Trigger: \(trigger) | Placement: \(placement)")
        print("📱 is_first_daily_open: \(isFirstDaily)")
        print("📱 is_discount_eligible (every 3rd): \(isEveryThird)")
        print("📱 Open count: \(getPaywallOpenCount())")
        print("📱 =========================================\n")
        
        #if canImport(SuperwallKit)
        let handler = PaywallPresentationHandler()
        handler.onDismiss { [weak self] _, _ in
            DispatchQueue.main.async { onComplete?() }
        }
        handler.onSkip { _ in DispatchQueue.main.async { onComplete?() } }
        handler.onError { _ in DispatchQueue.main.async { onComplete?() } }
        Superwall.shared.register(placement: placement, handler: handler)
        #else
        print("⚠️ SuperwallKit not available.")
        onComplete?()
        #endif
    }
    
    /// Resets paywall presentation history (debug/test).
    func resetPaywallHistory() {
        let oldCount = getPaywallPresentationCount()
        userDefaults.removeObject(forKey: paywallCountKey)
        userDefaults.removeObject(forKey: lastPaywallDateKey)
        userDefaults.removeObject(forKey: paywallOpenCountKey)
        userDefaults.removeObject(forKey: lastDailyPaywallOpenKey)
        UserDefaults.standard.removeObject(forKey: "has_triggered_onboarding_paywall")
        
        print("🔄 PaywallManager: History reset (was \(oldCount) → 0)")
    }
    
    /// No-op kept for call-site compatibility; eligibility is now evaluated at open time.
    func checkFirstDailyOpen() {}
    
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
        userDefaults.set(getPaywallPresentationCount() + 1, forKey: paywallCountKey)
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
    
    // MARK: - Discount Drawer Eligibility

    private func isFirstPaywallOpenToday() -> Bool {
        guard let last = userDefaults.object(forKey: lastDailyPaywallOpenKey) as? Date else { return true }
        return !Calendar.current.isDateInToday(last)
    }

    private func getPaywallOpenCount() -> Int {
        userDefaults.integer(forKey: paywallOpenCountKey)
    }

    private func incrementPaywallOpenCount() {
        let newCount = getPaywallOpenCount() + 1
        userDefaults.set(newCount, forKey: paywallOpenCountKey)
        // Mark today as "paywall was opened today"
        userDefaults.set(Date(), forKey: lastDailyPaywallOpenKey)
    }

    /// Sends two independent user attributes to Superwall before each paywall open:
    /// - `is_first_daily_open`: true if this is the first paywall open of the calendar day (controls Lottie visibility)
    /// - `is_discount_eligible`: true on every 3rd total open — 3rd, 6th, 9th… (controls drawer vs close tap behavior)
    private func setPaywallAttributes(isFirstDaily: Bool, isEveryThird: Bool) {
        #if canImport(SuperwallKit)
        Superwall.shared.setUserAttributes([
            "is_first_daily_open": isFirstDaily,
            "is_discount_eligible": isEveryThird
        ])
        #endif
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
