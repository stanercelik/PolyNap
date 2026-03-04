import SwiftUI

/// PaywallManager'ı test etmek için debug view
struct PaywallTestView: View {
    @StateObject private var paywallManager = PaywallManager.shared
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Paywall Test Arayüzü")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Paywall Sayacı Bilgisi
                VStack(spacing: 8) {
                    Text("Mevcut Paywall Sayısı")
                        .font(.headline)
                    Text("\(UserDefaults.standard.integer(forKey: "paywall_presentation_count"))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Test Butonları
                VStack(spacing: 12) {
                    PaywallTestButton(
                        title: "Senaryo 1: Onboarding Complete",
                        subtitle: "Superwall: onboarding_complete",
                        color: .blue
                    ) {
                        paywallManager.presentPaywall(trigger: .onboardingComplete)
                    }
                    
                    PaywallTestButton(
                        title: "Senaryo 2: Premium Feature",
                        subtitle: "Superwall: feature_paywall",
                        color: .orange
                    ) {
                        paywallManager.presentPaywall(trigger: .premiumFeatureAccess)
                    }
                    
                    PaywallTestButton(
                        title: "Manuel Tetikleme",
                        subtitle: "Superwall: feature_paywall",
                        color: .green
                    ) {
                        paywallManager.presentPaywall(trigger: .manualTrigger)
                    }
                }
                
                Divider()
                
                // Debug Butonları
                VStack(spacing: 12) {
                    Button("Paywall Geçmişini Sıfırla") {
                        paywallManager.resetPaywallHistory()
                    }
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    
                    Button("Offerings'leri Yenile") {
                        Task {
                            await revenueCatManager.fetchOfferings()
                        }
                    }
                    .foregroundColor(.purple)
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Premium Status
                VStack {
                    Text("Premium Status:")
                    Text(revenueCatManager.userState == .premium ? "Premium ✅" : "Free 🆓")
                        .fontWeight(.bold)
                        .foregroundColor(revenueCatManager.userState == .premium ? .green : .orange)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("Paywall Test")
            .managePaywalls() // PaywallManager entegrasyonu
        }
    }
}

struct PaywallTestButton: View {
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(color)
            .cornerRadius(12)
        }
    }
}

#Preview {
    PaywallTestView()
        .environmentObject(RevenueCatManager.shared)
} 
