import AppKit
import QuartzCore

enum ParticleFactory {
    private static var multiplier: CGFloat {
        AppSettings.shared.particleLevel.multiplier * PerformanceGovernor.current.particleScale
    }

    static func sparks(at point: CGPoint, count: Int, in canvas: DestructionCanvas) {
        let scaledCount = max(2, Int(CGFloat(count) * multiplier))
        let emitter = burstEmitter(at: point, life: 0.75)
        emitter.zPosition = 92
        let cell = CAEmitterCell()
        cell.contents = ArtAssets.image(named: "effect-spark")
        cell.scale = CGFloat(0.045)
        cell.scaleRange = CGFloat(0.025)
        cell.birthRate = Float(scaledCount)
        cell.lifetime = 0.35
        cell.lifetimeRange = 0.15
        cell.velocity = 230
        cell.velocityRange = 160
        cell.emissionLongitude = .pi / 2
        cell.emissionRange = 2 * .pi
        cell.yAcceleration = -620
        cell.color = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        cell.alphaSpeed = -1.5
        emitter.emitterCells = [cell]
        canvas.addTransient(emitter)
        canvas.removeAfter(emitter, delay: 0.8)
    }

    static func debris(at point: CGPoint, count: Int, in canvas: DestructionCanvas) {
        let scaledCount = max(3, Int(CGFloat(count) * multiplier))
        let emitter = burstEmitter(at: point, life: 1.05)
        emitter.zPosition = 91
        let cell = CAEmitterCell()
        cell.contents = ArtAssets.image(named: "effect-debris")
        cell.scale = CGFloat(0.10)
        cell.scaleRange = CGFloat(0.05)
        cell.birthRate = Float(scaledCount)
        cell.lifetime = 0.72
        cell.lifetimeRange = 0.22
        cell.velocity = 190
        cell.velocityRange = 120
        cell.emissionLongitude = .pi / 2
        cell.emissionRange = 2 * .pi
        cell.yAcceleration = -700
        cell.spin = CGFloat.random(in: -7...7)
        cell.spinRange = 4
        cell.alphaSpeed = -0.9
        emitter.emitterCells = [cell]
        canvas.addTransient(emitter)
        canvas.removeAfter(emitter, delay: 1.1)
    }

    static func glassShards(at point: CGPoint, count: Int, in canvas: DestructionCanvas) {
        let scaledCount = max(5, Int(CGFloat(count) * multiplier))
        let emitter = burstEmitter(at: point, life: 0.95)
        emitter.zPosition = 91
        let cell = CAEmitterCell()
        cell.contents = ArtAssets.image(named: "effect-glass-shard")
        cell.scale = CGFloat(0.075)
        cell.scaleRange = CGFloat(0.035)
        cell.birthRate = Float(scaledCount)
        cell.lifetime = 0.65
        cell.lifetimeRange = 0.25
        cell.velocity = 310
        cell.velocityRange = 180
        cell.emissionRange = 2 * .pi
        cell.yAcceleration = -760
        cell.spin = CGFloat.random(in: -12...12)
        cell.spinRange = 8
        cell.color = CGColor(red: 1, green: 1, blue: 1, alpha: 0.88)
        cell.alphaSpeed = -1.2
        emitter.emitterCells = [cell]
        canvas.addTransient(emitter)
        canvas.removeAfter(emitter, delay: 1)
    }

    static func dust(at point: CGPoint, count: Int, in canvas: DestructionCanvas) {
        let scaledCount = max(2, Int(CGFloat(count) * multiplier))
        let emitter = burstEmitter(at: point, life: 0.8)
        emitter.zPosition = 90
        let cell = CAEmitterCell()
        cell.contents = ArtAssets.image(named: "effect-smoke")
        cell.scale = CGFloat(0.10)
        cell.scaleRange = CGFloat(0.05)
        cell.birthRate = Float(scaledCount)
        cell.lifetime = 0.5
        cell.velocity = 55
        cell.velocityRange = 38
        cell.emissionLongitude = .pi / 2
        cell.emissionRange = 2 * .pi
        cell.yAcceleration = -160
        cell.color = CGColor(red: 1, green: 1, blue: 1, alpha: 0.58)
        cell.alphaSpeed = -0.6
        emitter.emitterCells = [cell]
        canvas.addTransient(emitter)
        canvas.removeAfter(emitter, delay: 0.85)
    }

