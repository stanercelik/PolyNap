import SwiftUI

// MARK: - Tour Target Preference Key
struct TourTargetKey: PreferenceKey {
    typealias Value = [String: Anchor<CGRect>]
    static var defaultValue: Value = [:]
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue()) { _, new in new }
    }
}

// MARK: - View Extension
extension View {
    /// Registers this view as a tour highlight target with the given identifier.
    func tourTarget(_ id: String) -> some View {
        anchorPreference(key: TourTargetKey.self, value: .bounds) { [id: $0] }
    }
}

// MARK: - Tour Overlay View
struct AppTourOverlayView: View {
    @EnvironmentObject private var tourManager: AppTourManager
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var spotlightPulseInset: CGFloat = 0

    let anchors: [String: Anchor<CGRect>]

    var body: some View {
        GeometryReader { proxy in
            let step = tourManager.currentStep
            let frame = resolvedFrame(for: step.anchorId, in: proxy)
            let hasFrame = frame.width > 0 && frame.height > 0

            ZStack {
                // Dimmed overlay with spotlight cutout
                dimmedOverlay(highlightFrame: hasFrame ? frame : nil)

                // Floating popup card
                if tourManager.spotlightVisible {
                    tourCard(frame: hasFrame ? frame : defaultFrame(proxy: proxy), proxy: proxy)
                        .transition(.opacity.combined(with: .scale(0.97)))
                }
            }
            .opacity(tourManager.isShowingTour ? 1 : 0)
            .animation(.easeInOut(duration: 0.25), value: tourManager.spotlightVisible)
            .onChange(of: tourManager.spotlightPulseToken) { _, _ in
                withAnimation(.easeOut(duration: 0.14)) {
                    spotlightPulseInset = 8
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
                        spotlightPulseInset = 0
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Helpers

    private func resolvedFrame(for anchorId: String, in proxy: GeometryProxy) -> CGRect {
        guard let anchor = anchors[anchorId] else { return .zero }
        let f = proxy[anchor]
        guard f.width > 0 && f.height > 0 else { return .zero }
        // The overlay sits outside TabView so safeAreaInsets.bottom = home indicator (~34pt) only.
        // We must also subtract the tab bar content height (~49pt) to avoid overlapping it.
        let safeTop: CGFloat = proxy.safeAreaInsets.top + 4
        let tabBarContentHeight: CGFloat = 49
        let safeBottom: CGFloat = proxy.size.height - proxy.safeAreaInsets.bottom - tabBarContentHeight - 8
        let clampedMinY = max(f.minY, safeTop)
        let clampedMaxY = min(f.maxY, safeBottom)
        guard clampedMaxY > clampedMinY else { return f }
        return CGRect(x: f.minX, y: clampedMinY, width: f.width, height: clampedMaxY - clampedMinY)
    }

    private func defaultFrame(proxy: GeometryProxy) -> CGRect {
        CGRect(x: proxy.size.width / 2, y: proxy.size.height / 2, width: 0, height: 0)
    }

    // MARK: - Dimmed Overlay

    @ViewBuilder
    private func dimmedOverlay(highlightFrame: CGRect?) -> some View {
        if let frame = highlightFrame, tourManager.spotlightVisible {
            Color.black.opacity(0.78)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .frame(
                            width: frame.width + 28 + spotlightPulseInset,
                            height: frame.height + 40 + spotlightPulseInset
                        )
                        .position(x: frame.midX, y: frame.midY + 8)
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: frame.midX)
                .animation(.easeInOut(duration: 0.4), value: frame.midY)
        } else {
            Color.black.opacity(0.78)
                .ignoresSafeArea()
        }
    }

    // MARK: - Tour Card

    @ViewBuilder
    private func tourCard(frame: CGRect, proxy: GeometryProxy) -> some View {
        let screenH = proxy.size.height
        let isInBottomHalf = frame.midY > screenH * 0.56

        // Tab bar top = screenH - safeAreaInsets.bottom - 49
        let tabBarTop = screenH - proxy.safeAreaInsets.bottom - 49

        VStack(spacing: 0) {
            if isInBottomHalf {
                Spacer()
                cardContent
                    .padding(.horizontal, 20)
                // Push card above the highlight, with bottom padding above the tab bar
                Spacer()
                    .frame(height: max(screenH - frame.minY + 24, tabBarTop * 0.12))
            } else {
                // Push card down to just below the highlight
                Spacer()
                    .frame(height: max(frame.maxY + 24, 80))
                cardContent
                    .padding(.horizontal, 20)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.35), value: tourManager.currentStepIndex)
    }

    // MARK: - Card Content

    private var cardContent: some View {
        let stepCount = TourStep.allCases.count
        let stepIndex = tourManager.currentStepIndex

        return VStack(alignment: .leading, spacing: 0) {
            LinearGradient(
                colors: [Color.appPrimary, Color.appPrimary.opacity(0.55)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 5)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.appPrimary)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L("tour.step\(stepIndex).title", table: "Tour"))
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundColor(Color.appText)
                            .fixedSize(horizontal: false, vertical: true)
                            .textCase(nil)

                        Text(L("tour.step\(stepIndex).desc", table: "Tour"))
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(Color.appTextSecondary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack {
                    Spacer(minLength: 0)
                    Text("\(stepIndex + 1) / \(stepCount)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.appPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.appPrimary.opacity(0.12), in: Capsule())
                    Spacer(minLength: 0)
                }

                HStack(spacing: 6) {
                    ForEach(0..<stepCount, id: \.self) { i in
                        Capsule()
                            .fill(i == stepIndex ? Color.appPrimary : Color.appBorder.opacity(0.55))
                            .frame(width: i == stepIndex ? 18 : 5, height: 5)
                    }
                }
                .frame(maxWidth: .infinity)
                .animation(.spring(response: 0.32, dampingFraction: 0.78), value: stepIndex)
                .accessibilityHidden(true)

                Rectangle()
                    .fill(Color.appBorder.opacity(0.35))
                    .frame(height: 1)

                HStack(alignment: .center, spacing: 0) {
                    HStack(spacing: 14) {
                        if stepIndex > 0 {
                            Button {
                                tourManager.previousStep()
                            } label: {
                                Text(L("tour.back", table: "Tour"))
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(Color.appTextSecondary)
                            }
                        }

                        Button {
                            tourManager.skipTour()
                        } label: {
                            Text(L("tour.skip", table: "Tour"))
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(Color.appTextSecondary)
                        }
                    }

                    Spacer(minLength: 12)

                    Button {
                        tourManager.nextStep()
                    } label: {
                        Text(tourManager.currentStep.isLastStep
                             ? L("tour.done", table: "Tour")
                             : L("tour.next", table: "Tour"))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.appTextOnPrimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 11)
                            .background(
                                Capsule()
                                    .fill(Color.appPrimary)
                                    .shadow(color: Color.appPrimary.opacity(0.45), radius: 8, x: 0, y: 4)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(22)
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.appCardBackground)
                .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                .shadow(color: .black.opacity(0.28), radius: 36, x: 0, y: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.appPrimary.opacity(0.45),
                            Color.appBorder.opacity(0.65)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.25
                )
        )
    }
}
