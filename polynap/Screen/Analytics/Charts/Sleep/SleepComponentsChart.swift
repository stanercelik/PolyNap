import SwiftUI
import Charts

// MARK: - Sleep Components Chart
struct SleepComponentsChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Binding var selectedBarDataPoint: SleepTrendData?
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        GeometryReader { geometry in
            Chart {
                // Gösterilecek veri aralığını zaman dilimine göre ayarla
                let displayData = ChartDataUtils.getDisplayData(from: viewModel.sleepTrendData, for: viewModel.selectedTimeRange)
                
                ForEach(displayData) { day in
                    // Ana uyku bloğu
                    BarMark(
                        x: .value(L("analytics.chart.dayLabel", table: "Analytics"), day.date, unit: .day),
                        y: .value("Core", day.coreHours),
                        width: .ratio(0.7),
                        stacking: .standard
                    )
                    .foregroundStyle(Color("AccentColor"))
                    .cornerRadius(4)
                    
                    // Şekerleme 1
                    BarMark(
                        x: .value(L("analytics.chart.dayLabel", table: "Analytics"), day.date, unit: .day),
                        y: .value("Nap 1", day.nap1Hours),
                        stacking: .standard
                    )
                    .foregroundStyle(Color.appPrimary)
                    .cornerRadius(4)
                    
                    // Şekerleme 2
                    BarMark(
                        x: .value(L("analytics.chart.dayLabel", table: "Analytics"), day.date, unit: .day),
                        y: .value("Nap 2", day.nap2Hours),
                        stacking: .standard
                    )
                    .foregroundStyle(Color("SecondaryColor"))
                    .cornerRadius(4)
                    
                    // Uyku skorunu nokta olarak ekle (sadece veri olan günler için)
                    if day.score > 0 {
                        let yValue = day.totalHours + 0.5
                        PointMark(
                            x: .value(L("analytics.chart.dayLabel", table: "Analytics"), day.date, unit: .day),
                            y: .value(L("analytics.chart.scoreLabel", table: "Analytics"), yValue)
                        )
                        .foregroundStyle(.white)
                        .symbolSize(60)
                        
                        PointMark(
                            x: .value(L("analytics.chart.dayLabel", table: "Analytics"), day.date, unit: .day),
                            y: .value(L("analytics.chart.scoreLabel", table: "Analytics"), yValue)
                        )
                        .foregroundStyle(ChartColorUtils.scoreColor(for: day.score))
                        .symbolSize(40)
                    }
                }
            }
            .frame(width: geometry.size.width, height: 220) // Sabit yükseklik, tam genişlik
            .chartForegroundStyleScale([
                L("analytics.sleepComponentsTrend.core", table: "Analytics"): Color("AccentColor"),
                L("analytics.sleepComponentsTrend.nap1", table: "Analytics"): .appPrimary,
                L("analytics.sleepComponentsTrend.nap2", table: "Analytics"): Color("SecondaryColor"),
                L("analytics.chart.sleepScoreLabel", table: "Analytics"): Color.yellow
            ])
            .chartLegend(position: .bottom, alignment: .center, spacing: 10) {
                HStack(spacing: 16) {
                    LegendItem(color: Color("AccentColor"), label: L("analytics.sleepComponentsTrend.core", table: "Analytics"))
                    LegendItem(color: .appPrimary, label: L("analytics.sleepComponentsTrend.nap", table: "Analytics"))
                    
                    Divider().frame(height: 20)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .stroke(Color.yellow, lineWidth: 2)
                            .frame(width: 12, height: 12)
                        Text(L("analytics.sleepComponentsTrend.score", table: "Analytics"))
                            .font(.system(size: 12))
                            .foregroundColor(.appText)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: ChartFormatUtils.getXAxisStrideForComponents(for: viewModel.selectedTimeRange))) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: ChartFormatUtils.getDateFormatForComponents(for: viewModel.selectedTimeRange))
                                .font(.system(size: 11))
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let hour = value.as(Double.self) {
                        AxisValueLabel {
                            Text("\(Int(hour))")
                                .font(.system(size: 11))
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartOverlay { proxy in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let location = value.location
                                let xPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
                                
                                guard xPosition >= 0, xPosition < proxy.plotAreaSize.width else {
                                    selectedBarDataPoint = nil
                                    return
                                }
                                
                                if let date = proxy.value(atX: xPosition, as: Date.self),
                                   let matchingDay = ChartDataUtils.getDisplayData(from: viewModel.sleepTrendData, for: viewModel.selectedTimeRange).min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                                    
                                    if selectedBarDataPoint?.id != matchingDay.id {
                                        withAnimation(.easeInOut(duration: 0.1)) {
                                            selectedBarDataPoint = matchingDay
                                            tooltipPosition = location
                                        }
                                    }
                                }
                            }
                            .onEnded { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedBarDataPoint = nil
                                    }
                                }
                            }
                    )
                
                // Tooltip gösterimi
                if let selectedDay = selectedBarDataPoint {
                    let xPosition = proxy.position(forX: selectedDay.date) ?? 0
                    
                    BarChartTooltip(for: selectedDay)
                        .offset(x: xPosition + 120 > geometry.size.width ? xPosition - 150 : xPosition + 10,
                                y: 50)
                        .transition(.opacity.animation(.easeInOut(duration: 0.1)))
                }
            }
        }
        .frame(height: 280) // Legend için ekstra yükseklik
    }
} 