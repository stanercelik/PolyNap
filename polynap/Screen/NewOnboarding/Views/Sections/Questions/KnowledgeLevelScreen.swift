import SwiftUI

struct KnowledgeLevelScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .meditation,
            question: L("newOnboarding.knowledgeLevel.question", table: "Onboarding"),
            microcopy: L("newOnboarding.knowledgeLevel.microcopy", table: "Onboarding")
        ) {
            OBSelectionCard(emoji: "🌱", text: L("newOnboarding.knowledgeLevel.option.beginner", table: "Onboarding"), isSelected: viewModel.knowledgeLevel == .beginner) {
                viewModel.knowledgeLevel = .beginner
            }
            OBSelectionCard(emoji: "😊", text: L("newOnboarding.knowledgeLevel.option.intermediate", table: "Onboarding"), isSelected: viewModel.knowledgeLevel == .intermediate) {
                viewModel.knowledgeLevel = .intermediate
            }
            OBSelectionCard(emoji: "🌟", text: L("newOnboarding.knowledgeLevel.option.advanced", table: "Onboarding"), isSelected: viewModel.knowledgeLevel == .advanced) {
                viewModel.knowledgeLevel = .advanced
            }
        }
    }
}

#Preview {
    KnowledgeLevelScreen(viewModel: NewOnboardingViewModel())
}
