import SwiftUI

// MARK: - Nimmy Image Helper
struct NimmyImage: View {
    let variant: NimmyVariant
    let size: CGFloat
    
    enum NimmyVariant: String {
        case alarm = "Nimmy-alarm"
        case dance = "Nimmy-dance"
        case hello = "Nimmy-hello"
        case meditation = "Nimmy-meditation"
        case sleepingNormal = "Nimmy-sleeping-normal"
        case sleepingPillow = "Nimmy-sleeping-with-pillow"
        case tired = "Nimmy-tired"
    }
    
    init(_ variant: NimmyVariant, size: CGFloat = 140) {
        self.variant = variant
        self.size = size
    }
    
    var body: some View {
        Image(variant.rawValue)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}

// MARK: - Onboarding CTA Button
struct OBButton: View {
    let title: String
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primaryDark
        case primaryWhite
        case ghost
    }
    
    init(_ title: String, style: ButtonStyle = .primaryDark, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            Text(title)
                .font(OBFont.button)
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(backgroundColor, in: RoundedRectangle(cornerRadius: 27))
                .overlay(
                    RoundedRectangle(cornerRadius: 27)
                        .stroke(borderColor, lineWidth: style == .ghost ? 1.5 : 0)
                )
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primaryDark: return .white
        case .primaryWhite: return OBColors.darkNavy
        case .ghost: return OBColors.textSecondary
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primaryDark: return OBColors.darkNavy
        case .primaryWhite: return .white
        case .ghost: return .clear
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .ghost: return OBColors.textMuted.opacity(0.3)
        default: return .clear
        }
    }
}

// MARK: - Tap to Continue
struct TapToContinue: View {
    let text: String
    let color: Color
    let action: () -> Void
    @State private var isVisible = false
    
    init(_ text: String = L("newOnboarding.common.tapToContinue", table: "Onboarding"), color: Color = OBColors.textMuted, action: @escaping () -> Void = {}) {
        self.text = text
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text(text)
                .font(OBFont.caption)
                .foregroundColor(color)
                .opacity(isVisible ? 0.7 : 0)
                .animation(.easeIn(duration: 0.8).delay(2.0), value: isVisible)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
        }
        .onAppear { isVisible = true }
    }
}

// MARK: - Selection Card (for question screens)
struct OBSelectionCard: View {
    let emoji: String
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: OBSpacing.md) {
                Text(emoji)
                    .font(.system(size: 24))
                
                Text(text)
                    .font(OBFont.body)
                    .foregroundColor(isSelected ? OBColors.darkNavy : OBColors.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(OBColors.accentBlue)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, OBSpacing.md)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? OBColors.accentBlue.opacity(0.08) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? OBColors.accentBlue : Color.gray.opacity(0.15), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Glass Card (for dark backgrounds)
struct GlassCard<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(OBSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial.opacity(0.3))
                    )
            )
    }
}

// MARK: - Icon Row (for trust screens)
struct OBIconRow: View {
    let icon: String
    let text: String
    let color: Color
    
    init(icon: String, text: String, color: Color = .white) {
        self.icon = icon
        self.text = text
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: OBSpacing.md) {
            Text(icon)
                .font(.system(size: 20))
            
            Text(text)
                .font(OBFont.body)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, OBSpacing.md)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - Progress Bar for Sections
struct OBProgressBar: View {
    let progress: CGFloat
    let sectionColor: Color
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.15))
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(sectionColor)
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
                    .animation(.easeInOut(duration: 0.4), value: progress)
            }
        }
        .frame(height: 3)
    }
}

// MARK: - Before/After Card
struct BeforeAfterCard: View {
    let nimmyBefore: NimmyImage.NimmyVariant
    let nimmyAfter: NimmyImage.NimmyVariant
    let label: String
    let isBefore: Bool
    
    var body: some View {
        VStack(spacing: OBSpacing.sm) {
            NimmyImage(isBefore ? nimmyBefore : nimmyAfter, size: 80)
            
            Text(label)
                .font(OBFont.captionBold)
                .foregroundColor(OBColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(OBSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isBefore ? OBColors.cardGray : OBColors.accentBlue.opacity(0.1))
        )
    }
}

// MARK: - Review Card
struct ReviewCard: View {
    let stars: Int
    let quote: String
    let author: String
    let isDarkBackground: Bool
    
