import Foundation
import SwiftUI
import SwiftData
import Charts

enum TimeRange: String, CaseIterable, Identifiable {
    case Week = "week"
    case Month = "month"
    case Quarter = "quarter"
    case Year = "year"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .Week: return L("analytics.timeRange.week", table: "Analytics")
        case .Month: return L("analytics.timeRange.month", table: "Analytics")
        case .Quarter: return L("analytics.timeRange.quarter", table: "Analytics")
        case .Year: return L("analytics.timeRange.year", table: "Analytics")
        }
    }
    
    var days: Int {
        switch self {
        case .Week: return 7
        case .Month: return 30
        case .Quarter: return 90
        case .Year: return 365
        }
    }
}

/// Uyku kalitesi kategorisi
enum SleepQualityCategory: String, CaseIterable {
    case excellent = "Mükemmel"
    case good = "İyi"
    case average = "Ortalama" 
    case poor = "Kötü"
    case bad = "Çok Kötü"
    
    var localizedName: String {
        switch self {
        case .excellent: return L("analytics.sleepQuality.excellent", table: "Analytics")
        case .good: return L("analytics.sleepQuality.good", table: "Analytics")
        case .average: return L("analytics.sleepQuality.average", table: "Analytics")
        case .poor: return L("analytics.sleepQuality.poor", table: "Analytics")
        case .bad: return L("analytics.sleepQuality.bad", table: "Analytics")
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return .appSecondary
        case .good: return .appPrimary
        case .average: return .appAccent
        case .poor: return .metricAmber
        case .bad: return .appError
        }
    }
    
    static func fromRating(_ rating: Double) -> SleepQualityCategory {
        switch rating {
        case 4.5...5: return .excellent
        case 3.5..<4.5: return .good
        case 2.5..<3.5: return .average
        case 1.5..<2.5: return .poor
        default: return .bad
        }
    }
}

/// Uyku trendi verileri
struct SleepTrendData: Identifiable {
    let id = UUID()
    let date: Date
    let totalHours: Double
    let coreHours: Double
    let napHours: Double
    let score: Double
    
    // Ayrıştırılmış şekli
    var nap1Hours: Double = 0.0
    var nap2Hours: Double = 0.0
    
    // Hesaplanmış veriler
    var scoreCategory: SleepQualityCategory {
        SleepQualityCategory.fromRating(score)
    }
    
    var percentageOfTarget: Double {
        // Hedef 8 saat kabul edilirse
        return min((totalHours / 8.0) * 100, 100)
    }
    
    /// Başlangıçta sadece ana değerleri belirle, sonra napları ayrıştır
    init(date: Date, totalHours: Double, coreHours: Double, napHours: Double, score: Double) {
        self.date = date
        // Veri validasyonu - NaN, Infinite ve negatif değerleri temizle
        self.totalHours = max(0, totalHours.isNaN || totalHours.isInfinite ? 0 : totalHours)
        self.coreHours = max(0, coreHours.isNaN || coreHours.isInfinite ? 0 : coreHours)
        self.napHours = max(0, napHours.isNaN || napHours.isInfinite ? 0 : napHours)
        self.score = max(0, min(5, score.isNaN || score.isInfinite ? 0 : score))
    }
    
    /// Napları belirli bir dağılımla ayır
    mutating func distributeNaps(nap1: Double, nap2: Double) {
        self.nap1Hours = max(0, nap1.isNaN || nap1.isInfinite ? 0 : nap1)
        self.nap2Hours = max(0, nap2.isNaN || nap2.isInfinite ? 0 : nap2)
    }
}

/// Uyku dağılım verileri
struct SleepBreakdownData: Identifiable {
    let id = UUID()
    let date: Date = Date()
    let type: String
    let hours: Double
    let percentage: Double
    let color: Color
    
    // Ek istatistikler
    var averagePerDay: Double = 0.0
    var daysWithThisType: Int = 0
    var percentageChange: Double = 0.0  // Önceki döneme göre değişim
    
    init(type: String, hours: Double, percentage: Double, color: Color) {
        self.type = type
        // Veri validasyonu
        self.hours = max(0, hours.isNaN || hours.isInfinite ? 0 : hours)
        self.percentage = max(0, min(100, percentage.isNaN || percentage.isInfinite ? 0 : percentage))
        self.color = color
    }
}

/// Uyku kalitesi istatistikleri
struct SleepQualityStats {
    var excellentDays: Int = 0
    var goodDays: Int = 0
    var averageDays: Int = 0
    var poorDays: Int = 0
    var badDays: Int = 0
    
    var totalDays: Int {
        excellentDays + goodDays + averageDays + poorDays + badDays
    }
    
    var excellentPercentage: Double {
        totalDays > 0 ? Double(excellentDays) / Double(totalDays) * 100 : 0
    }
    
    var goodPercentage: Double {
        totalDays > 0 ? Double(goodDays) / Double(totalDays) * 100 : 0
    }
    
    var averagePercentage: Double {
        totalDays > 0 ? Double(averageDays) / Double(totalDays) * 100 : 0
    }
    
    var poorPercentage: Double {
        totalDays > 0 ? Double(poorDays) / Double(totalDays) * 100 : 0
    }
    
    var badPercentage: Double {
        totalDays > 0 ? Double(badDays) / Double(totalDays) * 100 : 0
    }
    
    var averageRating: Double {
        if totalDays == 0 { return 0 }
        let weightedSum = Double(excellentDays * 5 + goodDays * 4 + averageDays * 3 + poorDays * 2 + badDays * 1)
        return weightedSum / Double(totalDays)
    }
}

/// Kapsamlı uyku istatistikleri
struct SleepStatistics {
    var totalSleepHours: Double = 0.0
    var averageDailyHours: Double = 0.0
    var averageSleepScore: Double = 0.0
    var timeGained: Double = 0.0
    
    // Verimlilik
    var efficiencyPercentage: Double = 0.0  // Hedef uyku süresine kıyasla
    
    // En iyi/en kötü günler
    var bestDay: Date?
    var bestDayScore: Double = 0.0
    var worstDay: Date?
    var worstDayScore: Double = 5.0
    
    // Uyku düzeni
    var consistencyScore: Double = 0.0  // Aynı zamanda uyuma tutarlılığı
    var variabilityScore: Double = 0.0  // Günler arası değişkenlik
    
