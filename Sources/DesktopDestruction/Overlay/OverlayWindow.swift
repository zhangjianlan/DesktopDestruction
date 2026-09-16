import AppKit

final class OverlayWindow: NSWindow {
    init(screenFrame: CGRect) {
        super.init(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        backgroundColor = .black
        isOpaque = true
        hasShadow = false
        ignoresMouseEvents = false
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        acceptsMouseMovedEvents = true
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
