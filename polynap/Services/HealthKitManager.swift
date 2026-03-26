import Foundation
import HealthKit
import OSLog

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    private let logger = Logger(subsystem: "com.polynap.healthkit", category: "HealthKitManager")
    
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var isHealthDataAvailable: Bool = false
    
    private init() {
        isHealthDataAvailable = HKHealthStore.isHealthDataAvailable()
        Task {
            await checkInitialAuthorizationStatus()
        }
    }
    
    // MARK: - Data Types
    
    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        
        if let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepAnalysisType)
        }
        if let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRateType)
        }
        if let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.insert(hrvType)
        }
        if let restingHRType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(restingHRType)
        }
        
        if types.isEmpty {
            logger.error("Failed to create health data types for reading")
        }
        return types
    }
    
    private var shareTypes: Set<HKSampleType> {
        guard let sleepAnalysisType = HKSampleType.categoryType(forIdentifier: .sleepAnalysis) else {
            logger.error("Failed to create sleep analysis type for sharing")
            return Set()
        }
        return [sleepAnalysisType]
    }
    
    // MARK: - Authorization
    
    private func checkInitialAuthorizationStatus() async {
        guard isHealthDataAvailable else { return }
        
        getAuthorizationStatus { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
            }
        }
    }
    
    func requestAuthorization() async -> Result<Bool, HealthKitError> {
        guard isHealthDataAvailable else {
            logger.error("HealthKit is not available on this device")
            return .failure(.healthKitNotAvailable)
        }
        
        return await withCheckedContinuation { continuation in
            healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { [weak self] (success, error) in
                if let error = error {
                    self?.logger.error("Failed to request HealthKit authorization: \(error.localizedDescription)")
                    continuation.resume(returning: .failure(.requestFailed(error)))
                    return
                }
                
                self?.getAuthorizationStatus { [weak self] status in
                    DispatchQueue.main.async {
                        self?.authorizationStatus = status
                    }
                    
                    switch status {
                    case .sharingAuthorized:
                        self?.logger.info("HealthKit authorization granted")
                        continuation.resume(returning: .success(true))
                    case .sharingDenied:
                        self?.logger.warning("HealthKit authorization denied")
                        continuation.resume(returning: .failure(.authorizationDenied))
                    default:
                        self?.logger.warning("HealthKit authorization status undetermined")
                        continuation.resume(returning: .failure(.authorizationNotDetermined))
                    }
                }
            }
        }
    }
    
    func getAuthorizationStatus(completion: @escaping (HKAuthorizationStatus) -> Void) {
        guard let sleepType = HKSampleType.categoryType(forIdentifier: .sleepAnalysis) else {
            logger.error("Failed to create sleep analysis type for authorization check")
            completion(.notDetermined)
            return
        }
        
        let status = healthStore.authorizationStatus(for: sleepType)
        completion(status)
    }
    
    // MARK: - Sleep Data Writing
    
    func saveSleepAnalysis(
        startDate: Date,
        endDate: Date,
        sleepType: SleepAnalysisType = .asleep
    ) async -> Result<Void, HealthKitError> {
        guard isHealthDataAvailable else {
            return .failure(.healthKitNotAvailable)
        }
        
        guard authorizationStatus == .sharingAuthorized else {
            return .failure(.authorizationDenied)
        }
        
        guard let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            logger.error("Failed to create sleep analysis type")
            return .failure(.invalidDataType)
        }
        
        // Create sleep sample
        let sleepSample = HKCategorySample(
            type: sleepAnalysisType,
            value: sleepType.healthKitValue,
            start: startDate,
            end: endDate
        )
        
        return await withCheckedContinuation { continuation in
            healthStore.save(sleepSample) { [weak self] (success, error) in
                if let error = error {
                    self?.logger.error("Failed to save sleep analysis: \(error.localizedDescription)")
                    continuation.resume(returning: .failure(.saveFailed(error)))
                } else {
                    self?.logger.info("Successfully saved sleep analysis to HealthKit: \(startDate) - \(endDate)")
                    continuation.resume(returning: .success(()))
                }
            }
        }
    }
    
    func saveSleepSession(
        startDate: Date,
        endDate: Date,
        sleepSegments: [SleepSegment]
    ) async -> Result<Void, HealthKitError> {
        guard isHealthDataAvailable else {
            return .failure(.healthKitNotAvailable)
        }
        
        guard authorizationStatus == .sharingAuthorized else {
            return .failure(.authorizationDenied)
        }
        
        guard let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            logger.error("Failed to create sleep analysis type")
            return .failure(.invalidDataType)
        }
        
        var samples: [HKCategorySample] = []
        
        // Create "in bed" sample for the entire session
        let inBedSample = HKCategorySample(
            type: sleepAnalysisType,
            value: HKCategoryValueSleepAnalysis.inBed.rawValue,
            start: startDate,
            end: endDate
        )
        samples.append(inBedSample)
        
        // Create individual sleep segment samples
        for segment in sleepSegments {
            let segmentSample = HKCategorySample(
                type: sleepAnalysisType,
                value: segment.type.healthKitValue,
                start: segment.startDate,
                end: segment.endDate
            )
            samples.append(segmentSample)
        }
        
        return await withCheckedContinuation { continuation in
            healthStore.save(samples) { [weak self] (success, error) in
                if let error = error {
                    self?.logger.error("Failed to save sleep session: \(error.localizedDescription)")
                    continuation.resume(returning: .failure(.saveFailed(error)))
                } else {
                    self?.logger.info("Successfully saved sleep session with \(samples.count) samples to HealthKit")
                    continuation.resume(returning: .success(()))
                }
            }
        }
    }
    
    // MARK: - Sleep Data Reading
    
    func fetchSleepAnalysis(
        startDate: Date,
        endDate: Date
    ) async -> Result<[HealthKitSleepSample], HealthKitError> {
        guard isHealthDataAvailable else {
            return .failure(.healthKitNotAvailable)
        }
        
        guard let sleepType = HKSampleType.categoryType(forIdentifier: .sleepAnalysis) else {
            logger.error("Failed to create sleep analysis type")
            return .failure(.invalidDataType)
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] (query, samples, error) in
                if let error = error {
                    self?.logger.error("Failed to fetch sleep analysis: \(error.localizedDescription)")
                    continuation.resume(returning: .failure(.fetchFailed(error)))
                    return
                }
                
                guard let samples = samples as? [HKCategorySample] else {
                    self?.logger.error("Invalid sample type returned from HealthKit")
                    continuation.resume(returning: .failure(.invalidDataType))
                    return
                }
                
                let healthKitSamples = samples.compactMap { sample -> HealthKitSleepSample? in
                    guard let sleepType = SleepAnalysisType(healthKitValue: sample.value) else {
                        return nil
                    }
                    
                    return HealthKitSleepSample(
                        startDate: sample.startDate,
                        endDate: sample.endDate,
                        type: sleepType,
                        source: sample.sourceRevision.source.name
                    )
                }
                
                self?.logger.info("Successfully fetched \(healthKitSamples.count) sleep samples from HealthKit")
                continuation.resume(returning: .success(healthKitSamples))
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchRecentSleepData(days: Int = 7) async -> Result<[HealthKitSleepSample], HealthKitError> {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        return await fetchSleepAnalysis(startDate: startDate, endDate: endDate)
    }
    
    /// Ham HealthKit segmentlerini gerçek uyku oturumlarına (session) dönüştürür.
    /// Kaynak çakışmalarını giderir ve 30dk boşluk eşiği ile segmentleri birleştirir.
    func fetchSleepSessions(startDate: Date, endDate: Date) async -> Result<[HealthKitSleepSession], HealthKitError> {
        let result = await fetchSleepAnalysis(startDate: startDate, endDate: endDate)
        switch result {
        case .failure(let error):
            return .failure(error)
        case .success(let rawSamples):
            let sessions = buildSleepSessions(from: rawSamples)
            logger.info("Session aggregation: \(rawSamples.count) ham segment → \(sessions.count) oturum")
            return .success(sessions)
        }
    }

    // MARK: - Session Aggregation (private)

    private func buildSleepSessions(from samples: [HealthKitSleepSample]) -> [HealthKitSleepSession] {
        guard !samples.isEmpty else { return [] }

        // Kronolojik sıralama
        let sorted = samples.sorted { $0.startDate < $1.startDate }

        // Ayrıntılı aşama varsa (Watch) generic `asleep`'i dedup et
        let deduplicated = deduplicateStages(in: sorted)

        // 30dk boşluk eşiği ile oturumları grupla
        let gapThreshold: TimeInterval = 30 * 60
        var sessionGroups: [[HealthKitSleepSample]] = []
        var currentGroup: [HealthKitSleepSample] = []

        for sample in deduplicated {
            if currentGroup.isEmpty {
                currentGroup.append(sample)
            } else {
                let lastEnd = currentGroup.max(by: { $0.endDate < $1.endDate })!.endDate
                if sample.startDate.timeIntervalSince(lastEnd) <= gapThreshold {
                    currentGroup.append(sample)
                } else {
                    sessionGroups.append(currentGroup)
                    currentGroup = [sample]
                }
            }
        }
        if !currentGroup.isEmpty {
            sessionGroups.append(currentGroup)
        }

        // Her grup için HealthKitSleepSession oluştur
        var sessions: [HealthKitSleepSession] = []
        for group in sessionGroups {
            // Sadece inBed içeren grupları atla
            let hasActualSleep = group.contains { $0.type != .inBed }
            guard hasActualSleep else { continue }

            // Oturum sınırlarını belirle
            let inBedSamples = group.filter { $0.type == .inBed }
            let nonBedSamples = group.filter { $0.type != .inBed }

            let sessionStart: Date
            let sessionEnd: Date
            if let inBed = inBedSamples.sorted(by: { $0.startDate < $1.startDate }).first {
                sessionStart = inBed.startDate
                let inBedEnd = inBedSamples.max(by: { $0.endDate < $1.endDate })!.endDate
                let lastSampleEnd = nonBedSamples.max(by: { $0.endDate < $1.endDate })?.endDate ?? inBedEnd
                sessionEnd = max(inBedEnd, lastSampleEnd)
            } else {
                sessionStart = nonBedSamples.min(by: { $0.startDate < $1.startDate })!.startDate
                sessionEnd = nonBedSamples.max(by: { $0.endDate < $1.endDate })!.endDate
            }

            // Gerçek uyku süresi: awake ve inBed hariç.
            // Hem iPhone hem Watch aynı aşamaları yazabilir; örtüşen aralıkları
            // birleştirerek her dakikayı yalnızca bir kez say.
            let asleepTypes: Set<SleepAnalysisType> = [.asleep, .core, .deep, .rem]
            let sleepIntervals = group
                .filter { asleepTypes.contains($0.type) }
                .map { ($0.startDate, $0.endDate) }
            let mergedIntervals = mergeIntervals(sleepIntervals)
            let actualSleepSeconds = mergedIntervals.reduce(0.0) { $0 + $1.1.timeIntervalSince($1.0) }
            let actualSleepMinutes = Int(actualSleepSeconds / 60)

            // Minimum 1 dakika uyku olmayan oturumları atla
            guard actualSleepMinutes > 0 else { continue }

            let source = group.first?.source ?? "Unknown"

            sessions.append(HealthKitSleepSession(
                id: UUID(),
                startDate: sessionStart,
                endDate: sessionEnd,
                actualSleepMinutes: actualSleepMinutes,
                source: source,
                stages: group
            ))
        }

        // En yeni oturum önce
        return sessions.sorted { $0.startDate > $1.startDate }
    }

    /// Örtüşen (start, end) aralıklarını birleştirerek her zaman dilimini yalnızca bir kez temsil eden
    /// minimal aralık listesi döndürür. Farklı kaynaklardan gelen çakışan segmentlerde çift sayımı önler.
    private func mergeIntervals(_ intervals: [(Date, Date)]) -> [(Date, Date)] {
        guard !intervals.isEmpty else { return [] }
        let sorted = intervals.sorted { $0.0 < $1.0 }
        var merged: [(Date, Date)] = [sorted[0]]
        for interval in sorted.dropFirst() {
            let last = merged[merged.count - 1]
            if interval.0 <= last.1 {
                // Örtüşme var — bitiş zamanını genişlet
                if interval.1 > last.1 {
                    merged[merged.count - 1] = (last.0, interval.1)
                }
            } else {
                merged.append(interval)
            }
        }
        return merged
    }

    /// Ayrıntılı aşamalar (Core/Deep/REM) ile çakışan generic `asleep` segmentlerini filtreler.
    /// Apple Watch ayrıntılı veri yazarken iPhone da aynı dönem için `asleep` yazar;
    /// bu fonksiyon çift sayımı önler.
    private func deduplicateStages(in samples: [HealthKitSleepSample]) -> [HealthKitSleepSample] {
        let detailedTypes: Set<SleepAnalysisType> = [.core, .deep, .rem]
        let detailedSamples = samples.filter { detailedTypes.contains($0.type) }

        guard !detailedSamples.isEmpty else { return samples }

        return samples.filter { sample in
            guard sample.type == .asleep else { return true }
            // Ayrıntılı bir aşama ile çakışıyorsa bu generic asleep'i at
            let overlaps = detailedSamples.contains { detailed in
                sample.startDate < detailed.endDate && detailed.startDate < sample.endDate
            }
            return !overlaps
        }
    }
    
    // MARK: - Heart Rate Data
    
    func fetchHeartRateData(
        startDate: Date,
        endDate: Date
    ) async -> Result<[HealthKitHeartRateSample], HealthKitError> {
        guard isHealthDataAvailable else {
            return .failure(.healthKitNotAvailable)
        }
        
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return .failure(.invalidDataType)
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] (_, samples, error) in
                if let error = error {
                    self?.logger.error("Failed to fetch heart rate data: \(error.localizedDescription)")
                    continuation.resume(returning: .failure(.fetchFailed(error)))
                    return
                }
                
                guard let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: .success([]))
                    return
                }
                
                let hrSamples = quantitySamples.map { sample in
                    HealthKitHeartRateSample(
                        date: sample.startDate,
                        bpm: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())),
                        source: sample.sourceRevision.source.name
                    )
                }
                
                self?.logger.info("Successfully fetched \(hrSamples.count) heart rate samples")
                continuation.resume(returning: .success(hrSamples))
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - HRV Data
    
    func fetchHRVData(
        startDate: Date,
        endDate: Date
    ) async -> Result<[HealthKitHRVSample], HealthKitError> {
        guard isHealthDataAvailable else {
            return .failure(.healthKitNotAvailable)
        }
        
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return .failure(.invalidDataType)
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] (_, samples, error) in
                if let error = error {
                    self?.logger.error("Failed to fetch HRV data: \(error.localizedDescription)")
                    continuation.resume(returning: .failure(.fetchFailed(error)))
                    return
                }
                
                guard let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: .success([]))
                    return
                }
                
                let hrvSamples = quantitySamples.map { sample in
                    HealthKitHRVSample(
                        date: sample.startDate,
                        sdnn: sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)),
                        source: sample.sourceRevision.source.name
                    )
                }
                
                self?.logger.info("Successfully fetched \(hrvSamples.count) HRV samples")
                continuation.resume(returning: .success(hrvSamples))
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Resting Heart Rate
    
    func fetchRestingHeartRate(
        startDate: Date,
        endDate: Date
    ) async -> Result<[HealthKitHeartRateSample], HealthKitError> {
        guard isHealthDataAvailable else {
            return .failure(.healthKitNotAvailable)
        }
        
        guard let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            return .failure(.invalidDataType)
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: restingHRType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] (_, samples, error) in
                if let error = error {
                    self?.logger.error("Failed to fetch resting heart rate: \(error.localizedDescription)")
                    continuation.resume(returning: .failure(.fetchFailed(error)))
                    return
                }
                
                guard let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: .success([]))
                    return
                }
                
                let hrSamples = quantitySamples.map { sample in
                    HealthKitHeartRateSample(
                        date: sample.startDate,
                        bpm: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())),
                        source: sample.sourceRevision.source.name
                    )
                }
                
                self?.logger.info("Successfully fetched \(hrSamples.count) resting heart rate samples")
                continuation.resume(returning: .success(hrSamples))
            }
            
            healthStore.execute(query)
        }
    }
}

