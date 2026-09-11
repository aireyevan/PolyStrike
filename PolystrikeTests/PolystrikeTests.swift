import Testing
import SpriteKit
@testable import Polystrike

struct PolystrikeTests {
    @Test @MainActor func arrowHiveHasAReadableAnimatedCluster() {
        let enemy = Enemy()
        enemy.configureVisual(archetype: 6)
        let orbit = enemy.childNode(withName: "enemyDetailHiveOrbit")
        #expect(orbit != nil)
        #expect(orbit?.children.filter { $0.name == "enemyDetailHiveArrow" }.count == 6)
        #expect(orbit?.hasActions == true)
    }
    @Test func endlessDifficultyKeepsAdvancing() {
        let fifth = GameTier.tier(for: 35000)
        let sixth = GameTier.tier(for: 50000)
        let late = GameTier.tier(for: 500000)
        #expect(sixth.number > fifth.number)
        #expect(late.number > sixth.number)
        #expect(late.enemyHealth > sixth.enemyHealth)
        #expect(late.spawnInterval > 0)
        #expect(late.enemySpeed <= 260)
    }
    @Test @MainActor func floatingStickResetsWithoutDrift() {
        let joystick = VirtualJoystick()
        joystick.begin(at: CGPoint(x: -250, y: -100))
        joystick.update(at: CGPoint(x: -150, y: -100))
        #expect(abs(joystick.direction.dx - 1) < 0.001)
        #expect(abs(joystick.direction.dy) < 0.001)
        joystick.end()
        #expect(joystick.direction == .zero)
        joystick.begin(at: CGPoint(x: 100, y: 80))
        joystick.update(at: CGPoint(x: 101, y: 80))
        #expect(joystick.direction == .zero)
    }
    @Test @MainActor func landscapeMenusFitSmallPhone() {
        let size = CGSize(width: 667, height: 375)
        let view = SKView(frame: CGRect(origin: .zero, size: size))
        let store = StoreScene(size: size)
        view.presentScene(store)
        for i in 0..<4 {
            let card = store.childNode(withName: "upgrade\(i)")
            #expect(card != nil)
            if let card { #expect(CGRect(origin: .zero, size: size).contains(card.frame)) }
        }
        let menu = MainMenuScene(size: size)
        view.presentScene(menu)
        #expect(menu.childNode(withName: "play") != nil)
        #expect(menu.childNode(withName: "store") != nil)
    }
    @Test @MainActor func arenaHasPersistentCoverAndCenteredHUD() {
        let size = CGSize(width: 852, height: 393)
        let view = SKView(frame: CGRect(origin: .zero, size: size))
        let scene = GameScene(size: size)
        view.presentScene(scene)
        #expect(scene.childNode(withName: "//player") != nil)
        var barriers = 0
        scene.enumerateChildNodes(withName: "//barrier") { _, _ in barriers += 1 }
        #expect(barriers >= 6)
        #expect(scene.camera?.children.filter { $0 is VirtualJoystick }.allSatisfy { $0.alpha == 0 } == true)
        let panels = scene.camera?.children.compactMap { $0 as? SKShapeNode } ?? []
        #expect(panels.count >= 3)
        for panel in panels { #expect(abs(panel.position.y) < size.height / 2) }
    }
}

struct TierAndFluxTests {
    @Test func shipCollectionPurchasesAndSelectionPersist() {
        let suite = "Polystrike.ships.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(2_500_000, forKey: "playerPoints")
        let progress = PlayerProgress(defaults: defaults)
        #expect(progress.selectedShip == .striker)
        #expect(progress.owns(.striker))
        #expect(!progress.selectShip(.sovereign))
        #expect(progress.buyShip(.sovereign))
        #expect(progress.flux == 500_000)
        #expect(progress.selectedShip == .sovereign)
        let reloaded = PlayerProgress(defaults: defaults)
        #expect(reloaded.owns(.sovereign))
        #expect(reloaded.selectedShip == .sovereign)
        #expect(!reloaded.buyShip(.sovereign))
    }
    @Test func wavesAreFiniteAndBossesArriveAtMilestones() {
        #expect(TierWavePlan.forTier(1) == TierWavePlan(regularEnemies: 12, bossCount: 0))
        #expect(TierWavePlan.forTier(3).bossCount == 1)
        #expect(TierWavePlan.forTier(4).bossCount == 0)
        #expect(TierWavePlan.forTier(10) == TierWavePlan(regularEnemies: 0, bossCount: 1))
        #expect(TierWavePlan.isFinalBossTier(20))
        #expect(!TierWavePlan.isFinalBossTier(15))
        #expect(TierWavePlan.forTier(30).regularEnemies <= 72)
        #expect(GameTier.tier(number: 12).number == 12)
    }
    @Test func arenaChangesAndLeavesRoomBetweenObstacles() {
        #expect(ArenaEvolution.obstacles(tier: 1, center: .zero).isEmpty)
        let early = ArenaEvolution.obstacles(tier: 2, center: .zero)
        let later = ArenaEvolution.obstacles(tier: 3, center: .zero)
        #expect(early != later)
        #expect(early.count == 4)
        for tier in 2...30 {
            let rects = ArenaEvolution.obstacles(tier: tier, center: .zero)
            #expect(rects.count <= 8)
            for (index, rect) in rects.enumerated() {
                #expect(!rect.insetBy(dx: -100, dy: -100).contains(CGPoint.zero))
                for other in rects.dropFirst(index + 1) {
                    #expect(!rect.insetBy(dx: -25, dy: -25).intersects(other))
                }
            }
        }
    }
    @Test func fluxPersistsAndPaysForUpgradesSeparatelyFromScore() {
        let suite = "Polystrike.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(15000, forKey: "polystrikeBestScore")
        // Existing currency survives the new Flux name.
        defaults.set(400, forKey: "playerPoints")
        let progress = PlayerProgress(defaults: defaults)
        #expect(progress.flux == 400)
        progress.addPoints(200)
        #expect(PlayerProgress(defaults: defaults).flux == 600)
        #expect(progress.buyFireRate())
        let reloaded = PlayerProgress(defaults: defaults)
        #expect(reloaded.flux == 100)
        #expect(reloaded.fireRateLevel == 1)
        #expect(defaults.integer(forKey: "polystrikeBestScore") == 15000)
        reloaded.addPoints(-50)
        #expect(reloaded.flux == 100)
    }
}

struct PickupCollectionTests {
    @Test @MainActor func pickupBanksFluxExactlyOnceWithoutChangingScore() {
        let suite = "Polystrike.pickup.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let game = GameScene(size: CGSize(width: 852, height: 393))
        game.progression = PlayerProgress(defaults: defaults)
        let pickup = FluxPickup(value: 75)
        game.addChild(pickup)
        game.collectPickup(pickup)
        game.collectPickup(pickup)
        #expect(game.score == 0)
        #expect(game.runCoins == 75)
        #expect(game.progression.flux == 75)
        #expect(PlayerProgress(defaults: defaults).flux == 75)
        #expect(pickup.parent == nil)
    }
}

struct JoystickSettingsTests {
    @Test @MainActor func visibilityDoesNotDisableInput() {
        for mode in JoystickVisibility.allCases {
            let stick = VirtualJoystick()
            stick.visibility = mode
            stick.refreshVisibility()
            #expect(stick.alpha == (mode == .always ? 1 : 0))
            stick.begin(at: .zero)
            stick.update(at: CGPoint(x: 60, y: 0))
            #expect(stick.direction.dx == 1)
            #expect(stick.alpha == (mode == .hidden ? 0 : 1))
            #expect((stick.action(forKey: "visibility") != nil) == (mode == .fade))
            stick.end()
            #expect(stick.direction == .zero)
            #expect(stick.alpha == (mode == .always ? 1 : 0))
        }
    }
    @Test func preferencePersists() {
        let suite = "JoystickSettings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = GameSettings(defaults: defaults)
        #expect(settings.joystickVisibility == .fade)
        settings.joystickVisibility = .hidden
        #expect(GameSettings(defaults: defaults).joystickVisibility == .hidden)
        #expect(settings.hapticsEnabled)
        settings.hapticsEnabled = false
        #expect(!GameSettings(defaults: defaults).hapticsEnabled)
    }
}


struct LivingArenaTests {
    @Test func allLayoutsHaveConnectedEscapeRoutes() {
        for phase in 0..<5 {
            let arena = LivingArena(phase: phase, center: .zero)
            var visited = Set<Int>()
            var queue = [5 * LivingArena.columns + 7]
            visited.insert(queue[0])
            var cursor = 0
            while cursor < queue.count {
                let index = queue[cursor]; cursor += 1
                let x = index % LivingArena.columns, y = index / LivingArena.columns
                for (nx, ny) in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)] where arena.isFloor(x: nx, y: ny) {
                    let next = ny * LivingArena.columns + nx
                    if visited.insert(next).inserted { queue.append(next) }
                }
            }
            #expect(visited.count == arena.floorCenters.count)
            #expect(arena.containsShip(at: .zero))
            for wall in arena.walls {
                let point = CGPoint(x: wall.midX, y: wall.midY)
                #expect(!arena.containsShip(at: point))
                #expect(arena.containsShip(at: arena.nearestFloor(to: point)))
            }
        }
    }
    @Test func clockWarnsBeforeLockingAndAccelerates() {
        var clock = ArenaClock()
        #expect(clock.advance(15.9, tier: 1) == nil)
        #expect(clock.advance(0.2, tier: 1) == .warning)
        #expect(clock.warning)
        #expect(clock.advance(2.9, tier: 1) == nil)
        #expect(clock.advance(0.2, tier: 1) == .commit)
        let early = clock.remaining
        #expect(clock.advance(early, tier: 20) == .warning)
        #expect(clock.advance(3, tier: 20) == .commit)
        #expect(clock.remaining < early)
        #expect(clock.remaining >= 7)
    }
    @Test func compressionMateriallyReducesFloorSpace() {
        let open = LivingArena(phase: 0, center: .zero)
        let cross = LivingArena(phase: 1, center: .zero)
        #expect(cross.floorCenters.count < open.floorCenters.count / 2)
        #expect(LivingArena(phase: 2, center: .zero).walls != LivingArena(phase: 3, center: .zero).walls)
    }
}

