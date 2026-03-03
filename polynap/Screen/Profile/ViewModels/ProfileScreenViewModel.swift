import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class ProfileScreenViewModel: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var totalSleepSessions: Int = 0
    @Published var successRate: Double = 0.0
    @Published var adaptationPhase: Int = 0
    @Published var activeScheduleName: String = ""
    @Published var totalSleepHours: Double = 0.0
    @Published var selectedCoreEmoji: String = "🌙"
    @Published var selectedNapEmoji: String = "💤"
    @Published var activeSchedule: UserSchedule? = nil
    @Published var adaptationDuration: Int = 21 // Varsayılan 21 gün
    
    // Undo özellikleri
    @Published var showingUndoScheduleChange: Bool = false
    @Published var undoDismissedByUser: Bool = false
    
    private let languageManager: LanguageManager

    // Yeni eklenen hesaplanmış özellik
    var adaptationPhaseDescription: String {
        switch adaptationPhase {
        case 0:
            return L("profile.adaptation.phase.day1", table: "Profile") // "1. Gün - Başlangıç"
        case 1:
            return L("profile.adaptation.phase.initial", table: "Profile") // "İlk Adaptasyon (2-7. günler)"
        case 2:
            return L("profile.adaptation.phase.middle", table: "Profile") // "Orta Adaptasyon (8-14. günler)"
        case 3:
            return L("profile.adaptation.phase.advanced", table: "Profile") // "İlerlemiş Adaptasyon (15-21. günler)"
        case 4:
            return L("profile.adaptation.phase.final", table: "Profile") // "Son Adaptasyon (22-28. günler)"
        case 5...:
            return L("profile.adaptation.phase.complete", table: "Profile") // "Adaptasyon Tamamlandı"
        default:
            return L("profile.adaptation.phase.unknown", table: "Profile")
        }
    }
    
    // Mevcut adaptasyon gün sayısını hesaplayan yardımcı metod
    private func currentAdaptationDay() -> Int {
        guard let schedule = activeSchedule else { return 0 }
        
        let calendar = Calendar.current
        let startDate = schedule.adaptationStartDate ?? schedule.createdAt
        let currentDate = Date()
        
        let startOfStartDate = calendar.startOfDay(for: startDate)
        let startOfCurrentDate = calendar.startOfDay(for: currentDate)
        
        let components = calendar.dateComponents([.day], from: startOfStartDate, to: startOfCurrentDate)
        let daysPassed = components.day ?? 0
        
        return daysPassed + 1
    }
    
    // Adaptasyon tamamlandı mı kontrol et
    var isAdaptationCompleted: Bool {
        return currentAdaptationDay() >= adaptationDuration
    }
    
    // Tamamlanan gün sayısı
    var completedAdaptationDays: Int {
        return currentAdaptationDay()
    }

    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext? = nil, languageManager: LanguageManager = LanguageManager.shared) {
        self.languageManager = languageManager
        self.modelContext = modelContext
        
        // UserDefaults'tan undo dismiss durumunu yükle
        self.undoDismissedByUser = UserDefaults.standard.bool(forKey: "undoDismissedByUser")
        
        if modelContext != nil {
            loadData()
        }
        loadEmojiPreferences()
        
        // ScheduleManager'ı observe et
        ScheduleManager.shared.$activeSchedule
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    await self.loadActiveSchedule()
                }
            }
            .store(in: &cancellables)
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadData()
        
        // ScheduleManager'ı yeniden yükle
        Task {
            await ScheduleManager.shared.loadActiveScheduleFromRepository()
        }
    }
    
    func loadData() {
        guard let context = modelContext else { 
            print("ProfileScreenViewModel: ModelContext yüklenemedi, loadData iptal edildi.")
            return
        }
        
        do {
            let descriptor = FetchDescriptor<HistoryModel>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            let historyItems = try context.fetch(descriptor)
            calculateStreak(from: historyItems)
        } catch {
            print("Profildeki streak verileri yüklenirken hata: \(error)")
        }
        
        // Undo data durumunu kontrol et
        objectWillChange.send()
        
        Task {
            await loadActiveSchedule()
        }
    }
    
    private func resetScheduleUI() {
        self.activeScheduleName = ""
        self.adaptationPhase = 0
        self.totalSleepHours = 0
        self.activeSchedule = nil
        self.adaptationDuration = 21
        UserDefaults.standard.set(false, forKey: "cachedHasSchedule")
    }

    // Aktif uyku programını ve adaptasyon aşamasını yükle
    private func loadActiveSchedule() async {
        guard let context = modelContext else {
            print("ProfileScreenViewModel: ModelContext bulunamadı, aktif program yüklenemiyor.")
            await MainActor.run { resetScheduleUI() }
            return
        }

        print("ProfileScreenViewModel: loadActiveSchedule başlıyor...")
        
        // ScheduleManager'dan aktif programı al (UserScheduleModel tipinde)
        if let activeScheduleModel = ScheduleManager.shared.activeSchedule {
            print("ProfileScreenViewModel: ✅ ScheduleManager'dan aktif program bulundu: \(activeScheduleModel.name) (ID: \(activeScheduleModel.id))")
            
            // UserScheduleModel'den UserSchedule entity'sini bul
            await loadActiveScheduleFromModel(activeScheduleModel, context: context)
        } else {
            // Eğer ScheduleManager'da yoksa, doğrudan Repository'den yükle
            print("ProfileScreenViewModel: ❌ ScheduleManager'da aktif program YOK! Repository'den yükleniyor...")
            await loadActiveScheduleFromRepository(context)
        }
    }
    
    private func loadActiveScheduleFromModel(_ scheduleModel: UserScheduleModel, context: ModelContext) async {
        guard let scheduleUUID = UUID(uuidString: scheduleModel.id) else {
            print("ProfileScreenViewModel: Geçersiz schedule ID: \(scheduleModel.id)")
            await MainActor.run { resetScheduleUI() }
            return
        }
        
        do {
            // UserSchedule entity'sini ID ile bul
            let predicate = #Predicate<UserSchedule> { $0.id == scheduleUUID }
            let descriptor = FetchDescriptor(predicate: predicate)
            
            if let scheduleEntity = try context.fetch(descriptor).first {
                await MainActor.run {
                    print("ProfileScreenViewModel: UserSchedule entity bulundu ve UI güncelleniyor: \(scheduleEntity.name)")
                    updateUIWithSchedule(scheduleEntity)
                }
            } else {
                print("ProfileScreenViewModel: UserSchedule entity bulunamadı, Repository'den yeniden yükleniyor...")
                await loadActiveScheduleFromRepository(context)
            }
        } catch {
            print("ProfileScreenViewModel: UserSchedule entity yüklenirken hata: \(error)")
            await loadActiveScheduleFromRepository(context)
        }
    }
    
    private func loadActiveScheduleFromRepository(_ context: ModelContext) async {
        guard let currentUserIdString = AuthManager.shared.currentUser?.id,
              let currentUserId = UUID(uuidString: currentUserIdString) else {
            print("ProfileScreenViewModel: Geçerli kullanıcı ID'si bulunamadı.")
            await MainActor.run { resetScheduleUI() }
            return
        }
        
        do {
            // Repository üzerinden aktif programı çek
            let activeScheduleEntity = try Repository.shared.getActiveUserSchedule(userId: currentUserId, context: context)

            await MainActor.run {
                if let scheduleData = activeScheduleEntity {
                    print("ProfileScreenViewModel: Repository'den aktif program bulundu: \(scheduleData.name)")
                    updateUIWithSchedule(scheduleData)
                } else {
                    print("ProfileScreenViewModel: Repository'de aktif program bulunamadı.")
                    self.resetScheduleUI()
                }
            }
        } catch {
            print("ProfileScreenViewModel: Repository'den aktif program yüklenirken hata: \(error)")
            await MainActor.run { self.resetScheduleUI() }
        }
    }
    
    private func updateUIWithSchedule(_ scheduleData: UserSchedule) {
        self.activeSchedule = scheduleData
        self.activeScheduleName = scheduleData.name
        
        let scheduleNameLowercased = scheduleData.name.lowercased()
        if scheduleNameLowercased.contains("uberman") || 
           scheduleNameLowercased.contains("dymaxion") ||
           (scheduleNameLowercased.contains("everyman") && scheduleNameLowercased.contains("1")) {
            self.adaptationDuration = 28
        } else {
            self.adaptationDuration = 21
        }
        
        let calculatedPhase = self.calculateAdaptationPhase(schedule: scheduleData)
        self.adaptationPhase = calculatedPhase
        
        // Eğer hesaplanan faz, veritabanındaki fazdan farklıysa güncelle
        if calculatedPhase != scheduleData.adaptationPhase {
            print("ProfileScreenViewModel: Adaptasyon fazı güncelleniyor. Eski: \(String(describing: scheduleData.adaptationPhase)), Yeni: \(calculatedPhase)")
            
            Task {
                do {
                    // Repository üzerinden güncelle
                    try Repository.shared.updateUserScheduleAdaptationPhase(
                        scheduleId: scheduleData.id,
                        newPhase: calculatedPhase,
                        context: modelContext!
                    )
                    print("ProfileScreenViewModel: Adaptasyon aşaması Repository üzerinden güncellendi.")
                    
                    // Local schedule objesini de güncelle
                    scheduleData.adaptationPhase = calculatedPhase
                    
                } catch {
                    print("ProfileScreenViewModel: Adaptasyon aşaması güncellenirken hata: \(error)")
                }
            }
        }
        self.totalSleepHours = scheduleData.totalSleepHours ?? 0.0

        // Cache adaptation data for badge evaluation across view models
        UserDefaults.standard.set(true, forKey: "cachedHasSchedule")
        UserDefaults.standard.set(self.adaptationPhase, forKey: "cachedAdaptationPhase")
        UserDefaults.standard.set(self.completedAdaptationDays, forKey: "cachedAdaptationDay")
        UserDefaults.standard.set(self.adaptationDuration, forKey: "cachedAdaptationDuration")
        UserDefaults.standard.set(self.isAdaptationCompleted, forKey: "cachedIsAdaptationComplete")

        evaluateBadges()
    }
    
    private func calculateAdaptationPhase(schedule: UserSchedule) -> Int {
        let currentDate = Date()
        let startDate = schedule.adaptationStartDate ?? schedule.createdAt
        
        let calendar = Calendar.current
        
        // İki tarih arasındaki tam gün farkını hesapla
        let startOfStartDate = calendar.startOfDay(for: startDate)
        let startOfCurrentDate = calendar.startOfDay(for: currentDate)
        
        let components = calendar.dateComponents([.day], from: startOfStartDate, to: startOfCurrentDate)
        let daysPassed = components.day ?? 0
        
        // 1. gün = adaptasyon başladığı gün (daysPassed = 0)
        // 2. gün = bir sonraki gün (daysPassed = 1)
        // vs.
        let currentDay = daysPassed + 1
        
        print("ProfileScreenViewModel: Adaptasyon hesaplama - Başlangıç: \(startDate), Şu an: \(currentDate), Geçen günler: \(daysPassed), Mevcut gün: \(currentDay)")
        
        let totalDuration = self.adaptationDuration
        let phase: Int
        
        if totalDuration == 28 {
            // 28 günlük programlar için (Uberman, Dymaxion, Everyman 1)
            switch currentDay {
            case 1:
                phase = 0  // İlk gün - Başlangıç
            case 2...7:
                phase = 1  // 2-7. günler - İlk Adaptasyon
            case 8...14:
                phase = 2  // 8-14. günler - Orta Adaptasyon
            case 15...21:
                phase = 3  // 15-21. günler - İlerlemiş Adaptasyon
            case 22...28:
                phase = 4  // 22-28. günler - İleri Adaptasyon
            default:
                phase = 5  // 28+ günler - Tamamlanmış
            }
        } else {
            // 21 günlük programlar için (diğer programlar)
            switch currentDay {
            case 1:
                phase = 0  // İlk gün - Başlangıç
            case 2...7:
                phase = 1  // 2-7. günler - İlk Adaptasyon
            case 8...14:
                phase = 2  // 8-14. günler - Orta Adaptasyon
            case 15...21:
                phase = 3  // 15-21. günler - İlerlemiş Adaptasyon
            default:
                phase = 4  // 21+ günler - Tamamlanmış
            }
        }
        
        print("ProfileScreenViewModel: Hesaplanan faz: \(phase)")
        return phase
    }

    private func calculateStreak(from history: [HistoryModel]) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // Build a set of calendar days that have at least one sleep entry with actual duration.
        // Schedule changes are irrelevant — streak is purely history-driven.
        let daysWithSleep: Set<Date> = Set(
            history.compactMap { model -> Date? in
                guard let entries = model.sleepEntries,
                      entries.contains(where: { $0.duration > 0 }) else { return nil }
                return cal.startOfDay(for: model.date)
            }
        )

        guard !daysWithSleep.isEmpty else {
            let prev = UserDefaults.standard.integer(forKey: "currentStreak")
            if prev > 0 { BadgeManager.shared.recordStreakBroken() }
            UserDefaults.standard.set(0, forKey: "currentStreak")
            currentStreak = 0
            longestStreak = UserDefaults.standard.integer(forKey: "longestStreak")
            return
        }

        // Current streak: count consecutive days backward from today.
        // If today has no entry yet, yesterday still keeps the streak alive.
        let yesterday = cal.startOfDay(for: cal.date(byAdding: .day, value: -1, to: today)!)
        let startDay: Date? = daysWithSleep.contains(today) ? today
                            : daysWithSleep.contains(yesterday) ? yesterday
                            : nil

        var current = 0
        if let start = startDay {
            var checkDay = start
            while daysWithSleep.contains(checkDay) {
                current += 1
                checkDay = cal.startOfDay(for: cal.date(byAdding: .day, value: -1, to: checkDay)!)
            }
        }

        // Longest streak: scan all days in ascending order and find the longest consecutive run.
        let sortedDays = daysWithSleep.sorted()
        var longest = 0
        var run = 0
        var prevDay: Date? = nil
        for day in sortedDays {
            if let prev = prevDay,
               day == cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: prev)!) {
                run += 1
            } else {
                run = 1
            }
            if run > longest { longest = run }
            prevDay = day
        }
        longest = max(longest, current)

        // Badge: detect when a previously active streak is now broken
        let previousStreakValue = UserDefaults.standard.integer(forKey: "currentStreak")
        if previousStreakValue > 0 && current == 0 {
            BadgeManager.shared.recordStreakBroken()
        }

        // Persist
        UserDefaults.standard.set(current, forKey: "currentStreak")
        self.currentStreak = current

        let storedLongest = UserDefaults.standard.integer(forKey: "longestStreak")
        let newLongest = max(longest, storedLongest)
        UserDefaults.standard.set(newLongest, forKey: "longestStreak")
        self.longestStreak = newLongest
    }
    
    // MARK: - Emoji Tercihleri
    
    // Emoji kaydetme fonksiyonu - ProfileScreenView içinde kullanılıyor
    func saveEmojiPreference(coreEmoji: String? = nil, napEmoji: String? = nil) {
        if let core = coreEmoji {
            self.selectedCoreEmoji = core
        }
        if let nap = napEmoji {
            self.selectedNapEmoji = nap
        }
        
        // Tercihleri UserDefaults'a kaydet
        saveEmojiPreferences()
        
        // Emoji değişikliklerini broadcast et
        NotificationCenter.default.post(
            name: NSNotification.Name("EmojiPreferencesChanged"),
            object: nil,
            userInfo: [
                "selectedCoreEmoji": selectedCoreEmoji,
                "selectedNapEmoji": selectedNapEmoji
            ]
        )
        
        print("Emoji tercihleri kaydedildi. Core: \(selectedCoreEmoji), Nap: \(selectedNapEmoji)")
    }
    
    // UserDefaults'a emoji tercihlerini kaydet
    private func saveEmojiPreferences() {
        UserDefaults.standard.set(selectedCoreEmoji, forKey: "selectedCoreEmoji")
        UserDefaults.standard.set(selectedNapEmoji, forKey: "selectedNapEmoji")
    }

    private func loadEmojiPreferences() {
        if let coreEmoji = UserDefaults.standard.string(forKey: "selectedCoreEmoji") {
            selectedCoreEmoji = coreEmoji
        }
        if let napEmoji = UserDefaults.standard.string(forKey: "selectedNapEmoji") {
            selectedNapEmoji = napEmoji
        }
    }
    
    // MARK: - Adaptasyon Fazı Yönetimi
    
    // Adaptasyon fazını sıfırlama fonksiyonu - ProfileScreenView içinde kullanılıyor
    func resetAdaptationPhase() async throws {
        guard let context = modelContext, 
              let currentScheduleId = activeSchedule?.id else { // scheduleId'yi aktif programdan al
            throw ProfileError.noActiveSchedule
        }
        
        do {
            // UserSchedule'ı ID ile çek
            let predicate = #Predicate<UserSchedule> { $0.id == currentScheduleId }
            var fetchDescriptor = FetchDescriptor(predicate: predicate)
            fetchDescriptor.fetchLimit = 1
            
            guard let scheduleToUpdate = try context.fetch(fetchDescriptor).first else {
                print("ProfileScreenViewModel: Güncellenecek program SwiftData'da bulunamadı.")
                throw ProfileError.scheduleUpdateFailed
            }

            // Adaptasyonu bugünden başlat (1. gün)
            scheduleToUpdate.adaptationPhase = 0  // İlk faz (1. gün)
            scheduleToUpdate.adaptationStartDate = Date()   // Şu anki zaman - adaptasyon bugün başlıyor
            
            try context.save()
            
            // UI'ı güncelle
            await MainActor.run {
                self.adaptationPhase = 0  // UI'da da ilk fazdan başlat
                self.activeSchedule = scheduleToUpdate // Güncellenmiş schedule'ı ata
            }
            
            print("Adaptasyon fazı başarıyla sıfırlandı - Bugünden (1. gün) başlatıldı.")
            
        } catch {
            print("Adaptasyon fazı sıfırlanırken SwiftData hatası: \(error.localizedDescription)")
            throw ProfileError.saveFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Undo Metodları
    
    /// Schedule değişimini geri al
    func undoScheduleChange() async throws {
        do {
            try await Repository.shared.undoScheduleChange()
            await loadActiveSchedule()
            // Streak'i yeniden yükle
            if let context = modelContext {
                let descriptor = FetchDescriptor<HistoryModel>(sortBy: [SortDescriptor(\.date, order: .reverse)])
                let historyItems = try context.fetch(descriptor)
                calculateStreak(from: historyItems)
            }
        } catch {
            throw error
        }
    }
    
    /// Undo verisi mevcut mu kontrol et (kullanıcı ertelememiş ise)
    func hasUndoData() -> Bool {
        return Repository.shared.hasUndoData() && !undoDismissedByUser
    }
    
    /// Kullanıcı undo'yu ertelediğinde çağrılır
    func dismissUndoForLater() {
        undoDismissedByUser = true
        UserDefaults.standard.set(true, forKey: "undoDismissedByUser")
    }
    
    /// Undo dismiss durumunu sıfırla (ayarlardan çağrılır)
    func resetUndoDismissStatus() {
        undoDismissedByUser = false
        UserDefaults.standard.set(false, forKey: "undoDismissedByUser")
    }
    
    /// Raw undo verisi mevcut mu (ayarlar için)
    func hasRawUndoData() -> Bool {
        return Repository.shared.hasUndoData()
    }

    // MARK: - Badge Evaluation

    func evaluateBadges() {
        let context = BadgeManager.EvaluationContext(
            hasSchedule: activeSchedule != nil,
            longestStreak: longestStreak,
            currentStreak: currentStreak,
            adaptationPhase: adaptationPhase,
            currentAdaptationDay: completedAdaptationDays,
            adaptationDuration: adaptationDuration,
            isAdaptationComplete: isAdaptationCompleted,
            isPremium: RevenueCatManager.shared.userState == .premium
        )
        BadgeManager.shared.evaluateBadges(context: context)
    }

}

// MARK: - Hata Tipleri
enum ProfileError: Error, LocalizedError {
    case noActiveSchedule
    case saveFailed(String)
    case scheduleUpdateFailed
    
    var errorDescription: String? {
        switch self {
        case .noActiveSchedule:
            return "Sıfırlanacak aktif bir uyku programı bulunamadı."
        case .saveFailed(let reason):
            return "Kaydetme başarısız: \(reason)"
        case .scheduleUpdateFailed:
            return "Program güncellenemedi."
        }
    }
}

// Eğer UserSchedule.scheduleDescription (eski JSONB) kullanılacaksa
// ve bu bir LocalizedDescription struct'ına decode edilecekse,
// bu struct'ın Codable olması gerekir.
// struct LocalizedDescription: Codable {
// var en: String
// var tr: String
// }
