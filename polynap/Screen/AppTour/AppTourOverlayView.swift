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
                        .frame(width: frame.width + 28, height: frame.height + 40)
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
        VStack(alignment: .leading, spacing: 14) {
            // Title
            Text(L("tour.step\(tourManager.currentStepIndex).title", table: "Tour"))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Color(.label))
                .fixedSize(horizontal: false, vertical: true)
                .textCase(nil)

            // Description
            Text(L("tour.step\(tourManager.currentStepIndex).desc", table: "Tour"))
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(Color(.secondaryLabel))
                .lineSpacing(2.5)
                .fixedSize(horizontal: false, vertical: true)

            // Controls row
            HStack(alignment: .center, spacing: 0) {
                // Skip button
                Button {
                    tourManager.skipTour()
                } label: {
                    Text(L("tour.skip", table: "Tour"))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(Color(.secondaryLabel))
                }

                Spacer()

                // Step indicator dots
                HStack(spacing: 5) {
                    ForEach(0..<TourStep.allCases.count, id: \.self) { i in
                        Circle()
                            .fill(i == tourManager.currentStepIndex ? Color.appPrimary : Color(.tertiaryLabel))
                            .frame(
                                width: i == tourManager.currentStepIndex ? 7 : 4.5,
                                height: i == tourManager.currentStepIndex ? 7 : 4.5
                            )
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.75), value: tourManager.currentStepIndex)

                Spacer()

                // Next / Done button
                Button {
                    tourManager.nextStep()
                } label: {
                    Text(tourManager.currentStep.isLastStep
                         ? L("tour.done", table: "Tour")
                         : L("tour.next", table: "Tour"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(Color.appPrimary, in: Capsule())
                }
            }
        }
        .padding(20)
        .background(
            Color(.systemBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.22), radius: 28, x: 0, y: 10)
        )
    }
}
