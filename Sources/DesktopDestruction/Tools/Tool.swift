import Foundation

enum Tool: Int, CaseIterable {
    case hammer = 1
    case machineGun = 2
    case saw = 3
    case water = 4
    case flame = 5
    case bomb = 6
    case eraser = 7
    case rocket = 8
    case fist = 9
    case insect = 10
    case person = 11
    case vehicle = 12
    case animal = 13
    case anything = 14

    var name: String {
        switch self {
        case .hammer: return "锤子"
        case .machineGun: return "机枪"
        case .saw: return "电锯"
        case .water: return "水枪"
        case .flame: return "火焰"
        case .bomb: return "炸弹"
        case .eraser: return "橡皮擦"
        case .rocket: return "火箭"
        case .fist: return "拳头"
        case .insect: return "放虫子"
        case .person: return "放小人"
        case .vehicle: return "放车"
        case .animal: return "放动物"
        case .anything: return "任意 emoji"
        }
    }

    var emoji: String {
        switch self {
        case .hammer: return "🔨"
        case .machineGun: return "🔫"
        case .saw: return "🪚"
        case .water: return "💧"
        case .flame: return "🔥"
        case .bomb: return "💣"
        case .eraser: return "🧽"
        case .rocket: return "🚀"
        case .fist: return "👊"
        case .insect: return "🐛"
        case .person: return "🧑"
        case .vehicle: return "🚗"
        case .animal: return "🐾"
        case .anything: return "🎲"
        }
    }

    var assetName: String {
        switch self {
        case .hammer: return "tool-hammer"
        case .machineGun: return "tool-machine-gun"
        case .saw: return "tool-saw"
        case .water: return "tool-water"
        case .flame: return "tool-flame"
        case .bomb: return "tool-bomb"
        case .eraser: return "tool-eraser"
        case .rocket: return "tool-rocket"
        case .fist: return "tool-fist"
        case .insect: return "tool-insect"
        case .person: return "tool-person"
        case .vehicle: return "tool-vehicle"
        case .animal: return "tool-animal"
        case .anything: return "tool-anything"
        }
    }

    var cursorAssetName: String {
        switch self {
        case .machineGun: return "tool-target"
        case .anything: return "tool-sparkle"
        default: return assetName
        }
    }

    var cursorEmoji: String {
        self == .machineGun ? "🎯" : (self == .anything ? "✨" : emoji)
    }
}
