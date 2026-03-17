import Foundation
import SwiftData

enum NudgeTone: String, CaseIterable, Codable {
    case supportive
    case direct
    case celebratory
}

enum NudgeCadence: String, CaseIterable, Codable {
    case minimal
    case balanced
    case proactive
}

enum MotivationTrigger: String, CaseIterable, Codable {
    case achievement
    case stability
    case curiosity
    case recovery
}

enum NudgeResponseState: String, CaseIterable, Codable {
    case none
    case accepted
    case snoozed
    case dismissed
    case completed
}

struct OnboardingNudgeProfileInput {
    let chronotype: Chronotype
    let lifestyle: Lifestyle
    let healthStatus: HealthStatus
    let motivationLevel: MotivationLevel
    let sleepGoal: SleepGoal
    let socialObligations: SocialObligations
    let disruptionTolerance: DisruptionTolerance
    let knowledgeLevel: KnowledgeLevel
    let workSchedule: WorkSchedule
    let napEnvironment: NapEnvironment
}

struct BehavioralRecoverySnapshot {
    let score: Double
    let adherence3DayScore: Double
    let quality3DayScore: Double
    let state: RecoveryState

    enum RecoveryState: String {
        case guarded
        case rebuilding
        case stable
    }
}

struct BehavioralNudgePlan {
    let messageKey: String
    let messageArguments: [CVarArg]
    let recommendedAction: String
    let reason: String
    let confidence: Double
    let adjustedLeadTimeMinutes: Int
    let tipKey: String
    let recoverySnapshot: BehavioralRecoverySnapshot
}

enum BehavioralNudgeEngine {
    static let deferredSleepBlocksKey = "deferredSleepBlocks"

    static func bootstrap(preferences: UserPreferences, input: OnboardingNudgeProfileInput) {
        preferences.preferredNudgeTone = preferredTone(from: input).rawValue
        preferences.notificationCadence = preferredCadence(from: input).rawValue
        preferences.motivationTrigger = preferredTrigger(from: input).rawValue
        preferences.lastNudgeResponse = NudgeResponseState.none.rawValue

        let quietHours = defaultQuietHours(for: input.chronotype)
        preferences.quietHoursStartMinutes = quietHours.start
        preferences.quietHoursEndMinutes = quietHours.end
        preferences.fatigueScore = baselineFatigueScore(from: input)
    }