struct ArenaHazardTests {
    @Test @MainActor func warningDoesNotHurtButLockDamagesAndRescuesShips() {
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 852, height: 393))
        let scene = GameScene(size: view.bounds.size)
        view.presentScene(scene)
        let player = scene.childNode(withName: "//player") as! Player
        let world = scene.childNode(withName: "worldNode")!
        let center = player.position
        player.position = CGPoint(x: center.x + 500, y: center.y + 300)
        let enemy = Enemy(); enemy.position = player.position; world.addChild(enemy)
        let flux = FluxPickup(value: 25); flux.position = player.position; world.addChild(flux)
        let health = player.health
        scene.beginArenaShift()
        #expect(player.health == health)
        scene.commitArenaShift()
        #expect(player.health < health)
        #expect(LivingArena(phase: 1, center: center).containsShip(at: player.position))
        #expect(LivingArena(phase: 1, center: center).containsShip(at: flux.position))
        #expect(flux.parent != nil)
        #expect(hypot(enemy.position.x - player.position.x, enemy.position.y - player.position.y) > 140)
        #expect(scene.score == 0)
    }
}


struct ArmoryTests {
    @Test func oldMaxLevelsCanAdvanceAndNewSystemsPersist() {
        let suite = "Armory.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(20, forKey: "fireRateLevel")
        defaults.set(10000000, forKey: "playerPoints")
        let p = PlayerProgress(defaults: defaults)
        let oldRate = p.playerFireRate()
        #expect(p.buyFireRate())
        #expect(p.fireRateLevel == 21)
        #expect(p.playerFireRate() < oldRate)
        for upgrade in ShipUpgrade.allCases where upgrade != .fire {
            #expect(p.buy(upgrade))
            #expect(PlayerProgress(defaults: defaults).level(upgrade) == p.level(upgrade))
        }
        #expect(p.damageMultiplier < 1)
        #expect(p.magnetRange > 110)
        #expect(p.repairPerSecond > 0)
    }
    @Test func capsRejectPurchasesWithoutSpending() {
        let suite = "ArmoryCaps.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(60, forKey: "fireRateLevel")
        defaults.set(20, forKey: "shipUpgrade.armor")
        defaults.set(900000, forKey: "playerPoints")
        let p = PlayerProgress(defaults: defaults)
        #expect(!p.buy(.fire))
        #expect(!p.buy(.armor))
        #expect(p.flux == 900000)
        #expect(p.playerFireRate() >= 0.055)
        #expect(p.damageMultiplier >= 0.59)
    }
}

