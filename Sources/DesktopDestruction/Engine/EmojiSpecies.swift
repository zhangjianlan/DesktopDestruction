import CoreGraphics

enum EmojiActorClass {
    case person
    case animal
    case insect
    case vehicle
    case plant
    case food
    case object
    case symbol
}

struct EmojiSpecies {
    let emoji: String
    let actorClass: EmojiActorClass

    static let showcase: [String] = [
        "🧑", "🏃", "🧟", "🦸", "👻", "👽", "🤖",
        "🐶", "🐱", "🦊", "🐻", "🦈", "🐳", "🦖", "🦄",
        "🐜", "🐝", "🦗", "🕷️", "🪲", "🐌", "🦋", "🪱",
        "🚗", "🚕", "🚌", "🚑", "🚒", "🏎️", "🚚", "🚲", "✈️", "🚀",
        "🌵", "🌳", "🌻", "🍀", "🌸",
        "🍎", "🍕", "🍔", "🍜", "🍩", "🍰", "🍺",
        "💥", "🔥", "💧", "⭐", "🌈", "⚡", "❄️", "🎉",
        "🎸", "🕹️", "💣", "🪓", "🔨", "🧲", "🛸", "🏰"
    ]

    init(emoji: String) {
        self.emoji = emoji
        self.actorClass = Self.classify(emoji)
    }

    static func emojiOptions(in text: String) -> [String] {
        text.compactMap { character in
            guard isEmoji(character) else { return nil }
            return String(character)
        }
    }

    var traits: CreatureTraits {
        if let species = InsectSpecies.allCases.first(where: { $0.emoji == emoji }) {
            return species.traits
        }
        if let species = PersonSpecies.allCases.first(where: { $0.emoji == emoji }) {
            return species.traits
        }
        if let species = AnimalSpecies.all.first(where: { $0.emoji == emoji }) {
            return species.traits
        }
        if let species = VehicleSpecies.allCases.first(where: { $0.emoji == emoji }) {
            return species.traits
        }

        switch actorClass {
        case .person:
            return genericPersonTraits
        case .animal:
            return genericAnimalTraits
        case .insect:
            return genericInsectTraits
        case .vehicle:
            return genericVehicleTraits
        case .plant:
            return CreatureTraits(
                speed: 8,
                turnInterval: 3.2,
                turnJitter: 0.4,
                biteInterval: 0,
                biteRadius: 0,
                biteShape: .none,
                hitRadius: 32,
                bodySize: 70,
                movement: .crawl,
                deathRadius: 46,
                leavesTrail: nil,
                deathEffect: .debris
            )
        case .food:
            return CreatureTraits(
                speed: 24,
                turnInterval: 2.2,
                turnJitter: 0.7,
                biteInterval: 0,
                biteRadius: 0,
                biteShape: .none,
                hitRadius: 28,
                bodySize: 58,
                movement: .crawl,
                deathRadius: 42,
                leavesTrail: nil,
                deathEffect: .puff
            )
        case .object:
            return CreatureTraits(
                speed: 34,
                turnInterval: 1.6,
                turnJitter: 0.85,
                biteInterval: 0,
                biteRadius: 0,
                biteShape: .none,
                hitRadius: 28,
                bodySize: 58,
                movement: .crawl,
                deathRadius: 40,
                leavesTrail: nil,
                deathEffect: .debris
            )
        case .symbol:
            return CreatureTraits(
                speed: 48,
                turnInterval: 0.8,
                turnJitter: 1.2,
                biteInterval: 0,
                biteRadius: 0,
                biteShape: .none,
                hitRadius: 25,
                bodySize: 52,
                movement: .flutter,
                deathRadius: 36,
                leavesTrail: nil,
                deathEffect: .puff
            )
        }
    }

