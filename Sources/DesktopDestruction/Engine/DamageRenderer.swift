import CoreGraphics
import Foundation

enum DamageRenderer {
    private static let renderScale: CGFloat = 2

    private final class CachedImage {
        let image: CGImage?

        init(_ image: CGImage?) {
            self.image = image
        }
    }

    private static let imageCache = NSCache<NSString, CachedImage>()

    enum ChewShape {
        case none
        case narrow
        case leaf
        case nibble
        case venom
        case bore
        case pierce
        case sting
        case speckle
        case rasp
        case graze
        case tunnel
    }

    static func frame(at point: CGPoint, radius: CGFloat) -> CGRect {
        CGRect(
            x: point.x - radius,
            y: point.y - radius,
            width: radius * 2,
            height: radius * 2
        )
    }

    static func frame(for geometry: CrackGeometry, padding: CGFloat = 12) -> CGRect {
        let points = geometry.points
        guard !points.isEmpty else { return frame(at: geometry.origin, radius: geometry.blotRadius) }
        var minX = points[0].x
        var maxX = points[0].x
        var minY = points[0].y
        var maxY = points[0].y
        for point in points {
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)
        }
        minX -= max(padding, geometry.blotRadius)
        minY -= max(padding, geometry.blotRadius)
        maxX += max(padding, geometry.blotRadius)
        maxY += max(padding, geometry.blotRadius)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    static func frame(from: CGPoint, to: CGPoint, width: CGFloat) -> CGRect {
        let minX = min(from.x, to.x) - width - 4
        let minY = min(from.y, to.y) - width - 4
        let maxX = max(from.x, to.x) + width + 4
        let maxY = max(from.y, to.y) + width + 4
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    static func renderCrackCluster(_ geometry: CrackGeometry, in frame: CGRect) -> (CGImage, CGRect)? {
        guard let context = makeContext(frame) else { return nil }
        drawRadial(
            in: context,
            at: pt(geometry.origin, in: frame),
            radius: geometry.blotRadius,
            colors: [rgba(0, 0, 0, 0.55), rgba(0.1, 0.1, 0.1, 0)]
        )

        for segment in geometry.segments {
            context.setStrokeColor(rgba(0.05, 0.05, 0.05, segment.alpha))
            context.setLineWidth(segment.width)
            context.setLineCap(.round)
            context.move(to: pt(segment.from, in: frame))
            context.addLine(to: pt(segment.to, in: frame))
            context.strokePath()
        }

        for segment in geometry.segments {
            context.setStrokeColor(rgba(0.48, 0.48, 0.52, segment.alpha * 0.35))
            context.setLineWidth(max(0.5, segment.width * 0.3))
            context.move(to: pt(segment.from, in: frame))
            context.addLine(to: pt(segment.to, in: frame))
            context.strokePath()
        }

        return context.makeImage().map { ($0, frame) }
    }

    static func renderBulletHole(at point: CGPoint, radius: CGFloat = 9) -> (CGImage, CGRect)? {
        let frame = frame(at: point, radius: radius * 2.3)
        let image = cachedImage("bullet", radius: radius, variants: 8, frameSize: frame.size) { context, center in
            drawRadial(
                in: context,
                at: center,
                radius: radius * 2,
                colors: [rgba(0, 0, 0, 0.8), rgba(0.14, 0.14, 0.16, 0)]
            )

            for i in 0..<7 {
                let angle = CGFloat(i) * (2 * .pi) / 7 + CGFloat.random(in: -0.25...0.25)
                let length = radius * CGFloat.random(in: 1.1...2.0)
                let end = CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length)
                context.setStrokeColor(rgba(0, 0, 0, 0.65))
                context.setLineWidth(CGFloat.random(in: 1...2.2))
                context.move(to: center)
                context.addLine(to: end)
                context.strokePath()
            }

            context.setFillColor(rgba(0.02, 0.02, 0.02, 1))
            context.fillEllipse(in: CGRect(
                x: center.x - radius * 0.55,
                y: center.y - radius * 0.55,
                width: radius * 1.1,
                height: radius * 1.1
            ))
            context.setFillColor(rgba(0.24, 0.24, 0.26, 0.65))
            context.fillEllipse(in: CGRect(
                x: center.x - radius * 0.82,
                y: center.y - radius * 0.82,
                width: radius * 1.64,
                height: radius * 1.64
            ))
        }
        return image.map { ($0, frame) }
    }

