import SwiftUI

// MARK: - Sleep Trends Section
struct AnalyticsSleepTrendsSection: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    let isPremiumUser: Bool
    @Binding var selectedTrendDataPoint: SleepTrendData?
    @Binding var selectedBarDataPoint: SleepTrendData?
    @Binding var tooltipPosition: CGPoint
    @State private var selectedQualityDataPoint: SleepTrendData?

    var body: some View {
        VStack(spacing: PSSpacing.xl) {
            // 1. Total sleep trend — FREE
            PSCard {
                VStack(alignment: .leading, spacing: PSSpacing.lg) {
                    PSSectionHeader(
                        L("analytics.totalSleepTrend.title", table: "Analytics"),
                        icon: "moon.circle.fill",
                        subtitle: L("analytics.totalSleepTrend.subtitle", table: "Analytics")
                    )
                    SleepTrendChart(
                        viewModel: viewModel,
                        selectedTrendDataPoint: $selectedTrendDataPoint,
                        tooltipPosition: $tooltipPosition
                    )
                }
            }
            .padding(.horizontal, PSSpacing.lg)

            // 2. Sleep quality trend — FREE (moved from premium)
            PSCard {
                VStack(alignment: .leading, spacing: PSSpacing.lg) {
                    PSSectionHeader(
                        L("analytics.sleepQualityTrendChart.title", table: "Analytics"),
                        icon: "star.circle.fill",
                        subtitle: L("analytics.sleepQualityTrendChart.subtitle", table: "Analytics")
                    )
                    SleepQualityTrendChart(
                        viewModel: viewModel,
                        selectedDataPoint: $selectedQualityDataPoint,
                        tooltipPosition: $tooltipPosition
                    )
                }
            }
            .padding(.horizontal, PSSpacing.lg)

            // 3. Sleep components trend — PREMIUM only
            if isPremiumUser {
                PSCard {
                    VStack(alignment: .leading, spacing: PSSpacing.lg) {
                        PSSectionHeader(
                            L("analytics.sleepComponentsTrend.title", table: "Analytics"),
                            icon: "chart.bar.fill",
                            subtitle: L("analytics.sleepComponentsTrend.subtitle", table: "Analytics")
                        )
                        SleepComponentsChart(
                            viewModel: viewModel,
                            selectedBarDataPoint: $selectedBarDataPoint,
                            tooltipPosition: $tooltipPosition
                        )
                    }
                }
                .padding(.horizontal, PSSpacing.lg)
            }
        }
    }
} 