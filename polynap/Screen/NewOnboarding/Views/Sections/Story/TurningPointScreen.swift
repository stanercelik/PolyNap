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
                        "uyku tek parça olmak zorunda değilmiş.",
                        font: OBFont.title,
                        color: .white,
                        delay: 1
                    )
                    
                    FadeInText("bazı insanlar uykuyu gün içinde akıllıca dağıtarak bir ritim kuruyor.", font: OBFont.body, color: .white.opacity(0.8), delay: 3.5)
                    
                    FadeInAttributedText(
                        segments: [
                            (text: "daha az", isHighlight: true),
                            (text: " uyuyorlar ama ", isHighlight: false),
                            (text: "daha dinlenmiş", isHighlight: true),
                            (text: " uyanıyorlar.", isHighlight: false)
                        ],
                        font: OBFont.body,
                        color: .white.opacity(0.8),
                        highlightColor: .accentColor,
                        delay: 5
                    )
                    
                    FadeInAttributedText(
                        segments: [
                            (text: "bunun adı ", isHighlight: false),
                            (text: "polifazik uyku", isHighlight: true)
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
                    OBButton("devam →", style: .primaryWhite) { viewModel.goToNext() }
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
