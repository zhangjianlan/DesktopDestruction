import QuartzCore

final class DestructionCanvas {
    let root = CALayer()
    var remainingDamageCount: Int { damageItems.count }
    private let damageLayer = CALayer()
    private let transientLayer = CALayer()
    private var damageItems: [(layer: CALayer, frame: CGRect, isPermanent: Bool)] = []
    private let maxDamageLayers = 1800
    private var nonPermanentDamageCount = 0

    init() {
        root.masksToBounds = false
        damageLayer.masksToBounds = false
        transientLayer.masksToBounds = false
        root.addSublayer(damageLayer)
        root.addSublayer(transientLayer)
    }

    func layout(for bounds: CGRect) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        root.frame = bounds
        damageLayer.frame = bounds
        transientLayer.frame = bounds
        CATransaction.commit()
    }

    func addDamage(image: CGImage, frame: CGRect, permanent: Bool = false) {
        pruneDamageIfNeeded()
        let layer = CALayer()
        layer.contents = image
        layer.contentsScale = 2
        layer.bounds = CGRect(origin: .zero, size: frame.size)
        layer.position = CGPoint(x: frame.midX, y: frame.midY)
        layer.opacity = 1
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        damageLayer.addSublayer(layer)
        CATransaction.commit()
        damageItems.append((layer, frame, permanent))
        if !permanent {
            nonPermanentDamageCount += 1
        }
    }

    private func pruneDamageIfNeeded() {
        var removedIndexes = IndexSet()
        for (index, item) in damageItems.enumerated()
        where !item.isPermanent && nonPermanentDamageCount - removedIndexes.count >= maxDamageLayers {
            removedIndexes.insert(index)
            if nonPermanentDamageCount - removedIndexes.count < maxDamageLayers {
                break
            }
        }

        guard !removedIndexes.isEmpty else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for index in removedIndexes {
            damageItems[index].layer.removeFromSuperlayer()
        }
        CATransaction.commit()
        nonPermanentDamageCount -= removedIndexes.count
        for index in removedIndexes.reversed() {
            damageItems.remove(at: index)
        }
    }

    func addTransient(_ layer: CALayer) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        transientLayer.addSublayer(layer)
        CATransaction.commit()
    }

    func removeAfter(_ layer: CALayer, delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            layer.removeFromSuperlayer()
            _ = self
        }
    }

    func clearTransients() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        transientLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        CATransaction.commit()
    }

    @discardableResult
    func erase(at point: CGPoint, radius: CGFloat) -> Int {
        let eraseRect = CGRect(
            x: point.x - radius,
            y: point.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        var removed = 0
        for (index, item) in damageItems.enumerated().reversed() where item.frame.intersects(eraseRect) {
            item.layer.removeFromSuperlayer()
            damageItems.remove(at: index)
            if !item.isPermanent {
                nonPermanentDamageCount -= 1
            }
            removed += 1
        }
        return removed
    }

    @discardableResult
    func clearDamage() -> Int {
        let removedCount = damageItems.count
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        damageLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        CATransaction.commit()
        damageItems.removeAll()
        nonPermanentDamageCount = 0
        return removedCount
    }
}