    static func muzzleFlash(at point: CGPoint, in canvas: DestructionCanvas) {
        let emitter = burstEmitter(at: point, life: 0.15)
        emitter.zPosition = 95
        let cell = CAEmitterCell()
        cell.contents = ArtAssets.image(named: "effect-muzzle-flash")
        cell.scale = CGFloat(0.28)
        cell.scaleRange = CGFloat(0.08)
        cell.birthRate = 22
        cell.lifetime = 0.11
        cell.velocity = 58
        cell.emissionRange = 2 * .pi
        cell.color = CGColor(red: 1, green: 1, blue: 1, alpha: 0.92)
        cell.alphaSpeed = -7
        emitter.emitterCells = [cell]
        canvas.addTransient(emitter)
        canvas.removeAfter(emitter, delay: 0.22)
    }

    static func creatureHit(at point: CGPoint, isVehicle: Bool, in canvas: DestructionCanvas) {
        let emitter = burstEmitter(at: point, life: 0.34)
        emitter.zPosition = 96
        let cell = CAEmitterCell()
        cell.contents = ArtAssets.image(named: "effect-spark")
        cell.scale = isVehicle ? 0.045 : 0.032
        cell.scaleRange = 0.016
        cell.birthRate = Float(max(5, Int(9 * multiplier)))
        cell.lifetime = 0.19
        cell.lifetimeRange = 0.08
        cell.velocity = isVehicle ? 285 : 190
        cell.velocityRange = 85
        cell.emissionRange = 2 * .pi
        cell.yAcceleration = isVehicle ? -520 : -700
        cell.color = isVehicle
            ? CGColor(red: 1, green: 0.72, blue: 0.28, alpha: 1)
            : CGColor(red: 0.82, green: 0.06, blue: 0.08, alpha: 1)
        cell.alphaSpeed = -3.2
        emitter.emitterCells = [cell]
        canvas.addTransient(emitter)
        canvas.removeAfter(emitter, delay: 0.38)
    }

    static func bloodSpray(at point: CGPoint, count: Int, in canvas: DestructionCanvas) {
        let emitter = burstEmitter(at: point, life: 0.48)
        emitter.zPosition = 96
        let cell = CAEmitterCell()
        cell.contents = ArtAssets.image(named: "effect-spark")
        cell.scale = 0.038
        cell.scaleRange = 0.018
        cell.birthRate = Float(max(5, Int(CGFloat(count) * multiplier)))
        cell.lifetime = 0.29
        cell.lifetimeRange = 0.12
        cell.velocity = 245
        cell.velocityRange = 115
        cell.emissionRange = 2 * .pi
        cell.yAcceleration = -620
        cell.color = CGColor(red: 0.68, green: 0.03, blue: 0.05, alpha: 1)
        cell.alphaSpeed = -2.1
        emitter.emitterCells = [cell]
        canvas.addTransient(emitter)
        canvas.removeAfter(emitter, delay: 0.52)
    }

