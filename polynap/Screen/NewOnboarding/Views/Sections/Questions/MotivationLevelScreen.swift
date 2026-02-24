import SwiftUI

struct MotivationLevelScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .alarm,
            question: "bu süreç için ne kadar hazırsın?",
            microcopy: "geçiş temposunu buna göre seçiyorum"
        ) {
            OBSelectionCard(emoji: "🔥", text: "kararlıyım — zorlanmayı kabul ediyorum", isSelected: viewModel.motivationLevel == .high) {
                viewModel.motivationLevel = .high
            }
            OBSelectionCard(emoji: "🌤", text: "orta — denemek istiyorum ama rahat olsun", isSelected: viewModel.motivationLevel == .moderate) {
                viewModel.motivationLevel = .moderate
            }
            OBSelectionCard(emoji: "🐢", text: "yavaş — en az değişimle, nazikçe başlayalım", isSelected: viewModel.motivationLevel == .low) {
                viewModel.motivationLevel = .low
            }
        }
    }
}

#Preview {
    MotivationLevelScreen(viewModel: NewOnboardingViewModel())
}
