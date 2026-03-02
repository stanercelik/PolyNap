import SwiftUI

struct SleepGoalScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .meditation,
            question: L("newOnboarding.sleepGoal.question", table: "Onboarding"),
            microcopy: L("newOnboarding.sleepGoal.microcopy", table: "Onboarding")
        ) {
            OBSelectionCard(emoji: "⚡", text: L("newOnboarding.sleepGoal.option.moreProductivity", table: "Onboarding"), isSelected: viewModel.sleepGoal == .moreProductivity) {
                viewModel.sleepGoal = .moreProductivity
            }
            OBSelectionCard(emoji: "⚖️", text: L("newOnboarding.sleepGoal.option.balancedLifestyle", table: "Onboarding"), isSelected: viewModel.sleepGoal == .balancedLifestyle) {
                viewModel.sleepGoal = .balancedLifestyle
            }
            OBSelectionCard(emoji: "❤️", text: L("newOnboarding.sleepGoal.option.improveHealth", table: "Onboarding"), isSelected: viewModel.sleepGoal == .improveHealth) {
                viewModel.sleepGoal = .improveHealth
            }
            OBSelectionCard(emoji: "🔭", text: L("newOnboarding.sleepGoal.option.curiosity", table: "Onboarding"), isSelected: viewModel.sleepGoal == .curiosity) {
                viewModel.sleepGoal = .curiosity
            }
        }
    }
}

#Preview {
    SleepGoalScreen(viewModel: NewOnboardingViewModel())
}