    static func waterStream(at point: CGPoint, direction: CGPoint, in canvas: DestructionCanvas) -> CAEmitterLayer {
        let emitter = streamEmitter(at: point)
        let stream = CAEmitterCell()
        stream.contents = ArtAssets.image(named: "effect-water-drop")
        stream.scale = CGFloat(0.055)
        stream.scaleRange = CGFloat(0.018)
        stream.birthRate = 92
        stream.lifetime = 0.82
        stream.velocity = 500
        stream.velocityRange = 65
        stream.emissionLongitude = emissionAngle(direction)
        stream.emissionRange = 0.13
        stream.yAcceleration = -700
        stream.color = CGColor(red: 1, green: 1, blue: 1, alpha: 0.9)
        stream.alphaSpeed = -0.8

        let mist = CAEmitterCell()
        mist.contents = ArtAssets.image(named: "effect-steam")
        mist.scale = CGFloat(0.13)
        mist.scaleSpeed = CGFloat(0.5)
        mist.birthRate = 26
        mist.lifetime = 0.45
        mist.velocity = 190
        mist.velocityRange = 45
        mist.emissionLongitude = emissionAngle(direction)
        mist.emissionRange = 0.38
        mist.color = CGColor(red: 1, green: 1, blue: 1, alpha: 0.38)
        mist.alphaSpeed = -1.1
        emitter.emitterCells = [stream, mist]
        canvas.addTransient(emitter)
        return emitter
    }

    static func flameStream(at point: CGPoint, direction: CGPoint, in canvas: DestructionCanvas) -> CAEmitterLayer {
        let emitter = streamEmitter(at: point)
        let fire = CAEmitterCell()
        fire.contents = ArtAssets.image(named: "effect-fire")
        fire.scale = CGFloat(0.18)
        fire.scaleRange = CGFloat(0.05)
        fire.scaleSpeed = CGFloat(1.0)
        fire.birthRate = 44
        fire.lifetime = 0.42
        fire.velocity = 310
        fire.velocityRange = 55
        fire.emissionLongitude = emissionAngle(direction)
        fire.emissionRange = 0.35
        fire.yAcceleration = -380
        fire.color = CGColor(red: 1, green: 1, blue: 1, alpha: 0.92)
        fire.alphaSpeed = -1.7

        let smoke = CAEmitterCell()
        smoke.contents = ArtAssets.image(named: "effect-smoke")
        smoke.scale = CGFloat(0.20)
        smoke.scaleSpeed = CGFloat(0.65)
        smoke.birthRate = 16
        smoke.lifetime = 0.85
        smoke.velocity = 160
        smoke.emissionLongitude = emissionAngle(direction)
        smoke.emissionRange = 0.5
        smoke.yAcceleration = -180
        smoke.color = CGColor(red: 1, green: 1, blue: 1, alpha: 0.36)
        smoke.alphaSpeed = -0.35
        emitter.emitterCells = [fire, smoke]
        canvas.addTransient(emitter)
        return emitter
    }

    static func lingeringFire(at point: CGPoint, intensity: CGFloat, in canvas: DestructionCanvas) -> CAEmitterLayer {
        let emitter = streamEmitter(at: point)
        emitter.zPosition = 66
        emitter.emitterSize = CGSize(width: 18, height: 8)
        let fireScale = PerformanceGovernor.current.fireScale

        let core = CAEmitterCell()
        core.contents = ArtAssets.image(named: "effect-fire")
        core.scale = 0.10 * intensity
        core.scaleRange = 0.025
        core.scaleSpeed = 0.75
        core.birthRate = 20 * Float(intensity * fireScale)
        core.lifetime = 0.31
        core.lifetimeRange = 0.1
        core.velocity = 55
        core.velocityRange = 24
        core.emissionLongitude = .pi / 2
        core.emissionRange = 0.45
        core.yAcceleration = -105
        core.color = CGColor(red: 1, green: 1, blue: 1, alpha: 0.96)
        core.alphaSpeed = -1.3

        let fire = CAEmitterCell()
        fire.contents = ArtAssets.image(named: "effect-fire")
        fire.scale = 0.14 * intensity
        fire.scaleRange = 0.04
        fire.scaleSpeed = 0.48
        fire.birthRate = 34 * Float(intensity * fireScale)
        fire.lifetime = 0.62
        fire.lifetimeRange = 0.22
        fire.velocity = 68
        fire.velocityRange = 30
        fire.emissionLongitude = .pi / 2
        fire.emissionRange = 0.72
        fire.yAcceleration = -120
        fire.color = CGColor(red: 1, green: 1, blue: 1, alpha: 0.92)
        fire.alphaSpeed = -1.15

        let smoke = CAEmitterCell()
        smoke.contents = ArtAssets.image(named: "effect-smoke")
        smoke.scale = 0.16
        smoke.scaleSpeed = 0.68
        smoke.birthRate = 12 * Float(fireScale)
        smoke.lifetime = 1.25
        smoke.velocity = 30
        smoke.emissionLongitude = .pi / 2
        smoke.emissionRange = 0.8
        smoke.yAcceleration = -65
        smoke.color = CGColor(red: 1, green: 1, blue: 1, alpha: 0.30)
        smoke.alphaSpeed = -0.24

        let ember = CAEmitterCell()
        ember.contents = ArtAssets.image(named: "effect-spark")
        ember.scale = 0.022
        ember.scaleRange = 0.008
        ember.birthRate = 9 * Float(fireScale)
        ember.lifetime = 0.85
        ember.velocity = 125
        ember.velocityRange = 45
        ember.emissionLongitude = .pi / 2
        ember.emissionRange = 0.45
        ember.yAcceleration = -170
        ember.color = CGColor(red: 1, green: 1, blue: 1, alpha: 0.95)
        ember.alphaSpeed = -1.05

        emitter.emitterCells = [fire, smoke, core, ember]
        canvas.addTransient(emitter)
        return emitter
    }

