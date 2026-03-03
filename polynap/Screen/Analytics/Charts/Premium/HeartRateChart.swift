import SwiftUI
import Charts

// MARK: - Heart Rate Chart (Premium + HealthKit)
struct HeartRateChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var selectedDataPoint: DailyHeartRateData?
    @State private var tooltipPosition: CGPoint = .zero
    
    var body: some View {
        Chart {
            ForEach(viewModel.heartRateData) { data in
                // Min-Max aralığı (alan)
                AreaMark(
                    x: .value("Tarih", data.date, unit: .day),
                    yStart: .value("Min", data.minBPM),
                    yEnd: .value("Max", data.maxBPM)
                )
                .foregroundStyle(Color.red.opacity(0.12))
                .interpolationMethod(.catmullRom)
                
                // Ortalama BPM çizgisi
                LineMark(
                    x: .value("Tarih", data.date, unit: .day),
                    y: .value("Ort", data.averageBPM)
                )
                .foregroundStyle(Color.red.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
                
                // Dinlenme kalp hızı
                if let resting = data.restingBPM {
                    LineMark(
                        x: .value("Tarih", data.date, unit: .day),
                        y: .value("Dinlenme", resting)
                    )
                    .foregroundStyle(Color.pink.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    .interpolationMethod(.catmullRom)
                }
                
                // Veri noktaları
                PointMark(
                    x: .value("Tarih", data.date, unit: .day),
                    y: .value("Ort", data.averageBPM)
                )
                .foregroundStyle(Color.red)
                .symbolSize(25)
            }
        }
        .chartLegend(position: .bottom, alignment: .center) {
            HStack(spacing: PSSpacing.lg) {
                HStack(spacing: PSSpacing.xs) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 12, height: 12)
                    Text(L("analytics.heartRate.legend.range", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appText)
                }
                HStack(spacing: PSSpacing.xs) {
                    Rectangle()
                        .fill(Color.red.opacity(0.8))
                        .frame(width: 12, height: 2)
                    Text(L("analytics.heartRate.legend.average", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appText)
                }
                HStack(spacing: PSSpacing.xs) {
                    Rectangle()
                        .fill(Color.pink.opacity(0.6))
                        .frame(width: 12, height: 2)
                    Text(L("analytics.heartRate.legend.resting", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appText)
                }
            }
        }
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
                    if let bpm = value.as(Double.self) {
                        Text(String(format: L("analytics.heartRate.bpmUnit", table: "Analytics"), Int(bpm)))
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
                           let matching = viewModel.heartRateData.first(where: {
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
                    let yPos = proxy.position(forY: selected.averageBPM) ?? 0
                    
                    VStack(alignment: .leading, spacing: PSSpacing.xs) {
                        Text(selected.date, style: .date)
                            .font(PSTypography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.appText)
                        Divider()
                        HStack(spacing: PSSpacing.lg) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("analytics.heartRate.tooltip.avg", table: "Analytics"))
                                    .font(PSTypography.caption)
                                    .foregroundColor(.appTextSecondary)
                                Text(String(format: "%.0f bpm", selected.averageBPM))
                                    .font(PSTypography.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("analytics.heartRate.tooltip.range", table: "Analytics"))
                                    .font(PSTypography.caption)
                                    .foregroundColor(.appTextSecondary)
                                Text(String(format: "%.0f-%.0f", selected.minBPM, selected.maxBPM))
                                    .font(PSTypography.caption)
                                    .foregroundColor(.appText)
                            }
                        }
                        if let resting = selected.restingBPM {
                            Text(String(format: L("analytics.heartRate.tooltip.resting", table: "Analytics"), Int(resting)))
                                .font(PSTypography.caption)
                                .foregroundColor(.pink)
                        }
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
}
