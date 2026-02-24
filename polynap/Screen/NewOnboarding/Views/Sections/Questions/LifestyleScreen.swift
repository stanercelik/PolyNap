import SwiftUI

struct LifestyleScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .alarm,
            question: "günlük aktivite tempon?",
            microcopy: "toparlanma ihtiyacı buna göre değişiyor"
        ) {
            OBSelectionCard(emoji: "🏋️", text: "aktifim — düzenli antrenman, fiziksel iş", isSelected: viewModel.lifestyle == .veryActive) {
                viewModel.lifestyle = .veryActive
            }
            OBSelectionCard(emoji: "🚶", text: "orta düzey — yürüyüş, hafif hareket", isSelected: viewModel.lifestyle == .moderatelyActive) {
                viewModel.lifestyle = .moderatelyActive
            }
            OBSelectionCard(emoji: "🧘", text: "sakin — çoğunlukla masa başı", isSelected: viewModel.lifestyle == .calm) {
                viewModel.lifestyle = .calm
            }
        }
    }
}

#Preview {
    LifestyleScreen(viewModel: NewOnboardingViewModel())
}
