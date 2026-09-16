import AppKit
import CoreGraphics

enum CanvasBackgroundRenderer {
    static func render(size: CGSize) -> CGImage {
        let backingScale: CGFloat = 2
        let width = max(2, Int(size.width * backingScale))
        let height = max(2, Int(size.height * backingScale))
        let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        ctx.scaleBy(x: backingScale, y: backingScale)

        drawBaseGradient(in: ctx, size: size)
        drawSunburst(in: ctx, size: size)
        drawHalftone(in: ctx, size: size)
        drawCentralBoard(in: ctx, size: size)
        drawDecorativeShapes(in: ctx, size: size)
        drawVignetteAndFrame(in: ctx, size: size)
        return ctx.makeImage()!
    }

    private static func drawBaseGradient(in ctx: CGContext, size: CGSize) {
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                CGColor(red: 0.07, green: 0.55, blue: 0.55, alpha: 1),
                CGColor(red: 0.05, green: 0.26, blue: 0.43, alpha: 1),
                CGColor(red: 0.13, green: 0.10, blue: 0.27, alpha: 1)
            ] as CFArray,
            locations: [0, 0.58, 1]
        )!
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: size.height),
            end: CGPoint(x: size.width, y: 0),
            options: []
        )
    }

    private static func drawSunburst(in ctx: CGContext, size: CGSize) {
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.54)
        let radius = max(size.width, size.height)
        ctx.saveGState()
        ctx.translateBy(x: center.x, y: center.y)
        ctx.setFillColor(CGColor(red: 1, green: 0.88, blue: 0.35, alpha: 0.07))

        for index in 0..<24 {
            let startAngle = CGFloat(index) / 24 * .pi * 2
            let endAngle = startAngle + (.pi * 2 / 48)
            ctx.move(to: .zero)
            ctx.addArc(
                center: .zero,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            ctx.closePath()
            ctx.fillPath()
        }
        ctx.restoreGState()
    }

    private static func drawHalftone(in ctx: CGContext, size: CGSize) {
        let spacing: CGFloat = 34
        ctx.setFillColor(CGColor(gray: 0, alpha: 0.055))

        var y: CGFloat = -spacing
        while y < size.height + spacing {
            var x: CGFloat = (y / spacing).rounded(.up).truncatingRemainder(dividingBy: 2) == 0
                ? 0
                : spacing / 2
            while x < size.width + spacing {
                let normalizedX = x / max(size.width, 1)
                let normalizedY = y / max(size.height, 1)
                let distance = hypot(normalizedX - 0.5, normalizedY - 0.54)
                let dotRadius: CGFloat
                if distance < 0.34 {
                    dotRadius = 1.1
                } else if distance < 0.62 {
                    dotRadius = 2.1
                } else {
                    dotRadius = 3.3
                }
                ctx.fillEllipse(in: CGRect(
                    x: x - dotRadius,
                    y: y - dotRadius,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                ))
                x += spacing
            }
            y += spacing
        }
    }

    private static func drawCentralBoard(in ctx: CGContext, size: CGSize) {
        let boardRect = CGRect(
            x: size.width * 0.08,
            y: size.height * 0.11,
            width: size.width * 0.84,
            height: size.height * 0.72
        )
        ctx.setFillColor(CGColor(gray: 0, alpha: 0.28))
        ctx.fill(boardRect.offsetBy(dx: 14, dy: -16))
        fillRoundedRect(
            in: ctx,
            rect: boardRect,
            radius: 24,
            color: CGColor(red: 0.97, green: 0.97, blue: 0.93, alpha: 1)
        )
        strokeRoundedRect(
            in: ctx,
            rect: boardRect.insetBy(dx: 9, dy: 9),
            radius: 18,
            color: CGColor(gray: 0, alpha: 0.78),
            lineWidth: 4
        )

        ctx.setStrokeColor(CGColor(gray: 0, alpha: 0.075))
        ctx.setLineWidth(1)
        var y = boardRect.minY + 38
        while y < boardRect.maxY - 18 {
            ctx.move(to: CGPoint(x: boardRect.minX + 24, y: y))
            ctx.addLine(to: CGPoint(x: boardRect.maxX - 24, y: y))
            y += 38
        }
        ctx.strokePath()
        drawComicPanels(in: ctx, boardRect: boardRect)
    }

    private static func drawComicPanels(in ctx: CGContext, boardRect: CGRect) {
        let inset = boardRect.insetBy(dx: 28, dy: 28)
        let panelWidth = (inset.width - 24) / 3
        let panelHeight = (inset.height - 24) / 2
        let colors: [CGColor] = [
            CGColor(red: 0.98, green: 0.72, blue: 0.24, alpha: 0.92),
            CGColor(red: 0.91, green: 0.29, blue: 0.36, alpha: 0.86),
            CGColor(red: 0.22, green: 0.68, blue: 0.79, alpha: 0.88),
            CGColor(red: 0.46, green: 0.36, blue: 0.87, alpha: 0.82),
            CGColor(red: 0.96, green: 0.91, blue: 0.77, alpha: 0.94),
            CGColor(red: 0.13, green: 0.25, blue: 0.25, alpha: 0.88)
        ]

        for index in 0..<6 {
            let column = index % 3
            let row = index / 3
            let rect = CGRect(
                x: inset.minX + CGFloat(column) * (panelWidth + 12),
                y: inset.maxY - panelHeight - CGFloat(row) * (panelHeight + 12),
                width: panelWidth,
                height: panelHeight
            )
            fillRoundedRect(in: ctx, rect: rect, radius: 14, color: colors[index])
            strokeRoundedRect(
                in: ctx,
                rect: rect,
                radius: 14,
                color: CGColor(gray: 0, alpha: 0.7),
                lineWidth: 4
            )
        }
    }

    private static func drawDecorativeShapes(in ctx: CGContext, size: CGSize) {
        drawTarget(
            in: ctx,
            center: CGPoint(x: size.width * 0.22, y: size.height * 0.3),
            radius: min(size.width, size.height) * 0.085
        )
        drawTarget(
            in: ctx,
            center: CGPoint(x: size.width * 0.79, y: size.height * 0.63),
            radius: min(size.width, size.height) * 0.07
        )
        drawHazardStripes(
            in: ctx,
            rect: CGRect(
                x: size.width * 0.38,
                y: size.height * 0.875,
                width: size.width * 0.24,
                height: 28
            )
        )
        drawCloud(
            in: ctx,
            center: CGPoint(x: size.width * 0.82, y: size.height * 0.88),
            radius: min(size.width, size.height) * 0.045
        )
    }

    private static func drawTarget(in ctx: CGContext, center: CGPoint, radius: CGFloat) {
        let rings: [(CGFloat, CGColor)] = [
            (1, CGColor(red: 0.96, green: 0.93, blue: 0.86, alpha: 0.95)),
            (0.68, CGColor(red: 0.91, green: 0.29, blue: 0.36, alpha: 0.94)),
            (0.36, CGColor(red: 0.96, green: 0.93, blue: 0.86, alpha: 0.95))
        ]
        for (scale, color) in rings {
            ctx.setFillColor(color)
            ctx.fillEllipse(in: CGRect(
                x: center.x - radius * scale,
                y: center.y - radius * scale,
                width: radius * scale * 2,
                height: radius * scale * 2
            ))
        }
        ctx.setFillColor(CGColor(gray: 0, alpha: 0.9))
        ctx.fillEllipse(in: CGRect(
            x: center.x - radius * 0.08,
            y: center.y - radius * 0.08,
            width: radius * 0.16,
            height: radius * 0.16
        ))
    }

    private static func drawHazardStripes(in ctx: CGContext, rect: CGRect) {
        ctx.saveGState()
        let path = CGPath(roundedRect: rect, cornerWidth: 8, cornerHeight: 8, transform: nil)
        ctx.addPath(path)
        ctx.clip()
        ctx.setFillColor(CGColor(red: 0.98, green: 0.82, blue: 0.25, alpha: 1))
        ctx.fill(rect)
        ctx.setFillColor(CGColor(gray: 0, alpha: 0.88))

        let stripeWidth: CGFloat = 18
        for x in stride(
            from: rect.minX - rect.height,
            to: rect.maxX + rect.height,
            by: stripeWidth * 2
        ) {
            ctx.move(to: CGPoint(x: x, y: rect.minY))
            ctx.addLine(to: CGPoint(x: x + stripeWidth, y: rect.minY))
            ctx.addLine(to: CGPoint(x: x + stripeWidth - rect.height, y: rect.maxY))
            ctx.addLine(to: CGPoint(x: x - rect.height, y: rect.maxY))
            ctx.closePath()
            ctx.fillPath()
        }
        ctx.restoreGState()
        strokeRoundedRect(
            in: ctx,
            rect: rect,
            radius: 8,
            color: CGColor(gray: 0, alpha: 0.82),
            lineWidth: 4
        )
    }

    private static func drawCloud(in ctx: CGContext, center: CGPoint, radius: CGFloat) {
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.88))
        let circles = [
            CGPoint(x: -radius, y: 0),
            CGPoint(x: -radius * 0.35, y: radius * 0.32),
            CGPoint(x: radius * 0.36, y: radius * 0.28),
            CGPoint(x: radius, y: 0)
        ]
        for circleCenter in circles {
            ctx.fillEllipse(in: CGRect(
                x: center.x + circleCenter.x - radius * 0.62,
                y: center.y + circleCenter.y - radius * 0.62,
                width: radius * 1.24,
                height: radius * 1.24
            ))
        }
        ctx.fill(CGRect(
            x: center.x - radius,
            y: center.y - radius * 0.42,
            width: radius * 2,
            height: radius * 0.84
        ))
    }

    private static func drawVignetteAndFrame(in ctx: CGContext, size: CGSize) {
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                CGColor(gray: 0, alpha: 0),
                CGColor(gray: 0, alpha: 0.38)
            ] as CFArray,
            locations: [0, 1]
        )!
        ctx.drawRadialGradient(
            gradient,
            startCenter: CGPoint(x: size.width / 2, y: size.height / 2),
            startRadius: min(size.width, size.height) * 0.25,
            endCenter: CGPoint(x: size.width / 2, y: size.height / 2),
            endRadius: max(size.width, size.height) * 0.78,
            options: []
        )
        strokeRoundedRect(
            in: ctx,
            rect: CGRect(origin: .zero, size: size).insetBy(dx: 8, dy: 8),
            radius: 22,
            color: CGColor(gray: 0, alpha: 0.72),
            lineWidth: 7
        )
    }

    private static func fillRoundedRect(
        in ctx: CGContext,
        rect: CGRect,
        radius: CGFloat,
        color: CGColor
    ) {
        let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
        ctx.addPath(path)
        ctx.setFillColor(color)
        ctx.fillPath()
    }

    private static func strokeRoundedRect(
        in ctx: CGContext,
        rect: CGRect,
        radius: CGFloat,
        color: CGColor,
        lineWidth: CGFloat
    ) {
        let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
        ctx.addPath(path)
        ctx.setStrokeColor(color)
        ctx.setLineWidth(lineWidth)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.strokePath()
    }
}
