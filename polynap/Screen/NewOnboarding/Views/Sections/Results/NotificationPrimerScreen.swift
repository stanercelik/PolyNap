import SwiftUI

struct NotificationPrimerScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: -OBSpacing.lg) {
                FadeIn(delay: 0.5) {
                    NimmyImage(.alarm, size: 240)
                        .frame(maxWidth: .infinity)
                }
                
                
                VStack(spacing: OBSpacing.md) {
                    VStack(alignment: .leading){
                        FadeInText(L("newOnboarding.notificationPrimer.title", table: "Onboarding"), font: OBFont.title, delay: 1.5)
                    }
                    
                    FadeIn(delay: 3) {
                        stepCard("📋", L("newOnboarding.notificationPrimer.step1Title", table: "Onboarding"), L("newOnboarding.notificationPrimer.step1Desc", table: "Onboarding"))
                    }
                    FadeIn(delay: 4.5) {
                        stepCard("⏰", L("newOnboarding.notificationPrimer.step2Title", table: "Onboarding"), L("newOnboarding.notificationPrimer.step2Desc", table: "Onboarding"))
                    }
                    FadeIn(delay: 6) {
                        stepCard("✅", L("newOnboarding.notificationPrimer.step3Title", table: "Onboarding"), L("newOnboarding.notificationPrimer.step3Desc", table: "Onboarding"))
                    }
                    
                    Spacer()
                    
                    FadeIn(delay: 7.5) {
                        Text(L("newOnboarding.notificationPrimer.dismissHint", table: "Onboarding"))
                            .font(OBFont.small)
                            .foregroundColor(OBColors.textMuted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    
                    FadeIn(delay: 7.5) {
                        OBButton(L("newOnboarding.notificationPrimer.cta", table: "Onboarding")) {
                            viewModel.requestNotificationPermission()
                        }
                    }
                }
                
                
            }
            .padding(.horizontal, OBSpacing.lg)
            .padding(.vertical, OBSpacing.xl)
        }
    }
    
    private func stepCard(_ emoji: String, _ title: String, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: OBSpacing.md) {
            Text(emoji)
                .font(.system(size: 32))
                .frame(width: 44)
            
            VStack(alignment: .leading, spacing: OBSpacing.xs) {
                Text(title)
                    .font(OBFont.bodyBold)
                    .foregroundColor(OBColors.textPrimary)
                Text(desc)
                    .font(OBFont.caption)
                    .foregroundColor(OBColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(OBSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(OBColors.cardGray)
        )
    }
}

#Preview {
    NotificationPrimerScreen(viewModel: NewOnboardingViewModel())
}
