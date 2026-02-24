import SwiftUI

struct NapEnvironmentScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .sleepingPillow,
            question: "gün içinde kısa uyuyabileceğin bir yerin var mı?",
            microcopy: "nap sayısını ve süresini buna göre ayarlıyorum"
        ) {
            OBSelectionCard(emoji: "🛏", text: "evet, rahat ortamım var", isSelected: viewModel.napEnvironment == .ideal) {
                viewModel.napEnvironment = .ideal
            }
            OBSelectionCard(emoji: "🛋", text: "biraz var (koltuk, biraz mahremiyet)", isSelected: viewModel.napEnvironment == .suitable) {
                viewModel.napEnvironment = .suitable
            }
            OBSelectionCard(emoji: "🪑", text: "zor ama imkansız değil", isSelected: viewModel.napEnvironment == .limited) {
                viewModel.napEnvironment = .limited
            }
            OBSelectionCard(emoji: "❌", text: "pek yok (gürültülü ya da çok açık alan)", isSelected: viewModel.napEnvironment == .unsuitable) {
                viewModel.napEnvironment = .unsuitable
            }
        }
    }
}

#Preview {
    NapEnvironmentScreen(viewModel: NewOnboardingViewModel())
}
