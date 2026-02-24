import SwiftUI

struct NimmyIntroScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        ZStack {
            StarsBackground(count: 12, color: .white.opacity(0.5))
            
            VStack(spacing: OBSpacing.lg) {
                Spacer()
                    .frame(height: OBSpacing.xl)
                
                FadeIn(delay: 0.3) {
                    NimmyImage(.meditation, size: 240)
                        .glowEffect(color: .accentColor.opacity(0.4), radius: 30)
                }
                
                
                VStack(alignment: .leading, spacing: OBSpacing.md) {
                    FadeInText("bu nimmy.", font: OBFont.title, color: .white, delay: 1.5)
                    Spacer()
                        .frame(height: OBSpacing.sm)
                    FadeInText("nimmy de böyleydi.", font: OBFont.subtitle, color: .accentColor, delay: 3.0)
                    FadeInText("nimmy de seninle aynı şeyleri hissetti.", font: OBFont.body, color: .white.opacity(0.8), delay: 4.5)
                    FadeInText("her gece yatıyor,", font: OBFont.body, color: .white.opacity(0.8), delay: 5.5)
                    FadeInText("her sabah yorgun kalkıyordu.", font: OBFont.body, color: .white.opacity(0.8), delay: 6.5)
                    Spacer()
                        .frame(height: OBSpacing.sm)
                    FadeInText("sonra bir şeyi fark etti.", font: OBFont.subtitle, color: .white, delay: 9)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, OBSpacing.lg)
                
                Spacer()
                
                FadeIn(delay: 10.5) {
                    TapToContinue("ne fark etti? →", color: .white) {
                        viewModel.goToNext()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, OBSpacing.lg)
                .padding(.bottom, OBSpacing.xl)
            }
        }
    }
}

#Preview {
    NimmyIntroScreen(viewModel: NewOnboardingViewModel())
        .background(OBColors.darkNavy.ignoresSafeArea())
}