    @MainActor
    static func buildPlan(
        preferences: UserPreferences?,
        historyModels: [HistoryModel],
        baseLeadTimeMinutes: Int,
        scheduleName: String,
        startDate: Date,
        externalRecoverySignal: Double? = nil
    ) -> BehavioralNudgePlan {
        let recovery = recoverySnapshot(
            preferences: preferences,
            historyModels: historyModels,
            externalRecoverySignal: externalRecoverySignal
        )
        let hasDeferredQuality = hasDeferredSleepQuality()
        let averageLateness = averageLatenessMinutes(from: historyModels)

        let tone = preferences?.nudgeTone ?? .supportive
        let cadence = preferences?.nudgeCadence ?? .balanced

        let leadTime = adjustedLeadTime(
            base: baseLeadTimeMinutes,
            cadence: cadence,
            adherenceScore: recovery.adherence3DayScore,
            averageLateness: averageLateness,
            hasDeferredQuality: hasDeferredQuality,
            recoveryScore: recovery.score
        )

        let startTimeFormatted = formatTime(startDate)

        if hasDeferredQuality {
            return BehavioralNudgePlan(
                messageKey: "alarm.sleep.reminder.deferred_quality",
                messageArguments: [startTimeFormatted],
                recommendedAction: "rate_last_sleep",
                reason: "deferred_sleep_quality",
                confidence: 0.94,
                adjustedLeadTimeMinutes: leadTime,
                tipKey: "tip.nudge.deferred_quality",
                recoverySnapshot: recovery
            )
        }

        if recovery.state == .guarded {
            return BehavioralNudgePlan(
                messageKey: "alarm.sleep.reminder.low_recovery",
                messageArguments: [startTimeFormatted],
                recommendedAction: "protect_recovery",
                reason: "low_recovery",
                confidence: 0.88,
                adjustedLeadTimeMinutes: leadTime,
                tipKey: "tip.nudge.recovery",
                recoverySnapshot: recovery
            )
        }

        if averageLateness >= 10 || recovery.adherence3DayScore < 65 {
            let key = tone == .direct
                ? "alarm.sleep.reminder.late.direct"
                : "alarm.sleep.reminder.late.supportive"

            return BehavioralNudgePlan(
                messageKey: key,
                messageArguments: [Int(averageLateness.rounded()), startTimeFormatted],
                recommendedAction: "start_next_block_on_time",
                reason: averageLateness >= 10 ? "recent_lateness" : "low_adherence",
                confidence: 0.83,
                adjustedLeadTimeMinutes: leadTime,
                tipKey: "tip.nudge.catch_up",
                recoverySnapshot: recovery
            )
        }

        let defaultKey: String
        switch tone {
        case .direct:
            defaultKey = "alarm.sleep.reminder.default.direct"
        case .celebratory:
            defaultKey = "alarm.sleep.reminder.default.celebratory"
        case .supportive:
            defaultKey = "alarm.sleep.reminder.default.supportive"
        }

        let tipKey = recovery.adherence3DayScore >= 90
            ? "tip.nudge.consistency"
            : "tip.nudge.default"

        return BehavioralNudgePlan(
            messageKey: defaultKey,
            messageArguments: [scheduleName, startTimeFormatted],
            recommendedAction: "protect_next_block",
            reason: "steady_progress",
            confidence: 0.72,
            adjustedLeadTimeMinutes: leadTime,
            tipKey: tipKey,
            recoverySnapshot: recovery
        )
    }

    @MainActor
    static func dailyTipKey(
        preferences: UserPreferences?,
        modelContext: ModelContext?
    ) -> String {
        guard let modelContext else {
            return "tip.nudge.default"
        }

        let history = recentHistoryModels(context: modelContext, lastDays: 7)
        return buildPlan(
            preferences: preferences,
            historyModels: history,
            baseLeadTimeMinutes: preferences?.reminderLeadTimeInMinutes ?? 15,
            scheduleName: "",
            startDate: Date()
        ).tipKey
    }

