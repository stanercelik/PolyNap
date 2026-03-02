import SwiftUI

struct MotivationLevelScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .alarm,
            question: L("newOnboarding.motivationLevel.question", table: "Onboarding"),
            microcopy: L("newOnboarding.motivationLevel.microcopy", table: "Onboarding")
        ) {
            OBSelectionCard(emoji: "🔥", text: L("newOnboarding.motivationLevel.option.high", table: "Onboarding"), isSelected: viewModel.motivationLevel == .high) {
                viewModel.motivationLevel = .high
            }
            OBSelectionCard(emoji: "🌤", text: L("newOnboarding.motivationLevel.option.moderate", table: "Onboarding"), isSelected: viewModel.motivationLevel == .moderate) {
                viewModel.motivationLevel = .moderate
            }
            OBSelectionCard(emoji: "🐢", text: L("newOnboarding.motivationLevel.option.low", table: "Onboarding"), isSelected: viewModel.motivationLevel == .low) {
                viewModel.motivationLevel = .low
            }
        }
    }
}

#Preview {
    MotivationLevelScreen(viewModel: NewOnboardingViewModel())
}
