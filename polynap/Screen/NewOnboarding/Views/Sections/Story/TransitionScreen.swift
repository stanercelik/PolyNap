import SwiftUI

struct TransitionScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: OBSpacing.xxxl)
            AutoScrollView {
                VStack(alignment: .leading, spacing: OBSpacing.lg) {
                    FadeInText("tamam,", font: OBFont.largeTitle, delay: 0.5)
                    
                    VStack(alignment: .leading, spacing: OBSpacing.md) {
                        FadeInText("şimdi sana uyan ritmi birlikte bulalım.", delay: 2.0)
                        FadeInText("bunun için birkaç soru soracağım.", delay: 3.5)
                        
                        FadeInAttributedText(
                            segments: [
                                (text: "merak etme senin için ", isHighlight: false),
                                (text: "en iyi", isHighlight: true),
                                (text: " olanı bulacağız", isHighlight: false)
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
                OBButton("hadi başlayalım →") { viewModel.goToNext() }
            }
            .padding(.horizontal, OBSpacing.lg)
            .padding(.bottom, OBSpacing.xl)
        }
    }
}

#Preview {
    TransitionScreen(viewModel: NewOnboardingViewModel())
}
