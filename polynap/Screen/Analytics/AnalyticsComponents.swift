import SwiftUI
import Charts

// MARK: - Summary Card
struct AnalyticsSummaryCard: View {
    @ObservedObject var viewModel: AnalyticsViewModel

    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.lg) {
                // Header row: title + period comparison badge
                HStack(alignment: .center) {
                    Text(L("analytics.summary.title", table: "Analytics"))
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundColor(.appText)

                    Spacer()

                    if viewModel.previousPeriodComparison.hours != 0 || viewModel.previousPeriodComparison.score != 0 {
                        HStack(spacing: PSSpacing.xs) {
                            if viewModel.previousPeriodComparison.hours != 0 {
                                HStack(spacing: 3) {
                                    Image(systemName: viewModel.previousPeriodComparison.hours >= 0 ? "arrow.up" : "arrow.down")
                                        .font(.system(size: 10, weight: .bold))
                                    Text(String(format: "%.1fh", abs(viewModel.previousPeriodComparison.hours)))
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(viewModel.previousPeriodComparison.hours >= 0 ? .appSuccess : .appError)
                            }
                            if viewModel.previousPeriodComparison.score != 0 {
                                HStack(spacing: 3) {
                                    Image(systemName: viewModel.previousPeriodComparison.score >= 0 ? "arrow.up" : "arrow.down")
                                        .font(.system(size: 10, weight: .bold))
                                    Text(String(format: "%.1f★", abs(viewModel.previousPeriodComparison.score)))
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(viewModel.previousPeriodComparison.score >= 0 ? .appSuccess : .appError)
                            }
                        }
                        .padding(.horizontal, PSSpacing.sm)
                        .padding(.vertical, PSSpacing.xs)
                        .background(Capsule().fill(Color.appCardBackground).overlay(Capsule().stroke(Color.appBorder.opacity(0.4), lineWidth: 1)))
                    }
                }

                // 3 metrics in one row
                HStack(spacing: 0) {
                    CompactMetricItem(
                        icon: "bed.double.fill",
                        iconColor: .metricAmber,
                        value: String(format: "%.1fh", viewModel.totalSleepHours),
                        label: L("analytics.totalSleep", table: "Analytics")
                    )

                    Divider().frame(height: 36).opacity(0.3)

                    CompactMetricItem(
                        icon: "clock.fill",
                        iconColor: .appPrimary,
                        value: String(format: "%.1fh", viewModel.averageDailyHours),
                        label: L("analytics.dailyAverage", table: "Analytics")
                    )

                    Divider().frame(height: 36).opacity(0.3)

                    CompactMetricItem(
                        icon: "star.fill",
                        iconColor: .appAccent,
                        value: String(format: "%.1f★", viewModel.averageSleepScore),
                        label: L("analytics.averageScore", table: "Analytics")
                    )
                }
                .padding(.vertical, PSSpacing.sm)
                .background(RoundedRectangle(cornerRadius: PSCornerRadius.medium).fill(Color.appBackground.opacity(0.5)))

                // Single insight line
                if let bestDay = viewModel.bestSleepDay {
                    HStack(spacing: PSSpacing.xs) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.appPrimary)
                        Text(bestDay.date, style: .date)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.appTextSecondary)
                        Text("·")
                            .foregroundColor(.appTextTertiary)
                        Text(String(format: "%.1f★", bestDay.score))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.appPrimary)
                        Spacer()
                        let category = SleepQualityCategory.fromRating(viewModel.averageSleepScore)
                        Text(category.localizedName)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(category.color)
                    }
                }
            }
        }
        .padding(.horizontal, PSSpacing.lg)
    }
}

