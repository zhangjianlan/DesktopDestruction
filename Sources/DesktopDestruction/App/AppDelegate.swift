import AppKit
import CoreGraphics

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: OverlayCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[DesktopDestruction] launched")
        guard let screen = NSScreen.main else { return }

        // Canvas mode is the default: no screen-recording permission and no
        // transparent-desktop compositing. Legacy capture remains opt-in.
        if usesDesktopCapture {
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
        } else {
            PipelineLog.info("canvas mode enabled")
            startOverlay(
                background: CanvasBackgroundRenderer.render(size: screen.frame.size)
            )
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    func applicationWillTerminate(_ notification: Notification) {
        AudioManager.shared.stopAllLoops()
    }

    private var usesDesktopCapture: Bool {
        ProcessInfo.processInfo.environment["DD_CAPTURE_DESKTOP"] != nil
    }

    private func startOverlay(background: CGImage) {
        guard let screen = NSScreen.main else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }

            let window = OverlayWindow(screenFrame: screen.frame)
            let coordinator = OverlayCoordinator(window: window, background: background)
            self.coordinator = coordinator
            coordinator.start()
            PipelineLog.info("overlay start confirmed")
        }
    }
}
