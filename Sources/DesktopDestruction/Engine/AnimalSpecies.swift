import CoreGraphics

struct AnimalSpecies {
    let emoji: String
    let movement: CreatureMovement
    let speed: CGFloat
    let bodySize: CGFloat
    let biteShape: ChewShape
    let biteRadius: CGFloat
    let groupSpawnCount: Int
    let leavesTrail: CreatureTrail?

    static let all: [AnimalSpecies] = [
        .species("🐶", .run, speed: 88, bodySize: 68, biteRadius: 9, trail: .paw),
        .species("🐱", .pounce, speed: 112, bodySize: 66, biteRadius: 8, trail: .paw),
        .species("🐭", .dashFreeze, speed: 104, bodySize: 54, biteRadius: 6, group: 2),
        .species("🐹", .crawl, speed: 62, bodySize: 54, biteRadius: 7),
        .species("🐰", .hop, speed: 126, bodySize: 62, biteRadius: 8, trail: .paw),
        .species("🦊", .pounce, speed: 138, bodySize: 74, biteRadius: 10, trail: .paw),
        .species("🐻", .lumber, speed: 72, bodySize: 96, biteRadius: 14, trail: .paw),
        .species("🐼", .lumber, speed: 58, bodySize: 94, biteRadius: 13, trail: .paw),
        .species("🐨", .crawl, speed: 34, bodySize: 76, biteRadius: 10),
        .species("🐯", .pounce, speed: 148, bodySize: 90, biteRadius: 14, trail: .paw),
        .species("🦁", .pounce, speed: 152, bodySize: 92, biteRadius: 15, trail: .paw),
        .species("🐮", .grazeWalk, speed: 54, bodySize: 88, biteRadius: 12),
        .species("🐷", .grazeWalk, speed: 68, bodySize: 82, biteRadius: 12),
        .species("🐸", .hop, speed: 82, bodySize: 60, biteRadius: 7),
        .species("🐵", .burst, speed: 122, bodySize: 72, biteRadius: 10),
        .species("🙈", .burst, speed: 116, bodySize: 74, biteRadius: 9),
        .species("🙉", .burst, speed: 112, bodySize: 74, biteRadius: 9),
        .species("🙊", .burst, speed: 118, bodySize: 74, biteRadius: 9),
        .species("🐔", .peckWalk, speed: 54, bodySize: 62, biteRadius: 5, group: 2, trail: .paw),
        .species("🐧", .waddle, speed: 46, bodySize: 64, biteRadius: 5, group: 2, trail: .paw),
        .species("🐦", .soar, speed: 118, bodySize: 58, biteRadius: 4, group: 2, trail: .feather),
        .species("🐤", .soar, speed: 92, bodySize: 54, biteRadius: 4, group: 2, trail: .feather),
        .species("🐥", .soar, speed: 94, bodySize: 54, biteRadius: 4, group: 2, trail: .feather),
        .species("🐣", .hop, speed: 46, bodySize: 52, biteRadius: 3, group: 2),
        .species("🦅", .soar, speed: 164, bodySize: 84, biteRadius: 9, trail: .feather),
        .species("🦆", .swim, speed: 88, bodySize: 64, biteRadius: 5, group: 2, trail: .feather),
        .species("🦉", .soar, speed: 104, bodySize: 72, biteRadius: 8, trail: .feather),
        .species("🦇", .flutter, speed: 154, bodySize: 62, group: 2),
        .species("🐺", .run, speed: 158, bodySize: 80, biteRadius: 13, trail: .paw),
        .species("🐗", .charge, speed: 132, bodySize: 82, biteRadius: 13, trail: .paw),
        .species("🐴", .gallop, speed: 178, bodySize: 88, biteRadius: 11, trail: .paw),
        .species("🦄", .gallop, speed: 202, bodySize: 92, biteRadius: 11, trail: .magic),
        .species("🐠", .swim, speed: 74, bodySize: 58, biteRadius: 5, group: 3, trail: .bubble),
        .species("🐟", .swim, speed: 82, bodySize: 60, biteRadius: 5, group: 3, trail: .bubble),
        .species("🐡", .swim, speed: 54, bodySize: 64, biteRadius: 6, trail: .bubble),
        .species("🦈", .swim, speed: 164, bodySize: 112, biteRadius: 16, trail: .bubble),
        .species("🐙", .swim, speed: 62, bodySize: 78, biteRadius: 12, trail: .bubble),
        .species("🦑", .swim, speed: 88, bodySize: 76, biteRadius: 10, trail: .bubble),
        .species("🦐", .swim, speed: 66, bodySize: 58, biteRadius: 5, group: 3, trail: .bubble),
        .species("🦞", .crawl, speed: 58, bodySize: 66, biteRadius: 8, trail: .bubble),
        .species("🦀", .sidestep, speed: 72, bodySize: 62, biteRadius: 7, trail: .bubble),
        .species("🐢", .crawl, speed: 28, bodySize: 68, biteRadius: 8),
        .species("🐍", .slither, speed: 84, bodySize: 78, biteRadius: 10),
        .species("🦎", .dashFreeze, speed: 108, bodySize: 66, biteRadius: 7),
        .species("🦖", .charge, speed: 126, bodySize: 116, biteRadius: 18),
        .species("🦕", .lumber, speed: 72, bodySize: 122, biteRadius: 17),
        .species("🐬", .swim, speed: 142, bodySize: 92, biteRadius: 10, trail: .bubble),
        .species("🐳", .swim, speed: 96, bodySize: 132, biteRadius: 16, trail: .bubble),
        .species("🐋", .swim, speed: 88, bodySize: 134, biteRadius: 16, trail: .bubble),
        .species("🐊", .charge, speed: 108, bodySize: 108, biteRadius: 17, trail: .bubble),
        .species("🐘", .lumber, speed: 64, bodySize: 126, biteRadius: 18, trail: .paw),
        .species("🦛", .lumber, speed: 68, bodySize: 112, biteRadius: 16, trail: .paw),
        .species("🦏", .charge, speed: 124, bodySize: 108, biteRadius: 16, trail: .paw),
        .species("🐪", .grazeWalk, speed: 82, bodySize: 96, biteRadius: 12),
        .species("🐫", .grazeWalk, speed: 84, bodySize: 98, biteRadius: 12),
        .species("🦒", .grazeWalk, speed: 92, bodySize: 112, biteRadius: 13),
        .species("🦓", .run, speed: 148, bodySize: 90, biteRadius: 10, trail: .paw),
        .species("🦭", .swim, speed: 86, bodySize: 88, biteRadius: 12, trail: .bubble),
        .species("🦘", .hop, speed: 146, bodySize: 92, biteRadius: 11, trail: .paw),
        .species("🐃", .charge, speed: 118, bodySize: 102, biteRadius: 14, trail: .paw),
        .species("🐂", .charge, speed: 124, bodySize: 100, biteRadius: 14, trail: .paw),
        .species("🐄", .grazeWalk, speed: 58, bodySize: 92, biteRadius: 12, trail: .paw),
        .species("🐎", .gallop, speed: 188, bodySize: 90, biteRadius: 11, trail: .paw),
        .species("🐖", .grazeWalk, speed: 66, bodySize: 82, biteRadius: 12, trail: .paw),
        .species("🐏", .charge, speed: 116, bodySize: 76, biteRadius: 11, trail: .paw),
        .species("🐑", .grazeWalk, speed: 58, bodySize: 72, biteRadius: 10, group: 2, trail: .paw),
        .species("🦙", .grazeWalk, speed: 68, bodySize: 88, biteRadius: 11),
        .species("🐐", .charge, speed: 112, bodySize: 72, biteRadius: 10, trail: .paw),
        .species("🦌", .gallop, speed: 156, bodySize: 88, biteRadius: 11, trail: .paw),
        .species("🐕", .run, speed: 132, bodySize: 74, biteRadius: 10, trail: .paw),
        .species("🐩", .run, speed: 124, bodySize: 72, biteRadius: 9, trail: .paw),
        .species("🦮", .run, speed: 116, bodySize: 76, biteRadius: 10, trail: .paw),
        .species("🐈", .pounce, speed: 138, bodySize: 70, biteRadius: 9, trail: .paw),
        .species("🐈‍⬛", .pounce, speed: 144, bodySize: 72, biteRadius: 9, trail: .paw),
        .species("🐓", .peckWalk, speed: 62, bodySize: 66, biteRadius: 5),
        .species("🦃", .peckWalk, speed: 58, bodySize: 76, biteRadius: 6, trail: .paw),
        .species("🦚", .soar, speed: 98, bodySize: 78, biteRadius: 7, trail: .feather),
        .species("🦜", .soar, speed: 96, bodySize: 76, biteRadius: 8, trail: .feather),
        .species("🦢", .swim, speed: 78, bodySize: 78, biteRadius: 7, trail: .feather),
        .species("🕊️", .soar, speed: 126, bodySize: 64, biteRadius: 4, group: 2, trail: .feather),
        .species("🦩", .waddle, speed: 62, bodySize: 76, biteRadius: 7, trail: .paw),
        .species("🐦‍⬛", .soar, speed: 132, bodySize: 60, biteRadius: 5, group: 2, trail: .feather),
        .species("🦍", .lumber, speed: 88, bodySize: 100, biteRadius: 14, trail: .paw),
        .species("🦧", .lumber, speed: 84, bodySize: 98, biteRadius: 13, trail: .paw),
        .species("🦣", .lumber, speed: 62, bodySize: 124, biteRadius: 18, trail: .paw),
        .species("🦦", .swim, speed: 118, bodySize: 70, biteRadius: 9, trail: .bubble),
        .species("🦥", .crawl, speed: 28, bodySize: 70, biteRadius: 9),
        .species("🦫", .crawl, speed: 76, bodySize: 74, biteRadius: 14, trail: .paw),
        .species("🦔", .crawl, speed: 54, bodySize: 60, biteRadius: 9),
        .species("🐻‍❄️", .lumber, speed: 132, bodySize: 104, biteRadius: 16, trail: .paw),
        .species("🐇", .hop, speed: 136, bodySize: 64, biteRadius: 8, group: 2, trail: .paw),
        .species("🐁", .dashFreeze, speed: 108, bodySize: 54, biteRadius: 6, group: 2),
        .species("🐀", .dashFreeze, speed: 116, bodySize: 58, biteRadius: 7, group: 2),
        .species("🐿️", .dashFreeze, speed: 132, bodySize: 58, biteRadius: 7, group: 2),
    ]

