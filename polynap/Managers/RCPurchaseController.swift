//
//  RCPurchaseController.swift
//  polynap
//
//  Superwall ↔ RevenueCat purchase bridge.
//  Handles purchases and restores through RevenueCat,
//  syncs subscription status with Superwall.
//

import SuperwallKit
import RevenueCat
import StoreKit

enum PurchasingError: LocalizedError {
    case sk2ProductNotFound
    
    var errorDescription: String? {
        switch self {
        case .sk2ProductNotFound:
            return "Superwall didn't pass a StoreKit 2 product to purchase."
        }
    }
}

final class RCPurchaseController: PurchaseController {
    
    // MARK: - Sync Subscription Status
    
    /// Keeps Superwall's subscription status in sync with RevenueCat entitlements.
    func syncSubscriptionStatus() {
        assert(Purchases.isConfigured, "RevenueCat must be configured before calling this method.")
        Task {
            for await customerInfo in Purchases.shared.customerInfoStream {
                let superwallEntitlements = customerInfo.entitlements.activeInCurrentEnvironment.keys.map {
                    Entitlement(id: $0)
                }
                await MainActor.run { [superwallEntitlements] in
                    Superwall.shared.subscriptionStatus = .active(Set(superwallEntitlements))
                }
            }
        }
    }
    
    // MARK: - Handle Purchases
    
    /// Purchases a product through RevenueCat when user buys on a Superwall paywall.
    func purchase(product: SuperwallKit.StoreProduct) async -> PurchaseResult {
        do {
            guard let sk2Product = product.sk2Product else {
                throw PurchasingError.sk2ProductNotFound
            }
            let storeProduct = RevenueCat.StoreProduct(sk2Product: sk2Product)
            let revenueCatResult = try await Purchases.shared.purchase(product: storeProduct)
            if revenueCatResult.userCancelled {
                return .cancelled
            } else {
                // Update RevenueCatManager state
                await MainActor.run {
                    RevenueCatManager.shared.userState = .premium
                }
                return .purchased
            }
        } catch let error as ErrorCode {
            if error == .paymentPendingError {
                return .pending
            } else {
                return .failed(error)
            }
        } catch {
            return .failed(error)
        }
    }
    
    // MARK: - Handle Restores
    
    /// Restores purchases through RevenueCat.
    func restorePurchases() async -> RestorationResult {
        do {
            _ = try await Purchases.shared.restorePurchases()
            return .restored
        } catch {
            return .failed(error)
        }
    }
}
