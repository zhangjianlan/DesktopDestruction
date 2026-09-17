import XCTest
@testable import DesktopDestruction

final class PerformanceOptimizationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        PerformanceGovernor.resetForTesting()
    }

    override func tearDown() {
        PerformanceGovernor.resetForTesting()
        super.tearDown()
    }

    func testPerformanceProfilesReduceWorkAsLoadIncreases() {
        let light = PerformanceGovernor.profile(creatureCount: 30, burningFireCount: 5)
        let medium = PerformanceGovernor.profile(creatureCount: 80, burningFireCount: 15)
        let heavy = PerformanceGovernor.profile(creatureCount: 140, burningFireCount: 30)
        let extreme = PerformanceGovernor.profile(creatureCount: 200, burningFireCount: 50)

        XCTAssertEqual(light.interactionStride, 1)
        XCTAssertEqual(medium.interactionStride, 2)
        XCTAssertEqual(heavy.interactionStride, 3)
        XCTAssertEqual(extreme.interactionStride, 4)
        XCTAssertGreaterThan(light.particleScale, medium.particleScale)
        XCTAssertGreaterThan(medium.particleScale, heavy.particleScale)
        XCTAssertGreaterThan(heavy.particleScale, extreme.particleScale)
        XCTAssertLessThan(light.simulationInterval, extreme.simulationInterval)
    }

    func testSlowTicksAlsoTriggerPerformanceScaling() {
        let profile = PerformanceGovernor.profile(
            creatureCount: 20,
            burningFireCount: 4,
            recentTickDuration: 0.052
        )

        XCTAssertEqual(profile.particleScale, 0.45)
        XCTAssertTrue(profile.lowDetail)
    }

    func testSpatialGridReturnsOnlyCreaturesWithinRequestedReach() {
        let near = CreatureActor(at: CGPoint(x: 55, y: 0), kind: .person(.walker))
        let far = CreatureActor(at: CGPoint(x: 700, y: 0), kind: .person(.walker))
        let grid = CreatureSpatialGrid(creatures: [near, far])

        let candidates = grid.nearbyActors(point: .zero, radius: 40)

        XCTAssertTrue(candidates.contains(where: { $0 === near }))
        XCTAssertFalse(candidates.contains(where: { $0 === far }))
        XCTAssertTrue(near.hitTest(.zero, radius: 40))
        XCTAssertFalse(far.hitTest(.zero, radius: 40))
    }
}
