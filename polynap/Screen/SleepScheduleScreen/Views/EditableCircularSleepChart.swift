import SwiftUI

struct EditableCircularSleepChart: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @ObservedObject private var chartState: MainScreenChartState
    let chartSize: CircularChartSize
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var activeDragInfo: String?

    @State private var center: CGPoint = .zero
    @State private var radius: CGFloat = 0
    @State private var strokeWidth: CGFloat = 0

    // Sabit label padding — hesaplamada her zaman 8 kullanılır
    private let chartLabelPadding: CGFloat = 8

    // Threshold constants for better UX
    private let dragThreshold: CGFloat = 40 // Chart'tan bu mesafede floating mode'a geçer
    private let snapBackThreshold: CGFloat = 40 // Bu mesafede chart'a geri snap olur

    private var circleRadius: CGFloat { chartSize.radius }
    private var defaultStrokeWidth: CGFloat { chartSize.strokeWidth }
    private let hourMarkers = [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22]

    init(
        viewModel: MainScreenViewModel,
        chartState: MainScreenChartState,
        chartSize: CircularChartSize = .extraLarge,
        activeDragInfo: Binding<String?>
    ) {
        self.viewModel = viewModel
        self._chartState = ObservedObject(wrappedValue: chartState)
        self.chartSize = chartSize
        self._activeDragInfo = activeDragInfo
    }

    var body: some View {
        // GeometryReader yerine onGeometryChange kullanılıyor:
        // GeometryReader tüm chart içeriğini sarması nedeniyle layout değişikliklerinde
        // (örn. hero section açılıp kapandığında) tüm ZStack'i yeniden inşa ediyordu.
        // onGeometryChange sadece genişlik değiştiğinde tetiklenir; ZStack @State üzerinden render eder.
        ZStack {
            if radius > 0 {
                backgroundCircle(center: center, radius: radius, strokeWidth: strokeWidth)
                editableSleepBlocksView(center: center, radius: radius, strokeWidth: strokeWidth)
                hourTickMarks(center: center, radius: radius, strokeWidth: strokeWidth)
                hourMarkersView(center: center, radius: radius, strokeWidth: strokeWidth, labelPadding: chartLabelPadding)
                innerTimeLabelsView(center: center, radius: radius, strokeWidth: strokeWidth)

                if chartState.isChartEditMode {
                    snapIndicators(center: center, radius: radius)

                    // Plus Button - Sağ alt köşe
                    plusButton(center: center, radius: radius, strokeWidth: strokeWidth)

                    // Trash Area - Sol alt köşe
                    trashArea(center: center, radius: radius, strokeWidth: strokeWidth)

                    // Preview Block (deprecated - keeping for backward compatibility)
                    if let previewBlock = chartState.previewBlock {
                        previewBlockView(
                            block: previewBlock,
                            center: center,
                            radius: radius,
                            strokeWidth: strokeWidth
                        )
                    }

                    // Floating Block System
                    if let floatingBlock = chartState.floatingBlock,
                       chartState.isFloatingBlockVisible,
                       chartState.isBlockFloating {
                        handDraggedBlockView(
                            block: floatingBlock,
                            position: chartState.floatingBlockPosition,
                            center: center,
                            radius: radius
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            updateChartGeometry(availableWidth: width)
        }
        .animation(.easeInOut(duration: 0.3), value: chartState.isChartEditMode)
    }

    /// Geometri değiştiğinde (ilk render dahil) @State değerlerini günceller.
    /// Yalnızca gerçekten değiştiğinde state güncellenir — gereksiz re-render engellenir.
    private func updateChartGeometry(availableWidth: CGFloat) {
        guard availableWidth > 0 else { return }
        let labelFontSize = max(8, availableWidth / 35)
        let labelWidthApproximation = labelFontSize * 5
        let totalPadding = defaultStrokeWidth + chartLabelPadding + labelWidthApproximation
        let chartDiameter = availableWidth - totalPadding
        let adjustedRadius = chartDiameter / 2
        let newCenter = CGPoint(x: adjustedRadius + totalPadding / 2, y: adjustedRadius + totalPadding / 2)
        let newStrokeWidth = adjustedRadius * (defaultStrokeWidth / circleRadius)

        if center != newCenter { center = newCenter }
        if radius != adjustedRadius { radius = adjustedRadius }
        if strokeWidth != newStrokeWidth { strokeWidth = newStrokeWidth }
    }
    
    // MARK: - Background Circle with Shimmer Effect

    private func backgroundCircle(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        ZStack {
            // Statik arka plan dairesi — drawingGroup ile tek Metal katmanına alındı
            Circle()
                .stroke(Color.appTextSecondary.opacity(0.12), lineWidth: strokeWidth)
                .frame(width: radius * 2, height: radius * 2)
                .position(center)
                .drawingGroup()

            // Shimmer effect yalnızca edit modda gösteriliyor
            if viewModel.isChartEditMode {
                ShimmerCircle(
                    center: center,
                    radius: radius,
                    strokeWidth: strokeWidth
                )
            }
        }
    }
    
    // MARK: - Hour Tick Marks
    // 24 ayrı Path yerine 2 birleşik Path kullanılıyor — view hiyerarşisi %92 küçüldü

    private func hourTickMarks(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        let outerR = radius + strokeWidth / 2
        let innerR = radius - strokeWidth / 2
        let toRad = Double.pi / 180

        return ZStack {
            // Ana tick'ler (her 3 saatte bir — düz çizgi)
            Path { path in
                for hour in stride(from: 0, to: 24, by: 3) {
                    let angle = Double(hour) * (360.0 / 24.0) - 90
                    let cos = Foundation.cos(angle * toRad)
                    let sin = Foundation.sin(angle * toRad)
                    path.move(to: CGPoint(x: center.x + outerR * cos, y: center.y + outerR * sin))
                    path.addLine(to: CGPoint(x: center.x + innerR * cos, y: center.y + innerR * sin))
                }
            }
            .stroke(Color.appTextSecondary.opacity(0.3), lineWidth: 1)

            // Ara tick'ler (kesik çizgi)
            Path { path in
                for hour in 0..<24 where hour % 3 != 0 {
                    let angle = Double(hour) * (360.0 / 24.0) - 90
                    let cos = Foundation.cos(angle * toRad)
                    let sin = Foundation.sin(angle * toRad)
                    path.move(to: CGPoint(x: center.x + outerR * cos, y: center.y + outerR * sin))
                    path.addLine(to: CGPoint(x: center.x + innerR * cos, y: center.y + innerR * sin))
                }
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .foregroundColor(Color.appTextSecondary.opacity(0.2))
        }
        .drawingGroup() // Tick mark path'lerini tek Metal katmanına flatten et
    }
    
    // MARK: - Hour Markers
    
    private func hourMarkersView(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat, labelPadding: CGFloat) -> some View {
        ZStack {
            ForEach(hourMarkers, id: \.self) { hour in
                hourMarkerLabel(for: hour, center: center, radius: radius, strokeWidth: strokeWidth, labelPadding: labelPadding)
            }
        }
        .drawingGroup() // 12 Text view'ı tek Metal katmanına flatten et
    }
    
    private func hourMarkerLabel(for hour: Int, center: CGPoint, radius: CGFloat, strokeWidth: CGFloat, labelPadding: CGFloat) -> some View {
        let angle = Double(hour) * (360.0 / 24.0) - 90
        let labelRadius = radius + strokeWidth / 2 + labelPadding + 12
        let xPosition = center.x + labelRadius * cos(angle * .pi / 180)
        let yPosition = center.y + labelRadius * sin(angle * .pi / 180)
        
        let availableWidth = 2 * (radius + strokeWidth / 2 + labelPadding)
        let fontSize = max(8, availableWidth / 40)

        return Text(String(format: "%02d:00", hour))
            .font(.system(size: fontSize, weight: .medium))
            .foregroundColor(Color.appTextSecondary.opacity(viewModel.isChartEditMode ? 0.6 : 1.0))
            .position(x: xPosition, y: yPosition)
    }
    
    // MARK: - Editable Sleep Blocks
    
    private func editableSleepBlocksView(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        ZStack {
            let schedule = viewModel.isChartEditMode ? viewModel.tempScheduleBlocks : viewModel.model.schedule.schedule
            
            ForEach(Array(schedule.enumerated()), id: \.element.id) { index, block in
                editableSleepBlockArc(
                    for: block,
                    center: center,
                    radius: radius,
                    strokeWidth: strokeWidth
                )
            }
        }
    }
    
    @ViewBuilder
    private func editableSleepBlockArc(for block: SleepBlock, center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        if let startTimeComponents = TimeFormatter.time(from: block.startTime) {
            let startAngle = angleForTime(hour: startTimeComponents.hour, minute: startTimeComponents.minute)
            let durationHours = Double(block.duration) / 60.0
            let endAngle = startAngle + (durationHours * (360.0 / 24.0))
            
            let isDragged = viewModel.draggedBlockId == block.id
            
            ZStack {
                // Ana blok with drag gesture
                Path { path in
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(startAngle),
                        endAngle: .degrees(endAngle),
                        clockwise: false
                    )
                }
                .stroke(
                    block.isCore ? Color.appPrimary : Color.appSecondary,
                    lineWidth: strokeWidth
                )
                .opacity(isDragged && viewModel.isBlockFloating ? 0.2 : (isDragged ? 0.7 : 0.85))
                .scaleEffect(isDragged ? 1.05 : 1.0)
                .gesture(
                    viewModel.isChartEditMode ?
                    DragGesture(coordinateSpace: .local)
                        .onChanged { value in
                            if viewModel.draggedBlockId == nil && !viewModel.isResizing {
                                viewModel.startDragging(blockId: block.id, at: value.startLocation)
                                // Center bilgisini floating block sistemine ver
                                if let floatingBlock = viewModel.floatingBlock {
                                    viewModel.startFloatingBlock(floatingBlock, at: value.startLocation, center: center, radius: radius)
                                }
                            }
                            
                            if viewModel.draggedBlockId == block.id {
                                // Gerçek drag pozisyonunu hesapla (startLocation + translation)
                                let actualDragPosition = CGPoint(
                                    x: value.startLocation.x + value.translation.width,
                                    y: value.startLocation.y + value.translation.height
                                )
                                
                                // Threshold kontrolü yap
                                let distance = distanceFromCenter(actualDragPosition, center: center)
                                let isWithinThreshold = distance <= (radius + dragThreshold)
                                
                                if isWithinThreshold {
                                    // Threshold içinde - normal chart editing
                                    updateBlockPosition(
                                        blockId: block.id,
                                        to: actualDragPosition,
                                        center: center,
                                        radius: radius
                                    )
                                    // Floating block'u gizle
                                    viewModel.isBlockFloating = false
                                } else {
                                    // Threshold dışında - floating mode
                                    viewModel.isBlockFloating = true
                                }
                                
                                // Her durumda floating sistemi güncelle (trash detection için)
                                viewModel.updateFloatingBlock(
                                    to: actualDragPosition,
                                    center: center,
                                    radius: radius
                                )
                            }
                        }
                        .onEnded { _ in
                            if viewModel.draggedBlockId == block.id {
                                viewModel.endDragging()
                                
                                let lastTime = viewModel.liveBlockTimeString
                                
                                // Set the binding with the final time
                                activeDragInfo = lastTime

                                // After 1 second, clear the binding, but only if a new drag hasn't started
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    if activeDragInfo == lastTime {
                                        activeDragInfo = nil
                                    }
                                }
                                
                                // Clear the internal VM property so it doesn't persist
                                viewModel.liveBlockTimeString = nil
                            }
                        }
                    : nil
                )
                .simultaneousGesture(
                    viewModel.isChartEditMode ?
                    TapGesture().onEnded { viewModel.selectChartBlock(block) }
                    : nil
                )
                
                // Enhanced drag handle sadece edit mode'da
                if viewModel.isChartEditMode && !viewModel.isResizing {
                    enhancedDragHandle(
                        for: block,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        center: center,
                        radius: radius,
                        strokeWidth: strokeWidth
                    )
                }
                
                // Resizing handles
                if viewModel.isChartEditMode {
                    ResizeHandleView(
                        viewModel: viewModel,
                        blockId: block.id,
                        handleType: .start,
                        angle: startAngle,
                        center: center,
                        radius: radius,
                        strokeWidth: strokeWidth
                    )
                    
                    ResizeHandleView(
                        viewModel: viewModel,
                        blockId: block.id,
                        handleType: .end,
                        angle: endAngle,
                        center: center,
                        radius: radius,
                        strokeWidth: strokeWidth
                    )
                }
            }
        }
    }
    
    // MARK: - Enhanced Drag Handle
    
    private func enhancedDragHandle(for block: SleepBlock, startAngle: Double, endAngle: Double, center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        let midAngle = (startAngle + endAngle) / 2
        let handleRadius = radius // - strokeWidth / 4
        
        // Büyük dokunma alanı (44pt minimum)
        let touchAreaSize: CGFloat = max(strokeWidth * 1.5, 44)
        
        let posX = center.x + handleRadius * cos(midAngle * .pi / 180)
        let posY = center.y + handleRadius * sin(midAngle * .pi / 180)
        
        return ZStack {
            // Görsel gösterge
            Circle()
                .fill(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.9))
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(block.isCore ? Color.appPrimary : Color.appSecondary)
                )
                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)


            // Dokunma alanı (görünmez)
            Circle()
                .fill(Color.clear)
                .frame(width: touchAreaSize, height: touchAreaSize)
        }
        .position(x: posX, y: posY)
        .scaleEffect(viewModel.draggedBlockId == block.id ? 1.15 : 1.0)
        
    }
    
    // MARK: - Time Labels (Normal Mode)
    
    private func innerTimeLabelsView(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        ZStack {
            let schedule = viewModel.isChartEditMode ? viewModel.tempScheduleBlocks : viewModel.model.schedule.schedule
            // .indices yerine stabil \.id kullanılıyor — schedule değiştiğinde gereksiz re-create engellendi
            ForEach(schedule, id: \.id) { block in
                timeLabel(for: block, center: center, radius: radius, strokeWidth: strokeWidth)
            }
        }
    }
    
    @ViewBuilder
    private func timeLabel(for block: SleepBlock, center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        if let labelData = generateLabelData(for: block, center: center, radius: radius, strokeWidth: strokeWidth) {
            let isDragged = viewModel.draggedBlockId == block.id
            Group {
                if labelData.isVertical {
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
            .opacity(viewModel.isChartEditMode && isDragged && viewModel.isBlockFloating ? 0 : (viewModel.isChartEditMode && isDragged ? 0.3 : 1))
        }
    }
    
    // MARK: - Snap Indicators
    
    private func snapIndicators(center: CGPoint, radius: CGFloat) -> some View {
        // 288 ayrı Circle view yerine tek Path — view hiyerarşisi dramatik şekilde küçüldü
        let indicatorRadius = radius + 8
        let toRad = Double.pi / 180

        return Path { path in
            for index in 0..<288 {
                let angle = Double(index * 5) * (360.0 / (24.0 * 60.0)) - 90
                let x = center.x + indicatorRadius * CGFloat(Foundation.cos(angle * toRad))
                let y = center.y + indicatorRadius * CGFloat(Foundation.sin(angle * toRad))
                path.addEllipse(in: CGRect(x: x - 1, y: y - 1, width: 2, height: 2))
            }
        }
        .fill(Color.appAccent.opacity(0.3))
    }
    
    // MARK: - Helper Functions
    
    private func angleForTime(hour: Int, minute: Int) -> Double {
        let totalMinutes = Double(hour * 60 + minute)
        return (totalMinutes / (24 * 60)) * 360 - 90
    }
    
    /// Merkez noktaya olan mesafeyi hesaplar
    private func distanceFromCenter(_ position: CGPoint, center: CGPoint) -> CGFloat {
        let dx = position.x - center.x
        let dy = position.y - center.y
        return sqrt(dx * dx + dy * dy)
    }
    
    private func normalizeAngle(_ angle: Double) -> Double {
        var normalized = angle
        while normalized < 0 {
            normalized += 360
        }
        while normalized >= 360 {
            normalized -= 360
        }
        return normalized
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
        guard let startTimeComponents = TimeFormatter.time(from: block.startTime) else { return nil }
        let endTimeComponents = TimeFormatter.time(from: block.endTime) ?? (0, 0)
        
        let startAngle = angleForTime(hour: startTimeComponents.hour, minute: startTimeComponents.minute)
        let endAngle = angleForTime(hour: endTimeComponents.hour, minute: endTimeComponents.minute)
        
        var adjustedEndAngle = endAngle
        if endAngle < startAngle {
            adjustedEndAngle = endAngle + 360
        }
        
        let midAngle = (startAngle + adjustedEndAngle) / 2
        let normalizedAngle = normalizeAngle(midAngle)
        
        let isVertical = (normalizedAngle >= 315 || normalizedAngle <= 45) || (normalizedAngle >= 135 && normalizedAngle <= 225)
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
    
    // MARK: - Block Position Update
    
    /// Bloğun pozisyonunu günceller (5 dakika snap ile)
    private func updateBlockPosition(blockId: UUID, to position: CGPoint, center: CGPoint, radius: CGFloat) {
        guard viewModel.draggedBlockId == blockId else { return }
        
        // Pozisyondan direkt zamanı hesapla (basit ve güvenilir)
        let newStartTime = viewModel.getCurrentTimeFromPosition(position, center: center)
        
        // Temp schedule'da bloğu güncelle
        if let blockIndex = viewModel.tempScheduleBlocks.firstIndex(where: { $0.id == blockId }) {
            let currentBlock = viewModel.tempScheduleBlocks[blockIndex]
            
            // Yeni start time ile end time'ı hesapla
            let newEndTime = TimeUtility.adjustTime(newStartTime, byMinutes: currentBlock.duration) ?? newStartTime
            
            // Canlı zaman gösterimini güncelle
            let timeString = "\(newStartTime) - \(newEndTime)"
            viewModel.liveBlockTimeString = timeString
            activeDragInfo = timeString
            
            // Collision detection - diğer bloklar ile çakışma kontrolü
            if !viewModel.hasCollisionInTemp(
                blockId: blockId,
                startTime: newStartTime,
                endTime: newEndTime
            ) {
                // Yeni SleepBlock oluştur (immutable property'ler nedeniyle, ID'yi koru)
                let newBlock = SleepBlock(
                    id: currentBlock.id,
                    startTime: newStartTime,
                    duration: currentBlock.duration,
                    type: currentBlock.type,
                    isCore: currentBlock.isCore
                )
                viewModel.tempScheduleBlocks[blockIndex] = newBlock
            }
        }
    }
    

}

// MARK: - Resize Handle View
struct ResizeHandleView: View {
    @ObservedObject var viewModel: MainScreenViewModel
    let blockId: UUID
    let handleType: MainScreenViewModel.ResizeHandle
    let angle: Double
    let center: CGPoint
    let radius: CGFloat
    let strokeWidth: CGFloat
    
    private var isBeingResized: Bool {
        viewModel.resizeBlockId == blockId && viewModel.resizeHandle == handleType
    }
    
    var body: some View {
        let handleRadius: CGFloat = radius
        let posX = center.x + handleRadius * cos(angle * .pi / 180)
        let posY = center.y + handleRadius * sin(angle * .pi / 180)
        let touchAreaSize: CGFloat = max(strokeWidth, 44)
        
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: isBeingResized ? 20 : 14, height: isBeingResized ? 20 : 14)
                .overlay(
                    Circle()
                        .stroke(Color.appPrimary, lineWidth: 2)
                )
                .shadow(radius: 2)
            
            Circle()
                .fill(Color.clear)
                .frame(width: touchAreaSize, height: touchAreaSize)
        }
        .position(x: posX, y: posY)
        .gesture(
            DragGesture(coordinateSpace: .local)
                .onChanged { value in
                    if !viewModel.isResizing {
                        viewModel.startResizing(blockId: blockId, handle: handleType, at: value.location, center: center)
                    }
                    viewModel.updateResize(to: value.location, center: center, radius: radius)
                }
                .onEnded { _ in
                    viewModel.endResizing()
                }
        )
    }
}