    static func renderScorch(at point: CGPoint, radius: CGFloat) -> (CGImage, CGRect)? {
        let frame = frame(at: point, radius: radius * 1.6)
        let image = cachedImage("scorch", radius: radius, frameSize: frame.size) { context, center in
            drawRadial(
                in: context,
                at: center,
                radius: radius * 1.5,
                colors: [
                    rgba(0, 0, 0, 0.72),
                    rgba(0.12, 0.08, 0.04, 0.44),
                    rgba(0.2, 0.14, 0.08, 0)
                ]
            )
        }
        return image.map { ($0, frame) }
    }

    static func renderGouge(at point: CGPoint, angle: CGFloat, radius: CGFloat) -> (CGImage, CGRect)? {
        let frame = frame(at: point, radius: radius * 1.8)
        let image = cachedImage(
            "gouge",
            radius: radius,
            angle: angle,
            variants: 6,
            frameSize: frame.size
        ) { context, center in
            context.saveGState()
            context.translateBy(x: center.x, y: center.y)
            context.rotate(by: -angle)
            drawRadial(
                in: context,
                at: .zero,
                radius: radius * 1.35,
                colors: [
                    rgba(0.02, 0.02, 0.03, 0.82),
                    rgba(0.08, 0.06, 0.04, 0.45),
                    rgba(0.16, 0.1, 0.06, 0)
                ]
            )
            context.setFillColor(rgba(0.01, 0.01, 0.01, 0.86))
            context.fillEllipse(in: ellipse(center: .zero, radiusX: radius, radiusY: radius * 0.35))
            context.setStrokeColor(rgba(0.48, 0.44, 0.4, 0.2))
            context.setLineWidth(radius * 0.08)
            context.strokeEllipse(in: ellipse(center: .zero, radiusX: radius * 1.2, radiusY: radius * 0.48))
            context.restoreGState()
        }
        return image.map { ($0, frame) }
    }

    static func renderCutSegment(from: CGPoint, to: CGPoint, width: CGFloat) -> (CGImage, CGRect)? {
        let frame = frame(from: from, to: to, width: width)
        guard let context = makeContext(frame) else { return nil }
        let start = pt(from, in: frame)
        let end = pt(to, in: frame)

        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = max(1, hypot(dx, dy))
        let unit = CGPoint(x: dx / length, y: dy / length)
        let normal = CGPoint(x: -unit.y, y: unit.x)

        context.setLineCap(.round)
        context.setStrokeColor(rgba(0.02, 0.02, 0.03, 0.78))
        context.setLineWidth(width * 0.68)
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()

        context.setStrokeColor(rgba(0.12, 0.08, 0.05, 0.42))
        context.setLineWidth(width)
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()

        context.setStrokeColor(rgba(0.68, 0.47, 0.24, 0.24))
        context.setLineWidth(width * 0.2)
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()

        context.setLineCap(.butt)
        context.setLineDash(phase: 0, lengths: [2.2, 3.6])
        context.setStrokeColor(rgba(0.55, 0.52, 0.48, 0.34))
        context.setLineWidth(max(0.7, width * 0.07))
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()
        context.setLineDash(phase: 0, lengths: [])

        for side in [-1.0, 1.0] {
            let path = CGMutablePath()
            let step = max(5, length / 9)
            var distance = 0.0
            var first = true
            while distance <= length {
                let offset = side * width * 0.4 + CGFloat.random(in: -0.9...0.9)
                let point = CGPoint(
                    x: start.x + unit.x * CGFloat(distance) + normal.x * offset,
                    y: start.y + unit.y * CGFloat(distance) + normal.y * offset
                )
                if first {
                    path.move(to: point)
                    first = false
                } else {
                    path.addLine(to: point)
                }
                distance += Double(step)
            }
            context.addPath(path)
            context.setStrokeColor(rgba(0.78, 0.72, 0.62, 0.24))
            context.setLineWidth(1.2)
            context.strokePath()
        }

        context.setStrokeColor(rgba(0.82, 0.82, 0.86, 0.16))
        context.setLineWidth(width * 0.1)
        context.setLineCap(.round)
        return context.makeImage().map { ($0, frame) }
    }

