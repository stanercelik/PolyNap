import SwiftUI
import SwiftData
import RevenueCat
import HealthKit

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("userSelectedTheme") private var userSelectedTheme: Bool?
    @AppStorage("coreNotificationTime") private var coreNotificationTime: Double = 30 // Dakika
    @AppStorage("napNotificationTime") private var napNotificationTime: Double = 15 // Dakika
    @AppStorage("showRatingNotification") private var showRatingNotification = true
    @AppStorage("app_haptics_enabled") private var appHapticsEnabled = true
    @AppStorage("app_sound_effects_enabled") private var appSoundEffectsEnabled = false
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @State private var showLanguagePicker = false
    @State private var showThemePicker = false
    @StateObject private var tourManager = AppTourManager.shared
    
    var body: some View {
        ScrollViewReader { scrollProxy in
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: PSSpacing.xl) {
                // Profile & Account Section
                SettingsGroup(title: L("settings.about.title", table: "Profile")) {
                    SettingsNavRow(
                        icon: "person.circle",
                        title: L("settings.about.personalInfo", table: "Profile"),
                        destination: PersonalInfoView()
                    )
                }

                // Notifications & Alarms Section
                SettingsGroup(title: L("settings.notifications.title", table: "Profile")) {
                    SettingsNavRow(
                        icon: "bell",
                        title: L("settings.notifications.settings", table: "Profile"),
                        destination: NotificationSettingsView()
                    )
                    .tourTarget("tour.settings.notifications")
                    .id("tour.settings.notifications")
                    SettingsRowDivider()
                    SettingsNavRow(
                        icon: "alarm",
                        title: L("settings.alarms.title", table: "Profile"),
                        destination: AlarmSettingsView()
                    )
                    .tourTarget("tour.settings.alarms")
                    .id("tour.settings.alarms")
                }

                // Advanced Section
                SettingsGroup(title: L("settings.advanced.title", table: "Profile")) {
                    AdaptationUndoRow()
                    SettingsRowDivider()
                    RestartOnboardingRow()
                    SettingsRowDivider()
                    RestartTourRow()
                }

                // Integrations Section
                SettingsGroup(title: L("settings.integrations", table: "Settings")) {
                    HealthKitIntegrationRow()
                        .tourTarget("tour.settings.health")
                        .id("tour.settings.health")
                }

                // General Settings Section
                SettingsGroup(title: L("settings.general.title", table: "Profile")) {
                    SettingsToggleRow(
                        icon: "iphone.radiowaves.left.and.right",
                        title: L("settings.haptics.title", table: "Settings"),
                        description: L("settings.haptics.description", table: "Settings"),
                        isOn: $appHapticsEnabled
                    )
                    SettingsRowDivider()
                    SettingsToggleRow(
                        icon: "speaker.wave.2",
                        title: L("settings.sounds.title", table: "Settings"),
                        description: L("settings.sounds.description", table: "Settings"),
                        isOn: $appSoundEffectsEnabled
                    )
                    SettingsRowDivider()
                    SettingsActionRow(
                        icon: "moon",
                        title: L("settings.general.theme", table: "Profile"),
                        value: getThemeDisplayText(),
                        action: { showThemePicker = true }
                    )
                    SettingsRowDivider()
                    SettingsActionRow(
                        icon: "globe",
                        title: L("settings.general.language", table: "Profile"),
                        value: getLanguageDisplayText(),
                        action: { showLanguagePicker = true }
                    )
                }

                // Support & More Section
                SettingsGroup(title: L("settings.other.title", table: "Profile")) {
                    if !hasUserRatedBefore() {
                        SettingsActionRow(
                            icon: "star",
                            iconColor: .orange,
                            title: L("settings.other.rate", table: "Profile"),
                            action: {
                                RatingManager.shared.requestRating { }
                            }
                        )
                        SettingsRowDivider()
                    }
                    SettingsNavRow(
                        icon: "info.circle",
                        title: L("settings.other.disclaimer", table: "Profile"),
                        destination: DisclaimerView()
                    )
                    SettingsRowDivider()
                    SettingsNavRow(
                        icon: "envelope",
                        title: L("feedback.title", table: "Profile"),
                        destination: FeedbackView()
                    )
                }

                // Version Footer
                VStack(spacing: 4) {
                    Text("PolyNap  v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.appTextSecondary)
                    Text(L("settings.copyright", table: "Profile"))
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.appTextSecondary.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, PSSpacing.sm)
                .padding(.bottom, PSSpacing.xxl)
            }
            .padding(.horizontal, PSSpacing.lg)
            .padding(.top, PSSpacing.sm)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(L("settings.title", table: "Profile"))
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: tourManager.currentStepIndex) { _, newIndex in
            guard let step = TourStep(rawValue: newIndex), step.requiresSettingsNav else { return }
            let scrollId: String
            switch step {
            case .settingsNotifications: scrollId = "tour.settings.notifications"
            case .settingsAlarms:        scrollId = "tour.settings.alarms"
            case .settingsRestartTour:   scrollId = "tour.settings.restartTour"
            case .settingsHealth:        scrollId = "tour.settings.health"
            default: return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    scrollProxy.scrollTo(scrollId, anchor: UnitPoint(x: 0.5, y: 0.25))
                }
            }
        }
        .confirmationDialog(L("settings.general.selectTheme", table: "Profile"), isPresented: $showThemePicker, titleVisibility: .visible) {
            Button(L("settings.general.theme.system", table: "Profile")) {
                HapticFeedbackManager.shared.trigger(.selection)
                userSelectedTheme = nil
            }
            Button(L("settings.general.theme.light", table: "Profile")) {
                HapticFeedbackManager.shared.trigger(.selection)
                userSelectedTheme = false
            }
            Button(L("settings.general.theme.dark", table: "Profile")) {
                HapticFeedbackManager.shared.trigger(.selection)
                userSelectedTheme = true
            }
            Button(L("general.cancel", table: "Profile"), role: .cancel) { }
        }
        .confirmationDialog(L("settings.general.selectLanguage", table: "Profile"), isPresented: $showLanguagePicker, titleVisibility: .visible) {
            Button(L("settings.language.turkish", table: "Profile")) {
                HapticFeedbackManager.shared.trigger(.selection)
                languageManager.changeLanguage(to: "tr")
            }
            Button(L("settings.language.english", table: "Profile")) {
                HapticFeedbackManager.shared.trigger(.selection)
                languageManager.changeLanguage(to: "en")
            }
            Button(L("settings.language.japanese", table: "Profile")) {
                HapticFeedbackManager.shared.trigger(.selection)
                languageManager.changeLanguage(to: "ja")
            }
            Button(L("settings.language.german", table: "Profile")) {
                HapticFeedbackManager.shared.trigger(.selection)
                languageManager.changeLanguage(to: "de")
            }
            Button(L("settings.language.malay", table: "Profile")) {
                HapticFeedbackManager.shared.trigger(.selection)
                languageManager.changeLanguage(to: "ms")
            }
            Button(L("settings.language.thai", table: "Profile")) {
                HapticFeedbackManager.shared.trigger(.selection)
                languageManager.changeLanguage(to: "th")
            }
            Button(L("general.cancel", table: "Profile"), role: .cancel) { }
        }
        .environment(\.locale, Locale(identifier: languageManager.currentLanguage))
        .onChange(of: appHapticsEnabled) { _, isEnabled in
            HapticFeedbackManager.shared.setEnabled(isEnabled)
            HapticFeedbackManager.shared.trigger(.selection)
        }
        .onChange(of: appSoundEffectsEnabled) { _, isEnabled in
            SoundEffectManager.shared.setEnabled(isEnabled)
            if isEnabled {
                SoundEffectManager.shared.play(.click)
            }
        }
        .onAppear {
            HapticFeedbackManager.shared.setEnabled(appHapticsEnabled)
            SoundEffectManager.shared.setEnabled(appSoundEffectsEnabled)
        }
        } // end ScrollViewReader
    }
    
    /// Kullanıcının daha önce rating verip vermediğini kontrol eder
    private func hasUserRatedBefore() -> Bool {
        return UserDefaults.standard.bool(forKey: "has_requested_review")
    }
    
    /// Seçili temanın görüntülenen metnini döndürür
    private func getThemeDisplayText() -> String {
        if let userChoice = userSelectedTheme {
            return userChoice ? L("settings.general.theme.dark", table: "Profile") : L("settings.general.theme.light", table: "Profile")
        } else {
            return L("settings.general.theme.system", table: "Profile")
        }
    }
    
    /// Seçili dilin görüntülenen metnini döndürür
    private func getLanguageDisplayText() -> String {
        switch languageManager.currentLanguage {
        case "tr":
            return L("settings.language.turkish", table: "Profile")
        case "ja":
            return L("settings.language.japanese", table: "Profile")
        case "de":
            return L("settings.language.german", table: "Profile")
        default:
            return L("settings.language.english", table: "Profile")
        }
    }
    

}

