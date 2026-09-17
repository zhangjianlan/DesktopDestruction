import AVFoundation
import Foundation

final class AudioManager {
    static let shared = AudioManager()

    private var players: [String: [AVAudioPlayer]] = [:]
    private var loops: [String: AVAudioPlayer] = [:]
    private var cursors: [String: Int] = [:]
    private var lastPlayTimes: [String: CFTimeInterval] = [:]
    private var durations: [String: TimeInterval] = [:]
    private let poolSize = 6

    private init() {}

    func duration(named name: String) -> TimeInterval? {
        if let cached = durations[name] {
            return cached
        }
        guard let url = Bundle.module.url(
            forResource: name,
            withExtension: "wav",
            subdirectory: "Resources/Sounds"
        ), let player = try? AVAudioPlayer(contentsOf: url) else {
            return nil
        }
        durations[name] = player.duration
        return player.duration
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
        guard AppSettings.shared.soundEnabled, let player = acquirePlayer(named: name) else {
            return false
        }
        player.rate = max(0.25, min(2.0, rate))
        player.volume = min(1, max(0, AppSettings.shared.volume * gain))
        player.currentTime = 0
        return player.play()
    }

    func startLoop(_ name: String) {
        guard AppSettings.shared.soundEnabled, loops[name] == nil else { return }
        guard let player = acquirePlayer(named: name) else { return }
        player.numberOfLoops = -1
        player.volume = AppSettings.shared.volume
        player.currentTime = 0
        player.play()
        loops[name] = player
    }

    func stopLoop(_ name: String) {
        loops[name]?.stop()
        loops[name] = nil
    }

    func stopAllLoops() {
        loops.values.forEach { $0.stop() }
        loops.removeAll()
    }

    func applyVolumeChange() {
        let volume = AppSettings.shared.volume
        for playerList in players.values {
            playerList.forEach { $0.volume = volume }
        }
        for player in loops.values {
            player.volume = volume
        }
    }

    private func acquirePlayer(named name: String) -> AVAudioPlayer? {
        if players[name] == nil {
            var list: [AVAudioPlayer] = []
            guard let url = Bundle.module.url(
                forResource: name,
                withExtension: "wav",
                subdirectory: "Resources/Sounds"
            ) else {
                PipelineLog.info("missing sound: \(name)")
                return nil
            }

            for _ in 0..<poolSize {
                if let player = try? AVAudioPlayer(contentsOf: url) {
                    player.enableRate = true
                    player.prepareToPlay()
                    list.append(player)
                }
            }
            players[name] = list
            cursors[name] = 0
        }

        guard let list = players[name], !list.isEmpty else { return nil }
        let cursor = cursors[name] ?? 0
        let player = list[cursor % list.count]
        cursors[name] = (cursor + 1) % list.count
        return player
    }
}
