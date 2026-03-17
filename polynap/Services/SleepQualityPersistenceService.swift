import Foundation
import SwiftData

@MainActor
final class SleepQualityPersistenceService {
    static let shared = SleepQualityPersistenceService()

    private let analyticsManager = AnalyticsManager.shared

    private init() {}

    func saveRating(
        rating: Double,
        startTime: Date,
        endTime: Date,
        isCore: Bool,
        blockId: String?,
        source: String
    ) throws {
        guard let context = Repository.shared.getModelContext() else {
            throw RepositoryError.modelContextNotSet
        }

        let entryDate = Calendar.current.startOfDay(for: startTime)
        let durationMinutes = max(Int(endTime.timeIntervalSince(startTime) / 60), 1)
        let emoji = emoji(for: rating)

        let existingEntry = try fetchExistingEntry(
            context: context,
            blockId: blockId,
            startTime: startTime,
            endTime: endTime
        )

        let entry: SleepEntry
        if let existingEntry {
            entry = existingEntry
        } else {
            entry = SleepEntry(
                date: entryDate,
                startTime: startTime,
                endTime: endTime,
                durationMinutes: durationMinutes,
                isCore: isCore,
                blockId: blockId,
                emoji: emoji,
                rating: rating,
                source: source
            )

            let historyModel = try getOrCreateHistoryModel(for: entryDate, context: context)
            entry.historyDay = historyModel
            historyModel.sleepEntries?.append(entry)
            context.insert(entry)
        }

        entry.rating = rating
        entry.emoji = emoji
        entry.source = source
        entry.updatedAt = Date()

        try context.save()

        analyticsManager.logSleepQualityRated(
            rating: rating,
            sleepType: isCore ? "core" : "nap"
        )
        analyticsManager.logNudgeOutcome(
            type: "sleep_quality_prompt",
            outcome: "completed",
            completionDelayMinutes: 0
        )
    }

    private func fetchExistingEntry(
        context: ModelContext,
        blockId: String?,
        startTime: Date,
        endTime: Date
    ) throws -> SleepEntry? {
        let descriptor = FetchDescriptor<SleepEntry>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let allEntries = try context.fetch(descriptor)

        return allEntries.first { entry in
            if let blockId, entry.blockId == blockId {
                return Calendar.current.isDate(entry.startTime, equalTo: startTime, toGranularity: .minute)
            }

            return Calendar.current.isDate(entry.startTime, equalTo: startTime, toGranularity: .minute)
                && Calendar.current.isDate(entry.endTime, equalTo: endTime, toGranularity: .minute)
        }
    }

    private func getOrCreateHistoryModel(for date: Date, context: ModelContext) throws -> HistoryModel {
        let descriptor = FetchDescriptor<HistoryModel>(
            predicate: #Predicate<HistoryModel> { model in
                model.date == date
            }
        )

        if let existingModel = try context.fetch(descriptor).first {
            return existingModel
        }

        let newModel = HistoryModel(date: date)
        context.insert(newModel)
        return newModel
    }

    private func emoji(for rating: Double) -> String {
        switch rating {
        case ..<1.5:
            return "😩"
        case ..<2.5:
            return "😪"
        case ..<3.5:
            return "😐"
        case ..<4.5:
            return "😊"
        default:
            return "😄"
        }
    }
}
