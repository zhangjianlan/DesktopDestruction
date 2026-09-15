import QuartzCore

typealias ChewShape = DamageRenderer.ChewShape

enum InsectSpecies: CaseIterable {
    case ant
    case caterpillar
    case cricket
    case spider
    case beetle
    case mosquito
    case bee
    case fly
    case ladybug
    case snail
    case cockroach
    case scorpion
    case butterfly
    case worm

    var emoji: String {
        switch self {
        case .ant: return "🐜"
        case .caterpillar: return "🐛"
        case .cricket: return "🦗"
        case .spider: return "🕷️"
        case .beetle: return "🪲"
        case .mosquito: return "🦟"
        case .bee: return "🐝"
        case .fly: return "🪰"
        case .ladybug: return "🐞"
        case .snail: return "🐌"
        case .cockroach: return "🪳"
        case .scorpion: return "🦂"
        case .butterfly: return "🦋"
        case .worm: return "🪱"
        }
    }

    var traits: CreatureTraits {
        switch self {
        case .ant:
            return CreatureTraits(
                speed: 82,
                turnInterval: 0.32,
                turnJitter: 0.45,
                biteInterval: 0.42,
                biteRadius: 4,
                biteShape: .narrow,
                hitRadius: 13,
                bodySize: 26,
                movement: .trail,
                deathRadius: 17
            )
        case .caterpillar:
            return CreatureTraits(
                speed: 20,
                turnInterval: 1.8,
                turnJitter: 1.0,
                biteInterval: 0.92,
                biteRadius: 11,
                biteShape: .leaf,
                hitRadius: 16,
                bodySize: 32,
                movement: .inch,
                deathRadius: 26
            )
        case .cricket:
            return CreatureTraits(
                speed: 145,
                turnInterval: 0.65,
                turnJitter: 1.15,
                biteInterval: 0.75,
                biteRadius: 5,
                biteShape: .nibble,
                hitRadius: 15,
                bodySize: 30,
                movement: .hop,
                deathRadius: 20
            )
        case .spider:
            return CreatureTraits(
                speed: 96,
                turnInterval: 0.45,
                turnJitter: 1.4,
                biteInterval: 1.1,
                biteRadius: 6,
                biteShape: .venom,
                hitRadius: 17,
                bodySize: 32,
                movement: .burst,
                deathRadius: 23,
                leavesTrail: .web
            )
        case .beetle:
            return CreatureTraits(
                speed: 34,
                turnInterval: 2.0,
                turnJitter: 0.8,
                biteInterval: 1.35,
                biteRadius: 9,
                biteShape: .bore,
                hitRadius: 18,
                bodySize: 34,
                movement: .crawl,
                deathRadius: 26
            )
        case .mosquito:
            return CreatureTraits(
                speed: 112,
                turnInterval: 0.14,
                turnJitter: 1.8,
                biteInterval: 0.6,
                biteRadius: 2.5,
                biteShape: .pierce,
                hitRadius: 12,
                bodySize: 26,
                movement: .buzz,
                deathRadius: 15
            )
        case .bee:
            return CreatureTraits(
                speed: 118,
                turnInterval: 0.28,
                turnJitter: 1.35,
                biteInterval: 1.0,
                biteRadius: 4,
                biteShape: .sting,
                hitRadius: 14,
                bodySize: 28,
                movement: .buzz,
                deathRadius: 18,
                leavesTrail: .pollen
            )
        case .fly:
            return CreatureTraits(
                speed: 128,
                turnInterval: 0.1,
                turnJitter: 2.0,
                biteInterval: 0.55,
                biteRadius: 3.5,
                biteShape: .speckle,
                hitRadius: 12,
                bodySize: 26,
                movement: .buzz,
                deathRadius: 16
            )
        case .ladybug:
            return CreatureTraits(
                speed: 44,
                turnInterval: 0.8,
                turnJitter: 1.1,
                biteInterval: 1.5,
                biteRadius: 4,
                biteShape: .nibble,
                hitRadius: 13,
                bodySize: 27,
                movement: .crawl,
                deathRadius: 17
            )
        case .snail:
            return CreatureTraits(
                speed: 9,
                turnInterval: 2.8,
                turnJitter: 0.7,
                biteInterval: 0.85,
                biteRadius: 8,
                biteShape: .rasp,
                hitRadius: 17,
                bodySize: 31,
                movement: .crawl,
                deathRadius: 24,
                leavesTrail: .slime
            )
        case .cockroach:
            return CreatureTraits(
                speed: 125,
                turnInterval: 0.5,
                turnJitter: 1.6,
                biteInterval: 0.48,
                biteRadius: 7,
                biteShape: .graze,
                hitRadius: 18,
                bodySize: 33,
                movement: .dashFreeze,
                deathRadius: 25
            )
        case .scorpion:
            return CreatureTraits(
                speed: 62,
                turnInterval: 0.75,
                turnJitter: 1.0,
                biteInterval: 1.05,
                biteRadius: 5,
                biteShape: .venom,
                hitRadius: 20,
                bodySize: 36,
                movement: .sidestep,
                deathRadius: 27
            )
        case .butterfly:
            return CreatureTraits(
                speed: 68,
                turnInterval: 0.5,
                turnJitter: 1.5,
                biteInterval: 0,
                biteRadius: 0,
                biteShape: .none,
                hitRadius: 14,
                bodySize: 31,
                movement: .flutter,
                deathRadius: 20,
                leavesTrail: .pollen
            )
        case .worm:
            return CreatureTraits(
                speed: 16,
                turnInterval: 1.6,
                turnJitter: 0.8,
                biteInterval: 0.7,
                biteRadius: 6,
                biteShape: .tunnel,
                hitRadius: 15,
                bodySize: 29,
                movement: .burrow,
                deathRadius: 22
            )
        }
    }