// MARK: - Settings Components

struct SettingsGroup<Content: View>: View {
    let title: String?
    @ViewBuilder let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title = title {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.appTextSecondary)
                    .padding(.leading, 4)
            }
            VStack(spacing: 0) {
                content
            }
            .background(Color.appCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appBorder.opacity(0.5), lineWidth: 0.5)
            )
        }
    }
}

struct SettingsNavRow<Destination: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let destination: Destination

    init(icon: String, iconColor: Color = .appPrimary, title: String, destination: Destination) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.destination = destination
    }

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(.appText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.appTextSecondary.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            TapGesture().onEnded {
                HapticFeedbackManager.shared.trigger(.softCommit)
            }
        )
    }
}

struct SettingsActionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let showChevron: Bool
    let action: () -> Void

    init(icon: String, iconColor: Color = .appPrimary, title: String, value: String = "", showChevron: Bool = true, action: @escaping () -> Void) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.value = value
        self.showChevron = showChevron
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticFeedbackManager.shared.trigger(.softCommit)
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(.appText)
                Spacer()
                if !value.isEmpty {
                    Text(value)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.appTextSecondary)
                }
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appTextSecondary.opacity(0.4))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String?
    @Binding var isOn: Bool

    init(icon: String, iconColor: Color = .appPrimary, title: String, description: String? = nil, isOn: Binding<Bool>) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.description = description
        self._isOn = isOn
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(.appText)

                if let description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.appTextSecondary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .onChange(of: isOn) { _, _ in
                    HapticFeedbackManager.shared.trigger(.selection)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}

