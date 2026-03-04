import SwiftUI

// MARK: - Total Sleep Chart (Free Users)
struct AnalyticsTotalSleepChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Binding var selectedTrendDataPoint: SleepTrendData?
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("analytics.trend.title", table: "Analytics"))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(.appText)
            
            VStack(alignment: .leading, spacing: 20) {
                // Sadece Toplam Uyku Süresi Grafiği
                ChartHeader(
                    title: L("analytics.totalSleepTrend.title", table: "Analytics"),
                    subtitle: L("analytics.totalSleepTrend.subtitle", table: "Analytics")
                )
                
                SleepTrendChart(
                    viewModel: viewModel,
                    selectedTrendDataPoint: $selectedTrendDataPoint,
                    tooltipPosition: $tooltipPosition
                )
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - Trend Charts Section
struct AnalyticsTrendCharts: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Binding var selectedTrendDataPoint: SleepTrendData?
    @Binding var selectedBarDataPoint: SleepTrendData?
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("analytics.trend.title", table: "Analytics"))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(.appText)
            
            VStack(alignment: .leading, spacing: 20) {
                // Toplam Uyku Süresi Grafiği
                ChartHeader(
                    title: L("analytics.totalSleepTrend.title", table: "Analytics"),
                    subtitle: L("analytics.totalSleepTrend.subtitle", table: "Analytics")
                )
                
                SleepTrendChart(
                    viewModel: viewModel,
                    selectedTrendDataPoint: $selectedTrendDataPoint,
                    tooltipPosition: $tooltipPosition
                )
                
                // Uyku Bileşenleri Çubuk Grafiği
                ChartHeader(
                    title: L("analytics.sleepComponentsTrend.title", table: "Analytics"),
                    subtitle: L("analytics.sleepComponentsTrend.subtitle", table: "Analytics")
                )
                
                SleepComponentsChart(
                    viewModel: viewModel,
                    selectedBarDataPoint: $selectedBarDataPoint,
                    tooltipPosition: $tooltipPosition
                )
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - Sleep Breakdown Section
struct AnalyticsSleepBreakdown: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Binding var selectedPieSlice: SleepBreakdownData?
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("analytics.sleepBreakdown.title", table: "Analytics"))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(.appText)
            
            VStack(spacing: 20) {
                HStack(alignment: .top, spacing: 20) {
                    // Pasta Grafiği
                    PieChart(
                        viewModel: viewModel,
                        selectedPieSlice: $selectedPieSlice,
                        tooltipPosition: $tooltipPosition
                    )
                    
                    // Detaylı dağılım tablosu
                    SleepBreakdownTable(viewModel: viewModel)
                }
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal)
    }
}

// MARK: - Premium Analytics Sections

// MARK: - Heat Map Section (Actogram)
struct AnalyticsHeatMapSection: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var selectedDay: SleepTrendData?
    @State private var tooltipPosition: CGPoint = .zero
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.lg) {
                PSSectionHeader(
                    L("analytics.heatMap.title", table: "Analytics"),
                    icon: "calendar.badge.clock",
                    subtitle: L("analytics.heatMap.subtitle", table: "Analytics")
                )
                
                SleepHeatMapChart(
                    viewModel: viewModel,
                    selectedDay: $selectedDay,
                    tooltipPosition: $tooltipPosition
                )
                
                // Veri yetersizliği uyarısı
                if viewModel.sleepTrendData.filter({ $0.totalHours > 0 }).count < 7 {
                    PSInfoBox(
                        title: L("analytics.heatMap.insufficientData.title", table: "Analytics"),
                        message: L("analytics.heatMap.insufficientData.message", table: "Analytics"),
                        icon: "exclamationmark.triangle.fill"
                    )
                }
                
                PSInfoBox(
                    title: L("analytics.heatMap.explanation.title", table: "Analytics"),
                    message: L("analytics.heatMap.explanation.message", table: "Analytics"),
                    icon: "info.circle.fill"
                )
            }
        }
        .padding(.horizontal, PSSpacing.lg)
    }
}

