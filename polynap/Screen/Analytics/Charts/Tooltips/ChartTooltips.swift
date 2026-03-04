import SwiftUI

// MARK: - Chart Tooltips

// MARK: - Sleep Quality Tooltip
struct SleepQualityTooltip: View {
    let data: SleepTrendData
    
    init(for data: SleepTrendData) {
        self.data = data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.xs) {
            Text(data.date, style: .date)
                .font(PSTypography.body)
                .fontWeight(.semibold)
                .foregroundColor(.appText)
            
            Divider()
            
            HStack(spacing: PSSpacing.lg) {
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text(L("analytics.sleepQualityTrendChart.tooltip.qualityScore", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                    
                    Text(String(format: "%.1f/5.0", data.score))
                        .font(PSTypography.body)
                        .fontWeight(.medium)
                        .foregroundColor(data.scoreCategory.color)
                }
                
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text(L("analytics.sleepQualityTrendChart.tooltip.category", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                    
                    Text(data.scoreCategory.localizedName)
                        .font(PSTypography.caption)
                        .foregroundColor(data.scoreCategory.color)
                }
            }
        }
        .padding(PSSpacing.sm)
        .background(Color.appCardBackground)
        .cornerRadius(PSCornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .fixedSize()
    }
}

// MARK: - Total Sleep Tooltip
struct TotalSleepTooltip: View {
    let data: SleepTrendData
    
    init(for data: SleepTrendData) {
        self.data = data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.xs) {
            Text(data.date, style: .date)
                .font(PSTypography.body)
                .fontWeight(.semibold)
                .foregroundColor(.appText)
            
            Divider()
            
            HStack(spacing: PSSpacing.lg) {
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text(L("analytics.tooltip.totalSleep", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                    
                    Text(String(format: L("analytics.sleepQualityTrendChart.tooltip.hoursFormat", table: "Analytics"), data.totalHours))
                        .font(PSTypography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.appPrimary)
                }
                
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text(L("analytics.sleepQualityTrendChart.tooltip.qualityScore", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                    
                    Text(String(format: "%.1f/5.0", data.score))
                        .font(PSTypography.caption)
                        .foregroundColor(data.scoreCategory.color)
                }
            }
        }
        .padding(PSSpacing.sm)
        .background(Color.appCardBackground)
        .cornerRadius(PSCornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .fixedSize()
    }
}

// MARK: - Bar Chart Tooltip
struct BarChartTooltip: View {
    let day: SleepTrendData
    
    init(for day: SleepTrendData) {
        self.day = day
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.xs) {
            Text(day.date, format: .dateTime.weekday(.wide).day())
                .font(PSTypography.body)
                .fontWeight(.semibold)
                .foregroundColor(.appText)
            
            Divider()
            
            HStack(spacing: PSSpacing.lg) {
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text(L("analytics.tooltip.totalSleep", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                    
                    Text(String(format: L("analytics.sleepQualityTrendChart.tooltip.hoursFormat", table: "Analytics"), day.totalHours))
                        .font(PSTypography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.appPrimary)
                }
                
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text(L("analytics.sleepQualityTrendChart.tooltip.qualityScore", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                    
                    Text(String(format: "%.1f/5.0", day.score))
                        .font(PSTypography.caption)
                        .foregroundColor(day.scoreCategory.color)
                }
            }
            
            // Bileşenler detayı (varsa göster)
            if day.coreHours > 0 || day.nap1Hours > 0 || day.nap2Hours > 0 {
                HStack(spacing: PSSpacing.sm) {
                    if day.coreHours > 0 {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(Color.appAccent)
                                .frame(width: 6, height: 6)
                            Text(String(format: "%.1fs", day.coreHours))
                                .font(PSTypography.caption)
                                .foregroundColor(.appText)
                        }
                    }
                    
                    if day.nap1Hours > 0 {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(Color.appPrimary)
                                .frame(width: 6, height: 6)
                            Text(String(format: "%.1fs", day.nap1Hours))
                                .font(PSTypography.caption)
                                .foregroundColor(.appText)
                        }
                    }
                    
                    if day.nap2Hours > 0 {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(Color.appSecondary)
                                .frame(width: 6, height: 6)
                            Text(String(format: "%.1fs", day.nap2Hours))
                                .font(PSTypography.caption)
                                .foregroundColor(.appText)
                        }
                    }
                }
            }
        }
        .padding(PSSpacing.sm)
        .background(Color.appCardBackground)
        .cornerRadius(PSCornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .fixedSize()
    }
}

// MARK: - Pie Chart Tooltip
struct PieChartTooltip: View {
    let slice: SleepBreakdownData
    let selectedTimeRange: TimeRange
    
    init(for slice: SleepBreakdownData, selectedTimeRange: TimeRange) {
        self.slice = slice
        self.selectedTimeRange = selectedTimeRange
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(slice.type)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.appText)
            
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(String(format: L("analytics.tooltip.percentageLabel", table: "Analytics"), slice.percentage))
                        .font(.system(size: 11))
                        .foregroundColor(.appText)
                    
                    Text(String(format: L("analytics.tooltip.totalHoursLabel", table: "Analytics"), slice.hours))
                        .font(.system(size: 11))
                        .foregroundColor(.appText)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(String(format: L("analytics.tooltip.dailyHoursLabel", table: "Analytics"), slice.averagePerDay))
                        .font(.system(size: 11))
                        .foregroundColor(.appText)
                    
                    Text(String(format: L("analytics.tooltip.daysLabel", table: "Analytics"), slice.daysWithThisType))
                        .font(.system(size: 11))
                        .foregroundColor(.appText)
                }
            }
        }
        .padding(8)
        .background(Color.appCardBackground)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .frame(width: 160)
    }
}