    static func renderWetSpot(at point: CGPoint, radius: CGFloat) -> (CGImage, CGRect)? {
        let frame = frame(at: point, radius: radius * 1.7)
        let image = cachedImage("wet", radius: radius, frameSize: frame.size) { context, center in
            drawRadial(
                in: context,
                at: center,
                radius: radius * 1.6,
                colors: [
                    rgba(0.26, 0.52, 0.9, 0.34),
                    rgba(0.24, 0.48, 0.86, 0.2),
                    rgba(0.2, 0.42, 0.82, 0)
                ]
            )
        }
        return image.map { ($0, frame) }
    }

    static func renderChewMarks(
        at point: CGPoint,
        radius: CGFloat,
        shape: ChewShape
    ) -> (CGImage, CGRect)? {
        guard radius > 0, shape != .none else { return nil }
        let frame = frame(at: point, radius: radius * 2.2)
        let image = cachedImage(
            "chew-\(shape)",
            radius: radius,
            variants: 8,
            frameSize: frame.size
        ) { context, center in

        switch shape {
        case .none:
            break
        case .narrow:
            context.setFillColor(rgba(0, 0, 0, 0.58))
            context.fillEllipse(in: ellipse(center: center, radiusX: radius * 1.15, radiusY: radius * 0.45))
            context.setStrokeColor(rgba(0.15, 0.08, 0.02, 0.25))
            context.setLineWidth(0.7)
            context.strokeEllipse(in: ellipse(center: center, radiusX: radius * 1.7, radiusY: radius * 0.7))
        case .leaf:
            context.setFillColor(rgba(0, 0, 0, 0.52))
            context.fillEllipse(in: ellipse(center: center, radiusX: radius, radiusY: radius * 0.78))
            for _ in 0..<5 {
                let angle = CGFloat.random(in: 0...(2 * .pi))
                let biteCenter = CGPoint(
                    x: center.x + cos(angle) * radius * 0.9,
                    y: center.y + sin(angle) * radius * 0.65
                )
                context.setFillColor(rgba(0.04, 0.07, 0.02, 0.28))
                context.fillEllipse(in: ellipse(center: biteCenter, radiusX: radius * 0.38, radiusY: radius * 0.3))
            }
        case .nibble:
            for _ in 0..<3 {
                let angle = CGFloat.random(in: 0...(2 * .pi))
                let biteCenter = CGPoint(
                    x: center.x + cos(angle) * radius * 0.7,
                    y: center.y + sin(angle) * radius * 0.55
                )
                context.setFillColor(rgba(0, 0, 0, CGFloat.random(in: 0.42...0.62)))
                context.fillEllipse(in: ellipse(center: biteCenter, radiusX: radius * 0.48, radiusY: radius * 0.35))
            }
        case .venom:
            context.setFillColor(rgba(0.06, 0.08, 0.03, 0.6))
            context.fillEllipse(in: ellipse(center: center, radiusX: radius * 0.8, radiusY: radius * 0.8))
            context.setStrokeColor(rgba(0.2, 0.45, 0.1, 0.35))
            context.setLineWidth(max(0.6, radius * 0.15))
            context.strokeEllipse(in: ellipse(center: center, radiusX: radius * 1.25, radiusY: radius * 1.15))
        case .bore:
            drawRadial(
                in: context,
                at: center,
                radius: radius * 1.6,
                colors: [rgba(0, 0, 0, 0.8), rgba(0.1, 0.08, 0.04, 0.25), rgba(0, 0, 0, 0)]
            )
            context.setStrokeColor(rgba(0.25, 0.18, 0.08, 0.3))
            context.setLineWidth(max(0.6, radius * 0.12))
            context.strokeEllipse(in: ellipse(center: center, radiusX: radius * 1.25, radiusY: radius * 1.25))
        case .pierce:
            for _ in 0..<2 {
                let offset = CGPoint(
                    x: center.x + CGFloat.random(in: -radius...radius),
                    y: center.y + CGFloat.random(in: -radius...radius)
                )
                context.setFillColor(rgba(0.36, 0.01, 0.03, 0.65))
                context.fillEllipse(in: ellipse(center: offset, radiusX: radius * 0.35, radiusY: radius * 0.35))
            }
        case .sting:
            context.setFillColor(rgba(0.9, 0.62, 0.05, 0.25))
            context.fillEllipse(in: ellipse(center: center, radiusX: radius * 1.4, radiusY: radius * 1.2))
            context.setFillColor(rgba(0.04, 0.03, 0, 0.66))
            context.fillEllipse(in: ellipse(center: center, radiusX: radius * 0.45, radiusY: radius * 0.45))
        case .speckle:
            for _ in 0..<7 {
                let offset = CGPoint(
                    x: center.x + CGFloat.random(in: -radius...radius) * 1.4,
                    y: center.y + CGFloat.random(in: -radius...radius) * 1.1
                )
                context.setFillColor(rgba(0.05, 0.04, 0, CGFloat.random(in: 0.28...0.5)))
                context.fillEllipse(in: ellipse(center: offset, radiusX: radius * 0.3, radiusY: radius * 0.25))
            }
        case .rasp:
            drawRadial(
                in: context,
                at: center,
                radius: radius * 1.5,
                colors: [rgba(0, 0, 0, 0.5), rgba(0.08, 0.08, 0.06, 0.22), rgba(0, 0, 0, 0)]
            )
            for _ in 0..<10 {
                let offset = CGPoint(
                    x: center.x + CGFloat.random(in: -radius...radius),
                    y: center.y + CGFloat.random(in: -radius...radius) * 0.7
                )
                context.setFillColor(rgba(0.02, 0.02, 0.02, 0.35))
                context.fillEllipse(in: ellipse(center: offset, radiusX: radius * 0.16, radiusY: radius * 0.12))
            }
        case .graze:
            for _ in 0..<6 {
                let angle = CGFloat.random(in: 0...(2 * .pi))
                let biteCenter = CGPoint(
                    x: center.x + cos(angle) * radius * 0.8,
                    y: center.y + sin(angle) * radius * 0.6
                )
                context.setFillColor(rgba(0.03, 0.03, 0.02, CGFloat.random(in: 0.42...0.62)))
                context.fillEllipse(in: ellipse(center: biteCenter, radiusX: radius * 0.55, radiusY: radius * 0.38))
            }
        case .tunnel:
            context.setStrokeColor(rgba(0, 0, 0, 0.5))
            context.setLineWidth(radius * 0.7)
            context.setLineCap(.round)
            context.move(to: CGPoint(x: center.x - radius * 1.2, y: center.y))
            context.addLine(to: CGPoint(x: center.x + radius * 1.2, y: center.y + radius * 0.2))
            context.strokePath()
        }

        }
        return image.map { ($0, frame) }
    }

