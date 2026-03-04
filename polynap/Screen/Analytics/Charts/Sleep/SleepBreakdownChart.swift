import SwiftUI
import Charts

// MARK: - Pie Chart
struct PieChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Binding var selectedPieSlice: SleepBreakdownData?
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        ZStack {
            Chart(viewModel.sleepBreakdownData) { item in
                SectorMark(
                    angle: .value(L("analytics.chart.percentageLabel", table: "Analytics"), item.percentage),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .cornerRadius(5)
                .foregroundStyle(item.color)
                .opacity(selectedPieSlice == nil || selectedPieSlice?.id == item.id ? 1.0 : 0.5)
            }
            .frame(width: 150, height: 150) // Sabit boyut
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle().fill(Color.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let location = value.location
                                    if let selectedItem = ChartDataUtils.findSelectedItem(at: location, proxy: proxy, geometry: geometry, in: viewModel.sleepBreakdownData) {
                                        if selectedPieSlice?.id != selectedItem.id {
                                            withAnimation(.easeInOut(duration: 0.1)) {
                                                selectedPieSlice = selectedItem
                                                tooltipPosition = location
                                            }
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedPieSlice = nil
                                        }
                                    }
                                }
                        )
                }
            }
            
            // Ortalama uyku süresini merkeze yerleştir
            VStack(spacing: 0) {
                Text(String(format: "%.1f", viewModel.averageDailyHours))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.appText)
                
                Text(L("analytics.sleepBreakdown.hoursPerDay", table: "Analytics"))
                    .font(.system(size: 12))
                    .foregroundColor(Color("SecondaryTextColor"))
            }
        }
        .overlay {
            if let selectedSlice = selectedPieSlice {
                PieChartTooltip(for: selectedSlice, selectedTimeRange: viewModel.selectedTimeRange)
                    .offset(x: tooltipPosition.x - 80, y: tooltipPosition.y - 120)
                    .transition(.opacity.animation(.easeInOut(duration: 0.1)))
            }
        }
    }
}

// MARK: - Sleep Breakdown Table
struct SleepBreakdownTable: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.sleepBreakdownData) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(item.color)
                            .frame(width: 16, height: 16)
                            .cornerRadius(4)
                        
                        Text(item.type)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.appText)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            // Yüzde
                            HStack {
                                Text(L("analytics.sleepBreakdown.percentageLabel", table: "Analytics"))
                                    .font(.system(size: 12))
                                    .foregroundColor(Color("SecondaryTextColor"))
                                
                                Text(String(format: L("analytics.sleepBreakdown.percentageValue", table: "Analytics"), item.percentage))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.appText)
                            }
                            
                            // Toplam süre
                            HStack {
                                Text(L("analytics.sleepBreakdown.totalLabel", table: "Analytics"))
                                    .font(.system(size: 12))
                                    .foregroundColor(Color("SecondaryTextColor"))
                                
                                Text(String(format: L("analytics.sleepBreakdown.totalValue", table: "Analytics"), item.hours))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.appText)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            // Günlük ortalama
                            HStack {
                                Text(L("analytics.sleepBreakdown.dailyLabel", table: "Analytics"))
                                    .font(.system(size: 12))
                                    .foregroundColor(Color("SecondaryTextColor"))
                                
                                Text(String(format: L("analytics.sleepBreakdown.dailyValue", table: "Analytics"), item.averagePerDay))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.appText)
                            }
                            
                            // Gün sayısı
                            HStack {
                                Text(L("analytics.sleepBreakdown.daysCountLabel", table: "Analytics"))
                                    .font(.system(size: 12))
                                    .foregroundColor(Color("SecondaryTextColor"))
                                
                                Text("\(item.daysWithThisType)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.appText)
                            }
                        }
                    }
                }
                
                if viewModel.sleepBreakdownData.last?.id != item.id {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
} 