// MARK: - Shimmer Effect Component

struct ShimmerCircle: View {
    let center: CGPoint
    let radius: CGFloat
    let strokeWidth: CGFloat
    
    @State private var rotation: Double = 0
    
    var body: some View {
        Circle()
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [
                        Color.appTextSecondary.opacity(0.0),
                        Color.appTextSecondary.opacity(0.1),
                        Color.appTextSecondary.opacity(0.2),
                        Color.appTextSecondary.opacity(0.1),
                        Color.appTextSecondary.opacity(0.0)
                    ]),
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360)
                ),
                lineWidth: strokeWidth
            )
            .frame(width: radius * 2, height: radius * 2)
            .position(center)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Plus Button Component

extension EditableCircularSleepChart {
    
    // MARK: - Plus Button
    
    private func plusButton(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        let buttonRadius: CGFloat = 28
        // Kartın sağ alt köşesine hizala (butonun merkezi köşede olacak)
        let buttonPosition = CGPoint(
            x: center.x + radius - strokeWidth / 2 + buttonRadius * 1.5,
            y: center.y + radius + strokeWidth + buttonRadius * 0.5
        )
        
        return ZStack {
            // Background circle - FAB style with drag state
            Circle()
                .fill(viewModel.isDraggingNewBlock ? Color.appAccent.opacity(0.8) : Color.appAccent)
                .frame(width: buttonRadius * 2, height: buttonRadius * 2)
                .shadow(
                    color: viewModel.isDraggingNewBlock ? Color.appAccent.opacity(0.2) : Color.appAccent.opacity(0.3), 
                    radius: viewModel.isDraggingNewBlock ? 6 : 8, 
                    x: 0, 
                    y: viewModel.isDraggingNewBlock ? 3 : 4
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            // Plus icon
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            // Touch area (invisible, larger for better UX)
            Circle()
                .fill(Color.clear)
                .frame(width: 70, height: 70)
        }
        .position(buttonPosition)
        //.scaleEffect(viewModel.isDraggingNewBlock ? 1. : 1.0)
        .opacity(1.0)
        .accessibilityLabel("Add new sleep block")
        .accessibilityHint("Drag to chart to add a 45-minute sleep block")
        .gesture(
            DragGesture(coordinateSpace: .local)
                .onChanged { value in
                    if !viewModel.isDraggingNewBlock {
                        viewModel.startDraggingNewBlock(at: value.location, center: center, radius: radius)
                    }
                    viewModel.updateNewBlockDrag(to: value.location, center: center, radius: radius)
                }
                .onEnded { _ in
                    viewModel.endNewBlockDrag()
                }
        )
    }
    
    // MARK: - Trash Area
    
    private func trashArea(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        let trashRadius: CGFloat = 28 // + butonu ile aynı boyut
        // Kartın sol alt köşesine hizala (butonun merkezi köşede olacak)
        let trashPosition = CGPoint(
            x: center.x - radius + strokeWidth / 2 - trashRadius * 1.5,
            y: center.y + radius + strokeWidth + trashRadius * 0.5
        )
        
        return ZStack {
            // Background circle - FAB style matching plus button
            Circle()
                .fill(viewModel.isInTrashZone ? Color.appError : Color.appError.opacity(0.9))
                .frame(width: trashRadius * 2, height: trashRadius * 2)
                .shadow(
                    color: viewModel.isInTrashZone ? Color.appError.opacity(0.3) : Color.appError.opacity(0.2), 
                    radius: viewModel.isInTrashZone ? 6 : 8, 
                    x: 0, 
                    y: viewModel.isInTrashZone ? 3 : 4
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            // Trash icon
            Image(systemName: "trash")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            // Touch area (invisible, larger for better UX)
            Circle()
                .fill(Color.clear)
                .frame(width: 70, height: 70)
        }
        .position(trashPosition)
        .opacity(1.0)
        .accessibilityLabel("Delete area")
        .accessibilityHint("Drag sleep blocks here to delete them")
        .accessibilityValue(viewModel.isInTrashZone ? "Ready to delete" : "Inactive")
    }
    
    // MARK: - Preview Block
    
    private func previewBlockView(block: SleepBlock, center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        guard let startTimeComponents = TimeFormatter.time(from: block.startTime) else {
            return AnyView(EmptyView())
        }
        
        let startAngle = angleForTime(hour: startTimeComponents.hour, minute: startTimeComponents.minute)
        let durationHours = Double(block.duration) / 60.0
        let endAngle = startAngle + (durationHours * (360.0 / 24.0))
        
        // Normal sleep block gibi göster - 45 dk olduğu için secondary color
        let blockColor = viewModel.isDragFromPlusValid ? 
            (block.isCore ? Color.appPrimary : Color.appSecondary) : 
            Color.appError
        
        return AnyView(
            Path { path in
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(endAngle),
                    clockwise: false
                )
            }
            .stroke(
                blockColor,
                lineWidth: strokeWidth
            )
            .opacity(viewModel.isDragFromPlusValid ? 0.8 : 0.5)
            .scaleEffect(1.02) // Biraz büyük göster ki dikkat çeksin
            .accessibilityLabel("Preview sleep block")
            .accessibilityValue(viewModel.isDragFromPlusValid ? "Valid position" : "Invalid position")
        )
    }
    
    // MARK: - Hand-Dragged Block Visual
    
    private func handDraggedBlockView(block: SleepBlock, position: CGPoint, center: CGPoint, radius: CGFloat) -> some View {
        let blockColor = block.isCore ? Color.appPrimary : Color.appSecondary
        let isInTrash = viewModel.isInTrashZone
        let blockEmoji = block.isCore ? "🌙" : "💤"
        let timeRange = "\(TimeFormatter.formattedString(from: block.startTime)) - \(block.endTime)"
        
        return VStack(spacing: 4) {
            Text(blockEmoji)
                .font(.system(size: 24))
            
            Text(timeRange)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
            
            Text("\(block.duration) min")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isInTrash ? Color.red : blockColor)
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isInTrash ? 1.1 : 1.0)
        .drawingGroup()
        .position(position)
        .accessibilityLabel("Dragging sleep block")
        .accessibilityValue("Duration: \(block.duration) minutes, Time: \(timeRange)")
        }
    
}