struct AbilityTests {
    @Test @MainActor func bombKillsAndHonorsCooldown() {
        let suite = "Bomb.\(UUID().uuidString)"; let d = UserDefaults(suiteName: suite)!
        defer { d.removePersistentDomain(forName: suite) }
        d.set(1, forKey: "shipUpgrade.bomb")
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 852, height: 393))
        let game = GameScene(size: view.bounds.size); game.progression = PlayerProgress(defaults: d)
        view.presentScene(game)
        let world = game.childNode(withName: "worldNode")!, player = game.childNode(withName: "//player")!
        let enemy = Enemy(); enemy.position = player.position; world.addChild(enemy)
        game.activateBomb()
        #expect(enemy.parent == nil)
        #expect(game.score == 100)
        let survivor = Enemy(); survivor.position = player.position; world.addChild(survivor)
        game.activateBomb()
        #expect(survivor.health == 30)
    }
    @Test @MainActor func dashMovesAndHonorsCooldown() {
        let suite = "Dash.\(UUID().uuidString)"; let d = UserDefaults(suiteName: suite)!
        defer { d.removePersistentDomain(forName: suite) }
        d.set(1, forKey: "shipUpgrade.dash")
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 852, height: 393))
        let game = GameScene(size: view.bounds.size); game.progression = PlayerProgress(defaults: d)
        view.presentScene(game)
        let player = game.childNode(withName: "//player")!
        let start = player.position
        game.activateDash()
        #expect(player.position.x > start.x)
        let end = player.position
        game.activateDash()
        #expect(player.position == end)
    }
}

