import Foundation
import QuartzCore

/// Drives the projectile position directly in the canvas coordinate space.
/// CAKeyframeAnimation.path can reinterpret points through layer geometry, which
/// previously made the throw appear to begin at the top of the screen.
final class PoopProjectileAnimator {
    private let layer: CALayer
    private let trajectory: PoopThrowTrajectory
    private let completion: () -> Void
    private var timer: Timer?
    private let startedAt = CFAbsoluteTimeGetCurrent()
    private var isCancelled = false

    deinit {
        timer?.invalidate()
    }

    init(
        layer: CALayer,
        trajectory: PoopThrowTrajectory,
        completion: @escaping () -> Void
    ) {
        self.layer = layer
        self.trajectory = trajectory
        self.completion = completion
    }

    func start() {
        setLayerPosition(trajectory.start)
        let timer = Timer(timeInterval: 1.0 / 90.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        timer.tolerance = 0.004
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func cancel() {
        isCancelled = true
        timer?.invalidate()
        timer = nil
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.removeFromSuperlayer()
        CATransaction.commit()
    }

    private func tick() {
        let elapsed = CFAbsoluteTimeGetCurrent() - startedAt
        let progress = CGFloat(min(1, elapsed / trajectory.duration))
        setLayerPosition(trajectory.point(at: progress))

        guard progress >= 1 else { return }
        timer?.invalidate()
        timer = nil
        guard !isCancelled else { return }
        completion()
    }

    private func setLayerPosition(_ point: CGPoint) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.position = point
        CATransaction.commit()
    }
}
