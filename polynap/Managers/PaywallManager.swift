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
    private let paywallDismissCountKey = "paywall_dismiss_count"
    private let lastDailyDiscountOpenKey = "last_daily_discount_open_date"
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
    /// - Parameter onComplete: Called when the paywall is dismissed or skipped (including when Superwall decides not to show it).
    func presentPaywall(trigger: PaywallTrigger, onComplete: (() -> Void)? = nil) {
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
        #if canImport(SuperwallKit)
        print("🧱 [Superwall] register(placement: \"\(placement)\") çağrılıyor...")
        print("🧱 [Superwall] Mevcut subscriptionStatus: \(Superwall.shared.subscriptionStatus)")
        print("🧱 [Superwall] ⚠️ NOT: Dashboard → Campaigns'de '\(placement)' adlı bir trigger/event tanımlı olmalı")
        let handler = PaywallPresentationHandler()
        handler.onDismiss { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.trackPaywallDismissed()
                onComplete?()
            }
        }
        handler.onSkip { _ in DispatchQueue.main.async { onComplete?() } }
        handler.onError { _ in DispatchQueue.main.async { onComplete?() } }
        Superwall.shared.register(placement: placement, handler: handler)
        #else
        print("⚠️ SuperwallKit not available. Add the SPM package to enable paywalls.")
        onComplete?()
        #endif
    }
    
    /// Resets paywall presentation history (debug/test).
    func resetPaywallHistory() {
        let oldCount = getPaywallPresentationCount()
        userDefaults.removeObject(forKey: paywallCountKey)
        userDefaults.removeObject(forKey: lastPaywallDateKey)
        userDefaults.removeObject(forKey: paywallDismissCountKey)
        userDefaults.removeObject(forKey: lastDailyDiscountOpenKey)
        UserDefaults.standard.removeObject(forKey: "has_triggered_onboarding_paywall")
        
        print("🔄 PaywallManager: History reset (was \(oldCount) → 0)")
    }
    
    /// Call on every app foreground/launch to trigger discount drawer on first open of the day.
    func checkFirstDailyOpen() {
        let lastDate = userDefaults.object(forKey: lastDailyDiscountOpenKey) as? Date
        let isFirstOpenToday = lastDate.map { !Calendar.current.isDateInToday($0) } ?? true
        
        setDiscountEligibility(isFirstOpenToday)
        
        if isFirstOpenToday {
            userDefaults.set(Date(), forKey: lastDailyDiscountOpenKey)
            print("🎯 [Discount] İlk günlük açılış — discount-drawer tetikleniyor")
            triggerDiscountDrawer()
        }
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
    
    // MARK: - Discount Drawer Logic
    
    /// Called on every paywall dismiss; triggers discount drawer every 3rd close.
    private func trackPaywallDismissed() {
        let newCount = userDefaults.integer(forKey: paywallDismissCountKey) + 1
        userDefaults.set(newCount, forKey: paywallDismissCountKey)
        
        let isEveryThird = newCount % 3 == 0
        setDiscountEligibility(isEveryThird)
        
        if isEveryThird {
            print("🎯 [Discount] Her 3. kapatma (\(newCount)) — discount-drawer tetikleniyor")
            triggerDiscountDrawer()
        }
    }
    
    /// Sets the Superwall user attribute `is_discount_eligible` for measurement.
    private func setDiscountEligibility(_ eligible: Bool) {
        #if canImport(SuperwallKit)
        Superwall.shared.setUserAttributes(["is_discount_eligible": eligible])
        #endif
    }
    
    /// Registers the discount drawer placement in Superwall.
    private func triggerDiscountDrawer() {
        #if canImport(SuperwallKit)
        Superwall.shared.register(placement: SuperwallPlacement.discountDrawer)
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