// MARK: - Compact Metric Item
private struct CompactMetricItem: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: PSSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(iconColor)
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundColor(.appText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.appTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PSSpacing.sm)
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.appText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Quality Distribution
struct AnalyticsQualityDistribution: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(L("analytics.qualityDistribution.title", table: "Analytics"))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundColor(.appText)
                
                VStack(spacing: 10) {
                    QualityDistributionRow(
                        category: L("analytics.sleepQuality.excellent", table: "Analytics"),
                        count: viewModel.sleepQualityStats.excellentDays,
                        percentage: viewModel.sleepQualityStats.excellentPercentage,
                        color: SleepQualityCategory.excellent.color
                    )
                    
                    QualityDistributionRow(
                        category: L("analytics.sleepQuality.good", table: "Analytics"),
                        count: viewModel.sleepQualityStats.goodDays,
                        percentage: viewModel.sleepQualityStats.goodPercentage,
                        color: SleepQualityCategory.good.color
                    )
                    
                    QualityDistributionRow(
                        category: L("analytics.sleepQuality.average", table: "Analytics"),
                        count: viewModel.sleepQualityStats.averageDays,
                        percentage: viewModel.sleepQualityStats.averagePercentage,
                        color: SleepQualityCategory.average.color
                    )
                    
                    QualityDistributionRow(
                        category: L("analytics.sleepQuality.poor", table: "Analytics"),
                        count: viewModel.sleepQualityStats.poorDays,
                        percentage: viewModel.sleepQualityStats.poorPercentage,
                        color: SleepQualityCategory.poor.color
                    )
                    
                    QualityDistributionRow(
                        category: L("analytics.sleepQuality.bad", table: "Analytics"),
                        count: viewModel.sleepQualityStats.badDays,
                        percentage: viewModel.sleepQualityStats.badPercentage,
                        color: SleepQualityCategory.bad.color
                    )
                }
                
                // Trend göstergesi
                HStack {
                    Text(L("analytics.sleepQualityTrend.title", table: "Analytics"))
                        .font(.system(size: 14))
                        .foregroundColor(.appText)
                    
                    if abs(viewModel.sleepStatistics.trendDirection) < 0.1 {
                        Text(L("analytics.sleepQualityTrend.stable", table: "Analytics"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.appText)
                    } else {
                        HStack(spacing: 4) {
                            Text(viewModel.sleepStatistics.trendDirection > 0 ? L("analytics.sleepQualityTrend.improving", table: "Analytics") : L("analytics.sleepQualityTrend.deteriorating", table: "Analytics"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(viewModel.sleepStatistics.trendDirection > 0 ? .appSecondary : .appError)
                            
                            Image(systemName: viewModel.sleepStatistics.trendDirection > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .foregroundColor(viewModel.sleepStatistics.trendDirection > 0 ? .appSecondary : .appError)
                        }
                    }
                    
                    if abs(viewModel.sleepStatistics.improvementRate) > 1 {
                        Text(String(format: L("analytics.sleepQualityTrend.improvementRate", table: "Analytics"), abs(viewModel.sleepStatistics.improvementRate)))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, PSSpacing.lg)
    }
}

// MARK: - Quality Distribution Row
struct QualityDistributionRow: View {
    let category: String
    let count: Int
    let percentage: Double
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(category)
                .font(.system(size: 14))
                .foregroundColor(.appText)
            
            Text(String(format: L("analytics.qualityDistribution.daysCount", table: "Analytics"), count))
                .font(.system(size: 12))
                .foregroundColor(.appTextSecondary)
            
            Spacer()
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(color)
                    .frame(width: percentage.isNaN ? 0 : min(percentage, 100), height: 8)
                    .cornerRadius(4)
            }
            
            Text(String(format: L("analytics.qualityDistribution.percentage", table: "Analytics"), percentage))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appText)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// MARK: - Consistency Section
struct AnalyticsConsistencySection: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(L("analytics.consistency.title", table: "Analytics"))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundColor(.appText)
                
                HStack(spacing: 20) {
                    // Tutarlılık göstergesi
                    VStack {
                        ZStack {
                            // Arkaplan daire
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                                .frame(width: 130, height: 130)
                            
                            // Değer dairesi
                            Circle()
                                .trim(from: 0, to: CGFloat(viewModel.sleepStatistics.consistencyScore / 100))
                                .stroke(
                                    viewModel.sleepStatistics.consistencyScore > 70 ? Color.appSecondary :
                                        viewModel.sleepStatistics.consistencyScore > 40 ? Color.appPrimary : Color.orange,
                                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .frame(width: 130, height: 130)
                            
                            // Değer metni
                            VStack(spacing: 0) {
                                Text(String(format: "%.0f", viewModel.sleepStatistics.consistencyScore))
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(.appText)
                                
                                Text(L("analytics.consistency.scoreUnit", table: "Analytics"))
                                    .font(.system(size: 14))
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                        
                        Text(L("analytics.consistency.description", table: "Analytics"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.appText)
                            .padding(.top, 8)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L("analytics.variability.title", table: "Analytics"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.appTextSecondary)
                            
                            HStack {
                                Text(String(format: "%.0f", viewModel.sleepStatistics.variabilityScore))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.appText)
                                
                                Text(L("analytics.consistency.scoreUnit", table: "Analytics"))
                                    .font(.system(size: 14))
                                    .foregroundColor(.appTextSecondary)
                            }
                            
                            Text(viewModel.sleepStatistics.variabilityScore < 30 ? L("analytics.variability.stable", table: "Analytics") :
                                 viewModel.sleepStatistics.variabilityScore < 60 ? L("analytics.variability.moderate", table: "Analytics") : L("analytics.variability.high", table: "Analytics"))
                                .font(.system(size: 12))
                                .foregroundColor(.appTextSecondary)
                        }
                        
                        Divider()
                        
                        // Başarı rozeti veya tavsiye
                        HStack {
                            if viewModel.sleepStatistics.consistencyScore > 70 {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.appSecondary)
                            } else {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.orange)
                            }
                            
                            Text(viewModel.sleepStatistics.consistencyScore > 70 ?
                                 L("analytics.consistency.greatRoutine", table: "Analytics") :
                                    L("analytics.consistency.improveRoutine", table: "Analytics"))
                                .font(.system(size: 12))
                                .foregroundColor(.appText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, PSSpacing.lg)
    }
}

// MARK: - Best Worst Days
struct AnalyticsBestWorstDays: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(L("analytics.bestWorstDays.title", table: "Analytics"))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundColor(.appText)
                
                HStack(spacing: 15) {
                    // En iyi gün
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "medal.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.appSecondary)
                            
                            Text(L("analytics.bestWorstDays.bestDay", table: "Analytics"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.appText)
                        }
                        
                        if let bestDay = viewModel.bestSleepDay {
                            Text(bestDay.date, style: .date)
                                .font(.system(size: 14))
                                .foregroundColor(.appText)
                            
                            HStack {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.appSecondary)
                                
                                Text(String(format: "%.1f/5", bestDay.score))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.appText)
                            }
                            
                            HStack {
                                Image(systemName: "bed.double.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.appPrimary)
                                
                                Text(String(format: L("analytics.bestWorstDays.hours", table: "Analytics"), bestDay.hours))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.appText)
                            }
                        } else {
                            Text(L("analytics.bestWorstDays.noData", table: "Analytics"))
                                .font(.system(size: 14))
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appSecondary.opacity(0.1))
                    .cornerRadius(8)
                    
                    // En kötü gün
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.appError)
                            
                            Text(L("analytics.bestWorstDays.worstDay", table: "Analytics"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.appText)
                        }
                        
                        if let worstDay = viewModel.worstSleepDay {
                            Text(worstDay.date, style: .date)
                                .font(.system(size: 14))
                                .foregroundColor(.appText)
                            
                            HStack {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.appError)
                                
                                Text(String(format: "%.1f/5", worstDay.score))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.appText)
                            }
                            
                            HStack {
                                Image(systemName: "bed.double.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.appPrimary)
                                
                                Text(String(format: L("analytics.bestWorstDays.hours", table: "Analytics"), worstDay.hours))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.appText)
                            }
                        } else {
                            Text(L("analytics.bestWorstDays.noData", table: "Analytics"))
                                .font(.system(size: 14))
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appError.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, PSSpacing.lg)
    }
}

