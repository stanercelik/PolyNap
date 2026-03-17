import Foundation
import UIKit

enum HapticIntent {
    case selection
    case softCommit
    case strongCommit
    case warning
    case success
    case error
    case celebrationPulse
}

@MainActor
final class HapticFeedbackManager {
    static let shared = HapticFeedbackManager()

    static let appHapticsEnabledKey = "app_haptics_enabled"

    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    private var lastSelectionFireDate = Date.distantPast
    private var lastCelebrationFireDate = Date.distantPast

    private let selectionRateLimit: TimeInterval = 0.04
    private let celebrationCooldown: TimeInterval = 8.0

    private init() {
        prepareGenerators()
    }

    var isEnabled: Bool {
        if UserDefaults.standard.object(forKey: Self.appHapticsEnabledKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: Self.appHapticsEnabledKey)
    }

    func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Self.appHapticsEnabledKey)
    }

    func prepareGenerators() {
        selectionFeedback.prepare()
        lightImpact.prepare()
        mediumImpact.prepare()
        rigidImpact.prepare()
        heavyImpact.prepare()
        notificationFeedback.prepare()
    }

    func trigger(_ intent: HapticIntent) {
        guard isEnabled else { return }

        switch intent {
        case .selection:
            let now = Date()
            guard now.timeIntervalSince(lastSelectionFireDate) >= selectionRateLimit else { return }
            lastSelectionFireDate = now
            selectionFeedback.selectionChanged()
            selectionFeedback.prepare()

        case .softCommit:
            lightImpact.impactOccurred()
            lightImpact.prepare()
            SoundEffectManager.shared.play(.click)

        case .strongCommit:
            mediumImpact.impactOccurred()
            mediumImpact.prepare()
            SoundEffectManager.shared.play(.click)

        case .warning:
            rigidImpact.impactOccurred()
            rigidImpact.prepare()
            SoundEffectManager.shared.play(.warning)

        case .success:
            notificationFeedback.notificationOccurred(.success)
            notificationFeedback.prepare()
            SoundEffectManager.shared.play(.success)

        case .error:
            notificationFeedback.notificationOccurred(.error)
            notificationFeedback.prepare()
            SoundEffectManager.shared.play(.warning)

        case .celebrationPulse:
            let now = Date()
            guard now.timeIntervalSince(lastCelebrationFireDate) >= celebrationCooldown else { return }
            lastCelebrationFireDate = now

            lightImpact.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
                self?.mediumImpact.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) { [weak self] in
                self?.notificationFeedback.notificationOccurred(.success)
            }
            SoundEffectManager.shared.play(.success)
        }
    }

    func triggerWarningBoundary() {
        guard isEnabled else { return }
        heavyImpact.impactOccurred()
        heavyImpact.prepare()
    }
}
