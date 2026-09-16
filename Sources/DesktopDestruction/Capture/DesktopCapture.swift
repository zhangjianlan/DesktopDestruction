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
}
