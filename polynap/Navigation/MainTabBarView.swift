import SwiftUI
import SwiftData

struct MainTabBarView: View {
    @State private var selectedTab = 0
    @StateObject private var mainScreenViewModel: MainScreenViewModel
    @StateObject private var paywallManager = PaywallManager.shared
    @StateObject private var tourManager = AppTourManager.shared
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var alarmManager: AlarmManager
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @EnvironmentObject private var analyticsManager: AnalyticsManager
    
    @State private var hasCheckedOnboardingPaywall = false
    @State private var earnedBadgeForModal: BadgeDefinition? = nil
    @State private var pendingOnboardingBadge: BadgeDefinition? = nil
    @AppStorage("hasShownOnboardingBadgeModal") private var hasShownOnboardingBadgeModal: Bool = false
    @AppStorage("onboardingPaywallCompleted") private var onboardingPaywallCompleted: Bool = false
    
    init() {
        self._mainScreenViewModel = StateObject(wrappedValue: MainScreenViewModel(languageManager: LanguageManager.shared))
    }
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
                
            TabView(selection: $selectedTab) {
                NavigationStack {
                    MainScreenView(viewModel: mainScreenViewModel)
                }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text(L("tabbar.schedule", table: "Common"))
                }
                .tag(0)
                
                HistoryView()
                    .environmentObject(mainScreenViewModel)
                    .tabItem {
                        Image(systemName: "clock.fill")
                        Text(L("tabbar.history", table: "Common"))
                    }
                    .tag(1)
                
                AnalyticsView()
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text(L("tabbar.analytics", table: "Common"))
                    }
                    .tag(2)
                
                ProfileScreenView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text(L("tabbar.profile", table: "Common"))
                    }
                    .tag(3)
            }
            .accentColor(Color("AccentColor"))
            .onAppear {
                // 📊 Analytics: İlk tab screen view
                logTabScreenView(selectedTab)
                HapticFeedbackManager.shared.prepareGenerators()
                mainScreenViewModel.setModelContext(modelContext)
                checkAndTriggerOnboardingPaywall()
                // Tanıtımı yalnızca paywall gösterildiyse başlat (yeni onboarding = paywall önce çıkar, sonra tanıtım)
                if onboardingPaywallCompleted || tourManager.hasCompletedTour {
                    tourManager.startTourIfNeeded()
                }
                
                // Badge modal: starter badge onboarding sırasında kazanıldıysa ama modal gösterilmediyse.
                // Tanıtım aktifse VEYA henüz tamamlanmamışsa (yakında başlayacak demek) badge'i pending'e al;
                // onChange(of: tourManager.isShowingTour) tur bitince pending badge'i gösterecek.
                if !hasShownOnboardingBadgeModal && BadgeManager.shared.earnedBadgeIds.contains("badge-starter") {
                    let all = BadgeDefinition.all(earnedIds: BadgeManager.shared.earnedBadgeIds)
                    if let starterBadge = all.first(where: { $0.id == "badge-starter" }) {
                        if tourManager.isShowingTour || !tourManager.hasCompletedTour {
                            pendingOnboardingBadge = starterBadge
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                earnedBadgeForModal = starterBadge
                                hasShownOnboardingBadgeModal = true
                            }
                        }
                    }
                }
            }
            .onChange(of: revenueCatManager.userState) { _, _ in
                // User state değiştiğinde tekrar kontrol et
                if !hasCheckedOnboardingPaywall {
                    checkAndTriggerOnboardingPaywall()
                }
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                guard oldValue != newValue else { return }
                HapticFeedbackManager.shared.trigger(.softCommit)
                // 📊 Analytics: Tab değişikliği tracking
                logTabScreenView(newValue)
                analyticsManager.logFeatureUsed(featureName: "tab_navigation", action: "tab_changed")
            }
            // Switch tab when tour requires it
            .onChange(of: tourManager.currentStepIndex) { _, _ in
                let requiredTab = tourManager.currentStep.requiredTab
                if selectedTab != requiredTab {
                    withAnimation {
                        selectedTab = requiredTab
                    }
                }
            }

            // Global badge earned modal
            if let badge = earnedBadgeForModal {
                BadgeCelebrationModal(badge: badge) {
                    let isStarterBadge = badge.id == "badge-starter"
                    earnedBadgeForModal = nil
                    if isStarterBadge {
                        // Tanıtım → badge → rating sırası: badge kapanınca rating sor
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            RatingManager.shared.requestRating {}
                        }
                    }
                }
                .zIndex(100)
            }
        }
        // App tour overlay collects preference anchors from all children
        .overlayPreferenceValue(TourTargetKey.self) { anchors in
            if tourManager.isShowingTour {
                AppTourOverlayView(anchors: anchors)
                    .environmentObject(tourManager)
                    .environmentObject(languageManager)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .badgeEarned)) { notification in
            guard let badgeId = notification.userInfo?["badgeId"] as? String else { return }
            let all = BadgeDefinition.all(earnedIds: BadgeManager.shared.earnedBadgeIds)
            guard let badge = all.first(where: { $0.id == badgeId }) else { return }

            if badge.id == "badge-starter" {
                // Starter badge: defer until after tour, show only once.
                // Tanıtım aktifse VEYA henüz tamamlanmamışsa badge'i pending'e al.
                guard !hasShownOnboardingBadgeModal else { return }
                if tourManager.isShowingTour || !tourManager.hasCompletedTour {
                    pendingOnboardingBadge = badge
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        earnedBadgeForModal = badge
                        hasShownOnboardingBadgeModal = true
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    earnedBadgeForModal = badge
                }
            }
        }
        .onChange(of: tourManager.isShowingTour) { _, isShowing in
            if isShowing {
                // Tanıtım her zaman ana sayfadan (overview) başlasın
                withAnimation { selectedTab = 0 }
            }
            if !isShowing, let pending = pendingOnboardingBadge, !hasShownOnboardingBadgeModal {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    earnedBadgeForModal = pending
                    hasShownOnboardingBadgeModal = true
                    pendingOnboardingBadge = nil
                }
            }
        }
        .managePaywalls() // PaywallManager ile otomatik paywall yönetimi
    }
    
    private func checkAndTriggerOnboardingPaywall() {
        // NOT: Onboarding paywall artık OnboardingViewModel'da yönetiliyor
        // Bu fonksiyon devre dışı bırakıldı - rating sonrası paywall akışı için
        print("📱 MainTabBarView: Onboarding paywall OnboardingViewModel'da yönetiliyor, burada skip ediliyor")
        hasCheckedOnboardingPaywall = true
    }
    
    // 📊 Analytics: Tab screen view tracking helper
    private func logTabScreenView(_ tabIndex: Int) {
        let screenNames = [
            0: ("MainScreen", "MainScreenView"),
            1: ("History", "HistoryView"),
            2: ("Analytics", "AnalyticsView"), 
            3: ("Profile", "ProfileScreenView")
        ]
        
        if let (screenName, screenClass) = screenNames[tabIndex] {
            analyticsManager.logScreenView(screenName: screenName, screenClass: screenClass)
        }
    }
}

struct MainTabBarView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabBarView()
            .environmentObject(LanguageManager.shared)
    }
}
