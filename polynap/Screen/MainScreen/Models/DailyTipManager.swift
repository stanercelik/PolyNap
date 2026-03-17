import Foundation
import SwiftData
import SwiftUI

enum DailyTipManager {
    private static let fallbackTipKeys = [
        "tip.sleep.adaptation",
        "tip.sleep.alertness",
        "tip.sleep.energy",
        "tip.sleep.memory_boost",
        "tip.sleep.natural_wake"
    ]

    @MainActor
    static func getDailyTip(
        preferences: UserPreferences?,
        modelContext: ModelContext?
    ) -> LocalizedStringKey {
        guard let modelContext else {
            return LocalizedStringKey(fallbackTipKeys[0])
        }

        let tipKey = BehavioralNudgeEngine.dailyTipKey(
            preferences: preferences,
            modelContext: modelContext
        )

        return LocalizedStringKey(
            tipKey.isEmpty ? fallbackTipKeys[0] : tipKey
        )
    }
}
