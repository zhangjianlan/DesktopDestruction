import QuartzCore

struct BurningSpotUpdate {
    let isAlive: Bool
    let spreadPoint: CGPoint?
}

final class BurningSpot {
    let position: CGPoint
    let radius: CGFloat
    let spreadIntensity: CGFloat

    private let emitter: CAEmitterLayer
    private let canvas: DestructionCanvas
    private let burnDuration: TimeInterval
    private let initialIntensity: CGFloat
    private let createdAt = Date()
    private var lastSpread = Date()
    private var lastScorch = Date()
    private var lastEmitterUpdate = Date()
    private var stopped = false

    init(
        at point: CGPoint,
        canvas: DestructionCanvas,
        duration: TimeInterval = 9,
        intensity: CGFloat = 1.25
    ) {
        position = point
        radius = 34
        self.canvas = canvas
        self.burnDuration = duration
        initialIntensity = intensity
        spreadIntensity = max(0.5, intensity - 0.2)
        emitter = ParticleFactory.lingeringFire(at: point, intensity: intensity, in: canvas)

        let pulse = CAKeyframeAnimation(keyPath: "transform.scale")
        pulse.values = [0.78, 1.16, 0.88, 1.08, 0.78]
        pulse.keyTimes = [0, 0.24, 0.5, 0.76, 1]
        pulse.duration = 1.15
        pulse.repeatCount = .infinity
        emitter.add(pulse, forKey: "flamePulse")
    }

    @discardableResult
    func update(now: Date, bounds: CGRect, lowDetail: Bool) -> BurningSpotUpdate {
        guard !stopped else { return BurningSpotUpdate(isAlive: false, spreadPoint: nil) }

        let age = now.timeIntervalSince(createdAt)
        if age >= burnDuration {
            stop(fadeDuration: 0.55)
            return BurningSpotUpdate(isAlive: false, spreadPoint: nil)
        }

        let intensity = currentIntensity(age: age)
        let emitterUpdateInterval: TimeInterval = lowDetail ? 0.07 : 0.02
        if now.timeIntervalSince(lastEmitterUpdate) >= emitterUpdateInterval,
           let cells = emitter.emitterCells,
           cells.count >= 2 {
            lastEmitterUpdate = now
            if cells.count > 0 {
                cells[0].scale = 0.38 * intensity
                cells[0].birthRate = 48 * Float(intensity)
            }
            if cells.count > 1 {
                cells[1].scale = 0.5 * min(1.25, intensity)
                cells[1].birthRate = 12 * Float(max(0.45, intensity * 0.8))
            }
            if cells.count > 2 {
                cells[2].scale = 0.28 * intensity
                cells[2].birthRate = 22 * Float(intensity)
            }
            if cells.count > 3 {
                cells[3].birthRate = 8 * Float(intensity)
            }
            emitter.emitterCells = cells
        }
        emitter.opacity = age > burnDuration - 0.8
            ? Float(max(0, (burnDuration - age) / 0.8))
            : 1

        if now.timeIntervalSince(lastScorch) >= (lowDetail ? 0.68 : 0.34) {
            lastScorch = now
            addScorch(near: position, bounds: bounds, distance: 4...14, radius: 6...12)
        }

        var spreadPoint: CGPoint?
        if now.timeIntervalSince(lastSpread) >= 1.05 {
            lastSpread = now
            addScorch(near: position, bounds: bounds, distance: 10...radius * 0.8, radius: 8...15)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 8...radius * 0.8)
            spreadPoint = CGPoint(
                x: min(max(position.x + cos(angle) * distance, bounds.minX + 4), bounds.maxX - 4),
                y: min(max(position.y + sin(angle) * distance, bounds.minY + 4), bounds.maxY - 4)
            )
        }

        return BurningSpotUpdate(isAlive: true, spreadPoint: spreadPoint)
    }

    func extinguish() {
        ParticleFactory.steam(at: position, count: 14, in: canvas)
        stop(fadeDuration: 0.24)
    }

    private func currentIntensity(age: TimeInterval) -> CGFloat {
        let ramp = max(0.72, min(1, age / 0.12))
        let decay = max(0.38, 1 - age / burnDuration * 0.62)
        return initialIntensity * CGFloat(ramp) * CGFloat(decay)
    }

    private func addScorch(
        near point: CGPoint,
        bounds: CGRect,
        distance: ClosedRange<CGFloat>,
        radius: ClosedRange<CGFloat>
    ) {
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let target = CGPoint(
            x: min(max(point.x + cos(angle) * CGFloat.random(in: distance), bounds.minX + 4), bounds.maxX - 4),
            y: min(max(point.y + sin(angle) * CGFloat.random(in: distance), bounds.minY + 4), bounds.maxY - 4)
        )
        if let damage = DamageRenderer.renderScorch(at: target, radius: CGFloat.random(in: radius)) {
            canvas.addDamage(image: damage.0, frame: damage.1)
        }
    }

    private func stop(fadeDuration: TimeInterval) {
        guard !stopped else { return }
        stopped = true
        emitter.emitterCells?.forEach { $0.birthRate = 0 }
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = emitter.opacity
        fade.toValue = 0
        fade.duration = fadeDuration
        fade.fillMode = .forwards
        fade.isRemovedOnCompletion = false
        emitter.add(fade, forKey: "fireFade")
        canvas.removeAfter(emitter, delay: fadeDuration + 0.04)
    }
}
