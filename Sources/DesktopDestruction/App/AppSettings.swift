import Foundation

enum ParticleLevel: Int, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2

    var multiplier: CGFloat {
        switch self {
        case .low: return 0.5
        case .medium: return 1.0
        case .high: return 1.7
        }
    }

    var label: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        }
    }
}

final class AppSettings {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let soundEnabled = "DDSoundEnabled"
        static let volume = "DDVolume"
        static let shakeEnabled = "DDShakeEnabled"
        static let particleLevel = "DDParticleLevel"
    }

    var soundEnabled: Bool {
        get {
            if defaults.object(forKey: Key.soundEnabled) == nil { return true }
            return defaults.bool(forKey: Key.soundEnabled)
        }
        set { defaults.set(newValue, forKey: Key.soundEnabled) }
    }

    var volume: Float {
        get {
            if defaults.object(forKey: Key.volume) == nil { return 0.8 }
            return defaults.float(forKey: Key.volume)
        }
        set { defaults.set(newValue, forKey: Key.volume) }
    }

    var shakeEnabled: Bool {
        get {
            if defaults.object(forKey: Key.shakeEnabled) == nil { return true }
            return defaults.bool(forKey: Key.shakeEnabled)
        }
        set { defaults.set(newValue, forKey: Key.shakeEnabled) }
    }

    var particleLevel: ParticleLevel {
        get {
            guard defaults.object(forKey: Key.particleLevel) != nil,
                  let level = ParticleLevel(rawValue: defaults.integer(forKey: Key.particleLevel)) else {
                return .medium
            }
            return level
        }
        set { defaults.set(newValue.rawValue, forKey: Key.particleLevel) }
    }
}
