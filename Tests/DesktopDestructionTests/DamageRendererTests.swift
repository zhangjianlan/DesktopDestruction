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
}
