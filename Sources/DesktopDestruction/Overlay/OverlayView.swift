import AppKit

extension NSCursor {
    static let invisibleCursor = NSCursor(
        image: NSImage(size: NSSize(width: 1, height: 1), flipped: false) { rect in
            NSColor.clear.setFill()
            NSBezierPath(rect: rect).fill()
            return true
        },
        hotSpot: .zero
    )
}

final class OverlayView: NSView {
    var controller: DestructionController!
    var onExit: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    private let wheel = ToolWheel()
    private var trackingArea: NSTrackingArea?

    func attachWheel() {
        wheel.attach(to: layer)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .invisibleCursor)
    }

    override func layout() {
        super.layout()
        controller?.layout()
    }

    override func mouseMoved(with event: NSEvent) {
        controller?.pointerMoved(to: convert(event.locationInWindow, from: nil))
    }

    override func mouseDown(with event: NSEvent) {
        if window?.firstResponder is NSView, window?.firstResponder !== self {
            window?.makeFirstResponder(self)
        }
        controller?.handleMouseDown(at: convert(event.locationInWindow, from: nil))
    }

    override func mouseDragged(with event: NSEvent) {
        controller?.handleMouseDragged(to: convert(event.locationInWindow, from: nil))
    }

    override func mouseUp(with event: NSEvent) {
        controller?.handleMouseUp()
    }

    override func rightMouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        controller?.pointerMoved(to: point)
        wheel.begin(at: point)
    }

    override func rightMouseDragged(with event: NSEvent) {
        wheel.update(at: convert(event.locationInWindow, from: nil))
    }

    override func rightMouseUp(with event: NSEvent) {
        if let tool = wheel.commit() {
            controller?.toolManager.select(tool)
        }
    }

    override func scrollWheel(with event: NSEvent) {
        controller?.toolManager.cycle(event.deltaY > 0 ? -1 : 1)
    }

    override func keyDown(with event: NSEvent) {
        guard let characters = event.characters else { return }
        if characters == "\u{1B}" {
            wheel.dismiss()
            controller?.handleEscape()
            return
        }
        if characters.lowercased() == "r" {
            controller?.restoreAll()
            return
        }
        if let digit = characters.first?.wholeNumberValue, (1...9).contains(digit) || digit == 0 {
            controller?.toolManager.select(number: digit == 0 ? 10 : digit)
            return
        }
        if characters.lowercased() == "p" {
            controller?.toolManager.select(.person)
            return
        }
        if characters.lowercased() == "a" {
            controller?.toolManager.select(.animal)
            return
        }
        if characters.lowercased() == "v" {
            controller?.toolManager.select(.vehicle)
            return
        }
        if characters.lowercased() == "e" {
            controller?.toolManager.select(.anything)
            return
        }
        if characters.lowercased() == "w" {
            controller?.toolManager.select(.wall)
            return
        }
        super.keyDown(with: event)
    }
}
