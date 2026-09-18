import AVFoundation
import Foundation

final class AudioManager {
    static let shared = AudioManager()

    private var players: [String: [AVAudioPlayer]] = [:]
    private var playerGains: [ObjectIdentifier: Float] = [:]
    private var loops: [String: AVAudioPlayer] = [:]
    private var cursors: [String: Int] = [:]
    private var lastPlayTimes: [String: CFTimeInterval] = [:]
    private var durations: [String: TimeInterval] = [:]

    private init() {}

    func duration(named name: String) -> TimeInterval? {
        if let cached = durations[name] {
            return cached
        }
        guard let url = Bundle.module.url(
            forResource: name,
            withExtension: "wav",
            subdirectory: "Resources/Sounds"
        ), let player = loadPlayer(contentsOf: url) else {
            return nil
        }
        if players[name] == nil {
            players[name] = [player]
            playerGains[ObjectIdentifier(player)] = 1.0
            cursors[name] = 0
        }
        durations[name] = player.duration
        return player.duration
    }

    func preloadCommonSounds() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
            guard let self else { return }
            for name in [
                "hammer_hit",
                "glass_shatter",
                "gun_01",
                "gun_02",
                "gun_03",
                "gun_04",
                "punch_hit",
                "creature_hit",
                "metal_hit",
                "explosion",
                "vehicle_explosion",
                "flame_loop",
                "water_spray",
                "saw_loop",
                "nuke_alarm",
                "nuke_detonation"
            ] {
                _ = self.acquirePlayer(named: name)
            }
        }
    }

    @discardableResult
    func play(
        _ name: String,
        gain: Float = 1.0,
        rate: Float = 1.0,
        minimumInterval: TimeInterval = 0
    ) -> Bool {
        if minimumInterval > 0 {
            let now = CFAbsoluteTimeGetCurrent()
            if let last = lastPlayTimes[name], now - last < minimumInterval {
                return false
            }
            lastPlayTimes[name] = now
        }
        guard AppSettings.shared.soundEnabled,
              AppSettings.shared.volume > 0.001,
              let player = acquirePlayer(named: name) else {
            return false
        }
        let gain = min(1.5, max(0, gain))
        player.rate = max(0.25, min(2.0, rate))
        playerGains[ObjectIdentifier(player)] = gain
        player.volume = min(1, max(0, AppSettings.shared.volume * gain))
        player.currentTime = 0
        return player.play()
    }

    func startLoop(_ name: String, gain: Float = 1.0) {
        guard AppSettings.shared.soundEnabled,
              AppSettings.shared.volume > 0.001,
              loops[name] == nil else { return }
        guard let player = acquirePlayer(named: name) else { return }
        let gain = min(1.0, max(0, gain))
        player.numberOfLoops = -1
        playerGains[ObjectIdentifier(player)] = gain
        player.volume = AppSettings.shared.volume * gain
        player.currentTime = 0
        player.play()
        loops[name] = player
    }

    func stopLoop(_ name: String) {
        guard let player = loops.removeValue(forKey: name) else { return }
        fadeOutAndStop(player)
    }

    func stopAllLoops() {
        loops.values.forEach { fadeOutAndStop($0) }
        loops.removeAll()
    }

    func applyVolumeChange() {
        let volume = AppSettings.shared.volume
        for (identifier, gain) in playerGains {
            guard let player = player(from: identifier) else { continue }
            player.volume = min(1, max(0, volume * gain))
        }
    }

    private func acquirePlayer(named name: String) -> AVAudioPlayer? {
        if players[name] == nil {
            players[name] = []
            cursors[name] = 0
        }

        guard var list = players[name] else { return nil }
        if list.isEmpty || list.count < poolSize(for: name) {
            guard let url = Bundle.module.url(
                forResource: name,
                withExtension: "wav",
                subdirectory: "Resources/Sounds"
            ), let player = loadPlayer(contentsOf: url) else {
                PipelineLog.info("missing sound: \(name)")
                return nil
            }
            playerGains[ObjectIdentifier(player)] = 1.0
            list.append(player)
            players[name] = list
            return player
        }

        let cursor = cursors[name] ?? 0
        let player = list[cursor % list.count]
        cursors[name] = (cursor + 1) % list.count
        return player
    }

    private func loadPlayer(contentsOf url: URL) -> AVAudioPlayer? {
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.enableRate = true
        player.prepareToPlay()
        return player
    }

    private func poolSize(for name: String) -> Int {
        switch name {
        case "gun_01", "gun_02", "gun_03", "gun_04",
             "creature_hit", "metal_hit", "punch_hit":
            return 6
        case "flame_loop", "water_spray", "saw_loop":
            return 2
        default:
            return 3
        }
    }

    private func fadeOutAndStop(_ player: AVAudioPlayer) {
        player.setVolume(0, fadeDuration: 0.13)
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { _ in
            player.stop()
        }
    }

    private func player(from identifier: ObjectIdentifier) -> AVAudioPlayer? {
        for list in players.values {
            if let player = list.first(where: { ObjectIdentifier($0) == identifier }) {
                return player
            }
        }
        return loops.values.first { ObjectIdentifier($0) == identifier }
    }
}
