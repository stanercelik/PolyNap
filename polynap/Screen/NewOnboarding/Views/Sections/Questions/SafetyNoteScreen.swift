import SwiftUI

struct SafetyNoteScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: -32) {
            HStack {
                FadeIn(delay: 0.3) {
                    NimmyImage(.tired, size: 180)
                    
                }
                Spacer()
            }
            .padding(.horizontal, OBSpacing.lg)
            .padding(.top, OBSpacing.md)
            
            AutoScrollView {
                VStack(alignment: .leading, spacing: OBSpacing.xxl) {
                    FadeInText(L("newOnboarding.safetyNote.title", table: "Onboarding"), font: OBFont.title, delay: 0.5)
                    
                    VStack(alignment: .leading, spacing: OBSpacing.lg) {
                        FadeInText(L("newOnboarding.safetyNote.line1", table: "Onboarding"), delay: 2.0)
                        
                        FadeInText(L("newOnboarding.safetyNote.line2", table: "Onboarding"), delay: 3.5)
                        
                        FadeInText(L("newOnboarding.safetyNote.line3", table: "Onboarding"), delay: 5.0)
                    }
                }
                .padding(.horizontal, OBSpacing.lg)
                .padding(.top, OBSpacing.xl)
            }
            
            Spacer()
            
            FadeIn(delay: 6.5) {
                OBButton(L("newOnboarding.safetyNote.cta", table: "Onboarding")) { viewModel.goToNext() }
            }
            .padding(.horizontal, OBSpacing.lg)
            .padding(.bottom, OBSpacing.xl)
        }
    }
}

#Preview {
    SafetyNoteScreen(viewModel: NewOnboardingViewModel())
}