    private var genericPersonTraits: CreatureTraits {
        let scalar = primaryScalar
        let movement: CreatureMovement
        var trail: CreatureTrail?

        switch scalar {
        case 0x1F3C3, 0x1F483, 0x1F6B6, 0x1F46B:
            movement = scalar == 0x1F483 ? .dance : .run
        case 0x1F3CA:
            movement = .swim
        case 0x1F9D8:
            movement = .moonwalk
        case 0x1F9D9:
            movement = .walk
            trail = .magic
        case 0x1F9DA:
            movement = .flutter
        case 0x1F9DB, 0x1F9DF:
            movement = .chase
        case 0x1F9DC:
            movement = .swim
        case 0x1F9B8:
            movement = .run
        case 0x1F9B9:
            movement = .charge
        case 0x1F9CE:
            movement = .crawl
        case 0x1F9CF:
            movement = .dashFreeze
        default:
            movement = .walk
        }

        return CreatureTraits(
            speed: movement == .run ? 126 : 44,
            turnInterval: 1.15,
            turnJitter: 0.9,
            biteInterval: 0,
            biteRadius: 0,
            biteShape: .none,
            hitRadius: 34,
            bodySize: 59,
            movement: movement,
            deathRadius: 80,
            leavesTrail: trail,
            deathEffect: .blood
        )
    }

    private var genericAnimalTraits: CreatureTraits {
        let scalar = primaryScalar
        let movement: CreatureMovement
        let bodySize: CGFloat
        let biteRadius: CGFloat

        switch scalar {
        case 0x1F40E, 0x1F984:
            movement = .gallop
            bodySize = 90
            biteRadius = 10
        case 0x1F981, 0x1F43A:
            movement = .pounce
            bodySize = 88
            biteRadius = 14
        case 0x1F418, 0x1F428, 0x1F42D:
            movement = .lumber
            bodySize = 98
            biteRadius = 16
        case 0x1F426...0x1F42A:
            movement = .soar
            bodySize = 62
            biteRadius = 5
        case 0x1F40C, 0x1F420...0x1F42F, 0x1F980...0x1F9AF:
            movement = .swim
            bodySize = 68
            biteRadius = 7
        case 0x1F40D, 0x1F432:
            movement = .slither
            bodySize = 76
            biteRadius = 9
        case 0x1F412, 0x1F435:
            movement = .burst
            bodySize = 72
            biteRadius = 10
        default:
            movement = .crawl
            bodySize = 72
            biteRadius = 8
        }

        return CreatureTraits(
            speed: movement == .gallop ? 172 : (movement == .pounce ? 138 : 72),
            turnInterval: movement == .soar ? 1.6 : 0.75,
            turnJitter: movement == .lumber ? 0.45 : 0.9,
            biteInterval: 0.8,
            biteRadius: biteRadius,
            biteShape: .nibble,
            hitRadius: bodySize * 0.48,
            bodySize: bodySize,
            movement: movement,
            deathRadius: min(84, max(30, bodySize * 0.84)),
            leavesTrail: movement == .soar ? .feather : nil,
            deathEffect: .blood
        )
    }

    private var genericInsectTraits: CreatureTraits {
        CreatureTraits(
            speed: 84,
            turnInterval: 0.42,
            turnJitter: 1.4,
            biteInterval: 0.65,
            biteRadius: 5,
            biteShape: .nibble,
            hitRadius: 15,
            bodySize: 30,
            movement: .buzz,
            deathRadius: 20,
            leavesTrail: nil,
            deathEffect: .blood
        )
    }

    private var genericVehicleTraits: CreatureTraits {
        let scalar = primaryScalar
        let movement: CreatureMovement
        let speed: CGFloat
        let bodySize: CGFloat

        switch scalar {
        case 0x1F3CE, 0x1F680, 0x1F6F8:
            movement = .speedster
            speed = 285
            bodySize = 96
        case 0x1F682...0x1F689, 0x1F69E, 0x1F69F:
            movement = .drive
            speed = 150
            bodySize = 122
        case 0x1F6B2, 0x1F6F4, 0x1F6FA:
            movement = .weave
            speed = 126
            bodySize = 86
        case 0x1F6A0, 0x1F6A1, 0x1F6A4, 0x1F6E5, 0x1F6F3, 0x1F6F6, 0x26F5:
            movement = .swim
            speed = 132
            bodySize = 110
        case 0x1F681, 0x1F6E9, 0x1F6EB, 0x1F6EC:
            movement = .soar
            speed = 218
            bodySize = 104
        default:
            movement = .drive
            speed = 175
            bodySize = 102
        }

        let hitRadius = bodySize * 0.48
        return CreatureTraits(
            speed: speed,
            turnInterval: 1.5,
            turnJitter: 0.28,
            biteInterval: 0,
            biteRadius: 0,
            biteShape: .none,
            hitRadius: hitRadius,
            bodySize: bodySize,
            movement: movement,
            deathRadius: 0,
            leavesTrail: nil,
            explosionRadius: max(84, bodySize * 1.18),
            deathEffect: .blood
        )
    }

