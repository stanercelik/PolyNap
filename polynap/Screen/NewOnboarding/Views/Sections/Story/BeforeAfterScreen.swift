import SwiftUI

struct BeforeAfterScreen_: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    @State private var showAfter = false
    
    var body: some View {
        VStack(spacing: OBSpacing.lg) {
            Spacer()
                .frame(height: OBSpacing.xxxl)
            
            VStack(alignment: .leading, spacing: OBSpacing.md) {
                FadeInText(L("newOnboarding.beforeAfter.line1", table: "Onboarding"), font: OBFont.body, delay: 0.5)
                FadeInText(L("newOnboarding.beforeAfter.line2", table: "Onboarding"), font: OBFont.body, delay: 2.0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            FadeIn(delay: 3.5) {
                HStack(spacing: OBSpacing.md) {
                    VStack(spacing: OBSpacing.sm) {
                        NimmyImage(.tired, size: 130)
                        Text(L("newOnboarding.beforeAfter.labelBefore", table: "Onboarding"))
                            .font(OBFont.captionBold)
                            .foregroundColor(OBColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, OBSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(OBColors.cardGray)
                    )
                    
                    if showAfter {
                        VStack(spacing: OBSpacing.sm) {
                            NimmyImage(.meditation, size: 130)
                            Text(L("newOnboarding.beforeAfter.labelAfter", table: "Onboarding"))
                                .font(OBFont.captionBold)
                                .foregroundColor(OBColors.accentBlue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, OBSpacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(OBColors.accentBlue.opacity(0.1))
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            
            VStack(spacing: OBSpacing.sm) {
                FadeInText(L("newOnboarding.beforeAfter.same", table: "Onboarding"), font: OBFont.title, delay: 6.5)
                FadeInAttributedText(
                    segments: [
                        (text: L("newOnboarding.beforeAfter.justPrefix", table: "Onboarding"), isHighlight: false),
                        (text: L("newOnboarding.beforeAfter.rhythm", table: "Onboarding"), isHighlight: true),
                        (text: L("newOnboarding.beforeAfter.rhythmSuffix", table: "Onboarding"), isHighlight: false)
                    ],
                    font: OBFont.subtitle,
                    color: OBColors.textSecondary,
                    highlightColor: OBColors.primaryColor,
                    delay: 8
                )
            }
            
            Spacer()
            
            FadeIn(delay: 9.5) {
                OBButton(L("newOnboarding.common.continueArrow", table: "Onboarding")) { viewModel.goToNext() }
            }
            .padding(.bottom, OBSpacing.xl)
        }
        .padding(.horizontal, OBSpacing.lg)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showAfter = true
                }
            }
        }
    }
}

#Preview {
    BeforeAfterScreen_(viewModel: NewOnboardingViewModel())
}
