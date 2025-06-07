import UserNotifications
import UIKit
import SwiftData
import AVFoundation

// Singleton service to handle notification scheduling.
class AlarmService {
    
    static let shared = AlarmService()
    private init() {}
    
    let notificationCenter = UNUserNotificationCenter.current()
    
    func requestAuthorization() {
        // Uygulama kapalıyken de çalması için tüm permission'ları iste
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge, .provisional, .timeSensitive]) { granted, error in
            if granted {
                print("PolyNap Debug: Notification permission granted - uygulama kapalıyken de çalacak")
                self.registerAlarmCategory()
                
                // iOS settings kontrolü
                self.checkNotificationSettings()
            } else if let error = error {
                print("PolyNap Debug: Notification permission error: \(error.localizedDescription)")
            } else {
                print("PolyNap Debug: Notification permission reddedildi - Ayarlar'dan açılması gerekiyor")
            }
        }
    }
    
    /// iOS notification ayarlarını kontrol et
    private func checkNotificationSettings() {
        notificationCenter.getNotificationSettings { settings in
            print("PolyNap Debug: Notification Settings:")
            print("- Authorization Status: \(settings.authorizationStatus.rawValue)")
            print("- Alert Setting: \(settings.alertSetting.rawValue)")
            print("- Sound Setting: \(settings.soundSetting.rawValue)")
            print("- Badge Setting: \(settings.badgeSetting.rawValue)")
            
            if #available(iOS 15.0, *) {
                print("- Time Sensitive Setting: \(settings.timeSensitiveSetting.rawValue)")
            }
            
            if settings.soundSetting != .enabled {
                print("⚠️ UYARI: Bildirim sesi kapalı! Ayarlar'dan açılması gerekiyor")
            }
        }
    }
    
    /// Settings'ten erteleme süresini alarak dinamik kategori oluşturur
    func updateAlarmCategoryWithSnooze(snoozeDuration: Int) {
        let snoozeAction = UNNotificationAction(identifier: "SNOOZE_ACTION", title: "\(snoozeDuration) Dakika Ertele", options: [])
        let stopAction = UNNotificationAction(identifier: "STOP_ACTION", title: "Kapat", options: [.destructive])
        
        let alarmCategory = UNNotificationCategory(identifier: "ALARM_CATEGORY",
                                                 actions: [snoozeAction, stopAction],
                                                 intentIdentifiers: [],
                                                 options: [.customDismissAction])
        
        notificationCenter.setNotificationCategories([alarmCategory])
        print("PolyNap Debug: Alarm kategorisi güncellendi - Erteleme: \(snoozeDuration) dakika")
    }
    
    private func registerAlarmCategory() {
        // Varsayılan erteleme süresi - güncel settings'ten alınacak
        let snoozeAction = UNNotificationAction(identifier: "SNOOZE_ACTION", title: "Ertele", options: [])
        let stopAction = UNNotificationAction(identifier: "STOP_ACTION", title: "Kapat", options: [.destructive])
        
        let alarmCategory = UNNotificationCategory(identifier: "ALARM_CATEGORY",
                                                 actions: [snoozeAction, stopAction],
                                                 intentIdentifiers: [],
                                                 options: [.customDismissAction])
        
        notificationCenter.setNotificationCategories([alarmCategory])
    }

    func scheduleAlarmNotification(date: Date, soundName: String = "alarm.caf", repeats: Bool, modelContext: ModelContext? = nil) {
        // Settings'ten erteleme süresini al ve kategoriyi güncelle
        if let context = modelContext {
            let request = FetchDescriptor<AlarmSettings>()
            do {
                let alarmSettingsList = try context.fetch(request)
                let snoozeDuration = alarmSettingsList.first?.snoozeDurationMinutes ?? 5
                updateAlarmCategoryWithSnooze(snoozeDuration: snoozeDuration)
            } catch {
                print("PolyNap Debug: AlarmSettings alınamadı, varsayılan kategori kullanılıyor: \(error)")
                updateAlarmCategoryWithSnooze(snoozeDuration: 5)
            }
        } else {
            updateAlarmCategoryWithSnooze(snoozeDuration: 5)
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🚨 UYANMA ALARMI!"
        content.body = "Alarm çalıyor! Uyanma zamanı geldi!"
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        // Uygulama kapalıyken de çalması için maksimum ayarlar
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive // En yüksek seviye (critical olmadan)
            content.relevanceScore = 1.0 // En yüksek önem
        }
        
        // Badge sayısını belirgin yap
        content.badge = NSNumber(value: 1)
        
        // Settings'ten seçilen alarm sesini kullan veya varsayılan
        var selectedSoundName = soundName
        if let context = modelContext {
            let request = FetchDescriptor<AlarmSettings>()
            do {
                let alarmSettingsList = try context.fetch(request)
                if let settings = alarmSettingsList.first {
                    selectedSoundName = settings.soundName
                }
            } catch {
                print("PolyNap Debug: AlarmSettings alınamadı, varsayılan ses kullanılıyor")
            }
        }
        
        // Ses dosyası ayarları - uygulama kapalıyken de çalması için
        content.sound = createNotificationSound(soundName: selectedSoundName)

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.hour, .minute, .second], from: date),
            repeats: repeats
        )
        
        // Using a unique identifier for each alarm
        let request = UNNotificationRequest(identifier: "alarm_\(date.timeIntervalSince1970)", content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("PolyNap Debug: Alarm notification eklenemedi: \(error.localizedDescription)")
            } else {
                print("PolyNap Debug: Alarm başarıyla planlandı - \(date). Repeats: \(repeats)")
            }
        }
    }
    
    /// 30 saniye boyunca çalan güçlü alarm - Sleep block sonunda kullanılır
    func schedulePersistentAlarm(date: Date, modelContext: ModelContext? = nil) {
        // Settings'ten alarm sesini al
        var selectedSoundName = "alarm.caf"
        if let context = modelContext {
            let request = FetchDescriptor<AlarmSettings>()
            do {
                let alarmSettingsList = try context.fetch(request)
                if let settings = alarmSettingsList.first {
                    selectedSoundName = settings.soundName
                    updateAlarmCategoryWithSnooze(snoozeDuration: settings.snoozeDurationMinutes)
                }
            } catch {
                print("PolyNap Debug: AlarmSettings alınamadı, varsayılan ayarlar kullanılıyor")
                updateAlarmCategoryWithSnooze(snoozeDuration: 5)
            }
        } else {
            updateAlarmCategoryWithSnooze(snoozeDuration: 5)
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🚨 UYANMA ALARMI!"
        content.body = "Uyku blok zamanınız doldu! Uyanma zamanı!"
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        // Uygulama kapalıyken de çalması için maksimum etkili ayarlar
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive // Critical olmadan en güçlü
            content.relevanceScore = 1.0 // En yüksek öncelik
        }
        
        content.badge = NSNumber(value: 1)
        
        // Uygulama kapalıyken de çalacak ses ayarları
        content.sound = createNotificationSound(soundName: selectedSoundName)
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1.0, date.timeIntervalSinceNow),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "persistent_alarm_\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("PolyNap Debug: Persistent alarm eklenemedi: \(error.localizedDescription)")
                print("PolyNap Debug: Hata detayı - notification permission kontrol edilmeli")
            } else {
                print("PolyNap Debug: 30 saniye uzunluğunda alarm başarıyla kuruldu - \(date)")
                print("PolyNap Debug: Alarm uygulama kapalıyken de çalacak")
            }
        }
    }
    
    /// Sleep block bitimi için tekli alarm sistemi - sadece bir alarm zamanlanır
    func scheduleComprehensiveAlarmForSleepBlockEnd(date: Date, modelContext: ModelContext? = nil) {
        print("PolyNap Debug: Sleep block bitimi için tekli alarm sistemi başlatılıyor")
        
        // Mevcut tüm benzer alarmları önce iptal et
        cancelDuplicateAlarms(for: date)
        
        DispatchQueue.main.async {
            let appState = UIApplication.shared.applicationState
            if appState == .active {
                // Uygulama önplanda - doğrudan UI alarm göster
                print("PolyNap Debug: Uygulama önplanda - doğrudan AlarmFiringView gösteriliyor")
                NotificationCenter.default.post(name: .startAlarm, object: nil)
            } else {
                // Uygulama arka planda veya kapalı - SADECE TEK BİR notification sistemi kullan
                print("PolyNap Debug: Uygulama arka planda/kapalı - tek notification sistemi aktif")
                
                // Immediate alarm mı yoksa scheduled alarm mı? Zamana göre karar ver
                if date.timeIntervalSinceNow <= 1.0 {
                    // Hemen çalacak alarm
                    self.scheduleImmediateAlarmNotification(modelContext: modelContext)
                } else {
                    // Zamanlanmış alarm
                    self.schedulePersistentAlarm(date: date, modelContext: modelContext)
                }
            }
        }
    }
    
    /// Anlık alarm notification'ı (immediate) - sleep block bitiminde kullanılır - TEKRARLANMAZ
    private func scheduleImmediateAlarmNotification(modelContext: ModelContext? = nil) {
        // Önce aynı türdeki immediate alarm'ları iptal et
        notificationCenter.getPendingNotificationRequests { requests in
            let immediateAlarmIds = requests.compactMap { request in
                if request.identifier.contains("immediate_alarm_") {
                    return request.identifier
                }
                return nil
            }
            
            if !immediateAlarmIds.isEmpty {
                self.notificationCenter.removePendingNotificationRequests(withIdentifiers: immediateAlarmIds)
                print("PolyNap Debug: \(immediateAlarmIds.count) immediate alarm iptal edildi (duplicate engellendi)")
            }
        }
        
        var selectedSoundName = "alarm.caf"
        if let context = modelContext {
            let request = FetchDescriptor<AlarmSettings>()
            do {
                let alarmSettingsList = try context.fetch(request)
                if let settings = alarmSettingsList.first {
                    selectedSoundName = settings.soundName
                }
            } catch {
                print("PolyNap Debug: AlarmSettings alınamadı, varsayılan ses kullanılıyor")
            }
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🚨 UYKU BLOĞU BİTTİ!"
        content.body = "Şu anda uyanmalısınız! Alarm çalıyor!"
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        // Maksimum etkililik ayarları
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
            content.relevanceScore = 1.0
        }
        
        content.badge = NSNumber(value: 1)
        content.sound = createNotificationSound(soundName: selectedSoundName)
        
        // Hemen tetiklenir (0.1 saniye gecikme)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        // Unique identifier - sadece bir tane immediate alarm olacak
        let request = UNNotificationRequest(
            identifier: "immediate_alarm_single",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("PolyNap Debug: Immediate alarm eklenemedi: \(error)")
            } else {
                print("PolyNap Debug: Tek immediate alarm başarıyla planlandı")
            }
        }
    }
    
    /// Uygulama kapalıyken de çalacak notification sound oluşturur
    private func createNotificationSound(soundName: String) -> UNNotificationSound {
        // Ses dosyası adını temizle
        let cleanSoundName = soundName.replacingOccurrences(of: ".caf", with: "")
        
        // Bundle'da ses dosyası var mı kontrol et
        if let soundURL = Bundle.main.url(forResource: cleanSoundName, withExtension: "caf") {
            // Ses dosyası süresi kontrol et
            do {
                let audioFile = try AVAudioFile(forReading: soundURL)
                let duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate
                
                if duration <= 30.0 { // Apple'ın 30 saniye kuralı
                    print("PolyNap Debug: Özel alarm sesi kullanılıyor: \(cleanSoundName).caf (\(duration)s)")
                    return UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(cleanSoundName).caf"))
                } else {
                    print("PolyNap Debug: Ses dosyası 30 saniyeden uzun (\(duration)s), varsayılan kullanılacak")
                }
            } catch {
                print("PolyNap Debug: Ses dosyası kontrol edilemedi: \(error)")
            }
        } else {
            print("PolyNap Debug: Ses dosyası bulunamadı: \(cleanSoundName).caf")
        }
        
        // Fallback: Sistem varsayılan alarm sesi (uygulama kapalıyken de çalar)
        print("PolyNap Debug: Varsayılan sistem alarm sesi kullanılıyor")
        return UNNotificationSound.default
    }
    
    func cancelPendingAlarms() {
        notificationCenter.removeAllPendingNotificationRequests()
        // Badge'i temizle
        UIApplication.shared.applicationIconBadgeNumber = 0
        print("PolyNap Debug: Tüm bekleyen alarmlar iptal edildi, badge temizlendi")
    }
    
    /// Belirli bir alarm serisini iptal et (persistent alarms için)
    func cancelPersistentAlarms(for date: Date) {
        let identifier = "persistent_alarm_\(date.timeIntervalSince1970)"
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("PolyNap Debug: Persistent alarm iptal edildi - \(identifier)")
    }
    
    /// Aynı zamana sahip duplicate alarmları iptal eder
    private func cancelDuplicateAlarms(for date: Date) {
        let dateTimeInterval = date.timeIntervalSince1970
        
        notificationCenter.getPendingNotificationRequests { requests in
            let duplicateIdentifiers = requests.compactMap { request -> String? in
                let identifier = request.identifier
                // Aynı zaman için farklı türdeki alarmları bul
                if identifier.contains("persistent_alarm_\(dateTimeInterval)") ||
                   identifier.contains("immediate_alarm_") ||
                   identifier.contains("alarm_\(dateTimeInterval)") {
                    return identifier
                }
                return nil
            }
            
            if !duplicateIdentifiers.isEmpty {
                self.notificationCenter.removePendingNotificationRequests(withIdentifiers: duplicateIdentifiers)
                print("PolyNap Debug: \(duplicateIdentifiers.count) duplicate alarm iptal edildi")
            }
        }
    }
    
    /// Test amaçlı hızlı alarm kurma (5 saniye sonra) - Tek güçlü bildirim
    func scheduleTestAlarm(modelContext: ModelContext? = nil) {
        let testDate = Date().addingTimeInterval(5) // 5 saniye sonra
        scheduleAlarmNotification(date: testDate, repeats: false, modelContext: modelContext)
        print("PolyNap Debug: Test alarmı 5 saniye sonra çalacak (uygulama kapalıyken de)")
    }
    
    /// Test amaçlı 30 saniye persistent alarm 
    func scheduleTestPersistentAlarm(modelContext: ModelContext? = nil) {
        let testDate = Date().addingTimeInterval(5) // 5 saniye sonra başlayacak
        schedulePersistentAlarm(date: testDate, modelContext: modelContext)
        print("PolyNap Debug: 30 saniye test alarm 5 saniye sonra başlayacak (uygulama kapalıyken de)")
    }
    
    /// Test için tekli alarm sistemi - Sleep block bitimi simülasyonu
    func scheduleTestComprehensiveAlarm(modelContext: ModelContext? = nil) {
        let testDate = Date().addingTimeInterval(5) // 5 saniye sonra
        scheduleComprehensiveAlarmForSleepBlockEnd(date: testDate, modelContext: modelContext)
        print("PolyNap Debug: Test tekli alarm sistemi 5 saniye sonra başlayacak - SADECE BİR ALARM çalacak")
    }
    
    /// Debug: Bekleyen notification'ları listele
    func debugPendingNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            print("PolyNap Debug: Bekleyen notification sayısı: \(requests.count)")
            for request in requests {
                print("- ID: \(request.identifier)")
                print("  Başlık: \(request.content.title)")
                print("  Trigger: \(request.trigger?.description ?? "Yok")")
            }
        }
    }
    
    /// iOS settings'e yönlendirme ve kullanıcı rehberliği için helper fonksiyonlar ekliyorum
    func openNotificationSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
            print("PolyNap Debug: iOS Ayarlar'a yönlendiriliyor")
        }
    }
    
    /// Kullanıcıya bildirim ayarları rehberi göster
    func showNotificationGuide() -> String {
        var guide = "🔔 Uygulama Kapalıyken Alarm Çalması İçin:\n\n"
        guide += "2️⃣ Bildirimler'e tıklayın\n"
        guide += "3️⃣ 'Bildirimlere İzin Ver'i açın\n"
        guide += "4️⃣ 'Sesler'i açın\n"
        guide += "5️⃣ 'Kilitleme Ekranında'yı açın\n"
        guide += "6️⃣ 'Bildirim Merkezi'ni açın\n"
        guide += "7️⃣ 'Afiş'leri açın\n\n"
        guide += "⚠️ Bu ayarlar açık olmadan alarm sadece uygulama açıkken çalar!"
        
        return guide
    }
} 
