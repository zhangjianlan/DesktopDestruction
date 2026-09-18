import XCTest
@testable import DesktopDestruction

final class CreatureSurvivalRulesTests: XCTestCase {
    func testWeaponDamageProfileMatchesToolPower() {
        XCTAssertEqual(Tool.hammer.creatureDamage, 12)
        XCTAssertEqual(Tool.machineGun.creatureDamage, 5)
        XCTAssertEqual(Tool.saw.creatureDamage, 8)
        XCTAssertEqual(Tool.fist.creatureDamage, 24)
        XCTAssertEqual(Tool.bomb.creatureDamage, 1000)

        let tierOne = CreatureActor(at: .zero, kind: .person(.zombie))
        XCTAssertTrue(tierOne.applyDamage(Tool.hammer.creatureDamage, from: .zero))

        let tierTwo = CreatureActor(at: .zero, kind: .person(.zombie))
        tierTwo.promoteZombieTier(to: 2)
        XCTAssertFalse(tierTwo.applyDamage(Tool.machineGun.creatureDamage, from: .zero))
        XCTAssertFalse(tierTwo.applyDamage(Tool.machineGun.creatureDamage, from: .zero))
        XCTAssertFalse(tierTwo.applyDamage(Tool.machineGun.creatureDamage, from: .zero))
        XCTAssertTrue(tierTwo.applyDamage(Tool.machineGun.creatureDamage, from: .zero))

        let tierFive = CreatureActor(at: .zero, kind: .person(.zombie))
        tierFive.promoteZombieTier(to: 5)
        var hammerHits = 0
        repeat {
            hammerHits += 1
        } while !tierFive.applyDamage(Tool.hammer.creatureDamage, from: .zero)
        XCTAssertEqual(hammerHits, 7)
    }

    func testLongSurvivingPersonGetsSpeedTierButNoDeathSave() {
        let person = CreatureActor(at: .zero, kind: .person(.walker))
        let canvas = DestructionCanvas()

        _ = person.update(
            now: Date().addingTimeInterval(41),
            canvas: canvas,
            bounds: CGRect(x: 0, y: 0, width: 800, height: 600),
            threat: nil,
            others: [],
            walls: []
        )

        XCTAssertEqual(person.survivalTier, 2)
        XCTAssertEqual(person.remainingDeathSaves, 0)
        XCTAssertTrue(person.applyDamage(3, from: .zero))
    }

    func testVehicleRequiresRepeatedWeaponDamageBeforeExploding() {
        let car = CreatureActor(at: .zero, kind: .vehicle(.car))

        XCTAssertFalse(car.applyDamage(Tool.hammer.creatureDamage, from: .zero))
        XCTAssertFalse(car.applyDamage(Tool.machineGun.creatureDamage, from: .zero))
        XCTAssertGreaterThan(car.healthFraction, 0.5)

        var shots = 0
        while !car.applyDamage(Tool.machineGun.creatureDamage, from: .zero) {
            shots += 1
        }
        XCTAssertGreaterThan(shots, 1)

        let bombTarget = CreatureActor(at: .zero, kind: .vehicle(.car))
        XCTAssertTrue(
            bombTarget.applyDamage(
                Tool.bomb.creatureDamage,
                from: .zero,
                source: .explosion
            )
        )
    }

    func testLongSurvivingAnimalKeepsSuperShieldSaves() {
        let animal = CreatureActor(at: .zero, kind: .animal(AnimalSpecies.all[0]))
        let canvas = DestructionCanvas()

        _ = animal.update(
            now: Date().addingTimeInterval(31),
            canvas: canvas,
            bounds: CGRect(x: 0, y: 0, width: 800, height: 600),
            threat: nil,
            others: [],
            walls: []
        )

        XCTAssertEqual(animal.survivalTier, 2)
        XCTAssertEqual(animal.remainingDeathSaves, 2)
        XCTAssertTrue(animal.applyDamage(1000, from: .zero))
        XCTAssertFalse(animal.kill(canvas: canvas))
    }