    var groupSpawnCount: Int {
        switch self {
        case .ant: return 3
        case .mosquito, .fly: return 2
        default: return 1
        }
    }
}

enum PersonSpecies: CaseIterable {
    case walker
    case runner
    case dancer
    case zombie
    case astronaut
    case wizard
    case hero
    case villain
    case ninja
    case clown

    var emoji: String {
        switch self {
        case .walker: return "🚶"
        case .runner: return "🏃"
        case .dancer: return "💃"
        case .zombie: return "🧟"
        case .astronaut: return "🧑‍🚀"
        case .wizard: return "🧙"
        case .hero: return "🦸"
        case .villain: return "🦹"
        case .ninja: return "🥷"
        case .clown: return "🤡"
        }
    }

    var traits: CreatureTraits {
        switch self {
        case .walker:
            return personTraits(speed: 38, movement: .walk, hitRadius: 34, bodySize: 58)
        case .runner:
            return personTraits(speed: 130, movement: .run, hitRadius: 35, bodySize: 60)
        case .dancer:
            return personTraits(speed: 42, movement: .dance, hitRadius: 33, bodySize: 57)
        case .zombie:
            return personTraits(speed: 30, movement: .chase, hitRadius: 35, bodySize: 60)
        case .astronaut:
            return personTraits(speed: 47, movement: .moonwalk, hitRadius: 36, bodySize: 62)
        case .wizard:
            return personTraits(speed: 33, movement: .walk, hitRadius: 34, bodySize: 59, trail: .magic)
        case .hero:
            return personTraits(speed: 108, movement: .run, hitRadius: 36, bodySize: 61)
        case .villain:
            return personTraits(speed: 74, movement: .dashFreeze, hitRadius: 35, bodySize: 60)
        case .ninja:
            return personTraits(speed: 160, movement: .burst, hitRadius: 33, bodySize: 58)
        case .clown:
            return personTraits(speed: 64, movement: .hop, hitRadius: 35, bodySize: 59)
        }
    }

    private func personTraits(
        speed: CGFloat,
        movement: CreatureMovement,
        hitRadius: CGFloat,
        bodySize: CGFloat,
        trail: CreatureTrail? = nil
    ) -> CreatureTraits {
        CreatureTraits(
            speed: speed,
            turnInterval: 1.2,
            turnJitter: 0.9,
            biteInterval: 0,
            biteRadius: 0,
            biteShape: .none,
            hitRadius: hitRadius,
            bodySize: bodySize,
            movement: movement,
            deathRadius: hitRadius * 2.35,
            leavesTrail: trail
        )
    }
}

enum VehicleSpecies: CaseIterable {
    case car
    case taxi
    case suv
    case bus
    case trolley
    case raceCar
    case policeCar
    case ambulance
    case fireTruck
    case minivan
    case pickup
    case truck
    case semiTruck
    case tractor
    case bicycle
    case scooter
    case motorcycle

    var emoji: String {
        switch self {
        case .car: return "🚗"
        case .taxi: return "🚕"
        case .suv: return "🚙"
        case .bus: return "🚌"
        case .trolley: return "🚎"
        case .raceCar: return "🏎️"
        case .policeCar: return "🚓"
        case .ambulance: return "🚑"
        case .fireTruck: return "🚒"
        case .minivan: return "🚐"
        case .pickup: return "🛻"
        case .truck: return "🚚"
        case .semiTruck: return "🚛"
        case .tractor: return "🚜"
        case .bicycle: return "🚲"
        case .scooter: return "🛴"
        case .motorcycle: return "🏍️"
        }
    }

