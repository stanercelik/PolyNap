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
                            (text: "günde 3 hatta ", isHighlight: false),
                            (text: "4 saate kadar", isHighlight: true),
                            (text: " kazanabilirsin.", isHighlight: false)
                        ],
                        font: OBFont.subtitle,
                        highlightColor: OBColors.primaryColor,
                        delay: 0.5
                    )
                    
                    VStack(alignment: .leading, spacing: OBSpacing.lg) {
                        FadeInAttributedText(
                            segments: [
                                (text: "bu, yılda ", isHighlight: false),
                                (text: "\(yearlyHours) saat", isHighlight: true),
                                (text: " yani ", isHighlight: false),
                                (text: "\(yearlyDays) gün", isHighlight: true)
                            ],
                            font: OBFont.subtitle,
                            highlightColor: OBColors.primaryColor,
                            highlightFont: OBFont.title,
                            delay: 2.5
                        )
                        
                        FadeInAttributedText(
                            segments: [
                                (text: "ömrün boyunca ise ", isHighlight: false),
                                (text: "\(lifetimeYears) yıl", isHighlight: true),
                                (text: " eder.", isHighlight: false)
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
                        "peki sen bu kadar zamanın olsa ne yapardın?",
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
                OBButton("devam →") { viewModel.goToNext() }
            }
            .padding(.horizontal, OBSpacing.lg)
            .padding(.bottom, OBSpacing.xl)
        }
    }
}

#Preview {
    OutcomeTimeCalcScreen(viewModel: NewOnboardingViewModel())
}