    func testZombieSwarmRulesMapGroupSizeToEliteTier() {
        XCTAssertEqual(ZombieSwarmRules.eliteTier(for: 7), 0)
        XCTAssertEqual(ZombieSwarmRules.eliteTier(for: 8), 2)
        XCTAssertEqual(ZombieSwarmRules.eliteTier(for: 14), 3)
        XCTAssertEqual(ZombieSwarmRules.eliteTier(for: 20), 4)
        XCTAssertEqual(ZombieSwarmRules.eliteTier(for: 28), 5)
        XCTAssertEqual(ZombieSwarmRules.eliteTier(for: 37), 6)
        XCTAssertEqual(ZombieSwarmRules.eliteTier(for: 46), 7)
    }

    func testEliteZombieKeepsTierAndDoesNotDowngrade() {
        let zombie = CreatureActor(at: .zero, kind: .person(.zombie))

        XCTAssertTrue(zombie.isZombie)
        XCTAssertFalse(zombie.applyDamage(9, from: .zero))
        XCTAssertTrue(zombie.applyDamage(1, from: .zero))

        zombie.promoteZombieTier(to: 5)
        zombie.promoteZombieTier(to: 2)

        XCTAssertEqual(zombie.zombieTier, 5)
        XCTAssertLessThanOrEqual(zombie.traits.bodySize, 390)
        XCTAssertGreaterThan(zombie.traits.bodySize, 300)
        XCTAssertFalse(zombie.applyDamage(70, from: .zero))
        XCTAssertTrue(zombie.applyDamage(10, from: .zero))
    }

    func testEliteZombieIgnoresVehicleButTakesExplosionDamage() {
        let zombie = CreatureActor(at: .zero, kind: .person(.zombie))
        zombie.promoteZombieTier(to: 2)

        XCTAssertFalse(zombie.applyDamage(100000, from: .zero, source: .vehicleImpact))
        XCTAssertEqual(zombie.healthFraction, 1)
        XCTAssertTrue(zombie.applyDamage(Tool.bomb.creatureDamage, from: .zero, source: .explosion))
        XCTAssertTrue(zombie.kill(canvas: DestructionCanvas()))
        XCTAssertFalse(zombie.isAlive)
    }

    func testEliteZombieIsNotImmediatelyKilledByFire() {
        let zombie = CreatureActor(at: .zero, kind: .person(.zombie))
        zombie.promoteZombieTier(to: 2)
        let now = Date()

        zombie.ignite(now: now)
        XCTAssertTrue(zombie.isBurning)

        let survived = zombie.update(
            now: now.addingTimeInterval(2),
            canvas: DestructionCanvas(),
            bounds: CGRect(x: 0, y: 0, width: 800, height: 600),
            threat: nil,
            others: [],
            walls: []
        )

        XCTAssertTrue(survived)
        XCTAssertTrue(zombie.isAlive)
        XCTAssertGreaterThan(zombie.healthFraction, 0)
        XCTAssertLessThan(zombie.healthFraction, 1)
    }

    func testAnnihilationBypassesEliteZombieAndAnimalSurvivalSaves() {
        let eliteZombie = CreatureActor(at: .zero, kind: .person(.zombie))
        eliteZombie.promoteZombieTier(to: 12)

        XCTAssertFalse(eliteZombie.applyDamage(100000, from: .zero, source: .vehicleImpact))
        XCTAssertTrue(eliteZombie.annihilate(canvas: DestructionCanvas()))
        XCTAssertFalse(eliteZombie.isAlive)

        let animal = CreatureActor(at: .zero, kind: .animal(AnimalSpecies.all[0]))
        _ = animal.update(
            now: Date().addingTimeInterval(31),
            canvas: DestructionCanvas(),
            bounds: CGRect(x: 0, y: 0, width: 800, height: 600),
            threat: nil,
            others: [],
            walls: []
        )
        XCTAssertEqual(animal.remainingDeathSaves, 2)
        XCTAssertTrue(animal.annihilate(canvas: DestructionCanvas()))
        XCTAssertFalse(animal.isAlive)
    }