struct OpeningPacingTests {
    @Test func upgradedShipsGetFasterOpeningAndNormalLateRate() {
        let suite = "Opening.\(UUID().uuidString)"; let d = UserDefaults(suiteName: suite)!
        defer { d.removePersistentDomain(forName: suite) }
        let beginner = OpeningPacing(progress: PlayerProgress(defaults: d))
        d.set(40, forKey: "damageLevel"); d.set(40, forKey: "fireRateLevel")
        let veteran = OpeningPacing(progress: PlayerProgress(defaults: d))
        #expect(beginner.multiplier(at: 30) < 2.1)
        #expect(veteran.multiplier(at: 30) < beginner.multiplier(at: 30))
        #expect(beginner.enemyLimit(at: 30) == 8)
        #expect(veteran.enemyLimit(at: 30) == 26)
        for curve in [beginner, veteran] {
            #expect(curve.multiplier(at: 180) == 1.3)
            #expect(curve.multiplier(at: 600) == 1.3)
            #expect(curve.enemyLimit(at: 180) == 130)
            #expect(abs(curve.multiplier(at: 59.99) - curve.multiplier(at: 60.01)) < 0.001)
            #expect(abs(curve.multiplier(at: 179.99) - curve.multiplier(at: 180.01)) < 0.001)
        }
    }
}

struct EnemyCrowdSteeringTests {
    @Test @MainActor func splittingOctagonHasDistinctVisualCore() {
        let enemy = Enemy()
        enemy.configureVisual(archetype: 5)
        #expect(enemy.childNode(withName: "enemyDetailOctagon") != nil)
        #expect(enemy.userData?["archetype"] as? Int == 5)
    }
    @Test func nearbyEnemiesSteerApart() {
        let positions = [CGPoint(x: 0, y: 0), CGPoint(x: 20, y: 0), CGPoint(x: 200, y: 0)]
        let left = EnemyCrowdSteering.separationVector(for: 0, positions: positions)
        let right = EnemyCrowdSteering.separationVector(for: 1, positions: positions)
        #expect(left.dx < 0)
        #expect(right.dx > 0)
        #expect(EnemyCrowdSteering.separationVector(for: 2, positions: positions) == .zero)
        let nearEdge = EnemyCrowdSteering.separationVector(
            for: 0,
            positions: [CGPoint.zero, CGPoint(x: 47.9, y: 0)]
        )
        #expect(abs(nearEdge.dx) < 0.01)
    }

    @Test func stackedEnemiesReceiveEscapeDirections() {
        let positions = [CGPoint.zero, CGPoint.zero]
        #expect(EnemyCrowdSteering.separationVector(for: 0, positions: positions) != .zero)
        #expect(EnemyCrowdSteering.separationVector(for: 1, positions: positions) != .zero)
    }
}

struct MapVarietyTests {
    @Test func everyShapeAndVariantIsConnectedAndRoomy() {
        for shape in ArenaShape.allCases {
            for phase in LivingArena.phases(for: shape) {
                for variant in 0..<4 {
                    let arena = LivingArena(phase: phase, center: .zero, shape: shape, variant: variant)
                    var seen: Set<Int> = [82], queue = [82], cursor = 0
                    while cursor < queue.count {
                        let index = queue[cursor]; cursor += 1
                        let x = index % 15, y = index / 15
                        for (nx, ny) in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)] where arena.isFloor(x: nx, y: ny) {
                            let next = ny * 15 + nx
                            if seen.insert(next).inserted { queue.append(next) }
                        }
                    }
                    #expect(seen.count == arena.floorCenters.count, "Disconnected \(shape) / \(phase) / \(variant)")
                    #expect(arena.containsShip(at: .zero))
                    if shape != .rectangle { #expect(arena.floorCenters.count >= 60) }
                }
            }
        }
    }
    @Test func outlinesUnlockAtTierMilestones() {
        #expect(ArenaShape.forTier(4) == .rectangle)
        #expect(ArenaShape.forTier(5) == .octagon)
        #expect(ArenaShape.forTier(8) == .square)
        #expect(ArenaShape.forTier(11) == .triangle)
        #expect(ArenaShape.forTier(14) == .octagon)
        #expect(LivingArena.phases(for: .rectangle).count == 12)
        let octagon = LivingArena(phase: 0, center: .zero, shape: .octagon)
        #expect(!octagon.insideOutline(x: 0, y: 0))
        #expect(octagon.insideOutline(x: 7, y: 0))
    }
}