    // Trend analizi
    var trendDirection: Double = 0.0  // Pozitif değer iyileşme, negatif değer kötüleşme
    var improvementRate: Double = 0.0  // İyileşme oranı
}

class AnalyticsViewModel: ObservableObject {
    @Published var selectedTimeRange: TimeRange = .Week
    @Published var isLoading: Bool = false
    @Published var hasEnoughData: Bool = false
    
    // Ana analiz verileri
    @Published var totalSleepHours: Double = 0.0
    @Published var averageDailyHours: Double = 0.0
    @Published var averageSleepScore: Double = 0.0
    @Published var timeGained: Double = 0.0
    
    // Grafik verileri
    @Published var sleepTrendData: [SleepTrendData] = []
    @Published var sleepBreakdownData: [SleepBreakdownData] = []
    
    // Gelişmiş istatistikler
    @Published var sleepQualityStats: SleepQualityStats = SleepQualityStats()
    @Published var sleepStatistics: SleepStatistics = SleepStatistics()
    
    // Premium analiz verileri
    @Published var consistencyTrendData: [ConsistencyTrendData] = []
    @Published var sleepDebtData: [SleepDebtData] = []
    @Published var qualityConsistencyData: [QualityConsistencyData] = []
    @Published var qualityConsistencyCorrelation: CorrelationStats = CorrelationStats(slope: 0, intercept: 0, correlation: 0)
    
    // Adherence verileri (Free)
    @Published var adherenceData: [DailyAdherenceData] = []
    @Published var adherenceSummary: AdherenceSummary = AdherenceSummary()
    
    // Sleep stages verileri (Premium + HealthKit)
    @Published var sleepStagesData: [DailySleepStagesData] = []
    
    // Apple Health verileri (Premium)
    @Published var heartRateData: [DailyHeartRateData] = []
    @Published var hrvData: [DailyHRVData] = []
    @Published var sleepRegularityData: [SleepRegularityData] = []
    @Published var isHealthDataLoading: Bool = false
    @Published var hasHealthKitAccess: Bool = false
    
    // En iyi/en kötü günler
    @Published var bestSleepDay: (date: Date, hours: Double, score: Double)?
    @Published var worstSleepDay: (date: Date, hours: Double, score: Double)?
    
    // Karşılaştırma istatistikleri
    @Published var previousPeriodComparison: (hours: Double, score: Double) = (0, 0)
    
    private var modelContext: ModelContext?
    private let minimumRequiredDays = 2  // Daha az veri gereksinimi
    
