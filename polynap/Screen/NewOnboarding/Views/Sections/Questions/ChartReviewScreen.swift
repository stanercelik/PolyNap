import SwiftUI

struct ChartReviewScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    @State private var chartProgress: CGFloat = 0
    
    var body: some View {
        ZStack {
            StarsBackground(count: 5, color: .white.opacity(0.2))
            
            VStack(spacing: OBSpacing.lg) {
                Spacer()
                    .frame(height: OBSpacing.xxxl)
                
                FadeInText(
                    "düzen kuranlar genelde şunu fark ediyor:",
                    font: OBFont.title,
                    color: .white,
                    delay: 0.5
                )
                .multilineTextAlignment(.center)
                .padding(.horizontal, OBSpacing.lg)
                
                FadeIn(delay: 2.0) {
                    EnergyStabilityCard(progress: chartProgress)
                }
                .padding(.horizontal, OBSpacing.lg)
                
                FadeIn(delay: 4.0) {
                    Text("temsili grafik — adaptasyon kişiden kişiye değişir")
                        .font(OBFont.small)
                        .foregroundColor(.white.opacity(0.4))
                }
                
                Spacer()
                
                FadeIn(delay: 5.0) {
                    OBButton("ben de hazırım", style: .primaryWhite) { viewModel.goToNext() }
                }
                .padding(.horizontal, OBSpacing.lg)
                .padding(.bottom, OBSpacing.xl)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 2.5)) {
                    chartProgress = 1.0
                }
            }
        }
    }
}

// MARK: - Energy Stability Card

private struct EnergyStabilityCard: View {
    let progress: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Text("gün içi enerji stabilitesi")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(OBColors.textPrimary)
                
                Spacer()
                
                NimmyImage(.sleepingNormal, size: 40)
            }
            
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Circle().fill(OBColors.accentBlue).frame(width: 8, height: 8)
                    Text("planlı ritim")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(OBColors.accentBlue)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(OBColors.warningRed)
                    Text("plansız uyku")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(OBColors.warningRed)
                }
            }
            .padding(.top, -4)
            
            EnergyChartView(progress: progress)
                .frame(height: 200)
            
            HStack {
                Text("bugün")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(OBColors.textSecondary)
                Spacer()
                Text("1 hafta")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(OBColors.textSecondary)
                Spacer()
                Text("2 hafta")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(OBColors.textSecondary)
            }
            .padding(.horizontal, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 10)
        )
    }
}

// MARK: - Energy Chart View

private struct EnergyChartView: View {
    let progress: CGFloat
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let baselineY = size.height * 0.95
            let goodPath = smoothPath(from: stablePoints(in: size))
            let badPath = smoothPath(from: unstablePoints(in: size))
            
            ZStack {
                stableFillPath(in: size, baselineY: baselineY)
                    .fill(
                        LinearGradient(
                            colors: [OBColors.accentBlue.opacity(0.3), OBColors.accentBlue.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: size.width * progress, height: size.height)
                    }
                
                unstableFillPath(in: size, baselineY: baselineY)
                    .fill(OBColors.warningRed.opacity(0.12))
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: size.width * progress, height: size.height)
                    }
                
                goodPath
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [OBColors.accentBlue.opacity(0.4), OBColors.accentBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: OBColors.accentBlue.opacity(0.2), radius: 6, x: 0, y: 2)
                
