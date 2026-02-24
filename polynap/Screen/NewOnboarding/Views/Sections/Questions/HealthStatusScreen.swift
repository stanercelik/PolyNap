import SwiftUI

struct HealthStatusScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        QuestionScreenLayout(
            viewModel: viewModel,
            nimmy: .sleepingNormal,
            question: "sağlık durumun?",
            microcopy: "en uygun ve güvenli planı seçmek için soruyorum"
        ) {
            OBSelectionCard(emoji: "✅", text: "sağlıklıyım", isSelected: viewModel.healthStatus == .healthy) {
                viewModel.healthStatus = .healthy
            }
            OBSelectionCard(emoji: "💊", text: "kontrol altında kronik bir durumum var", isSelected: viewModel.healthStatus == .managedConditions) {
                viewModel.healthStatus = .managedConditions
            }
            OBSelectionCard(emoji: "🏥", text: "aktif tedavi gerektiren bir durumum var", isSelected: viewModel.healthStatus == .seriousConditions) {
                viewModel.healthStatus = .seriousConditions
            }
        }
    }
}

#Preview {
    HealthStatusScreen(viewModel: NewOnboardingViewModel())
}
