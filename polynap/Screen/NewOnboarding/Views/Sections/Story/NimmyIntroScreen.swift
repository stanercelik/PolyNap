import SwiftUI

struct NimmyIntroScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        ZStack {
            StarsBackground(count: 12, color: .white.opacity(0.5))
            
            VStack(spacing: OBSpacing.lg) {
                Spacer()
                    .frame(height: OBSpacing.xl)
                
                FadeIn(delay: 0.3) {
                    NimmyImage(.meditation, size: 240)
                        .glowEffect(color: .accentColor.opacity(0.4), radius: 30)
                }
                
                
                VStack(alignment: .leading, spacing: OBSpacing.md) {
                    FadeInText(L("newOnboarding.nimmyIntro.title", table: "Onboarding"), font: OBFont.title, color: .white, delay: 1.5)
                    Spacer()
                        .frame(height: OBSpacing.sm)
                    FadeInText(L("newOnboarding.nimmyIntro.subtitle", table: "Onboarding"), font: OBFont.subtitle, color: .accentColor, delay: 3.0)
                    FadeInText(L("newOnboarding.nimmyIntro.line1", table: "Onboarding"), font: OBFont.body, color: .white.opacity(0.8), delay: 4.5)
                    FadeInText(L("newOnboarding.nimmyIntro.line2", table: "Onboarding"), font: OBFont.body, color: .white.opacity(0.8), delay: 5.5)
                    FadeInText(L("newOnboarding.nimmyIntro.line3", table: "Onboarding"), font: OBFont.body, color: .white.opacity(0.8), delay: 6.5)
                    Spacer()
                        .frame(height: OBSpacing.sm)
                    FadeInText(L("newOnboarding.nimmyIntro.turning", table: "Onboarding"), font: OBFont.subtitle, color: .white, delay: 9)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, OBSpacing.lg)
                
                Spacer()
                
                FadeIn(delay: 10.5) {
                    TapToContinue(L("newOnboarding.nimmyIntro.cta", table: "Onboarding"), color: .white) {
                        viewModel.goToNext()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, OBSpacing.lg)
                .padding(.bottom, OBSpacing.xl)
            }
        }
    }
}

#Preview {
    NimmyIntroScreen(viewModel: NewOnboardingViewModel())
        .background(OBColors.darkNavy.ignoresSafeArea())
}