                badPath
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [OBColors.warningRed.opacity(0.4), OBColors.warningRed],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: OBColors.warningRed.opacity(0.15), radius: 4, x: 0, y: 2)
                
                ForEach(Array(unstableTroughIndices.enumerated()), id: \.offset) { _, idx in
                    let points = unstablePoints(in: size)
                    if idx < points.count {
                        let point = points[idx]
                        if point.x <= size.width * progress {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(OBColors.warningRed)
                                .position(CGPoint(x: point.x, y: point.y - 14))
                        }
                    }
                }
                
                if let stableEnd = stablePoints(in: size).last,
                   stableEnd.x <= size.width * progress {
                    Circle()
                        .fill(OBColors.accentBlue)
                        .frame(width: 10, height: 10)
                        .position(stableEnd)
                }
                
                if let unstableEnd = unstablePoints(in: size).last,
                   unstableEnd.x <= size.width * progress {
                    Circle()
                        .fill(OBColors.warningRed)
                        .frame(width: 10, height: 10)
                        .position(unstableEnd)
                }
                
                if let stableStart = stablePoints(in: size).first,
                   stableStart.x <= size.width * progress {
                    Circle()
                        .stroke(OBColors.accentBlue, lineWidth: 1.5)
                        .frame(width: 10, height: 10)
                        .position(stableStart)
                }
                
                if let unstableStart = unstablePoints(in: size).first,
                   unstableStart.x <= size.width * progress {
                    Circle()
                        .stroke(OBColors.warningRed, lineWidth: 1.5)
                        .frame(width: 10, height: 10)
                        .position(unstableStart)
                }
            }
            .drawingGroup()
        }
    }
    
    private let unstableTroughIndices = [2, 4, 6, 8]
    
    private func stablePoints(in size: CGSize) -> [CGPoint] {
        [
            CGPoint(x: size.width * 0.05, y: size.height * 0.55),
            CGPoint(x: size.width * 0.18, y: size.height * 0.50),
            CGPoint(x: size.width * 0.30, y: size.height * 0.52),
            CGPoint(x: size.width * 0.42, y: size.height * 0.44),
            CGPoint(x: size.width * 0.55, y: size.height * 0.38),
            CGPoint(x: size.width * 0.67, y: size.height * 0.28),
            CGPoint(x: size.width * 0.80, y: size.height * 0.22),
            CGPoint(x: size.width * 0.95, y: size.height * 0.08)
        ]
    }
    
    private func unstablePoints(in size: CGSize) -> [CGPoint] {
        [
            CGPoint(x: size.width * 0.05, y: size.height * 0.65),
            CGPoint(x: size.width * 0.14, y: size.height * 0.58),
            CGPoint(x: size.width * 0.22, y: size.height * 0.78),
            CGPoint(x: size.width * 0.32, y: size.height * 0.55),
            CGPoint(x: size.width * 0.40, y: size.height * 0.75),
            CGPoint(x: size.width * 0.50, y: size.height * 0.60),
            CGPoint(x: size.width * 0.60, y: size.height * 0.82),
            CGPoint(x: size.width * 0.70, y: size.height * 0.62),
            CGPoint(x: size.width * 0.80, y: size.height * 0.78),
            CGPoint(x: size.width * 0.90, y: size.height * 0.68),
            CGPoint(x: size.width * 0.95, y: size.height * 0.80)
        ]
    }
    
    private func stableFillPath(in size: CGSize, baselineY: CGFloat) -> Path {
        let points = stablePoints(in: size)
        var path = smoothPath(from: points)
        guard let first = points.first, let last = points.last else { return path }
        path.addLine(to: CGPoint(x: last.x, y: baselineY))
        path.addLine(to: CGPoint(x: first.x, y: baselineY))
        path.closeSubpath()
        return path
    }
    
    private func unstableFillPath(in size: CGSize, baselineY: CGFloat) -> Path {
        let points = unstablePoints(in: size)
        var path = smoothPath(from: points)
        guard let first = points.first, let last = points.last else { return path }
        path.addLine(to: CGPoint(x: last.x, y: baselineY))
        path.addLine(to: CGPoint(x: first.x, y: baselineY))
        path.closeSubpath()
        return path
    }
    
    private func smoothPath(from points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        path.move(to: points[0])
        
        for index in 0..<(points.count - 1) {
            let p0 = index > 0 ? points[index - 1] : points[index]
            let p1 = points[index]
            let p2 = points[index + 1]
            let p3 = index + 2 < points.count ? points[index + 2] : p2
            
            let control1 = CGPoint(
                x: p1.x + (p2.x - p0.x) / 6,
                y: p1.y + (p2.y - p0.y) / 6
            )
            let control2 = CGPoint(
                x: p2.x - (p3.x - p1.x) / 6,
                y: p2.y - (p3.y - p1.y) / 6
            )
            
            path.addCurve(to: p2, control1: control1, control2: control2)
        }
        
        return path
    }
}

#Preview {
    ChartReviewScreen(viewModel: NewOnboardingViewModel())
        .background(OBColors.darkNavy.ignoresSafeArea())
}
