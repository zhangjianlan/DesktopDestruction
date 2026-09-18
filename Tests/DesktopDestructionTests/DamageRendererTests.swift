import XCTest
@testable import DesktopDestruction

final class DamageRendererTests: XCTestCase {
    func testCutSegmentProducesBoundedImage() {
        let start = CGPoint(x: 20, y: 34)
        let end = CGPoint(x: 92, y: 58)
        let rendered = DamageRenderer.renderCutSegment(from: start, to: end, width: 18)

        XCTAssertNotNil(rendered?.0)
        XCTAssertGreaterThan(rendered?.1.width ?? 0, 0)
        XCTAssertGreaterThan(rendered?.1.height ?? 0, 0)
        XCTAssertTrue(rendered?.1.contains(start) ?? false)
        XCTAssertTrue(rendered?.1.contains(end) ?? false)
    }

    func testPoopSplatProducesBoundedImage() {
        let point = CGPoint(x: 120, y: 86)
        let rendered = DamageRenderer.renderPoopSplat(at: point, radius: 36)

        XCTAssertNotNil(rendered?.0)
        XCTAssertEqual(rendered?.1.minX ?? 0, point.x - 70.2, accuracy: 0.1)
        XCTAssertEqual(rendered?.1.minY ?? 0, point.y - 70.2, accuracy: 0.1)
        XCTAssertEqual(rendered?.1.width ?? 0, 140.4, accuracy: 0.1)
        XCTAssertEqual(rendered?.1.height ?? 0, 140.4, accuracy: 0.1)
        XCTAssertTrue(rendered?.1.contains(point) ?? false)
    }
}
