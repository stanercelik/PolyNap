//
//  RCPurchaseController.swift
//  polynap
//
//  Superwall ↔ RevenueCat purchase bridge.
//  Handles purchases and restores through RevenueCat,
//  syncs subscription status with Superwall.
//

#if canImport(SuperwallKit)
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

// MARK: - Superwall Debug Delegate

final class SuperwallDebugDelegate: SuperwallDelegate {
    
    static let shared = SuperwallDebugDelegate()
    private init() {}
    
    func handleSuperwallEvent(withInfo eventInfo: SuperwallEventInfo) {
        let prefix = "🧱 [Superwall Event]"
        switch eventInfo.event {
        case .appOpen:
            print("\(prefix) appOpen")
        case .appLaunch:
            print("\(prefix) appLaunch")
        case .sessionStart:
            print("\(prefix) sessionStart")
        case .deviceAttributes(let attributes):
            print("\(prefix) deviceAttributes: \(attributes)")
        case .firstSeen:
            print("\(prefix) firstSeen")
        case .appInstall:
            print("\(prefix) appInstall")
        case .paywallOpen(let paywallInfo):
            print("\(prefix) ✅ paywallOpen — identifier: \(paywallInfo.identifier), name: \(paywallInfo.name)")
        case .paywallClose(let paywallInfo):
            print("\(prefix) paywallClose — \(paywallInfo.name)")
        case .paywallDecline(let paywallInfo):
            print("\(prefix) paywallDecline — \(paywallInfo.name)")
        case .transactionStart(let product, let paywallInfo):
            print("\(prefix) transactionStart — product: \(product.productIdentifier), paywall: \(paywallInfo.name)")
        case .transactionComplete(_, _, _, let paywallInfo):
            print("\(prefix) ✅ transactionComplete — paywall: \(paywallInfo.name)")
        case .transactionFail(let error, let paywallInfo):
            print("\(prefix) ❌ transactionFail — \(error.localizedDescription), paywall: \(paywallInfo.name)")
        case .transactionAbandon(let product, let paywallInfo):
            print("\(prefix) transactionAbandon — \(product.productIdentifier), paywall: \(paywallInfo.name)")
        case .subscriptionStart(let product, let paywallInfo):
            print("\(prefix) subscriptionStart — \(product.productIdentifier), paywall: \(paywallInfo.name)")
        case .freeTrialStart(let product, let paywallInfo):
            print("\(prefix) freeTrialStart — \(product.productIdentifier), paywall: \(paywallInfo.name)")
        case .restoreStart:
            print("\(prefix) restoreStart")
        case .restoreComplete:
            print("\(prefix) ✅ restoreComplete")
        case .restoreFail(let message):
            print("\(prefix) ❌ restoreFail — \(message)")
        case .userAttributes(let attributes):
            print("\(prefix) userAttributes: \(attributes)")
        case .customPlacement(let name, let params, _):
            print("\(prefix) customPlacement — name: \(name), params: \(params)")
        case .paywallResponseLoadStart(let triggeredPlacementName):
            print("\(prefix) paywallResponseLoadStart — trigger: \(triggeredPlacementName ?? "nil")")
        case .paywallResponseLoadNotFound(let triggeredPlacementName):
            print("\(prefix) ⚠️ paywallResponseLoadNotFound — trigger: \(triggeredPlacementName ?? "nil")")
            print("\(prefix) ⚠️ ÇÖZÜM: Superwall dashboard → Campaigns → Bu event için campaign oluştur → Trigger adı bu olmalı")
        case .paywallResponseLoadFail(let triggeredPlacementName):
            print("\(prefix) ❌ paywallResponseLoadFail — trigger: \(triggeredPlacementName ?? "nil")")
        case .paywallResponseLoadComplete(let triggeredPlacementName, let paywallInfo):
            print("\(prefix) paywallResponseLoadComplete — trigger: \(triggeredPlacementName ?? "nil"), paywall: \(paywallInfo.name)")
        case .paywallWebviewLoadStart(let paywallInfo):
            print("\(prefix) paywallWebviewLoadStart — \(paywallInfo.name)")
        case .paywallWebviewLoadFail(let paywallInfo):
            print("\(prefix) ❌ paywallWebviewLoadFail — \(paywallInfo.name)")
        case .paywallWebviewLoadComplete(let paywallInfo):
            print("\(prefix) paywallWebviewLoadComplete — \(paywallInfo.name)")
        case .paywallProductsLoadStart(let triggeredPlacementName, let paywallInfo):
            print("\(prefix) paywallProductsLoadStart — trigger: \(triggeredPlacementName ?? "nil"), paywall: \(paywallInfo.name)")
        case .paywallProductsLoadFail(let triggeredPlacementName, let paywallInfo):
            print("\(prefix) ❌ paywallProductsLoadFail — trigger: \(triggeredPlacementName ?? "nil"), paywall: \(paywallInfo.name)")
        case .paywallProductsLoadComplete(let triggeredPlacementName):
            print("\(prefix) paywallProductsLoadComplete — trigger: \(triggeredPlacementName ?? "nil")")
        case .paywallPresentationRequest(let status, let reason):
            print("\(prefix) paywallPresentationRequest — status: \(status), reason: \(reason)")
        default:
            print("\(prefix) other event: \(eventInfo.event)")
        }
    }
    