    private var primaryScalar: UInt32 {
        emoji.unicodeScalars.first?.value ?? 0
    }

    private static func isEmoji(_ character: Character) -> Bool {
        character.unicodeScalars.contains { scalar in
            scalar.properties.isEmoji
                || (0x1F000...0x1FAFF).contains(scalar.value)
                || (0x2600...0x27BF).contains(scalar.value)
                || (0x2190...0x21FF).contains(scalar.value)
                || (0x2B00...0x2BFF).contains(scalar.value)
                || (0x1F100...0x1F1FF).contains(scalar.value)
        }
    }

    private static func classify(_ emoji: String) -> EmojiActorClass {
        let values = emoji.unicodeScalars.map(\.value)
        let scalar = values.first ?? 0

        if values.contains(where: personScalars.contains) {
            return .person
        }
        if vehicleScalars.contains(scalar) {
            return .vehicle
        }
        if insectScalars.contains(scalar) {
            return .insect
        }
        if animalRanges.contains(where: { $0.contains(scalar) }) {
            return .animal
        }
        if foodRanges.contains(where: { $0.contains(scalar) }) {
            return .food
        }
        if plantScalars.contains(scalar) {
            return .plant
        }
        if scalar >= 0x1F300 && scalar <= 0x1FAFF {
            return .object
        }
        return .symbol
    }

    private static let personScalars: Set<UInt32> = {
        var scalars = Set<UInt32>([
            0x1F46A, 0x1F46B, 0x1F46C, 0x1F46D, 0x1F47C, 0x1F47D,
            0x1F47F, 0x1F483, 0x1F48F, 0x1F491, 0x1F9B8, 0x1F9B9
        ])
        scalars.formUnion(0x1F466...0x1F469)
        scalars.formUnion(0x1F46E...0x1F478)
        scalars.formUnion(0x1F485...0x1F487)
        scalars.formUnion(0x1F9D1...0x1F9DF)
        scalars.formUnion(0x1F9CD...0x1F9CF)
        return scalars
    }()

    private static let insectScalars: Set<UInt32> = [
        0x1F40C, 0x1F41B, 0x1F41D, 0x1F41E, 0x1F577,
        0x1F98B, 0x1F997, 0x1F99F, 0x1F9A0, 0x1FAB0,
        0x1FAB1, 0x1FAB2, 0x1FAB3
    ]

    private static let vehicleScalars: Set<UInt32> = [
        0x1F3CD, 0x1F3CE, 0x1F681, 0x1F682, 0x1F683, 0x1F684,
        0x1F685, 0x1F686, 0x1F687, 0x1F688, 0x1F689, 0x1F68B,
        0x1F68C, 0x1F68D, 0x1F68E, 0x1F691, 0x1F692, 0x1F693,
        0x1F694, 0x1F695, 0x1F696, 0x1F697, 0x1F698, 0x1F699,
        0x1F69A, 0x1F69B, 0x1F69C, 0x1F69E, 0x1F69F, 0x1F6A0,
        0x1F6A1, 0x1F6A4, 0x1F6B2, 0x1F6E5, 0x1F6E9, 0x1F6EB,
        0x1F6EC, 0x1F6F0, 0x1F6F3, 0x1F6F4, 0x1F6F6, 0x1F6F8,
        0x1F6FA, 0x1F6FB, 0x26F5, 0x2708
    ]

    private static let animalRanges: [ClosedRange<UInt32>] = [
        0x1F400...0x1F43F,
        0x1F980...0x1F9AF,
        0x1FAB0...0x1FABF,
        0x1FAC0...0x1FACF
    ]

    private static let foodRanges: [ClosedRange<UInt32>] = [
        0x1F345...0x1F37F,
        0x1F950...0x1F96F,
        0x1F9C0...0x1F9CB,
        0x1FAD0...0x1FADF
    ]

    private static let plantScalars: Set<UInt32> = [
        0x1F331, 0x1F332, 0x1F333, 0x1F334, 0x1F335,
        0x1F337, 0x1F338, 0x1F339, 0x1F33A, 0x1F33B,
        0x1F33C, 0x1F33D, 0x1F33E, 0x1F33F, 0x1F340,
        0x1F341, 0x1F342, 0x1F343, 0x1F344,
        0x1F38D, 0x1F390, 0x1F391
    ]
}