    static func random() -> AnimalSpecies {
        all.randomElement() ?? all[0]
    }

    var traits: CreatureTraits {
        let hitRadius = bodySize * 0.48
        return CreatureTraits(
            speed: speed,
            turnInterval: movement == .soar ? 1.7 : 0.75,
            turnJitter: movement == .lumber ? 0.45 : 0.9,
            biteInterval: biteRadius > 0 ? 0.8 : 0,
            biteRadius: biteRadius,
            biteShape: biteShape,
            hitRadius: hitRadius,
            bodySize: bodySize,
            movement: movement,
            deathRadius: min(84, max(28, hitRadius * 1.75)),
            leavesTrail: leavesTrail,
            explosionRadius: 0,
            deathEffect: .blood
        )
    }

    private static func species(
        _ emoji: String,
        _ movement: CreatureMovement,
        speed: CGFloat,
        bodySize: CGFloat,
        biteShape: ChewShape = .nibble,
        biteRadius: CGFloat = 7,
        group: Int = 1,
        trail: CreatureTrail? = nil
    ) -> AnimalSpecies {
        AnimalSpecies(
            emoji: emoji,
            movement: movement,
            speed: speed,
            bodySize: bodySize,
            biteShape: biteShape,
            biteRadius: biteRadius,
            groupSpawnCount: group,
            leavesTrail: trail
        )
    }
}