    func testNuclearBlastKillsInsideCreaturesAndLeavesOutsideCreaturesAlone() {
        let canvas = DestructionCanvas()
        let inside = CreatureActor(at: .zero, kind: .person(.walker))
        let outside = CreatureActor(at: CGPoint(x: 900, y: 0), kind: .insect(.ant))
        var affectedCreatureIDs = Set<UUID>()

        let result = NuclearBlastRules.resolve(
            creatures: [inside, outside],
            at: .zero,
            radius: 320,
            canvas: canvas,
            affectedCreatureIDs: &affectedCreatureIDs
        )

        XCTAssertEqual(result.killedCount, 1)
        XCTAssertTrue(result.mutatedCreatures.isEmpty)
        XCTAssertFalse(inside.isAlive)
        XCTAssertTrue(outside.isAlive)
    }

    func testNuclearBlastMutatesEliteZombieIntoRadiationMonster() {
        let zombie = CreatureActor(at: .zero, kind: .person(.zombie))
        zombie.promoteZombieTier(to: 7)
        let canvas = DestructionCanvas()
        var affectedCreatureIDs = Set<UUID>()

        let result = NuclearBlastRules.resolve(
            creatures: [zombie],
            at: .zero,
            radius: 320,
            canvas: canvas,
            affectedCreatureIDs: &affectedCreatureIDs
        )

        XCTAssertEqual(result.killedCount, 0)
        XCTAssertEqual(result.mutatedCreatures.count, 1)
        XCTAssertTrue(result.mutatedCreatures.first === zombie)
        XCTAssertTrue(zombie.isRadiationMonster)
        XCTAssertTrue(zombie.isAlive)
        XCTAssertEqual(zombie.radiationPower, 7)
        XCTAssertGreaterThan(zombie.maximumHealth, 100_000)
        XCTAssertGreaterThan(zombie.traits.bodySize, 500)
    }

    func testNuclearBlastMutatesOnlyStrongestHighTierCreature() {
        let strongest = CreatureActor(at: CGPoint(x: 40, y: 0), kind: .person(.zombie))
        strongest.promoteZombieTier(to: 9)
        let weakerZombie = CreatureActor(at: CGPoint(x: -40, y: 0), kind: .person(.zombie))
        weakerZombie.promoteZombieTier(to: 4)
        let highTierAnimal = CreatureActor(at: CGPoint(x: 0, y: 70), kind: .animal(AnimalSpecies.all[0]))
        _ = highTierAnimal.update(
            now: Date().addingTimeInterval(46),
            canvas: DestructionCanvas(),
            bounds: CGRect(x: 0, y: 0, width: 800, height: 600),
            threat: nil,
            others: [],
            walls: []
        )
        let normalCreature = CreatureActor(at: CGPoint(x: 0, y: -70), kind: .person(.walker))
        let canvas = DestructionCanvas()
        var affectedCreatureIDs = Set<UUID>()

        let result = NuclearBlastRules.resolve(
            creatures: [weakerZombie, strongest, highTierAnimal, normalCreature],
            at: .zero,
            radius: 320,
            canvas: canvas,
            affectedCreatureIDs: &affectedCreatureIDs
        )

        XCTAssertEqual(result.killedCount, 3)
        XCTAssertEqual(result.mutatedCreatures.count, 1)
        XCTAssertTrue(result.mutatedCreatures.first === strongest)
        XCTAssertTrue(strongest.isRadiationMonster)
        XCTAssertTrue(strongest.isAlive)
        XCTAssertEqual(strongest.radiationPower, 9)
        XCTAssertFalse(weakerZombie.isRadiationMonster)
        XCTAssertFalse(weakerZombie.isAlive)
        XCTAssertFalse(highTierAnimal.isRadiationMonster)
        XCTAssertFalse(highTierAnimal.isAlive)
        XCTAssertFalse(normalCreature.isAlive)
    }

