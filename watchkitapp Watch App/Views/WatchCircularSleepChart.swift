import SwiftUI
import PolyNapShared

/// Watch için optimize edilmiş, duyarlı ve gerçek zamanlı CircularSleepChart.
struct WatchCircularSleepChart: View {
    let schedule: SharedUserSchedule?
    
    private let hourMarkers = [0, 3, 6, 9, 12, 15, 18, 21]
    
    var body: some View {
        // TimelineView, her saniye `context.date`'i güncelleyerek
        // kırmızı zaman ibresinin akıcı bir şekilde hareket etmesini sağlar.
        TimelineView(.everyMinute) { context in
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Boyutları dinamik olarak hesapla
                let radius = (min(geometry.size.width, geometry.size.height) / 2) * 0.70
                let strokeWidth = radius * 0.25
                
                ZStack {
                    // Arka plan dairesi
                    backgroundCircle(center: center, radius: radius, strokeWidth: strokeWidth)
                    
                    // Saat dilimi işaretleri
                    hourTickMarks(center: center, radius: radius, strokeWidth: strokeWidth)
                    
                    // Uyku blokları
                    if let schedule = schedule, let sleepBlocks = schedule.sleepBlocks {
                        sleepBlocksView(blocks: sleepBlocks, center: center, radius: radius, strokeWidth: strokeWidth)
                        sleepBlockTimeLabels(blocks: sleepBlocks, center: center, radius: radius, strokeWidth: strokeWidth)
                    }
                    
                    // Saat etiketleri (00, 03, 06...)
                    hourMarkersView(center: center, radius: radius, strokeWidth: strokeWidth)
                    
                    // Gerçek zamanlı kırmızı ibre
                    currentTimeIndicator(date: context.date, center: center, radius: radius, strokeWidth: strokeWidth)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    // MARK: - View Components
    
    private func backgroundCircle(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        Circle()
            .stroke(Color.secondary.opacity(0.15), lineWidth: strokeWidth)
            .frame(width: radius * 2, height: radius * 2)
            .position(center)
    }
    
    // 24 ayrı Path → 2 birleşik Path (Watch'ta bellek daha kritik)
    private func hourTickMarks(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        let innerR = radius - strokeWidth / 2
        let outerR = radius + strokeWidth / 2

        return ZStack {
            Path { path in
                for hour in stride(from: 0, to: 24, by: 3) {
                    let angle = Angle(degrees: Double(hour) * 15.0 - 90.0)
                    path.move(to: pointOnCircle(center: center, radius: innerR, angle: angle))
                    path.addLine(to: pointOnCircle(center: center, radius: outerR, angle: angle))
                }
            }
            .stroke(Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 0.5))

            Path { path in
                for hour in 0..<24 where hour % 3 != 0 {
                    let angle = Angle(degrees: Double(hour) * 15.0 - 90.0)
                    path.move(to: pointOnCircle(center: center, radius: innerR, angle: angle))
                    path.addLine(to: pointOnCircle(center: center, radius: outerR, angle: angle))
                }
            }
            .stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
        }
    }
    
    private func sleepBlocksView(blocks: [SharedSleepBlock], center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        ForEach(blocks) { block in
            let startAngle = angleForTime(timeString: block.startTime)
            let endAngle = angleForTime(timeString: block.endTime)
            let blockColor = block.isCore ? Color.blue : Color.orange
            
            Path { path in
                path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            }
            .stroke(blockColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))
            .opacity(0.85)
        }
    }
    
    private func hourMarkersView(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        ForEach(hourMarkers, id: \.self) { hour in
            let angle = Angle(degrees: Double(hour) * 15.0 - 90.0)
            let labelRadius = radius + strokeWidth / 2 + (radius * 0.15) // Etiketi dışarı konumlandır
            let position = pointOnCircle(center: center, radius: labelRadius, angle: angle)
            
            Text(String(format: "%02d", hour))
                .font(.system(size: radius * 0.15, weight: .medium, design: .rounded))
                .foregroundColor(.primary.opacity(0.9))
                .position(position)
        }
    }
    
    private func sleepBlockTimeLabels(blocks: [SharedSleepBlock], center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        ForEach(blocks) { block in
            let angles = calculateBlockAngles(startTime: block.startTime, endTime: block.endTime)
            let labelRadius = radius - strokeWidth / 2 - (radius * 0.18) // Etiketi içeri konumlandır
            let position = pointOnCircle(center: center, radius: labelRadius, angle: angles.midAngle)
            
            Text(formatTime(block.startTime))
                .font(.system(size: radius * 0.12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(2)
                .background(Color.black.opacity(0.6).cornerRadius(3))
                .position(position)
        }
    }
    
    private func currentTimeIndicator(date: Date, center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        let angle = angleForCurrentTime(date: date)
        let indicatorLength = strokeWidth / 2
        let startPoint = pointOnCircle(center: center, radius: radius - indicatorLength, angle: angle)
        let endPoint = pointOnCircle(center: center, radius: radius + indicatorLength, angle: angle)
        
        return ZStack {
            Path { path in
                path.move(to: startPoint)
                path.addLine(to: endPoint)
            }
            .stroke(Color.red, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .shadow(color: .red.opacity(0.5), radius: 3, x: 0, y: 0)
            
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .position(center)
        }
    }
    
    // MARK: - Helper Functions
    
    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        return CGPoint(
            x: center.x + radius * cos(CGFloat(angle.radians)),
            y: center.y + radius * sin(CGFloat(angle.radians))
        )
    }
    
    private func angleForTime(timeString: String) -> Angle {
        let components = timeString.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return .zero }
        let totalMinutes = Double(components[0] * 60 + components[1])
        let degrees = (totalMinutes / 1440.0) * 360.0 - 90.0
        return .degrees(degrees)
    }
    
    private func angleForCurrentTime(date: Date) -> Angle {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let second = components.second ?? 0
        let totalSeconds = Double(hour * 3600 + minute * 60 + second)
        let degrees = (totalSeconds / 86400.0) * 360.0 - 90.0
        return .degrees(degrees)
    }
    
    private func formatTime(_ timeString: String) -> String {
        let components = timeString.split(separator: ":")
        guard components.count == 2, let hour = Int(components[0]), let minute = Int(components[1]) else {
            return timeString
        }
        return String(format: "%02d:%02d", hour, minute)
    }
    
    private func calculateBlockAngles(startTime: String, endTime: String) -> (startAngle: Angle, endAngle: Angle, midAngle: Angle) {
        let startAngle = angleForTime(timeString: startTime)
        var endAngle = angleForTime(timeString: endTime)
        
        // Gece yarısını geçen blokları handle et
        if endAngle.degrees < startAngle.degrees {
            endAngle = Angle(degrees: endAngle.degrees + 360)
        }
        
        let midAngleDegrees = (startAngle.degrees + endAngle.degrees) / 2
        let midAngle = Angle(degrees: midAngleDegrees)
        
        return (startAngle, endAngle, midAngle)
    }
}

#if DEBUG
#Preview {
    // Mock data for preview
    let mockSchedule = SharedUserSchedule(
        id: UUID(),
        user: nil,
        name: "Biphasic",
        scheduleDescription: "Test schedule",
        totalSleepHours: 6.5,
        adaptationPhase: 2,
        createdAt: Date(),
        updatedAt: Date(),
        isActive: true
    )
    
    let block1 = SharedSleepBlock(startTime: "23:00", endTime: "05:00", durationMinutes: 360, isCore: true)
    let block2 = SharedSleepBlock(startTime: "13:00", endTime: "13:20", durationMinutes: 20, isCore: false)
    mockSchedule.sleepBlocks = [block1, block2]
    
    return WatchCircularSleepChart(schedule: mockSchedule)
        .frame(width: 180, height: 180)
        .environment(\.colorScheme, .dark)
}
#endif 