// MARK: - Consistency Trend Section
struct AnalyticsConsistencyTrendSection: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var selectedDataPoint: ConsistencyTrendData?
    @State private var tooltipPosition: CGPoint = .zero
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.lg) {
                PSSectionHeader(
                    L("analytics.consistencyTrend.title", table: "Analytics"),
                    icon: "waveform.path.ecg",
                    subtitle: L("analytics.consistencyTrend.subtitle", table: "Analytics")
                )
                
                ConsistencyTrendChart(
                    viewModel: viewModel,
                    selectedDataPoint: $selectedDataPoint,
                    tooltipPosition: $tooltipPosition
                )
                
                PSInfoBox(
                    title: L("analytics.consistencyTrend.explanation.title", table: "Analytics"),
                    message: L("analytics.consistencyTrend.explanation.message", table: "Analytics"),
                    icon: "lightbulb.fill"
                )
            }
        }
        .padding(.horizontal, PSSpacing.lg)
    }
}

// MARK: - Sleep Debt Section
struct AnalyticsSleepDebtSection: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var selectedDataPoint: SleepDebtData?
    @State private var tooltipPosition: CGPoint = .zero
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.lg) {
                PSSectionHeader(
                    L("analytics.sleepDebt.title", table: "Analytics"),
                    icon: "chart.line.uptrend.xyaxis",
                    subtitle: L("analytics.sleepDebt.subtitle", table: "Analytics")
                )
                
                SleepDebtChart(
                    viewModel: viewModel,
                    selectedDataPoint: $selectedDataPoint,
                    tooltipPosition: $tooltipPosition
                )
                
                PSInfoBox(
                    title: L("analytics.sleepDebt.explanation.title", table: "Analytics"),
                    message: L("analytics.sleepDebt.explanation.message", table: "Analytics"),
                    icon: "exclamationmark.triangle.fill"
                )
            }
        }
        .padding(.horizontal, PSSpacing.lg)
    }
}

// MARK: - Quality-Consistency Correlation Section
struct AnalyticsQualityConsistencyCorrelation: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var selectedDataPoint: QualityConsistencyData?
    @State private var tooltipPosition: CGPoint = .zero
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.lg) {
                PSSectionHeader(
                    L("analytics.qualityConsistencyCorrelation.title", table: "Analytics"),
                    icon: "chart.dots.scatter",
                    subtitle: L("analytics.qualityConsistencyCorrelation.subtitle", table: "Analytics")
                )
                
                QualityConsistencyScatterChart(
                    viewModel: viewModel,
                    selectedDataPoint: $selectedDataPoint,
                    tooltipPosition: $tooltipPosition
                )
                
                // Veri güvenilirliği uyarısı
                if viewModel.qualityConsistencyData.count < 10 {
                    PSInfoBox(
                        title: L("analytics.qualityConsistency.limitedData.title", table: "Analytics"),
                        message: L("analytics.qualityConsistency.limitedData.message", table: "Analytics"),
                        icon: "exclamationmark.triangle.fill"
                    )
                }
                
                PSInfoBox(
                    title: L("analytics.qualityConsistencyCorrelation.explanation.title", table: "Analytics"),
                    message: L("analytics.qualityConsistencyCorrelation.explanation.message", table: "Analytics"),
                    icon: "arrow.triangle.2.circlepath"
                )
            }
        }
        .padding(.horizontal, PSSpacing.lg)
    }
}

// MARK: - Sleep Quality Trend Section
struct AnalyticsSleepQualityTrendSection: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var selectedDataPoint: SleepTrendData?
    @State private var tooltipPosition: CGPoint = .zero
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.lg) {
                PSSectionHeader(
                    L("analytics.sleepQualityTrendChart.title", table: "Analytics"),
                    icon: "star.circle.fill",
                    subtitle: L("analytics.sleepQualityTrendChart.subtitle", table: "Analytics")
                )
                
                SleepQualityTrendChart(
                    viewModel: viewModel,
                    selectedDataPoint: $selectedDataPoint,
                    tooltipPosition: $tooltipPosition
                )
                
                PSInfoBox(
                    title: L("analytics.sleepQualityTrendChart.infoTitle", table: "Analytics"),
                    message: L("analytics.sleepQualityTrendChart.infoMessage", table: "Analytics"),
                    icon: "lightbulb.fill"
                )
            }
        }
        .padding(.horizontal, PSSpacing.lg)
    }
} 