import SwiftUI

struct QuestionHookScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AutoScrollView {
                VStack(alignment: .leading, spacing: OBSpacing.lg) {
                    FadeInText(
                        L("newOnboarding.questionHook.title", table: "Onboarding"),
                        font: OBFont.largeTitle,
                        color: OBColors.textPrimary,
                        delay: 0.5
                    )
                    
                    VStack(alignment: .leading, spacing: OBSpacing.md) {
                        FadeInText(L("newOnboarding.questionHook.line1", table: "Onboarding"), delay: 2)
                        FadeInText(L("newOnboarding.questionHook.line2", table: "Onboarding"), delay: 3.5)
                    }
                }
                .padding(.horizontal, OBSpacing.lg)
                .padding(.top, OBSpacing.xxxl)
            }
            
            Spacer()
            
            FadeIn(delay: 5) {
                TapToContinue(L("newOnboarding.common.tapToContinue", table: "Onboarding")) {
                    viewModel.goToNext()
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, OBSpacing.lg)
            .padding(.bottom, OBSpacing.xl)
        }
    }
}

#Preview {
    QuestionHookScreen(viewModel: NewOnboardingViewModel())
}
