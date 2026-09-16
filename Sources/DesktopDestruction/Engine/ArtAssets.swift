import AppKit
import CoreGraphics
import ImageIO

enum ArtAssets {
    private final class CachedImage {
        let image: CGImage?

        init(_ image: CGImage?) {
            self.image = image
        }
    }

    private static let cache = NSCache<NSString, CachedImage>()

    static func image(named name: String) -> CGImage? {
        let key = name as NSString
        cache.countLimit = 128
        if let cached = cache.object(forKey: key) {
            return cached.image
        }

        guard let url = Bundle.module.url(
            forResource: name,
            withExtension: "png",
            subdirectory: "Resources/Art"
        ) else {
            PipelineLog.info("missing art asset: \(name)")
            return nil
        }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            PipelineLog.info("unreadable art asset: \(name)")
            return nil
        }

        cache.setObject(CachedImage(image), forKey: key)
        return image
    }

    static func nsImage(named name: String) -> NSImage? {
        guard let image = image(named: name) else { return nil }
        return NSImage(
            cgImage: image,
            size: NSSize(width: image.width, height: image.height)
        )
    }
}