    var traits: CreatureTraits {
        switch self {
        case .car:
            return vehicleTraits(speed: 175, movement: .drive, hitRadius: 46, bodySize: 94, explosionRadius: 106)
        case .taxi:
            return vehicleTraits(speed: 165, movement: .weave, hitRadius: 46, bodySize: 94, explosionRadius: 104)
        case .suv:
            return vehicleTraits(speed: 150, movement: .drive, hitRadius: 49, bodySize: 100, explosionRadius: 112)
        case .bus:
            return vehicleTraits(speed: 128, movement: .drive, hitRadius: 66, bodySize: 138, explosionRadius: 145)
        case .trolley:
            return vehicleTraits(speed: 112, movement: .drive, hitRadius: 63, bodySize: 132, explosionRadius: 138)
        case .raceCar:
            return vehicleTraits(speed: 315, movement: .speedster, hitRadius: 47, bodySize: 98, explosionRadius: 122)
        case .policeCar:
            return vehicleTraits(speed: 215, movement: .siren, hitRadius: 48, bodySize: 98, explosionRadius: 116)
        case .ambulance:
            return vehicleTraits(speed: 195, movement: .siren, hitRadius: 51, bodySize: 104, explosionRadius: 120)
        case .fireTruck:
            return vehicleTraits(speed: 168, movement: .siren, hitRadius: 62, bodySize: 128, explosionRadius: 134)
        case .minivan:
            return vehicleTraits(speed: 145, movement: .drive, hitRadius: 52, bodySize: 106, explosionRadius: 114)
        case .pickup:
            return vehicleTraits(speed: 155, movement: .drive, hitRadius: 52, bodySize: 108, explosionRadius: 118)
        case .truck:
            return vehicleTraits(speed: 132, movement: .haul, hitRadius: 60, bodySize: 126, explosionRadius: 132)
        case .semiTruck:
            return vehicleTraits(speed: 142, movement: .haul, hitRadius: 69, bodySize: 148, explosionRadius: 150)
        case .tractor:
            return vehicleTraits(speed: 78, movement: .crawl, hitRadius: 54, bodySize: 112, explosionRadius: 124)
        case .bicycle:
            return vehicleTraits(speed: 118, movement: .weave, hitRadius: 38, bodySize: 82, explosionRadius: 82)
        case .scooter:
            return vehicleTraits(speed: 128, movement: .weave, hitRadius: 39, bodySize: 84, explosionRadius: 86)
        case .motorcycle:
            return vehicleTraits(speed: 225, movement: .speedster, hitRadius: 41, bodySize: 88, explosionRadius: 96)
        }
    }

    private func vehicleTraits(
        speed: CGFloat,
        movement: CreatureMovement,
        hitRadius: CGFloat,
        bodySize: CGFloat,
        explosionRadius: CGFloat
    ) -> CreatureTraits {
        CreatureTraits(
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
            explosionRadius: explosionRadius
        )
    }
}

enum CreatureKind {
    case insect(InsectSpecies)
    case person(PersonSpecies)
    case animal(AnimalSpecies)
    case vehicle(VehicleSpecies)
    case anything(EmojiSpecies)

    var traits: CreatureTraits {
        switch self {
        case .insect(let species): return species.traits
        case .person(let species): return species.traits
        case .animal(let species): return species.traits
        case .vehicle(let species): return species.traits
        case .anything(let species): return species.traits
        }
    }

    var isPerson: Bool {
        if case .person = self { return true }
        if case .anything(let species) = self { return species.actorClass == .person }
        return false
    }

    var isInsect: Bool {
        if case .insect = self { return true }
        if case .anything(let species) = self { return species.actorClass == .insect }
        return false
    }

    var isAnimal: Bool {
        if case .animal = self { return true }
        if case .anything(let species) = self { return species.actorClass == .animal }
        return false
    }

    var isVehicle: Bool {
        if case .vehicle = self { return true }
        if case .anything(let species) = self { return species.actorClass == .vehicle }
        return false
    }
}

struct CreatureTraits {
    let speed: CGFloat
    let turnInterval: TimeInterval
    let turnJitter: CGFloat
    let biteInterval: TimeInterval
    let biteRadius: CGFloat
    let biteShape: ChewShape
    let hitRadius: CGFloat
    let bodySize: CGFloat
    let movement: CreatureMovement
    let deathRadius: CGFloat
    var leavesTrail: CreatureTrail?
    var explosionRadius: CGFloat = 0
    var deathEffect: CreatureDeathEffect = .blood
}

enum CreatureMovement {
    case trail
    case inch
    case hop
    case burst
    case crawl
    case buzz
    case dashFreeze
    case sidestep
    case flutter
    case burrow
    case walk
    case run
    case dance
    case chase
    case moonwalk
    case drive
    case weave
    case speedster
    case siren
    case haul
    case swim
    case pounce
    case grazeWalk
    case peckWalk
    case waddle
    case soar
    case lumber
    case slither
    case gallop
    case charge
}

