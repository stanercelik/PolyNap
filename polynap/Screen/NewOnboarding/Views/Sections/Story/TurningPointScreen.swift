import SwiftUI

struct TurningPointScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        ZStack {
            StarsBackground(count: 6, color: .white.opacity(0.3))
            
            VStack(alignment: .leading, spacing: OBSpacing.lg) {
                Spacer()
                    .frame(height: OBSpacing.xxxl)
                
                VStack(alignment: .leading, spacing: OBSpacing.md) {
                    FadeInText(
                        L("newOnboarding.turningPoint.line1", table: "Onboarding"),
                        font: OBFont.title,
                        color: .white,
                        delay: 1
                    )
                    
                    FadeInText(L("newOnboarding.turningPoint.line2", table: "Onboarding"), font: OBFont.body, color: .white.opacity(0.8), delay: 3.5)
                    
                    FadeInAttributedText(
                        segments: [
                            (text: L("newOnboarding.turningPoint.lessPrefix", table: "Onboarding"), isHighlight: true),
                            (text: L("newOnboarding.turningPoint.lessSuffix", table: "Onboarding"), isHighlight: false),
                            (text: L("newOnboarding.turningPoint.moreRested", table: "Onboarding"), isHighlight: true),
                            (text: L("newOnboarding.turningPoint.restedSuffix", table: "Onboarding"), isHighlight: false)
                        ],
                        font: OBFont.body,
                        color: .white.opacity(0.8),
                        highlightColor: .accentColor,
                        delay: 5
                    )
                    
                    FadeInAttributedText(
                        segments: [
                            (text: L("newOnboarding.turningPoint.namePrefix", table: "Onboarding"), isHighlight: false),
                            (text: L("newOnboarding.turningPoint.nameHighlight", table: "Onboarding"), isHighlight: true)
                        ],
                        font: OBFont.title,
                        color: .white,
                        highlightColor: .accentColor,
                        delay: 7
                    )
                }
                .padding(.horizontal, OBSpacing.lg)
                
                Spacer()
                
                FadeIn(delay: 8) {
                    OBButton(L("newOnboarding.common.continueArrow", table: "Onboarding"), style: .primaryWhite) { viewModel.goToNext() }
                }
                .padding(.horizontal, OBSpacing.lg)
                .padding(.bottom, OBSpacing.xl)
            }
        }
    }
}

#Preview {
    TurningPointScreen(viewModel: NewOnboardingViewModel())
        .background(OBColors.darkNavy.ignoresSafeArea())
}
