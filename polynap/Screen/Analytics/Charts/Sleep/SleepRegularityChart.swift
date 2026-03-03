import SwiftUI
import Charts

// MARK: - Sleep Regularity Chart (Premium - HealthKit gated)
struct SleepRegularityChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var selectedDataPoint: SleepRegularityData?
    @State private var tooltipPosition: CGPoint = .zero
    
    var body: some View {
        Chart {
            ForEach(viewModel.sleepRegularityData) { data in
                // Düzenlilik skoru bar chart
                BarMark(
                    x: .value("Tarih", data.date, unit: .day),
                    y: .value("Skor", data.score)
                )
                .foregroundStyle(barColor(for: data.score))
                .cornerRadius(PSCornerRadius.small)
            }
            
            // Hedef düzenlilik çizgisi
            RuleMark(y: .value("Hedef", 80))
                .foregroundStyle(Color.appSecondary.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .annotation(position: .top, alignment: .trailing) {
                    Text(L("analytics.sleepRegularity.target", table: "Analytics"))
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
                        Text("\(Int(score))%")
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
                           let matching = viewModel.sleepRegularityData.first(where: {
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
                    let yPos = proxy.position(forY: selected.score) ?? 0
                    
                    VStack(alignment: .leading, spacing: PSSpacing.xs) {
                        Text(selected.date, style: .date)
                            .font(PSTypography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.appText)
                        Divider()
                        Text(String(format: L("analytics.sleepRegularity.tooltip.score", table: "Analytics"), Int(selected.score)))
                            .font(PSTypography.body)
                            .foregroundColor(barColor(for: selected.score))
                        Text(String(format: L("analytics.sleepRegularity.tooltip.deviation", table: "Analytics"), Int(selected.deviationMinutes)))
                            .font(PSTypography.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    .padding(PSSpacing.sm)
                    .background(Color.appCardBackground)
                    .cornerRadius(PSCornerRadius.medium)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .fixedSize()
                    .offset(x: xPos + 130 > geometry.size.width ? xPos - 130 : xPos + 10,
                            y: yPos - 60 < 0 ? yPos + 10 : yPos - 60)
                    .transition(.opacity)
                }
            }
        }
    }
    
    private func barColor(for score: Double) -> Color {
        switch score {
        case 80...100: return .appSecondary
        case 60..<80: return .appPrimary
        case 40..<60: return .metricAmber
        default: return .appError
        }
    }
}
