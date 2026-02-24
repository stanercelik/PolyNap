import SwiftUI
import SwiftData

class SleepScheduleViewModel: ObservableObject {
    @Published var schedule: SleepScheduleModel
    @Published private(set) var recommendedSchedule: SleepScheduleModel?
    @Published private(set) var defaultSchedule: SleepScheduleModel
    
    private var recommender: SleepScheduleRecommender?
    private let analyticsManager = AnalyticsManager.shared
    
    init() {
        // Load default biphasic schedule from JSON (or fallback to hardcoded)
        let defaultSchedule = Self.loadDefaultSchedule()
        
        self.defaultSchedule = defaultSchedule
        self.schedule = defaultSchedule
    }
    
    private static func loadDefaultSchedule() -> SleepScheduleModel {
        // Try to load biphasic schedule from JSON first
        if let schedules = loadSleepSchedulesFromJSON(),
           let biphasicSchedule = schedules.first(where: { $0.id == "biphasic" }) {
            return biphasicSchedule
        }
        
        // Fallback to hardcoded simple schedule if JSON loading fails
        let coreBlock = SleepBlock(
            startTime: "23:00",
            duration: 480,
            type: "core",
            isCore: true
        )
        
        return SleepScheduleModel(
            id: "fallback-monophasic",
            name: "Monophasic",
            description: .defaultFallback,
            totalSleepHours: 8.0,
            schedule: [coreBlock]
        )
    }
    
    private static func loadSleepSchedulesFromJSON() -> [SleepScheduleModel]? {
        guard let url = Bundle.main.url(forResource: "SleepSchedules", withExtension: "json") else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let container = try decoder.decode(SleepSchedulesContainer.self, from: data)
            return container.sleepSchedules
        } catch {
            print("Error loading schedules: \(error)")
            return nil
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.recommender = SleepScheduleRecommender()
        Task {
            await updateRecommendations()
        }
    }
    
    func updateRecommendations() async {
        print("\n=== Getting Sleep Schedule Recommendations ===")
        
        guard let recommender = recommender else {
            print("No recommender available")
            return
        }
        
        do {
            guard let recommendation = try await recommender.recommendSchedule() else {
                print("No recommendation available, using default schedule")
                return
            }
            
            self.recommendedSchedule = recommendation.schedule
            
            // İsterseniz warnings'leri yazdırabilirsiniz
            for warning in recommendation.warnings {
                print("Warning (\(warning.severity)): \(warning.messageKey)")
            }
            
            print("Confidence Score: \(recommendation.confidenceScore)")
            print("Adaptation Period: \(recommendation.adaptationPeriod) days")
            
            // İsterseniz otomatik olarak schedule'ı güncelleyebilirsiniz:
            schedule = recommendation.schedule
        } catch {
            print("Error getting recommendations: \(error.localizedDescription)")
        }
    }
    
    func shareSchedule() {
        // TO-DO: Share function
    }
    
    func updateToRecommendedSchedule() {
        if let recommended = recommendedSchedule {
            let previousScheduleName = schedule.name
            schedule = recommended
            
            // 📊 Analytics: Schedule seçimi/değişikliği tracking
            if previousScheduleName != recommended.name {
                analyticsManager.logScheduleChanged(
                    fromSchedule: previousScheduleName,
                    toSchedule: recommended.name,
                    reason: "recommended_schedule_selected"
                )
            }
            
            analyticsManager.logScheduleSelected(
                scheduleName: recommended.name,
                difficulty: determineDifficultyLevel(recommended)
            )
        }
    }
    
    private func determineDifficultyLevel(_ schedule: SleepScheduleModel) -> String {
        schedule.difficulty.rawValue
    }
}
