import SwiftUI

struct NapEnvironmentScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .sleepingPillow,
            question: L("newOnboarding.napEnvironment.question", table: "Onboarding"),
            microcopy: L("newOnboarding.napEnvironment.microcopy", table: "Onboarding")
        ) {
            OBSelectionCard(emoji: "🛏", text: L("newOnboarding.napEnvironment.option.ideal", table: "Onboarding"), isSelected: viewModel.napEnvironment == .ideal) {
                viewModel.napEnvironment = .ideal
            }
            OBSelectionCard(emoji: "🛋", text: L("newOnboarding.napEnvironment.option.suitable", table: "Onboarding"), isSelected: viewModel.napEnvironment == .suitable) {
                viewModel.napEnvironment = .suitable
            }
            OBSelectionCard(emoji: "🪑", text: L("newOnboarding.napEnvironment.option.limited", table: "Onboarding"), isSelected: viewModel.napEnvironment == .limited) {
                viewModel.napEnvironment = .limited
            }
            OBSelectionCard(emoji: "❌", text: L("newOnboarding.napEnvironment.option.unsuitable", table: "Onboarding"), isSelected: viewModel.napEnvironment == .unsuitable) {
                viewModel.napEnvironment = .unsuitable
            }
        }
    }
}

#Preview {
    NapEnvironmentScreen(viewModel: NewOnboardingViewModel())
}
