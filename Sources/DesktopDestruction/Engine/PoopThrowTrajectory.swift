import CoreGraphics

struct PoopThrowTrajectory {
    let start: CGPoint
    let target: CGPoint
    let control: CGPoint
    let duration: CFTimeInterval

    static func make(target: CGPoint, bounds: CGRect) -> PoopThrowTrajectory {
        let lateralSwing = min(220, max(130, bounds.width * 0.18))
        let start = CGPoint(
            x: min(
                bounds.maxX - 56,
                max(bounds.minX + 56, target.x - lateralSwing)
            ),
            y: bounds.minY - 68
        )
        let distance = hypot(target.x - start.x, target.y - start.y)
        let diagonal = max(1, hypot(bounds.width, bounds.height))
        let duration = 0.64 + 0.30 * min(1, distance / diagonal)
        let arcHeight = min(280, max(120, distance * 0.34))
        let control = CGPoint(
            x: target.x + lateralSwing * 0.48,
            y: target.y + arcHeight
        )

        return PoopThrowTrajectory(
            start: start,
            target: target,
            control: control,
            duration: duration
        )
    }

    func point(at progress: CGFloat) -> CGPoint {
        let t = min(1, max(0, progress))
        let inverse = 1 - t
        return CGPoint(
            x: inverse * inverse * start.x
                + 2 * inverse * t * control.x
                + t * t * target.x,
            y: inverse * inverse * start.y
                + 2 * inverse * t * control.y
                + t * t * target.y
        )
    }
}
