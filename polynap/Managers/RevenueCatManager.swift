//
//  RevenueCatManager.swift
//  polynap
//
//  Created by [Your Name] on [Date].
//

import Foundation
import SwiftUI
import RevenueCat

// MARK: - UserState

enum UserState {
    case free
    case premium
}

// MARK: - RevenueCatManager

final class RevenueCatManager: NSObject, ObservableObject {

    static let shared = RevenueCatManager()
    
    @Published var userState: UserState = .free
    @Published var offerings: Offerings?
    
    private let premiumEntitlementID = "premium"
    private static let apiKey = AppConfiguration.revenueCatAPIKey

    private override init() {
        super.init()
        Purchases.shared.delegate = self
        Task {
            await self.checkInitialUserStatus()
        }
    }

    static func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(
            with: RevenueCat.Configuration.Builder(withAPIKey: apiKey)
                .with(appUserID: nil)
                .build()
        )
    }
    
    func fetchOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            await MainActor.run {
                self.offerings = offerings
            }
        } catch {
            print("Error fetching offerings: \(error)")
        }
    }
    
    /// Belirli bir offering identifier'ı ile offering getirir
    func getOffering(identifier: String) async -> Offering? {
        do {
            let offerings = try await Purchases.shared.offerings()
            return offerings.all[identifier]
        } catch {
            print("Error fetching offering \(identifier): \(error)")
            return nil
        }
    }
    


    func purchase(package: Package) async throws -> Bool {
        let purchaseResult = try await Purchases.shared.purchase(package: package)
        if purchaseResult.customerInfo.entitlements[premiumEntitlementID]?.isActive == true {
            await MainActor.run {
                self.userState = .premium
                self.evaluatePremiumBadge()
            }
            return true
        }
        return false
    }
    
    func restorePurchases() async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            updateUserState(for: customerInfo)
            print("Purchases restored successfully.")
            return true
        } catch {
            print("Error restoring purchases: \(error)")
            return false
        }
    }

    private func checkInitialUserStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateUserState(for: customerInfo)
        } catch {
            print("Error fetching initial customer info: \(error)")
        }
    }

    private func updateUserState(for customerInfo: CustomerInfo?) {
        guard let customerInfo = customerInfo else { return }
        
        let isPremium = customerInfo.entitlements[premiumEntitlementID]?.isActive == true
        
        Task { @MainActor in
            self.userState = isPremium ? .premium : .free
            print("User state updated: \(self.userState)")
            if isPremium {
                self.evaluatePremiumBadge()
            }
        }
    }

    private func evaluatePremiumBadge() {
        let longestStreak = UserDefaults.standard.integer(forKey: "longestStreak")
        let currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")
        let hasSchedule = UserDefaults.standard.bool(forKey: "cachedHasSchedule")
        let context = BadgeManager.EvaluationContext(
            hasSchedule: hasSchedule,
            longestStreak: longestStreak,
            currentStreak: currentStreak,
            adaptationPhase: UserDefaults.standard.integer(forKey: "cachedAdaptationPhase"),
            currentAdaptationDay: UserDefaults.standard.integer(forKey: "cachedAdaptationDay"),
            adaptationDuration: UserDefaults.standard.integer(forKey: "cachedAdaptationDuration") > 0
                ? UserDefaults.standard.integer(forKey: "cachedAdaptationDuration") : 21,
            isAdaptationComplete: UserDefaults.standard.bool(forKey: "cachedIsAdaptationComplete"),
            isPremium: true
        )
        BadgeManager.shared.evaluateBadges(context: context)
    }
}

// MARK: - PurchasesDelegate

extension RevenueCatManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        updateUserState(for: customerInfo)
    }
} 