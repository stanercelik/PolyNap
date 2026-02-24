import SwiftUI

struct CommitmentScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    @State private var lines: [[CGPoint]] = []
    @State private var currentLine: [CGPoint] = []
    @State private var hasDrawn = false
    @State private var showCanvas = false
    @State private var showButton = false
    
    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var holdTimer: Timer?
    @State private var isTransitioning = false
    @State private var lastHapticProgress: CGFloat = 0
    @State private var buttonCenter: CGPoint = .zero
    
    private let holdDuration: Double = 1.8
    
    var body: some View {
        GeometryReader { geometry in
            let screenSize = geometry.size
            
            ZStack {
                StarsBackground(count: 6, color: .white.opacity(0.3))
                
                VStack(spacing: OBSpacing.md) {
                    Spacer()
                        .frame(height: OBSpacing.xl)
                    
                    FadeInText(
                        "son bir şey.",
                        font: OBFont.title,
                        color: .white,
                        delay: 0.3
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, OBSpacing.lg)
                    
                    FadeInText(
                        "kendine bir söz ver.\nbir imza, bir çizim, bir kelime.\nne istersen.",
                        font: OBFont.body,
                        color: .white.opacity(0.8),
                        delay: 1.2
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, OBSpacing.lg)
                    
                    if showCanvas {
                        drawingArea
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            .padding(.horizontal, OBSpacing.lg)
                            .padding(.top, OBSpacing.sm)
                    }
                    
                    Spacer()
                    
                    if showButton && hasDrawn {
                        fingerprintSection
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .padding(.bottom, OBSpacing.xxl)
                    }
                }
                
                if (holdProgress > 0 || isTransitioning) && buttonCenter != .zero {
                    let maxDist = maxCornerDistance(from: buttonCenter, in: screenSize)
                    let neededScale = maxDist / 40 + 1
                    
                    Circle()
                        .fill(OBColors.primaryColor)
                        .frame(width: 80, height: 80)
                        .scaleEffect(1 + holdProgress * (neededScale - 1))
                        .position(buttonCenter)
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }
            }
            .coordinateSpace(name: "commitmentSpace")
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showCanvas = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.spring(response: 0.5)) {
                    showButton = true
                }
            }
        }
    }
    
    // MARK: - Drawing Area
    
    private var drawingArea: some View {
        ZStack(alignment: .bottomTrailing) {
            Canvas { context, size in
                for line in lines {
                    drawLine(line, in: &context)
                }
                drawLine(currentLine, in: &context)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        currentLine.append(value.location)
                        if !hasDrawn {
                            withAnimation(.spring(response: 0.4)) {
                                hasDrawn = true
                            }
                        }
                    }
                    .onEnded { _ in
                        if !currentLine.isEmpty {
                            lines.append(currentLine)
                            currentLine = []
                        }
                    }
            )
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .overlay(alignment: .center) {
                if !hasDrawn {
                    VStack(spacing: 8) {
                        Image(systemName: "hand.draw")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.3))
                        Text("buraya çiz veya yaz")
                            .font(OBFont.caption)
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
            }
            
            if hasDrawn {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        lines = []
                        currentLine = []
                        hasDrawn = false
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(10)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                .padding(12)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private func drawLine(_ line: [CGPoint], in context: inout GraphicsContext) {
        guard line.count > 1 else { return }
        var path = Path()
        path.move(to: line[0])
        
        if line.count == 2 {
            path.addLine(to: line[1])
        } else {
            for i in 1..<line.count {
                let mid = CGPoint(
                    x: (line[i - 1].x + line[i].x) / 2,
                    y: (line[i - 1].y + line[i].y) / 2
                )
                path.addQuadCurve(to: mid, control: line[i - 1])
            }
            if let last = line.last {
                path.addLine(to: last)
            }
        }
        
        context.stroke(
            path,
            with: .color(.white.opacity(0.9)),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        )
    }
    
    // MARK: - Fingerprint Button
    
    private var fingerprintSection: some View {
        VStack(spacing: 12) {
            Text(isHolding ? "basılı tut..." : "başlamak için basılı tut")
                .font(OBFont.caption)
                .foregroundColor(.white.opacity(0.5))
                .animation(.easeInOut(duration: 0.2), value: isHolding)
            
            Circle()
                .fill(OBColors.primaryColor.opacity(0.2))
                .frame(width: 80, height: 80)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                let frame = geo.frame(in: .named("commitmentSpace"))
                                buttonCenter = CGPoint(x: frame.midX, y: frame.midY)
                            }
                            .onChange(of: geo.size) { _ in
                                let frame = geo.frame(in: .named("commitmentSpace"))
                                buttonCenter = CGPoint(x: frame.midX, y: frame.midY)
                            }
                    }
                )
                .overlay(
                    Image(systemName: "touchid")
                        .font(.system(size: 34, weight: .light))
                        .foregroundColor(.white.opacity(0.8))
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isHolding && !isTransitioning {
                                isHolding = true
                                startHold()
                            }
                        }
                        .onEnded { _ in
                            if !isTransitioning {
                                isHolding = false
                                cancelHold()
                            }
                        }
                )
        }
    }
    
    // MARK: - Hold Logic
    
    private func startHold() {
        holdProgress = 0
        lastHapticProgress = 0
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        let interval: Double = 1.0 / 60.0
        holdTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                guard isHolding, !isTransitioning else { return }
                
                holdProgress += CGFloat(interval / holdDuration)
                
                let hapticStep: CGFloat = 0.06
                if holdProgress - lastHapticProgress >= hapticStep {
                    lastHapticProgress = holdProgress
                    if holdProgress < 0.35 {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } else if holdProgress < 0.75 {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } else {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    }
                }
                
                if holdProgress >= 1.0 {
                    holdProgress = 1.0
                    holdTimer?.invalidate()
                    holdTimer = nil
                    completeHold()
                }
            }
        }
    }
    
    private func cancelHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            holdProgress = 0
        }
    }
    
    private func completeHold() {
        isTransitioning = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            Task { await viewModel.completeOnboarding() }
        }
    }
    
    // MARK: - Helpers
    
    private func maxCornerDistance(from point: CGPoint, in size: CGSize) -> CGFloat {
        let corners = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: size.width, y: 0),
            CGPoint(x: 0, y: size.height),
            CGPoint(x: size.width, y: size.height)
        ]
        return corners.map { hypot($0.x - point.x, $0.y - point.y) }.max() ?? size.height
    }
}

#Preview {
    CommitmentScreen(viewModel: NewOnboardingViewModel())
        .background(OBColors.darkNavy.ignoresSafeArea())
}
