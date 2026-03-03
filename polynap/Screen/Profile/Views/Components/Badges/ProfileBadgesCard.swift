import SwiftUI

// MARK: - Profile Badges Card
struct ProfileBadgesCard: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    @State private var selectedBadge: BadgeDefinition? = nil

    private var badges: [BadgeDefinition] {
        BadgeDefinition.all(earnedIds: BadgeManager.shared.earnedBadgeIds)
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
                    let earnedCount = badges.filter { $0.isEarned }.count
                    Text("\(earnedCount)/\(badges.count)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.appTextSecondary)
                }

                // Badge grid — 5 columns (horizontal compact layout)
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: PSSpacing.sm), count: 5),
                    spacing: PSSpacing.md
                ) {
                    ForEach(badges) { badge in
                        BadgeItemView(badge: badge, isSelected: selectedBadge?.id == badge.id)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedBadge = (selectedBadge?.id == badge.id) ? nil : badge
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                    }
                }

                // Selected badge detail
                if let badge = selectedBadge {
                    BadgeDetailRow(badge: badge)
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                }
            }
        }
    }
}

// MARK: - Badge Item View
private struct BadgeItemView: View {
    let badge: BadgeDefinition
    let isSelected: Bool
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Background circle with gradient
                Circle()
                    .fill(
                        badge.isEarned
                        ? LinearGradient(
                            colors: [badge.gradientStart, badge.gradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                        : LinearGradient(
                            colors: [Color.appCardBackground, Color.appCardBackground],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                    )
                    .frame(width: 56, height: 56)

                // Ring
                Circle()
                    .stroke(
                        badge.isEarned ? badge.ringColor.opacity(0.7) : Color.appTextTertiary.opacity(0.2),
                        lineWidth: badge.isEarned ? 1.5 : 1
                    )
                    .frame(width: 56, height: 56)

                // Badge image or lock
                if badge.isEarned {
                    Image(badge.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appTextTertiary)
                }

                // Selection ring
                if isSelected && badge.isEarned {
                    Circle()
                        .stroke(badge.ringColor, lineWidth: 2.5)
                        .frame(width: 60, height: 60)
                }
            }
            .scaleEffect(appeared ? 1.0 : 0.7)
            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.05), value: appeared)
            .opacity(badge.isEarned ? 1.0 : 0.4)

            Text(badge.name)
                .font(.system(size: 9, weight: badge.isEarned ? .semibold : .regular, design: .rounded))
                .foregroundColor(badge.isEarned ? .appText : .appTextTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Badge Detail Row
private struct BadgeDetailRow: View {
    let badge: BadgeDefinition

    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.xs) {
            HStack(spacing: PSSpacing.sm) {
                if badge.isEarned {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appSuccess)
                    Text(badge.name)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.appText)
                } else {
                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appTextTertiary)
                    Text(badge.name)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.appTextSecondary)
                }
                Spacer()
            }
            Text(badge.isEarned ? badge.description : badge.howToEarn)
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, PSSpacing.md)
        .padding(.vertical, PSSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                .fill(badge.isEarned ? Color.appSuccess.opacity(0.08) : Color.appCardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                        .stroke(
                            badge.isEarned ? Color.appSuccess.opacity(0.2) : Color.appTextTertiary.opacity(0.15),
                            lineWidth: 1
                        )
                )
        )
    }
}
