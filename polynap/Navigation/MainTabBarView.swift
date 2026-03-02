import SwiftUI
import SwiftData

struct MainTabBarView: View {
    @State private var selectedTab = 0
    @StateObject private var mainScreenViewModel: MainScreenViewModel
    @StateObject private var paywallManager = PaywallManager.shared
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var alarmManager: AlarmManager
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @EnvironmentObject private var analyticsManager: AnalyticsManager
    
    @State private var hasCheckedOnboardingPaywall = false
    
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
                mainScreenViewModel.setModelContext(modelContext)
                checkAndTriggerOnboardingPaywall()
            }
            .onChange(of: revenueCatManager.userState) { _, _ in
                // User state değiştiğinde tekrar kontrol et
                if !hasCheckedOnboardingPaywall {
                    checkAndTriggerOnboardingPaywall()
                }
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                // 📊 Analytics: Tab değişikliği tracking
                logTabScreenView(newValue)
                analyticsManager.logFeatureUsed(featureName: "tab_navigation", action: "tab_changed")
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