enum CreatureTrail {
    case web
    case pollen
    case slime
    case magic
    case paw
    case feather
    case bubble
}

enum CreatureDeathEffect {
    case blood
    case debris
    case puff
}

final class CreatureActor {
    let id = UUID()
    let kind: CreatureKind
    let layer = CALayer()
    let traits: CreatureTraits
    private(set) var isAlive = true

    private var position: CGPoint
    private var heading: CGFloat
    private var speedFactor: CGFloat = 1
    private var nextTurn = Date()
    private var navigationState: UInt32 = 1
    private var navigationTargetHeading: CGFloat = 0
    private var navigationWaypoint: CGPoint?
    private var navigationPhase: CGFloat = 0
    private var navigationPhaseOffset: CGFloat = 0
    private var nextBite = Date().addingTimeInterval(0.45)
    private var nextTrail = Date().addingTimeInterval(0.2)
    private var nextAction = Date().addingTimeInterval(0.3)
    private var actionActiveUntil: Date?
    private var lastUpdateTime = Date()
    private var cachedTarget: CGPoint?
    private var nextTargetSearch = Date()
    private var burnEmitter: CAEmitterLayer?
    private var burnStartedAt: Date?
    private var burnDuration: TimeInterval = 0

    var isBurning: Bool {
        burnStartedAt != nil
    }

    var currentPosition: CGPoint {
        position
    }

    init(at point: CGPoint, kind: CreatureKind) {
        self.kind = kind
        self.position = point
        self.traits = kind.traits
        var state = UInt32.random(in: 1...UInt32.max)
        heading = Self.nextNavigationValue(&state) * 2 * .pi
        navigationTargetHeading = heading
        navigationPhaseOffset = Self.nextNavigationValue(&state) * 2 * .pi
        navigationState = state
        layer.bounds = CGRect(x: 0, y: 0, width: traits.bodySize, height: traits.bodySize)
        layer.contents = IconRenderer.emoji(kindEmoji, size: traits.bodySize * 0.82)
        layer.contentsScale = 2
        layer.position = point
        layer.zPosition = kind.isVehicle ? 78 : (kind.isAnimal ? 76 : (kind.isPerson ? 73 : 72))
    }

    private var kindEmoji: String {
        switch kind {
        case .insect(let species): return species.emoji
        case .person(let species): return species.emoji
        case .animal(let species): return species.emoji
        case .vehicle(let species): return species.emoji
        case .anything(let species): return species.emoji
        }
    }

    func update(
        now: Date,
        canvas: DestructionCanvas,
        bounds: CGRect,
        threat: CGPoint?,
        others: [CreatureActor]
    ) -> Bool {
        guard isAlive else { return false }
        let dt = min(0.1, max(0.005, now.timeIntervalSince(lastUpdateTime)))
        lastUpdateTime = now
        guard updateBurning(now: now, canvas: canvas) else { return false }
        updateMotion(now: now, dt: dt, bounds: bounds, threat: threat, others: others)
        keepInside(bounds: bounds)
        updateLayer()
        let persistentDamageChance: CGFloat
        switch others.count {
        case ..<90:
            persistentDamageChance = 1
        case ..<150:
            persistentDamageChance = 0.55
        default:
            persistentDamageChance = 0.28
        }
        biteIfReady(now: now, canvas: canvas, chance: persistentDamageChance)
        leaveTrailIfReady(now: now, canvas: canvas, chance: persistentDamageChance)
        return true
    }

