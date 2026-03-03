import SwiftUI
import SwiftData
import UserNotifications

struct NotificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.colorScheme) private var colorScheme
    
    // State ile async veri yükleme
    @State private var userPreferences: [UserPreferences] = []
    @State private var isLoading = true
    @State private var reminderTime: Double = 15
    @State private var showTestAlert = false
    @State private var testNotificationScheduled = false
    @State private var notificationPermissionStatus = "Bilinmiyor"
    
    var currentPreferences: UserPreferences? {
        userPreferences.first
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: PSSpacing.xl) {
                // Reminder Time Card
                SettingsGroup(title: L("notifications.reminderTime.title", table: "Settings")) {
                    VStack(spacing: 16) {
                        HStack {
                            if reminderTime > 0 {
                                Text(formatTime(minutes: Int(reminderTime)))
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.appPrimary)
                            } else {
                                Text(L("notifications.off", table: "Settings"))
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.appTextSecondary)
                            }
                            Spacer()
                            HStack(spacing: 8) {
                                QuickTimeButton(time: 5, currentTime: $reminderTime)
                                QuickTimeButton(time: 15, currentTime: $reminderTime)
                                QuickTimeButton(time: 30, currentTime: $reminderTime)
                            }
                        }

                        Slider(value: $reminderTime, in: 0...120, step: 1)
                            .accentColor(.appPrimary)
                            .onChange(of: reminderTime) { oldValue, newValue in
                                saveReminderTime(minutes: Int(newValue))
                            }

                        HStack {
                            Text(L("notifications.off", table: "Settings"))
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(.appTextSecondary)
                            Spacer()
                            Text(L("notifications.twoHours", table: "Settings"))
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }

                Spacer(minLength: PSSpacing.xl)
            }
            .padding(.horizontal, PSSpacing.lg)
            .padding(.top, PSSpacing.sm)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(L("notifications.settings.title", table: "Settings"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadDataAsync()
        }
        .alert(L("notifications.test.alert.title", table: "Settings"), isPresented: $showTestAlert) {
            Button(L("general.ok", table: "Settings")) { }
        } message: {
            Text(L("notifications.test.alert.message", table: "Settings"))
        }
    }
    
    // MARK: - Data Loading
    private func loadDataAsync() {
        guard isLoading else { return }
        
        Task { @MainActor in
            do {
                // SwiftData'dan async olarak veri çek
                let fetchDescriptor = FetchDescriptor<UserPreferences>()
                let preferences = try modelContext.fetch(fetchDescriptor)
                
                userPreferences = preferences
                loadCurrentSettings()
                await checkNotificationPermission()
                isLoading = false
            } catch {
                print("NotificationSettingsView: Veri yükleme hatası - \(error)")
                isLoading = false
            }
        }
    }
    
    private func loadCurrentSettings() {
        if let preferences = currentPreferences {
            reminderTime = Double(preferences.reminderLeadTimeInMinutes)
        } else {
            createInitialPreferences()
        }
    }
    
    private func createInitialPreferences() {
        let newPreferences = UserPreferences(reminderLeadTimeInMinutes: 15)
        modelContext.insert(newPreferences)
        do { try modelContext.save(); reminderTime = 15 }
        catch { print("UserPreferences oluşturulurken hata: \(error)") }
    }
    
    private func saveReminderTime(minutes: Int) {
        guard let preferences = currentPreferences else {
            createInitialPreferences()
            return
        }
        
        preferences.reminderLeadTimeInMinutes = minutes
        
        do {
            try modelContext.save()
            print("✅ Hatırlatma süresi güncellendi: \(minutes) dakika. Bildirimler yeniden planlanıyor...")
            
            // Async işlemi Task içinde yap
            Task {
                await updateNotificationsForActiveSchedule()
            }
        } catch {
            print("❌ Hatırlatma süresi kaydedilemedi: \(error)")
        }
    }
    
    private func updateNotificationsForActiveSchedule() async {
        await AlarmService.shared.rescheduleNotificationsForActiveSchedule(modelContext: modelContext)
    }

    private func checkNotificationPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            switch settings.authorizationStatus {
            case .authorized: notificationPermissionStatus = "İzin Verildi"
            case .denied: notificationPermissionStatus = "Reddedildi"
            default: notificationPermissionStatus = "Belirlenmedi"
            }
        }
    }
    
    private func formatTime(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) dakika"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 { return "\(hours) saat" }
            else { return "\(hours) saat \(remainingMinutes) dakika" }
        }
    }
    
    private func testNotificationImmediately() {
        Task {
            await AlarmService.shared.scheduleTestNotification(soundName: "default", volume: 0.8)
            showTestAlert = true
            testNotificationScheduled = true
            
            // 3 saniye sonra scheduled durumunu sıfırla
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                testNotificationScheduled = false
            }
        }
    }
    
    private func test5SecondNotification() {
        Task {
            await AlarmService.shared.scheduleTestNotification(soundName: "default", volume: 0.8)
            showTestAlert = true
            testNotificationScheduled = true
            
            // 3 saniye sonra scheduled durumunu sıfırla
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                testNotificationScheduled = false
            }
        }
    }
}

// MARK: - Modern Components

// Modern notification card component with enhanced styling
struct ModernNotificationCard<Content: View>: View {
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCardBackground)
                    .overlay(
                        // Subtle border for light mode
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(colorScheme == .light ? 0.15 : 0),
                                        Color.gray.opacity(colorScheme == .light ? 0.05 : 0)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: colorScheme == .light ? 
                        Color.black.opacity(0.08) : 
                        Color.black.opacity(0.3),
                        radius: colorScheme == .light ? 12 : 16,
                        x: 0,
                        y: colorScheme == .light ? 6 : 8
                    )
            )
    }
}

// Fixed quick time button
struct QuickTimeButton: View {
    let time: Int
    @Binding var currentTime: Double

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentTime = Double(time)
            }
        }) {
            Text("\(time) dk")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .fixedSize()
                .foregroundColor(currentTime == Double(time) ? .white : .appPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(currentTime == Double(time) ? Color.appPrimary : Color.appPrimary.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
    }
}

// Modern slider with enhanced styling
struct ModernSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let trackColor: Color
    let thumbColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Slider(value: $value, in: range, step: step)
                .accentColor(thumbColor)
                .background(
                    // Custom track
                    RoundedRectangle(cornerRadius: 8)
                        .frame(height: 6)
                        .foregroundColor(trackColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .frame(height: 6)
                                .foregroundColor(thumbColor)
                                .scaleEffect(x: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)), y: 1, anchor: .leading)
                        )
                        .allowsHitTesting(false)
                )
        }
    }
}

// Modern test button with enhanced styling
struct ModernNotificationTestButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.appText)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(color.opacity(0.7))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                color.opacity(0.05),
                                color.opacity(0.02)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ModernTestButtonStyle())
    }
}

// Modern status row with enhanced styling
struct ModernStatusRow: View {
    let icon: String
    let title: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appPrimary)
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.appText)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(valueColor.opacity(0.1))
                )
        }
    }
}

// Modern status divider
struct ModernStatusDivider: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.appTextSecondary.opacity(colorScheme == .light ? 0.15 : 0.08),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.horizontal, 8)
    }
}

// MARK: - Button Styles

struct ModernQuickButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct ModernTestButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NotificationSettingsView()
        }
    }
}