    @MainActor
    static func recentHistoryModels(context: ModelContext, lastDays: Int) -> [HistoryModel] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -max(lastDays - 1, 0), to: calendar.startOfDay(for: Date())) ?? Date()

        let descriptor = FetchDescriptor<HistoryModel>(
            predicate: #Predicate<HistoryModel> { model in
                model.date >= startDate
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    static func recoverySnapshot(
        preferences: UserPreferences?,
        historyModels: [HistoryModel],
        externalRecoverySignal: Double? = nil
    ) -> BehavioralRecoverySnapshot {
        let entries = historyModels
            .sorted(by: { $0.date > $1.date })
            .prefix(3)
            .flatMap { $0.sleepEntries ?? [] }

        let recentDays = historyModels
            .sorted(by: { $0.date > $1.date })
            .prefix(3)

        let adherenceDays = recentDays.filter { model in
            (model.sleepEntries ?? []).contains(where: { $0.durationMinutes > 0 })
        }.count
        let adherenceScore = min(100, max(0, Double(adherenceDays) / 3.0 * 100))

        let ratedEntries = entries.filter { $0.rating > 0 }
        let averageQuality = ratedEntries.isEmpty
            ? 3.0
            : ratedEntries.reduce(0.0) { $0 + $1.rating } / Double(ratedEntries.count)
        let qualityScore = min(100, max(0, averageQuality / 5.0 * 100))

        let fatiguePenalty = min(max((preferences?.fatigueScore ?? 0.35) * 100, 0), 100)

        var weightedScore = (adherenceScore * 0.4) + (qualityScore * 0.35) + ((100 - fatiguePenalty) * 0.25)

        if let externalRecoverySignal {
            weightedScore = (weightedScore * 0.7) + (externalRecoverySignal * 0.3)
        }

        let clampedScore = min(100, max(0, weightedScore))
        let state: BehavioralRecoverySnapshot.RecoveryState
        switch clampedScore {
        case ..<45:
            state = .guarded
        case ..<70:
            state = .rebuilding
        default:
            state = .stable
        }

        return BehavioralRecoverySnapshot(
            score: clampedScore,
            adherence3DayScore: adherenceScore,
            quality3DayScore: qualityScore,
            state: state
        )
    }

    @MainActor
    static func hasDeferredSleepQuality() -> Bool {
        let deferred = UserDefaults.standard.stringArray(forKey: deferredSleepBlocksKey) ?? []
        return !deferred.isEmpty
    }

    private static func preferredTone(from input: OnboardingNudgeProfileInput) -> NudgeTone {
        if input.healthStatus == .seriousConditions || input.disruptionTolerance == .verySensitive {
            return .supportive
        }

        if input.motivationLevel == .high && input.knowledgeLevel == .advanced {
            return .direct
        }

        if input.sleepGoal == .curiosity {
            return .celebratory
        }

        return .supportive
    }

    private static func preferredCadence(from input: OnboardingNudgeProfileInput) -> NudgeCadence {
        if input.motivationLevel == .low || input.workSchedule == .shift || input.workSchedule == .irregular {
            return .proactive
        }

        if input.motivationLevel == .high && input.socialObligations == .minimal {
            return .minimal
        }

        return .balanced
    }

    private static func preferredTrigger(from input: OnboardingNudgeProfileInput) -> MotivationTrigger {
        switch input.sleepGoal {
        case .moreProductivity:
            return .achievement
        case .balancedLifestyle, .improveHealth:
            return .stability
        case .curiosity:
            return .curiosity
        }
    }

    private static func defaultQuietHours(for chronotype: Chronotype) -> (start: Int, end: Int) {
        switch chronotype {
        case .nightOwl:
            return (start: 60, end: 9 * 60)
        case .morningLark:
            return (start: 22 * 60, end: 6 * 60)
        case .neutral:
            return (start: 23 * 60, end: 7 * 60)
        }
    }

    private static func baselineFatigueScore(from input: OnboardingNudgeProfileInput) -> Double {
        var score = 0.35

        if input.healthStatus == .seriousConditions {
            score += 0.25
        } else if input.healthStatus == .managedConditions {
            score += 0.15
        }

        if input.lifestyle == .veryActive {
            score += 0.1
        }

        if input.napEnvironment == .limited || input.napEnvironment == .unsuitable {
            score += 0.1
        }

        if input.motivationLevel == .low {
            score += 0.1
        }

        return min(max(score, 0), 1)
    }

    private static func adjustedLeadTime(
        base: Int,
        cadence: NudgeCadence,
        adherenceScore: Double,
        averageLateness: Double,
        hasDeferredQuality: Bool,
        recoveryScore: Double
    ) -> Int {
        var leadTime = max(base, 5)

        switch cadence {
        case .minimal:
            leadTime -= 5
        case .balanced:
            break
        case .proactive:
            leadTime += 5
        }

        if averageLateness >= 10 {
            leadTime += 10
        } else if averageLateness >= 5 {
            leadTime += 5
        }

        if adherenceScore < 65 {
            leadTime += 5
        }

        if hasDeferredQuality || recoveryScore < 45 {
            leadTime += 10
        }

        return min(max(leadTime, 5), 45)
    }

    private static func averageLatenessMinutes(from historyModels: [HistoryModel]) -> Double {
        let recentEntries = historyModels
            .sorted(by: { $0.date > $1.date })
            .prefix(3)
            .flatMap { $0.sleepEntries ?? [] }

        let latenessValues = recentEntries.compactMap { entry -> Double? in
            guard let original = entry.originalScheduledStartTime else { return nil }
            return max(0, entry.startTime.timeIntervalSince(original) / 60)
        }

        guard !latenessValues.isEmpty else { return 0 }
        return latenessValues.reduce(0, +) / Double(latenessValues.count)
    }

    private static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_GB")
        return formatter.string(from: date)
    }
}
