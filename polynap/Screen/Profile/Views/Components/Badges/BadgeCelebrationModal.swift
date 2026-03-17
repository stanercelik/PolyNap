import SwiftUI
import Lottie

// MARK: - Badge Celebration Modal
/// Shown when a badge is earned while the app is in the foreground.
struct BadgeCelebrationModal: View {
    let badge: BadgeDefinition
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var contentScale: CGFloat = 0.7

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Lottie celebration behind modal
            LottieView(animation: .named("celebration"))
                .playing(loopMode: .playOnce)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Modal card
            VStack(spacing: PSSpacing.lg) {
                // Badge image
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [badge.gradientStart, badge.gradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Circle()
                        .stroke(badge.ringColor.opacity(0.8), lineWidth: 2.5)
                        .frame(width: 120, height: 120)

                    Image(badge.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                }
                .shadow(color: badge.ringColor.opacity(0.4), radius: 16, x: 0, y: 4)

                VStack(spacing: PSSpacing.sm) {
                    Text(L("badge.earned.title", table: "Profile"))
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                        .textCase(.uppercase)
                        .tracking(1.2)

                    Text(badge.name)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundColor(.appText)
                        .multilineTextAlignment(.center)

                    Text(badge.description)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: { dismiss(triggerButtonHaptic: true) }) {
                    Text(L("badge.earned.cta", table: "Profile"))
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PSSpacing.md)
                        .background(
                            Capsule()
                                .fill(badge.ringColor)
                        )
                }
            }
            .padding(PSSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: PSCornerRadius.large)
                    .fill(Color.appCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: PSCornerRadius.large)
                            .stroke(badge.ringColor.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, PSSpacing.xl)
            .scaleEffect(contentScale)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                HapticFeedbackManager.shared.trigger(.celebrationPulse)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                    appeared = true
                    contentScale = 1.0
                }
            }
        }
    }

    private func dismiss(triggerButtonHaptic: Bool = false) {
        if triggerButtonHaptic {
            HapticFeedbackManager.shared.trigger(.softCommit)
        }
        withAnimation(.easeOut(duration: 0.2)) {
            appeared = false
            contentScale = 0.85
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}
