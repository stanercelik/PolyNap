import SwiftUI

struct HealthStatusScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .sleepingNormal,
            question: L("newOnboarding.healthStatus.question", table: "Onboarding"),
            microcopy: L("newOnboarding.healthStatus.microcopy", table: "Onboarding")
        ) {
            OBSelectionCard(emoji: "✅", text: L("newOnboarding.healthStatus.option.healthy", table: "Onboarding"), isSelected: viewModel.healthStatus == .healthy) {
                viewModel.healthStatus = .healthy
            }
            OBSelectionCard(emoji: "💊", text: L("newOnboarding.healthStatus.option.managedConditions", table: "Onboarding"), isSelected: viewModel.healthStatus == .managedConditions) {
                viewModel.healthStatus = .managedConditions
            }
            OBSelectionCard(emoji: "🏥", text: L("newOnboarding.healthStatus.option.seriousConditions", table: "Onboarding"), isSelected: viewModel.healthStatus == .seriousConditions) {
                viewModel.healthStatus = .seriousConditions
            }
        }
    }
}

#Preview {
    HealthStatusScreen(viewModel: NewOnboardingViewModel())
}