// MARK: - Time Gained Section
struct AnalyticsTimeGained: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(L("analytics.timeGained.title", table: "Analytics"))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundColor(.appText)
                
                VStack(spacing: 20) {
                    HStack(spacing: 15) {
                        // Kazanılan zaman
                        ZStack {
                            Circle()
                                .fill(Color.appSecondary.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            VStack(spacing: 0) {
                                Text("\(Int(viewModel.timeGained))")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.appSecondary)
                                
                                Text(L("analytics.timeGained.hoursUnit", table: "Analytics"))
                                    .font(.system(size: 14))
                                    .foregroundColor(.appSecondary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L("analytics.timeGained.subtitle", table: "Analytics"))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.appText)
                            
                            Text(L("analytics.timeGained.description", table: "Analytics"))
                                .font(.system(size: 14))
                                .foregroundColor(.appTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Verimlilik yüzdesi
                            HStack {
                                Text(L("analytics.timeGained.efficiency", table: "Analytics"))
                                    .font(.system(size: 14))
                                    .foregroundColor(.appTextSecondary)
                                
                                Text(String(format: L("analytics.timeGained.efficiencyValue", table: "Analytics"), viewModel.sleepStatistics.efficiencyPercentage))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.appSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text("🎉")
                            .font(.system(size: 36))
                    }
                    
                    // Kazanılan zamanla yapılabilecekler
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L("analytics.timeGained.actionsTitle", table: "Analytics"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.appText)
                        
                        VStack(spacing: 10) {
                            ActivityRow(
                                icon: "book.fill",
                                color: .blue,
                                activity: String(format: L("analytics.timeGained.activity.reading", table: "Analytics"), Int(viewModel.timeGained * 30)),
                                note: L("analytics.timeGained.note1", table: "Analytics"))
                            
                            ActivityRow(
                                icon: "figure.walk",
                                color: .green,
                                activity: String(format: L("analytics.timeGained.activity.walking", table: "Analytics"), Int(viewModel.timeGained * 5)),
                                note: L("analytics.timeGained.note2", table: "Analytics"))
                            
                            ActivityRow(
                                icon: "person.crop.rectangle.stack",
                                color: .purple,
                                activity: String(format: L("analytics.timeGained.activity.movies", table: "Analytics"), Int(viewModel.timeGained / 2)),
                                note: L("analytics.timeGained.note3", table: "Analytics"))
                            
                            ActivityRow(
                                icon: "laptopcomputer",
                                color: .orange,
                                activity: String(format: L("analytics.timeGained.activity.projects", table: "Analytics"), Int(viewModel.timeGained * 0.5)),
                                note: L("analytics.timeGained.note4", table: "Analytics"))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, PSSpacing.lg)
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let icon: String
    let color: Color
    let activity: String
    let note: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(color)
                .cornerRadius(8)
            
            Text(activity)
                .font(.system(size: 14))
                .foregroundColor(.appText)
            
            Spacer()
            
            Text(note)
                .font(.system(size: 12))
                .foregroundColor(.appTextSecondary)
                .italic()
        }
    }
}

// MARK: - Premium Upsell Section (replaces 4 separate locked cards)
struct AnalyticsPremiumUpsell: View {
    @State private var animateGlow = false

    var body: some View {
        Button(action: {
            PaywallManager.shared.presentPaywall(trigger: .premiumFeatureAccess)
        }) {
            ZStack {
                // Background: hero gradient matching app header
                RoundedRectangle(cornerRadius: PSCornerRadius.extraLarge)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.heroTop, Color.heroBottom]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // 2x2 blurred chart grid visible through bottom half
                VStack(spacing: 0) {
                    Spacer()
                    // Mini chart grid — blurred, fades to gradient
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: PSSpacing.sm) {
                        BlurredMiniChart(content: AnyView(MiniBarChartPreview(colors: [.appPrimary, .appPrimary.opacity(0.6)])))
                        BlurredMiniChart(content: AnyView(MiniLineChartPreview()))
                        BlurredMiniChart(content: AnyView(MiniDonutPreview()))
                        BlurredMiniChart(content: AnyView(MiniBarChartPreview(colors: [.appSecondary, .appSecondary.opacity(0.5)])))
                    }
                    .padding(.horizontal, PSSpacing.md)
                    .padding(.bottom, PSSpacing.md)
                    .mask(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black.opacity(0.5), location: 0.4),
                                .init(color: .black, location: 1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                // Content overlay (top portion)
                VStack(spacing: PSSpacing.xl) {
                    // Crown icon with glow
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 56, height: 56)
                            .scaleEffect(animateGlow ? 1.08 : 1.0)
                            .opacity(animateGlow ? 0.6 : 0.3)
                            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: animateGlow)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(spacing: PSSpacing.sm) {
                        Text(L("analytics.premium.upsell.title", table: "Analytics"))
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text(L("analytics.premium.upsell.subtitle", table: "Analytics"))
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, PSSpacing.lg)
                    }

                    // Feature bullets
                    VStack(alignment: .leading, spacing: PSSpacing.sm) {
                        PremiumFeatureBullet(icon: "chart.bar.fill", text: L("analytics.premium.feature1", table: "Analytics"))
                        PremiumFeatureBullet(icon: "waveform.path.ecg", text: L("analytics.premium.feature2", table: "Analytics"))
                        PremiumFeatureBullet(icon: "clock.arrow.2.circlepath", text: L("analytics.premium.feature3", table: "Analytics"))
                        PremiumFeatureBullet(icon: "heart.fill", text: L("analytics.premium.feature4", table: "Analytics"))
                    }
                    .padding(.horizontal, PSSpacing.lg)

                    // CTA Button
                    HStack(spacing: PSSpacing.sm) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                        Text(L("analytics.premium.upsell.cta", table: "Analytics"))
                            .font(.system(.headline, design: .rounded, weight: .bold))
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Color.heroTop)
                    .padding(.horizontal, PSSpacing.xxl)
                    .padding(.vertical, PSSpacing.md)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .shadow(color: Color.white.opacity(0.3), radius: 8, x: 0, y: 0)
                    )
                }
                .padding(.top, PSSpacing.xl)
                .padding(.bottom, 160)
                .padding(.horizontal, PSSpacing.lg)
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
        .onAppear { animateGlow = true }
    }
}

