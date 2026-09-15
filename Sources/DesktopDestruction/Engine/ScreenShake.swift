import QuartzCore

enum ScreenShake {
    @discardableResult
    static func shake(_ layer: CALayer, intensity: CGFloat, duration: TimeInterval) -> Bool {
        guard AppSettings.shared.shakeEnabled, intensity > 0, duration > 0 else {
            return false
        }
        let frameCount = 18
        var values: [CATransform3D] = []
        var keyTimes: [NSNumber] = []
        values.append(layer.transform)
        keyTimes.append(0)

        for index in 1..<frameCount {
            let progress = CGFloat(index) / CGFloat(frameCount)
            let amount = intensity * (1 - progress)
            let transform = CATransform3DMakeTranslation(
                CGFloat.random(in: -amount...amount),
                CGFloat.random(in: -amount...amount),
                0
            )
            values.append(transform)
            keyTimes.append(NSNumber(value: Double(index) / Double(frameCount)))
        }

        values.append(CATransform3DIdentity)
        keyTimes.append(1)

        let animation = CAKeyframeAnimation(keyPath: "transform")
        animation.values = values
        animation.keyTimes = keyTimes
        animation.duration = duration
        animation.calculationMode = .discrete
        animation.isRemovedOnCompletion = true
        layer.add(animation, forKey: "DesktopDestruction.screenShake")
        return true
    }
}