    private func updateMotion(
        now: Date,
        dt: TimeInterval,
        bounds: CGRect,
        threat: CGPoint?,
        others: [CreatureActor]
    ) {
        navigationPhase += CGFloat(dt)
        let time = navigationPhase + navigationPhaseOffset

        if navigationWaypoint == nil {
            retargetNavigation(jitter: traits.turnJitter, bounds: bounds, now: now)
        } else if now >= nextTurn {
            retargetNavigation(jitter: traits.turnJitter, bounds: bounds, now: now)
        } else if let waypoint = navigationWaypoint,
                  distance(to: waypoint) < max(16, traits.hitRadius * 0.35),
                  !(kind.isInsect && traits.biteInterval > 0) {
            retargetNavigation(jitter: traits.turnJitter, bounds: bounds, now: now)
        }

        if let waypoint = navigationWaypoint {
            let targetPoint = navigationTargetPoint(around: waypoint, time: time)
            navigationTargetHeading = atan2(targetPoint.y - position.y, targetPoint.x - position.x)
        }

        let headingDelta = shortestAngle(from: heading, to: navigationTargetHeading)
        let maximumTurnRate = max(0.65, min(2.8, traits.turnJitter * 0.55 + 0.5))
        let maximumTurn = maximumTurnRate * CGFloat(dt)
        let turn = min(abs(headingDelta), maximumTurn) * (headingDelta < 0 ? -1 : 1)
        heading = normalizedAngle(heading + turn)

        var speed = traits.speed

        if isBurning {
            if let threat {
                navigationTargetHeading = atan2(position.y - threat.y, position.x - threat.x)
            } else {
                navigationTargetHeading = normalizedAngle(
                    navigationTargetHeading + sin(time * 2.1) * 0.12
                )
            }
            speed *= kind.isPerson ? 1.85 : (kind.isAnimal ? 2.1 : 2.4)
        }

        switch traits.movement {
        case .trail:
            heading += sin(time * 2.7) * 0.03
        case .inch:
            speedFactor = max(0.08, sin(time * 2.2))
            speed *= speedFactor
        case .hop:
            if now >= nextAction {
                nextAction = now.addingTimeInterval(nextNavigationInterval(0.55...1.1))
                actionActiveUntil = now.addingTimeInterval(0.19)
                maybeRetargetNavigation(jitter: 0.6, bounds: bounds, now: now)
            }
            speed *= actionActiveUntil.map { now < $0 } == true ? 2.2 : 0
        case .burst, .run:
            if now >= nextAction {
                nextAction = now.addingTimeInterval(nextNavigationInterval(0.35...0.85))
                actionActiveUntil = now.addingTimeInterval(0.28)
                maybeRetargetNavigation(jitter: 0.35, bounds: bounds, now: now)
            }
            speed *= actionActiveUntil.map { now < $0 } == true ? 1.5 : 0.55
        case .crawl:
            speed *= 0.82 + sin(time * 1.5) * 0.12
        case .buzz:
            heading += sin(time * 7.2) * 0.14
            speed *= 0.75 + abs(sin(time * 7.5)) * 0.45
        case .dashFreeze:
            if let threat, distance(to: threat) < 150 {
                heading = atan2(position.y - threat.y, position.x - threat.x)
                speed *= 2.3
            } else if now >= nextAction {
                nextAction = now.addingTimeInterval(nextNavigationInterval(0.45...1.2))
                actionActiveUntil = now.addingTimeInterval(nextNavigationInterval(0.22...0.38))
                maybeRetargetNavigation(jitter: 0.8, bounds: bounds, now: now)
            }
            speed *= actionActiveUntil.map { now < $0 } == true ? 1.7 : 0
        case .sidestep:
            heading += sin(time * 3.1) * 0.05
            speed *= 0.7 + abs(sin(time * 2.4)) * 0.55
        case .flutter:
            heading = normalizedAngle(navigationTargetHeading + sin(time * 0.8) * 0.35)
            speed *= 0.7 + sin(time * 5.0) * 0.3
        case .burrow:
            layer.opacity = Float(0.22 + abs(sin(time * 1.2)) * 0.55)
            speed *= 0.6 + abs(sin(time * 1.2)) * 0.7
        case .walk:
            speed *= 0.9
        case .dance:
            heading = normalizedAngle(navigationTargetHeading + sin(time * 1.7) * 0.5)
            speed *= 0.55 + abs(cos(time * 2.4)) * 0.45
        case .chase:
            if let target = nearestTarget(in: others, now: now) {
                heading = atan2(target.y - position.y, target.x - position.x)
                speed *= 1.2
            }
        case .moonwalk:
            if now >= nextAction {
                nextAction = now.addingTimeInterval(nextNavigationInterval(0.8...1.5))
                actionActiveUntil = now.addingTimeInterval(0.35)
                maybeRetargetNavigation(jitter: 0.45, bounds: bounds, now: now)
            }
            speed *= actionActiveUntil.map { now < $0 } == true ? 1.6 : 0.3
        case .drive:
            heading += sin(time * 1.1) * 0.012
        case .weave:
            heading += sin(time * 2.5) * 0.055
            speed *= 0.88 + abs(sin(time * 1.8)) * 0.25
        case .speedster:
            heading += sin(time * 3.4) * 0.028
            speed *= 1.02 + abs(sin(time * 4.1)) * 0.1
        case .siren:
            if now >= nextAction {
                nextAction = now.addingTimeInterval(nextNavigationInterval(0.7...1.6))
                actionActiveUntil = now.addingTimeInterval(0.22)
                maybeRetargetNavigation(jitter: 0.12, bounds: bounds, now: now)
            }
            speed *= actionActiveUntil.map { now < $0 } == true ? 1.24 : 0.92
        case .haul:
            heading += sin(time * 0.55) * 0.008
            speed *= 0.94
        case .swim:
            heading += sin(time * 1.9) * 0.055
            speed *= 0.76 + abs(sin(time * 2.4)) * 0.28
        case .pounce:
            if now >= nextAction {
                nextAction = now.addingTimeInterval(nextNavigationInterval(0.5...1.15))
                actionActiveUntil = now.addingTimeInterval(0.24)
                maybeRetargetNavigation(jitter: 0.35, bounds: bounds, now: now)
            }
            speed *= actionActiveUntil.map { now < $0 } == true ? 2.1 : 0.15
        case .grazeWalk:
            speed *= 0.62 + abs(sin(time * 0.7)) * 0.25
        case .peckWalk:
            speed *= 0.48 + abs(sin(time * 3.8)) * 0.35
        case .waddle:
            heading += sin(time * 2.7) * 0.035
            speed *= 0.72 + abs(sin(time * 2.1)) * 0.22
        case .soar:
            heading += sin(time * 1.1) * 0.04
            speed *= 0.88 + abs(sin(time * 1.7)) * 0.18
        case .lumber:
            speed *= 0.58 + abs(sin(time * 0.65)) * 0.24
        case .slither:
            heading += sin(time * 2.9) * 0.09
            speed *= 0.78 + abs(sin(time * 2.3)) * 0.22
        case .gallop:
            speed *= 0.9 + abs(sin(time * 3.6)) * 0.14
        case .charge:
            if now >= nextAction {
                nextAction = now.addingTimeInterval(nextNavigationInterval(0.8...1.7))
                actionActiveUntil = now.addingTimeInterval(0.42)
            }
            speed *= actionActiveUntil.map { now < $0 } == true ? 1.5 : 0.42
        }

        position.x += cos(heading) * speed * CGFloat(dt)
        position.y += sin(heading) * speed * CGFloat(dt)
    }

