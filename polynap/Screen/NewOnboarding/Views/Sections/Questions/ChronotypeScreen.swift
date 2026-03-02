import SwiftUI

struct ChronotypeScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .meditation,
            question: L("newOnboarding.chronotype.question", table: "Onboarding"),
            microcopy: L("newOnboarding.chronotype.microcopy", table: "Onboarding")
        ) {
            OBSelectionCard(emoji: "🌅", text: L("newOnboarding.chronotype.option.morningLark", table: "Onboarding"), isSelected: viewModel.chronotype == .morningLark) {
                viewModel.chronotype = .morningLark
            }
            OBSelectionCard(emoji: "🌙", text: L("newOnboarding.chronotype.option.nightOwl", table: "Onboarding"), isSelected: viewModel.chronotype == .nightOwl) {
                viewModel.chronotype = .nightOwl
            }
            OBSelectionCard(emoji: "⚖️", text: L("newOnboarding.chronotype.option.neutral", table: "Onboarding"), isSelected: viewModel.chronotype == .neutral) {
                viewModel.chronotype = .neutral
            }
        }
    }
}

#Preview {
    ChronotypeScreen(viewModel: NewOnboardingViewModel())
}
