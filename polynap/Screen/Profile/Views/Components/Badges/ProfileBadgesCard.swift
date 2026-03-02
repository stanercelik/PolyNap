import SwiftUI

// MARK: - Badge Model
struct ProfileBadge: Identifiable {
    let id: String
    let icon: String          // SF Symbol name OR emoji string
    let isEmoji: Bool
    let title: String
    let isEarned: Bool
    let earnedColor: Color
}

// MARK: - Profile Badges Card
struct ProfileBadgesCard: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    @State private var selectedBadge: ProfileBadge? = nil

    private var badges: [ProfileBadge] {
        [
            ProfileBadge(
                id: "starter",
                icon: "🌱",
                isEmoji: true,
                title: L("profile.badge.starter", table: "Profile"),
                isEarned: true, // Always earned (app opened)
                earnedColor: .appPrimary
            ),
            ProfileBadge(
                id: "streak3",
                icon: "flame.fill",
                isEmoji: false,
                title: L("profile.badge.streak3", table: "Profile"),
                isEarned: viewModel.longestStreak >= 3,
                earnedColor: .metricAmber
            ),
            ProfileBadge(
                id: "week1",
                icon: "star.fill",
                isEmoji: false,
                title: L("profile.badge.week1", table: "Profile"),
                isEarned: viewModel.longestStreak >= 7,
                earnedColor: .appAccent
            ),
            ProfileBadge(
                id: "bounceback",
                icon: "arrow.uturn.up.circle.fill",
                isEmoji: false,
                title: L("profile.badge.bounceBack", table: "Profile"),
                isEarned: viewModel.longestStreak >= 2 && viewModel.currentStreak > 0,
                earnedColor: .appSecondary
            ),
            ProfileBadge(
                id: "focus",
                icon: "🎯",
                isEmoji: true,
                title: L("profile.badge.focus", table: "Profile"),
                isEarned: viewModel.longestStreak >= 14,
                earnedColor: .metricPurple
            ),
            ProfileBadge(
                id: "days30",
                icon: "trophy.fill",
                isEmoji: false,
                title: L("profile.badge.days30", table: "Profile"),
                isEarned: viewModel.longestStreak >= 30,
                earnedColor: .metricTeal
            ),
        ]
    }

    var body: some View {
        PSCard(padding: PSSpacing.lg) {
            VStack(alignment: .leading, spacing: PSSpacing.md) {
                // Section header
                HStack(spacing: PSSpacing.sm) {
                    Image(systemName: "medal.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appPrimary)
                    Text(L("profile.badges.title", table: "Profile"))
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(.appText)
                    Spacer()
                    // Earned count
                    let earnedCount = badges.filter { $0.isEarned }.count
                    Text("\(earnedCount)/\(badges.count)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.appTextSecondary)
                }

                // Badge grid — 3 columns
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: PSSpacing.sm), count: 3), spacing: PSSpacing.md) {
                    ForEach(badges) { badge in
                        BadgeItemView(badge: badge)
                            .onTapGesture {
                                if badge.isEarned {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedBadge = (selectedBadge?.id == badge.id) ? nil : badge
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            }
                    }
                }

                // Selected badge tooltip
                if let badge = selectedBadge, badge.isEarned {
                    HStack(spacing: PSSpacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.appSuccess)
                        Text(badge.title)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.appText)
                        Spacer()
                    }
                    .padding(.horizontal, PSSpacing.md)
                    .padding(.vertical, PSSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                            .fill(Color.appSuccess.opacity(0.1))
                            .overlay(RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                                .stroke(Color.appSuccess.opacity(0.2), lineWidth: 1))
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
    }
}

// MARK: - Badge Item View
private struct BadgeItemView: View {
    let badge: ProfileBadge
    @State private var appeared = false

    var body: some View {
        VStack(spacing: PSSpacing.xs) {
            ZStack {
                Circle()
                    .fill(badge.isEarned
                        ? badge.earnedColor.opacity(0.15)
                        : Color.appBackground.opacity(0.5))
                    .frame(width: 56, height: 56)

                if badge.isEarned {
                    Circle()
                        .stroke(badge.earnedColor.opacity(0.35), lineWidth: 1.5)
                        .frame(width: 56, height: 56)
                }

                if badge.isEmoji {
                    Text(badge.icon)
                        .font(.system(size: badge.isEarned ? 26 : 22))
                        .opacity(badge.isEarned ? 1.0 : 0.3)
                } else {
                    Image(systemName: badge.isEarned ? badge.icon : "lock.fill")
                        .font(.system(size: badge.isEarned ? 22 : 16, weight: .semibold))
                        .foregroundColor(badge.isEarned ? badge.earnedColor : .appTextTertiary)
                }
            }
            .scaleEffect(appeared ? 1.0 : 0.7)
            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.05), value: appeared)

            Text(badge.title)
                .font(.system(size: 10, weight: badge.isEarned ? .semibold : .regular, design: .rounded))
                .foregroundColor(badge.isEarned ? .appText : .appTextTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onAppear { appeared = true }
    }
}