    private static func nextNavigationValue(_ state: inout UInt32) -> CGFloat {
        state ^= state << 13
        state ^= state >> 17
        state ^= state << 5
        return CGFloat(state) / CGFloat(UInt32.max)
    }

    private func nextNavigationValue() -> CGFloat {
        Self.nextNavigationValue(&navigationState)
    }

    private func nextNavigationInterval(_ range: ClosedRange<TimeInterval>) -> TimeInterval {
        range.lowerBound + (range.upperBound - range.lowerBound) * Double(nextNavigationValue())
    }

    private func retargetNavigation(jitter: CGFloat, bounds: CGRect, now: Date) {
        let turn = (nextNavigationValue() * 2 - 1) * min(jitter, 1.1)
        let direction = normalizedAngle(heading + turn)
        let boundsMargin = traits.hitRadius + 20
        let availableWidth = max(60, bounds.width - boundsMargin * 2)
        let availableHeight = max(60, bounds.height - boundsMargin * 2)
        let travelScale = traits.speed * max(0.8, traits.turnInterval) * (1.2 + nextNavigationValue() * 1.6)
        let maximumTravel = min(720, hypot(availableWidth, availableHeight) * 0.55)
        let travelDistance = max(70, min(maximumTravel, travelScale))
        let target = CGPoint(
            x: position.x + cos(direction) * travelDistance,
            y: position.y + sin(direction) * travelDistance
        )
        navigationWaypoint = CGPoint(
            x: min(max(target.x, bounds.minX + boundsMargin), bounds.maxX - boundsMargin),
            y: min(max(target.y, bounds.minY + boundsMargin), bounds.maxY - boundsMargin)
        )

        let baseInterval = max(1.2, traits.turnInterval * (kind.isVehicle ? 3.0 : 2.4))
        let interval = baseInterval * (0.75 + Double(nextNavigationValue()) * 0.7)
        nextTurn = now.addingTimeInterval(interval)
        navigationTargetHeading = atan2(
            navigationWaypoint!.y - position.y,
            navigationWaypoint!.x - position.x
        )
    }

    private func maybeRetargetNavigation(jitter: CGFloat, bounds: CGRect, now: Date) {
        guard nextNavigationValue() < 0.22 else { return }
        retargetNavigation(jitter: jitter, bounds: bounds, now: now)
    }

    private func navigationTargetPoint(around waypoint: CGPoint, time: CGFloat) -> CGPoint {
        guard kind.isInsect, traits.biteInterval > 0 else { return waypoint }
        let orbitRadius = max(5, min(18, traits.bodySize * 0.2))
        let angle = time * 0.9
        return CGPoint(
            x: waypoint.x + cos(angle) * orbitRadius,
            y: waypoint.y + sin(angle) * orbitRadius
        )
    }