// MARK: - Consistency Trend Tooltip
struct ConsistencyTrendTooltip: View {
    let data: ConsistencyTrendData
    
    init(for data: ConsistencyTrendData) {
        self.data = data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.xs) {
            Text(data.date, style: .date)
                .font(PSTypography.body)
                .fontWeight(.semibold)
                .foregroundColor(.appText)
            
            Divider()
            
            VStack(alignment: .leading, spacing: PSSpacing.xs) {
                Text(String(format: L("analytics.consistencyTrend.tooltip.score", table: "Analytics"), data.consistencyScore))
                    .font(PSTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.appText)
                
                Text(String(format: L("analytics.consistencyTrend.tooltip.deviation", table: "Analytics"), data.deviation))
                    .font(PSTypography.caption)
                    .foregroundColor(.appTextSecondary)
            }
        }
        .padding(PSSpacing.sm)
        .background(Color.appCardBackground)
        .cornerRadius(PSCornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .fixedSize()
    }
}

// MARK: - Sleep Debt Tooltip
struct SleepDebtTooltip: View {
    let data: SleepDebtData
    
    init(for data: SleepDebtData) {
        self.data = data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.xs) {
            Text(data.date, style: .date)
                .font(PSTypography.body)
                .fontWeight(.semibold)
                .foregroundColor(.appText)
            
            Divider()
            
            VStack(alignment: .leading, spacing: PSSpacing.xs) {
                Text(String(format: L("analytics.sleepDebt.tooltip.daily", table: "Analytics"), data.dailyDebt))
                    .font(PSTypography.caption)
                    .foregroundColor(.appText)
                
                Text(String(format: L("analytics.sleepDebt.tooltip.cumulative", table: "Analytics"), data.cumulativeDebt))
                    .font(PSTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(data.cumulativeDebt >= 0 ? .red : .green)
            }
        }
        .padding(PSSpacing.sm)
        .background(Color.appCardBackground)
        .cornerRadius(PSCornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .fixedSize()
    }
}

// MARK: - Quality Consistency Tooltip
struct QualityConsistencyTooltip: View {
    let data: QualityConsistencyData
    
    init(for data: QualityConsistencyData) {
        self.data = data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.xs) {
            Text(data.date, style: .date)
                .font(PSTypography.body)
                .fontWeight(.semibold)
                .foregroundColor(.appText)
            
            Divider()
            
            HStack(spacing: PSSpacing.md) {
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text(L("analytics.qualityConsistency.tooltip.quality", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                    
                    Text(String(format: "%.1f", data.sleepQuality))
                        .font(PSTypography.body)
                        .fontWeight(.medium)
                        .foregroundColor(data.qualityCategory.color)
                }
                
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text(L("analytics.qualityConsistency.tooltip.deviation", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                    
                    Text(String(format: "%.0f dk", data.consistencyDeviation))
                        .font(PSTypography.caption)
                        .foregroundColor(.appText)
                }
            }
        }
        .padding(PSSpacing.sm)
        .background(Color.appCardBackground)
        .cornerRadius(PSCornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .fixedSize()
    }
} 