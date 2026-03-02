import SwiftUI

struct NotificationPromptScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(OBColors.accentBlue)
            Text(L("newOnboarding.notificationPrompt.loading", table: "Onboarding"))
                .font(OBFont.caption)
                .foregroundColor(OBColors.textMuted)
                .padding(.top, OBSpacing.sm)
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.goToNext()
            }
        }
    }
}

#Preview {
    NotificationPromptScreen(viewModel: NewOnboardingViewModel())
}