    func paywallWillPresent(withInfo paywallInfo: PaywallInfo) {
        print("🧱 [Superwall] ✅ paywallWillPresent — \(paywallInfo.name) (id: \(paywallInfo.identifier))")
    }
    
    func paywallDidPresent(withInfo paywallInfo: PaywallInfo) {
        print("🧱 [Superwall] ✅ paywallDidPresent — \(paywallInfo.name)")
    }
    
    func paywallWillDismiss(withInfo paywallInfo: PaywallInfo) {
        print("🧱 [Superwall] paywallWillDismiss — \(paywallInfo.name)")
    }
    
    func paywallDidDismiss(withInfo paywallInfo: PaywallInfo) {
        print("🧱 [Superwall] paywallDidDismiss — \(paywallInfo.name)")
    }
}

// MARK: - Purchase Controller

final class RCPurchaseController: PurchaseController {
    
    // MARK: - Sync Subscription Status
    
    /// Keeps Superwall's subscription status in sync with RevenueCat entitlements.
    func syncSubscriptionStatus() {
        assert(Purchases.isConfigured, "RevenueCat must be configured before calling this method.")
        
        // Set initial status from cache immediately to prevent Superwall 5-second timeout.
        // On first launch cachedCustomerInfo is nil → default to .inactive (free user).
        Task { @MainActor in
            if let cachedInfo = Purchases.shared.cachedCustomerInfo {
                self.updateSuperwallSubscriptionStatus(from: cachedInfo)
            } else {
                Superwall.shared.subscriptionStatus = .inactive
            }
        }
        
        // Continue listening for updates from RevenueCat
        Task {
            for await customerInfo in Purchases.shared.customerInfoStream {
                await MainActor.run {
                    self.updateSuperwallSubscriptionStatus(from: customerInfo)
                }
            }
        }
    }
    
    /// Maps RevenueCat entitlements to the correct Superwall subscription status.
    @MainActor
    private func updateSuperwallSubscriptionStatus(from customerInfo: RevenueCat.CustomerInfo) {
        let activeEntitlements = customerInfo.entitlements.activeInCurrentEnvironment
        if activeEntitlements.isEmpty {
            Superwall.shared.subscriptionStatus = .inactive
        } else {
            let entitlements = activeEntitlements.keys.map { Entitlement(id: $0) }
            Superwall.shared.subscriptionStatus = .active(Set(entitlements))
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
#endif
