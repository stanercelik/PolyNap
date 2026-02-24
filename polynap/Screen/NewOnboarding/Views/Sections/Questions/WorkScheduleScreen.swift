import SwiftUI

struct WorkScheduleScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .alarm,
            question: "günlük programın nasıl?",
            microcopy: "planı takviminle kavga ettirmeyeceğim"
        ) {
            OBSelectionCard(emoji: "🔄", text: "esnek — saatlerimi ayarlayabilirim", isSelected: viewModel.workSchedule == .flexible) {
                viewModel.workSchedule = .flexible
            }
            OBSelectionCard(emoji: "📅", text: "düzenli — her gün sabit mesai", isSelected: viewModel.workSchedule == .regular) {
                viewModel.workSchedule = .regular
            }
            OBSelectionCard(emoji: "🌙", text: "vardiyalı — gündüz/gece değişiyor", isSelected: viewModel.workSchedule == .shift) {
                viewModel.workSchedule = .shift
            }
            OBSelectionCard(emoji: "🎲", text: "düzensiz — sürekli farklı", isSelected: viewModel.workSchedule == .irregular) {
                viewModel.workSchedule = .irregular
            }
        }
    }
}

#Preview {
    WorkScheduleScreen(viewModel: NewOnboardingViewModel())
}
