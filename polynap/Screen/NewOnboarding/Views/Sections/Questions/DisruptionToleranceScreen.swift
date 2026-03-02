import SwiftUI

struct DisruptionToleranceScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .alarm,
            question: L("newOnboarding.disruptionTolerance.question", table: "Onboarding"),
            microcopy: L("newOnboarding.disruptionTolerance.microcopy", table: "Onboarding")
        ) {
            OBSelectionCard(emoji: "🥺", text: L("newOnboarding.disruptionTolerance.option.verySensitive", table: "Onboarding"), isSelected: viewModel.disruptionTolerance == .verySensitive) {
                viewModel.disruptionTolerance = .verySensitive
            }
            OBSelectionCard(emoji: "😐", text: L("newOnboarding.disruptionTolerance.option.somewhatSensitive", table: "Onboarding"), isSelected: viewModel.disruptionTolerance == .somewhatSensitive) {
                viewModel.disruptionTolerance = .somewhatSensitive
            }
            OBSelectionCard(emoji: "💪", text: L("newOnboarding.disruptionTolerance.option.notSensitive", table: "Onboarding"), isSelected: viewModel.disruptionTolerance == .notSensitive) {
                viewModel.disruptionTolerance = .notSensitive
            }
        }
    }
}

#Preview {
    DisruptionToleranceScreen(viewModel: NewOnboardingViewModel())
}
