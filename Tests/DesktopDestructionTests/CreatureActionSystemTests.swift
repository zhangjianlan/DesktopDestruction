import XCTest
@testable import DesktopDestruction

final class CreatureActionSystemTests: XCTestCase {
    func testActionPriorityAndMovementMapping() {
        var system = CreatureActionSystem()

        XCTAssertEqual(
            system.update(
                dt: 0.1,
                context: context(movement: .walk, isBurning: true)
            ),
            .burning
        )

        system = CreatureActionSystem()
        XCTAssertEqual(
            system.update(
                dt: 0.1,
                context: context(movement: .walk, isPanicking: true)
            ),
            .panic
        )

        system = CreatureActionSystem()
        XCTAssertEqual(
            system.update(
                dt: 0.1,
                context: context(movement: .crawl, isVehicle: true)
            ),
            .drive
        )

        system = CreatureActionSystem()
        XCTAssertEqual(
            system.update(
                dt: 0.1,
                context: context(movement: .chase, isZombie: true)
            ),
            .stalk
        )

        system = CreatureActionSystem()
        XCTAssertEqual(
            system.update(
                dt: 0.1,
                context: context(movement: .run, actualSpeed: 0)
            ),
            .idle
        )
    }

    func testTransientActionFallsBackToResolvedAction() {
        var system = CreatureActionSystem()
        system.begin(.bite, duration: 0.2)

        XCTAssertEqual(
            system.update(
                dt: 0.1,
                context: context(movement: .walk, isPanicking: true)
            ),
            .bite
        )
        XCTAssertEqual(
            system.update(
                dt: 0.15,
                context: context(movement: .walk, isPanicking: true)
            ),
            .panic
        )
    }

    func testTransformChangesOverActionTimeline() {
        var system = CreatureActionSystem()
        system.begin(.bite, duration: 0.24)
        let initial = system.transform(
            heading: 0,
            bodySize: 100,
            rotatesWithHeading: false,
            facingLeft: false
        )

        _ = system.update(
            dt: 0.06,
            context: context(movement: .chase, isZombie: true)
        )
        let animated = system.transform(
            heading: 0,
            bodySize: 100,
            rotatesWithHeading: false,
            facingLeft: false
        )

        XCTAssertGreaterThan(abs(animated.tx - initial.tx), 0.5)
        XCTAssertGreaterThan(abs(animated.a - initial.a), 0.01)
    }

    private func context(
        movement: CreatureMovement,
        actualSpeed: CGFloat = 80,
        baseSpeed: CGFloat = 100,
        isBurning: Bool = false,
        isPanicking: Bool = false,
        isZombie: Bool = false,
        isVehicle: Bool = false
    ) -> CreatureActionContext {
        CreatureActionContext(
            movement: movement,
            actualSpeed: actualSpeed,
            baseSpeed: baseSpeed,
            isBurning: isBurning,
            isPanicking: isPanicking,
            isZombie: isZombie,
            isVehicle: isVehicle
        )
    }
}
