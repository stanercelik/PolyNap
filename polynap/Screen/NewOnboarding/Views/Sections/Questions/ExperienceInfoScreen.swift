import SwiftUI

struct ExperienceInfoScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AutoScrollView {
                VStack(alignment: .leading, spacing: OBSpacing.md) {
                    let lines = viewModel.experienceInfoText.components(separatedBy: "\n\n")
                    if let firstLine = lines.first {
                        FadeInText(firstLine, font: OBFont.heroTitle, delay: 0.5)
                    }
                    ForEach(Array(lines.dropFirst().enumerated()), id: \.offset) { index, line in
                        FadeInText(line, delay: Double(index) * 1.2 + 2.0)
                    }
                }
                .padding(.horizontal, OBSpacing.lg)
                .padding(.top, OBSpacing.xxxl)
            }
            
            Spacer()
            
            FadeIn(delay: 5.0) {
                OBButton(L("newOnboarding.common.continueArrow", table: "Onboarding")) { viewModel.goToNext() }
            }
            .padding(.horizontal, OBSpacing.lg)
            .padding(.bottom, OBSpacing.xl)
        }
    }
}

#Preview {
    ExperienceInfoScreen(viewModel: NewOnboardingViewModel())
}
