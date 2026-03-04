import SwiftUI
import SuperwallKit

/// A view modifier that presents a Superwall paywall when a non-premium user tries to interact with the content.
struct RequirePremiumViewModifier: ViewModifier {
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @StateObject private var paywallManager = PaywallManager.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if revenueCatManager.userState != .premium {
                        Rectangle()
                            .foregroundColor(.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                paywallManager.presentPaywall(trigger: .premiumFeatureAccess)
                            }
                    }
                }
            )
    }
}

extension View {
    /// Restricts interaction to premium users. Non-premium taps trigger a Superwall paywall.
    func requiresPremium() -> some View {
        modifier(RequirePremiumViewModifier())
    }
}