    func testNuclearBlastMutatesHighTierAnimalIntoRadiationMonster() {
        let animal = CreatureActor(at: .zero, kind: .animal(AnimalSpecies.all[0]))
        _ = animal.update(
            now: Date().addingTimeInterval(46),
            canvas: DestructionCanvas(),
            bounds: CGRect(x: 0, y: 0, width: 800, height: 600),
            threat: nil,
            others: [],
            walls: []
        )
        var affectedCreatureIDs = Set<UUID>()
        XCTAssertTrue(animal.isHighTierMonster)

        let result = NuclearBlastRules.resolve(
            creatures: [animal],
            at: .zero,
            radius: 320,
            canvas: DestructionCanvas(),
            affectedCreatureIDs: &affectedCreatureIDs
        )

        XCTAssertEqual(result.mutatedCreatures.count, 1)
        XCTAssertTrue(result.mutatedCreatures.first === animal)
        XCTAssertTrue(animal.isRadiationMonster)
        XCTAssertGreaterThanOrEqual(animal.radiationPower, 3)
    }

    func testRadiationMonsterIsImmuneToNormalAttacksButNotASecondNuclearBlast() {
        let zombie = CreatureActor(at: .zero, kind: .person(.zombie))
        zombie.promoteZombieTier(to: 4)
        XCTAssertTrue(zombie.mutateIntoRadiationMonster())
        let canvas = DestructionCanvas()

        XCTAssertTrue(zombie.isImmune(to: .weapon))
        XCTAssertTrue(zombie.isImmune(to: .fire))
        XCTAssertTrue(zombie.isImmune(to: .vehicleImpact))
        XCTAssertTrue(zombie.isImmune(to: .explosion))
        XCTAssertTrue(zombie.isImmune(to: .zombie(tier: 100)))
        XCTAssertFalse(zombie.applyDamage(1_000_000, from: .zero, source: .weapon))
        zombie.ignite()
        XCTAssertFalse(zombie.isBurning)
        XCTAssertFalse(zombie.kill(canvas: canvas))
        XCTAssertFalse(zombie.killByFire(canvas: canvas))
        XCTAssertTrue(zombie.isAlive)
        XCTAssertEqual(zombie.healthFraction, 1)

        var affectedCreatureIDs = Set<UUID>()
        let result = NuclearBlastRules.resolve(
            creatures: [zombie],
            at: .zero,
            radius: 320,
            canvas: canvas,
            affectedCreatureIDs: &affectedCreatureIDs
        )
        XCTAssertEqual(result.killedCount, 1)
        XCTAssertFalse(zombie.isAlive)
    }

    func testSameNuclearBlastAftershockDoesNotKillFreshlyMutatedRadiationMonster() {
        let zombie = CreatureActor(at: .zero, kind: .person(.zombie))
        zombie.promoteZombieTier(to: 5)
        let canvas = DestructionCanvas()
        var affectedCreatureIDs = Set<UUID>()

        let firstResult = NuclearBlastRules.resolve(
            creatures: [zombie],
            at: .zero,
            radius: 320,
            canvas: canvas,
            affectedCreatureIDs: &affectedCreatureIDs
        )
        let aftershockResult = NuclearBlastRules.resolve(
            creatures: [zombie],
            at: .zero,
            radius: 320,
            canvas: canvas,
            affectedCreatureIDs: &affectedCreatureIDs
        )

        XCTAssertEqual(firstResult.mutatedCreatures.count, 1)
        XCTAssertTrue(firstResult.mutatedCreatures.first === zombie)
        XCTAssertEqual(aftershockResult.killedCount, 0)
        XCTAssertTrue(aftershockResult.mutatedCreatures.isEmpty)
        XCTAssertTrue(zombie.isAlive)
    }