struct SettingsRowDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 52)
    }
}

// Legacy divider kept for sub-screen use
struct ModernDivider: View {
    var body: some View {
        Divider().padding(.leading, 52)
    }
}

// MARK: - Adaptation Undo Row
struct AdaptationUndoRow: View {
    @StateObject private var viewModel = ProfileScreenViewModel(languageManager: LanguageManager.shared)
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showingUndoAlert = false
    @State private var isUndoing = false
    @State private var undoError: String? = nil
    @StateObject private var paywallManager = PaywallManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.orange)
                .frame(width: 24, height: 24)

            Text(L("settings.adaptation.undo.title", table: "Profile"))
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundColor(.appText)

            Spacer()
            
            // Action button
            if viewModel.hasRawUndoData() {
                PSStatusBadge(
                    L("settings.adaptation.undo.button", table: "Profile"),
                    icon: "arrow.uturn.backward",
                    color: .orange,
                    backgroundColor: Color.orange.opacity(0.15)
                )
                .onTapGesture {
                    handleUndoTap()
                }
            } else {
                PSStatusBadge(
                    L("settings.adaptation.undo.notAvailableStatus", table: "Profile"),
                    icon: "xmark.circle",
                    color: .appTextSecondary,
                    backgroundColor: Color.appTextSecondary.opacity(0.1)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .alert(L("settings.adaptation.undo.alert.title", table: "Profile"), isPresented: $showingUndoAlert) {
            Button(L("general.cancel", table: "Profile"), role: .cancel) {}
            Button(L("settings.adaptation.undo.button", table: "Profile"), role: .destructive) {
                performUndo()
            }
        } message: {
            Text(L("settings.adaptation.undo.alert.message", table: "Profile"))
        }
        .alert(L("general.error", table: "Profile"), isPresented: .init(get: { undoError != nil }, set: { if !$0 { undoError = nil } })) {
            Button(L("general.ok", table: "Profile"), role: .cancel) {
                undoError = nil
            }
        } message: {
            Text(undoError ?? L("general.unknownError", table: "Profile"))
        }
        .environment(\.locale, Locale(identifier: languageManager.currentLanguage))
        .onAppear {
            // ViewModelContext gerekli değil, sadece repository kullanacağız
        }
    }
    
    private func handleUndoTap() {
        // Premium kontrolü
        if revenueCatManager.userState != .premium {
            HapticFeedbackManager.shared.trigger(.warning)
            paywallManager.presentPaywall(trigger: .premiumFeatureAccess)
            return
        }

        HapticFeedbackManager.shared.trigger(.warning)
        showingUndoAlert = true
    }
    
    private func performUndo() {
        isUndoing = true
        
        Task {
            do {
                try await viewModel.undoScheduleChange()
                await MainActor.run {
                    HapticFeedbackManager.shared.trigger(.success)
                    isUndoing = false
                }
            } catch {
                await MainActor.run {
                    HapticFeedbackManager.shared.trigger(.error)
                    undoError = error.localizedDescription
                    isUndoing = false
                }
            }
        }
    }
}

