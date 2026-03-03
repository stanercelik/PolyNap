import SwiftUI
import StoreKit

struct FirstBadgeScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        ZStack {
            StarsBackground(count: 10, color: .white.opacity(0.3))

            
            VStack(spacing: OBSpacing.lg) {
                Spacer()
                    .frame(height: OBSpacing.xxxl)
                
                FadeInText(L("newOnboarding.firstBadge.title", table: "Onboarding"), font: OBFont.largeTitle, color: .white, delay: 0.5)
                
                VStack(spacing: -OBSpacing.md){
                    FadeIn(delay: 1.5) {
                        Image("badge-starter")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 220, height: 220)
                            .glowEffect(color: .white.opacity(0.75), radius: 30)
                    }
                    
                    FadeInText(L("newOnboarding.firstBadge.badgeName", table: "Onboarding"), font: OBFont.title, color: .white, delay: 2.5)
                }
                
                Spacer()
                    .frame(height: OBSpacing.xl)
                
                VStack(alignment: .leading, spacing: OBSpacing.md) {
                        FadeInText(L("newOnboarding.firstBadge.line1", table: "Onboarding"), font: OBFont.body, color: .white.opacity(0.8), delay: 4.5)
                        FadeInText(L("newOnboarding.firstBadge.line2", table: "Onboarding"), font: OBFont.body, color: .white.opacity(0.8), delay: 6)
                }
                
                
                
                Spacer()
                
                FadeIn(delay: 7.5) {
                    OBButton(L("newOnboarding.firstBadge.cta", table: "Onboarding"), style: .primaryWhite) {
                        requestNativeRating()
                        viewModel.goToNext()
                    }
                }
                .padding(.bottom, OBSpacing.xl)
            }
            .padding(.horizontal, OBSpacing.lg)
        }
    }
    
    private func requestNativeRating() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

#Preview {
    FirstBadgeScreen(viewModel: NewOnboardingViewModel())
        .background(OBColors.darkNavy.ignoresSafeArea())
}
