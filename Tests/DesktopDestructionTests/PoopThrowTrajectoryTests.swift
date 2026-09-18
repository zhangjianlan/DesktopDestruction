import XCTest
@testable import DesktopDestruction

final class PoopThrowTrajectoryTests: XCTestCase {
    func testTrajectoryStartsBelowScreenAndArcsAboveTarget() {
        let bounds = CGRect(x: 0, y: 0, width: 1600, height: 900)
        let target = CGPoint(x: 800, y: 450)
        let trajectory = PoopThrowTrajectory.make(target: target, bounds: bounds)

        XCTAssertLessThan(trajectory.start.y, bounds.minY)
        XCTAssertGreaterThan(trajectory.control.y, target.y)
        XCTAssertEqual(trajectory.start.x, 580, accuracy: 0.1)
        XCTAssertEqual(trajectory.control.x, 905.6, accuracy: 0.1)
        XCTAssertGreaterThan(trajectory.duration, 0.64)
        XCTAssertLessThan(trajectory.duration, 0.94)
    }

    func testSampledPathLeavesBottomAndLandsOnTarget() {
        let bounds = CGRect(x: 0, y: 0, width: 1600, height: 900)
        let target = CGPoint(x: 800, y: 450)
        let trajectory = PoopThrowTrajectory.make(target: target, bounds: bounds)

        let earlyPoint = trajectory.point(at: 0.08)
        let nearApex = trajectory.point(at: 0.7)
        let landing = trajectory.point(at: 1)

        XCTAssertGreaterThan(earlyPoint.y, trajectory.start.y)
        XCTAssertGreaterThan(nearApex.y, target.y)
        XCTAssertEqual(landing.x, target.x, accuracy: 0.1)
        XCTAssertEqual(landing.y, target.y, accuracy: 0.1)
    }
}
