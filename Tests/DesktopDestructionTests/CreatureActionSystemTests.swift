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

    func testMotionIntensityChangesTransformAmplitude() {
        var slowSystem = CreatureActionSystem()
        var fastSystem = CreatureActionSystem()

        for _ in 0..<2 {
            _ = slowSystem.update(
                dt: 0.1,
                context: context(movement: .run, actualSpeed: 20, baseSpeed: 100)
            )
            _ = fastSystem.update(
                dt: 0.1,
                context: context(movement: .run, actualSpeed: 180, baseSpeed: 100)
            )
        }

        let slowTransform = slowSystem.transform(
            heading: 0,
            bodySize: 100,
            rotatesWithHeading: false,
            facingLeft: false
        )
        let fastTransform = fastSystem.transform(
            heading: 0,
            bodySize: 100,
            rotatesWithHeading: false,
            facingLeft: false
        )

        XCTAssertGreaterThan(fastTransform.ty, slowTransform.ty + 0.5)
    }

    func testAnimationPhasePreventsCrowdSynchronization() {
        var firstSystem = CreatureActionSystem(animationPhase: 0)
        var secondSystem = CreatureActionSystem(animationPhase: 0.17)

        _ = firstSystem.update(
            dt: 0.1,
            context: context(movement: .walk, actualSpeed: 80, baseSpeed: 100)
        )
        _ = secondSystem.update(
            dt: 0.1,
            context: context(movement: .walk, actualSpeed: 80, baseSpeed: 100)
        )

        let firstTransform = firstSystem.transform(
            heading: 0,
            bodySize: 100,
            rotatesWithHeading: false,
            facingLeft: false
        )
        let secondTransform = secondSystem.transform(
            heading: 0,
            bodySize: 100,
            rotatesWithHeading: false,
            facingLeft: false
        )

        XCTAssertNotEqual(firstTransform.ty, secondTransform.ty, accuracy: 0.01)
    }

    func testRadiationMonsterHasHeavierIdleMotion() {
        var normalSystem = CreatureActionSystem()
        var radiationSystem = CreatureActionSystem()

        for _ in 0..<2 {
            _ = normalSystem.update(
                dt: 0.1,
                context: context(
                    movement: .chase,
                    actualSpeed: 60,
                    baseSpeed: 100,
                    isZombie: true
                )
            )
            _ = radiationSystem.update(
                dt: 0.1,
                context: context(
                    movement: .chase,
                    actualSpeed: 60,
                    baseSpeed: 100,
                    isZombie: true,
                    isRadiationMonster: true
                )
            )
        }

        let normalTransform = normalSystem.transform(
            heading: 0,
            bodySize: 100,
            rotatesWithHeading: false,
            facingLeft: false
        )
        let radiationTransform = radiationSystem.transform(
            heading: 0,
            bodySize: 100,
            rotatesWithHeading: false,
            facingLeft: false
        )

        XCTAssertGreaterThan(radiationTransform.ty, normalTransform.ty)
    }

    private func context(
        movement: CreatureMovement,
        actualSpeed: CGFloat = 80,
        baseSpeed: CGFloat = 100,
        isBurning: Bool = false,
        isPanicking: Bool = false,
        isZombie: Bool = false,
        isVehicle: Bool = false,
        isRadiationMonster: Bool = false
    ) -> CreatureActionContext {
        CreatureActionContext(
            movement: movement,
            actualSpeed: actualSpeed,
            baseSpeed: baseSpeed,
            isBurning: isBurning,
            isPanicking: isPanicking,
            isZombie: isZombie,
            isVehicle: isVehicle,
            isRadiationMonster: isRadiationMonster
        )
    }
}
