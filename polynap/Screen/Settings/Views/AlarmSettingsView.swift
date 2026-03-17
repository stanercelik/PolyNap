import SwiftUI
import SwiftData
import UserNotifications
import AVFoundation

struct AlarmSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var languageManager: LanguageManager
    
    // State ile async veri yükleme
    @State private var alarmSettings: [AlarmSettings] = []
    @State private var isLoading = true
    @State private var currentSettings: AlarmSettings?
    @State private var showingPermissionAlert = false
    @State private var showingTestAlarm = false
    @State private var showingAlarmKitTest = false
    @State private var alarmKitTestMessage = ""
    @State private var alarmKitAuthStatus = ""
    
    // State for UI reflecting AlarmService status
    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined
    @State private var pendingAlarmsCount: Int = 0
    
    // State variables
    @State private var isEnabled = true
    @State private var selectedSound = "Alarm 1.caf"
    @State private var volume: Double = 0.8
    @State private var vibrationEnabled = true
    @State private var snoozeEnabled = true
    @State private var snoozeDuration = 5
    @State private var maxSnoozeCount = 3
    
    // Ses dosyalarını bir kez yüklemek için State variable
    @State private var availableSounds: [(String, String)] = []
    
    // Değişiklikleri kaydetmek için debounce timer
    @State private var saveTimer: Timer?
    
    private var isAuthorized: Bool {
        notificationAuthStatus == .authorized || notificationAuthStatus == .provisional
    }
    
    private let snoozeDurations = [1, 3, 5, 10, 15]
    private let maxSnoozeCounts = [1, 2, 3, 5, 10]
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: PSSpacing.xl) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                        .padding(.top, PSSpacing.xxl)
                } else {
                    // Status Section
                    SettingsGroup(title: L("alarmSettings.status.title", table: "Settings")) {
                        HStack(spacing: 12) {
                            Image(systemName: isEnabled ? "alarm" : "alarm.slash")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(isEnabled ? .appPrimary : .appTextSecondary)
                                .frame(width: 24, height: 24)
                            Text(L("alarmSettings.status.sleepAlarms", table: "Settings"))
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundColor(.appText)
                            Spacer()
                            Toggle("", isOn: $isEnabled)
                                .labelsHidden()
                                .onChange(of: isEnabled) { _, _ in
                                    HapticFeedbackManager.shared.trigger(.selection)
                                    scheduleSettingsSave()
                                }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                    }

                    if isEnabled {
                        // Sound Section
                        SettingsGroup(title: L("alarmSettings.sound.title", table: "Settings")) {
                            // Alarm Sound picker
                            Menu {
                                ForEach(availableSounds, id: \.0) { sound, name in
                                    Button(action: {
                                        HapticFeedbackManager.shared.trigger(.selection)
                                        selectedSound = sound
                                        scheduleSettingsSave()
                                        previewSound(sound)
                                    }) {
                                        HStack {
                                            Text(name)
                                            if sound == selectedSound {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "music.note")
                                        .font(.system(size: 18, weight: .regular))
                                        .foregroundColor(.appPrimary)
                                        .frame(width: 24, height: 24)
                                    Text(L("alarmSettings.sound.alarmSound", table: "Settings"))
                                        .font(.system(.body, design: .rounded, weight: .medium))
                                        .foregroundColor(.appText)
                                    Spacer()
                                    Text(availableSounds.first(where: { $0.0 == selectedSound })?.1 ?? "Alarm 1")
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundColor(.appTextSecondary)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.appTextSecondary.opacity(0.4))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 13)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            SettingsRowDivider()

                            // Vibration toggle
                            HStack(spacing: 12) {
                                Image(systemName: "iphone.radiowaves.left.and.right")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundColor(.appPrimary)
                                    .frame(width: 24, height: 24)
                                Text(L("alarmSettings.sound.vibration", table: "Settings"))
                                    .font(.system(.body, design: .rounded, weight: .medium))
                                    .foregroundColor(.appText)
                                Spacer()
                                Toggle("", isOn: $vibrationEnabled)
                                    .labelsHidden()
                                    .onChange(of: vibrationEnabled) { _, _ in
                                        HapticFeedbackManager.shared.trigger(.selection)
                                        scheduleSettingsSave()
                                    }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                        }

                        // Snooze Section
                        SettingsGroup(title: L("alarmSettings.snooze.title", table: "Settings")) {
                            // Enable snooze toggle
                            HStack(spacing: 12) {
                                Image(systemName: "clock.arrow.2.circlepath")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundColor(.purple)
                                    .frame(width: 24, height: 24)
                                Text(L("alarmSettings.snooze.allowSnooze", table: "Settings"))
                                    .font(.system(.body, design: .rounded, weight: .medium))
                                    .foregroundColor(.appText)
                                Spacer()
                                Toggle("", isOn: $snoozeEnabled)
                                    .labelsHidden()
                                    .onChange(of: snoozeEnabled) { _, _ in
                                        HapticFeedbackManager.shared.trigger(.selection)
                                        scheduleSettingsSave()
                                    }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)

                            if snoozeEnabled {
                                SettingsRowDivider()

                                Menu {
                                    ForEach(snoozeDurations, id: \.self) { duration in
                                        Button(L("alarmSettings.snooze.minutesFormat", table: "Settings").replacingOccurrences(of: "{duration}", with: "\(duration)")) {
                                            HapticFeedbackManager.shared.trigger(.selection)
                                            snoozeDuration = duration
                                            scheduleSettingsSave()
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "timer")
                                            .font(.system(size: 18, weight: .regular))
                                            .foregroundColor(.purple)
                                            .frame(width: 24, height: 24)
                                        Text(L("alarmSettings.snooze.duration", table: "Settings"))
                                            .font(.system(.body, design: .rounded, weight: .medium))
                                            .foregroundColor(.appText)
                                        Spacer()
                                        Text(L("alarmSettings.snooze.minutesFormat", table: "Settings").replacingOccurrences(of: "{duration}", with: "\(snoozeDuration)"))
                                            .font(.system(size: 14, design: .rounded))
                                            .foregroundColor(.appTextSecondary)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.appTextSecondary.opacity(0.4))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 13)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                SettingsRowDivider()

                                Menu {
                                    ForEach(maxSnoozeCounts, id: \.self) { count in
                                        Button(L("alarmSettings.snooze.timesFormat", table: "Settings").replacingOccurrences(of: "{count}", with: "\(count)")) {
                                            HapticFeedbackManager.shared.trigger(.selection)
                                            maxSnoozeCount = count
                                            scheduleSettingsSave()
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "repeat")
                                            .font(.system(size: 18, weight: .regular))
                                            .foregroundColor(.purple)
                                            .frame(width: 24, height: 24)
                                        Text(L("alarmSettings.snooze.maxCount", table: "Settings"))
                                            .font(.system(.body, design: .rounded, weight: .medium))
                                            .foregroundColor(.appText)
                                        Spacer()
                                        Text(L("alarmSettings.snooze.timesFormat", table: "Settings").replacingOccurrences(of: "{count}", with: "\(maxSnoozeCount)"))
                                            .font(.system(size: 14, design: .rounded))
                                            .foregroundColor(.appTextSecondary)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.appTextSecondary.opacity(0.4))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 13)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        #if DEBUG
                        // MARK: - [DEV] Test Section
                        SettingsGroup(title: "[DEV] Alarm Test") {
                            VStack(spacing: PSSpacing.sm) {
                                if AlarmKitService.isAvailable {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("AlarmKit kullanılabilir (iOS 26+)")
                                            .font(.system(size: 13, design: .rounded))
                                            .foregroundColor(.appTextSecondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)
                                }

                                if !alarmKitAuthStatus.isEmpty {
                                    Text(alarmKitAuthStatus)
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundColor(.appTextSecondary)
                                        .padding(.horizontal, 16)
                                }

                                SettingsRowDivider()

                                Button(action: { testAlarmKit() }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "alarm.waves.left.and.right")
                                            .font(.system(size: 18)).foregroundColor(.red).frame(width: 24, height: 24)
                                        Text("[DEV] AlarmKit Test").font(.system(.body, design: .rounded, weight: .medium)).foregroundColor(.appText)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 13)
                                }.buttonStyle(.plain)

                                SettingsRowDivider()

                                Button(action: { testAlarm() }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "bell.badge")
                                            .font(.system(size: 18)).foregroundColor(.blue).frame(width: 24, height: 24)
                                        Text("[DEV] Bildirim Test").font(.system(.body, design: .rounded, weight: .medium)).foregroundColor(.appText)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 13)
                                }.buttonStyle(.plain)

                                SettingsRowDivider()

                                Button(action: { checkAlarmKitAuth() }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "shield.checkered")
                                            .font(.system(size: 18)).foregroundColor(.purple).frame(width: 24, height: 24)
                                        Text("[DEV] AlarmKit İzin Kontrol").font(.system(.body, design: .rounded, weight: .medium)).foregroundColor(.appText)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 13)
                                }.buttonStyle(.plain)

                                SettingsRowDivider()

                                Button(action: { cancelAllAlarmKitAlarms() }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 18)).foregroundColor(.orange).frame(width: 24, height: 24)
                                        Text("[DEV] Tüm AlarmKit Alarmlarını Sil").font(.system(.body, design: .rounded, weight: .medium)).foregroundColor(.appText)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 13)
                                }.buttonStyle(.plain)
                            }
                        }
                        #endif
                    } // end isEnabled
                } // end else (not loading)

                Spacer(minLength: PSSpacing.xl)
            }
            .padding(.horizontal, PSSpacing.lg)
            .padding(.top, PSSpacing.sm)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(L("alarmSettings.title", table: "Settings"))
        .navigationBarTitleDisplayMode(.large)
        .alert(L("alarmSettings.permission.alertTitle", table: "Settings"), isPresented: $showingPermissionAlert) {
            Button(L("alarmSettings.permission.alertSettings", table: "Settings")) {
                openAppSettings()
            }
            Button(L("general.cancel", table: "Settings"), role: .cancel) { }
        } message: {
            Text(L("alarmSettings.permission.alertMessage", table: "Settings"))
        }
        .alert("Test Alarmı Kuruldu", isPresented: $showingTestAlarm) {
            Button("Tamam") { }
        } message: {
            Text("Test alarmı 5 saniye sonra çalacak. Uygulamayı kapatabilir, arka plana alabilir veya açık bırakabilirsiniz.")
        }
        .alert("[DEV] AlarmKit Test", isPresented: $showingAlarmKitTest) {
            Button("Tamam") { }
        } message: {
            Text(alarmKitTestMessage)
        }
        .onAppear {
            loadDataAsync()
        }
        .onDisappear {
            // Sayfa kapatılırken ayarları kaydet
            saveTimer?.invalidate()
            Task {
                await saveSettingsToSwiftData()
            }
        }
        .environment(\.locale, Locale(identifier: languageManager.currentLanguage))
    }
    
    // MARK: - Functions
    
    // MARK: - Data Loading
    private func loadDataAsync() {
        guard isLoading else { return }
        
        Task { @MainActor in
            do {
                // Ses dosyalarını sadece bir kez yükle
                if availableSounds.isEmpty {
                    availableSounds = getAvailableAlarmSounds()
                }
                
                // SwiftData'dan async olarak veri çek
                let fetchDescriptor = FetchDescriptor<AlarmSettings>()
                let settings = try modelContext.fetch(fetchDescriptor)
                
                alarmSettings = settings
                loadCurrentSettings()
                await updateStatus()
                isLoading = false
            } catch {
                print("AlarmSettingsView: Veri yükleme hatası - \(error)")
                isLoading = false
            }
        }
    }
    
    private func getAvailableAlarmSounds() -> [(String, String)] {
        // Optimized: Sadece bir kez bundle arama yapıyoruz
        var sounds: [(String, String)] = []
        
        // Öncelikle manuel olarak bilinen sesleri ekleyelim (en hızlı yöntem)
        let knownAlarms = ["Alarm 1.caf", "Alarm 2.caf", "Alarm 3.caf", "Alarm 4.caf", "Alarm 5.caf"]
        for alarm in knownAlarms {
            // Basit bir kontrol - dosya mevcut mu?
            if Bundle.main.path(forResource: alarm.replacingOccurrences(of: ".caf", with: ""), ofType: "caf") != nil {
                let displayName = alarm.replacingOccurrences(of: ".caf", with: "")
                sounds.append((alarm, displayName))
            }
        }
        
        // Eğer manuel listede hiçbir dosya bulunamazsa bundle aramaya başvur
        if sounds.isEmpty {
            // Tek seferde tüm .caf dosyalarını al
            if let allSoundURLs = Bundle.main.urls(forResourcesWithExtension: "caf", subdirectory: nil) {
                for url in allSoundURLs {
                    let fileName = url.lastPathComponent
                    if fileName.hasPrefix("Alarm") || fileName.contains("alarm") || fileName.contains("Alarm") {
                        let displayName = fileName.replacingOccurrences(of: ".caf", with: "")
                        sounds.append((fileName, displayName))
                    }
                }
            }
        }
        
        // Alfabetik sıralama
        sounds.sort { $0.1 < $1.1 }
        
        // Güvenlik önlemi: Hiç ses dosyası bulunamazsa varsayılan ses ekle
        if sounds.isEmpty {
            sounds.append(("Alarm 1.caf", "Alarm 1"))
        }
        
        print("PolyNap: \(sounds.count) alarm sesi yüklendi")
        return sounds
    }
    
    private func updateStatus() async {
        let alarmService = AlarmService.shared
        notificationAuthStatus = await alarmService.getAuthorizationStatus()
        pendingAlarmsCount = await alarmService.getPendingNotificationsCount()
    }
    
    private func loadCurrentSettings() {
        if let settings = alarmSettings.first {
            currentSettings = settings
            
            // SwiftData'dan state değişkenlerine veri aktar
            isEnabled = settings.isEnabled
            volume = settings.volume
            vibrationEnabled = settings.vibrationEnabled
            snoozeEnabled = settings.snoozeEnabled
            snoozeDuration = settings.snoozeDurationMinutes
            maxSnoozeCount = settings.maxSnoozeCount
            
            // Seçilen ses dosyasının hala mevcut olup olmadığını kontrol et
            let availableSoundFiles = availableSounds.map { $0.0 }
            if !settings.soundName.isEmpty && availableSoundFiles.contains(settings.soundName) {
                selectedSound = settings.soundName
            } else {
                // Eğer kayıtlı ses dosyası yoksa veya boşsa varsayılan ses kullan
                selectedSound = "Alarm 1.caf"
            }
        } else {
            createDefaultSettings()
        }
    }
    
    private func createDefaultSettings() {
        // MIGRATION FİX: AlarmSettings entity'si yoksa güvenli yaklaşım
        do {
            let defaultSettings = AlarmSettings(userId: UUID())
            defaultSettings.soundName = "Alarm 1.caf" // Varsayılan ses dosyası
            defaultSettings.volume = 0.8
            defaultSettings.isEnabled = true
            defaultSettings.vibrationEnabled = true
            defaultSettings.snoozeEnabled = true
            defaultSettings.snoozeDurationMinutes = 5
            defaultSettings.maxSnoozeCount = 3
            
            modelContext.insert(defaultSettings)
            try modelContext.save()
            currentSettings = defaultSettings
            print("✅ Varsayılan AlarmSettings oluşturuldu")
            
        } catch {
            print("❌ Varsayılan alarm ayarları oluşturulamadı: \(error)")
            print("⚠️ Bu hata yeni entity migration sorunundan kaynaklanabilir")
            // Fallback: UserDefaults'tan yükle
            isEnabled = UserDefaults.standard.object(forKey: "alarm_isEnabled") as? Bool ?? true
            selectedSound = UserDefaults.standard.string(forKey: "alarm_soundName") ?? "Alarm 1.caf"
            volume = UserDefaults.standard.object(forKey: "alarm_volume") as? Double ?? 0.8
            vibrationEnabled = UserDefaults.standard.object(forKey: "alarm_vibrationEnabled") as? Bool ?? true
            snoozeEnabled = UserDefaults.standard.object(forKey: "alarm_snoozeEnabled") as? Bool ?? true
            snoozeDuration = UserDefaults.standard.object(forKey: "alarm_snoozeDuration") as? Int ?? 5
            maxSnoozeCount = UserDefaults.standard.object(forKey: "alarm_maxSnoozeCount") as? Int ?? 3
            print("✅ Varsayılan ayarlar UserDefaults'tan yüklendi")
        }
    }
    
    private func scheduleSettingsSave() {
        // Önceki timer'ı iptal et
        saveTimer?.invalidate()
        
        // 0.5 saniye sonra kaydet (debounce)
        saveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            Task {
                await saveSettingsToSwiftData()
            }
        }
    }
    
    private func saveSettingsToSwiftData() async {
        await MainActor.run {
            // MIGRATION FİX: AlarmSettings entity'si yoksa güvenli yaklaşım
            do {
                // Mevcut ayarları bul veya yeni oluştur
                let settings: AlarmSettings
                if let existingSettings = alarmSettings.first {
                    settings = existingSettings
                } else {
                    settings = AlarmSettings(userId: UUID())
                    modelContext.insert(settings)
                }
                
                // State değişkenlerini SwiftData modeline aktar
                settings.isEnabled = isEnabled
                settings.soundName = selectedSound
                settings.volume = volume
                settings.vibrationEnabled = vibrationEnabled
                settings.snoozeEnabled = snoozeEnabled
                settings.snoozeDurationMinutes = snoozeDuration
                settings.maxSnoozeCount = maxSnoozeCount
                settings.updatedAt = Date()
                
                try modelContext.save()
                currentSettings = settings
                HapticFeedbackManager.shared.trigger(.success)
                print("✅ AlarmSettings başarıyla kaydedildi")
                
            } catch {
                HapticFeedbackManager.shared.trigger(.error)
                print("❌ AlarmSettings kaydetme hatası: \(error)")
                print("⚠️ Bu hata yeni entity migration sorunundan kaynaklanabilir")
                // Fallback: UserDefaults kullan
                UserDefaults.standard.set(isEnabled, forKey: "alarm_isEnabled")
                UserDefaults.standard.set(selectedSound, forKey: "alarm_soundName")
                UserDefaults.standard.set(volume, forKey: "alarm_volume")
                UserDefaults.standard.set(vibrationEnabled, forKey: "alarm_vibrationEnabled")
                UserDefaults.standard.set(snoozeEnabled, forKey: "alarm_snoozeEnabled")
                UserDefaults.standard.set(snoozeDuration, forKey: "alarm_snoozeDuration")
                UserDefaults.standard.set(maxSnoozeCount, forKey: "alarm_maxSnoozeCount")
                print("✅ Alarm ayarları UserDefaults'a fallback olarak kaydedildi")
            }
        }
        
        // Alarmları yeniden planla (async işlem)
        let alarmService = AlarmService.shared
        await alarmService.rescheduleNotificationsForActiveSchedule(modelContext: modelContext)
    }
    
    private func saveSettingsIfNeeded() {
        scheduleSettingsSave()
    }

    private func requestNotificationPermission() async {
        let alarmService = AlarmService.shared
        await alarmService.requestAuthorization()
        await updateStatus()
    }
    
    private func testAlarm() {
        Task {
            let alarmService = AlarmService.shared
            await alarmService.scheduleTestNotification(soundName: selectedSound, volume: Float(volume))
            showingTestAlarm = true
            await updateStatus()
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - [DEV] AlarmKit Test Functions
    
    private func testAlarmKit() {
        Task {
            guard AlarmKitService.isAvailable else {
                alarmKitTestMessage = "AlarmKit kullanılamıyor. iOS 26+ gerekli.\nMevcut cihaz desteklemiyor."
                showingAlarmKitTest = true
                return
            }
            
            let authState = await AlarmKitService.shared.requestAuthorization()
            guard authState == .authorized else {
                alarmKitTestMessage = "AlarmKit izni verilmedi.\nDurum: \(authState)\nAyarlar > PolyNap > Alarmlar'dan izin verin."
                showingAlarmKitTest = true
                return
            }
            
            do {
                try await AlarmKitService.shared.scheduleTestAlarm()
                alarmKitTestMessage = "AlarmKit test alarmı 5 saniye sonra çalacak!\n\nBu alarm Do Not Disturb modunu atlayabilir ve Lock Screen'de countdown gösterebilir."
                showingAlarmKitTest = true
            } catch {
                alarmKitTestMessage = "AlarmKit test alarmı kurulamadı:\n\(error.localizedDescription)"
                showingAlarmKitTest = true
            }
        }
    }
    
    private func checkAlarmKitAuth() {
        Task {
            guard AlarmKitService.isAvailable else {
                alarmKitAuthStatus = "AlarmKit mevcut değil (iOS 26+ gerekli)"
                return
            }
            
            let authState = await AlarmKitService.shared.checkAuthorizationStatus()
            switch authState {
            case .authorized:
                alarmKitAuthStatus = "✅ AlarmKit: İzin verilmiş"
            case .denied:
                alarmKitAuthStatus = "❌ AlarmKit: İzin reddedilmiş"
            case .notDetermined:
                alarmKitAuthStatus = "⏳ AlarmKit: İzin henüz istenmemiş"
            case .unsupported:
                alarmKitAuthStatus = "⚠️ AlarmKit: Desteklenmiyor"
            }
        }
    }
    
    private func cancelAllAlarmKitAlarms() {
        Task {
            await AlarmKitService.shared.cancelAllAlarms()
            alarmKitTestMessage = "Tüm AlarmKit alarmları iptal edildi."
            showingAlarmKitTest = true
        }
    }
    
    private func previewSound(_ soundFileName: String) {
        // AlarmSound klasöründeki ses dosyasını çal
        let resourceName = soundFileName.replacingOccurrences(of: ".caf", with: "")
        
        var soundURL: URL?
        
        // Yöntem 1: AlarmSound subdirectory'sinde ara
        soundURL = Bundle.main.url(forResource: resourceName, withExtension: "caf", subdirectory: "AlarmSound")
        
        // Yöntem 2: Eğer bulunamazsa, ana bundle'da ara
        if soundURL == nil {
            soundURL = Bundle.main.url(forResource: resourceName, withExtension: "caf")
        }
        
        // Yöntem 3: Resources klasöründe ara
        if soundURL == nil {
            soundURL = Bundle.main.url(forResource: resourceName, withExtension: "caf", subdirectory: "Resources/AlarmSound")
        }
        
        guard let finalSoundURL = soundURL else {
            return
        }
        
        Task {
            do {
                let player = try AVAudioPlayer(contentsOf: finalSoundURL)
                player.volume = Float(volume)
                player.play()
                
                // 3 saniye sonra dur
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    player.stop()
                }
            } catch {
                // Ses önizlemesi oynatılamadı
            }
        }
    }
}

// MARK: - Modern Components

struct ModernInfoCard: View {
    let icon: String
    let title: String
    let message: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: PSSpacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: PSSpacing.xs) {
                Text(title)
                    .font(PSTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Text(message)
                    .font(PSTypography.caption)
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(PSSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ModernTestButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: PSSpacing.md) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text(title)
                        .font(PSTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.appText)
                    
                    Text(subtitle)
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(color.opacity(0.7))
            }
            .padding(PSSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: PSCornerRadius.medium)
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
                        RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { isPressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = isPressing
            }
        } perform: {
            action()
        }
    }
}

#Preview {
    NavigationStack {
        AlarmSettingsView()
            .environmentObject(LanguageManager.shared)
    }
} 
