import CoreGraphics

enum CreatureActionKind: Equatable {
    case idle
    case walk
    case run
    case stalk
    case dance
    case moonwalk
    case hop
    case pounce
    case charge
    case flutter
    case slither
    case swim
    case panic
    case burning
    case bite
    case hit
    case drive
}

struct CreatureActionContext {
    let movement: CreatureMovement
    let actualSpeed: CGFloat
    let baseSpeed: CGFloat
    let isBurning: Bool
    let isPanicking: Bool
    let isZombie: Bool
    let isVehicle: Bool
}

struct CreatureActionSystem {
    private(set) var state: CreatureActionKind = .idle
    private(set) var elapsed: Double = 0

    private var transientState: CreatureActionKind?
    private var transientElapsed: Double = 0
    private var transientDuration: Double = 0

    mutating func update(dt: Double, context: CreatureActionContext) -> CreatureActionKind {
        elapsed += dt

        if let transientState {
            transientElapsed += dt
            if transientElapsed >= transientDuration {
                self.transientState = nil
            } else {
                state = transientState
                return transientState
            }
        }

        let nextState = resolvedAction(for: context)
        if nextState != state {
            state = nextState
            elapsed = 0
        }
        return state
    }

    mutating func begin(_ action: CreatureActionKind, duration: Double) {
        transientState = action
        transientElapsed = 0
        transientDuration = max(0.05, duration)
        state = action
        elapsed = 0
    }

    private func resolvedAction(for context: CreatureActionContext) -> CreatureActionKind {
        if context.isVehicle {
            return .drive
        }
        if context.isBurning {
            return .burning
        }
        if context.isPanicking {
            return .panic
        }

        let stoppedSpeed = max(5, context.baseSpeed * 0.12)
        let canIdle = context.actualSpeed < stoppedSpeed
        switch context.movement {
        case .dance, .drive, .flutter, .slither, .swim:
            break
        default:
            if canIdle {
                return .idle
            }
        }

        switch context.movement {
        case .trail, .inch, .crawl, .sidestep, .burrow, .walk,
             .grazeWalk, .peckWalk, .waddle, .lumber:
            return .walk
        case .burst, .run, .dashFreeze, .gallop:
            return .run
        case .hop:
            return .hop
        case .buzz, .soar, .flutter:
            return .flutter
        case .dance:
            return .dance
        case .chase:
            return context.isZombie ? .stalk : .run
        case .moonwalk:
            return .moonwalk
        case .drive, .weave, .speedster, .siren, .haul:
            return .drive
        case .swim:
            return .swim
        case .pounce:
            return .pounce
        case .slither:
            return .slither
        case .charge:
            return .charge
        }
    }

