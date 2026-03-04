import SwiftUI

// MARK: - Schedule Change Undo Banner (Premium Feature)
struct UndoScheduleChangeCard: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @State private var isUndoing = false
    @State private var undoError: String? = nil
    @StateObject private var paywallManager = PaywallManager.shared
    
    // Computed properties for alert binding
    private var isShowingUndoError: Binding<Bool> {
        Binding(
            get: { undoError != nil },
            set: { if !$0 { undoError = nil } }
        )
    }
    
    private var undoErrorMessage: String {
        undoError ?? L("general.unknownError", table: "Profile")
    }
    
    // Extracted background view to fix compiler error
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: PSCornerRadius.large)
            .fill(Color.orange.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: PSCornerRadius.large)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
    }

    var body: some View {
        PSCard {
            VStack(spacing: PSSpacing.md) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: PSIconSize.medium))
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: PSSpacing.xs) {
                        HStack {
                            Text("Adaptasyon İlerlemesi Geri Getir")
                                .font(PSTypography.headline)
                                .foregroundColor(.appText)
                            
                            Spacer()
                            
                            // Premium Badge
                            Text("PREMIUM")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.yellow)
                                )
                        }
                        
                        Text("Yeni programınız aynı kalacak, sadece önceki adaptasyon gününüzden devam edeceksiniz")
                            .font(PSTypography.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    Spacer()
                }
                
                Button(action: {
                    handleUndoButtonTap()
                }) {
                    HStack {
                        if isUndoing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: revenueCatManager.userState == .premium ? "arrow.uturn.backward" : "crown.fill")
                                .font(.system(size: PSIconSize.small))
                        }
                        
                        Text(revenueCatManager.userState == .premium ? "Adaptasyonu Geri Getir" : "Premium ile Kilidi Aç")
                            .font(PSTypography.body)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, PSSpacing.lg)
                    .padding(.vertical, PSSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                            .fill(revenueCatManager.userState == .premium ? Color.orange : Color.yellow)
                    )
                }
                .disabled(isUndoing)
            }
        }
        .background(cardBackground)
        .alert(
            L("general.error", table: "Profile"),
            isPresented: isShowingUndoError
        ) {
            Button(L("general.ok", table: "Profile"), role: .cancel) {
                undoError = nil
            }
        } message: {
            Text(undoErrorMessage)
        }
    }
    
    // MARK: - Actions
    
    private func handleUndoButtonTap() {
        // Premium kontrolü
        if revenueCatManager.userState != .premium {
            paywallManager.presentPaywall(trigger: .premiumFeatureAccess)
            return
        }
        
        // Premium kullanıcı - undo işlemini gerçekleştir
        undoScheduleChange()
    }
    
    private func undoScheduleChange() {
        isUndoing = true
        
        Task {
            do {
                try await viewModel.undoScheduleChange()
                await MainActor.run {
                    isUndoing = false
                }
            } catch {
                await MainActor.run {
                    undoError = error.localizedDescription
                    isUndoing = false
                }
            }
        }
    }
} 