import SwiftUI

struct Timeline24hScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    @ObservedObject private var scheduleManager = ScheduleManager.shared

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: OBSpacing.lg) {

                // MARK: Başlık
                FadeInText(
                    L("newOnboarding.timeline24h.title", table: "Onboarding"),
                    font: OBFont.title,
                    delay: 0.3
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                // MARK: Dairesel Grafik
                FadeIn(delay: 0.7) {
                    circularTimeline
                }

                // MARK: Uyku Blokları Listesi
                FadeIn(delay: 1.4) {
                    blockDetailsList
                }

                // MARK: Hafta Hedefi Kartı
                firstWeekGoalCard

                Spacer(minLength: OBSpacing.md)

                FadeIn(delay: 3.2) {
                    OBButton(L("newOnboarding.common.continueArrow", table: "Onboarding")) {
                        viewModel.goToNext()
                    }
                }
                .padding(.bottom, OBSpacing.xl)
            }
            .padding(.horizontal, OBSpacing.lg)
            .padding(.top, OBSpacing.xl)
        }
    }

    // MARK: - Dairesel Zaman Çizelgesi

    private var circularTimeline: some View {
        let schedule = scheduleManager.activeSchedule
        let blocks = schedule?.schedule ?? []
        let chartSize: CGFloat = 234
        let lineWidth: CGFloat = 28
        let totalSize: CGFloat = chartSize + 48

        return VStack(spacing: OBSpacing.md) {
            ZStack {
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let radius = (chartSize - lineWidth) / 2

                    // Arka plan halkası
                    var bgPath = Path()
                    bgPath.addArc(center: center, radius: radius,
                                  startAngle: .degrees(0), endAngle: .degrees(360),
                                  clockwise: false)
                    context.stroke(bgPath,
                                   with: .color(Color.gray.opacity(0.09)),
                                   style: StrokeStyle(lineWidth: lineWidth))

                    // Gece dilimi: 22:00 – 06:00 (hafif navy tonu)
                    let nightStart = angleForTime(hour: 22, minute: 0)
                    let nightEnd = angleForTime(hour: 6, minute: 0) + 360
                    var nightPath = Path()
                    nightPath.addArc(center: center, radius: radius,
                                     startAngle: .degrees(nightStart), endAngle: .degrees(nightEnd),
                                     clockwise: false)
                    context.stroke(nightPath,
                                   with: .color(OBColors.darkNavy.opacity(0.07)),
                                   style: StrokeStyle(lineWidth: lineWidth))

                    // Uyku blokları — önce glow, sonra esas yay
                    for block in blocks {
                        guard let startC = TimeFormatter.time(from: block.startTime) else { continue }
                        let startAngle = angleForTime(hour: startC.hour, minute: startC.minute)
                        let endAngle = startAngle + Double(block.duration) / 60.0 * (360.0 / 24.0)
                        let color: Color = block.isCore ? OBColors.darkNavy : OBColors.accentBlue

                        // Glow katmanı
                        var glowPath = Path()
                        glowPath.addArc(center: center, radius: radius,
                                        startAngle: .degrees(startAngle), endAngle: .degrees(endAngle),
                                        clockwise: false)
                        context.stroke(glowPath,
                                       with: .color(color.opacity(0.18)),
                                       style: StrokeStyle(lineWidth: lineWidth + 10, lineCap: .round))

                        // Ana yay
                        var arcPath = Path()
                        arcPath.addArc(center: center, radius: radius,
                                       startAngle: .degrees(startAngle), endAngle: .degrees(endAngle),
                                       clockwise: false)
                        context.stroke(arcPath,
                                       with: .color(color),
                                       style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    }

                    // Saat işaretleri: 00 · 06 · 12 · 18
                    for hour in [0, 6, 12, 18] {
                        let rad = Double(hour) / 24.0 * 360.0 - 90.0
                        let radRad = rad * .pi / 180.0
                        let outerR = radius + lineWidth / 2 + 4
                        let innerR = radius - lineWidth / 2 - 4

                        var tick = Path()
                        tick.move(to: CGPoint(x: center.x + outerR * cos(radRad),
                                              y: center.y + outerR * sin(radRad)))
                        tick.addLine(to: CGPoint(x: center.x + innerR * cos(radRad),
                                                 y: center.y + innerR * sin(radRad)))
                        context.stroke(tick,
                                       with: .color(OBColors.textMuted.opacity(0.55)),
                                       style: StrokeStyle(lineWidth: 1.5))

                        let labelR = radius + lineWidth / 2 + 18
                        let labelPoint = CGPoint(
                            x: center.x + labelR * cos(radRad),
                            y: center.y + labelR * sin(radRad)
                        )
                        let label = context.resolve(
                            Text(String(format: "%02d", hour))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(OBColors.textMuted)
                        )
                        context.draw(label, at: labelPoint)
                    }
                }
                .frame(width: totalSize, height: totalSize)

                // Merkez: toplam uyku
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", schedule?.displayTotalSleepHours ?? 6.5))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(OBColors.textPrimary)
                    Text(L("newOnboarding.timeline24h.unitHour", table: "Onboarding"))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(OBColors.textMuted)
                        .textCase(.uppercase)
                        .tracking(1)
                }
            }

            // Açıklama etiketleri (legend pills)
            HStack(spacing: OBSpacing.sm) {
                TimelineLegendPill(color: OBColors.darkNavy,
                                   icon: "moon.fill",
                                   label: L("newOnboarding.timeline24h.labelCore", table: "Onboarding"))
                TimelineLegendPill(color: OBColors.accentBlue,
                                   icon: "bolt.fill",
                                   label: L("newOnboarding.timeline24h.labelNap", table: "Onboarding"))
            }
        }
    }

    // MARK: - Uyku Blokları Listesi

    private var blockDetailsList: some View {
        let schedule = scheduleManager.activeSchedule
        let blocks = schedule?.schedule ?? []

        return VStack(spacing: 0) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                TimelineBlockRow(
                    block: block,
                    isLast: index == blocks.count - 1
                )
            }
        }
        .padding(.horizontal, OBSpacing.md)
        .padding(.vertical, OBSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: OBColors.darkNavy.opacity(0.07), radius: 14, x: 0, y: 5)
        )
    }

    // MARK: - Hafta Hedefi Kartı

    private var firstWeekGoalCard: some View {
        HStack(alignment: .top, spacing: OBSpacing.md) {
            ZStack {
                Circle()
                    .fill(OBColors.starGold.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "target")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(OBColors.starGold)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: OBSpacing.xs) {
                FadeInText(
                    L("newOnboarding.timeline24h.firstWeekGoalPrefix", table: "Onboarding"),
                    font: OBFont.captionBold,
                    color: OBColors.textMuted,
                    delay: 2.1
                )
                FadeInAttributedText(
                    segments: [
                        (text: L("newOnboarding.timeline24h.firstWeekGoalHighlight", table: "Onboarding"),
                         isHighlight: true),
                        (text: L("newOnboarding.timeline24h.firstWeekGoalSuffix", table: "Onboarding"),
                         isHighlight: false)
                    ],
                    font: OBFont.body,
                    highlightColor: OBColors.darkNavy,
                    delay: 2.6
                )
            }
        }
        .padding(OBSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(OBColors.starGold.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(OBColors.starGold.opacity(0.25), lineWidth: 1)
                )
        )
    }

    // MARK: - Yardımcı

    private func angleForTime(hour: Int, minute: Int) -> Double {
        (Double(hour * 60 + minute) / 1440.0) * 360.0 - 90.0
    }
}

