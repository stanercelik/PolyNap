import SwiftUI

struct ComparisonScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    @State private var showLeft = false
    @State private var showRight = false
    @State private var showBottom = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: OBSpacing.lg) {
                    FadeInText(
                        L("newOnboarding.comparison.title", table: "Onboarding"),
                        font: OBFont.title,
                        delay: 1
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, OBSpacing.xxxl)
                    
                    HStack(alignment: .top, spacing: OBSpacing.sm) {
                        VStack(alignment: .leading, spacing: OBSpacing.md) {
                            Text(L("newOnboarding.comparison.otherApps", table: "Onboarding"))
                                .font(OBFont.captionBold)
                                .foregroundColor(OBColors.textPrimary)
                            
                            VStack(alignment: .leading, spacing: OBSpacing.sm) {
                                comparisonRow("✗", L("newOnboarding.comparison.con1", table: "Onboarding"), isNegative: true)
                                comparisonRow("✗", L("newOnboarding.comparison.con2", table: "Onboarding"), isNegative: true)
                                comparisonRow("✗", L("newOnboarding.comparison.con3", table: "Onboarding"), isNegative: true)
                                comparisonRow("✗", L("newOnboarding.comparison.con4", table: "Onboarding"), isNegative: true)
                            }
                            
                            NimmyImage(.tired, size: 100)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(OBSpacing.md)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(OBColors.cardGray)
                        )
                        .opacity(showLeft ? 1 : 0)
                        .animation(.easeOut(duration: 0.75), value: showLeft)
                        
                        VStack(alignment: .leading, spacing: OBSpacing.md) {
                            Text(L("newOnboarding.comparison.withNimmy", table: "Onboarding"))
                                .font(OBFont.captionBold)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: OBSpacing.sm) {
                                comparisonRow("✓", L("newOnboarding.comparison.pro1", table: "Onboarding"), isNegative: false)
                                comparisonRow("✓", L("newOnboarding.comparison.pro2", table: "Onboarding"), isNegative: false)
                                comparisonRow("✓", L("newOnboarding.comparison.pro3", table: "Onboarding"), isNegative: false)
                                comparisonRow("✓", L("newOnboarding.comparison.pro4", table: "Onboarding"), isNegative: false)
                            }
                            
                            NimmyImage(.dance, size: 100)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(OBSpacing.md)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(OBColors.accentBlue)
                        )
                        .opacity(showRight ? 1 : 0)
                        .animation(.easeOut(duration: 0.75), value: showRight)
                    }
                    
                    if showBottom {
                        Text(L("newOnboarding.comparison.footer", table: "Onboarding"))
                            .font(OBFont.caption)
                            .foregroundColor(OBColors.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, OBSpacing.lg)
                .padding(.bottom, OBSpacing.xxl)
            }
            
            VStack(spacing: 0) {
                if showBottom {
                    OBButton(L("newOnboarding.common.continue", table: "Onboarding")) { viewModel.goToNext() }
                        .padding(.horizontal, OBSpacing.lg)
                        .padding(.vertical, OBSpacing.md)
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showLeft = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation { showRight = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
                withAnimation { showBottom = true }
            }
        }
    }
    
    private func comparisonRow(_ symbol: String, _ text: String, isNegative: Bool) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(symbol)
                .font(OBFont.caption)
                .foregroundColor(isNegative ? OBColors.warningRed : .white)
            Text(text)
                .font(OBFont.small)
                .foregroundColor(isNegative ? OBColors.textSecondary : .white.opacity(0.9))
        }
    }
}

#Preview {
    ComparisonScreen(viewModel: NewOnboardingViewModel())
}
