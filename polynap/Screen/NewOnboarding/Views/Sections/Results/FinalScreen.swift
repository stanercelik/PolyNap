import SwiftUI
import Lottie

struct FinalScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    @State private var showCelebration = false
    
    var body: some View {
        ZStack {
            StarsBackground(count: 12, color: .white.opacity(0.5))
            
            if showCelebration {
                LottieView(animation: .named("celebration"))
                    .playing(loopMode: .playOnce)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            
            VStack(alignment: .center, spacing: OBSpacing.md) {
                Spacer()
                
                FadeIn(delay: 0.5) {
                    NimmyImage(.dance, size: 280)
                        .breathingAnimation(minScale: 0.95, maxScale: 1.05, duration: 2)
                        .glowEffect(color: .white.opacity(0.75), radius: 30)
                        .frame(maxWidth: .infinity)
                }

                    FadeInText(
                        L("newOnboarding.final.title", table: "Onboarding"),
                        font: OBFont.largeTitle,
                        color: .white,
                        delay: 1.5
                    )

                
                Spacer()
                
                FadeIn(delay: 2.0) {
                    OBButton(L("newOnboarding.final.cta", table: "Onboarding"), style: .primaryWhite) {
                        viewModel.goToNext()
                    }
                }
                .padding(.horizontal, OBSpacing.lg)
                .padding(.bottom, OBSpacing.xl)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showCelebration = true
            }
        }
    }
}

#Preview {
    FinalScreen(viewModel: NewOnboardingViewModel())
        .background(OBColors.darkNavy.ignoresSafeArea())
}
