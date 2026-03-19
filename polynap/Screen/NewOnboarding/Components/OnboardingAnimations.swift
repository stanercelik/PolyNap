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
    @State private var breathing = false
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
            // İçerik rasterize edilip sonra scale uygulanıyor — animasyon sırasında re-render yok
            .drawingGroup()
            .scaleEffect(breathing ? maxScale : minScale)
            .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true), value: breathing)
            .onAppear { breathing = true }
    }
}

extension View {
    func breathingAnimation(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 3.0) -> some View {
        modifier(BreathingAnimation(minScale: minScale, maxScale: maxScale, duration: duration))
    }
}

// MARK: - Slow Rotation
struct SlowRotation: ViewModifier {
    @State private var rotating = false
    let duration: Double

    func body(content: Content) -> some View {
        content
            .drawingGroup()
            .rotationEffect(.degrees(rotating ? 360 : 0))
            .animation(.linear(duration: duration).repeatForever(autoreverses: false), value: rotating)
            .onAppear { rotating = true }
    }
}

extension View {
    func slowRotation(duration: Double = 20) -> some View {
        modifier(SlowRotation(duration: duration))
    }
}

// MARK: - Floating Animation
struct FloatingAnimation: ViewModifier {
    @State private var floating = false
    let amplitude: CGFloat
    let duration: Double

    init(amplitude: CGFloat = 6, duration: Double = 2.5) {
        self.amplitude = amplitude
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .offset(y: floating ? -amplitude : 0)
            .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true), value: floating)
            .onAppear { floating = true }
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
    let animDuration: Double
    let targetOpacity: Double
    let targetScale: CGFloat
    @State private var opacity: Double = 0.3
    @State private var scale: CGFloat = 0.8

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size))
            .foregroundColor(color)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: animDuration).repeatForever(autoreverses: true)) {
                    opacity = targetOpacity
                    scale = targetScale
                }
            }
    }
}

// Sabit bir parçacık verisi — her render'da rastgele değer üretimi engelleniyor
private struct StarData: Identifiable {
    let id: Int
    let size: CGFloat
    let xRatio: CGFloat  // 0…1 aralığında pozisyon
    let yRatio: CGFloat
    let floatAmplitude: CGFloat
    let floatDuration: Double
    let animDuration: Double
    let targetOpacity: Double
    let targetScale: CGFloat
}

// MARK: - Stars Background
struct StarsBackground: View {
    let count: Int
    let color: Color

    // Rastgele değerler bir kez üretilip saklanıyor
    @State private var stars: [StarData] = []

    init(count: Int = 8, color: Color = .white.opacity(0.6)) {
        self.count = count
        self.color = color
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(stars) { star in
                StarParticle(
                    size: star.size,
                    color: color,
                    animDuration: star.animDuration,
                    targetOpacity: star.targetOpacity,
                    targetScale: star.targetScale
                )
                .position(
                    x: star.xRatio * geo.size.width,
                    y: star.yRatio * geo.size.height
                )
                .floating(amplitude: star.floatAmplitude, duration: star.floatDuration)
            }
        }
        .onAppear {
            guard stars.isEmpty else { return }
            stars = (0..<count).map { i in
                StarData(
                    id: i,
                    size: CGFloat.random(in: 8...16),
                    xRatio: CGFloat.random(in: 0.05...0.95),
                    yRatio: CGFloat.random(in: 0.05...0.95),
                    floatAmplitude: CGFloat.random(in: 3...8),
                    floatDuration: Double.random(in: 2...4),
                    animDuration: Double.random(in: 1.5...3.0),
                    targetOpacity: Double.random(in: 0.6...1.0),
                    targetScale: CGFloat.random(in: 0.9...1.2)
                )
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
            // Tüm partiküller tek bir Metal katmanında birleştiriliyor — GPU rendering
            .drawingGroup()
            .onAppear {
                HapticFeedbackManager.shared.trigger(.success)
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
            // İçerik önce rasterize ediliyor, sonra shadow uygulanıyor — CPU yükü azalıyor
            .drawingGroup()
            .shadow(color: color.opacity(glowing ? 0.6 : 0.2), radius: radius)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowing)
            .onAppear { glowing = true }
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