    private func normalizedAngle(_ angle: CGFloat) -> CGFloat {
        let twoPi = 2 * CGFloat.pi
        return angle - twoPi * floor(angle / twoPi)
    }

    private func shortestAngle(from source: CGFloat, to target: CGFloat) -> CGFloat {
        let twoPi = 2 * CGFloat.pi
        var delta = (target - source).truncatingRemainder(dividingBy: twoPi)
        if delta > .pi {
            delta -= twoPi
        }
        if delta < -.pi {
            delta += twoPi
        }
        return delta
    }

    private func nearestTarget(in others: [CreatureActor], now: Date) -> CGPoint? {
        if now < nextTargetSearch {
            return cachedTarget
        }
        nextTargetSearch = now.addingTimeInterval(0.25)
        cachedTarget = nil
        var nearest: (point: CGPoint, distance: CGFloat)?
        for other in others where other.isAlive && other.id != id {
            let target = other.position
            let distance = distance(to: target)
            if distance < 300 && (nearest == nil || distance < nearest!.distance) {
                nearest = (target, distance)
            }
        }
        cachedTarget = nearest?.point
        return cachedTarget
    }

    private func keepInside(bounds: CGRect) {
        let margin = traits.hitRadius * 0.7
        var touchedEdge = false
        if position.x < bounds.minX + margin || position.x > bounds.maxX - margin {
            heading = .pi - heading
            position.x = min(max(position.x, bounds.minX + margin), bounds.maxX - margin)
            touchedEdge = true
        }
        if position.y < bounds.minY + margin || position.y > bounds.maxY - margin {
            heading = -heading
            position.y = min(max(position.y, bounds.minY + margin), bounds.maxY - margin)
            touchedEdge = true
        }
        if touchedEdge {
            navigationWaypoint = nil
            nextTurn = .distantPast
        }
    }

    private func updateLayer() {
        layer.position = position
        if kind.isPerson || kind.isAnimal || kind.isVehicle {
            let facingLeft = cos(heading) < 0
            layer.setAffineTransform(CGAffineTransform(scaleX: facingLeft ? -1 : 1, y: 1))
        } else {
            layer.setAffineTransform(CGAffineTransform(rotationAngle: heading))
        }
    }

    private func biteIfReady(now: Date, canvas: DestructionCanvas, chance: CGFloat) {
        guard traits.biteInterval > 0, traits.biteRadius > 0, now >= nextBite else { return }
        nextBite = now.addingTimeInterval(traits.biteInterval * nextNavigationInterval(0.8...1.2))
        guard CGFloat.random(in: 0...1) < chance else { return }
        let chewCenter = navigationWaypoint ?? position
        let biteJitter = traits.biteRadius * 0.24
        let bitePoint = CGPoint(
            x: chewCenter.x + (nextNavigationValue() * 2 - 1) * biteJitter,
            y: chewCenter.y + (nextNavigationValue() * 2 - 1) * biteJitter
        )
        if let damage = DamageRenderer.renderChewMarks(
            at: bitePoint,
            radius: traits.biteRadius,
            shape: traits.biteShape
        ) {
            canvas.addDamage(image: damage.0, frame: damage.1)
        }
    }

    private func leaveTrailIfReady(now: Date, canvas: DestructionCanvas, chance: CGFloat) {
        guard let trail = traits.leavesTrail, now >= nextTrail else { return }
        nextTrail = now.addingTimeInterval(trail == .slime ? 0.18 : 0.24)
        guard CGFloat.random(in: 0...1) < chance else { return }
        let damage: (CGImage, CGRect)?
        switch trail {
        case .web:
            damage = DamageRenderer.renderWebStrand(at: position, heading: heading)
        case .pollen:
            damage = DamageRenderer.renderPollen(at: position)
        case .slime:
            damage = DamageRenderer.renderSlimeTrail(at: position)
        case .magic:
            damage = DamageRenderer.renderMagicDust(at: position)
        case .paw:
            damage = DamageRenderer.renderPawPrint(at: position, heading: heading)
        case .feather:
            damage = DamageRenderer.renderFeather(at: position, heading: heading)
        case .bubble:
            damage = DamageRenderer.renderBubbleTrail(at: position)
        }
        if let damage {
            canvas.addDamage(image: damage.0, frame: damage.1)
        }
    }

    func hitTest(_ point: CGPoint, radius: CGFloat) -> Bool {
        guard isAlive else { return false }
        let dx = point.x - position.x
        let dy = point.y - position.y
        let availableRadius = radius + traits.hitRadius
        return dx * dx + dy * dy <= availableRadius * availableRadius
    }

