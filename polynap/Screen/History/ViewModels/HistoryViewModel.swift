import Foundation
import SwiftUI
import SwiftData
import Combine
import HealthKit

enum TimeFilter: String, CaseIterable {
    case allTime = "history.filter.allTime"
    case thisMonth = "history.filter.thisMonth"
    case thisWeek = "history.filter.thisWeek"
    case today = "history.filter.today"
    case specificDate = "history.filter.specificDate"
    
    var localizedTitle: String {
        return L(self.rawValue, table: "History")
    }
}

// New filter types
enum SleepTypeFilter: String, CaseIterable {
    case all = "history.filter.allTypes"
    case core = "history.filter.coreOnly"
    case nap = "history.filter.napOnly"
    
    var localizedTitle: String {
        return L(self.rawValue, table: "Localizable")
    }
}

enum RatingFilter: String, CaseIterable {
    case all = "history.filter.allRatings"
    case zeroOne = "history.filter.rating01"
    case oneTwo = "history.filter.rating12"
    case twoThree = "history.filter.rating23"
    case threeFour = "history.filter.rating34"
    case fourFive = "history.filter.rating45"
    case unrated = "history.filter.unrated"
    
    var localizedTitle: String {
        return L(self.rawValue, table: "Localizable")
    }
}

enum SourceFilter: String, CaseIterable {
    case all = "history.filter.allSources"
    case manual = "history.filter.manualOnly"
    case health = "history.filter.healthOnly"
    
    var localizedTitle: String {
        return L(self.rawValue, table: "Localizable")
    }
}

enum AdjustmentFilter: String, CaseIterable {
    case all = "history.filter.allAdjustments"
    case asScheduled = "history.filter.asScheduledOnly"
    case differentTime = "history.filter.differentTimeOnly"
    case custom = "history.filter.customOnly"
    case skipped = "history.filter.skippedOnly"
    
    var localizedTitle: String {
        return L(self.rawValue, table: "Localizable")
    }
}

enum SyncStatus {
    case synced
    case pendingSync
    case offline
    case error(String)
}

