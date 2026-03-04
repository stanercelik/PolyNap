import SwiftUI
import Charts

// MARK: - Quality-Consistency Scatter Chart
struct QualityConsistencyScatterChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Binding var selectedDataPoint: QualityConsistencyData?
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        if viewModel.qualityConsistencyData.count < 3 {
            // Minimum 3 veri noktası gerekli
            VStack(spacing: PSSpacing.sm) {
                Image(systemName: "chart.dots.scatter")
                    .font(.system(size: 28))
                    .foregroundColor(.appTextSecondary)
                Text(L("analytics.qualityConsistency.needMoreData", table: "Analytics"))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
        } else {
            scatterContent
        }
    }
    
    private var scatterContent: some View {
        Chart(viewModel.qualityConsistencyData) { data in
            PointMark(
                x: .value(L("analytics.qualityConsistency.deviation", table: "Analytics"), data.consistencyDeviation),
                y: .value(L("analytics.qualityConsistency.quality", table: "Analytics"), data.sleepQuality)
            )
            .foregroundStyle(data.qualityCategory.color)
            .symbolSize(max(30, data.sleepHours * 10))
            .opacity(0.7)
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                ZStack {
                    // Trend çizgisi overlay olarak ekle
                    let trendStartY = viewModel.qualityConsistencyCorrelation.intercept
                    let trendEndY = viewModel.qualityConsistencyCorrelation.intercept + (120 * viewModel.qualityConsistencyCorrelation.slope)
                    
                    Path { path in
                        let startPoint = proxy.position(forX: 0) ?? 0
                        let endPoint = proxy.position(forX: 120) ?? 0
                        let startYPos = proxy.position(forY: trendStartY) ?? 0
                        let endYPos = proxy.position(forY: trendEndY) ?? 0
                        
                        path.move(to: CGPoint(x: startPoint, y: startYPos))
                        path.addLine(to: CGPoint(x: endPoint, y: endYPos))
                    }
                    .stroke(Color.appSecondary.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    
                    // Touch handling
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            let xPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
                            let yPosition = location.y - geometry[proxy.plotAreaFrame].origin.y
                            
                            guard xPosition >= 0, xPosition < proxy.plotAreaSize.width,
                                  yPosition >= 0, yPosition < proxy.plotAreaSize.height else {
                                selectedDataPoint = nil
                                return
                            }
                            
                            let x = proxy.value(atX: xPosition, as: Double.self) ?? 0
                            let y = proxy.value(atY: yPosition, as: Double.self) ?? 0
                            
                            // En yakın noktayı bul
                            let closestPoint = viewModel.qualityConsistencyData.min { data1, data2 in
                                let distance1 = sqrt(pow(data1.consistencyDeviation - x, 2) + pow(data1.sleepQuality - y, 2))
                                let distance2 = sqrt(pow(data2.consistencyDeviation - x, 2) + pow(data2.sleepQuality - y, 2))
                                return distance1 < distance2
                            }
                            
                            if let closestPoint = closestPoint {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDataPoint = closestPoint
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
                        let xPosition = proxy.position(forX: selectedData.consistencyDeviation) ?? 0
                        let yPosition = proxy.position(forY: selectedData.sleepQuality) ?? 0
                        
                        QualityConsistencyTooltip(for: selectedData)
                            .offset(x: xPosition + 150 > geometry.size.width ? xPosition - 150 : xPosition + 10,
                                    y: yPosition - 60 < 0 ? yPosition + 10 : yPosition - 60)
                            .transition(.opacity)
                    }
                }
            }
        }
        .chartLegend(position: .bottom, alignment: .center) {
            HStack(spacing: PSSpacing.lg) {
                ForEach(SleepQualityCategory.allCases, id: \.self) { category in
                    HStack(spacing: PSSpacing.xs) {
                        Circle()
                            .fill(category.color)
                            .frame(width: 8, height: 8)
                        Text(category.localizedTitle)
                            .font(PSTypography.caption)
                            .foregroundColor(.appText)
                    }
                }
            }
        }
        .chartXScale(domain: 0...120)
        .chartYScale(domain: 1...5)
        .chartXAxis {
            AxisMarks(position: .bottom) { value in
                AxisValueLabel {
                    if let deviation = value.as(Double.self) {
                        Text("\(Int(deviation))m")
                            .font(PSTypography.caption)
                    }
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let quality = value.as(Double.self) {
                        Text(String(format: "%.1f", quality))
                            .font(PSTypography.caption)
                    }
                }
                AxisGridLine()
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
    }
} 