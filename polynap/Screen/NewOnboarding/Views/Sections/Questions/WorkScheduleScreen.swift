import SwiftUI

struct WorkScheduleScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .alarm,
            question: L("newOnboarding.workSchedule.question", table: "Onboarding"),
            microcopy: L("newOnboarding.workSchedule.microcopy", table: "Onboarding")
        ) {
            OBSelectionCard(emoji: "🔄", text: L("newOnboarding.workSchedule.option.flexible", table: "Onboarding"), isSelected: viewModel.workSchedule == .flexible) {
                viewModel.workSchedule = .flexible
            }
            OBSelectionCard(emoji: "📅", text: L("newOnboarding.workSchedule.option.regular", table: "Onboarding"), isSelected: viewModel.workSchedule == .regular) {
                viewModel.workSchedule = .regular
            }
            OBSelectionCard(emoji: "🌙", text: L("newOnboarding.workSchedule.option.shift", table: "Onboarding"), isSelected: viewModel.workSchedule == .shift) {
                viewModel.workSchedule = .shift
            }
            OBSelectionCard(emoji: "🎲", text: L("newOnboarding.workSchedule.option.irregular", table: "Onboarding"), isSelected: viewModel.workSchedule == .irregular) {
                viewModel.workSchedule = .irregular
            }
        }
    }
}

#Preview {
    WorkScheduleScreen(viewModel: NewOnboardingViewModel())
}
