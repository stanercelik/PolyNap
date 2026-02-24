import SwiftUI

// MARK: - Sequential Fade-In Text
struct FadeInText: View {
    let text: String
    let font: Font
    let color: Color
    let delay: Double
    let duration: Double
    
    @State private var isVisible = false
    
    init(
        _ text: String,
        font: Font = OBFont.body,
        color: Color = OBColors.textPrimary,
        delay: Double = 0,
        duration: Double = 0.75
    ) {
        self.text = text
        self.font = font
        self.color = color
        self.delay = delay
        self.duration = duration
    }
    
    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: duration).delay(delay), value: isVisible)
            .onAppear { isVisible = true }
    }
}

// MARK: - Attributed Fade-In Text (with highlight support)
struct FadeInAttributedText: View {
    let segments: [(text: String, isHighlight: Bool)]
    let font: Font
    let color: Color
    let highlightColor: Color
    let highlightFont: Font?
    let delay: Double
    let duration: Double
    
    @State private var isVisible = false
    
    init(
        segments: [(text: String, isHighlight: Bool)],
        font: Font = OBFont.body,
        color: Color = OBColors.textPrimary,
        highlightColor: Color = OBColors.accentBlue,
        highlightFont: Font? = nil,
        delay: Double = 0,
        duration: Double = 0.75
    ) {
        self.segments = segments
        self.font = font
        self.color = color
        self.highlightColor = highlightColor
        self.highlightFont = highlightFont
        self.delay = delay
        self.duration = duration
    }
    
    var body: some View {
        buildText()
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: duration).delay(delay), value: isVisible)
            .onAppear { isVisible = true }
    }
    
    private func buildText() -> Text {
        var result = Text("")
        for segment in segments {
            if segment.isHighlight {
                result = result + Text(segment.text)
                    .font(highlightFont ?? font)
                    .foregroundColor(highlightColor)
                    .bold()
            } else {
                result = result + Text(segment.text)
                    .font(font)
                    .foregroundColor(color)
            }
        }
        return result
    }
}

// MARK: - Fade-In View Wrapper
struct FadeIn<Content: View>: View {
    let delay: Double
    let duration: Double
    let content: () -> Content
    
    @State private var isVisible = false
    
    init(
        delay: Double = 0,
        duration: Double = 0.75,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.delay = delay
        self.duration = duration
        self.content = content
    }
    
    var body: some View {
        content()
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: duration).delay(delay), value: isVisible)
            .onAppear { isVisible = true }
    }
}

// MARK: - Breathing Animation Modifier
struct BreathingAnimation: ViewModifier {
    @State private var scale: CGFloat = 1.0
    let minScale: CGFloat
    let maxScale: CGFloat
    let duration: Double
    
    init(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 3.0) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    scale = maxScale
                }
            }
    }
}

extension View {
    func breathingAnimation(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 3.0) -> some View {
        modifier(BreathingAnimation(minScale: minScale, maxScale: maxScale, duration: duration))
    }
}

// MARK: - Slow Rotation
struct SlowRotation: ViewModifier {
    @State private var angle: Double = 0
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
            .onAppear {
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    angle = 360
                }
            }
    }
}

extension View {
    func slowRotation(duration: Double = 20) -> some View {
        modifier(SlowRotation(duration: duration))
    }
}

// MARK: - Floating Animation
struct FloatingAnimation: ViewModifier {
    @State private var offset: CGFloat = 0
    let amplitude: CGFloat
    let duration: Double
    
    init(amplitude: CGFloat = 6, duration: Double = 2.5) {
        self.amplitude = amplitude
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    offset = -amplitude
                }
            }
    }
}

extension View {
    func floating(amplitude: CGFloat = 6, duration: Double = 2.5) -> some View {
        modifier(FloatingAnimation(amplitude: amplitude, duration: duration))
    }
}

// MARK: - Star Particle View
struct StarParticle: View {
    let size: CGFloat
    let color: Color
    @State private var opacity: Double = 0.3
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size))
            .foregroundColor(color)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: Double.random(in: 1.5...3.0)).repeatForever(autoreverses: true)) {
                    opacity = Double.random(in: 0.6...1.0)
                    scale = CGFloat.random(in: 0.9...1.2)
                }
            }
    }
}

// MARK: - Stars Background
struct StarsBackground: View {
    let count: Int
    let color: Color
    
    init(count: Int = 8, color: Color = .white.opacity(0.6)) {
        self.count = count
        self.color = color
    }
    
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<count, id: \.self) { i in
                StarParticle(
                    size: CGFloat.random(in: 8...16),
                    color: color
                )
                .position(
                    x: CGFloat.random(in: 0...geo.size.width),
                    y: CGFloat.random(in: 0...geo.size.height)
                )
                .floating(amplitude: CGFloat.random(in: 3...8), duration: Double.random(in: 2...4))
            }
        }
    }
}

