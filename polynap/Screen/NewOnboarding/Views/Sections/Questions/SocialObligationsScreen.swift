import SwiftUI

struct SocialObligationsScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .sleepingNormal,
            question: L("newOnboarding.socialObligations.question", table: "Onboarding"),
            microcopy: L("newOnboarding.socialObligations.microcopy", table: "Onboarding")
        ) {
            OBSelectionCard(emoji: "📅", text: L("newOnboarding.socialObligations.option.significant", table: "Onboarding"), isSelected: viewModel.socialObligations == .significant) {
                viewModel.socialObligations = .significant
            }
            OBSelectionCard(emoji: "🙂", text: L("newOnboarding.socialObligations.option.moderate", table: "Onboarding"), isSelected: viewModel.socialObligations == .moderate) {
                viewModel.socialObligations = .moderate
            }
            OBSelectionCard(emoji: "🏖", text: L("newOnboarding.socialObligations.option.minimal", table: "Onboarding"), isSelected: viewModel.socialObligations == .minimal) {
                viewModel.socialObligations = .minimal
            }
        }
    }
}

#Preview {
    SocialObligationsScreen(viewModel: NewOnboardingViewModel())
}
