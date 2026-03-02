import SwiftUI

struct NapEnvironmentInfoScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: OBSpacing.xxxl)
            
            AutoScrollView {
                VStack(alignment: .leading, spacing: OBSpacing.xl) {
                    FadeInText(L("newOnboarding.napEnvironmentInfo.title", table: "Onboarding"), font: OBFont.title, delay: 0.5)
                    
                    VStack(alignment: .leading, spacing: OBSpacing.md) {
                        FadeInText(L("newOnboarding.napEnvironmentInfo.quote", table: "Onboarding"), font: OBFont.body, color: OBColors.textSecondary, delay: 2.0)
                        Spacer()
                            .frame(height: OBSpacing.md)
                        
                        FadeInText(L("newOnboarding.napEnvironmentInfo.line1", table: "Onboarding"), delay: 5)
                        
                        FadeInText(L("newOnboarding.napEnvironmentInfo.line2", table: "Onboarding"), delay: 7.5)
                        
                        FadeInText(L("newOnboarding.napEnvironmentInfo.line3", table: "Onboarding"), delay: 9.5)
                    }
                }
                .padding(.horizontal, OBSpacing.lg)
                .padding(.top, OBSpacing.xl)
            }
            
            Spacer()
            
            FadeIn(delay: 11) {
                OBButton(L("newOnboarding.common.understoodArrow", table: "Onboarding")) { viewModel.goToNext() }
            }
            .padding(.horizontal, OBSpacing.lg)
            .padding(.bottom, OBSpacing.xl)
        }
    }
}

#Preview {
    NapEnvironmentInfoScreen(viewModel: NewOnboardingViewModel())
}
