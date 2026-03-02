import SwiftUI

struct Timeline24hScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    @ObservedObject private var scheduleManager = ScheduleManager.shared
    
    var body: some View {
        VStack(spacing: OBSpacing.lg) {
            FadeInText(L("newOnboarding.timeline24h.title", table: "Onboarding"), font: OBFont.title, delay: 0.3)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            FadeIn(delay: 0.8) {
                circularTimeline
            }
            
            FadeIn(delay: 1.5) {
                blockDetailsList
            }
            
            VStack(alignment: .leading, spacing: OBSpacing.sm) {
                FadeInText(L("newOnboarding.timeline24h.firstWeekGoalPrefix", table: "Onboarding"), delay: 2.0)
                FadeInAttributedText(
                    segments: [
                        (text: L("newOnboarding.timeline24h.firstWeekGoalHighlight", table: "Onboarding"), isHighlight: true),
                        (text: L("newOnboarding.timeline24h.firstWeekGoalSuffix", table: "Onboarding"), isHighlight: false)
                    ],
                    font: OBFont.body,
                    delay: 2.5
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            FadeIn(delay: 3.0) {
                OBButton(L("newOnboarding.common.continueArrow", table: "Onboarding")) { viewModel.goToNext() }
            }
            .padding(.bottom, OBSpacing.xl)
        }
        .padding(.horizontal, OBSpacing.lg)
        .padding(.top, OBSpacing.xl)
    }
    
    // MARK: - Circular Timeline (Canvas-based)
    
    private var circularTimeline: some View {
        let schedule = scheduleManager.activeSchedule
        let blocks = schedule?.schedule ?? []
        let chartSize: CGFloat = 220
        let lineWidth: CGFloat = 24
        let totalSize: CGFloat = chartSize + 40
        
        return VStack(spacing: OBSpacing.md) {
            ZStack {
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let radius = (chartSize - lineWidth) / 2
                    
                    // Background ring
                    var bgPath = Path()
                    bgPath.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360),
                        clockwise: false
                    )
                    context.stroke(
                        bgPath,
                        with: .color(OBColors.softGray.opacity(0.3)),
                        style: StrokeStyle(lineWidth: lineWidth)
                    )
                    
                    // Sleep block arcs
                    for block in blocks {
                        guard let startComponents = TimeFormatter.time(from: block.startTime) else { continue }
                        let startAngle = angleForTime(hour: startComponents.hour, minute: startComponents.minute)
                        let durationHours = Double(block.duration) / 60.0
                        let endAngle = startAngle + (durationHours * (360.0 / 24.0))
                        
                        var blockPath = Path()
                        blockPath.addArc(
                            center: center,
                            radius: radius,
                            startAngle: .degrees(startAngle),
                            endAngle: .degrees(endAngle),
                            clockwise: false
                        )
                        
                        let color: Color = block.isCore ? OBColors.darkNavy : OBColors.accentBlue
                        context.stroke(
                            blockPath,
                            with: .color(color),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                    }
                    
                    // Hour tick marks (0, 6, 12, 18)
                    for hour in [0, 6, 12, 18] {
                        let angle = Double(hour) / 24.0 * 360 - 90
                        let outerR = radius + lineWidth / 2 + 2
                        let innerR = radius - lineWidth / 2 - 2
                        
                        let outerPoint = CGPoint(
                            x: center.x + outerR * CGFloat(cos(angle * .pi / 180)),
                            y: center.y + outerR * CGFloat(sin(angle * .pi / 180))
                        )
                        let innerPoint = CGPoint(
                            x: center.x + innerR * CGFloat(cos(angle * .pi / 180)),
                            y: center.y + innerR * CGFloat(sin(angle * .pi / 180))
                        )
                        
                        var tickPath = Path()
                        tickPath.move(to: outerPoint)
                        tickPath.addLine(to: innerPoint)
                        context.stroke(
                            tickPath,
                            with: .color(OBColors.textMuted.opacity(0.5)),
                            style: StrokeStyle(lineWidth: 1.5)
                        )
                        
                        let labelRadius = radius + lineWidth / 2 + 14
                        let labelPoint = CGPoint(
                            x: center.x + labelRadius * CGFloat(cos(angle * .pi / 180)),
                            y: center.y + labelRadius * CGFloat(sin(angle * .pi / 180))
                        )
                        
                        let text = context.resolve(
                            Text(String(format: "%02d", hour))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(OBColors.textMuted)
                        )
                        context.draw(text, at: labelPoint)
                    }
                }
                .frame(width: totalSize, height: totalSize)
                
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", schedule?.displayTotalSleepHours ?? 6.5))
                        .font(OBFont.bigNumber)
                        .foregroundColor(OBColors.textPrimary)
                    Text(L("newOnboarding.timeline24h.unitHour", table: "Onboarding"))
                        .font(OBFont.caption)
                        .foregroundColor(OBColors.textMuted)
                }
            }
            
            HStack(spacing: OBSpacing.lg) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2).fill(OBColors.darkNavy).frame(width: 12, height: 12)
                    Text(L("newOnboarding.timeline24h.labelCore", table: "Onboarding")).font(OBFont.small).foregroundColor(OBColors.textMuted)
                }
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2).fill(OBColors.accentBlue).frame(width: 12, height: 12)
                    Text(L("newOnboarding.timeline24h.labelNap", table: "Onboarding")).font(OBFont.small).foregroundColor(OBColors.textMuted)
                }
            }
        }
    }
    
    // MARK: - Block Details List
    
    private var blockDetailsList: some View {
        let schedule = scheduleManager.activeSchedule
        let blocks = schedule?.schedule ?? []
        
        return VStack(spacing: 6) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                HStack(spacing: 8) {
                    Circle()
                        .fill(block.isCore ? OBColors.darkNavy : OBColors.accentBlue)
                        .frame(width: 8, height: 8)
                    
                    Text(block.isCore ? L("newOnboarding.timeline24h.blockCore", table: "Onboarding") : L("newOnboarding.timeline24h.blockNap", table: "Onboarding"))
                        .font(OBFont.caption)
                        .foregroundColor(OBColors.textSecondary)
                        .frame(width: 36, alignment: .leading)
                    
                    Spacer()
                    
                    Text("\(block.startTime) – \(block.endTime)")
                        .font(OBFont.captionBold)
                        .foregroundColor(OBColors.textPrimary)
                    
                    Text(block.isCore ? String(format: L("newOnboarding.timeline24h.durationHour", table: "Onboarding"), block.duration / 60) : String(format: L("newOnboarding.timeline24h.durationMin", table: "Onboarding"), block.duration))
                        .font(OBFont.small)
                        .foregroundColor(OBColors.textMuted)
                        .frame(width: 50, alignment: .trailing)
                }
            }
        }
        .padding(.horizontal, OBSpacing.md)
        .padding(.vertical, OBSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(OBColors.softGray)
        )
    }
    
    // MARK: - Helpers
    
    private func angleForTime(hour: Int, minute: Int) -> Double {
        let totalMinutes = Double(hour * 60 + minute)
        return (totalMinutes / (24 * 60)) * 360 - 90
    }
}

#Preview {
    Timeline24hScreen(viewModel: NewOnboardingViewModel())
}
