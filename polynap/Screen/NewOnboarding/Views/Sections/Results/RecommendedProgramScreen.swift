import SwiftUI

struct RecommendedProgramScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    @ObservedObject private var scheduleManager = ScheduleManager.shared
    
    var body: some View {
        ZStack {
            StarsBackground(count: 6, color: .white.opacity(0.3))
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: OBSpacing.lg) {
                    FadeIn(delay: 0.2) {
                        NimmyImage(.meditation, size: 80)
                            .glowEffect(color: .white.opacity(0.3), radius: 15)
                    }
                    
                    FadeInText("önerilen planın:", font: OBFont.subtitle, color: .white.opacity(0.7), delay: 0.5)
                    
                    FadeIn(delay: 0.8) {
                        Text(scheduleManager.activeSchedule?.name ?? "Biphasic Sleep")
                            .font(OBFont.heroTitle)
                            .foregroundColor(.white)
                    }
                    
                    FadeIn(delay: 1.3) {
                        programCard
                    }
                    
                    FadeInText(
                        "bu planı ilerleyen günlerde ayarlayabilirsin.\nsadece bir başlangıç noktası.",
                        font: OBFont.caption,
                        color: .white.opacity(0.5),
                        delay: 2.0
                    )
                    .multilineTextAlignment(.center)
                    
                    FadeIn(delay: 2.5) {
                        OBButton("anladım →", style: .primaryWhite) { viewModel.goToNext() }
                    }
                }
                .padding(.horizontal, OBSpacing.lg)
                .padding(.vertical, OBSpacing.xl)
            }
        }
    }
    
    private var programCard: some View {
        VStack(alignment: .leading, spacing: OBSpacing.md) {
            let schedule = scheduleManager.activeSchedule
            let blocks = schedule?.schedule ?? []
            let coreBlocks = blocks.filter { $0.isCore }
            let napBlocks = blocks.filter { !$0.isCore }
            let totalHours = (schedule?.totalSleepHours ?? 6.5)
            
            programRow("🌙", "core uyku", "\(coreBlocks.first.map { "\(Int($0.duration / 60)) saat" } ?? "6 saat")")
            programRow("☀️", "nap sayısı", "\(napBlocks.count)")
            programRow("⏱", "nap süresi", "\(napBlocks.first.map { "\(Int($0.duration)) dk" } ?? "30 dk")")
            programRow("📅", "toplam uyku", String(format: "%.1f saat", totalHours))
            
            Divider().background(Color.gray.opacity(0.2))
            
            VStack(alignment: .leading, spacing: OBSpacing.xs) {
                Text("neden bu plan?")
                    .font(OBFont.captionBold)
                    .foregroundColor(OBColors.textPrimary)
                
                bulletPoint("çalışma düzeninle uyumlu")
                bulletPoint("ortamına göre gerçekçi")
                bulletPoint("kronotipinle örtüşüyor")
            }
        }
        .padding(OBSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
        )
    }
    
    private func programRow(_ emoji: String, _ label: String, _ value: String) -> some View {
        HStack {
            Text(emoji).font(.system(size: 20))
            Text(label).font(OBFont.body).foregroundColor(OBColors.textSecondary)
            Spacer()
            Text(value).font(OBFont.bodyBold).foregroundColor(OBColors.darkNavy)
        }
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•").foregroundColor(OBColors.accentBlue)
            Text(text).font(OBFont.caption).foregroundColor(OBColors.textSecondary)
        }
    }
}

#Preview {
    RecommendedProgramScreen(viewModel: NewOnboardingViewModel())
        .background(OBColors.darkNavy.ignoresSafeArea())
}
