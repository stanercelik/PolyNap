import SwiftUI

struct TrustScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        ZStack {
            StarsBackground(count: 5, color: .white.opacity(0.2))
            
            VStack(spacing: OBSpacing.lg) {
                Spacer()
                    .frame(height: OBSpacing.xxxl)
                
                VStack(spacing: OBSpacing.md) {
                    FadeInText(
                        "bu plan nereden geliyor?",
                        font: OBFont.largeTitle,
                        color: .white,
                        delay: 0.5
                    )
                    
                    FadeInText(
                        "yıllar içinde birikmiş uyku araştırmaları\nve davranış bilimi prensiplerinden.",
                        font: OBFont.body,
                        color: .white.opacity(0.7),
                        delay: 2.0
                    )
                }
                .multilineTextAlignment(.center)
                
                VStack(spacing: OBSpacing.sm) {
                    FadeIn(delay: 4) {
                        OBIconRow(icon: "🔬", text: "uyku bilimi araştırmaları")
                    }
                    FadeIn(delay: 5.5) {
                        OBIconRow(icon: "🧠", text: "davranış değişikliği & alışkanlık")
                    }
                    FadeIn(delay: 7) {
                        OBIconRow(icon: "🛡️", text: "güvenlik sınırları & esneklik")
                    }
                    FadeIn(delay: 8.5) {
                        OBIconRow(icon: "📚", text: "kaynaklar uygulama içinde açık")
                    }
                }
                .padding(.horizontal, OBSpacing.lg)
                
                Spacer()
                
                FadeIn(delay: 10) {
                    VStack(spacing: OBSpacing.sm) {
                        Text("mucize vaat etmiyoruz.\nsadece bilimle desteklenen, gerçek hayata uyan bir ritim.")
                            .font(OBFont.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                        
                        OBButton("anladım", style: .primaryWhite) { viewModel.goToNext() }
                    }
                }
                .padding(.horizontal, OBSpacing.lg)
                .padding(.bottom, OBSpacing.xl)
            }
        }
    }
}

#Preview {
    TrustScreen(viewModel: NewOnboardingViewModel())
        .background(OBColors.darkNavy.ignoresSafeArea())
}
