import SwiftUI

struct QuestionHookScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AutoScrollView {
                VStack(alignment: .leading, spacing: OBSpacing.lg) {
                    FadeInText(
                        "uykunda sorun yok gibi görünüyor ama…",
                        font: OBFont.largeTitle,
                        color: OBColors.textPrimary,
                        delay: 0.5
                    )
                    
                    VStack(alignment: .leading, spacing: OBSpacing.md) {
                        FadeInText("her sabah yine de yorgun uyanıyorsun.", delay: 2)
                        FadeInText("5 dakika daha diyorsun ve bu döngü devam ediyor.", delay: 3.5)
                    }
                }
                .padding(.horizontal, OBSpacing.lg)
                .padding(.top, OBSpacing.xxxl)
            }
            
            Spacer()
            
            FadeIn(delay: 5) {
                TapToContinue("tap to continue →") {
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
