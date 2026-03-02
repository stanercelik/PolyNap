import SwiftUI
import Charts

// MARK: - Sleep Trend Chart
struct SleepTrendChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Binding var selectedTrendDataPoint: SleepTrendData?
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        Chart {
            ForEach(viewModel.sleepTrendData) { day in
                // Alanı göstermek için alan işaretleyici
                AreaMark(
                    x: .value("Tarih", day.date, unit: .day),
                    y: .value("Saat", day.totalHours)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [Color("PrimaryColor").opacity(0.7), Color("PrimaryColor").opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                // Çizgi
                LineMark(
                    x: .value("Tarih", day.date, unit: .day),
                    y: .value("Saat", day.totalHours)
                )
                .foregroundStyle(Color("PrimaryColor"))
                .lineStyle(StrokeStyle(lineWidth: 3))
                .interpolationMethod(.catmullRom)
                
                // Noktalar (sadece veri olan günler için)
                if day.totalHours > 0 {
                    PointMark(
                        x: .value("Tarih", day.date, unit: .day),
                        y: .value("Saat", day.totalHours)
                    )
                    .foregroundStyle(Color("PrimaryColor"))
                    .symbolSize(30)
                }
            }
            
            // Hedef uyku süresi - referans çizgisi
            RuleMark(y: .value("Hedef", 8))
                .foregroundStyle(Color.gray.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .annotation(position: .top, alignment: .trailing) {
                    Text(L("analytics.totalSleepTrend.goal", table: "Analytics"))
                        .font(.system(size: 12))
                        .foregroundColor(Color("SecondaryTextColor"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color("CardBackground").opacity(0.8))
                        .cornerRadius(4)
                }
        }
        .chartYScale(domain: {
            let maxValue = viewModel.sleepTrendData.compactMap { $0.totalHours.isNaN || $0.totalHours.isInfinite ? nil : $0.totalHours }.max() ?? 8
            let upperBound = max(8, maxValue) + 1
            return 0...max(1, upperBound) // En az 1 saat domain garantisi
        }())
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: ChartFormatUtils.getXAxisStride(for: viewModel.selectedTimeRange))) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: ChartFormatUtils.getDateFormat(for: viewModel.selectedTimeRange))
                            .font(.system(size: 11))
                    }
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let hour = value.as(Double.self) {
                        Text(String(format: L("analytics.chart.hoursUnit", table: "Analytics"), Int(hour)))
                            .font(.system(size: 11))
                    }
                }
                AxisGridLine()
            }
        }
        .frame(height: 220) // Sabit boyut
        .frame(maxWidth: .infinity) // Tam genişlik
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { value in
                                // Yalnızca yatay sürükleme tooltip açsın; dikey scroll ile çakışmasın
                                let dx = abs(value.translation.width)
                                let dy = abs(value.translation.height)
                                guard dx > dy else {
                                    selectedTrendDataPoint = nil
                                    return
                                }

                                let location = value.location
                                let xPosition = location.x - geometry[proxy.plotAreaFrame].origin.x

                                guard xPosition >= 0, xPosition < proxy.plotAreaSize.width else {
                                    selectedTrendDataPoint = nil
                                    return
                                }

                                if let date = proxy.value(atX: xPosition, as: Date.self),
                                   let matchingDay = viewModel.sleepTrendData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                                    if selectedTrendDataPoint?.id != matchingDay.id {
                                        withAnimation(.easeInOut(duration: 0.1)) {
                                            selectedTrendDataPoint = matchingDay
                                            tooltipPosition = location
                                        }
                                    }
                                }
                            }
                            .onEnded { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedTrendDataPoint = nil
                                    }
                                }
                            }
                    )
                
                // Tooltip gösterimi
                if let selectedDay = selectedTrendDataPoint {
                    let xPosition = proxy.position(forX: selectedDay.date) ?? 0
                    
                    TotalSleepTooltip(for: selectedDay)
                        .offset(x: xPosition + 120 > geometry.size.width ? xPosition - 120 : xPosition + 10,
                                y: tooltipPosition.y - 70)
                        .transition(.opacity.animation(.easeInOut(duration: 0.1)))
                }
            }
        }
    }
} 