    func ignite(now: Date = Date()) {
        guard isAlive, !kind.isVehicle, !isBurning else { return }
        burnDuration = kind.isPerson
            ? Double.random(in: 1.3...1.8)
            : (kind.isAnimal
                ? Double.random(in: 0.75...1.5)
                : (kind.isInsect ? Double.random(in: 0.5...0.85) : Double.random(in: 0.35...0.7)))
        burnStartedAt = now
        burnEmitter = ParticleFactory.creatureFire(attachedTo: layer)
    }

    func extinguish() {
        burnStartedAt = nil
        burnEmitter?.removeFromSuperlayer()
        burnEmitter = nil
    }

    private func updateBurning(now: Date, canvas: DestructionCanvas) -> Bool {
        guard let startedAt = burnStartedAt else { return true }
        guard now.timeIntervalSince(startedAt) < burnDuration else {
            killByFire(canvas: canvas)
            return false
        }
        return true
    }

    private func distance(to point: CGPoint) -> CGFloat {
        let dx = point.x - position.x
        let dy = point.y - position.y
        return sqrt(dx * dx + dy * dy)
    }

    func kill(canvas: DestructionCanvas) {
        guard isAlive else { return }
        isAlive = false
        extinguish()
        playDeathSound(burning: false)
        switch traits.deathEffect {
        case .blood:
            if let blood = DamageRenderer.renderBloodSplat(at: position, radius: traits.deathRadius) {
                canvas.addDamage(image: blood.0, frame: blood.1)
            }
        case .debris:
            if let debris = DamageRenderer.renderScorch(at: position, radius: traits.deathRadius * 0.65) {
                canvas.addDamage(image: debris.0, frame: debris.1)
            }
            ParticleFactory.debris(at: position, count: 12, in: canvas)
        case .puff:
            if let dust = DamageRenderer.renderWetSpot(at: position, radius: traits.deathRadius * 0.5) {
                canvas.addDamage(image: dust.0, frame: dust.1)
            }
            ParticleFactory.dust(at: position, count: 12, in: canvas)
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.opacity = 0.8
        if kind.isPerson || kind.isAnimal {
            layer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat.random(in: -1.1...1.1)))
        } else {
            layer.setAffineTransform(CGAffineTransform(rotationAngle: heading).scaledBy(x: 1.35, y: 0.32))
        }
        CATransaction.commit()

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0.8
        fade.toValue = 0
        fade.duration = kind.isPerson || kind.isAnimal ? 0.34 : 0.22
        fade.fillMode = .forwards
        fade.isRemovedOnCompletion = false
        layer.add(fade, forKey: "creatureDeath")
        canvas.removeAfter(layer, delay: kind.isPerson || kind.isAnimal ? 0.38 : 0.26)
    }

    func killByFire(canvas: DestructionCanvas) {
        guard isAlive else { return }
        isAlive = false
        extinguish()
        playDeathSound(burning: true)
        let scorchRadius = max(
            traits.hitRadius,
            kind.isPerson || kind.isAnimal ? traits.deathRadius * 0.72 : traits.hitRadius
        )
        if let scorch = DamageRenderer.renderScorch(at: position, radius: scorchRadius) {
            canvas.addDamage(image: scorch.0, frame: scorch.1)
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.opacity = 0.9
        if kind.isPerson || kind.isAnimal {
            layer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat.random(in: -1.2...1.2)))
        } else {
            layer.setAffineTransform(
                CGAffineTransform(rotationAngle: heading).scaledBy(x: 1.28, y: 0.38)
            )
        }
        CATransaction.commit()

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0.9
        fade.toValue = 0
        fade.duration = kind.isPerson || kind.isAnimal ? 0.5 : 0.32
        fade.fillMode = .forwards
        fade.isRemovedOnCompletion = false
        layer.add(fade, forKey: "creatureFireDeath")
        canvas.removeAfter(layer, delay: kind.isPerson || kind.isAnimal ? 0.54 : 0.36)
    }

    private func playDeathSound(burning: Bool) {
        guard kind.isPerson || kind.isAnimal else { return }
        if kind.isPerson {
            AudioManager.shared.play(
                burning ? "person_burn_death" : "person_death",
                gain: 0.92,
                rate: Float.random(in: 0.96...1.08),
                minimumInterval: 0.045
            )
            return
        }

        let sizeRate = Float(max(0.68, min(1.25, 84 / traits.bodySize)))
        AudioManager.shared.play(
            burning ? "animal_burn_death" : "animal_death",
            gain: 0.95,
            rate: sizeRate * Float.random(in: 0.96...1.08),
            minimumInterval: 0.045
        )
    }

    func destroy() {
        guard isAlive else { return }
        isAlive = false
        extinguish()
        layer.removeFromSuperlayer()
    }

    func discard() {
        isAlive = false
        extinguish()
        layer.removeFromSuperlayer()
    }
}