    func transform(
        heading: CGFloat,
        bodySize: CGFloat,
        rotatesWithHeading: Bool,
        facingLeft: Bool
    ) -> CGAffineTransform {
        let time = CGFloat(elapsed)
        var rotation: CGFloat = 0
        var scaleX: CGFloat = 1
        var scaleY: CGFloat = 1
        var forwardOffset: CGFloat = 0
        var verticalOffset: CGFloat = 0

        switch state {
        case .idle:
            let breath = sin(time * 2.1)
            scaleX = 1 + breath * 0.018
            scaleY = 1 - breath * 0.018
        case .walk:
            let step = sin(time * 5.2)
            rotation = step * 0.045
            scaleX = 1 + step * 0.025
            scaleY = 1 - step * 0.025
            verticalOffset = abs(step) * bodySize * 0.018
        case .run:
            let step = sin(time * 9.4)
            rotation = 0.07 + step * 0.075
            scaleX = 1 + step * 0.045
            scaleY = 1 - step * 0.045
            verticalOffset = abs(step) * bodySize * 0.035
        case .stalk:
            let sway = sin(time * 3.2)
            rotation = sway * 0.085
            scaleX = 1 + sin(time * 2.4) * 0.03
            scaleY = 1 - sin(time * 2.4) * 0.03
            verticalOffset = abs(sway) * bodySize * 0.012
        case .dance:
            let beat = sin(time * 6.4)
            rotation = beat * 0.18
            scaleX = 1 + beat * 0.05
            scaleY = 1 - beat * 0.05
            verticalOffset = abs(sin(time * 12.8)) * bodySize * 0.025
        case .moonwalk:
            let slide = sin(time * 3.8)
            rotation = -0.08 + slide * 0.05
            scaleX = 1 + slide * 0.035
            scaleY = 1 - slide * 0.025
            verticalOffset = abs(slide) * bodySize * 0.018
        case .hop:
            let phase = (sin(time * 7.2) + 1) / 2
            rotation = sin(time * 7.2) * 0.07
            scaleX = 1 - phase * 0.06
            scaleY = 1 + phase * 0.1
            verticalOffset = phase * bodySize * 0.06
        case .pounce:
            let phase = (sin(time * 6.1) + 1) / 2
            rotation = 0.11
            scaleX = 1 + phase * 0.12
            scaleY = 1 - phase * 0.08
            forwardOffset = phase * bodySize * 0.045
        case .charge:
            let rumble = sin(time * 15.5)
            rotation = 0.13 + rumble * 0.025
            scaleX = 1.06
            scaleY = 0.95
            forwardOffset = bodySize * 0.025
        case .flutter:
            let flap = sin(time * 10.8)
            rotation = flap * 0.11
            scaleX = 1 + flap * 0.05
            scaleY = 1 - flap * 0.035
            verticalOffset = sin(time * 5.4) * bodySize * 0.03
        case .slither:
            let wave = sin(time * 5.8)
            rotation = wave * 0.16
            scaleX = 1 + wave * 0.07
            scaleY = 1 - wave * 0.04
            forwardOffset = sin(time * 2.9) * bodySize * 0.02
        case .swim:
            let wave = sin(time * 4.4)
            rotation = wave * 0.1
            scaleX = 1 + wave * 0.045
            scaleY = 1 - wave * 0.03
            verticalOffset = sin(time * 2.2) * bodySize * 0.024
        case .panic:
            let step = sin(time * 14.2)
            rotation = 0.12 + step * 0.1
            scaleX = 1 + step * 0.055
            scaleY = 1 - step * 0.055
            verticalOffset = abs(step) * bodySize * 0.042
        case .burning:
            let flail = sin(time * 18.5)
            rotation = flail * 0.17
            scaleX = 1 + sin(time * 15.2) * 0.055
            scaleY = 1 - sin(time * 15.2) * 0.055
            verticalOffset = sin(time * 13.1) * bodySize * 0.03
        case .bite:
            let phase = min(1, time / 0.24)
            let lunge = sin(phase * .pi)
            rotation = lunge * 0.1
            scaleX = 1 + lunge * 0.13
            scaleY = 1 - lunge * 0.09
            forwardOffset = lunge * bodySize * 0.1
        case .hit:
            let phase = min(1, time / 0.18)
            let recoil = sin(phase * .pi)
            rotation = -recoil * 0.14
            scaleX = 1 - recoil * 0.11
            scaleY = 1 + recoil * 0.09
            forwardOffset = -recoil * bodySize * 0.08
        case .drive:
            let suspension = sin(time * 6.8)
            rotation = suspension * 0.035
            scaleX = 1 + suspension * 0.015
            scaleY = 1 - suspension * 0.025
            verticalOffset = suspension * bodySize * 0.012
        }

        let headingUnitX = rotatesWithHeading ? cos(heading) : (facingLeft ? -1 : 1)
        let headingUnitY = rotatesWithHeading ? sin(heading) : 0
        let translation = CGAffineTransform(
            translationX: headingUnitX * forwardOffset,
            y: headingUnitY * forwardOffset + verticalOffset
        )
        let baseRotation = rotatesWithHeading ? heading + rotation : rotation
        var transform = translation.rotated(by: baseRotation).scaledBy(x: scaleX, y: scaleY)
        if !rotatesWithHeading && facingLeft {
            transform = transform.scaledBy(x: -1, y: 1)
        }
        return transform
    }
}
