import SwiftUI

// MARK: - Adaptation Phase Card
struct AdaptationPhaseCard: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingResetAlert = false
    @State private var isResetting = false
    @State private var resetError: String? = nil
    @State private var showingLaterAlert = false
    @State private var isUndoing = false
    @State private var undoError: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile.fill")
                    .font(.title2)
                    .foregroundColor(.appAccent)
                
                Text(L("profile.adaptation.title", table: "Profile"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
                
                Spacer()
                
                if viewModel.activeSchedule != nil {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title3)
                            .foregroundColor(.appTextSecondary.opacity(0.7))
                    }
                    .disabled(isResetting)
                }
            }
            
            if viewModel.activeSchedule != nil {
                AdaptationProgressCard(
                    duration: viewModel.adaptationDuration,
                    currentPhase: viewModel.adaptationPhase,
                    phaseDescription: viewModel.adaptationPhaseDescription,
                    showingResetAlert: $showingResetAlert,
                    isResetting: isResetting,
                    viewModel: viewModel,
                    hasUndoData: viewModel.hasUndoData(),
                    isUndoing: isUndoing,
                    onUndo: performUndo,
                    onUndoLater: dismissUndoForLater
                )
            } else {
                EmptyAdaptationCard()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .alert(L("profile.adaptation.reset.title", table: "Profile"), isPresented: $showingResetAlert) {
            Button(L("general.cancel", table: "Profile"), role: .cancel) { }
            Button(L("profile.adaptation.reset.confirm", table: "Profile"), role: .destructive) {
                resetAdaptationPhase()
            }
        } message: {
            Text(L("profile.adaptation.reset.message", table: "Profile"))
        }
        .alert(L("general.error", table: "Profile"), isPresented: .init(get: { resetError != nil }, set: { if !$0 { resetError = nil } })) {
            Button(L("general.ok", table: "Profile"), role: .cancel) {
                resetError = nil
            }
        } message: {
            Text(resetError ?? L("general.unknownError", table: "Profile"))
        }
        .alert(L("profile.adaptation.undo.later.title", table: "Profile"), isPresented: $showingLaterAlert) {
            Button(L("general.ok", table: "Profile"), role: .cancel) {}
        } message: {
            Text(L("profile.adaptation.undo.later.message", table: "Profile"))
        }
        .alert(L("general.error", table: "Profile"), isPresented: .init(get: { undoError != nil }, set: { if !$0 { undoError = nil } })) {
            Button(L("general.ok", table: "Profile"), role: .cancel) {
                undoError = nil
            }
        } message: {
            Text(undoError ?? L("general.unknownError", table: "Profile"))
        }
    }
    
    private func resetAdaptationPhase() {
        isResetting = true
        
        Task {
            do {
                try await viewModel.resetAdaptationPhase()
                
                await MainActor.run {
                    isResetting = false
                }
            } catch {
                await MainActor.run {
                    resetError = error.localizedDescription
                    isResetting = false
                }
            }
        }
    }
    
    private func performUndo() {
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
    
    private func dismissUndoForLater() {
        viewModel.dismissUndoForLater()
        showingLaterAlert = true
    }
}