    static func sawSparks(at point: CGPoint, direction: CGPoint, in canvas: DestructionCanvas) -> CAEmitterLayer {
        let emitter = streamEmitter(at: point)
        let cell = CAEmitterCell()
        cell.contents = ArtAssets.image(named: "effect-spark")
        cell.scale = CGFloat(0.035)
        cell.scaleRange = CGFloat(0.015)
        cell.birthRate = 68
        cell.lifetime = 0.28
        cell.velocity = 250
        cell.velocityRange = 80
        cell.emissionLongitude = emissionAngle(direction) + .pi
        cell.emissionRange = 1.0
        cell.yAcceleration = -620
        cell.color = CGColor(red: 1, green: 1, blue: 1, alpha: 0.9)
        cell.alphaSpeed = -2.4
        emitter.emitterCells = [cell]
        canvas.addTransient(emitter)
        return emitter
    }

    static func creatureFire(attachedTo layer: CALayer) -> CAEmitterLayer {
        let emitter = CAEmitterLayer()
        emitter.position = CGPoint(x: layer.bounds.midX, y: layer.bounds.midY)
        emitter.emitterSize = CGSize(
            width: min(26, max(8, layer.bounds.width * 0.36)),
            height: min(16, max(6, layer.bounds.height * 0.28))
        )
        emitter.emitterShape = .circle
        emitter.renderMode = .unordered
        emitter.zPosition = 4
        let fireScale = PerformanceGovernor.current.creatureFireScale

        let fire = CAEmitterCell()
        fire.contents = ArtAssets.image(named: "effect-fire")
        fire.scale = CGFloat(0.06)
        fire.scaleRange = CGFloat(0.02)
        fire.scaleSpeed = CGFloat(0.36)
        fire.birthRate = 42 * Float(fireScale)
        fire.lifetime = 0.3
        fire.lifetimeRange = 0.1
        fire.velocity = 48
        fire.velocityRange = 22
        fire.emissionLongitude = .pi / 2
        fire.emissionRange = 0.72
        fire.yAcceleration = -90
        fire.color = CGColor(red: 1, green: 1, blue: 1, alpha: 0.92)
        fire.alphaSpeed = -1.7

        let core = CAEmitterCell()
        core.contents = ArtAssets.image(named: "effect-fire")
        core.scale = CGFloat(0.035)
        core.scaleRange = CGFloat(0.012)
        core.birthRate = 22 * Float(fireScale)
        core.lifetime = 0.19
        core.velocity = 36
        core.emissionLongitude = .pi / 2
        core.emissionRange = 0.48
        core.yAcceleration = -80
        core.color = CGColor(red: 1, green: 1, blue: 1, alpha: 0.96)
        core.alphaSpeed = -2.2

        let smoke = CAEmitterCell()
        smoke.contents = ArtAssets.image(named: "effect-smoke")
        smoke.scale = CGFloat(0.05)
        smoke.scaleSpeed = CGFloat(0.3)
        smoke.birthRate = fireScale >= 0.55 ? 9 * Float(fireScale) : 0
        smoke.lifetime = 0.58
        smoke.velocity = 24
        smoke.emissionLongitude = .pi / 2
        smoke.emissionRange = 0.68
        smoke.yAcceleration = -50
        smoke.color = CGColor(red: 1, green: 1, blue: 1, alpha: 0.30)
        smoke.alphaSpeed = -0.42

        emitter.emitterCells = [fire, core, smoke]
        layer.addSublayer(emitter)
        return emitter
    }

