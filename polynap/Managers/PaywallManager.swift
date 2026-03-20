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
    /// Automatically sets `is_discount_eligible` before presenting so the
    /// Superwall dashboard can show the discount drawer on the X-button tap
    /// when eligible (first paywall of the day OR every 3rd open).
    func presentPaywall(trigger: PaywallTrigger, onComplete: (() -> Void)? = nil) {
        let placement = placementName(for: trigger)
        
        // Determine eligibility BEFORE presenting so the attribute is already
        // set when Superwall evaluates the X-button audience rule.
        let eligible = shouldShowDrawerOnNextOpen()
        setDiscountEligibility(eligible)

        incrementPaywallOpenCount()
        incrementPaywallCount()
        
        print("\n📱 ========== SUPERWALL PAYWALL ==========")
        print("📱 Trigger: \(trigger) | Placement: \(placement)")
        print("📱 is_discount_eligible: \(eligible)")
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
    
    /// Returns true when the discount drawer should be shown on the X-button tap:
    /// • First paywall open of the day, OR
    /// • Every 3rd paywall open total.
    private func shouldShowDrawerOnNextOpen() -> Bool {
        let isFirstToday = isFirstPaywallOpenToday()
        let openCount = getPaywallOpenCount()
        let isEveryThird = openCount > 0 && (openCount + 1) % 3 == 0
        return isFirstToday || isEveryThird
    }

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

    /// Sends `is_discount_eligible` user attribute to Superwall.
    /// In the Superwall dashboard, add an audience filter on the paywall's
    /// X-button action:  `is_discount_eligible == true` → trigger `discount-drawer`.
    private func setDiscountEligibility(_ eligible: Bool) {
        #if canImport(SuperwallKit)
        Superwall.shared.setUserAttributes(["is_discount_eligible": eligible])
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
