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
                    .padding(.horizontal, 16)
                // Push card above the highlight, with bottom padding above the tab bar
                Spacer()
                    .frame(height: max(screenH - frame.minY + 16, tabBarTop * 0.08))
            } else {
                // Push card down to just below the highlight
                Spacer()
                    .frame(height: max(frame.maxY + 16, 64))
                cardContent
                    .padding(.horizontal, 16)
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

        return VStack(alignment: .leading, spacing: 10) {
            // Header: step badge + title
            HStack(alignment: .top, spacing: 6) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("tour.step\(stepIndex).title", table: "Tour"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color.appText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .textCase(nil)

                    Text(L("tour.step\(stepIndex).desc", table: "Tour"))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(Color.appTextSecondary)
                        .lineSpacing(1.5)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(stepIndex + 1)/\(stepCount)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(Color.appPrimary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.appPrimary.opacity(0.12), in: Capsule())
                    .fixedSize()
            }

            // Progress bar (single segment fill)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appBorder.opacity(0.4))
                    Capsule()
                        .fill(Color.appPrimary)
                        .frame(width: geo.size.width * CGFloat(stepIndex + 1) / CGFloat(stepCount))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: stepIndex)
                }
            }
            .frame(height: 3)
            .accessibilityHidden(true)

            // Actions
            HStack(spacing: 0) {
                HStack(spacing: 10) {
                    if stepIndex > 0 {
                        Button { tourManager.previousStep() } label: {
                            Text(L("tour.back", table: "Tour"))
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(Color.appTextSecondary)
                        }
                    }
                    Button { tourManager.skipTour() } label: {
                        Text(L("tour.skip", table: "Tour"))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color.appTextSecondary)
                    }
                }

                Spacer(minLength: 8)

                Button { tourManager.nextStep() } label: {
                    Text(tourManager.currentStep.isLastStep
                         ? L("tour.done", table: "Tour")
                         : L("tour.next", table: "Tour"))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.appTextOnPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.appPrimary))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.appCardBackground)
                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.appPrimary.opacity(0.25), lineWidth: 1)
        )
    }
}
