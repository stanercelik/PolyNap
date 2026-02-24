import SwiftUI

struct SocialObligationsScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .sleepingNormal,
            question: "sosyal hayatın ve rutin yükümlülüklerin ne kadar sabit?",
            microcopy: "esneklik payını ve toparlama planını buna göre yapıyorum"
        ) {
            OBSelectionCard(emoji: "📅", text: "çok fazla — neredeyse her günüm dolu", isSelected: viewModel.socialObligations == .significant) {
                viewModel.socialObligations = .significant
            }
            OBSelectionCard(emoji: "🙂", text: "orta — bazı günler esnekliğim var", isSelected: viewModel.socialObligations == .moderate) {
                viewModel.socialObligations = .moderate
            }
            OBSelectionCard(emoji: "🏖", text: "az — günlük programım büyük ölçüde bende", isSelected: viewModel.socialObligations == .minimal) {
                viewModel.socialObligations = .minimal
            }
        }
    }
}

#Preview {
    SocialObligationsScreen(viewModel: NewOnboardingViewModel())
}
