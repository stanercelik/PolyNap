import SwiftUI

struct ChronotypeScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .meditation,
            question: "senin doğan en çok hangisine uygun?",
            microcopy: "şekerleme saatlerini sana en doğal gelen yerlere koyacağım."
        ) {
            OBSelectionCard(emoji: "🌅", text: "sabahçıyım — erken kalkmak zor değil benim için", isSelected: viewModel.chronotype == .morningLark) {
                viewModel.chronotype = .morningLark
            }
            OBSelectionCard(emoji: "🌙", text: "gececiyim — geceleri daha iyi çalışırım", isSelected: viewModel.chronotype == .nightOwl) {
                viewModel.chronotype = .nightOwl
            }
            OBSelectionCard(emoji: "⚖️", text: "ikisi arası — duruma göre değişiyor", isSelected: viewModel.chronotype == .neutral) {
                viewModel.chronotype = .neutral
            }
        }
    }
}

#Preview {
    ChronotypeScreen(viewModel: NewOnboardingViewModel())
}
