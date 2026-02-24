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
                        FadeInText("onboarding'i bitirdin.", font: OBFont.title, delay: 0.5)
                        FadeInText("sana bir şey göstereyim.", font: OBFont.body, color: OBColors.textSecondary, delay: 2)
                        
                        Spacer()
                            .frame(height: OBSpacing.lg)
                        
                        FadeInText("uygulama boyunca ilerledikçe\nnimmy'nin farklı versiyonlarını açıyorsun.", font: OBFont.body, delay: 3.5)
                        FadeInText("bunlara rozet diyoruz.", font: OBFont.body, delay: 5)
                        FadeInText("uyum sağladıkça, tutarlılık gösterdikçe,\nnimmy büyüyor ve değişiyor.", font: OBFont.body, delay: 6.5)
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
                OBButton("ilk rozetimi gör →") { viewModel.goToNext() }
            }
            .padding(.horizontal, OBSpacing.lg)
            .padding(.bottom, OBSpacing.xl)
        }
    }
    
    private var badgeGrid: some View {
        let badges = [
            ("Starter Nimmy", true),
            ("3 Günlük Seri", false),
            ("İlk Haftam", false),
            ("Bounce Back", false),
            ("Focus Nimmy", false),
            ("30 Gün", false)
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
                        Text("🎉 şimdi kazandın!")
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