    // MARK: - Public Methods
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadRealData()
    }
    
    func changeTimeRange(to newRange: TimeRange) {
        // Güncelleme sırasında loading state'i göster
        guard selectedTimeRange != newRange else { return } // Gereksiz güncellemeyi önle
        
        selectedTimeRange = newRange
        loadRealData()
    }
    
    /// Apple Health verilerini yükle (Premium özellik)
    func loadHealthData() {
        isHealthDataLoading = true
        
        let healthKit = HealthKitManager.shared
        
        Task { @MainActor in
            guard healthKit.isHealthDataAvailable else {
                isHealthDataLoading = false
                hasHealthKitAccess = false
                return
            }
            
            let authResult = await healthKit.requestAuthorization()
            switch authResult {
            case .success:
                hasHealthKitAccess = true
            case .failure:
                isHealthDataLoading = false
                hasHealthKitAccess = false
                return
            }
            
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: endDate) ?? endDate
            
            // Paralel olarak HR, HRV ve Sleep Stages verilerini çek
            async let hrResult = healthKit.fetchHeartRateData(startDate: startDate, endDate: endDate)
            async let hrvResult = healthKit.fetchHRVData(startDate: startDate, endDate: endDate)
            async let restingHRResult = healthKit.fetchRestingHeartRate(startDate: startDate, endDate: endDate)
            async let sleepResult = healthKit.fetchSleepAnalysis(startDate: startDate, endDate: endDate)
            
            let (hrData, hrvRawData, restingHRData, sleepData) = await (hrResult, hrvResult, restingHRResult, sleepResult)
            
            // Heart Rate verilerini günlük gruplara ayır
            if case .success(let samples) = hrData {
                self.heartRateData = self.aggregateHeartRateByDay(samples, restingHR: (try? restingHRData.get()) ?? [])
            }
            
            // HRV verilerini günlük gruplara ayır
            if case .success(let samples) = hrvRawData {
                self.hrvData = self.aggregateHRVByDay(samples)
            }
            
            // Sleep stages verilerini günlük gruplara ayır
            if case .success(let samples) = sleepData {
                self.sleepStagesData = self.aggregateSleepStagesByDay(samples)
            }
            
            // Uyku düzenlilik verisini hesapla
            self.calculateSleepRegularity()
            
            self.isHealthDataLoading = false
        }
    }
    
    private func aggregateHeartRateByDay(_ samples: [HealthKitHeartRateSample], restingHR: [HealthKitHeartRateSample]) -> [DailyHeartRateData] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: samples) { calendar.startOfDay(for: $0.date) }
        let restingGrouped = Dictionary(grouping: restingHR) { calendar.startOfDay(for: $0.date) }
        
        return grouped.map { (day, daySamples) in
            let bpms = daySamples.map(\.bpm)
            let avg = bpms.reduce(0, +) / Double(bpms.count)
            let resting = restingGrouped[day]?.map(\.bpm).min()
            return DailyHeartRateData(
                date: day,
                averageBPM: avg,
                minBPM: bpms.min() ?? 0,
                maxBPM: bpms.max() ?? 0,
                restingBPM: resting
            )
        }.sorted { $0.date < $1.date }
    }
    
    private func aggregateHRVByDay(_ samples: [HealthKitHRVSample]) -> [DailyHRVData] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: samples) { calendar.startOfDay(for: $0.date) }
        
        return grouped.map { (day, daySamples) in
            let sdnns = daySamples.map(\.sdnn)
            let avg = sdnns.reduce(0, +) / Double(sdnns.count)
            return DailyHRVData(
                date: day,
                averageSDNN: avg,
                minSDNN: sdnns.min() ?? 0,
                maxSDNN: sdnns.max() ?? 0
            )
        }.sorted { $0.date < $1.date }
    }
    
    private func calculateSleepRegularity() {
        guard !sleepTrendData.isEmpty else { return }
        
        sleepRegularityData = sleepTrendData.map { trend in
            // Uyku düzenlilik skoru: tutarlılık bazlı (ortalamadan sapma)
            let avgHours = averageDailyHours > 0 ? averageDailyHours : 6.0
            let deviation = abs(trend.totalHours - avgHours)
            let maxDeviation: Double = 4.0 // 4 saatten fazla sapma = 0 puan
            let regularityScore = max(0, (1.0 - deviation / maxDeviation)) * 100
            let deviationMinutes = deviation * 60
            
            return SleepRegularityData(
                date: trend.date,
                scheduledStartTime: nil,
                actualStartTime: nil,
                deviationMinutes: deviationMinutes,
                totalSleepHours: trend.totalHours,
                score: regularityScore
            )
        }
    }
    
    private func aggregateSleepStagesByDay(_ samples: [HealthKitSleepSample]) -> [DailySleepStagesData] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: samples) { calendar.startOfDay(for: $0.startDate) }
        
        return grouped.compactMap { (day, daySamples) in
            var remMinutes = 0.0
            var coreMinutes = 0.0
            var deepMinutes = 0.0
            var awakeMinutes = 0.0
            
            for sample in daySamples {
                let duration = sample.endDate.timeIntervalSince(sample.startDate) / 60.0
                switch sample.type {
                case .rem: remMinutes += duration
                case .core, .asleep: coreMinutes += duration
                case .deep: deepMinutes += duration
                case .awake: awakeMinutes += duration
                case .inBed: break
                }
            }
            
            let total = remMinutes + coreMinutes + deepMinutes + awakeMinutes
            guard total > 0 else { return nil }
            
            return DailySleepStagesData(
                date: day,
                remMinutes: remMinutes,
                coreMinutes: coreMinutes,
                deepMinutes: deepMinutes,
                awakeMinutes: awakeMinutes,
                totalMinutes: total
            )
        }.sorted(by: { $0.date < $1.date })
    }
    
    // MARK: - Private Methods
    
    private func loadRealData() {
        guard let modelContext = modelContext else { 
            print("❌ ModelContext bulunamadı")
            return 
        }
        
        // UI'da loading durumunu hemen göster
        DispatchQueue.main.async {
            self.isLoading = true
            self.hasEnoughData = false
        }
        
        Task {
            do {
                print("�� Analytics veri yükleniyor - Zaman aralığı: \(selectedTimeRange.rawValue)")
                
                let descriptor = FetchDescriptor<HistoryModel>(
                    sortBy: [SortDescriptor(\HistoryModel.date, order: .forward)]
                )
                let allHistoryModels = try await modelContext.fetch(descriptor)
                
                let endDate = Date()
                let startDate = calculateStartDate(from: endDate)
                
                print("📅 Tarih aralığı: \(startDate) - \(endDate)")
                print("📊 Toplam history count: \(allHistoryModels.count)")
                
                // Seçilen zaman aralığına göre filtrele
                let filteredHistoryModels = allHistoryModels.filter { historyModel in
                    let dayStart = Calendar.current.startOfDay(for: historyModel.date)
                    let isInRange = dayStart >= Calendar.current.startOfDay(for: startDate) && 
                                   dayStart <= Calendar.current.startOfDay(for: endDate)
                    return isInRange
                }
                
                print("🔍 Filtrelenmiş history count: \(filteredHistoryModels.count)")
                
                // Önceki dönem verilerini al (karşılaştırma için)
                let previousPeriodModels = allHistoryModels.filter { historyModel in
                    let prevStartDate = calculatePreviousPeriodStartDate(from: startDate, endDate: endDate)
                    let dayStart = Calendar.current.startOfDay(for: historyModel.date)
                    return dayStart >= Calendar.current.startOfDay(for: prevStartDate) && 
                           dayStart < Calendar.current.startOfDay(for: startDate)
                }
                
                // Benzersiz günleri say
                let uniqueDaysCount = Set(filteredHistoryModels.map { 
                    Calendar.current.startOfDay(for: $0.date) 
                }).count
                
                print("📈 Benzersiz gün sayısı: \(uniqueDaysCount), Minimum gerekli: \(minimumRequiredDays)")
                
                // Ana thread'de UI güncellemelerini yap
                await MainActor.run {
                    let hasData = uniqueDaysCount >= minimumRequiredDays || !filteredHistoryModels.isEmpty
                    
                    if hasData {
                        print("✅ Yeterli veri var, analiz başlatılıyor")
                        self.hasEnoughData = true
                        self.analyzeData(historyModels: filteredHistoryModels, startDate: startDate, endDate: endDate)
                        self.compareToPreviousPeriod(currentModels: filteredHistoryModels, previousModels: previousPeriodModels)
                    } else {
                        print("❌ Yetersiz veri")
                        self.hasEnoughData = false
                        self.resetAnalyticsData()
                    }
                    
                    self.isLoading = false
                    print("✅ Analytics yükleme tamamlandı")
                }
                
            } catch {
                print("❌ Analytics veri yüklenirken hata: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                    self.hasEnoughData = false
                    self.resetAnalyticsData()
                }
            }
        }
    }
    
    private func resetAnalyticsData() {
        totalSleepHours = 0.0
        averageDailyHours = 0.0
        averageSleepScore = 0.0
        timeGained = 0.0
        sleepTrendData = []
        sleepBreakdownData = []
        sleepStatistics = SleepStatistics()
        sleepQualityStats = SleepQualityStats()
        bestSleepDay = nil
        worstSleepDay = nil
        previousPeriodComparison = (0, 0)
        consistencyTrendData = []
        sleepDebtData = []
        qualityConsistencyData = []
        adherenceData = []
        adherenceSummary = AdherenceSummary()
        sleepStagesData = []
    }
    
    private func calculateStartDate(from endDate: Date) -> Date {
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: endDate)
        
        switch selectedTimeRange {
        case .Week:
            return calendar.date(byAdding: .day, value: -6, to: endOfDay) ?? endOfDay // 7 gün (bugün dahil)
        case .Month:
            return calendar.date(byAdding: .day, value: -29, to: endOfDay) ?? endOfDay // 30 gün (bugün dahil)
        case .Quarter:
            return calendar.date(byAdding: .day, value: -89, to: endOfDay) ?? endOfDay // 90 gün (bugün dahil)
        case .Year:
            return calendar.date(byAdding: .day, value: -364, to: endOfDay) ?? endOfDay // 365 gün (bugün dahil)
        }
    }
    
    private func calculatePreviousPeriodStartDate(from startDate: Date, endDate: Date) -> Date {
        let timeSpan = endDate.timeIntervalSince(startDate)
        return startDate.addingTimeInterval(-timeSpan)
    }
    
    private func analyzeData(historyModels: [HistoryModel], startDate: Date, endDate: Date) {
        let allSleepEntries = historyModels.flatMap { $0.sleepEntries ?? [] }
        var stats = SleepStatistics()
        stats.totalSleepHours = allSleepEntries.reduce(0.0) { $0 + ($1.duration / 3600.0) }

        let calendar = Calendar.current
        let daysWithData = Set(historyModels.map { calendar.startOfDay(for: $0.date) }).sorted()
        let daysWithDataCount = daysWithData.count
        stats.averageDailyHours = daysWithDataCount > 0 ? stats.totalSleepHours / Double(daysWithDataCount) : 0
        
        let totalScoreSum = allSleepEntries.reduce(0) { $0 + $1.rating }
        stats.averageSleepScore = allSleepEntries.isEmpty ? 0 : Double(totalScoreSum) / Double(allSleepEntries.count)
        
        let traditionalSleepHours = 8.0 * Double(daysWithDataCount)
        stats.timeGained = max(0, traditionalSleepHours - stats.totalSleepHours)
        stats.efficiencyPercentage = traditionalSleepHours > 0 ? ((traditionalSleepHours - stats.totalSleepHours) / traditionalSleepHours) * 100 : 0
            
        var bestDay: (date: Date, hours: Double, score: Double)?
        var worstDay: (date: Date, hours: Double, score: Double)?
        
        for dayDate in daysWithData {
            let dayEntries = allSleepEntries.filter { calendar.isDate($0.date, inSameDayAs: dayDate) }
            if dayEntries.isEmpty { continue }
            
            let dayTotalHours = dayEntries.reduce(0.0) { $0 + $1.duration / 3600.0 }
            let dayTotalScore = dayEntries.reduce(0) { $0 + $1.rating }
            let dayAverageScore = Double(dayTotalScore) / Double(dayEntries.count)
            
            if bestDay == nil || dayAverageScore > bestDay!.score {
                bestDay = (dayDate, dayTotalHours, dayAverageScore)
            }
            if worstDay == nil || dayAverageScore < worstDay!.score {
                worstDay = (dayDate, dayTotalHours, dayAverageScore)
            }
        }
        
        stats.bestDay = bestDay?.date
        stats.bestDayScore = bestDay?.score ?? 0
        stats.worstDay = worstDay?.date
        stats.worstDayScore = worstDay?.score ?? 5.0 // Default to 5 for comparison

        if daysWithDataCount > 1 {
            var sleepTimesInMinutes: [Double] = []
            for entry in allSleepEntries { // Iterate over allSleepEntries directly
                let components = calendar.dateComponents([.hour, .minute], from: entry.startTime)
                if let hour = components.hour, let minute = components.minute {
                    sleepTimesInMinutes.append(Double(hour * 60 + minute))
                }
            }
            
            if sleepTimesInMinutes.count > 1 {
                let mean = sleepTimesInMinutes.reduce(0, +) / Double(sleepTimesInMinutes.count)
                let variance = sleepTimesInMinutes.reduce(0) { $0 + pow($1 - mean, 2) } / Double(sleepTimesInMinutes.count - 1)
                let standardDeviation = sqrt(variance)
                stats.consistencyScore = max(0, 100 - min(100, standardDeviation / 60)) // SD in minutes / 60 min
                stats.variabilityScore = min(100, standardDeviation / 60)
            }
        }

        if daysWithDataCount > 2 {
            let sortedHistoryByDate = historyModels.sorted(by: { $0.date < $1.date })
            let firstHalfModels = sortedHistoryByDate.prefix(sortedHistoryByDate.count / 2)
            let secondHalfModels = sortedHistoryByDate.suffix(sortedHistoryByDate.count - sortedHistoryByDate.count / 2)
            
            let firstHalfEntries = firstHalfModels.flatMap { $0.sleepEntries ?? [] }
            let secondHalfEntries = secondHalfModels.flatMap { $0.sleepEntries ?? [] }

            let firstHalfScoreSum = firstHalfEntries.reduce(0) { $0 + $1.rating }
            let secondHalfScoreSum = secondHalfEntries.reduce(0) { $0 + $1.rating }
            
            let firstHalfAvg = !firstHalfEntries.isEmpty ? Double(firstHalfScoreSum) / Double(firstHalfEntries.count) : 0
            let secondHalfAvg = !secondHalfEntries.isEmpty ? Double(secondHalfScoreSum) / Double(secondHalfEntries.count) : 0
            
            stats.trendDirection = secondHalfAvg - firstHalfAvg
            stats.improvementRate = firstHalfAvg > 0 ? (secondHalfAvg - firstHalfAvg) / firstHalfAvg * 100 : 0
        }
        
        var qualityStats = SleepQualityStats()
        for dayDate in daysWithData {
            let dayEntries = allSleepEntries.filter { calendar.isDate($0.date, inSameDayAs: dayDate) }
            if dayEntries.isEmpty { continue }
            let dayTotalScore = dayEntries.reduce(0) { $0 + $1.rating }
            let dayAvgScore = Double(dayTotalScore) / Double(dayEntries.count)
            let category = SleepQualityCategory.fromRating(dayAvgScore)
            
            switch category {
            case .excellent: qualityStats.excellentDays += 1
            case .good: qualityStats.goodDays += 1
            case .average: qualityStats.averageDays += 1
            case .poor: qualityStats.poorDays += 1
            case .bad: qualityStats.badDays += 1
            }
        }
        
        self.totalSleepHours = stats.totalSleepHours
        self.averageDailyHours = stats.averageDailyHours
        self.averageSleepScore = stats.averageSleepScore
        self.timeGained = stats.timeGained
        self.sleepStatistics = stats
        self.sleepQualityStats = qualityStats
        self.bestSleepDay = bestDay
        self.worstSleepDay = worstDay
        
        createTrendData(fromSleepEntries: allSleepEntries, startDate: startDate, endDate: endDate)
        createBreakdownData(from: allSleepEntries, timeRangeDays: selectedTimeRange.days)
        
        // Adherence hesapla (Free tier)
        createAdherenceData(fromSleepEntries: allSleepEntries, startDate: startDate, endDate: endDate)
        
        // Premium analizler — gerçek schedule verilerini kullanır
        let scheduleInfo = fetchActiveScheduleInfo()
        createConsistencyTrendData(fromSleepEntries: allSleepEntries, startDate: startDate, endDate: endDate, scheduleInfo: scheduleInfo)
        createSleepDebtData(fromSleepEntries: allSleepEntries, startDate: startDate, endDate: endDate, targetSleepHours: scheduleInfo.targetSleepHours)
        createQualityConsistencyData(fromSleepEntries: allSleepEntries, scheduleInfo: scheduleInfo)
    }
    
    private func compareToPreviousPeriod(currentModels: [HistoryModel], previousModels: [HistoryModel]) {
        let currentSleepEntries = currentModels.flatMap { $0.sleepEntries ?? [] }
        let prevSleepEntries = previousModels.flatMap { $0.sleepEntries ?? [] }
        
        let currentTotalHours = currentSleepEntries.reduce(0.0) { $0 + ($1.duration / 3600.0) }
        let prevTotalHours = prevSleepEntries.reduce(0.0) { $0 + ($1.duration / 3600.0) }
        
        let currentTotalScoreSum = currentSleepEntries.reduce(0) { $0 + $1.rating }
        let prevTotalScoreSum = prevSleepEntries.reduce(0) { $0 + $1.rating }
        
        let currentAvgScore = !currentSleepEntries.isEmpty ? Double(currentTotalScoreSum) / Double(currentSleepEntries.count) : 0
        let prevAvgScore = !prevSleepEntries.isEmpty ? Double(prevTotalScoreSum) / Double(prevSleepEntries.count) : 0
        
        let hoursDiff = currentTotalHours - prevTotalHours
        let scoreDiff = currentAvgScore - prevAvgScore
        
        previousPeriodComparison = (hoursDiff, scoreDiff)
    }
    
    private func createTrendData(fromSleepEntries entries: [SleepEntry], startDate: Date, endDate: Date) {
        switch selectedTimeRange {
        case .Week, .Month:
            createDailyTrendData(fromSleepEntries: entries, startDate: startDate, endDate: endDate)
        case .Quarter:
            sleepTrendData = aggregateTrendData(entries: entries, by: .weekOfYear, from: startDate, to: endDate)
        case .Year:
            sleepTrendData = aggregateTrendData(entries: entries, by: .month, from: startDate, to: endDate)
        }
    }
    
    private func createDailyTrendData(fromSleepEntries entries: [SleepEntry], startDate: Date, endDate: Date) {
        var trendData: [SleepTrendData] = []
        let calendar = Calendar.current
        let maxDataPoints = selectedTimeRange.days
        
        guard let actualStartDate = calendar.date(byAdding: .day, value: -(maxDataPoints - 1), to: calendar.startOfDay(for: endDate)) else { return }

        for dayOffset in 0..<maxDataPoints {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: actualStartDate) else { continue }
            
            // Filter entries for the specific day
            let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
            
            let coreEntries = dayEntries.filter { $0.isCore }
            let napEntries = dayEntries.filter { !$0.isCore }
            
            let totalHours = dayEntries.reduce(0.0) { $0 + $1.duration / 3600.0 }
            let coreHours = coreEntries.reduce(0.0) { $0 + $1.duration / 3600.0 }
            let napHours = napEntries.reduce(0.0) { $0 + $1.duration / 3600.0 }

            let totalScoreSum = dayEntries.reduce(0) { $0 + $1.rating }
            let score = dayEntries.isEmpty ? 0.0 : Double(totalScoreSum) / Double(dayEntries.count)
            
            var sleepData = SleepTrendData(
                date: date,
                totalHours: totalHours,
                coreHours: coreHours,
                napHours: napHours,
                score: score
            )

            let sortedNaps = napEntries.sorted { $0.startTime < $1.startTime }
            let nap1Duration = (sortedNaps.first?.duration ?? 0.0) / 3600.0
            let nap2Duration = (sortedNaps.dropFirst().first?.duration ?? 0.0) / 3600.0
            
            sleepData.distributeNaps(nap1: nap1Duration, nap2: nap2Duration)
            
            trendData.append(sleepData)
        }
        // Ensure the trend data is sorted by date if the generation order wasn't strictly chronological
        trendData.sort(by: { $0.date < $1.date })
        self.sleepTrendData = trendData
    }
    
    private func aggregateTrendData(entries: [SleepEntry], by component: Calendar.Component, from startDate: Date, to endDate: Date) -> [SleepTrendData] {
        let calendar = Calendar.current
        var distinctIntervals = [Date: SleepTrendData]()
        var loopDate = startDate

        while loopDate <= endDate {
            guard let interval = calendar.dateInterval(of: component, for: loopDate) else {
                loopDate = calendar.date(byAdding: .day, value: 1, to: loopDate) ?? endDate.addingTimeInterval(1)
                continue
            }
            
            if distinctIntervals[interval.start] == nil {
                let entriesInInterval = entries.filter { interval.contains($0.date) }
                
                let avgData: SleepTrendData
                if !entriesInInterval.isEmpty {
                    let uniqueDays = Set(entriesInInterval.map { calendar.startOfDay(for: $0.date) })
                    let daysCount = max(1, uniqueDays.count)
                    
                    let totalHours = entriesInInterval.reduce(0.0) { $0 + ($1.duration / 3600.0) }
                    let coreHours = entriesInInterval.filter { $0.isCore }.reduce(0.0) { $0 + ($1.duration / 3600.0) }
                    let napHours = entriesInInterval.filter { !$0.isCore }.reduce(0.0) { $0 + ($1.duration / 3600.0) }
                    let totalScore = entriesInInterval.reduce(0.0) { $0 + Double($1.rating) }
                    let score = entriesInInterval.isEmpty ? 0 : totalScore / Double(entriesInInterval.count)
                    
                    avgData = SleepTrendData(
                        date: interval.start,
                        totalHours: totalHours / Double(daysCount),
                        coreHours: coreHours / Double(daysCount),
                        napHours: napHours / Double(daysCount),
                        score: score
                    )
                } else {
                    avgData = SleepTrendData(
                        date: interval.start,
                        totalHours: 0,
                        coreHours: 0,
                        napHours: 0,
                        score: 0
                    )
                }
                distinctIntervals[interval.start] = avgData
            }
            
            // Move to the next day to find the next interval
            loopDate = calendar.date(byAdding: .day, value: 1, to: loopDate) ?? endDate.addingTimeInterval(1)
        }
        
        return distinctIntervals.values.sorted(by: { $0.date < $1.date })
    }
    
    private func createBreakdownData(from entries: [SleepEntry], timeRangeDays: Int) {
        sleepBreakdownData = []
        guard timeRangeDays > 0 else { return } // Avoid division by zero
        
        let coreEntries = entries.filter { $0.isCore } // isCore direkt kullanılır
        let napEntries = entries.filter { !$0.isCore }  // isCore direkt kullanılır
        
        let coreHours = coreEntries.reduce(0.0) { $0 + ($1.duration / 3600.0) }
        let napHours = napEntries.reduce(0.0) { $0 + ($1.duration / 3600.0) }
        
        let totalHours = coreHours + napHours
        
        var coreData = SleepBreakdownData(
            type: L("analytics.sleepBreakdown.core", table: "Analytics"),
            hours: coreHours,
            percentage: totalHours > 0 ? (coreHours / totalHours) * 100 : 0,
            color: Color("AccentColor") // Design system rengi
        )
        
        var napData = SleepBreakdownData(
            type: L("analytics.sleepBreakdown.nap", table: "Analytics"),
            hours: napHours,
            percentage: totalHours > 0 ? (napHours / totalHours) * 100 : 0,
            color: .appPrimary // Design system rengi
        )
        
        coreData.averagePerDay = coreHours / Double(timeRangeDays)
        napData.averagePerDay = napHours / Double(timeRangeDays)
        
        let uniqueCoreDays = Set(coreEntries.map { Calendar.current.startOfDay(for: $0.date) }).count // date kullanılır
        let uniqueNapDays = Set(napEntries.map { Calendar.current.startOfDay(for: $0.date) }).count // date kullanılır
        
        coreData.daysWithThisType = uniqueCoreDays
        napData.daysWithThisType = uniqueNapDays
        
        sleepBreakdownData = [coreData, napData].filter { $0.hours > 0 } // Sadece saati olanları göster
    }
    
    // MARK: - Schedule Info Helper
    
    private struct ScheduleInfo {
        var targetSleepHours: Double = 6.0
        var coreBlockStartHour: Int = 23
        var coreBlockStartMinute: Int = 0
    }
    
    private func fetchActiveScheduleInfo() -> ScheduleInfo {
        guard let modelContext = modelContext else { return ScheduleInfo() }
        var info = ScheduleInfo()
        
        do {
            let predicate = #Predicate<UserSchedule> { $0.isActive == true }
            let descriptor = FetchDescriptor(predicate: predicate)
            if let activeSchedule = try modelContext.fetch(descriptor).first {
                info.targetSleepHours = activeSchedule.totalSleepHours ?? 6.0
                
                // Core bloğun başlangıç saatini bul
                if let coreBlock = activeSchedule.sleepBlocks?.first(where: { $0.isCore }) {
                    let components = Calendar.current.dateComponents([.hour, .minute], from: coreBlock.startTime)
                    info.coreBlockStartHour = components.hour ?? 23
                    info.coreBlockStartMinute = components.minute ?? 0
                }
            }
        } catch {
            print("⚠️ Aktif schedule bilgisi alınamadı: \(error)")
        }
        
        return info
    }
    
    // MARK: - Adherence Methods
    
    private func createAdherenceData(fromSleepEntries entries: [SleepEntry], startDate: Date, endDate: Date) {
        adherenceData = []
        let calendar = Calendar.current
        let maxDataPoints = selectedTimeRange.days
        
        guard let actualStartDate = calendar.date(byAdding: .day, value: -(maxDataPoints - 1), to: calendar.startOfDay(for: endDate)) else { return }
        
        var totalAdherence = 0.0
        var totalLateness = 0.0
        var adherentDays = 0
        var totalBlocks = 0
        var missedBlocks = 0
        var daysWithEntries = 0
        
        for dayOffset in 0..<maxDataPoints {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: actualStartDate) else { continue }
            
            let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
            guard !dayEntries.isEmpty else { continue }
            
            daysWithEntries += 1
            var dayAdherenceSum = 0.0
            var dayLatenessSum = 0.0
            var dayBlockCount = 0
            
            for entry in dayEntries {
                totalBlocks += 1
                dayBlockCount += 1
                
                if let scheduledStart = entry.originalScheduledStartTime {
                    let deviationMinutes = abs(entry.startTime.timeIntervalSince(scheduledStart)) / 60.0
                    dayLatenessSum += deviationMinutes
                    
                    // ±15 dakika tolerans = tam uyum
                    let blockAdherence = max(0, min(100, 100 - (deviationMinutes - 15) * (100.0 / 45.0)))
                    dayAdherenceSum += deviationMinutes <= 15 ? 100.0 : blockAdherence
                } else {
                    // Zamanında kaydedildiyse uyumlu sayılır
                    dayAdherenceSum += 80.0
                }
                
                if entry.adjustmentInfo == .skipped {
                    missedBlocks += 1
                }
            }
            
            let dayAdherence = dayBlockCount > 0 ? dayAdherenceSum / Double(dayBlockCount) : 0
            let dayLateness = dayBlockCount > 0 ? dayLatenessSum / Double(dayBlockCount) : 0
            
            totalAdherence += dayAdherence
            totalLateness += dayLateness
            if dayAdherence >= 80 { adherentDays += 1 }
            
            adherenceData.append(DailyAdherenceData(
                date: date,
                adherenceScore: dayAdherence,
                averageLateness: dayLateness,
                blocksCompleted: dayBlockCount,
                blocksMissed: dayEntries.filter({ $0.adjustmentInfo == .skipped }).count
            ))
        }
        
        adherenceData.sort(by: { $0.date < $1.date })
        
        adherenceSummary = AdherenceSummary(
            overallScore: daysWithEntries > 0 ? totalAdherence / Double(daysWithEntries) : 0,
            averageLateness: daysWithEntries > 0 ? totalLateness / Double(daysWithEntries) : 0,
            totalBlocksCompleted: totalBlocks,
            totalBlocksMissed: missedBlocks,
            adherentDays: adherentDays,
            totalDays: daysWithEntries
        )
    }
    
    // MARK: - Premium Analytics Methods
    
    private func createConsistencyTrendData(fromSleepEntries entries: [SleepEntry], startDate: Date, endDate: Date, scheduleInfo: ScheduleInfo) {
        consistencyTrendData = []
        let calendar = Calendar.current
        let maxDataPoints = selectedTimeRange.days
        
        guard let actualStartDate = calendar.date(byAdding: .day, value: -(maxDataPoints - 1), to: calendar.startOfDay(for: endDate)) else { return }
        
        let targetHour = scheduleInfo.coreBlockStartHour
        let targetMinute = scheduleInfo.coreBlockStartMinute
        
        for dayOffset in 0..<maxDataPoints {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: actualStartDate) else { continue }
            
            let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let coreEntries = dayEntries.filter { $0.isCore }
            
            if let firstCoreEntry = coreEntries.first {
                // Hedef zaman oluştur
                guard let plannedTime = calendar.date(bySettingHour: targetHour, minute: targetMinute, second: 0, of: date) else { continue }
                
                let actualTime = firstCoreEntry.startTime
                let deviationMinutes = abs(actualTime.timeIntervalSince(plannedTime)) / 60
                
                // Tutarlılık skoru hesapla (daha az sapma = daha yüksek skor)
                let consistencyScore = max(0, 100 - min(100, deviationMinutes))
                
                let consistencyData = ConsistencyTrendData(
                    date: date,
                    consistencyScore: consistencyScore,
                    deviation: deviationMinutes,
                    plannedTime: plannedTime,
                    actualTime: actualTime
                )
                
                consistencyTrendData.append(consistencyData)
            }
        }
        
        consistencyTrendData.sort(by: { $0.date < $1.date })
    }
    
    private func createSleepDebtData(fromSleepEntries entries: [SleepEntry], startDate: Date, endDate: Date, targetSleepHours: Double) {
        sleepDebtData = []
        let calendar = Calendar.current
        let maxDataPoints = selectedTimeRange.days
        let target = targetSleepHours > 0 ? targetSleepHours : 6.0
        
        guard let actualStartDate = calendar.date(byAdding: .day, value: -(maxDataPoints - 1), to: calendar.startOfDay(for: endDate)) else { return }
        
        var cumulativeDebt = 0.0
        
        for dayOffset in 0..<maxDataPoints {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: actualStartDate) else { continue }
            
            let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let actualSleep = dayEntries.reduce(0.0) { $0 + $1.duration / 3600.0 }
            
            let dailyDebt = target - actualSleep
            cumulativeDebt += dailyDebt
            
            let debtData = SleepDebtData(
                date: date,
                targetSleep: target,
                actualSleep: actualSleep,
                dailyDebt: dailyDebt,
                cumulativeDebt: cumulativeDebt
            )
            
            sleepDebtData.append(debtData)
        }
        
        sleepDebtData.sort(by: { $0.date < $1.date })
    }
    
    private func createQualityConsistencyData(fromSleepEntries entries: [SleepEntry], scheduleInfo: ScheduleInfo) {
        qualityConsistencyData = []
        let calendar = Calendar.current
        
        let groupedByDay = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        
        let targetHour = scheduleInfo.coreBlockStartHour
        let targetMinute = scheduleInfo.coreBlockStartMinute
        
        for (date, dayEntries) in groupedByDay {
            let coreEntries = dayEntries.filter { $0.isCore }
            
            if let firstCoreEntry = coreEntries.first {
                // Kalite hesapla
                let totalScore = dayEntries.reduce(0) { $0 + $1.rating }
                let sleepQuality = Double(totalScore) / Double(dayEntries.count)
                
                // Tutarlılık sapması hesapla
                guard let plannedTime = calendar.date(bySettingHour: targetHour, minute: targetMinute, second: 0, of: date) else { continue }
                let consistencyDeviation = abs(firstCoreEntry.startTime.timeIntervalSince(plannedTime)) / 60
                
                // Toplam uyku süresi
                let sleepHours = dayEntries.reduce(0.0) { $0 + $1.duration / 3600.0 }
                
                let qualityConsistencyData = QualityConsistencyData(
                    date: date,
                    sleepQuality: sleepQuality,
                    consistencyDeviation: consistencyDeviation,
                    sleepHours: sleepHours
                )
                
                self.qualityConsistencyData.append(qualityConsistencyData)
            }
        }
        
        // Korelasyon hesapla
        calculateQualityConsistencyCorrelation()
        
        qualityConsistencyData.sort(by: { $0.date < $1.date })
    }
    
    private func calculateQualityConsistencyCorrelation() {
        guard qualityConsistencyData.count > 1 else {
            qualityConsistencyCorrelation = CorrelationStats(slope: 0, intercept: 0, correlation: 0)
            return
        }
        
        let n = Double(qualityConsistencyData.count)
        let sumX = qualityConsistencyData.reduce(0) { $0 + $1.consistencyDeviation }
        let sumY = qualityConsistencyData.reduce(0) { $0 + $1.sleepQuality }
        let sumXY = qualityConsistencyData.reduce(0) { $0 + ($1.consistencyDeviation * $1.sleepQuality) }
        let sumX2 = qualityConsistencyData.reduce(0) { $0 + ($1.consistencyDeviation * $1.consistencyDeviation) }
        let sumY2 = qualityConsistencyData.reduce(0) { $0 + ($1.sleepQuality * $1.sleepQuality) }
        
        let meanX = sumX / n
        let meanY = sumY / n
        
        let numerator = sumXY - (n * meanX * meanY)
        let denominatorX = sumX2 - (n * meanX * meanX)
        let denominatorY = sumY2 - (n * meanY * meanY)
        
        let correlation = denominatorX * denominatorY > 0 ? numerator / sqrt(denominatorX * denominatorY) : 0
        let slope = denominatorX > 0 ? numerator / denominatorX : 0
        let intercept = meanY - (slope * meanX)
        
        qualityConsistencyCorrelation = CorrelationStats(
            slope: slope,
            intercept: intercept,
            correlation: correlation
        )
    }
}

