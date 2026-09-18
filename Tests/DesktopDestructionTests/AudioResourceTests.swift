import XCTest
@testable import DesktopDestruction

final class AudioResourceTests: XCTestCase {
    func testEnhancedFeedbackSoundsAreBundled() {
        let names = [
            "hammer_hit",
            "glass_shatter",
            "gun_01",
            "creature_hit",
            "metal_hit",
            "explosion",
            "vehicle_explosion",
            "water_spray",
            "flame_loop"
        ]

        for name in names {
            XCTAssertGreaterThan(
                AudioManager.shared.duration(named: name) ?? 0,
                0.1,
                "Missing or invalid sound: \(name)"
            )
        }
    }
}
