import AppKit

/// Unified desktop coordinate: AppKit view space with a bottom-left origin.
struct DesktopPoint {
    var x: CGFloat
    var y: CGFloat
}

enum DesktopCoordinateMapper {
    static func point(from event: NSEvent, in view: NSView) -> DesktopPoint {
        let point = view.convert(event.locationInWindow, from: nil)
        return DesktopPoint(x: point.x, y: point.y)
    }

    static func cgPoint(_ point: DesktopPoint) -> CGPoint {
        CGPoint(x: point.x, y: point.y)
    }
}
