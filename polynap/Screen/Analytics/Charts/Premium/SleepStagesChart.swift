import SwiftUI
import Charts

struct SleepStagesChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    private let remColor = Color.purple
    private let coreColor = Color.blue
    private let deepColor = Color.indigo
    private let awakeColor = Color.orange.opacity(0.7)
    
    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.sm) {
            Chart(viewModel.sleepStagesData) { data in
                BarMark(
                    x: .value("Date", data.date, unit: .day),
                    y: .value("Minutes", data.deepMinutes)
                )
                .foregroundStyle(deepColor)
                
                BarMark(
                    x: .value("Date", data.date, unit: .day),
                    y: .value("Minutes", data.coreMinutes)
                )
                .foregroundStyle(coreColor)
                
                BarMark(
                    x: .value("Date", data.date, unit: .day),
                    y: .value("Minutes", data.remMinutes)
                )
                .foregroundStyle(remColor)
                
                BarMark(
                    x: .value("Date", data.date, unit: .day),
                    y: .value("Minutes", data.awakeMinutes)
                )
                .foregroundStyle(awakeColor)
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.appTextSecondary.opacity(0.3))
                    AxisValueLabel {
                        if let minutes = value.as(Double.self) {
                            Text(formatMinutes(minutes))
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
            .frame(height: 180)
            
            // Average summary
            if let avgData = averageStages {
                HStack(spacing: PSSpacing.lg) {
                    StagePill(color: deepColor, label: "Deep", value: formatMinutes(avgData.deep))
                    StagePill(color: coreColor, label: "Core", value: formatMinutes(avgData.core))
                    StagePill(color: remColor, label: "REM", value: formatMinutes(avgData.rem))
                    StagePill(color: awakeColor, label: "Awake", value: formatMinutes(avgData.awake))
                }
            }
        }
    }
    
    private var averageStages: (deep: Double, core: Double, rem: Double, awake: Double)? {
        let data = viewModel.sleepStagesData
        guard !data.isEmpty else { return nil }
        let count = Double(data.count)
        return (
            deep: data.map(\.deepMinutes).reduce(0, +) / count,
            core: data.map(\.coreMinutes).reduce(0, +) / count,
            rem: data.map(\.remMinutes).reduce(0, +) / count,
            awake: data.map(\.awakeMinutes).reduce(0, +) / count
        )
    }
    
    private func formatMinutes(_ minutes: Double) -> String {
        let h = Int(minutes) / 60
        let m = Int(minutes) % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

private struct StagePill: View {
    let color: Color
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.appText)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
