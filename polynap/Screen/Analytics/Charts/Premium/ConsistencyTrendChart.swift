import SwiftUI
import Charts

// MARK: - Consistency Trend Chart
struct ConsistencyTrendChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Binding var selectedDataPoint: ConsistencyTrendData?
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        Chart {
            ForEach(viewModel.consistencyTrendData) { data in
                // Tutarlılık skoru çizgisi
                LineMark(
                    x: .value(L("analytics.chart.dayLabel", table: "Analytics"), data.date, unit: .day),
                    y: .value(L("analytics.consistency.description", table: "Analytics"), data.consistencyScore)
                )
                .foregroundStyle(Color.appPrimary)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
                
                // Tutarlılık bandı (± sapma)
                AreaMark(
                    x: .value(L("analytics.chart.dayLabel", table: "Analytics"), data.date, unit: .day),
                    yStart: .value(L("analytics.consistencyTrend.lowerBound", table: "Analytics"), max(0, data.consistencyScore - data.deviation)),
                    yEnd: .value(L("analytics.consistencyTrend.upperBound", table: "Analytics"), min(100, data.consistencyScore + data.deviation))
                )
                .foregroundStyle(Color.appPrimary.opacity(0.2))
                .interpolationMethod(.catmullRom)
                
                // Hedef çizgisi
                RuleMark(y: .value(L("analytics.consistencyTrend.target", table: "Analytics"), 80))
                    .foregroundStyle(Color.appSecondary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text(L("analytics.consistencyTrend.target", table: "Analytics"))
                            .font(PSTypography.caption)
                            .foregroundColor(.appTextSecondary)
                            .padding(.horizontal, PSSpacing.xs)
                            .padding(.vertical, PSSpacing.xs / 2)
                            .background(Color.appCardBackground.opacity(0.8))
                            .cornerRadius(PSCornerRadius.small)
                    }
                
                // Noktalar
                PointMark(
                    x: .value(L("analytics.chart.dayLabel", table: "Analytics"), data.date, unit: .day),
                    y: .value(L("analytics.consistency.description", table: "Analytics"), data.consistencyScore)
                )
                .foregroundStyle(Color.appPrimary)
                .symbolSize(20)
            }
        }
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: ChartFormatUtils.getConsistencyXAxisStride(for: viewModel.selectedTimeRange))) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: ChartFormatUtils.getConsistencyDateFormat(for: viewModel.selectedTimeRange))
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
                        guard let plotFrameAnchor = proxy.plotFrame else {
                            selectedDataPoint = nil
                            return
                        }

                        let plotFrame = geometry[plotFrameAnchor]
                        let xPosition = location.x - plotFrame.origin.x
                        guard xPosition >= 0, xPosition < proxy.plotSize.width else {
                            selectedDataPoint = nil
                            return
                        }
                        
                        let x = proxy.value(atX: xPosition, as: Date.self)
                        
                        if let x = x,
                           let matchingData = viewModel.consistencyTrendData.first(where: { 
                               Calendar.current.isDate($0.date, inSameDayAs: x)
                           }) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDataPoint = matchingData
                                tooltipPosition = location
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDataPoint = nil
                                }
                            }
                        }
                    }
                
                // Tooltip gösterimi
                if let selectedData = selectedDataPoint {
                    let xPosition = proxy.position(forX: selectedData.date) ?? 0
                    let yPosition = proxy.position(forY: selectedData.consistencyScore) ?? 0
                    
                    ConsistencyTrendTooltip(for: selectedData)
                        .offset(x: xPosition + 150 > geometry.size.width ? xPosition - 150 : xPosition + 10,
                                y: yPosition - 60 < 0 ? yPosition + 10 : yPosition - 60)
                        .transition(.opacity)
                }
            }
        }
    }
} 
