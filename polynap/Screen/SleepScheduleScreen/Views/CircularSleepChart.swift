import SwiftUI

enum CircularChartSize {
    case small
    case medium
    case large
    case extraLarge
    
    var radius: CGFloat {
        switch self {
        case .small: return 60
        case .medium: return 80
        case .large: return 100
        case .extraLarge: return 140
        }
    }
    
    var strokeWidth: CGFloat {
        switch self {
        case .small: return 20
        case .medium: return 28
        case .large: return 35
        case .extraLarge: return 45
        }
    }
}

struct CircularSleepChart: View {
    let schedule: SleepScheduleModel
    let textOpacity: Double
    let isEditing: Bool
    let chartSize: CircularChartSize
    @Environment(\.colorScheme) var colorScheme

    private var circleRadius: CGFloat { chartSize.radius }
    private var strokeWidth: CGFloat { chartSize.strokeWidth }
    private let hourMarkers = [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22]

    init(
        schedule: SleepScheduleModel,
        textOpacity: Double = 1.0,
        isEditing: Bool = false,
        chartSize: CircularChartSize = .large
    ) {
        self.schedule = schedule
        self.textOpacity = textOpacity
        self.isEditing = isEditing
        self.chartSize = chartSize
    }

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let labelFontSize = max(8, availableWidth / 35) // Yazı boyutunu ayarla
            let labelWidthApproximation = labelFontSize * 5 // "22:00" için yaklaşık genişlik
            let labelPadding: CGFloat = 8 // Etiket ve daire arasındaki boşluk

            // strokeWidth ve etiketler için gereken toplam alanı hesaba kat
            let totalPadding = strokeWidth + labelPadding + labelWidthApproximation
            let chartDiameter = availableWidth - totalPadding
            let adjustedRadius = chartDiameter / 2
            let center = CGPoint(x: availableWidth / 2, y: availableWidth / 2)
            