// MARK: - Empty Adaptation Card
struct EmptyAdaptationCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 48))
                .foregroundColor(.appTextSecondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(L("profile.adaptation.empty.title", table: "Profile"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appText)
                
                Text(L("profile.adaptation.empty.description", table: "Profile"))
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Adaptation Progress Card
struct AdaptationProgressCard: View {
    let duration: Int
    let currentPhase: Int
    let phaseDescription: String
    @Binding var showingResetAlert: Bool
    let isResetting: Bool
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: ProfileScreenViewModel
    let hasUndoData: Bool
    let isUndoing: Bool
    let onUndo: () -> Void
    let onUndoLater: () -> Void
    
    var body: some View {
        let completedDays = calculateRealCompletedDays()
        let progress = Float(completedDays) / Float(duration)
        let phaseColor = getPhaseColor(currentPhase)
        
        VStack(spacing: 20) {
            // Header dengan progress info
            HStack(spacing: 16) {
                // Phase icon
                ZStack {
                    Circle()
                        .fill(phaseColor)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: phaseColor.opacity(0.3), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(phaseDescription)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.appText)
                    
                    Text(String(format: L("profile.adaptation.dayProgress", table: "Profile"), completedDays, duration))
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(phaseColor)
                }
            }
            
            // Modern progress bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 10)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [phaseColor.opacity(0.7), phaseColor]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(6, geometry.size.width * CGFloat(progress)), height: 10)
                            .animation(.easeInOut(duration: 0.6), value: progress)
                    }
                }
                .frame(height: 10)
            }
            
            // Status description
            Text(getStatusDescription())
                .font(.footnote)
                .foregroundColor(.appTextSecondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(phaseColor.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(phaseColor.opacity(0.15), lineWidth: 1)
                        )
                )
        }
        .animation(.easeInOut(duration: 0.3), value: currentPhase)
    }
    
    private func calculateRealCompletedDays() -> Int {
        if let schedule = viewModel.activeSchedule {
            let calendar = Calendar.current
            let startDate = schedule.adaptationStartDate ?? schedule.createdAt
            let currentDate = Date()
            
            // İki tarih arasındaki tam gün farkını hesapla
            let startOfStartDate = calendar.startOfDay(for: startDate)
            let startOfCurrentDate = calendar.startOfDay(for: currentDate)
            
            let components = calendar.dateComponents([.day], from: startOfStartDate, to: startOfCurrentDate)
            let daysPassed = components.day ?? 0
            
            // 1. gün = adaptasyon başladığı gün (daysPassed = 0)
            // 2. gün = bir sonraki gün (daysPassed = 1)
            // vs.
            let currentDay = daysPassed + 1
            
            return min(currentDay, duration)
        }
        return 1
    }
    
    private func getPhaseColor(_ phase: Int) -> Color {
        let colors: [Color] = [.blue, .purple, .appSecondary, .orange, .green, .pink]
        return colors[safe: phase] ?? .appSecondary
    }
    
    private func getStatusDescription() -> String {
        let completedDays = calculateRealCompletedDays()
        let remainingDays = max(0, duration - completedDays)
        
        switch currentPhase {
        case 0:
            return String(format: L("profile.adaptation.phase0.description", table: "Profile"), completedDays, duration)
        case 1:
            return String(format: L("profile.adaptation.phase1.description", table: "Profile"), completedDays, remainingDays)
        case 2:
            return String(format: L("profile.adaptation.phase2.description", table: "Profile"), completedDays, remainingDays)
        case 3:
            return String(format: L("profile.adaptation.phase3.description", table: "Profile"), completedDays, remainingDays)
        case 4:
            if duration == 28 {
                return String(format: L("profile.adaptation.phase4.28day.description", table: "Profile"), completedDays, remainingDays)
            } else {
                return String(format: L("profile.adaptation.phase4.21day.description", table: "Profile"), completedDays)
            }
        case 5...:
            return String(format: L("profile.adaptation.phase5.description", table: "Profile"), completedDays)
        default:
            return L("profile.adaptation.default.description", table: "Profile")
        }
    }
}

// MARK: - Undo Adaptation Section
struct UndoAdaptationSection: View {
    let isUndoing: Bool
    let onUndo: () -> Void
    let onUndoLater: () -> Void
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @StateObject private var paywallManager = PaywallManager.shared
    
    var body: some View {
        PSInfoBox(
            title: L("profile.adaptation.undo.title", table: "Profile"),
            message: L("profile.adaptation.undo.message", table: "Profile"),
            subtitle: L("profile.adaptation.undo.subtitle", table: "Profile"),
            icon: "arrow.uturn.left.circle.fill",
            style: .warning
        )
        
        HStack(spacing: PSSpacing.sm) {
            // Later Button
            PSSecondaryButton(L("profile.adaptation.undo.later", table: "Profile"), icon: "clock") {
                onUndoLater()
            }
            
            // Undo Button (Premium gated)
            PSPrimaryButton(
                L("profile.adaptation.undo.button", table: "Profile"),
                icon: isUndoing ? nil : "arrow.uturn.backward",
                isLoading: isUndoing,
                customBackgroundColor: Color.orange
            ) {
                handleUndoButtonTap()
            }
        }
    }
    
    private func handleUndoButtonTap() {
        // Premium kontrolü
        if revenueCatManager.userState != .premium {
            paywallManager.presentPaywall(trigger: .premiumFeatureAccess)
            return
        }
        
        // Premium kullanıcı - undo işlemini gerçekleştir
        onUndo()
    }
}

// MARK: - Array Extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
} 
