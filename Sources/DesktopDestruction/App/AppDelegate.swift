import AppKit
import CoreGraphics

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: OverlayCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[DesktopDestruction] launched")
        guard let screen = NSScreen.main else { return }

        // Capture the real desktop by default. The comic canvas remains useful
        // for demos and permission troubleshooting, but is opt-in only.
        if usesSyntheticCanvas {
            PipelineLog.info("synthetic canvas mode enabled")
            startOverlay(
                background: CanvasBackgroundRenderer.render(size: screen.frame.size)
            )
        } else {
            PermissionGateController.shared.run(
                capture: { await DesktopCapture.captureMainDisplay() },
                onReady: { [weak self] image in
                    self?.startOverlay(background: image)
                },
                onUseSyntheticBackground: { [weak self] in
                    guard let screen = NSScreen.main else { return }
                    self?.startOverlay(
                        background: CanvasBackgroundRenderer.render(size: screen.frame.size)
                    )
                },
                onQuit: { AppRuntime.quit() }
            )
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    func applicationWillTerminate(_ notification: Notification) {
        AudioManager.shared.stopAllLoops()
    }

    private var usesSyntheticCanvas: Bool {
        guard let value = ProcessInfo.processInfo.environment["DD_CANVAS_MODE"] else {
            return false
        }
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.isEmpty || normalized == "1" || normalized == "true" || normalized == "yes"
    }

    private func startOverlay(background: CGImage) {
        guard let screen = NSScreen.main else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }

            let window = OverlayWindow(screenFrame: screen.frame)
            let coordinator = OverlayCoordinator(window: window, background: background)
            self.coordinator = coordinator
            coordinator.start()
            AudioManager.shared.preloadCommonSounds()
            PipelineLog.info("overlay start confirmed")
        }
    }
}
