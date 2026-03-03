import SwiftUI
import SwiftData
import AVFoundation
import Lottie
import RevenueCat
import RevenueCatUI

struct ProfileScreenView: View {
    @StateObject var viewModel: ProfileScreenViewModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @State private var showEmojiPicker = false
    @State private var isPickingCoreEmoji = true
    @State private var showLoginSheet = false
    @State private var showLogoutSheet = false
    @State private var navigateToSettings = false
    @StateObject private var authManager = AuthManager.shared
    @State private var showSuccessMessage = false
    @State private var adaptationTimer: Timer?
    @State private var showingCelebration = false
    @StateObject private var paywallManager = PaywallManager.shared
    @StateObject private var tourManager = AppTourManager.shared
    
    init() {
        self._viewModel = StateObject(wrappedValue: ProfileScreenViewModel(languageManager: LanguageManager.shared))
    }
    
    var body: some View {
        return ZStack {
            // Ana NavigationStack
            NavigationStack {
                ZStack {
                    Color.appBackground
                        .ignoresSafeArea()
                    
                    ScrollViewReader { scrollProxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: PSSpacing.xl) {
                            // Profile Header Card
                            ProfileHeaderCard(
                                showLoginSheet: $showLoginSheet, 
                                showLogoutSheet: $showLogoutSheet,
                                navigateToSettings: $navigateToSettings, 
                                authManager: authManager
                            )
                            .id("scroll.profile.top")
                            
                            // Premium Upgrade Card - Premium kullanıcılar için gizle ve en üstte göster
                            if revenueCatManager.userState != .premium {
                                PremiumUpgradeCard()
                                    .onTapGesture {
                                        paywallManager.presentPaywall(trigger: .manualTrigger)
                                    }
                            }
                            
                            // Stats Grid
                            StatsGridSection(viewModel: viewModel)
                            
                            // Adaptation Completed Celebration Card or Adaptation Phase Card
                            if viewModel.isAdaptationCompleted {
                                AdaptationCompletedCard(viewModel: viewModel, showingCelebration: $showingCelebration)
                                    .tourTarget("tour.profile.adaptation")
                                    .id("tour.profile.adaptation")
                            } else {
                                // Adaptation Phase Card (only show if not completed)
                                AdaptationPhaseCard(viewModel: viewModel)
                                    .tourTarget("tour.profile.adaptation")
                                    .id("tour.profile.adaptation")
                            }
                            

                            
                            // Badges Card
                            ProfileBadgesCard(viewModel: viewModel)
                                .tourTarget("tour.profile.badges")
                                .id("tour.profile.badges")
                            
                            // Customization Card
                            CustomizationCard(
                                viewModel: viewModel, 
                                showEmojiPicker: $showEmojiPicker, 
                                isPickingCoreEmoji: $isPickingCoreEmoji
                            )
                            .requiresPremium()
                        }
                        .padding(.horizontal, PSSpacing.lg)
                        .padding(.vertical, PSSpacing.sm)
                    }
                    .onChange(of: tourManager.currentStepIndex) { _, newIndex in
                        // Handles intra-profile step changes (e.g., adaptation → badges)
                        handleProfileTourScroll(step: TourStep(rawValue: newIndex), proxy: scrollProxy, delay: 0.2)
                    }
                    .onAppear {
                        // Handles the tab-switch-to-profile case: onChange fires before views render,
                        // so onAppear gives a second chance after the tab is fully visible.
                        guard tourManager.isShowingTour else { return }
                        handleProfileTourScroll(step: TourStep(rawValue: tourManager.currentStepIndex), proxy: scrollProxy, delay: 0.35)
                    }
                    } // end ScrollViewReader
                    
                    // Başarılı giriş mesajı
                    if showSuccessMessage {
                        VStack {
                            Text(L("profile.login.success", table: "Profile"))
                                .font(PSTypography.body)
                                .padding(PSSpacing.md)
                                .background(Color.appPrimary)
                                .foregroundColor(.appTextOnPrimary)
                                .cornerRadius(PSCornerRadius.small)
                                .shadow(radius: PSSpacing.xs / 2)
                                .padding(.top, PSSpacing.lg)
                            
                            Spacer()
                        }
                        .transition(.move(edge: .top))
                        .animation(.easeInOut, value: showSuccessMessage)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    showSuccessMessage = false
                                }
                            }
                        }
                    }
                }
                .navigationTitle(L("profile.title", table: "Profile"))
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showEmojiPicker) {
                    EmojiPickerView(
                        selectedEmoji: isPickingCoreEmoji ? $viewModel.selectedCoreEmoji : $viewModel.selectedNapEmoji,
                        onSave: {
                            if isPickingCoreEmoji {
                                viewModel.saveEmojiPreference(coreEmoji: viewModel.selectedCoreEmoji)
                            } else {
                                viewModel.saveEmojiPreference(napEmoji: viewModel.selectedNapEmoji)
                            }
                        }
                    )
                    .presentationDetents([.medium])
                }
                .sheet(isPresented: $showLoginSheet) {
                    LoginSheetView(authManager: authManager, onSuccessfulLogin: {
                        showSuccessMessage = true
                    })
                    .presentationDetents([.height(350)])
                }
                .sheet(isPresented: $showLogoutSheet) {
                    LogoutSheetView(authManager: authManager)
                        .presentationDetents([.height(200)])
                }

                .navigationDestination(isPresented: $navigateToSettings) {
                    SettingsView()
                }
                .onAppear {
                    viewModel.setModelContext(modelContext)
                    startAdaptationTimer()
                    
                    // Undo banner için güncelleme timer'ı
                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                        viewModel.objectWillChange.send()
                    }
                }
                .onChange(of: tourManager.navigateToSettingsForTour) { _, shouldNavigate in
                    navigateToSettings = shouldNavigate
                }
                .onDisappear {
                    stopAdaptationTimer()
                }
            }
            .id(languageManager.currentLanguage)
            
            // Celebration Overlay - NavigationStack'in DIŞINDA tam ekranı kaplar
            if showingCelebration {
                CelebrationOverlay(
                    isShowing: $showingCelebration,
                    title: L("profile.adaptation.completed.title", table: "Profile"),
                    subtitle: L("profile.adaptation.completed.subtitle", table: "Profile")
                )
            }
        }
    }
    
    // MARK: - Timer Functions
    private func startAdaptationTimer() {
        stopAdaptationTimer() // Mevcut timer'ı durdur
        
        // Her gece yarısında adaptasyon fazını kontrol et
        adaptationTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { (_: Timer) in
            // Her saat kontrol et, ama sadece gece yarısı geçtiyse güncelle
            Task {
                await viewModel.loadData()
            }
        }
    }
    
    private func stopAdaptationTimer() {
        adaptationTimer?.invalidate()
        adaptationTimer = nil
    }

    // MARK: - Tour Scroll Helper

    private func handleProfileTourScroll(step: TourStep?, proxy: ScrollViewProxy, delay: Double) {
        guard let step, step.requiredTab == 3 else { return }
        let scrollId: String
        switch step {
        case .profileAdaptation: scrollId = "tour.profile.adaptation"
        case .profileBadges:     scrollId = "tour.profile.badges"
        case .settingsButton:    scrollId = "scroll.profile.top"
        default: return
        }
        let anchor: UnitPoint = scrollId == "scroll.profile.top" ? .top : UnitPoint(x: 0.5, y: 0.25)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeInOut(duration: 0.35)) {
                proxy.scrollTo(scrollId, anchor: anchor)
            }
        }
    }
}

struct ProfileScreenView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileScreenView()
            .environmentObject(LanguageManager.shared)
    }
}
