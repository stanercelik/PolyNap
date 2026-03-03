import SwiftUI
import Charts

// MARK: - HRV Recovery Chart (Premium + HealthKit)
struct HRVRecoveryChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var selectedDataPoint: DailyHRVData?
    @State private var tooltipPosition: CGPoint = .zero
    
    var body: some View {
        Chart {
            ForEach(viewModel.hrvData) { data in
                // Recovery score area (gradient fill)
                AreaMark(
                    x: .value("Tarih", data.date, unit: .day),
                    y: .value("Toparlanma", data.recoveryScore)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [Color.green.opacity(0.5), Color.green.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                // Recovery score line
                LineMark(
                    x: .value("Tarih", data.date, unit: .day),
                    y: .value("Toparlanma", data.recoveryScore)
                )
                .foregroundStyle(Color.green)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
                
                // Data points with color based on score
                PointMark(
                    x: .value("Tarih", data.date, unit: .day),
                    y: .value("Toparlanma", data.recoveryScore)
                )
                .foregroundStyle(recoveryColor(for: data.recoveryScore))
                .symbolSize(35)
            }
            
            // Recovery zone bands
            RuleMark(y: .value("İyi", 75))
                .foregroundStyle(Color.green.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .annotation(position: .top, alignment: .trailing) {
                    Text(L("analytics.hrv.goodZone", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                        .padding(.horizontal, PSSpacing.xs)
                        .padding(.vertical, PSSpacing.xs / 2)
                        .background(Color.appCardBackground.opacity(0.8))
                        .cornerRadius(PSCornerRadius.small)
                }
            
            RuleMark(y: .value("Düşük", 40))
                .foregroundStyle(Color.orange.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .annotation(position: .bottom, alignment: .trailing) {
                    Text(L("analytics.hrv.lowZone", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                        .padding(.horizontal, PSSpacing.xs)
                        .padding(.vertical, PSSpacing.xs / 2)
                        .background(Color.appCardBackground.opacity(0.8))
                        .cornerRadius(PSCornerRadius.small)
                }
        }
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: ChartFormatUtils.getXAxisStride(for: viewModel.selectedTimeRange))) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: ChartFormatUtils.getDateFormat(for: viewModel.selectedTimeRange))
                            .font(PSTypography.caption)
                    }
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let score = value.as(Double.self) {
                        Text("\(Int(score))")
                            .font(PSTypography.caption)
                    }
                }
                AxisGridLine()
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        let xPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
                        guard xPosition >= 0, xPosition < proxy.plotAreaSize.width else {
                            selectedDataPoint = nil
                            return
                        }
                        
                        if let x = proxy.value(atX: xPosition, as: Date.self),
                           let matching = viewModel.hrvData.first(where: {
                               Calendar.current.isDate($0.date, inSameDayAs: x)
                           }) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDataPoint = matching
                                tooltipPosition = location
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDataPoint = nil
                                }
                            }
                        }
                    }
                
                if let selected = selectedDataPoint {
                    let xPos = proxy.position(forX: selected.date) ?? 0
                    let yPos = proxy.position(forY: selected.recoveryScore) ?? 0
                    
                    VStack(alignment: .leading, spacing: PSSpacing.xs) {
                        Text(selected.date, style: .date)
                            .font(PSTypography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.appText)
                        Divider()
                        HStack(spacing: PSSpacing.lg) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("analytics.hrv.tooltip.recovery", table: "Analytics"))
                                    .font(PSTypography.caption)
                                    .foregroundColor(.appTextSecondary)
                                Text(String(format: "%.0f/100", selected.recoveryScore))
                                    .font(PSTypography.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(recoveryColor(for: selected.recoveryScore))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("analytics.hrv.tooltip.sdnn", table: "Analytics"))
                                    .font(PSTypography.caption)
                                    .foregroundColor(.appTextSecondary)
                                Text(String(format: "%.0f ms", selected.averageSDNN))
                                    .font(PSTypography.caption)
                                    .foregroundColor(.appText)
                            }
                        }
                        Text(String(format: L("analytics.hrv.tooltip.range", table: "Analytics"), Int(selected.minSDNN), Int(selected.maxSDNN)))
                            .font(PSTypography.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    .padding(PSSpacing.sm)
                    .background(Color.appCardBackground)
                    .cornerRadius(PSCornerRadius.medium)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .fixedSize()
                    .offset(x: xPos + 160 > geometry.size.width ? xPos - 160 : xPos + 10,
                            y: yPos - 80 < 0 ? yPos + 10 : yPos - 80)
                    .transition(.opacity)
                }
            }
        }
    }
    
    private func recoveryColor(for score: Double) -> Color {
        switch score {
        case 75...100: return .green
        case 50..<75: return .appPrimary
        case 25..<50: return .orange
        default: return .red
        }
    }
}