    static func renderBloodSplat(at point: CGPoint, radius: CGFloat = 19) -> (CGImage, CGRect)? {
        let frame = frame(at: point, radius: radius * 1.55)
        let image = cachedImage("blood", radius: radius, variants: 8, frameSize: frame.size) { context, center in

            drawRadial(
                in: context,
                at: center,
                radius: radius,
                colors: [
                    rgba(0.58, 0.03, 0.05, 0.94),
                    rgba(0.40, 0.02, 0.04, 0.68),
                    rgba(0.20, 0.01, 0.02, 0)
                ]
            )

            for _ in 0..<9 {
                let angle = CGFloat.random(in: 0...(2 * .pi))
                let distance = radius * CGFloat.random(in: 0.4...1.35)
                let dropRadius = CGFloat.random(in: 1.2...3.6)
                let drop = CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance)
                context.setFillColor(rgba(0.49, 0.02, 0.04, CGFloat.random(in: 0.62...0.9)))
                context.fillEllipse(in: CGRect(
                    x: drop.x - dropRadius,
                    y: drop.y - dropRadius,
                    width: dropRadius * 2,
                    height: dropRadius * 2
                ))
            }
        }

        return image.map { ($0, frame) }
    }

    static func renderSlimeTrail(at point: CGPoint) -> (CGImage, CGRect)? {
        let radius: CGFloat = 8
        let frame = frame(at: point, radius: radius * 1.5)
        let image = cachedImage("slime", radius: radius, frameSize: frame.size) { context, center in
            drawRadial(
                in: context,
                at: center,
                radius: radius * 1.4,
                colors: [
                    rgba(0.56, 0.8, 0.38, 0.24),
                    rgba(0.42, 0.68, 0.3, 0.15),
                    rgba(0.3, 0.55, 0.25, 0)
                ]
            )
            context.setFillColor(rgba(0.65, 0.86, 0.5, 0.12))
            context.fillEllipse(in: ellipse(center: center, radiusX: radius * 1.3, radiusY: radius * 0.5))
        }
        return image.map { ($0, frame) }
    }

    static func renderWebStrand(at point: CGPoint, heading: CGFloat) -> (CGImage, CGRect)? {
        let radius: CGFloat = 12
        let frame = frame(at: point, radius: radius)
        let image = cachedImage(
            "web",
            radius: radius,
            angle: heading,
            frameSize: frame.size
        ) { context, center in
            let angle = -heading
            let start = CGPoint(x: center.x - cos(angle) * radius, y: center.y - sin(angle) * radius)
            let end = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            context.setStrokeColor(rgba(0.75, 0.82, 0.9, 0.14))
            context.setLineWidth(2.5)
            context.move(to: start)
            context.addLine(to: end)
            context.strokePath()
            context.setStrokeColor(rgba(0.92, 0.96, 1, 0.28))
            context.setLineWidth(0.8)
            context.strokePath()
        }
        return image.map { ($0, frame) }
    }

    static func renderPollen(at point: CGPoint) -> (CGImage, CGRect)? {
        speckleEffect(
            "pollen",
            at: point,
            radius: 8,
            colors: [rgba(1, 0.84, 0.24, 0.28), rgba(1, 0.72, 0.16, 0.16)]
        )
    }

    static func renderMagicDust(at point: CGPoint) -> (CGImage, CGRect)? {
        speckleEffect(
            "magic",
            at: point,
            radius: 10,
            colors: [rgba(0.48, 0.68, 1, 0.24), rgba(0.75, 0.45, 1, 0.16)]
        )
    }

    static func renderPawPrint(at point: CGPoint, heading: CGFloat) -> (CGImage, CGRect)? {
        let radius: CGFloat = 15
        let frame = frame(at: point, radius: radius)
        let image = cachedImage(
            "paw",
            radius: radius,
            angle: heading,
            frameSize: frame.size
        ) { context, center in
            let angle = -heading
            let forward = CGPoint(x: cos(angle), y: sin(angle))
            let side = CGPoint(x: -forward.y, y: forward.x)

            context.setFillColor(rgba(0.07, 0.05, 0.04, 0.2))
            context.fillEllipse(in: ellipse(
                center: CGPoint(x: center.x - forward.x * 4, y: center.y - forward.y * 4),
                radiusX: 5.8,
                radiusY: 4.6
            ))

            for index in -1...1 {
                let offset = CGFloat(index)
                let toe = CGPoint(
                    x: center.x + forward.x * 5 + side.x * offset * 4.5,
                    y: center.y + forward.y * 5 + side.y * offset * 4.5
                )
                context.fillEllipse(in: CGRect(x: toe.x - 1.7, y: toe.y - 2.3, width: 3.4, height: 4.6))
            }
        }
        return image.map { ($0, frame) }
    }

    static func renderFeather(at point: CGPoint, heading: CGFloat) -> (CGImage, CGRect)? {
        let radius: CGFloat = 12
        let frame = frame(at: point, radius: radius)
        let image = cachedImage(
            "feather",
            radius: radius,
            angle: heading,
            frameSize: frame.size
        ) { context, center in
            context.saveGState()
            context.translateBy(x: center.x, y: center.y)
            context.rotate(by: -heading)
            context.setFillColor(rgba(0.92, 0.95, 1, 0.1))
            context.fillEllipse(in: CGRect(x: -9, y: -3.2, width: 18, height: 6.4))
            context.setStrokeColor(rgba(1, 1, 1, 0.2))
            context.setLineWidth(0.8)
            context.move(to: CGPoint(x: -10, y: 0))
            context.addLine(to: CGPoint(x: 10, y: 0))
            context.strokePath()
            context.restoreGState()
        }
        return image.map { ($0, frame) }
    }

    static func renderBubbleTrail(at point: CGPoint) -> (CGImage, CGRect)? {
        let radius: CGFloat = 10
        let frame = frame(at: point, radius: radius)
        let image = cachedImage("bubble", radius: radius, variants: 6, frameSize: frame.size) { context, center in
            for _ in 0..<4 {
                let bubbleRadius = CGFloat.random(in: 1.5...4.2)
                let offset = CGPoint(
                    x: CGFloat.random(in: -7...7),
                    y: CGFloat.random(in: -7...7)
                )
                let bubble = CGPoint(x: center.x + offset.x, y: center.y + offset.y)
                context.setStrokeColor(rgba(0.72, 0.9, 1, 0.16))
                context.setLineWidth(0.8)
                context.strokeEllipse(in: CGRect(
                    x: bubble.x - bubbleRadius,
                    y: bubble.y - bubbleRadius,
                    width: bubbleRadius * 2,
                    height: bubbleRadius * 2
                ))
            }
        }
        return image.map { ($0, frame) }
    }

    static func addDamage(_ geometry: CrackGeometry) -> (CGImage, CGRect)? {
        let frame = frame(for: geometry)
        return renderCrackCluster(geometry, in: frame)
    }

    private static func makeContext(_ frame: CGRect) -> CGContext? {
        makeContext(size: frame.size)
    }

    private static func makeContext(size: CGSize) -> CGContext? {
        let width = max(1, Int((size.width * renderScale).rounded(.up)))
        let height = max(1, Int((size.height * renderScale).rounded(.up)))
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.scaleBy(x: renderScale, y: renderScale)
        return context
    }

    private static func cachedImage(
        _ kind: String,
        radius: CGFloat,
        angle: CGFloat? = nil,
        variants: Int = 1,
        frameSize: CGSize,
        render: (CGContext, CGPoint) -> Void
    ) -> CGImage? {
        let radiusBucket = Int((max(1, radius) / 2).rounded())
        let angleBucket = angle.map { heading -> Int in
            let normalized = atan2(sin(heading), cos(heading))
            return Int(((normalized + .pi) / (.pi / 8)).rounded())
        } ?? 0
        let variant = variants > 1 ? Int.random(in: 0..<variants) : 0
        let cacheKey = "\(kind):\(radiusBucket):\(angleBucket):\(variant)" as NSString
        imageCache.countLimit = 2048
        if let cached = imageCache.object(forKey: cacheKey) {
            return cached.image
        }

        guard let context = makeContext(size: frameSize) else { return nil }
        render(context, CGPoint(x: frameSize.width / 2, y: frameSize.height / 2))
        let image = context.makeImage()
        imageCache.setObject(CachedImage(image), forKey: cacheKey)
        return image
    }

    private static func pt(_ point: CGPoint, in frame: CGRect) -> CGPoint {
        let flipY = frame.minY + frame.height
        return CGPoint(x: point.x - frame.minX, y: flipY - point.y)
    }

    private static func gray(_ value: CGFloat, _ alpha: CGFloat) -> CGColor {
        CGColor(red: value, green: value, blue: value, alpha: alpha)
    }

    private static func rgba(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat) -> CGColor {
        CGColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    private static func ellipse(center: CGPoint, radiusX: CGFloat, radiusY: CGFloat) -> CGRect {
        CGRect(
            x: center.x - radiusX,
            y: center.y - radiusY,
            width: radiusX * 2,
            height: radiusY * 2
        )
    }

    private static func speckleEffect(
        _ kind: String,
        at point: CGPoint,
        radius: CGFloat,
        colors: [CGColor]
    ) -> (CGImage, CGRect)? {
        let frame = frame(at: point, radius: radius * 1.3)
        let image = cachedImage(
            kind,
            radius: radius,
            variants: 8,
            frameSize: frame.size
        ) { context, center in
            for _ in 0..<7 {
                let angle = CGFloat.random(in: 0...(2 * .pi))
                let distance = radius * CGFloat.random(in: 0.1...1.1)
                let dot = CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance)
                context.setFillColor(colors.randomElement() ?? colors[0])
                let dotRadius = CGFloat.random(in: 0.8...2.1)
                context.fillEllipse(in: ellipse(center: dot, radiusX: dotRadius, radiusY: dotRadius))
            }
        }
        return image.map { ($0, frame) }
    }

    private static func drawRadial(
        in context: CGContext,
        at point: CGPoint,
        radius: CGFloat,
        colors: [CGColor]
    ) {
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: nil
        ) else { return }
        context.drawRadialGradient(
            gradient,
            startCenter: point,
            startRadius: 0,
            endCenter: point,
            endRadius: max(1, radius),
            options: []
        )
    }
}
