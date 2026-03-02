import SwiftUI

struct PersonalizedGreetingScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        VStack(spacing: OBSpacing.lg) {
            Spacer()
                .frame(height: OBSpacing.xxxl)
            
            FadeIn(delay: 0.5) {
                NimmyImage(.hello, size: 240)
                    .frame(maxWidth: .infinity)
            }
            
            VStack(spacing: OBSpacing.md) {
                FadeInText(
                    String(format: L("newOnboarding.personalizedGreeting.greeting", table: "Onboarding"), viewModel.displayName),
                    font: OBFont.largeTitle,
                    delay: 2
                )
                
                FadeInText(
                    L("newOnboarding.personalizedGreeting.subtitle", table: "Onboarding"),
                    font: OBFont.body,
                    color: OBColors.textSecondary,
                    delay: 3.5
                )
            }
            
            Spacer()
            
            FadeIn(delay: 5.5) {
                TapToContinue(L("newOnboarding.common.tapToContinue", table: "Onboarding")) {
                    viewModel.goToNext()
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, OBSpacing.lg)
            .padding(.bottom, OBSpacing.xl)
        }
        .padding(.horizontal, OBSpacing.lg)
    }
}

#Preview {
    PersonalizedGreetingScreen(viewModel: NewOnboardingViewModel())
}
