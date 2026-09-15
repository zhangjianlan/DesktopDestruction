import CoreGraphics
import Foundation

struct CrackSegment {
    var from: CGPoint
    var to: CGPoint
    var width: CGFloat
    var alpha: CGFloat
}

struct CrackGeometry {
    var origin: CGPoint
    var segments: [CrackSegment]
    var blotRadius: CGFloat

    var points: [CGPoint] {
        var result = [origin]
        for segment in segments {
            result.append(segment.from)
            result.append(segment.to)
        }
        return result
    }
}

enum CrackGenerator {
    static func cluster(at point: CGPoint, radius: CGFloat, strength: CGFloat = 1) -> CrackGeometry {
        var geometry = CrackGeometry(origin: point, segments: [], blotRadius: radius * 0.12 * strength)
        let armCount = Int.random(in: 4...6)
        for arm in 0..<armCount {
            let baseAngle = CGFloat(arm) * (2 * .pi) / CGFloat(armCount) + CGFloat.random(in: -0.24...0.24)
            addArm(
                to: &geometry,
                from: point,
                angle: baseAngle,
                length: radius * CGFloat.random(in: 0.7...1.1),
                width: max(1.4, 4.2 * strength),
                alpha: 0.85,
                segments: Int.random(in: 3...5)
            )
        }
        return geometry
    }

    private static func addArm(
        to geometry: inout CrackGeometry,
        from point: CGPoint,
        angle: CGFloat,
        length: CGFloat,
        width: CGFloat,
        alpha: CGFloat,
        segments: Int
    ) {
        var current = point
        var currentAngle = angle
        var currentWidth = width
        var remainingLength = length
        let stepLength = length / CGFloat(segments)

        for index in 0..<segments {
            currentAngle += CGFloat.random(in: -0.55...0.55)
            let next = CGPoint(
                x: current.x + cos(currentAngle) * stepLength,
                y: current.y + sin(currentAngle) * stepLength
            )
            geometry.segments.append(CrackSegment(
                from: current,
                to: next,
                width: currentWidth,
                alpha: alpha
            ))

            if index == 1 && width > 1.5 {
                addArm(
                    to: &geometry,
                    from: next,
                    angle: currentAngle + CGFloat.random(in: -1.1...1.1),
                    length: remainingLength * 0.35,
                    width: currentWidth * 0.55,
                    alpha: alpha * 0.7,
                    segments: 2
                )
            }

            current = next
            currentWidth = max(0.6, currentWidth * 0.76)
            remainingLength -= stepLength
        }
    }
}