// MARK: - Extensions

extension LocalizedStringKey {
    func toString() -> String {
        return "\(self)"
    }
}

// MARK: - Premium Analytics Data Models

/// Tutarlılık seviyesi
enum ConsistencyLevel: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    
    var localizedTitle: String {
        switch self {
        case .excellent: return L("analytics.consistency.excellent", table: "Analytics")
        case .good: return L("analytics.consistency.good", table: "Analytics")
        case .fair: return L("analytics.consistency.fair", table: "Analytics")
        case .poor: return L("analytics.consistency.poor", table: "Analytics")
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
    
    static func fromScore(_ score: Double) -> ConsistencyLevel {
        switch score {
        case 80...100: return .excellent
        case 60..<80: return .good
        case 40..<60: return .fair
        default: return .poor
        }
    }
}

/// Tutarlılık trendi verileri
struct ConsistencyTrendData: Identifiable {
    let id = UUID()
    let date: Date
    let consistencyScore: Double // 0-100 arası
    let deviation: Double // ± sapma dakika cinsinden
    let plannedTime: Date
    let actualTime: Date
    
    var consistencyLevel: ConsistencyLevel {
        ConsistencyLevel.fromScore(consistencyScore)
    }
    
    var deviationMinutes: Double {
        abs(actualTime.timeIntervalSince(plannedTime)) / 60
    }
}

/// Uyku borcu verileri
struct SleepDebtData: Identifiable {
    let id = UUID()
    let date: Date
    let targetSleep: Double // Hedef uyku süresi (saat)
    let actualSleep: Double // Gerçek uyku süresi (saat)
    let dailyDebt: Double // Günlük borç/fazla (saat)
    let cumulativeDebt: Double // Kümülatif borç/fazla (saat)
    
    var isInDebt: Bool {
        cumulativeDebt > 0
    }
    
    var debtLevel: String {
        switch abs(cumulativeDebt) {
        case 0..<1: return L("analytics.sleepDebt.level.minimal", table: "Analytics")
        case 1..<3: return L("analytics.sleepDebt.level.moderate", table: "Analytics")
        case 3..<6: return L("analytics.sleepDebt.level.significant", table: "Analytics")
        default: return L("analytics.sleepDebt.level.severe", table: "Analytics")
        }
    }
}

/// Kalite-Tutarlılık korelasyon verileri
struct QualityConsistencyData: Identifiable {
    let id = UUID()
    let date: Date
    let sleepQuality: Double // 1-5 arası uyku kalitesi
    let consistencyDeviation: Double // Dakika cinsinden sapma
    let sleepHours: Double // Uyku süresi
    
    var qualityCategory: SleepQualityCategory {
        SleepQualityCategory.fromRating(sleepQuality)
    }
}

/// Korelasyon istatistikleri
struct CorrelationStats {
    let slope: Double // Eğim
    let intercept: Double // Y-kesişim noktası
    let correlation: Double // Korelasyon katsayısı (-1 ile 1 arası)
    
    var correlationStrength: String {
        let absCorrelation = abs(correlation)
        switch absCorrelation {
        case 0.8...1.0: return L("analytics.correlation.veryStrong", table: "Analytics")
        case 0.6..<0.8: return L("analytics.correlation.strong", table: "Analytics")
        case 0.4..<0.6: return L("analytics.correlation.moderate", table: "Analytics")
        case 0.2..<0.4: return L("analytics.correlation.weak", table: "Analytics")
        default: return L("analytics.correlation.veryWeak", table: "Analytics")
        }
    }
}

// MARK: - SleepQualityCategory Extension
extension SleepQualityCategory {
    var localizedTitle: String {
        switch self {
        case .excellent: return L("analytics.quality.excellent", table: "Analytics")
        case .good: return L("analytics.quality.good", table: "Analytics")
        case .average: return L("analytics.quality.average", table: "Analytics")
        case .poor: return L("analytics.quality.poor", table: "Analytics")
        case .bad: return L("analytics.quality.bad", table: "Analytics")
        }
    }
}

// MARK: - Health Data Models

/// Günlük kalp atış hızı verisi
struct DailyHeartRateData: Identifiable {
    let id = UUID()
    let date: Date
    let averageBPM: Double
    let minBPM: Double
    let maxBPM: Double
    let restingBPM: Double?
}

/// Günlük HRV verisi
struct DailyHRVData: Identifiable {
    let id = UUID()
    let date: Date
    let averageSDNN: Double
    let minSDNN: Double
    let maxSDNN: Double
    
    /// HRV recovery score (0-100)
    var recoveryScore: Double {
        // HRV SDNN bazlı recovery skoru
        // 20ms altı: kötü, 20-40: düşük, 40-60: orta, 60-100: iyi, 100+: mükemmel
        let normalized = min(max((averageSDNN - 20) / 80.0, 0), 1.0)
        return normalized * 100
    }
}

/// Uyku düzenlilik verisi
struct SleepRegularityData: Identifiable {
    let id = UUID()
    let date: Date
    let scheduledStartTime: Date?
    let actualStartTime: Date?
    let deviationMinutes: Double
    let totalSleepHours: Double
    let score: Double
}

// MARK: - Adherence Data Models

struct DailyAdherenceData: Identifiable {
    let id = UUID()
    let date: Date
    let adherenceScore: Double // 0-100
    let averageLateness: Double // dakika
    let blocksCompleted: Int
    let blocksMissed: Int
    
    var adherenceLevel: AdherenceLevel {
        AdherenceLevel.fromScore(adherenceScore)
    }
}

struct AdherenceSummary {
    var overallScore: Double = 0
    var averageLateness: Double = 0
    var totalBlocksCompleted: Int = 0
    var totalBlocksMissed: Int = 0
    var adherentDays: Int = 0
    var totalDays: Int = 0
}

enum AdherenceLevel: String {
    case excellent, good, fair, poor
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
    
    static func fromScore(_ score: Double) -> AdherenceLevel {
        switch score {
        case 85...100: return .excellent
        case 65..<85: return .good
        case 40..<65: return .fair
        default: return .poor
        }
    }
}

// MARK: - Sleep Stages Data Model

struct DailySleepStagesData: Identifiable {
    let id = UUID()
    let date: Date
    let remMinutes: Double
    let coreMinutes: Double
    let deepMinutes: Double
    let awakeMinutes: Double
    let totalMinutes: Double
    
    var remPercentage: Double { totalMinutes > 0 ? (remMinutes / totalMinutes) * 100 : 0 }
    var corePercentage: Double { totalMinutes > 0 ? (coreMinutes / totalMinutes) * 100 : 0 }
    var deepPercentage: Double { totalMinutes > 0 ? (deepMinutes / totalMinutes) * 100 : 0 }
    var awakePercentage: Double { totalMinutes > 0 ? (awakeMinutes / totalMinutes) * 100 : 0 }
}
