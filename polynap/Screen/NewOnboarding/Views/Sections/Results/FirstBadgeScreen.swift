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
                
                FadeInText("ilk rozetin açıldı!", font: OBFont.largeTitle, color: .white, delay: 0.5)
                
                VStack(spacing: -OBSpacing.md){
                    FadeIn(delay: 1.5) {
                        NimmyImage(.meditation, size: 220)
                            .glowEffect(color: .white.opacity(0.75), radius: 30)
                    }
                    
                    FadeInText("starter nimmy", font: OBFont.title, color: .white, delay: 2.5)
                }
                
                Spacer()
                    .frame(height: OBSpacing.xl)
                
                VStack(alignment: .leading, spacing: OBSpacing.md) {
                        FadeInText("onboarding'i bitirdin. bu küçük ama gerçek bir adım.", font: OBFont.body, color: .white.opacity(0.8), delay: 4.5)
                        FadeInText("3 gün düzeni korursan bir sonraki nimmy seni bekliyor.", font: OBFont.body, color: .white.opacity(0.8), delay: 6)
                }
                
                
                
                Spacer()
                
                FadeIn(delay: 7.5) {
                    OBButton("harika →", style: .primaryWhite) {
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
