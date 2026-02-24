import SwiftUI

struct SplashScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    @State private var showText = false
    @State private var showTap = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [OBColors.primaryColor, OBColors.primaryColor.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                FadeInText("selam",
                           font: OBFont.heroTitle,
                           color: .white,
                           delay: 1)
                
                Spacer()
                
                HStack {
                    Spacer()
                    TapToContinue("tap to continue →", color: .white) {
                        viewModel.goToNext()
                    }
                    .opacity(showTap ? 1 : 0)
                }
                .padding(.horizontal, OBSpacing.lg)
                .padding(.bottom, OBSpacing.xl)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showText = true
            }
            withAnimation(.easeIn(duration: 0.6).delay(1.2)) {
                showTap = true
            }
        }
    }
}

#Preview {
    SplashScreen(viewModel: NewOnboardingViewModel())
}