    init(stars: Int = 5, quote: String, author: String, isDarkBackground: Bool = false) {
        self.stars = stars
        self.quote = quote
        self.author = author
        self.isDarkBackground = isDarkBackground
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: OBSpacing.sm) {
            HStack(spacing: 2) {
                ForEach(0..<stars, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(OBColors.starGold)
                }
            }
            
            Text("\"\(quote)\"")
                .font(OBFont.body)
                .foregroundColor(isDarkBackground ? .white.opacity(0.9) : OBColors.textPrimary)
                .italic()
            
            Text("— \(author)")
                .font(OBFont.caption)
                .foregroundColor(isDarkBackground ? .white.opacity(0.6) : OBColors.textSecondary)
        }
        .padding(OBSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkBackground ? Color.white.opacity(0.08) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isDarkBackground ? Color.white.opacity(0.1) : Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Age Slider
struct AgeSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let onChanged: (Double) -> Void
    
    init(value: Binding<Double>, range: ClosedRange<Double> = 18...65, step: Double = 1, onChanged: @escaping (Double) -> Void = { _ in }) {
        self._value = value
        self.range = range
        self.step = step
        self.onChanged = onChanged
    }
    
    var body: some View {
        let displayAge = Int(value.rounded())
        
        VStack(spacing: OBSpacing.lg) {
            Text("\(displayAge)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(OBColors.primaryColor)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.3), value: displayAge)
            
            VStack(spacing: OBSpacing.sm) {
                Slider(value: $value, in: range)
                    .tint(OBColors.primaryColor)
                
                HStack {
                    Text("\(Int(range.lowerBound))")
                        .font(OBFont.small)
                        .foregroundColor(OBColors.textMuted)
                    Spacer()
                    Text(L("newOnboarding.ageRange.agePlus65", table: "Onboarding"))
                        .font(OBFont.small)
                        .foregroundColor(OBColors.textMuted)
                }
            }
        }
        .padding(OBSpacing.lg)
        .onChange(of: displayAge) { _, newAge in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onChanged(Double(newAge))
        }
    }
}

// MARK: - Testimonial Card (bouncy, tilted)
struct TestimonialCard: View {
    let quote: String
    let author: String
    let tiltDegrees: Double
    let delay: Double
    
    @State private var appeared = false
    
    init(quote: String, author: String, tiltDegrees: Double = 0, delay: Double = 0) {
        self.quote = quote
        self.author = author
        self.tiltDegrees = tiltDegrees
        self.delay = delay
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: OBSpacing.sm) {
            Text("\"\(quote)\"")
                .font(OBFont.body)
                .foregroundColor(OBColors.textPrimary)
                .italic()
            
            Text("— \(author)")
                .font(OBFont.caption)
                .foregroundColor(OBColors.textSecondary)
        }
        .padding(OBSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .rotationEffect(.degrees(tiltDegrees))
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.65).delay(delay), value: appeared)
        .onAppear { appeared = true }
    }
}

// MARK: - Tips Carousel
struct TipsCarousel: View {
    let tips: [String]
    @Binding var currentIndex: Int
    
    var body: some View {
        VStack(spacing: OBSpacing.md) {
            Text(tips[currentIndex])
                .font(OBFont.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .id(currentIndex)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.5), value: currentIndex)
            
            HStack(spacing: 6) {
                ForEach(0..<tips.count, id: \.self) { i in
                    Circle()
                        .fill(i == currentIndex ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: currentIndex)
                }
            }
        }
        .padding(.horizontal, OBSpacing.lg)
    }
}

// MARK: - Ring Progress
struct RingProgress: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let gradientColors: [Color]
    
    init(progress: Double, lineWidth: CGFloat = 8, size: CGFloat = 120, gradientColors: [Color] = [OBColors.accentBlue, OBColors.primaryColor]) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.gradientColors = gradientColors
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradientColors),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Nimmy Question Header
struct NimmyQuestionHeader: View {
    let nimmy: NimmyImage.NimmyVariant
    let topLabel: String?
    let question: String
    let microcopy: String?
    
    init(nimmy: NimmyImage.NimmyVariant = .sleepingNormal, topLabel: String? = nil, question: String, microcopy: String? = nil) {
        self.nimmy = nimmy
        self.topLabel = topLabel
        self.question = question
        self.microcopy = microcopy
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: OBSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: OBSpacing.xs) {
                    if let topLabel = topLabel {
                        Text(topLabel)
                            .font(OBFont.caption)
                            .foregroundColor(OBColors.textMuted)
                    }
                    
                    Text(question)
                        .font(OBFont.title)
                        .foregroundColor(OBColors.textPrimary)
                }
                
                Spacer()
                
                NimmyImage(nimmy, size: 80)
                    .floating(amplitude: 4, duration: 3)
            }
            
            if let microcopy = microcopy {
                Text(microcopy)
                    .font(OBFont.caption)
                    .foregroundColor(OBColors.textMuted)
            }
        }
    }
}
