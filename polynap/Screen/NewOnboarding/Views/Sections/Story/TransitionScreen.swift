import SwiftUI

struct TransitionScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: OBSpacing.xxxl)
            AutoScrollView {
                VStack(alignment: .leading, spacing: OBSpacing.lg) {
                    FadeInText(L("newOnboarding.transition.title", table: "Onboarding"), font: OBFont.largeTitle, delay: 0.5)
                    
                    VStack(alignment: .leading, spacing: OBSpacing.md) {
                        FadeInText(L("newOnboarding.transition.line1", table: "Onboarding"), delay: 2.0)
                        FadeInText(L("newOnboarding.transition.line2", table: "Onboarding"), delay: 3.5)
                        
                        FadeInAttributedText(
                            segments: [
                                (text: L("newOnboarding.transition.dontWorryPrefix", table: "Onboarding"), isHighlight: false),
                                (text: L("newOnboarding.transition.best", table: "Onboarding"), isHighlight: true),
                                (text: L("newOnboarding.transition.dontWorrySuffix", table: "Onboarding"), isHighlight: false)
                            ],
                            font: OBFont.body,
                            highlightColor: OBColors.primaryColor,
                            highlightFont: OBFont.bodyBold,
                            delay: 5.0
                        )
                    }
                }
                .padding(.horizontal, OBSpacing.lg)
                .padding(.top, OBSpacing.xxxl)
            }
            
            Spacer()
            
            FadeIn(delay: 6.5) {
                OBButton(L("newOnboarding.transition.cta", table: "Onboarding")) { viewModel.goToNext() }
            }
            .padding(.horizontal, OBSpacing.lg)
            .padding(.bottom, OBSpacing.xl)
        }
    }
}

#Preview {
    TransitionScreen(viewModel: NewOnboardingViewModel())
}