            VStack {
                ZStack {
                    backgroundCircle(center: center, radius: adjustedRadius, strokeWidth: strokeWidth)
                    sleepBlocksView(center: center, radius: adjustedRadius, strokeWidth: strokeWidth)
                    hourTickMarks(center: center, radius: adjustedRadius, strokeWidth: strokeWidth)
                        .opacity(textOpacity)
                    hourMarkersView(center: center, radius: adjustedRadius, strokeWidth: strokeWidth, labelPadding: labelPadding)
                        .opacity(textOpacity)
                    innerTimeLabelsView(center: center, radius: adjustedRadius, strokeWidth: strokeWidth)
                        .opacity(textOpacity)
                }
            }
            .frame(width: availableWidth, height: availableWidth) // ZStack'i sarmalayan VStack'e tam genişlik ver
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.easeInOut(duration: 0.3), value: textOpacity)
        .animation(.easeInOut(duration: 0.3), value: isEditing)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(generateAccessibilityLabel())
    }
    
    // MARK: - Alt Görünümler
    
    private func backgroundCircle(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        Circle()
            .stroke(Color.appTextSecondary.opacity(0.12), lineWidth: strokeWidth)
            .frame(width: radius * 2, height: radius * 2)
            .position(center)
            .drawingGroup()
    }
    
    // 24 ayrı Path yerine 2 birleşik Path — view sayısı %92 azaldı
    private func hourTickMarks(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        let outerR = radius + strokeWidth / 2
        let innerR = radius - strokeWidth / 2
        let toRad = Double.pi / 180

        return ZStack {
            Path { path in
                for hour in stride(from: 0, to: 24, by: 3) {
                    let angle = Double(hour) * (360.0 / 24.0) - 90
                    let c = Foundation.cos(angle * toRad)
                    let s = Foundation.sin(angle * toRad)
                    path.move(to: CGPoint(x: center.x + outerR * c, y: center.y + outerR * s))
                    path.addLine(to: CGPoint(x: center.x + innerR * c, y: center.y + innerR * s))
                }
            }
            .stroke(Color.appTextSecondary.opacity(0.3), lineWidth: 1)

            Path { path in
                for hour in 0..<24 where hour % 3 != 0 {
                    let angle = Double(hour) * (360.0 / 24.0) - 90
                    let c = Foundation.cos(angle * toRad)
                    let s = Foundation.sin(angle * toRad)
                    path.move(to: CGPoint(x: center.x + outerR * c, y: center.y + outerR * s))
                    path.addLine(to: CGPoint(x: center.x + innerR * c, y: center.y + innerR * s))
                }
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .foregroundColor(Color.appTextSecondary.opacity(0.2))
        }
    }
    
    private func hourMarkersView(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat, labelPadding: CGFloat) -> some View {
        ZStack {
            ForEach(hourMarkers, id: \.self) { hour in
                hourMarkerLabel(for: hour, center: center, radius: radius, strokeWidth: strokeWidth, labelPadding: labelPadding)
            }
        }
    }
    
    private func hourMarkerLabel(for hour: Int, center: CGPoint, radius: CGFloat, strokeWidth: CGFloat, labelPadding: CGFloat) -> some View {
        let angle = Double(hour) * (360.0 / 24.0) - 90
        let labelRadius = radius + strokeWidth / 2 + labelPadding + 12 // 12, metnin kendi genişliğinin yarısı için bir tampon
        let xPosition = center.x + labelRadius * cos(angle * .pi / 180)
        let yPosition = center.y + labelRadius * sin(angle * .pi / 180)
        
        let availableWidth = 2 * (radius + strokeWidth / 2 + labelPadding) // Yaklaşık olarak kullanılabilir genişlik
        let fontSize = max(8, availableWidth / 40)

        return Text(String(format: "%02d:00", hour))
            .font(.system(size: fontSize, weight: .medium))
            .foregroundColor(Color.appTextSecondary)
            .position(x: xPosition, y: yPosition)
    }
    
    private func sleepBlocksView(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        ZStack {
            ForEach(schedule.schedule.indices, id: \.self) { index in
                sleepBlockArc(for: schedule.schedule[index], center: center, radius: radius, strokeWidth: strokeWidth)
            }
        }
    }
    
    @ViewBuilder
    private func sleepBlockArc(for block: SleepBlock, center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        // Düzeltilmiş time parsing - String formatından direkt parse et
        if let startTimeComponents = TimeFormatter.time(from: block.startTime) {
            let startAngle = angleForTime(hour: startTimeComponents.hour, minute: startTimeComponents.minute)
            let durationHours = Double(block.duration) / 60.0
            let endAngle = startAngle + (durationHours * (360.0 / 24.0))
            
            Path { path in
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(endAngle),
                    clockwise: false
                )
            }
            .stroke(block.isCore ? Color.appPrimary : Color.appSecondary, lineWidth: strokeWidth)
            .opacity(0.85)
        } else {
            EmptyView()
                .onAppear {
                    print("⚠️ CircularSleepChart: Geçersiz startTime formatı: \(block.startTime)")
                }
        }
    }
    
    private func innerTimeLabelsView(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        ZStack {
            ForEach(schedule.schedule.indices, id: \.self) { index in
                timeLabel(for: schedule.schedule[index], center: center, radius: radius, strokeWidth: strokeWidth)
            }
        }
    }
    
    @ViewBuilder
    private func timeLabel(for block: SleepBlock, center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        if let labelData = generateLabelData(for: block, center: center, radius: radius, strokeWidth: strokeWidth) {
            Group {
                if labelData.isVertical {
                    // Dikey layout - sağ/sol tarafta (alt alta)
                    VStack(spacing: 1) {
                        Text(labelData.startTimeStr)
                            .font(.system(size: labelData.fontSize, weight: .semibold))
                        Text(labelData.endTimeStr)
                            .font(.system(size: labelData.fontSize, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, labelData.isLongBlock ? 6 : 4)
                    .padding(.vertical, labelData.isLongBlock ? 3 : 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.black.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            )
                    )
                    .position(x: labelData.xPosition, y: labelData.yPosition)
                } else {
                    // Yatay layout - üst/alt tarafta (yan yana)
                    HStack(spacing: 2) {
                        Text(labelData.startTimeStr)
                            .font(.system(size: labelData.fontSize, weight: .semibold))
                        Text("-")
                            .font(.system(size: labelData.fontSize - 1, weight: .medium))
                        Text(labelData.endTimeStr)
                            .font(.system(size: labelData.fontSize, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, labelData.isLongBlock ? 6 : 4)
                    .padding(.vertical, labelData.isLongBlock ? 3 : 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.black.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            )
                    )
                    .position(x: labelData.xPosition, y: labelData.yPosition)
                }
            }
        } else {
            EmptyView()
        }
    }
    
    private struct LabelData {
        let startTimeStr: String
        let endTimeStr: String
        let isVertical: Bool
        let isLongBlock: Bool
        let fontSize: CGFloat
        let xPosition: CGFloat
        let yPosition: CGFloat
    }
    
    private func generateLabelData(for block: SleepBlock, center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> LabelData? {
        // Düzeltilmiş time parsing
        guard let startTimeComponents = TimeFormatter.time(from: block.startTime) else {
            print("⚠️ CircularSleepChart.generateLabelData: Geçersiz startTime formatı: \(block.startTime)")
            return nil
        }
        
        let endTimeComponents = TimeFormatter.time(from: block.endTime) ?? (0, 0)
        
        // Başlangıç ve bitiş açıları
        let startAngle = angleForTime(hour: startTimeComponents.hour, minute: startTimeComponents.minute)
        let endAngle = angleForTime(hour: endTimeComponents.hour, minute: endTimeComponents.minute)
        
        // Gece yarısını geçen uyku bloklarını doğru şekilde hesapla
        var adjustedEndAngle = endAngle
        if endAngle < startAngle {
            adjustedEndAngle = endAngle + 360
        }
        
        // Bloğun ortasında tek bir etiket göster
        let midAngle = (startAngle + adjustedEndAngle) / 2
        
        // Açıyı normalize et
        let normalizedAngle = normalizeAngle(midAngle)
        
        // Etiket yönünü belirle
        let isVertical = (normalizedAngle >= 315 || normalizedAngle <= 45) || (normalizedAngle >= 135 && normalizedAngle <= 225)
        
        // Responsive font size ve positioning
        let isLongBlock = block.duration > 90
        let fontSize = max(7, radius / 12)
        let labelRadius = radius - strokeWidth / 2 - (isLongBlock ? 24 : 28) // 18/22'den 24/28'e artırıldı (daha uzağa)
        let xPosition = center.x + labelRadius * cos(midAngle * .pi / 180)
        let yPosition = center.y + labelRadius * sin(midAngle * .pi / 180)
        
        let startTimeStr = String(format: "%02d:%02d", startTimeComponents.hour, startTimeComponents.minute)
        let endTimeStr = String(format: "%02d:%02d", endTimeComponents.hour, endTimeComponents.minute)
        
        return LabelData(
            startTimeStr: startTimeStr,
            endTimeStr: endTimeStr,
            isVertical: isVertical,
            isLongBlock: isLongBlock,
            fontSize: fontSize,
            xPosition: xPosition,
            yPosition: yPosition
        )
    }
    
    private func normalizeAngle(_ angle: Double) -> Double {
        var normalizedAngle = angle
        while normalizedAngle < 0 {
            normalizedAngle += 360
        }
        while normalizedAngle >= 360 {
            normalizedAngle -= 360
        }
        return normalizedAngle
    }
    
    // MARK: - Yardımcı Fonksiyonlar
    
    private func angleForTime(hour: Int, minute: Int) -> Double {
        let totalMinutes = Double(hour * 60 + minute)
        return (totalMinutes / (24 * 60)) * 360 - 90
    }
    
    private func generateAccessibilityLabel() -> String {
        var descriptions: [String] = []
        for (index, block) in schedule.schedule.enumerated() {
            guard let startTimeComponents = TimeFormatter.time(from: block.startTime) else { continue }
            let endTimeComponents = TimeFormatter.time(from: block.endTime) ?? (0, 0)
            let startTimeStr = String(format: "%02d:%02d", startTimeComponents.hour, startTimeComponents.minute)
            let endTimeStr = String(format: "%02d:%02d", endTimeComponents.hour, endTimeComponents.minute)
            let blockType = block.isCore ?
                NSLocalizedString("sleepBlock.core", tableName: "MainScreen", comment: "Core sleep block") :
                NSLocalizedString("sleepBlock.nap", tableName: "MainScreen", comment: "Nap block")
            let description = String(
                format: NSLocalizedString("sleepBlock.description", tableName: "MainScreen", comment: "Sleep block description format"),
                arguments: ["\(index + 1)", blockType, startTimeStr, endTimeStr]
            )
            descriptions.append(description)
        }
        let scheduleDescription = descriptions.joined(separator: ". ")
        return String(
            format: NSLocalizedString("sleepSchedule.description", tableName: "MainScreen", comment: "Sleep schedule description"),
            arguments: [scheduleDescription]
        )
    }
}