// MARK: - Premium Feature Bullet
private struct PremiumFeatureBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: PSSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.white.opacity(0.2)))
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            Spacer()
        }
    }
}

// MARK: - Mini Chart Previews for Upsell Grid
private struct BlurredMiniChart: View {
    let content: AnyView

    var body: some View {
        content
            .blur(radius: 4)
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: PSCornerRadius.medium).fill(Color.white.opacity(0.08)))
            .clipped()
    }
}

private struct MiniBarChartPreview: View {
    let colors: [Color]
    let heights: [CGFloat] = [0.4, 0.7, 0.55, 0.9, 0.65, 0.5, 0.8]

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(heights.indices, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(i < colors.count ? colors[i % colors.count] : colors[0])
                    .frame(maxWidth: .infinity)
                    .frame(height: heights[i] * 50)
            }
        }
        .padding(PSSpacing.sm)
    }
}

private struct MiniLineChartPreview: View {
    var body: some View {
        Canvas { ctx, size in
            let points: [CGFloat] = [0.6, 0.4, 0.7, 0.5, 0.8, 0.6, 0.75]
            var path = Path()
            for (i, y) in points.enumerated() {
                let x = size.width * CGFloat(i) / CGFloat(points.count - 1)
                let pt = CGPoint(x: x, y: size.height * (1 - y))
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            ctx.stroke(path, with: .color(.white.opacity(0.8)), lineWidth: 2)
            for (i, y) in points.enumerated() {
                let x = size.width * CGFloat(i) / CGFloat(points.count - 1)
                let pt = CGPoint(x: x, y: size.height * (1 - y))
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x-3, y: pt.y-3, width: 6, height: 6)), with: .color(.white))
            }
        }
        .padding(PSSpacing.sm)
    }
}

