import SwiftUI

// MARK: - Stats Grid Section (compact: current streak + longest streak only)
struct StatsGridSection: View {
    @ObservedObject var viewModel: ProfileScreenViewModel

    var body: some View {
        PSCard(padding: PSSpacing.lg) {
            VStack(spacing: PSSpacing.md) {
                // Section header
                HStack(spacing: PSSpacing.sm) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.metricAmber)
                    Text(L("profile.stats.title", table: "Profile"))
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(.appText)
                    Spacer()
                }

                // Two stats side-by-side with divider
                HStack(spacing: 0) {
                    // Current streak
                    VStack(spacing: PSSpacing.xs) {
                        HStack(spacing: 4) {
                            Text("\(viewModel.currentStreak)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(viewModel.currentStreak > 0 ? .metricAmber : .appTextSecondary)
                            if viewModel.currentStreak > 0 {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.metricAmber)
                                    .offset(y: -2)
                            }
                        }
                        Text(L("profile.stats.currentStreak", table: "Profile"))
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Color.appBorder.opacity(0.4))
                        .frame(width: 1, height: 40)

                    // Longest streak
                    VStack(spacing: PSSpacing.xs) {
                        HStack(spacing: 4) {
                            Text("\(viewModel.longestStreak)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(viewModel.longestStreak > 0 ? .appSecondary : .appTextSecondary)
                            if viewModel.longestStreak > 0 {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.appSecondary)
                                    .offset(y: -2)
                            }
                        }
                        Text(L("profile.stats.longestStreak", table: "Profile"))
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, PSSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                        .fill(Color.appBackground.opacity(0.5))
                )
            }
        }
    }
}
