import SwiftUI

struct SleepGoalScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .meditation,
            question: "peki en çok ne istiyorsun?",
            microcopy: "planın \"neden\"i buna göre şekilleniyor"
        ) {
            OBSelectionCard(emoji: "⚡", text: "daha fazla üretken zaman", isSelected: viewModel.sleepGoal == .moreProductivity) {
                viewModel.sleepGoal = .moreProductivity
            }
            OBSelectionCard(emoji: "⚖️", text: "daha dengeli, daha az stresli bir gün", isSelected: viewModel.sleepGoal == .balancedLifestyle) {
                viewModel.sleepGoal = .balancedLifestyle
            }
            OBSelectionCard(emoji: "❤️", text: "daha iyi toparlanma ve sağlık", isSelected: viewModel.sleepGoal == .improveHealth) {
                viewModel.sleepGoal = .improveHealth
            }
            OBSelectionCard(emoji: "🔭", text: "merak — nasıl bir şeymiş görmek istiyorum", isSelected: viewModel.sleepGoal == .curiosity) {
                viewModel.sleepGoal = .curiosity
            }
        }
    }
}

#Preview {
    SleepGoalScreen(viewModel: NewOnboardingViewModel())
}