    func testZombieTierHasNoUpperLimitAndHealthGrows() {
        let tierFive = CreatureActor(at: .zero, kind: .person(.zombie))
        tierFive.promoteZombieTier(to: 5)
        let tierTwelve = CreatureActor(at: .zero, kind: .person(.zombie))
        tierTwelve.promoteZombieTier(to: 12)

        XCTAssertEqual(tierTwelve.zombieTier, 12)
        XCTAssertGreaterThan(tierTwelve.maximumHealth, tierFive.maximumHealth * 10)
    }

    func testHighTierAnimalResistsLowerZombieAndInfectsAtItsTier() {
        let animal = CreatureActor(at: .zero, kind: .animal(AnimalSpecies.all[0]))
        let now = Date()
        _ = animal.update(
            now: now.addingTimeInterval(46),
            canvas: DestructionCanvas(),
            bounds: CGRect(x: 0, y: 0, width: 800, height: 600),
            threat: nil,
            others: [],
            walls: []
        )

        XCTAssertTrue(animal.isHighTierAnimal)
        XCTAssertFalse(animal.applyDamage(1000, from: .zero, source: .zombie(tier: 2)))
        let infectionTier = animal.survivalTier
        animal.infect(fromZombieTier: 2)
        XCTAssertEqual(animal.zombieTier, infectionTier)
    }

    func testZombieKeepsMovingWhenThereIsNoPrey() {
        let zombie = CreatureActor(
            at: CGPoint(x: 400, y: 300),
            kind: .person(.zombie)
        )
        let canvas = DestructionCanvas()
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        let now = Date()

        _ = zombie.update(
            now: now.addingTimeInterval(0.1),
            canvas: canvas,
            bounds: bounds,
            threat: nil,
            others: [],
            walls: []
        )
        let previousPosition = zombie.currentPosition
        _ = zombie.update(
            now: now.addingTimeInterval(0.45),
            canvas: canvas,
            bounds: bounds,
            threat: nil,
            others: [],
            walls: []
        )

        let dx = zombie.currentPosition.x - previousPosition.x
        let dy = zombie.currentPosition.y - previousPosition.y
        XCTAssertGreaterThan(hypot(dx, dy), 3.5)
    }

    func testEliteZombieMovementScalesWithTier() {
        let zombie = CreatureActor(
            at: CGPoint(x: 400, y: 300),
            kind: .person(.zombie)
        )
        zombie.promoteZombieTier(to: 5)
        let canvas = DestructionCanvas()
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        let now = Date()

        _ = zombie.update(
            now: now.addingTimeInterval(0.1),
            canvas: canvas,
            bounds: bounds,
            threat: nil,
            others: [],
            walls: []
        )
        let previousPosition = zombie.currentPosition
        _ = zombie.update(
            now: now.addingTimeInterval(0.35),
            canvas: canvas,
            bounds: bounds,
            threat: nil,
            others: [],
            walls: []
        )

        let dx = zombie.currentPosition.x - previousPosition.x
        let dy = zombie.currentPosition.y - previousPosition.y
        XCTAssertGreaterThan(hypot(dx, dy), 7)
    }

    func testZombieChasesPreyInsteadOfOtherZombies() {
        let zombie = CreatureActor(
            at: CGPoint(x: 400, y: 300),
            kind: .person(.zombie)
        )
        let otherZombie = CreatureActor(
            at: CGPoint(x: 500, y: 300),
            kind: .person(.zombie)
        )
        let prey = CreatureActor(
            at: CGPoint(x: 300, y: 300),
            kind: .person(.walker)
        )

        _ = zombie.update(
            now: Date().addingTimeInterval(0.1),
            canvas: DestructionCanvas(),
            bounds: CGRect(x: 0, y: 0, width: 800, height: 600),
            threat: nil,
            others: [otherZombie, prey],
            walls: []
        )

        XCTAssertLessThan(zombie.currentPosition.x, 400)
    }
}
