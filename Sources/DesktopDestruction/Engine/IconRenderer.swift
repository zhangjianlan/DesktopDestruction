import AppKit
import CoreGraphics

enum IconRenderer {
    private final class CachedImage {
        let image: CGImage?

        init(_ image: CGImage?) {
            self.image = image
        }
    }

    private static let imageCache = NSCache<NSString, CachedImage>()

    static func emoji(_ text: String, size: CGFloat) -> CGImage? {
        let renderSize = max(8, (size / 2).rounded() * 2)
        let cacheKey = "emoji:\(Int(renderSize)):\(text)" as NSString
        imageCache.countLimit = 1024
        if let cached = imageCache.object(forKey: cacheKey) {
            return cached.image
        }

        let frame = CGSize(width: renderSize * 1.4, height: renderSize * 1.4)
        let image = NSImage(size: frame)
        image.lockFocus()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: renderSize)
        ]
        let string = NSAttributedString(string: text, attributes: attributes)
        let textSize = string.size()
        string.draw(at: NSPoint(
            x: (frame.width - textSize.width) / 2,
            y: (frame.height - textSize.height) / 2
        ))
        image.unlockFocus()
        var rect = CGRect(origin: .zero, size: frame)
        let result = image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
        imageCache.setObject(CachedImage(result), forKey: cacheKey)
        return result
    }

    static func softCircle(_ color: NSColor = .white, diameter: CGFloat = 48) -> CGImage? {
        let renderDiameter = max(4, (diameter / 4).rounded() * 4)
        let cacheKey = "circle:\(Int(renderDiameter)):\(colorCacheKey(color))" as NSString
        imageCache.countLimit = 1024
        if let cached = imageCache.object(forKey: cacheKey) {
            return cached.image
        }

        let pixelSize = Int(renderDiameter.rounded(.up))
        guard let context = CGContext(
            data: nil,
            width: pixelSize,
            height: pixelSize,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                color.cgColor,
                color.withAlphaComponent(0.75).cgColor,
                color.withAlphaComponent(0).cgColor
            ] as CFArray,
            locations: [0, 0.28, 1]
        ) else { return nil }
        let center = CGPoint(x: renderDiameter / 2, y: renderDiameter / 2)
        context.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: renderDiameter / 2,
            options: []
        )
        let result = context.makeImage()
        imageCache.setObject(CachedImage(result), forKey: cacheKey)
        return result
    }

    static func triangle(_ color: NSColor) -> CGImage? {
        let cacheKey = "triangle:\(colorCacheKey(color))" as NSString
        imageCache.countLimit = 1024
        if let cached = imageCache.object(forKey: cacheKey) {
            return cached.image
        }

        let size: CGFloat = 12
        guard let context = CGContext(
            data: nil,
            width: Int(size),
            height: Int(size),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.setFillColor(color.cgColor)
        context.move(to: CGPoint(x: size / 2, y: size))
        context.addLine(to: CGPoint(x: 0, y: 0))
        context.addLine(to: CGPoint(x: size, y: 0))
        context.closePath()
        context.fillPath()
        let result = context.makeImage()
        imageCache.setObject(CachedImage(result), forKey: cacheKey)
        return result
    }

    private static func colorCacheKey(_ color: NSColor) -> String {
        let deviceColor = color.usingColorSpace(.deviceRGB) ?? color
        return [
            deviceColor.redComponent,
            deviceColor.greenComponent,
            deviceColor.blueComponent,
            deviceColor.alphaComponent
        ]
        .map { String(format: "%.3f", $0) }
        .joined(separator: "-")
    }
}
