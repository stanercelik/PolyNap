import SwiftUI

struct OutcomeTimeCalcScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    private var yearlyHours: Int { 3 * 365 }
    private var yearlyDays: Int { yearlyHours / 24 }
    private var lifetimeYears: Int { yearlyDays * 50 / 365 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: OBSpacing.lg) {
            Spacer()
                .frame(height: OBSpacing.xxxl)
            
            AutoScrollView {
                VStack(alignment: .leading, spacing: OBSpacing.lg) {
                    FadeInAttributedText(
                        segments: [
                            (text: L("newOnboarding.outcomeTimeCalc.prefix", table: "Onboarding"), isHighlight: false),
                            (text: L("newOnboarding.outcomeTimeCalc.highlight", table: "Onboarding"), isHighlight: true),
                            (text: L("newOnboarding.outcomeTimeCalc.suffix", table: "Onboarding"), isHighlight: false)
                        ],
                        font: OBFont.subtitle,
                        highlightColor: OBColors.primaryColor,
                        delay: 0.5
                    )
                    
                    VStack(alignment: .leading, spacing: OBSpacing.lg) {
                        FadeInAttributedText(
                            segments: [
                                (text: L("newOnboarding.outcomeTimeCalc.yearlyPrefix", table: "Onboarding"), isHighlight: false),
                                (text: "\(yearlyHours) \(L("newOnboarding.outcomeTimeCalc.yearlySuffix1", table: "Onboarding"))", isHighlight: true),
                                (text: L("newOnboarding.outcomeTimeCalc.yearlyMidfix", table: "Onboarding"), isHighlight: false),
                                (text: "\(yearlyDays) \(L("newOnboarding.outcomeTimeCalc.yearlySuffix2", table: "Onboarding"))", isHighlight: true)
                            ],
                            font: OBFont.subtitle,
                            highlightColor: OBColors.primaryColor,
                            highlightFont: OBFont.title,
                            delay: 2.5
                        )
                        
                        FadeInAttributedText(
                            segments: [
                                (text: L("newOnboarding.outcomeTimeCalc.lifetimePrefix", table: "Onboarding"), isHighlight: false),
                                (text: "\(lifetimeYears) \(L("newOnboarding.outcomeTimeCalc.lifetimeSuffix1", table: "Onboarding"))", isHighlight: true),
                                (text: L("newOnboarding.outcomeTimeCalc.lifetimeSuffix2", table: "Onboarding"), isHighlight: false)
                            ],
                            font: OBFont.subtitle,
                            highlightColor: OBColors.primaryColor,
                            highlightFont: OBFont.title,
                            delay: 4
                        )
                    }
                    Spacer()
                        .frame(height: OBSpacing.lg)
                    
                    FadeInText(
                        L("newOnboarding.outcomeTimeCalc.question", table: "Onboarding"),
                        font: OBFont.subtitle,
                        color: OBColors.textSecondary,
                        delay: 6.0
                    )
                }
                .padding(.horizontal, OBSpacing.lg)
                .padding(.top, OBSpacing.xxxl)
            }
            
            Spacer()
            
            FadeIn(delay: 7.5) {
                OBButton(L("newOnboarding.common.continueArrow", table: "Onboarding")) { viewModel.goToNext() }
            }
            .padding(.horizontal, OBSpacing.lg)
            .padding(.bottom, OBSpacing.xl)
        }
    }
}

#Preview {
    OutcomeTimeCalcScreen(viewModel: NewOnboardingViewModel())
}
