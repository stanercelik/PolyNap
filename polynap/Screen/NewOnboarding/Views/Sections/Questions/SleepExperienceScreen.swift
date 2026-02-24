import SwiftUI

struct SleepExperienceScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .sleepingNormal,
            topLabel: "nimmy merak ediyor...",
            question: "\(viewModel.displayName), daha önce polifazik uykuyu denemiş miydin?",
            microcopy: "başlangıç hızını buna göre ayarlıyorum"
        ) {
            OBSelectionCard(emoji: "😴", text: "hayır, hiç denemedim", isSelected: viewModel.previousSleepExperience == .none) {
                viewModel.previousSleepExperience = .none
            }
            OBSelectionCard(emoji: "🙂", text: "biraz denedim ama devam edemedim", isSelected: viewModel.previousSleepExperience == .some) {
                viewModel.previousSleepExperience = .some
            }
            OBSelectionCard(emoji: "📅", text: "birkaç aydır uyguluyorum", isSelected: viewModel.previousSleepExperience == .moderate) {
                viewModel.previousSleepExperience = .moderate
            }
            OBSelectionCard(emoji: "⭐", text: "deneyimliyim", isSelected: viewModel.previousSleepExperience == .extensive) {
                viewModel.previousSleepExperience = .extensive
            }
        }
    }
}

#Preview {
    SleepExperienceScreen(viewModel: NewOnboardingViewModel())
}
