import SwiftUI

struct GoalSocialProofScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    @State private var visibleCards: Int = 0
    @State private var showBottom = false
    
    var body: some View {
        ZStack {
            StarsBackground(count: 5, color: .white.opacity(0.3))
            
            VStack(spacing: OBSpacing.lg) {
                
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: OBSpacing.md) {
                        Spacer()
                            .frame(height: OBSpacing.xxl)
                        let cards = viewModel.goalSocialProofCards
                        ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                            socialProofCard(quote: card.quote, author: card.author, rotationDegrees: card.degree)
                                .opacity(visibleCards > index ? 1 : 0)
                                .animation(.easeOut(duration: 0.75).delay(0), value: visibleCards)
                        }
                    }
                    .padding(.horizontal, OBSpacing.lg)
                }
                
                if showBottom {
                    VStack(spacing: OBSpacing.sm) {
                        Text(L("newOnboarding.goalSocialProof.title", table: "Onboarding"))
                            .font(OBFont.title)
                            .foregroundColor(.white)
                            .bold()
                        
                        Text(L("newOnboarding.goalSocialProof.subtitle", table: "Onboarding"))
                            .font(OBFont.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .opacity(showBottom ? 1 : 0)
                    .animation(.easeOut(duration: 0.75), value: showBottom)
                    .padding(.horizontal, OBSpacing.lg)
                }
                
                Spacer()
                
                if showBottom {
                    FadeIn(delay: 1.5) {
                        OBButton(L("newOnboarding.common.continueArrow", table: "Onboarding"), style: .primaryWhite) { viewModel.goToNext() }
                    }
                    .padding(.horizontal, OBSpacing.lg)
                    .padding(.bottom, OBSpacing.xl)
                }
            }
        }
        .onAppear {
            let cards = viewModel.goalSocialProofCards
            for i in 0..<cards.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.2 + 0.5) {
                    withAnimation {
                        visibleCards = i + 1
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(cards.count) * 1.2 + 1.5) {
                withAnimation {
                    showBottom = true
                }
            }
        }
    }
    
    private func socialProofCard(quote: String, author: String, rotationDegrees: Double) -> some View {
        VStack(alignment: .leading, spacing: OBSpacing.sm) {
            Text("\"\(quote)\"")
                .font(OBFont.body)
                .foregroundColor(OBColors.textPrimary)
                .italic()
            
            Text("— \(author)")
                .font(OBFont.caption)
                .foregroundColor(OBColors.textSecondary)
        }
        .padding(OBSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
        .rotationEffect(.degrees(rotationDegrees))
    }
}

#Preview {
    GoalSocialProofScreen(viewModel: NewOnboardingViewModel())
        .background(OBColors.darkNavy.ignoresSafeArea())
}
