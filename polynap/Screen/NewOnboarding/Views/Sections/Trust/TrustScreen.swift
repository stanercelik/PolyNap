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
                        L("newOnboarding.trust.title", table: "Onboarding"),
                        font: OBFont.largeTitle,
                        color: .white,
                        delay: 0.5
                    )
                    
                    FadeInText(
                        L("newOnboarding.trust.subtitle", table: "Onboarding"),
                        font: OBFont.body,
                        color: .white.opacity(0.7),
                        delay: 2.0
                    )
                }
                .multilineTextAlignment(.center)
                
                VStack(spacing: OBSpacing.sm) {
                    FadeIn(delay: 4) {
                        OBIconRow(icon: "🔬", text: L("newOnboarding.trust.row1", table: "Onboarding"))
                    }
                    FadeIn(delay: 5.5) {
                        OBIconRow(icon: "🧠", text: L("newOnboarding.trust.row2", table: "Onboarding"))
                    }
                    FadeIn(delay: 7) {
                        OBIconRow(icon: "🛡️", text: L("newOnboarding.trust.row3", table: "Onboarding"))
                    }
                    FadeIn(delay: 8.5) {
                        OBIconRow(icon: "📚", text: L("newOnboarding.trust.row4", table: "Onboarding"))
                    }
                }
                .padding(.horizontal, OBSpacing.lg)
                
                Spacer()
                
                FadeIn(delay: 10) {
                    VStack(spacing: OBSpacing.sm) {
                        Text(L("newOnboarding.trust.disclaimer", table: "Onboarding"))
                            .font(OBFont.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                        
                        OBButton(L("newOnboarding.common.understood", table: "Onboarding"), style: .primaryWhite) { viewModel.goToNext() }
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
