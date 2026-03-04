import SwiftUI
import Charts

struct AdherenceScoreChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.sm) {
            Chart(viewModel.adherenceData) { data in
                BarMark(
                    x: .value("Date", data.date, unit: .day),
                    y: .value("Score", data.adherenceScore)
                )
                .foregroundStyle(data.adherenceLevel.color.gradient)
                .cornerRadius(4)
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.appTextSecondary.opacity(0.3))
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)%")
                                .font(.system(size: 10))
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date.formatted(.dateTime.weekday(.narrow)))
                                .font(.system(size: 10))
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                }
            }
            .frame(height: 160)
            
            // Legend
            HStack(spacing: PSSpacing.md) {
                LegendDot(color: .green, label: L("analytics.adherence.excellent", table: "Analytics"))
                LegendDot(color: .blue, label: L("analytics.adherence.good", table: "Analytics"))
                LegendDot(color: .orange, label: L("analytics.adherence.fair", table: "Analytics"))
                LegendDot(color: .red, label: L("analytics.adherence.poor", table: "Analytics"))
            }
            .font(PSTypography.caption)
        }
    }
}

private struct LegendDot: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.appTextSecondary)
        }
    }
}