// MARK: - HealthKit Integration Row
struct HealthKitIntegrationRow: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @StateObject private var paywallManager = PaywallManager.shared
    @State private var isConnecting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.green)
                .frame(width: 24, height: 24)

            HStack(spacing: 4) {
                Text("Apple Sağlık")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(.appText)

                Image(systemName: "crown.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.yellow)
            }

            Spacer()

            // Status badge or action button
            statusBadge
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .onAppear {
            Task {
                await healthKitManager.getAuthorizationStatus { status in
                    DispatchQueue.main.async {
                        healthKitManager.authorizationStatus = status
                    }
                }
            }
        }
        .alert("Hata", isPresented: $showingError) {
            Button("Tamam", role: .cancel) {
                showingError = false
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        // Premium check first
        if revenueCatManager.userState != .premium {
            PSStatusBadge(
                "Premium",
                icon: "crown.fill",
                color: .yellow,
                backgroundColor: Color.yellow.opacity(0.15)
            )
            .onTapGesture {
                paywallManager.presentPaywall(trigger: .premiumFeatureAccess)
            }
        } else {
            switch healthKitManager.authorizationStatus {
            case .notDetermined:
                if isConnecting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                } else {
                    PSStatusBadge(
                        L("settings.health.connect", table: "Settings"),
                        icon: "plus.circle.fill",
                        color: .green,
                        backgroundColor: Color.green.opacity(0.15)
                    )
                    .onTapGesture {
                        Task {
                            await requestHealthKitPermission()
                        }
                    }
                }
            
            case .sharingAuthorized:
                PSStatusBadge(
                    L("settings.health.connected", table: "Settings"),
                    icon: "checkmark.circle.fill",
                    color: .green,
                    backgroundColor: Color.green.opacity(0.15)
                )
                
            case .sharingDenied:
                PSStatusBadge(
                    L("settings.health.denied", table: "Settings"),
                    icon: "xmark.circle.fill",
                    color: .red,
                    backgroundColor: Color.red.opacity(0.15)
                )
                .onTapGesture {
                    openHealthSettings()
                }
                
            @unknown default:
                PSStatusBadge(
                    "Bilinmiyor",
                    icon: "questionmark.circle.fill",
                    color: .appTextSecondary,
                    backgroundColor: Color.appTextSecondary.opacity(0.1)
                )
            }
        }
    }
    
    private func getStatusText() -> String {
        if revenueCatManager.userState != .premium {
            return "Premium üyelik gerekli"
        }
        
        if !healthKitManager.isHealthDataAvailable {
            return "Bu cihazda HealthKit kullanılamıyor"
        }
        
        switch healthKitManager.authorizationStatus {
        case .notDetermined:
            return L("settings.health.status.notDetermined", table: "Settings")
        case .sharingAuthorized:
            return L("settings.health.status.authorized", table: "Settings")
        case .sharingDenied:
            return L("settings.health.status.denied", table: "Settings")
        @unknown default:
            return L("settings.health.status.unknown", table: "Settings")
        }
    }
    
    private func requestHealthKitPermission() async {
        guard !isConnecting else { return }
        
        isConnecting = true
        defer { isConnecting = false }
        
        let result = await healthKitManager.requestAuthorization()
        
        switch result {
        case .success(_):
            // Success, status will be updated automatically
            break
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func openHealthSettings() {
        guard let url = URL(string: "x-apple-health://") else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Fallback to general settings
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }
}

// MARK: - Restart Onboarding Row
struct RestartOnboardingRow: View {
    @State private var showingRestartAlert = false
    @State private var isRestarting = false
    @State private var userPreferences: UserPreferences?
    @State private var restartCount = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @StateObject private var paywallManager = PaywallManager.shared
    
    var isPremiumRequired: Bool {
        return restartCount >= 1
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.appPrimary)
                .frame(width: 24, height: 24)

            HStack(spacing: 4) {
                Text(L("settings.onboarding.restart.title", table: "Profile"))
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(.appText)

                if isPremiumRequired {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.yellow)
                }
            }

            Spacer()

            // Action button
            PSStatusBadge(
                L("settings.onboarding.restart.button", table: "Profile"),
                icon: "arrow.clockwise",
                color: isPremiumRequired && revenueCatManager.userState != .premium ? .yellow : .appPrimary,
                backgroundColor: isPremiumRequired && revenueCatManager.userState != .premium ? Color.yellow.opacity(0.15) : Color.appPrimary.opacity(0.15)
            )
            .onTapGesture {
                handleRestartTap()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
        .alert(
            L("settings.onboarding.restart.alert.title", table: "Profile"),
            isPresented: $showingRestartAlert
        ) {
            Button(L("common.cancel", table: "Common"), role: .cancel) {}
            Button(L("settings.onboarding.restart.alert.confirm", table: "Profile"), role: .destructive) {
                Task {
                    await restartOnboarding()
                }
            }
        } message: {
            Text(L("settings.onboarding.restart.alert.message", table: "Profile"))
        }
        .overlay {
            if isRestarting {
                ProgressView()
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
        .onAppear {
            loadUserPreferences()
        }
    }
    
    private func loadUserPreferences() {
        do {
            let descriptor = FetchDescriptor<UserPreferences>()
            let preferences = try modelContext.fetch(descriptor)
            
            if let preference = preferences.first {
                userPreferences = preference
                restartCount = preference.onboardingRestartCount
            }
        } catch {
            print("❌ RestartOnboardingRow: UserPreferences yüklenirken hata: \(error.localizedDescription)")
        }
    }
    
    private func handleRestartTap() {
        // Check if premium is required and user is not premium
        if isPremiumRequired && revenueCatManager.userState != .premium {
            HapticFeedbackManager.shared.trigger(.warning)
            paywallManager.presentPaywall(trigger: .premiumFeatureAccess)
            return
        }

        HapticFeedbackManager.shared.trigger(.warning)
        showingRestartAlert = true
    }
    
    private func restartOnboarding() async {
        isRestarting = true
        defer { isRestarting = false }
        
        // Increment restart count
        await incrementRestartCount()
        
        // Reset user preferences to restart onboarding
        await resetUserPreferencesForOnboarding()
        
        // Dismiss settings and trigger onboarding restart
        await MainActor.run {
            HapticFeedbackManager.shared.trigger(.success)
            dismiss()
            
            // Trigger onboarding restart by posting notification
            NotificationCenter.default.post(name: .restartOnboarding, object: nil)
        }
    }
    
    private func incrementRestartCount() async {
        do {
            let descriptor = FetchDescriptor<UserPreferences>()
            let preferences = try modelContext.fetch(descriptor)
            
            for preference in preferences {
                preference.onboardingRestartCount += 1
                restartCount = preference.onboardingRestartCount
            }
            
            try modelContext.save()
            print("✅ RestartOnboardingRow: Restart count artırıldı: \(restartCount)")
        } catch {
            print("❌ RestartOnboardingRow: Restart count artırılırken hata: \(error.localizedDescription)")
        }
    }
    
    private func resetUserPreferencesForOnboarding() async {
        do {
            let descriptor = FetchDescriptor<UserPreferences>()
            let preferences = try modelContext.fetch(descriptor)
            
            for preference in preferences {
                preference.hasCompletedOnboarding = false
                preference.hasSkippedOnboarding = false
                preference.hasCompletedQuestions = false
                // onboardingRestartCount'ı sıfırlamıyoruz - kullanıcının geçmişi
            }
            
            try modelContext.save()
            print("✅ RestartOnboardingRow: UserPreferences onboarding için sıfırlandı")
        } catch {
            print("❌ RestartOnboardingRow: UserPreferences sıfırlanırken hata: \(error.localizedDescription)")
        }
    }
}

extension Notification.Name {
    static let restartOnboarding = Notification.Name("restartOnboarding")
}

// MARK: - Restart Tour Row
struct RestartTourRow: View {
    @StateObject private var tourManager = AppTourManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            HapticFeedbackManager.shared.trigger(.softCommit)
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                tourManager.restartTour()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "map")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.appPrimary)
                    .frame(width: 24, height: 24)
                Text(L("tour.restart.title", table: "Tour"))
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(.appText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.appTextSecondary.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .tourTarget("tour.settings.restartTour")
        .id("tour.settings.restartTour")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
        }
        .environmentObject(LanguageManager.shared)
        .environmentObject(RevenueCatManager.shared)
    }
}