// MARK: - Confetti Effect
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    let colors: [Color]
    let count: Int
    
    init(colors: [Color] = [OBColors.accentBlue, .white, OBColors.accentBlue.opacity(0.6), OBColors.starGold], count: Int = 40) {
        self.colors = colors
        self.count = count
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geo.size)
                animateParticles(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<count).map { _ in
            ConfettiParticle(
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 4...10),
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                opacity: 1.0
            )
        }
    }
    
    private func animateParticles(in size: CGSize) {
        for i in particles.indices {
            let delay = Double.random(in: 0...1.5)
            let duration = Double.random(in: 2...4)
            withAnimation(.easeIn(duration: duration).delay(delay)) {
                particles[i].position = CGPoint(
                    x: particles[i].position.x + CGFloat.random(in: -60...60),
                    y: size.height + 20
                )
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

// MARK: - Glow Effect
struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    @State private var glowing = false
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(glowing ? 0.6 : 0.2), radius: radius)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    glowing = true
                }
            }
    }
}

extension View {
    func glowEffect(color: Color = OBColors.accentBlue, radius: CGFloat = 20) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
}

// MARK: - Auto-Scrolling ScrollView
struct AutoScrollView<Content: View>: View {
    let content: () -> Content
    @State private var contentHeight: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0
    @State private var scrollProxy: ScrollViewProxy?
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    content()
                    
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: ContentHeightKey.self, value: geo.size.height)
                    }
                )
            }
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: ScrollViewHeightKey.self, value: geo.size.height)
                }
            )
            .onPreferenceChange(ContentHeightKey.self) { height in
                contentHeight = height
                if contentHeight > scrollViewHeight {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            .onPreferenceChange(ScrollViewHeightKey.self) { height in
                scrollViewHeight = height
            }
        }
    }
}

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct ScrollViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Line Chart Animation
struct AnimatedLineChart: View {
    let stablePath: [CGPoint]
    let unstablePath: [CGPoint]
    
    @State private var trimEnd: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: OBSpacing.sm) {
            Text("gün içi enerji stabilitesi")
                .font(OBFont.captionBold)
                .foregroundColor(OBColors.textPrimary)
            
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                ZStack {
                    Path { path in
                        guard !stablePath.isEmpty else { return }
                        path.move(to: CGPoint(x: stablePath[0].x * w, y: stablePath[0].y * h))
                        for point in stablePath.dropFirst() {
                            path.addLine(to: CGPoint(x: point.x * w, y: point.y * h))
                        }
                    }
                    .trim(from: 0, to: trimEnd)
                    .stroke(OBColors.accentBlue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    
                    Path { path in
                        guard !unstablePath.isEmpty else { return }
                        path.move(to: CGPoint(x: unstablePath[0].x * w, y: unstablePath[0].y * h))
                        for point in unstablePath.dropFirst() {
                            path.addLine(to: CGPoint(x: point.x * w, y: point.y * h))
                        }
                    }
                    .trim(from: 0, to: trimEnd)
                    .stroke(OBColors.warningRed.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 3]))
                }
            }
            .frame(height: 120)
            
            HStack {
                HStack(spacing: 4) {
                    Circle().fill(OBColors.accentBlue).frame(width: 8, height: 8)
                    Text("planlı ritim").font(OBFont.small).foregroundColor(OBColors.textSecondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(OBColors.warningRed.opacity(0.6)).frame(width: 8, height: 8)
                    Text("plansız").font(OBFont.small).foregroundColor(OBColors.textSecondary)
                }
            }
            
            HStack {
                Text("bugün").font(OBFont.small).foregroundColor(OBColors.textMuted)
                Spacer()
                Text("2 hafta").font(OBFont.small).foregroundColor(OBColors.textMuted)
            }
        }
        .padding(OBSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).delay(0.3)) {
                trimEnd = 1.0
            }
        }
    }
}

// MARK: - Bouncy Card Animation Modifier
struct BouncyAppear: ViewModifier {
    let delay: Double
    @State private var appeared = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(delay), value: appeared)
            .onAppear { appeared = true }
    }
}

extension View {
    func bouncyAppear(delay: Double = 0) -> some View {
        modifier(BouncyAppear(delay: delay))
    }
}

// MARK: - Screen Transition
enum OBTransition {
    static var slideForward: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    static var slideBackward: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }
    
    static var fade: AnyTransition {
        .opacity
    }
    
    static var scaleUp: AnyTransition {
        .scale(scale: 0.9).combined(with: .opacity)
    }
}