// MARK: - Legend Pill

private struct TimelineLegendPill: View {
    let color: Color
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(OBFont.small)
                .foregroundColor(OBColors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(color.opacity(0.08))
                .overlay(Capsule().strokeBorder(color.opacity(0.18), lineWidth: 1))
        )
    }
}

// MARK: - Zaman Çizelgesi Blok Satırı

private struct TimelineBlockRow: View {
    let block: SleepBlock
    let isLast: Bool

    var body: some View {
        HStack(alignment: .center, spacing: OBSpacing.md) {

            // İkon + bağlantı çizgisi
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(blockColor.opacity(0.1))
                        .frame(width: 38, height: 38)
                    Image(systemName: block.isCore ? "moon.fill" : "bolt.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(blockColor)
                }

                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [blockColor.opacity(0.2), Color.gray.opacity(0.08)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: 20)
                }
            }

            // Tür + zaman
            VStack(alignment: .leading, spacing: 3) {
                Text(block.isCore
                     ? L("newOnboarding.timeline24h.blockCore", table: "Onboarding")
                     : L("newOnboarding.timeline24h.blockNap", table: "Onboarding"))
                    .font(OBFont.captionBold)
                    .foregroundColor(OBColors.textPrimary)

                Text("\(block.startTime) – \(block.endTime)")
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(OBColors.textSecondary)
            }

            Spacer()

            // Süre rozeti
            Text(durationText)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(blockColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(blockColor.opacity(0.09), in: Capsule())
        }
        .padding(.vertical, 6)
    }

    private var blockColor: Color {
        block.isCore ? OBColors.darkNavy : OBColors.accentBlue
    }

    private var durationText: String {
        block.isCore
            ? String(format: L("newOnboarding.timeline24h.durationHour", table: "Onboarding"), block.duration / 60)
            : String(format: L("newOnboarding.timeline24h.durationMin", table: "Onboarding"), block.duration)
    }
}

#Preview {
    Timeline24hScreen(viewModel: NewOnboardingViewModel())
}
