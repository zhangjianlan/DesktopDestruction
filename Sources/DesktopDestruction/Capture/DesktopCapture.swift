import AppKit
import CoreGraphics
import ScreenCaptureKit

enum DesktopCapture {
    static var hasPermission: Bool { CGPreflightScreenCaptureAccess() }

    struct CaptureAttempt {
        let image: CGImage?
        let diagnostic: String
    }

    static func requestPermission() {
        _ = CGRequestScreenCaptureAccess()
    }

    /// One-shot composite of the main display (wallpaper, icons and windows).
    /// The image is only read into memory; the real desktop is never modified.
    static func captureMainDisplay() async -> CaptureAttempt {
        let preflightGranted = hasPermission
        PipelineLog.info("screen-capture attempt preflight=\(preflightGranted)")
        guard let screen = NSScreen.main else {
            let diagnostic = "预检=\(permissionText(preflightGranted))；失败原因=找不到主屏幕"
            PipelineLog.info("ScreenCaptureKit found no main screen")
            return CaptureAttempt(image: nil, diagnostic: diagnostic)
        }

        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: false
            )
            guard let display = content.displays.first else {
                PipelineLog.info("ScreenCaptureKit found no display")
                let diagnostic = "预检=\(permissionText(preflightGranted))；失败原因=ScreenCaptureKit 没有返回显示器"
                return CaptureAttempt(image: nil, diagnostic: diagnostic)
            }

            let filter = SCContentFilter(display: display, excludingWindows: [])
            let configuration = SCStreamConfiguration()
            let scale = screen.backingScaleFactor
            configuration.width = Int(screen.frame.width * scale)
            configuration.height = Int(screen.frame.height * scale)
            configuration.showsCursor = false

            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: configuration
            )
            PipelineLog.info("capture source=ScreenCaptureKit display=\(display.displayID) width=\(image.width) height=\(image.height)")
            return CaptureAttempt(
                image: image,
                diagnostic: "预检=\(permissionText(preflightGranted))；真实截图=成功"
            )
        } catch {
            let errorText = String(describing: error)
            PipelineLog.info("ScreenCaptureKit capture failed: \(errorText)")
            return CaptureAttempt(
                image: nil,
                diagnostic: "预检=\(permissionText(preflightGranted))；真实截图失败=\(errorText)"
            )
        }
    }

    private static func permissionText(_ granted: Bool) -> String {
        granted ? "已通过" : "未通过"
    }

    /// Synthetic background for development and testing without screen access.
    static func syntheticBackground(size: CGSize) -> CGImage {
        let scale: CGFloat = 2
        let width = max(2, Int(size.width * scale))
        let height = max(2, Int(size.height * scale))
        let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        ctx.scaleBy(x: scale, y: scale)

        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                CGColor(red: 0.13, green: 0.32, blue: 0.58, alpha: 1),
                CGColor(red: 0.04, green: 0.09, blue: 0.20, alpha: 1)
            ] as CFArray,
            locations: [0, 1]
        )!
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size.height), end: CGPoint(x: 0, y: 0), options: [])

        for i in 0..<5 {
            let x = 64 + CGFloat(i) * 120
            let y = size.height - 150
            ctx.setFillColor(CGColor(gray: 1, alpha: 0.16))
            let rect = CGRect(x: x, y: y, width: 66, height: 66)
            let path = CGPath(roundedRect: rect, cornerWidth: 12, cornerHeight: 12, transform: nil)
            ctx.addPath(path)
            ctx.fillPath()
            ctx.setFillColor(CGColor(gray: 1, alpha: 0.4))
            ctx.fillEllipse(in: CGRect(x: x + 21, y: y + 20, width: 24, height: 24))
        }

        let windowRect = CGRect(
            x: size.width * 0.22,
            y: size.height * 0.24,
            width: size.width * 0.56,
            height: size.height * 0.44
        )
        ctx.setFillColor(CGColor(gray: 0.94, alpha: 0.9))
        let winPath = CGPath(roundedRect: windowRect, cornerWidth: 10, cornerHeight: 10, transform: nil)
        ctx.addPath(winPath)
        ctx.fillPath()
        ctx.setFillColor(CGColor(gray: 0.82, alpha: 1))
        ctx.fill(CGRect(x: windowRect.minX, y: windowRect.maxY - 30, width: windowRect.width, height: 30))
        let dotColors: [CGColor] = [
            CGColor(red: 1, green: 0.35, blue: 0.3, alpha: 1),
            CGColor(red: 1, green: 0.8, blue: 0.25, alpha: 1),
            CGColor(red: 0.35, green: 0.85, blue: 0.4, alpha: 1)
        ]
        for i in 0..<3 {
            let x = windowRect.minX + 14 + CGFloat(i) * 20
            ctx.setFillColor(dotColors[i])
            ctx.fillEllipse(in: CGRect(x: x, y: windowRect.maxY - 22, width: 10, height: 10))
        }

        drawSyntheticLabel(in: ctx, size: size)
        return ctx.makeImage()!
    }

    private static func drawSyntheticLabel(in ctx: CGContext, size: CGSize) {
        let nsContext = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext
        let text = "开发测试背景（未捕获真实桌面）"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 22, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.7)
        ]
        let str = NSAttributedString(string: text, attributes: attributes)
        let textSize = str.size()
        str.draw(at: NSPoint(x: (size.width - textSize.width) / 2, y: size.height * 0.5))
        NSGraphicsContext.restoreGraphicsState()
    }
}
