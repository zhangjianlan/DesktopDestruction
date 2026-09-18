import CoreGraphics

enum SawBladeRenderer {
    static func image(pixelSize: Int = 192) -> CGImage? {
        let size = max(32, CGFloat(pixelSize))
        guard let context = CGContext(
            data: nil,
            width: Int(size),
            height: Int(size),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let center = CGPoint(x: size / 2, y: size / 2)
        let outerRadius = size * 0.47
        let toothRoot = size * 0.365
        let bladePath = CGMutablePath()
        let teeth = 20

        for index in 0..<teeth {
            let startAngle = CGFloat(index) / CGFloat(teeth) * 2 * .pi
            let tipAngle = startAngle + (2 * .pi / CGFloat(teeth) * 0.42)
            let nextRootAngle = startAngle + (2 * .pi / CGFloat(teeth) * 0.60)
            let tip = CGPoint(
                x: center.x + cos(tipAngle) * outerRadius,
                y: center.y + sin(tipAngle) * outerRadius
            )
            let nextRoot = CGPoint(
                x: center.x + cos(nextRootAngle) * toothRoot,
                y: center.y + sin(nextRootAngle) * toothRoot
            )

            if index == 0 {
                bladePath.move(to: tip)
            } else {
                bladePath.addLine(to: tip)
            }
            bladePath.addLine(to: nextRoot)
        }
        bladePath.closeSubpath()

        context.saveGState()
        context.addPath(bladePath)
        context.clip()
        if let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                CGColor(red: 0.92, green: 0.94, blue: 0.97, alpha: 1),
                CGColor(red: 0.61, green: 0.65, blue: 0.70, alpha: 1),
                CGColor(red: 0.32, green: 0.36, blue: 0.42, alpha: 1)
            ] as CFArray,
            locations: [0.12, 0.58, 1]
        ) {
            context.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: center.x - size * 0.09, y: center.y + size * 0.09),
                startRadius: size * 0.04,
                endCenter: center,
                endRadius: outerRadius,
                options: []
            )
        }
        context.restoreGState()

        context.addPath(bladePath)
        context.setStrokeColor(CGColor(red: 0.04, green: 0.05, blue: 0.07, alpha: 0.92))
        context.setLineWidth(size * 0.025)
        context.strokePath()

        for index in 0..<teeth {
            let angle = CGFloat(index) / CGFloat(teeth) * 2 * .pi
            let start = CGPoint(
                x: center.x + cos(angle) * toothRoot,
                y: center.y + sin(angle) * toothRoot
            )
            let end = CGPoint(
                x: center.x + cos(angle) * outerRadius,
                y: center.y + sin(angle) * outerRadius
            )
            context.setStrokeColor(CGColor(red: 0.99, green: 0.98, blue: 0.92, alpha: 0.42))
            context.setLineWidth(size * 0.012)
            context.move(to: start)
            context.addLine(to: end)
            context.strokePath()
        }

        context.setFillColor(CGColor(red: 0.91, green: 0.32, blue: 0.12, alpha: 0.96))
        context.fillEllipse(in: CGRect(
            x: center.x - size * 0.115,
            y: center.y - size * 0.115,
            width: size * 0.23,
            height: size * 0.23
        ))
        context.setStrokeColor(CGColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 0.9))
        context.setLineWidth(size * 0.022)
        context.strokeEllipse(in: CGRect(
            x: center.x - size * 0.115,
            y: center.y - size * 0.115,
            width: size * 0.23,
            height: size * 0.23
        ))
        context.setFillColor(CGColor(red: 0.09, green: 0.10, blue: 0.11, alpha: 1))
        context.fillEllipse(in: CGRect(
            x: center.x - size * 0.032,
            y: center.y - size * 0.032,
            width: size * 0.064,
            height: size * 0.064
        ))

        context.setFillColor(CGColor(red: 0.99, green: 0.99, blue: 1, alpha: 0.20))
        for index in 0..<4 {
            let angle = CGFloat(index) * .pi / 2 + .pi / 4
            let point = CGPoint(
                x: center.x + cos(angle) * size * 0.245,
                y: center.y + sin(angle) * size * 0.245
            )
            context.fillEllipse(in: CGRect(
                x: point.x - size * 0.024,
                y: point.y - size * 0.024,
                width: size * 0.048,
                height: size * 0.048
            ))
        }

        return context.makeImage()
    }
}