// MARK: - Supporting Types

enum HealthKitError: LocalizedError {
    case healthKitNotAvailable
    case authorizationDenied
    case authorizationNotDetermined
    case requestFailed(Error)
    case saveFailed(Error)
    case fetchFailed(Error)
    case invalidDataType
    
    var errorDescription: String? {
        switch self {
        case .healthKitNotAvailable:
            return "HealthKit bu cihazda kullanılamıyor"
        case .authorizationDenied:
            return "HealthKit erişim izni reddedildi"
        case .authorizationNotDetermined:
            return "HealthKit erişim izni henüz belirlenmedi"
        case .requestFailed(let error):
            return "İzin isteği başarısız: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Veri kaydetme başarısız: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Veri çekme başarısız: \(error.localizedDescription)"
        case .invalidDataType:
            return "Geçersiz veri tipi"
        }
    }
}

enum SleepAnalysisType: String, CaseIterable {
    case inBed
    case asleep
    case awake
    case core
    case deep
    case rem
    
    var healthKitValue: Int {
        switch self {
        case .inBed:
            return HKCategoryValueSleepAnalysis.inBed.rawValue
        case .asleep:
            return HKCategoryValueSleepAnalysis.asleep.rawValue
        case .awake:
            return HKCategoryValueSleepAnalysis.awake.rawValue
        case .core:
            if #available(iOS 16.0, *) {
                return HKCategoryValueSleepAnalysis.asleepCore.rawValue
            } else {
                return HKCategoryValueSleepAnalysis.asleep.rawValue
            }
        case .deep:
            if #available(iOS 16.0, *) {
                return HKCategoryValueSleepAnalysis.asleepDeep.rawValue
            } else {
                return HKCategoryValueSleepAnalysis.asleep.rawValue
            }
        case .rem:
            if #available(iOS 16.0, *) {
                return HKCategoryValueSleepAnalysis.asleepREM.rawValue
            } else {
                return HKCategoryValueSleepAnalysis.asleep.rawValue
            }
        }
    }
    
    init?(healthKitValue: Int) {
        if #available(iOS 16.0, *) {
            switch healthKitValue {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                self = .inBed
            case HKCategoryValueSleepAnalysis.asleep.rawValue:
                self = .asleep
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                self = .awake
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                self = .core
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                self = .deep
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                self = .rem
            default:
                return nil
            }
        } else {
            switch healthKitValue {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                self = .inBed
            case HKCategoryValueSleepAnalysis.asleep.rawValue:
                self = .asleep
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                self = .awake
            default:
                return nil
            }
        }
    }
    
    var displayName: String {
        switch self {
        case .inBed:
            return "Yatakta"
        case .asleep:
            return "Uykuda"
        case .awake:
            return "Uyanık"
        case .core:
            return "Hafif Uyku"
        case .deep:
            return "Derin Uyku"
        case .rem:
            return "REM Uyku"
        }
    }
}

