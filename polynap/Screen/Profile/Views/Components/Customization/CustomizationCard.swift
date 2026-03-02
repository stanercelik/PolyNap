import SwiftUI

// MARK: - Customization Card
struct CustomizationCard: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    @Binding var showEmojiPicker: Bool
    @Binding var isPickingCoreEmoji: Bool

    var body: some View {
        PSCard(padding: PSSpacing.lg) {
            VStack(spacing: PSSpacing.md) {
                // Header with prominent premium badge
                HStack(spacing: PSSpacing.sm) {
                    Image(systemName: "paintbrush.pointed.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appPrimary)
                    Text(L("profile.customization.title", table: "Profile"))
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(.appText)
                    Spacer()
                    // Premium badge — more prominent
                    HStack(spacing: 3) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text("PREMIUM")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, PSSpacing.sm)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.appPrimary, Color.appSecondary]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }

                // Core + Nap emoji in one compact row each
                VStack(spacing: PSSpacing.sm) {
                    emojiRow(
                        label: L("profile.customization.coreEmoji", table: "Profile"),
                        emoji: viewModel.selectedCoreEmoji,
                        isCore: true
                    )

                    Divider()
                        .opacity(0.4)

                    emojiRow(
                        label: L("profile.customization.napEmoji", table: "Profile"),
                        emoji: viewModel.selectedNapEmoji,
                        isCore: false
                    )
                }
            }
        }
        .shadow(color: .appBorder.opacity(0.3), radius: PSSpacing.xs, x: 0, y: 2)
    }

    @ViewBuilder
    private func emojiRow(label: String, emoji: String, isCore: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.appText)
            Spacer()
            Button(action: {
                isPickingCoreEmoji = isCore
                showEmojiPicker = true
            }) {
                HStack(spacing: PSSpacing.xs) {
                    Text(emoji)
                        .font(.system(size: 22))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                }
                .padding(.horizontal, PSSpacing.md)
                .padding(.vertical, PSSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: PSCornerRadius.small)
                        .fill(Color.appBackground)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}
