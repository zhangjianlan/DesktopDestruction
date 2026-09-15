import AppKit

final class OverlayCoordinator {
    private let window: OverlayWindow
    private let toolbar: ToolbarController
    private let controller: DestructionController
    private let view: OverlayView

    init(window: OverlayWindow, background: CGImage) {
        self.window = window

        let view = OverlayView(frame: NSRect(origin: .zero, size: window.frame.size))
        let toolbar = ToolbarController()
        let controller = DestructionController(view: view, background: background, toolbar: toolbar)
        self.view = view
        self.toolbar = toolbar
        self.controller = controller

        view.controller = controller
        view.onExit = { AppRuntime.quit() }
        controller.onExit = { AppRuntime.quit() }

        toolbar.onTool = { [weak controller] tool in
            controller?.toolManager.select(tool)
        }
        toolbar.onRestore = { [weak controller] in
            controller?.restoreAll()
        }
        toolbar.onSettings = {
            SettingsWindowController.shared.show()
        }
        toolbar.onExit = { AppRuntime.quit() }

        window.contentView = view
        window.initialFirstResponder = view
        let bounds = view.bounds
        toolbar.view.frame = CGRect(
            x: bounds.midX - toolbar.view.bounds.width / 2,
            y: bounds.height - toolbar.view.bounds.height - 14,
            width: toolbar.view.bounds.width,
            height: toolbar.view.bounds.height
        )
        toolbar.view.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin]
        view.addSubview(toolbar.view)
        controller.layout()
        view.attachWheel()
    }

    func start() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window.makeFirstResponder(view)
        toolbar.showAndScheduleHide()
    }
}
