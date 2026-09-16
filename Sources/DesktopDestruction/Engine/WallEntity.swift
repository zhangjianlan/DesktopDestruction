import QuartzCore

final class WallEntity {
    let layer = CALayer()
    let frame: CGRect
    private(set) var isAlive = true
    private let maximumHealth: CGFloat = 120
    private var health: CGFloat

    init(at point: CGPoint, size: CGSize) {
        frame = CGRect(
            x: point.x - size.width / 2,
            y: point.y - size.height / 2,
            width: size.width,
            height: size.height
        )
        health = maximumHealth

        layer.contents = ArtAssets.image(named: "wall-brick")
        layer.contentsGravity = .resize
        layer.contentsScale = 2
        layer.bounds = CGRect(origin: .zero, size: size)
        layer.position = point
        layer.cornerRadius = 6
        layer.borderWidth = 2
        layer.borderColor = CGColor(gray: 0.08, alpha: 0.85)
        layer.zPosition = 74
    }

    func hitTest(position: CGPoint, radius: CGFloat) -> Bool {
        let dx = max(frame.minX - position.x, 0, position.x - frame.maxX)
        let dy = max(frame.minY - position.y, 0, position.y - frame.maxY)
        return dx * dx + dy * dy <= radius * radius
    }

    @discardableResult
    func applyDamage(_ amount: CGFloat, canvas: DestructionCanvas) -> Bool {
        guard isAlive else { return false }
        health -= max(0, amount)
        updateAppearance()

        guard health <= 0 else { return false }
        isAlive = false
        ParticleFactory.debris(at: CGPoint(x: frame.midX, y: frame.midY), count: 26, in: canvas)
        ParticleFactory.dust(at: CGPoint(x: frame.midX, y: frame.midY), count: 18, in: canvas)

        CATransaction.begin()
        CATransaction.setDisableActions(false)
        layer.opacity = 0
        CATransaction.commit()
        canvas.removeAfter(layer, delay: 0.22)
        return true
    }

    private func updateAppearance() {
        let fraction = max(0.35, min(1, health / maximumHealth))
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.opacity = Float(fraction)
        layer.borderWidth = health < maximumHealth * 0.55 ? 3 : 2
        CATransaction.commit()
    }

    func discard() {
        isAlive = false
        layer.removeFromSuperlayer()
    }
}