    static func updateLingeringFire(
        _ emitter: CAEmitterLayer,
        intensity: CGFloat
    ) {
        guard let cells = emitter.emitterCells else { return }
        let fireScale = PerformanceGovernor.current.fireScale

        if cells.indices.contains(0) {
            cells[0].scale = 0.38 * intensity
            cells[0].birthRate = 48 * Float(intensity * fireScale)
        }
        if cells.indices.contains(1) {
            cells[1].scale = 0.5 * min(1.25, intensity)
            cells[1].birthRate = 12 * Float(max(0.45, intensity * 0.8) * fireScale)
        }
        if cells.indices.contains(2) {
            cells[2].scale = 0.28 * intensity
            cells[2].birthRate = 22 * Float(intensity * fireScale)
        }
        if cells.indices.contains(3) {
            cells[3].birthRate = 8 * Float(intensity * fireScale)
        }
        emitter.emitterCells = cells
    }

    static func updateCreatureFire(_ emitter: CAEmitterLayer) {
        guard let cells = emitter.emitterCells else { return }
        let fireScale = PerformanceGovernor.current.creatureFireScale

        if cells.indices.contains(0) {
            cells[0].birthRate = 42 * Float(fireScale)
        }
        if cells.indices.contains(1) {
            cells[1].birthRate = 22 * Float(fireScale)
        }
        if cells.indices.contains(2) {
            cells[2].birthRate = fireScale >= 0.55 ? 9 * Float(fireScale) : 0
        }
        emitter.emitterCells = cells
    }

    static func smoke(at point: CGPoint, count: Int, in canvas: DestructionCanvas) {
        let scaledCount = max(3, Int(CGFloat(count) * multiplier))
        let emitter = burstEmitter(at: point, life: 1.2)
        emitter.zPosition = 90
        let cell = CAEmitterCell()
        cell.contents = ArtAssets.image(named: "effect-smoke")
        cell.scale = CGFloat(0.20)
        cell.scaleSpeed = CGFloat(0.7)
        cell.birthRate = Float(scaledCount)
        cell.lifetime = 0.85
        cell.velocity = 85
        cell.velocityRange = 55
        cell.emissionLongitude = .pi / 2
        cell.emissionRange = 2 * .pi
        cell.yAcceleration = -260
        cell.color = CGColor(red: 1, green: 1, blue: 1, alpha: 0.42)
        cell.alphaSpeed = -0.35
        emitter.emitterCells = [cell]
        canvas.addTransient(emitter)
        canvas.removeAfter(emitter, delay: 1.25)
    }

    static func steam(at point: CGPoint, count: Int, in canvas: DestructionCanvas) {
        let scaledCount = max(4, Int(CGFloat(count) * multiplier))
        let emitter = burstEmitter(at: point, life: 0.9)
        emitter.zPosition = 90
        let cell = CAEmitterCell()
        cell.contents = ArtAssets.image(named: "effect-steam")
        cell.scale = CGFloat(0.12)
        cell.scaleSpeed = CGFloat(0.55)
        cell.birthRate = Float(scaledCount)
        cell.lifetime = 0.72
        cell.velocity = 115
        cell.velocityRange = 42
        cell.emissionLongitude = .pi / 2
        cell.emissionRange = 0.65
        cell.yAcceleration = -180
        cell.color = CGColor(red: 1, green: 1, blue: 1, alpha: 0.44)
        cell.alphaSpeed = -0.62
        emitter.emitterCells = [cell]
        canvas.addTransient(emitter)
        canvas.removeAfter(emitter, delay: 0.95)
    }