struct HealthKitSleepSample: Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let type: SleepAnalysisType
    let source: String
    var rating: Double? = nil // Kullanıcı tarafından verilen puan
    
    var duration: TimeInterval {
        return endDate.timeIntervalSince(startDate)
    }
    
    var hasRating: Bool {
        return rating != nil
    }
    
    // HealthKit sample'ı için unique identifier
    var healthKitIdentifier: String {
        return "\(startDate.timeIntervalSince1970)_\(endDate.timeIntervalSince1970)_\(type.rawValue)_\(source)"
    }
}

// Birleştirilmiş uyku oturumu (ham segmentlerden oluşturulur)
struct HealthKitSleepSession: Identifiable {
    let id: UUID
    let startDate: Date       // oturumun başlangıcı (inBed veya ilk segment)
    let endDate: Date         // oturumun bitişi (inBed veya son segment)
    let actualSleepMinutes: Int  // sadece asleep aşamaları toplamı (awake ve inBed hariç)
    let source: String
    var rating: Double?
    var stages: [HealthKitSleepSample]  // ham segmentler (Analytics için)

    var duration: TimeInterval {
        return endDate.timeIntervalSince(startDate)
    }

    var hasRating: Bool {
        return rating != nil
    }

    // Persistence için unique identifier
    var healthKitIdentifier: String {
        return "\(startDate.timeIntervalSince1970)_\(endDate.timeIntervalSince1970)_\(source)"
    }
}

struct SleepSegment {
    let startDate: Date
    let endDate: Date
    let type: SleepAnalysisType
    
    var duration: TimeInterval {
        return endDate.timeIntervalSince(startDate)
    }
}

// MARK: - Heart Rate Sample
struct HealthKitHeartRateSample: Identifiable {
    let id = UUID()
    let date: Date
    let bpm: Double
    let source: String
}

// MARK: - HRV Sample
struct HealthKitHRVSample: Identifiable {
    let id = UUID()
    let date: Date
    let sdnn: Double // milliseconds
    let source: String
}