private struct MiniDonutPreview: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 10)
            Circle()
                .trim(from: 0, to: 0.65)
                .stroke(Color.white.opacity(0.7), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0.68, to: 0.93)
                .stroke(Color.white.opacity(0.4), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .padding(PSSpacing.lg)
    }
}

// MARK: - Premium Locked Analytics
struct PremiumLockedAnalytics<PreviewContent: View>: View {
    let title: String
    let description: String
    let preview: () -> PreviewContent
    @State private var showPremiumAlert = false
    
    var body: some View {
        Button(action: {
            showPremiumAlert = true
        }) {
            ZStack {
                // Bulanık preview
                preview()
                    .blur(radius: 3)
                    .opacity(0.4)
                    .disabled(true)
                
                // Premium overlay
                VStack(spacing: PSSpacing.md) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.yellow)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    VStack(spacing: PSSpacing.sm) {
                        Text(L("analytics.premium.required", table: "Analytics"))
                            .font(PSTypography.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.appText)
                            .multilineTextAlignment(.center)
                        
                        Text(description)
                            .font(PSTypography.body)
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, PSSpacing.lg)
                    }
                    
                    HStack(spacing: PSSpacing.sm) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(.appPrimary)
                        
                        Text(L("analytics.premium.upgrade", table: "Analytics"))
                            .font(PSTypography.button)
                            .fontWeight(.semibold)
                            .foregroundColor(.appPrimary)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(.appPrimary)
                    }
                    .padding(.horizontal, PSSpacing.lg)
                    .padding(.vertical, PSSpacing.sm)
                    .background(
                        Capsule()
                            .fill(Color.appPrimary.opacity(0.1))
                    )
                }
                .padding(PSSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: PSCornerRadius.large)
                        .fill(Color.appBackground.opacity(0.95))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
            }
        }
        .buttonStyle(.plain)
        .alert(L("analytics.premium.alert.title", table: "Analytics"), isPresented: $showPremiumAlert) {
            Button(L("analytics.premium.alert.upgrade", table: "Analytics")) {
                // Premium upgrade navigation
            }
            Button(L("analytics.premium.alert.cancel", table: "Analytics"), role: .cancel) {}
        } message: {
            Text(L("analytics.premium.alert.message", table: "Analytics"))
        }
    }
}

