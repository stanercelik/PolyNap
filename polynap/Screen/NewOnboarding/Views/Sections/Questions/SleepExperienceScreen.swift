import SwiftUI

struct SleepExperienceScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .sleepingNormal,
            topLabel: L("newOnboarding.sleepExperience.topLabel", table: "Onboarding"),
            question: String(format: L("newOnboarding.sleepExperience.question", table: "Onboarding"), viewModel.displayName),
            microcopy: L("newOnboarding.sleepExperience.microcopy", table: "Onboarding")
        ) {
            OBSelectionCard(emoji: "😴", text: L("newOnboarding.sleepExperience.option.none", table: "Onboarding"), isSelected: viewModel.previousSleepExperience == .none) {
                viewModel.previousSleepExperience = .none
            }
            OBSelectionCard(emoji: "🙂", text: L("newOnboarding.sleepExperience.option.some", table: "Onboarding"), isSelected: viewModel.previousSleepExperience == .some) {
                viewModel.previousSleepExperience = .some
            }
            OBSelectionCard(emoji: "📅", text: L("newOnboarding.sleepExperience.option.moderate", table: "Onboarding"), isSelected: viewModel.previousSleepExperience == .moderate) {
                viewModel.previousSleepExperience = .moderate
            }
            OBSelectionCard(emoji: "⭐", text: L("newOnboarding.sleepExperience.option.extensive", table: "Onboarding"), isSelected: viewModel.previousSleepExperience == .extensive) {
                viewModel.previousSleepExperience = .extensive
            }
        }
    }
}

#Preview {
    SleepExperienceScreen(viewModel: NewOnboardingViewModel())
}
