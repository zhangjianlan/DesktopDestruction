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
        image(named: name, subdirectory: "Resources/Art")
    }

    static func character(named name: String) -> CGImage? {
        image(named: name, subdirectory: "Resources/Characters")
    }

    static func openMoji(_ emoji: String) -> CGImage? {
        let scalars = emoji.unicodeScalars.filter { $0.value != 0xFE0F }
        let name = scalars
            .map { String(format: "%04X", $0.value) }
            .joined(separator: "-")
        return image(named: name, subdirectory: "Resources/OpenMoji")
    }

    private static func image(named name: String, subdirectory: String) -> CGImage? {
        let key = name as NSString
        cache.countLimit = 512
        if let cached = cache.object(forKey: key) {
            return cached.image
        }

        guard let url = Bundle.module.url(
            forResource: name,
            withExtension: "png",
            subdirectory: subdirectory
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
}