// MARK: - Preview Components for Premium Lock
struct AnalyticsSleepComponentsPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.md) {
            Text(L("analytics.sleepComponentsTrend.title", table: "Analytics"))
                .font(PSTypography.headline)
                .fontWeight(.semibold)
                .foregroundColor(.appText)
            
            Text(L("analytics.sleepComponentsTrend.subtitle", table: "Analytics"))
                .font(PSTypography.body)
                .foregroundColor(.appTextSecondary)
            
            // Daha modern ve responsive bar chart preview
            GeometryReader { geometry in
                HStack(alignment: .bottom, spacing: max(4, geometry.size.width / 50)) {
                    ForEach(0..<7) { index in
                        VStack(spacing: 1) {
                            // Skor noktası
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 8, height: 8)
                                .offset(y: -4)
                            
                            // Şekerleme 2
                            Rectangle()
                                .fill(Color("SecondaryColor"))
                                .frame(height: CGFloat.random(in: 8...20))
                            
                            // Şekerleme 1
                            Rectangle()
                                .fill(Color("PrimaryColor"))
                                .frame(height: CGFloat.random(in: 12...35))
                            
                            // Ana uyku
                            Rectangle()
                                .fill(Color("AccentColor"))
                                .frame(height: CGFloat.random(in: 40...80))
                        }
                        .frame(maxWidth: .infinity)
                        .cornerRadius(3)
                    }
                }
            }
            .frame(height: 140)
            
            // Legend
            HStack(spacing: PSSpacing.lg) {
                LegendItem(color: Color("AccentColor"), label: L("analytics.sleepComponentsTrend.core", table: "Analytics"))
                LegendItem(color: Color("PrimaryColor"), label: L("analytics.sleepComponentsTrend.nap", table: "Analytics"))
                
                HStack(spacing: PSSpacing.xs) {
                    Circle()
                        .stroke(Color.yellow, lineWidth: 2)
                        .frame(width: 12, height: 12)
                    Text(L("analytics.sleepComponentsTrend.score", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appText)
                }
            }
            .padding(.top, PSSpacing.sm)
        }
        .padding(PSSpacing.lg)
        .background(Color.appCardBackground)
        .cornerRadius(PSCornerRadius.large)
    }
}

struct AnalyticsQualityDistributionPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("analytics.qualityDistribution.title", table: "Analytics"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color("TextColor"))
            
            VStack(spacing: 8) {
                ForEach(["Mükemmel", "İyi", "Ortalama", "Kötü"], id: \.self) { quality in
                    HStack {
                        Circle()
                            .fill(Color.random)
                            .frame(width: 12, height: 12)
                        
                        Text(quality)
                            .font(.system(size: 14))
                            .foregroundColor(Color("TextColor"))
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(Color.random.opacity(0.7))
                            .frame(width: CGFloat.random(in: 30...80), height: 8)
                            .cornerRadius(4)
                        
                        Text("\(Int.random(in: 10...45))%")
                            .font(.system(size: 14))
                            .foregroundColor(Color("TextColor"))
                            .frame(width: 35, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color("CardBackground"))
        .cornerRadius(12)
    }
}

struct AnalyticsSleepBreakdownPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("analytics.sleepBreakdown.title", table: "Analytics"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color("TextColor"))
            
            HStack {
                // Fake pie chart
                ZStack {
                    Circle()
                        .fill(Color("AccentColor"))
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .fill(Color("PrimaryColor"))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(90))
                    
                    Circle()
                        .trim(from: 0, to: 0.15)
                        .fill(Color("SecondaryColor"))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(198))
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(Color("AccentColor"))
                            .frame(width: 12, height: 12)
                        Text(String(format: L("analytics.sleepBreakdown.core", table: "Analytics"), 75))
                            .font(.system(size: 14))
                            .foregroundColor(Color("TextColor"))
                    }
                    
                    HStack {
                        Circle()
                            .fill(Color("PrimaryColor"))
                            .frame(width: 12, height: 12)
                        Text(String(format: L("analytics.sleepBreakdown.nap1", table: "Analytics"), 20))
                            .font(.system(size: 14))
                            .foregroundColor(Color("TextColor"))
                    }
                    
                    HStack {
                        Circle()
                            .fill(Color("SecondaryColor"))
                            .frame(width: 12, height: 12)
                        Text(String(format: L("analytics.sleepBreakdown.nap2", table: "Analytics"), 5))
                            .font(.system(size: 14))
                            .foregroundColor(Color("TextColor"))
                    }
                }
            }
        }
        .padding()
        .background(Color("CardBackground"))
        .cornerRadius(12)
    }
}

struct AnalyticsConsistencyPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("analytics.consistency.title", table: "Analytics"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color("TextColor"))
            
            HStack {
                // Fake consistency circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(Color("SecondaryColor"), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 100, height: 100)
                    
                    VStack {
                        Text("75")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color("TextColor"))
                        Text(L("analytics.consistency.scoreUnit", table: "Analytics"))
                            .font(.system(size: 12))
                            .foregroundColor(Color("SecondaryTextColor"))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(format: L("analytics.variability.scoreFormat", table: "Analytics"), 25))
                        .font(.system(size: 14))
                        .foregroundColor(Color("TextColor"))
                    
                    Text(L("analytics.consistency.greatRoutine", table: "Analytics"))
                        .font(.system(size: 12))
                        .foregroundColor(Color("SecondaryTextColor"))
                }
            }
        }
        .padding()
        .background(Color("CardBackground"))
        .cornerRadius(12)
    }
}

struct AnalyticsTimeGainedPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("analytics.timeGained.title", table: "Analytics"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color("TextColor"))
            
            HStack {
                ZStack {
                    Circle()
                        .fill(Color("SecondaryColor").opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    VStack {
                        Text("2.5")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color("SecondaryColor"))
                        Text(L("analytics.timeGained.hoursUnit", table: "Analytics"))
                            .font(.system(size: 12))
                            .foregroundColor(Color("SecondaryColor"))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("analytics.timeGained.activity.reading", table: "Analytics"))
                        .font(.system(size: 12))
                        .foregroundColor(Color("TextColor"))
                    
                    Text(L("analytics.timeGained.activity.walking", table: "Analytics"))
                        .font(.system(size: 12))
                        .foregroundColor(Color("TextColor"))
                    
                    Text(L("analytics.timeGained.activity.movies", table: "Analytics"))
                        .font(.system(size: 12))
                        .foregroundColor(Color("TextColor"))
                }
            }
        }
        .padding()
        .background(Color("CardBackground"))
        .cornerRadius(12)
    }
}

// MARK: - Color Extension for Random Colors
extension Color {
    static var random: Color {
        return Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
} 