    static func sawdust(at point: CGPoint, count: Int, in canvas: DestructionCanvas) {
        let scaledCount = max(3, Int(CGFloat(count) * multiplier))
        let emitter = burstEmitter(at: point, life: 0.8)
        emitter.zPosition = 91
        let cell = CAEmitterCell()
        cell.contents = ArtAssets.image(named: "effect-debris")
        cell.scale = CGFloat(0.06)
        cell.scaleRange = CGFloat(0.025)
        cell.birthRate = Float(scaledCount)
        cell.lifetime = 0.55
        cell.lifetimeRange = 0.2
        cell.velocity = 150
        cell.velocityRange = 75
        cell.emissionRange = 2 * .pi
        cell.yAcceleration = -620
        cell.spin = CGFloat.random(in: -9...9)
        cell.spinRange = 6
        cell.color = CGColor(red: 1, green: 1, blue: 1, alpha: 0.72)
        cell.alphaSpeed = -0.9
        emitter.emitterCells = [cell]
        canvas.addTransient(emitter)
        canvas.removeAfter(emitter, delay: 0.85)
    }

    static func rocketTrail(attachedTo layer: CALayer) {
        let emitter = CAEmitterLayer()
        emitter.position = CGPoint(x: layer.bounds.midX, y: layer.bounds.midY)
        emitter.emitterSize = CGSize(width: 3, height: 3)
        emitter.emitterShape = .circle
        emitter.renderMode = .unordered
        emitter.zPosition = -1

        let flame = CAEmitterCell()
        flame.contents = ArtAssets.image(named: "effect-fire")
        flame.scale = CGFloat(0.12)
        flame.scaleRange = CGFloat(0.025)
        flame.scaleSpeed = CGFloat(0.5)
        flame.birthRate = 84
        flame.lifetime = 0.28
        flame.velocity = 180
        flame.velocityRange = 30
        flame.emissionLongitude = .pi
        flame.emissionRange = 0.24
        flame.color = CGColor(red: 1, green: 1, blue: 1, alpha: 0.94)
        flame.alphaSpeed = -2.5

        let smoke = CAEmitterCell()
        smoke.contents = ArtAssets.image(named: "effect-smoke")
        smoke.scale = CGFloat(0.09)
        smoke.scaleSpeed = CGFloat(0.85)
        smoke.birthRate = 40
        smoke.lifetime = 0.75
        smoke.velocity = 145
        smoke.velocityRange = 32
        smoke.emissionLongitude = .pi
        smoke.emissionRange = 0.42
        smoke.color = CGColor(red: 1, green: 1, blue: 1, alpha: 0.38)
        smoke.alphaSpeed = -0.45

        emitter.emitterCells = [flame, smoke]
        layer.addSublayer(emitter)
    }

    private static func burstEmitter(at point: CGPoint, life: TimeInterval) -> CAEmitterLayer {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = point
        emitter.emitterSize = CGSize(width: 6, height: 6)
        emitter.emitterShape = .circle
        emitter.renderMode = .unordered
        emitter.lifetime = Float(life)
        return emitter
    }

    private static func streamEmitter(at point: CGPoint) -> CAEmitterLayer {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = point
        emitter.emitterSize = CGSize(width: 6, height: 6)
        emitter.emitterShape = .circle
        emitter.renderMode = .unordered
        emitter.lifetime = 0
        return emitter
    }

    private static func emissionAngle(_ direction: CGPoint) -> CGFloat {
        atan2(direction.y, direction.x)
    }
}
