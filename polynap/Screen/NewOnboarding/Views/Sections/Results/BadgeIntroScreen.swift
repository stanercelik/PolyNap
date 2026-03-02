import SwiftUI

struct BadgeIntroScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: OBSpacing.lg) {
                    Spacer()
                        .frame(height: OBSpacing.xxxl)
                    
                    VStack(alignment: .leading, spacing: OBSpacing.sm) {
                        FadeInText(L("newOnboarding.badgeIntro.line1", table: "Onboarding"), font: OBFont.title, delay: 0.5)
                        FadeInText(L("newOnboarding.badgeIntro.line2", table: "Onboarding"), font: OBFont.body, color: OBColors.textSecondary, delay: 2)
                        
                        Spacer()
                            .frame(height: OBSpacing.lg)
                        
                        FadeInText(L("newOnboarding.badgeIntro.line3", table: "Onboarding"), font: OBFont.body, delay: 3.5)
                        FadeInText(L("newOnboarding.badgeIntro.line4", table: "Onboarding"), font: OBFont.body, delay: 5)
                        FadeInText(L("newOnboarding.badgeIntro.line5", table: "Onboarding"), font: OBFont.body, delay: 6.5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    FadeIn(delay: 8) {
                        badgeGrid
                    }
                }
                .padding(.horizontal, OBSpacing.lg)
                .padding(.bottom, OBSpacing.lg)
            }
            
            FadeIn(delay: 9.5) {
                OBButton(L("newOnboarding.badgeIntro.cta", table: "Onboarding")) { viewModel.goToNext() }
            }
            .padding(.horizontal, OBSpacing.lg)
            .padding(.bottom, OBSpacing.xl)
        }
    }
    
    private var badgeGrid: some View {
        let badges = [
            (L("newOnboarding.badgeIntro.badge.starterNimmy", table: "Onboarding"), true),
            (L("newOnboarding.badgeIntro.badge.threeDayStreak", table: "Onboarding"), false),
            (L("newOnboarding.badgeIntro.badge.firstWeek", table: "Onboarding"), false),
            (L("newOnboarding.badgeIntro.badge.bounceBack", table: "Onboarding"), false),
            (L("newOnboarding.badgeIntro.badge.focusNimmy", table: "Onboarding"), false),
            (L("newOnboarding.badgeIntro.badge.thirtyDays", table: "Onboarding"), false)
        ]
        
        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: OBSpacing.md) {
            ForEach(Array(badges.enumerated()), id: \.offset) { index, badge in
                VStack(spacing: OBSpacing.xs) {
                    ZStack {
                        Circle()
                            .fill(badge.1 ? OBColors.accentBlue.opacity(0.15) : OBColors.cardGray)
                            .frame(width: 70, height: 70)
                        
                        if badge.1 {
                            NimmyImage(.meditation, size: 45)
                                .glowEffect(color: OBColors.accentBlue, radius: 10)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 20))
                                .foregroundColor(OBColors.textMuted)
                        }
                    }
                    
                    Text(badge.0)
                        .font(OBFont.small)
                        .foregroundColor(badge.1 ? OBColors.textPrimary : OBColors.textMuted)
                        .multilineTextAlignment(.center)
                    
                    if badge.1 {
                        Text(L("newOnboarding.badgeIntro.badge.justEarned", table: "Onboarding"))
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(OBColors.starGold)
                    }
                }
            }
        }
    }
}

#Preview {
    BadgeIntroScreen(viewModel: NewOnboardingViewModel())
}
