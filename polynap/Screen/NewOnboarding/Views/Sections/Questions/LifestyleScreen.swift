import SwiftUI

struct LifestyleScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .alarm,
            question: L("newOnboarding.lifestyle.question", table: "Onboarding"),
            microcopy: L("newOnboarding.lifestyle.microcopy", table: "Onboarding")
        ) {
            OBSelectionCard(emoji: "🏋️", text: L("newOnboarding.lifestyle.option.veryActive", table: "Onboarding"), isSelected: viewModel.lifestyle == .veryActive) {
                viewModel.lifestyle = .veryActive
            }
            OBSelectionCard(emoji: "🚶", text: L("newOnboarding.lifestyle.option.moderatelyActive", table: "Onboarding"), isSelected: viewModel.lifestyle == .moderatelyActive) {
                viewModel.lifestyle = .moderatelyActive
            }
            OBSelectionCard(emoji: "🧘", text: L("newOnboarding.lifestyle.option.calm", table: "Onboarding"), isSelected: viewModel.lifestyle == .calm) {
                viewModel.lifestyle = .calm
            }
        }
    }
}

#Preview {
    LifestyleScreen(viewModel: NewOnboardingViewModel())
}
