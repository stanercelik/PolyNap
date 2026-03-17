import AVFoundation
import AudioToolbox
import Foundation

enum SoundEffectIntent: Hashable {
    case click
    case success
    case warning
}

@MainActor
final class SoundEffectManager {
    static let shared = SoundEffectManager()

    static let appSoundEffectsEnabledKey = "app_sound_effects_enabled"

    private var players: [SoundEffectIntent: AVAudioPlayer] = [:]
    private var lastPlayDates: [SoundEffectIntent: Date] = [:]

    private let minimumPlayInterval: TimeInterval = 0.06

    private init() {
        preloadPlayers()
    }

    var isEnabled: Bool {
        if UserDefaults.standard.object(forKey: Self.appSoundEffectsEnabledKey) == nil {
            return false
        }
        return UserDefaults.standard.bool(forKey: Self.appSoundEffectsEnabledKey)
    }

    func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Self.appSoundEffectsEnabledKey)
    }

    func play(_ intent: SoundEffectIntent) {
        guard isEnabled else { return }

        let now = Date()
        if let lastPlay = lastPlayDates[intent], now.timeIntervalSince(lastPlay) < minimumPlayInterval {
            return
        }
        lastPlayDates[intent] = now

        if let player = players[intent] {
            player.currentTime = 0
            player.play()
            return
        }

        AudioServicesPlaySystemSound(fallbackSystemSound(for: intent))
    }

    private func preloadPlayers() {
        let candidates: [SoundEffectIntent: [String]] = [
            .click: ["sfx_click", "click"],
            .success: ["sfx_success", "success"],
            .warning: ["sfx_warning", "warning"]
        ]

        for (intent, names) in candidates {
            if let player = makePlayer(from: names) {
                players[intent] = player
            }
        }
    }

    private func makePlayer(from possibleNames: [String]) -> AVAudioPlayer? {
        let extensions = ["wav", "caf", "m4a", "aif", "mp3"]

        for name in possibleNames {
            for fileExt in extensions {
                if let url = Bundle.main.url(forResource: name, withExtension: fileExt),
                   let player = try? AVAudioPlayer(contentsOf: url) {
                    player.volume = 0.55
                    player.prepareToPlay()
                    return player
                }
            }
        }

        return nil
    }

    private func fallbackSystemSound(for intent: SoundEffectIntent) -> SystemSoundID {
        switch intent {
        case .click:
            return 1104
        case .success:
            return 1113
        case .warning:
            return 1053
        }
    }
}
