import SwiftUI

struct KnowledgeLevelScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .meditation,
            question: "polifazik uyku hakkında ne kadar şey biliyorsun?",
            microcopy: "rehberliği ve içerikleri buna göre ayarlıyorum"
        ) {
            OBSelectionCard(emoji: "🌱", text: "yeni başlıyorum — ne olduğunu az biliyorum", isSelected: viewModel.knowledgeLevel == .beginner) {
                viewModel.knowledgeLevel = .beginner
            }
            OBSelectionCard(emoji: "😊", text: "biraz okudum — mantığını anlıyorum", isSelected: viewModel.knowledgeLevel == .intermediate) {
                viewModel.knowledgeLevel = .intermediate
            }
            OBSelectionCard(emoji: "🌟", text: "iyi biliyorum — detaya girmeyi seviyorum", isSelected: viewModel.knowledgeLevel == .advanced) {
                viewModel.knowledgeLevel = .advanced
            }
        }
    }
}

#Preview {
    KnowledgeLevelScreen(viewModel: NewOnboardingViewModel())
}
