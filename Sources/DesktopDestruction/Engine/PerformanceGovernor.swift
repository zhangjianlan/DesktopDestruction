import CoreGraphics
import Foundation

struct PerformanceProfile: Equatable {
    let simulationInterval: TimeInterval
    let interactionStride: Int
    let giantZombieStride: Int
    let vehicleCollisionStride: Int
    let eliteZombieStride: Int
    let particleScale: CGFloat
    let fireScale: CGFloat
    let creatureFireScale: CGFloat
    let desktopDamageChanceScale: CGFloat
    let maximumBurningSpots: Int
    let lowDetail: Bool
}

enum PerformanceGovernor {
    private(set) static var current = PerformanceProfile(
        simulationInterval: 1.0 / 30.0,
        interactionStride: 1,
        giantZombieStride: 1,
        vehicleCollisionStride: 2,
        eliteZombieStride: 4,
        particleScale: 1,
        fireScale: 1,
        creatureFireScale: 1,
        desktopDamageChanceScale: 1,
        maximumBurningSpots: 72,
        lowDetail: false
    )

    static func profile(
        creatureCount: Int,
        burningFireCount: Int,
        recentTickDuration: TimeInterval = 0
    ) -> PerformanceProfile {
        let loadLevel: Int
        if creatureCount > 180
            || burningFireCount > 40
            || recentTickDuration > 0.050 {
            loadLevel = 3
        } else if creatureCount > 120
            || burningFireCount > 24
            || recentTickDuration > 0.035 {
            loadLevel = 2
        } else if creatureCount > 60
            || burningFireCount > 12
            || recentTickDuration > 0.025 {
            loadLevel = 1
        } else {
            loadLevel = 0
        }

        switch loadLevel {
        case 0:
            return PerformanceProfile(
                simulationInterval: 1.0 / 30.0,
                interactionStride: 1,
                giantZombieStride: 1,
                vehicleCollisionStride: 2,
                eliteZombieStride: 4,
                particleScale: 1,
                fireScale: 1,
                creatureFireScale: 1,
                desktopDamageChanceScale: 1,
                maximumBurningSpots: 72,
                lowDetail: false
            )
        case 1:
            return PerformanceProfile(
                simulationInterval: 1.0 / 24.0,
                interactionStride: 2,
                giantZombieStride: 2,
                vehicleCollisionStride: 2,
                eliteZombieStride: 4,
                particleScale: 0.8,
                fireScale: 0.72,
                creatureFireScale: 0.65,
                desktopDamageChanceScale: 0.8,
                maximumBurningSpots: 48,
                lowDetail: true
            )
        case 2:
            return PerformanceProfile(
                simulationInterval: 1.0 / 20.0,
                interactionStride: 3,
                giantZombieStride: 3,
                vehicleCollisionStride: 3,
                eliteZombieStride: 6,
                particleScale: 0.6,
                fireScale: 0.52,
                creatureFireScale: 0.45,
                desktopDamageChanceScale: 0.6,
                maximumBurningSpots: 32,
                lowDetail: true
            )
        default:
            return PerformanceProfile(
                simulationInterval: 1.0 / 18.0,
                interactionStride: 4,
                giantZombieStride: 4,
                vehicleCollisionStride: 4,
                eliteZombieStride: 8,
                particleScale: 0.45,
                fireScale: 0.3,
                creatureFireScale: 0.2,
                desktopDamageChanceScale: 0.45,
                maximumBurningSpots: 24,
                lowDetail: true
            )
        }
    }

    @discardableResult
    static func update(
        creatureCount: Int,
        burningFireCount: Int,
        recentTickDuration: TimeInterval = 0
    ) -> PerformanceProfile {
        current = profile(
            creatureCount: creatureCount,
            burningFireCount: burningFireCount,
            recentTickDuration: recentTickDuration
        )
        return current
    }

    static func resetForTesting() {
        current = profile(creatureCount: 0, burningFireCount: 0)
    }
}