@MainActor
class HistoryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var historyItems: [HistoryModel] = []
    @Published var selectedFilter: TimeFilter = .allTime
    @Published var selectedSpecificDate: Date = Date()
    @Published var selectedSleepTypeFilter: SleepTypeFilter = .all
    @Published var selectedRatingFilter: RatingFilter = .all
    @Published var selectedSourceFilter: SourceFilter = .all
    @Published var selectedAdjustmentFilter: AdjustmentFilter = .all
    @Published var isFilterMenuPresented = false
    @Published var selectedDay: Date?
    @Published var isDayDetailPresented = false
    @Published var isAddSleepEntryPresented = false
    @Published var isSyncing = false
    @Published var syncError: String?
    @Published var syncStatus: SyncStatus = .synced
    @Published var healthKitData: [HealthKitSleepSample] = []
    @Published var isHealthKitDataLoaded = false
    @Published var filteredHealthKitData: [HealthKitSleepSample] = []
    
    // MARK: - Private Properties
    var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    private var hasInitialLoadCompleted = false
    
    // MARK: - Initialization
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        if modelContext != nil {
            loadHistoryItems()
        }
    }
    
    // MARK: - Public Methods
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadHistoryItems()
        
        // HealthKit verilerini her zaman yükle (initial load'da)
        Task {
            await loadHealthKitData()
            await MainActor.run {
                hasInitialLoadCompleted = true
            }
        }
    }
    
    func setFilter(_ filter: TimeFilter) {
        selectedFilter = filter
        if filter != .specificDate {
            applyFilters()
        }
    }
    
    func setSleepTypeFilter(_ filter: SleepTypeFilter) {
        selectedSleepTypeFilter = filter
        applyFilters()
    }
    
    func setRatingFilter(_ filter: RatingFilter) {
        selectedRatingFilter = filter
        applyFilters()
    }
    
    func setSourceFilter(_ filter: SourceFilter) {
        selectedSourceFilter = filter
        applyFilters()
    }
    
    func setAdjustmentFilter(_ filter: AdjustmentFilter) {
        selectedAdjustmentFilter = filter
        applyFilters()
    }
    
    func setSpecificDate(_ date: Date) {
        selectedSpecificDate = date
        if selectedFilter == .specificDate {
            applyFilters()
        }
    }
    
    func resetAllFilters() {
        selectedFilter = .allTime
        selectedSleepTypeFilter = .all
        selectedRatingFilter = .all
        selectedSourceFilter = .all
        selectedAdjustmentFilter = .all
        applyFilters()
    }
    
    func selectDateForDetail(_ date: Date) {
        selectedDay = date
        isDayDetailPresented = true
    }
    
    func getHistoryItem(for date: Date) -> HistoryModel? {
        let calendar = Calendar.current
        return historyItems.first { item in
            calendar.isDate(item.date, inSameDayAs: date)
        }
    }
    
    func addSleepEntry(_ newSleepEntry: SleepEntry) {
        guard let modelContext = modelContext else {
            handleError("ModelContext not available")
            return
        }
        
        do {
            let historyModel = try getOrCreateHistoryModel(for: newSleepEntry.date)
            
            // Entry'yi history model'e bağla
            newSleepEntry.historyDay = historyModel
            historyModel.sleepEntries?.append(newSleepEntry)
            
            // Context'e ekle ve kaydet
            modelContext.insert(newSleepEntry)
            try modelContext.save()
            
            // Manuel veri eklendiğinde çakışan HealthKit verileri otomatik filtrelenir (view level'da yapılıyor)
            loadHistoryItems()
            print("SleepEntry başarıyla eklendi: \(newSleepEntry.id)")

            // Badge evaluation after new sleep entry
            evaluateBadgesAfterSleepLog()
            
        } catch {
            handleError("Failed to add sleep entry: \(error.localizedDescription)")
        }
    }
    
    func deleteSleepEntry(_ entry: SleepEntry) {
        guard let modelContext = modelContext else {
            handleError("ModelContext not available")
            return
        }
        
        let historyDay = entry.historyDay
        
        Task { @MainActor in
            do {
                // Entry'yi sil
                modelContext.delete(entry)
                
                // Eğer HistoryModel boş kaldıysa onu da sil
                if let historyDay = historyDay,
                   let sleepEntries = historyDay.sleepEntries,
                   sleepEntries.count <= 1 { // <= 1 çünkü henüz silinmemiş
                    modelContext.delete(historyDay)
                    print("Boş HistoryModel silindi: \(historyDay.date)")
                }
                
                try modelContext.save()
                
                // UI'ı güncelle
                await refreshData()
                
                print("SleepEntry başarıyla silindi: \(entry.id)")
                
            } catch {
                handleError("Failed to delete sleep entry: \(error.localizedDescription)")
            }
        }
    }
    
    func updateSleepEntry(_ entry: SleepEntry) {
        guard let modelContext = modelContext else {
            handleError("ModelContext not available")
            return
        }
        
        do {
            entry.updatedAt = Date()
            try modelContext.save()
            loadHistoryItems()
            print("SleepEntry başarıyla güncellendi: \(entry.id)")
            
        } catch {
            handleError("Failed to update sleep entry: \(error.localizedDescription)")
        }
    }
    
    func deleteHistoryDay(_ historyModel: HistoryModel) {
        guard let modelContext = modelContext else {
            handleError("ModelContext not available")
            return
        }
        
        do {
            // İlişkili tüm sleep entry'leri de silinecek (cascade delete)
            modelContext.delete(historyModel)
            try modelContext.save()
            loadHistoryItems()
            print("HistoryModel ve ilişkili entry'ler silindi: \(historyModel.date)")
            
        } catch {
            handleError("Failed to delete history day: \(error.localizedDescription)")
        }
    }
    
    func reloadData() {
        // State'leri temizle
        isAddSleepEntryPresented = false
        isDayDetailPresented = false
        selectedDay = nil
        
        // Data'yı yeniden yükle
        loadHistoryItems()
        
        // HealthKit verilerini yükle
        Task {
            await loadHealthKitData()
        }
        
        // UI'ı güncelle
        objectWillChange.send()
    }
    
    func syncData() {
        isSyncing = true
        syncError = nil
        print("SyncData çağrıldı (offline modda işlem yok).")
        
        // Simulated sync delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isSyncing = false
            self?.syncStatus = .synced
        }
    }
    
    // MARK: - Private Methods
    private func loadHistoryItems() {
        guard let modelContext = modelContext else {
            self.historyItems = []
            handleError("ModelContext not available")
            return
        }
        
        do {
            let predicate = createTimeFilterPredicate()
            let descriptor = FetchDescriptor<HistoryModel>(
                predicate: predicate,
                sortBy: [SortDescriptor(\HistoryModel.date, order: .reverse)]
            )
            
            let allHistoryItems = try modelContext.fetch(descriptor)
            
            // Sadece en az bir SleepEntry'si olan günleri filtrele
            let validHistoryItems = allHistoryItems.filter { historyModel in
                guard let sleepEntries = historyModel.sleepEntries else { return false }
                return !sleepEntries.isEmpty
            }
            
            self.historyItems = validHistoryItems
            syncStatus = .synced
            print("\(self.historyItems.count) adet HistoryModel yüklendi (Filtre: \(selectedFilter.rawValue))")
            
            // HealthKit verilerini de yükle
            Task {
                await loadHealthKitData()
            }
            
        } catch {
            handleError("Failed to load history: \(error.localizedDescription)")
        }
    }
    
    private func applyFilters() {
        loadHistoryItems()
        Task {
            await loadHealthKitData()
            await MainActor.run {
                applyHealthKitFilters()
            }
        }
    }
    
    private func applyHealthKitFilters() {
        filteredHealthKitData = healthKitData.filter { sample in
            // Apply sleep type filter
            if selectedSleepTypeFilter != .all {
                let isCore = sample.type == .asleep || sample.type == .inBed
                switch selectedSleepTypeFilter {
                case .core:
                    if !isCore { return false }
                case .nap:
                    if isCore { return false }
                case .all:
                    break
                }
            }
            
            // Apply rating filter
            if selectedRatingFilter != .all {
                let rating = sample.rating ?? 0
                switch selectedRatingFilter {
                case .zeroOne:
                    if rating < 0 || rating > 1 { return false }
                case .oneTwo:
                    if rating < 1 || rating > 2 { return false }
                case .twoThree:
                    if rating < 2 || rating > 3 { return false }
                case .threeFour:
                    if rating < 3 || rating > 4 { return false }
                case .fourFive:
                    if rating < 4 || rating > 5 { return false }
                case .unrated:
                    if rating > 0 { return false }
                case .all:
                    break
                }
            }
            
            // Apply source filter
            if selectedSourceFilter != .all {
                switch selectedSourceFilter {
                case .manual:
                    return false // HealthKit data should be filtered out for manual-only
                case .health:
                    break // HealthKit data should be included for health-only
                case .all:
                    break
                }
            }
            
            // Apply adjustment filter
            if selectedAdjustmentFilter != .all {
                switch selectedAdjustmentFilter {
                case .custom:
                    break // HealthKit is typically custom
                default:
                    return false // HealthKit doesn't have other adjustment types
                }
            }
            
            return true
        }
    }
    
    private func createTimeFilterPredicate() -> Predicate<HistoryModel>? {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedFilter {
        case .today:
            let todayStart = calendar.startOfDay(for: now)
            return #Predicate<HistoryModel> { $0.date == todayStart }
            
        case .thisWeek:
            guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
                return nil
            }
            guard let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else {
                return nil
            }
             return #Predicate<HistoryModel> { $0.date >= startOfWeek && $0.date < endOfWeek }

         case .thisMonth:
             guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
                 return nil
             }
            guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
                return nil
            }
             return #Predicate<HistoryModel> { $0.date >= startOfMonth && $0.date < endOfMonth }
         
         case .specificDate:
             let selectedDayStart = calendar.startOfDay(for: selectedSpecificDate)
             return #Predicate<HistoryModel> { $0.date == selectedDayStart }
            
        case .allTime:
            return nil
        }
    }
    
    private func getOrCreateHistoryModel(for date: Date) throws -> HistoryModel {
        guard let modelContext = modelContext else {
            throw HistoryError.contextNotAvailable
        }
        
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        // Var olan HistoryModel'i ara
        let predicate = #Predicate<HistoryModel> { $0.date == dayStart }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        if let existingModel = try modelContext.fetch(descriptor).first {
            return existingModel
        }
        
        // Yeni HistoryModel oluştur
        let newModel = HistoryModel(date: dayStart)
        modelContext.insert(newModel)
        print("Yeni HistoryModel oluşturuldu: \(dayStart)")
        
        return newModel
    }
    
    private func handleError(_ message: String) {
        syncError = message
        syncStatus = .error(message)
        print("HistoryViewModel Error: \(message)")
    }
    
    // Yeni refresh metodu
    @MainActor
    private func refreshData() {
        // State'leri sıfırla
        isAddSleepEntryPresented = false
        isDayDetailPresented = false
        selectedDay = nil
        
        // Data'yı yeniden yükle
        loadHistoryItems()
        
        // HealthKit verilerini yükle
        Task {
            await loadHealthKitData()
        }
        
        // Published property'leri güncelle
        objectWillChange.send()
    }
    
    // MARK: - HealthKit Integration
    
    /// HealthKit verilerini yükler
    func loadHealthKitData() async {
        let healthKitManager = HealthKitManager.shared
        
        // Authorization kontrolü - asenkron authorization check
        let authStatus = await withCheckedContinuation { continuation in
            healthKitManager.getAuthorizationStatus { status in
                continuation.resume(returning: status)
            }
        }
        
        guard authStatus == .sharingAuthorized else {
            print("ℹ️ HistoryViewModel: HealthKit izni yok (\(authStatus)), veriler yüklenmeyecek")
            await MainActor.run {
                isHealthKitDataLoaded = false
                healthKitData = []
            }
            return
        }
        
        // Filtre durumuna göre tarih aralığını belirle
        let (startDate, endDate) = getDateRangeForFilter()
        
        // HealthKit verilerini çek
        let result = await healthKitManager.fetchSleepAnalysis(
            startDate: startDate,
            endDate: endDate
        )
        
        await MainActor.run {
            switch result {
            case .success(let samples):
                // Rating'leri yükle ve samples ile eşleştir
                var updatedSamples = samples
                loadHealthKitRatingsFromPersistence(for: &updatedSamples)
                
                healthKitData = updatedSamples
                isHealthKitDataLoaded = true
                print("✅ HistoryViewModel: \(samples.count) adet HealthKit verisi yüklendi (Filtre: \(selectedFilter.rawValue), Tarih aralığı: \(startDate) - \(endDate))")
                objectWillChange.send() // UI güncelleme için explicit trigger
                
            case .failure(let error):
                healthKitData = []
                isHealthKitDataLoaded = false
                print("🚨 HistoryViewModel: HealthKit verisi yüklenemedi: \(error.localizedDescription)")
            }
        }
    }
    
    /// Belirtilen tarih için HealthKit verilerini döndürür
    func getHealthKitData(for date: Date) -> [HealthKitSleepSample] {
        let calendar = Calendar.current
        return healthKitData.filter { sample in
            calendar.isDate(sample.startDate, inSameDayAs: date)
        }
    }
    
    /// Seçili filtre için tarih aralığını döndürür
    private func getDateRangeForFilter() -> (startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        let now = Date()
        let endDate = now
        
        let startDate: Date
        switch selectedFilter {
        case .today:
            startDate = calendar.startOfDay(for: now)
        case .thisWeek:
            startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        case .thisMonth:
            startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        case .specificDate:
            startDate = calendar.startOfDay(for: selectedSpecificDate)
        case .allTime:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now // Son 3 ay
        }
        
        return (startDate, endDate)
    }
    
    /// HealthKit ve PolyNap verilerini birleştirerek kombine günlük data döndürür
    func getCombinedDayData(for date: Date) -> (polyNapEntry: HistoryModel?, healthKitData: [HealthKitSleepSample]) {
        let polyNapEntry = getHistoryItem(for: date)
        let healthKitEntries = getHealthKitData(for: date)
        
        return (polyNapEntry, healthKitEntries)
    }
    
    // MARK: - HealthKit Data Management
    
    /// HealthKit verisi için puan günceller ve kaydeder
    func updateHealthKitRating(for sampleId: UUID, rating: Double) {
        guard let modelContext = modelContext else {
            print("🚨 ModelContext not available for HealthKit rating")
            return
        }
        
        if let index = healthKitData.firstIndex(where: { $0.id == sampleId }) {
            let sample = healthKitData[index]
            healthKitData[index].rating = rating
            
            // Database'e kalıcı olarak kaydet
            saveHealthKitRatingToPersistence(sample: sample, rating: rating)
            
            // UI'ı güncelle (günün ortalama rating'i değişebilir)
            reloadData()
            
            print("✅ HealthKit sample rating güncellendi ve kaydedildi: \(rating)")
        }
    }
    
    /// HealthKit rating'ini SleepEntry olarak SwiftData'ya kaydeder
    private func saveHealthKitRatingToPersistence(sample: HealthKitSleepSample, rating: Double) {
        guard let modelContext = modelContext else { return }
        
        do {
            let calendar = Calendar.current
            let entryDate = calendar.startOfDay(for: sample.startDate)
            
            // Önce aynı HealthKit sample için SleepEntry olup olmadığını kontrol et  
            let sampleStartDate = sample.startDate
            let sampleEndDate = sample.endDate
            let predicate = #Predicate<SleepEntry> { entry in
                entry.source == "health" &&
                entry.startTime == sampleStartDate &&
                entry.endTime == sampleEndDate
            }
            let descriptor = FetchDescriptor(predicate: predicate)
            
            if let existingEntry = try modelContext.fetch(descriptor).first {
                // Mevcut SleepEntry'yi güncelle
                existingEntry.rating = rating
                existingEntry.updatedAt = Date()
                print("✅ Mevcut HealthKit SleepEntry rating'i güncellendi: \(rating)")
            } else {
                // Yeni SleepEntry oluştur (HealthKit verisi olarak işaretle)
                let durationMinutes = Int(sample.endDate.timeIntervalSince(sample.startDate) / 60)
                
                let newEntry = SleepEntry(
                    date: entryDate,
                    startTime: sample.startDate,
                    endTime: sample.endDate,
                    durationMinutes: durationMinutes,
                    isCore: sample.type == .inBed || sample.type == .asleep, // HealthKit core sleep types
                    blockId: nil, // HealthKit verileri schedule block'una bağlı değil
                    emoji: nil, // HealthKit verileri emoji içermez
                    rating: rating,
                    source: "health" // HealthKit verisi olduğunu belirt
                )
                
                // HistoryModel'i bul veya oluştur
                let historyPredicate = #Predicate<HistoryModel> { $0.date == entryDate }
                let historyDescriptor = FetchDescriptor(predicate: historyPredicate)
                
                var historyModel = try modelContext.fetch(historyDescriptor).first
                if historyModel == nil {
                    historyModel = HistoryModel(date: entryDate)
                    modelContext.insert(historyModel!)
                }
                
                // SleepEntry'yi HistoryModel'e bağla
                newEntry.historyDay = historyModel
                historyModel?.sleepEntries?.append(newEntry)
                modelContext.insert(newEntry)
                
                print("✅ Yeni HealthKit SleepEntry oluşturuldu: \(rating)")
            }
            
            try modelContext.save()
            print("✅ HealthKit rating SleepEntry olarak kaydedildi")
            
        } catch {
            print("🚨 HealthKit rating SleepEntry kaydetme hatası: \(error.localizedDescription)")
        }
    }
    
    /// HealthKit samples'ları için kaydedilmiş rating'leri SleepEntry'lerden yükler
    private func loadHealthKitRatingsFromPersistence(for samples: inout [HealthKitSleepSample]) {
        guard let modelContext = modelContext else { return }
        
        do {
            // HealthKit kaynaklı SleepEntry'leri çek
            let predicate = #Predicate<SleepEntry> { $0.source == "health" }
            let descriptor = FetchDescriptor(predicate: predicate)
            let healthSleepEntries = try modelContext.fetch(descriptor)
            
            // Her sample için ilgili SleepEntry'yi bul ve rating'i ata
            for index in samples.indices {
                let sample = samples[index]
                
                // Aynı başlangıç ve bitiş zamanına sahip SleepEntry'yi bul
                if let matchingEntry = healthSleepEntries.first(where: { entry in
                    entry.startTime == sample.startDate && entry.endTime == sample.endDate
                }) {
                    samples[index].rating = matchingEntry.rating
                }
            }
            
            let ratedCount = samples.filter { $0.rating != nil }.count
            print("✅ \(ratedCount) adet HealthKit sample için rating SleepEntry'lerden yüklendi")
            
        } catch {
            print("🚨 HealthKit rating'leri SleepEntry'lerden yüklenirken hata: \(error.localizedDescription)")
        }
    }
    
    /// HealthKit verisini siler (sadece uygulama içinde)
    func deleteHealthKitSample(_ sample: HealthKitSleepSample) {
        healthKitData.removeAll { $0.id == sample.id }
        
        // Rating'i de veritabanından sil
        deleteHealthKitRatingFromPersistence(sample: sample)
        
        print("✅ HealthKit sample silindi: \(sample.id)")
    }
    
    /// HealthKit için oluşturulan SleepEntry'yi veritabanından siler
    private func deleteHealthKitRatingFromPersistence(sample: HealthKitSleepSample) {
        guard let modelContext = modelContext else { return }
        
        do {
            // İlgili SleepEntry'yi bul
            let sampleStartDate = sample.startDate
            let sampleEndDate = sample.endDate
            let predicate = #Predicate<SleepEntry> { entry in
                entry.source == "health" &&
                entry.startTime == sampleStartDate &&
                entry.endTime == sampleEndDate
            }
            let descriptor = FetchDescriptor(predicate: predicate)
            
            if let entryToDelete = try modelContext.fetch(descriptor).first {
                modelContext.delete(entryToDelete)
                try modelContext.save()
                print("✅ HealthKit SleepEntry veritabanından silindi")
            }
            
        } catch {
            print("🚨 HealthKit rating silme hatası: \(error.localizedDescription)")
        }
    }
    
    /// HealthKit verisini düzenler
    func editHealthKitSample(_ sample: HealthKitSleepSample, newRating: Double) {
        updateHealthKitRating(for: sample.id, rating: newRating)
    }

    // MARK: - Badge Evaluation

    /// Tüm kayıtlı uyku verilerinden streak hesaplar (filtre uygulanmaz).
    /// ProfileScreenViewModel ile aynı mantığı kullanır, böylece uyku kaydı
    /// eklendikten hemen sonra güncel değerler ile badge evaluation yapılabilir.
    private func calculateStreakFromAllHistory() -> (current: Int, longest: Int) {
        guard let modelContext = modelContext else { return (0, 0) }
        let allHistory: [HistoryModel]
        do {
            let descriptor = FetchDescriptor<HistoryModel>(
                sortBy: [SortDescriptor(\HistoryModel.date, order: .ascending)]
            )
            allHistory = try modelContext.fetch(descriptor)
        } catch {
            return (0, 0)
        }

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        let daysWithSleep: Set<Date> = Set(
            allHistory.compactMap { model -> Date? in
                guard let entries = model.sleepEntries,
                      entries.contains(where: { $0.duration > 0 }) else { return nil }
                return cal.startOfDay(for: model.date)
            }
        )

        guard !daysWithSleep.isEmpty else { return (0, 0) }

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

        return (current, longest)
    }

    private func evaluateBadgesAfterSleepLog() {
        // Streak değerlerini doğrudan tüm geçmişten hesapla;
        // UserDefaults cache'i ProfileScreenViewModel henüz açılmadıysa
        // güncel olmayabilir.
        let (freshCurrent, freshLongest) = calculateStreakFromAllHistory()

        // Cache'i güncelle (ProfileScreenViewModel ile tutarlılık için)
        let storedLongest = UserDefaults.standard.integer(forKey: "longestStreak")
        let newLongest = max(freshLongest, storedLongest)
        UserDefaults.standard.set(freshCurrent, forKey: "currentStreak")
        UserDefaults.standard.set(newLongest, forKey: "longestStreak")

        // adaptationDuration: cache yoksa (profil hiç açılmadıysa) aktif
        // program adından belirle, yoksa 21'e düş.
        let cachedDuration = UserDefaults.standard.integer(forKey: "cachedAdaptationDuration")
        let adaptationDuration: Int
        if cachedDuration > 0 {
            adaptationDuration = cachedDuration
        } else if let name = ScheduleManager.shared.activeSchedule?.name.lowercased() {
            let isLongProgram = name.contains("uberman")
                || name.contains("dymaxion")
                || (name.contains("everyman") && name.contains("1"))
            adaptationDuration = isLongProgram ? 28 : 21
        } else {
            adaptationDuration = 21
        }

        let context = BadgeManager.EvaluationContext(
            hasSchedule: ScheduleManager.shared.activeSchedule != nil,
            longestStreak: newLongest,
            currentStreak: freshCurrent,
            adaptationPhase: UserDefaults.standard.integer(forKey: "cachedAdaptationPhase"),
            currentAdaptationDay: UserDefaults.standard.integer(forKey: "cachedAdaptationDay"),
            adaptationDuration: adaptationDuration,
            isAdaptationComplete: UserDefaults.standard.bool(forKey: "cachedIsAdaptationComplete"),
            isPremium: RevenueCatManager.shared.userState == .premium
        )
        BadgeManager.shared.evaluateBadges(context: context)
    }
}

// MARK: - Error Types
enum HistoryError: LocalizedError {
    case contextNotAvailable
    case invalidDate
    case entryNotFound
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Data context is not available"
        case .invalidDate:
            return "Invalid date provided"
        case .entryNotFound:
            return "Sleep entry not found"
        }
    }
}
