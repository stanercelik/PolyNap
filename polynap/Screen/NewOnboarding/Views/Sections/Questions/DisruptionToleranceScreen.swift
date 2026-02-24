import SwiftUI

struct DisruptionToleranceScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .alarm,
            question: "uyku düzenin bozulduğunda nasıl etkilenirsin?",
            microcopy: "toparlama stratejini buraya göre ayarlıyorum"
        ) {
            OBSelectionCard(emoji: "🥺", text: "çok etkilenirim — günüm gider", isSelected: viewModel.disruptionTolerance == .verySensitive) {
                viewModel.disruptionTolerance = .verySensitive
            }
            OBSelectionCard(emoji: "😐", text: "idare ederim — zorlanırım ama geçer", isSelected: viewModel.disruptionTolerance == .somewhatSensitive) {
                viewModel.disruptionTolerance = .somewhatSensitive
            }
            OBSelectionCard(emoji: "💪", text: "çok etkilenmem — hızlı toparlıyorum", isSelected: viewModel.disruptionTolerance == .notSensitive) {
                viewModel.disruptionTolerance = .notSensitive
            }
        }
    }
}

#Preview {
    DisruptionToleranceScreen(viewModel: NewOnboardingViewModel())
}
