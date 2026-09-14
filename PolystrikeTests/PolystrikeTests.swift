import Testing
import UIKit
import SpriteKit
@testable import Polystrike

struct PolystrikeTests {
    @Test @MainActor func arrowHiveHasAReadableAnimatedCluster() {
        let enemy = Enemy()
        enemy.configureVisual(archetype: 6)
        let orbit = enemy.childNode(withName: "enemyDetailHiveOrbit")
        #expect(orbit != nil)
        #expect(orbit?.children.filter { $0.name == "enemyDetailHiveArrow" }.count == 6)
        #expect(orbit?.hasActions() == true)
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
        #expect(menu.childNode(withName: "playPreview") != nil)
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
        #expect(game.runCoins == 52)
        #expect(game.progression.flux == 52)
        #expect(PlayerProgress(defaults: defaults).flux == 52)
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
        for phase in 0..<LivingArena.blueprintCount {
            let arena = LivingArena(phase: phase, center: .zero)
            var visited = Set<Int>()
            var queue = [(LivingArena.rows/2) * LivingArena.columns + LivingArena.columns/2]
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
        #expect(cross.floorCenters.count < open.floorCenters.count)
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
        player.position = CGPoint(x: center.x + 700, y: center.y + 100)
        let enemy = Enemy(); enemy.position = player.position; world.addChild(enemy)
        let flux = FluxPickup(value: 25); flux.position = player.position; world.addChild(flux)
        let health = player.health
        let next = LivingArena(phase:6,center:center)
        scene.beginArenaShift(to:next)
        #expect(player.health == health)
        scene.commitArenaShift()
        #expect(player.health < health)
        #expect(next.containsShip(at: player.position))
        #expect(next.containsShip(at: flux.position))
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
    @Test func everyArenaHasConnectedPlayerAndBossRoutes() {
        for phase in 0..<LivingArena.blueprintCount {
            for variant in 0..<4 {
                let arena = LivingArena(phase:phase,center:.zero,variant:variant)
                #expect(arena.floorCenters.count >= 100)
                for clearance: CGFloat in [24,62] {
                    let columns = LivingArena.columns*2, rows = LivingArena.rows*2
                    var cells = Set<Int>()
                    for y in 0..<rows { for x in 0..<columns {
                        let point = CGPoint(x:arena.bounds.minX+(CGFloat(x)+0.5)*48,
                                            y:arena.bounds.minY+(CGFloat(y)+0.5)*48)
                        if arena.bounds.insetBy(dx:clearance,dy:clearance).contains(point),
                           !arena.walls.contains(where: { $0.insetBy(dx:-clearance,dy:-clearance).contains(point) }) {
                            cells.insert(y*columns+x)
                        }
                    }}
                    let start = rows/2*columns+columns/2
                    #expect(cells.contains(start))
                    var seen: Set<Int> = [start], queue = [start], cursor = 0
                    while cursor < queue.count {
                        let i=queue[cursor]; cursor += 1
                        for n in [i-1,i+1,i-columns,i+columns] {
                            let dx=abs(n%columns-i%columns),dy=abs(n/columns-i/columns)
                            if cells.contains(n),dx+dy==1,seen.insert(n).inserted {queue.append(n)}
                        }
                    }
                    #expect(seen.count == cells.count,"Disconnected \(arena.name), variant \(variant), clearance \(clearance)")
                }
            }
        }
    }
    @Test func blueprintsHaveUniqueFootprintsAndSeparateBossDecks() {
        var signatures=Set<String>()
        for phase in 0..<LivingArena.blueprintCount {
            let arena=LivingArena(phase:phase,center:.zero)
            let signature=(0..<LivingArena.rows).flatMap { y in
                (0..<LivingArena.columns).map { x in arena.isFloor(x:x,y:y) ? "1" : "0" }
            }.joined()
            #expect(signatures.insert(signature).inserted)
        }
        #expect(LivingArena.combatPhases.count == 20)
        #expect(LivingArena.bossPhases.count == 4)
        #expect(Set(LivingArena.combatPhases).isDisjoint(with:LivingArena.bossPhases))
        #expect(LivingArena(phase:0,center:.zero).bounds.width > 1440)
    }
}

struct CombatUpgradeTests {
    @Test func indexedWallsMatchFullScanAndRebuild() {
        var walls: [CGRect] = []
        for i in 0..<100 { let x=(i*173)%1800-900; let y=(i*97)%1200-600; walls.append(CGRect(x:x,y:y,width:96,height:96)) }
        let grid=WallSpatialIndex(walls:walls)
        for i in 0..<1000 {
            let point=CGPoint(x:(i*37)%2200-1100,y:(i*61)%1600-800)
            #expect(grid.contains(point,clearance:22)==walls.contains { $0.insetBy(dx:-22,dy:-22).contains(point) })
        }
        let barrier=WallSpatialIndex(walls:[CGRect(x:0,y:-50,width:1,height:100)])
        #expect(!barrier.clearPath(from:CGPoint(x:-100,y:0),to:CGPoint(x:100,y:0),clearance:0))
        #expect(barrier.clearPath(from:CGPoint(x:-100,y:80),to:CGPoint(x:100,y:80),clearance:22))
        #expect(!barrier.clearPath(from:CGPoint(x:0,y:0),to:CGPoint(x:0,y:0)))
        #expect(WallSpatialIndex().clearPath(from:CGPoint(x:-100,y:0),to:CGPoint(x:100,y:0)))
    }
    @Test @MainActor func combatEffectsStayBoundedAndOutsidePhysics() {
        let hull=CGPath(ellipseIn:CGRect(x:-15,y:-15,width:30,height:30),transform:nil)
        let dash=CombatEffects.dash(from:.zero,to:CGPoint(x:160,y:0),hull:hull,angle:0,color:.cyan)
        let wave=CombatEffects.shockwave(radius:180,color:.cyan)
        #expect(dash.children.count==7)
        #expect(wave.children.count==4)
        for effect in [dash,wave] {
            #expect(effect.hasActions())
            #expect(effect.physicsBody == nil)
            #expect(effect.children.allSatisfy { $0.physicsBody == nil && !($0 is SKEmitterNode) })
        }
    }
}

struct StoryReworkTests {
    private func defaults()->UserDefaults {
        let d=UserDefaults(suiteName:"StoryTests.\(UUID().uuidString)")!
        d.set(StoryCampaign.version,forKey:"storyCampaignVersion")
        return d
    }
    @Test func campaignHasCompleteDistinctOperationRoutes() {
        #expect(StoryCampaign.missions.count==40)
        #expect(StoryCampaign.missions.reduce(0){$0+$1.stages.count}==120)
        #expect(Set(StoryCampaign.missions.map(\.id)).count==40)
        var layouts=Set<String>()
        for sector in 1...5 {
            let missions=StoryCampaign.missions.filter{$0.sector==sector}
            #expect(missions.count==8)
            #expect(missions.last?.stages.last?.type == .boss)
            for mission in missions {
                #expect(mission.stages.count==3)
                #expect(mission.reward>0)
                for stage in mission.stages {
                    #expect(stage.arenaPhase>=0 && stage.arenaPhase<LivingArena.blueprintCount)
                    #expect(stage.arenaVariant>=0 && stage.arenaVariant<4)
                    if stage.type == .capture || stage.type == .assault {#expect(stage.objectiveCount>=2)}
                    layouts.insert("\(stage.arenaPhase)/\(stage.arenaVariant)")
                }
            }
        }
        #expect(layouts.count>=45)
    }
    @Test func all120StagesCanCompleteAndAdvanceExactlyOnce() {
        for index in StoryCampaign.missions.indices {
            let manager=StoryModeManager(missionIndex:index,defaults:defaults())
            for stageIndex in 0..<3 {
                #expect(manager.stageIndex==stageIndex)
                manager.begin()
                let stage=manager.stage
                switch stage.type {
                case .elimination:
                    for _ in 0..<stage.enemyCount {manager.registeredSpawn();manager.spawnArrived();manager.enemyDefeated(elite:false,objectiveTarget:false)}
                case .capture:
                    for i in 0..<stage.objectiveCount {manager.holdCaptureZone(i,delta:100)}
                case .assault:
                    for _ in 0..<stage.objectiveCount {manager.enemyDefeated(elite:false,objectiveTarget:true)}
                case .eliteHunt,.boss:manager.enemyDefeated(elite:true,objectiveTarget:false)
                case .survival,.defense,.escape:
                    for _ in 0..<Int(stage.duration*20+10) {manager.tick(0.05,enemiesAlive:0)}
                    if stage.type == .escape {manager.reachedExtraction()}
                }
                manager.tick(0.05,enemiesAlive:0)
                #expect(manager.phase == (stageIndex==2 ? .complete:.checkpoint))
                if stageIndex<2 {#expect(manager.advanceStage());#expect(!manager.advanceStage())}
            }
        }
    }
    @Test func captureContestsCheckpointsAndPendingSpawnsAreSafe() {
        let d=defaults(),manager=StoryModeManager(missionIndex:0,defaults:defaults())
        manager.begin()
        for _ in 0..<manager.stage.enemyCount {manager.registeredSpawn();manager.enemyDefeated(elite:false,objectiveTarget:false)}
        manager.tick(0.05,enemiesAlive:0)
        #expect(manager.phase == .active)
        for _ in 0..<manager.stage.enemyCount {manager.spawnArrived()}
        manager.tick(0.05,enemiesAlive:0);#expect(manager.phase == .checkpoint)
        let checkpoint=StoryModeManager(missionIndex:0,defaults:d)
        checkpoint.begin();checkpoint.complete();#expect(checkpoint.advanceStage());checkpoint.begin()
        checkpoint.holdCaptureZone(0,delta:5,contested:true);#expect(checkpoint.captureProgress[0]==0)
        checkpoint.holdCaptureZone(0,delta:2);#expect(checkpoint.captureProgress[0]>0)
        checkpoint.fail();checkpoint.retryCurrentStage();#expect(checkpoint.stageIndex==1);#expect(checkpoint.captureProgress[0]==0)
        let resumed=StoryModeManager(defaults:d);#expect(resumed.stageIndex==1)
        resumed.reachedExtraction();#expect(resumed.phase == .briefing)
    }
    @Test func campaignMigrationAndFirstClearRewardAreIdempotent() {
        let d=defaults();d.set(0,forKey:"storyCampaignVersion");d.set(12,forKey:"polystrikeStoryMission")
        StoryCampaign.migrateProgress(defaults:d);#expect(d.integer(forKey:"polystrikeStoryMission")==23)
        StoryCampaign.migrateProgress(defaults:d);#expect(d.integer(forKey:"polystrikeStoryMission")==23)
        let fresh=defaults(),m=StoryModeManager(missionIndex:0,defaults:defaults())
        #expect(m.recordVictory(healthRatio:1).reward==0)
        let run=StoryModeManager(missionIndex:0,defaults:fresh)
        for i in 0..<3 {run.begin();run.complete();if i<2 {_ = run.advanceStage()}}
        #expect(run.recordVictory(healthRatio:1).reward==run.mission.reward)
        #expect(run.recordVictory(healthRatio:1).reward==0)
        #expect(fresh.integer(forKey:"polystrikeStoryMission")==1)
        #expect(run.advance());#expect(run.stageIndex==0)
    }
    @Test @MainActor func objectiveModelsHaveArmorAndBoundedAnimationNodes() {
        for kind:StoryObjectiveNode.Kind in [.reactor,.relay,.installation,.gate] {
            let node=StoryObjectiveNode(kind:kind)
            #expect(node.children.count<20)
            #expect(node.childNode(withName:"//machineArmor") != nil)
            #expect(node.children.contains{$0.hasActions()})
            #expect(node.physicsBody == nil)
            node.render(progress:0.5,state:"TEST",contested:true)
            node.render(progress:1,state:"SECURED")
        }
    }
    @Test @MainActor func campaignObjectivesInstallForEveryStageType() {
        let view=SKView(frame:CGRect(x:0,y:0,width:852,height:393))
        var tested=Set<MissionType>()
        for (index,mission) in StoryCampaign.missions.enumerated() {
            for stageIndex in mission.stages.indices where !tested.contains(mission.stages[stageIndex].type) {
                let manager=StoryModeManager(missionIndex:index,defaults:defaults())
                for _ in 0..<stageIndex {manager.begin();manager.complete();_ = manager.advanceStage()}
                let scene=GameScene(size:view.bounds.size,storyModeManager:manager);view.presentScene(scene)
                let world=scene.childNode(withName:"worldNode")!
                switch manager.stage.type {
                case .capture,.defense:#expect(world.children.compactMap{$0 as? StoryObjectiveNode}.count==manager.stage.objectiveCount)
                case .assault:#expect(world.children.filter{$0.name=="storyPowerTarget"}.count==manager.stage.objectiveCount)
                case .boss,.eliteHunt:#expect(world.children.contains{$0.userData?["managedBoss"] as? Bool == true})
                default:break
                }
                tested.insert(manager.stage.type)
                view.presentScene(nil)
            }
        }
        #expect(tested.count==8)
    }
}

struct StoryIntegrationTests {
    @Test @MainActor func assaultDamageRegistersAndBriefingBlocksAbilities() {
        let suite="StoryDamage.\(UUID().uuidString)"
        let d=UserDefaults(suiteName:suite)!
        defer {d.removePersistentDomain(forName:suite)}
        d.set(StoryCampaign.version,forKey:"storyCampaignVersion");d.set(1,forKey:"shipUpgrade.bomb")
        let manager=StoryModeManager(missionIndex:2,defaults:d)
        let view=SKView(frame:CGRect(x:0,y:0,width:852,height:393)),game=GameScene(size:CGSize(width:852,height:393),storyModeManager:manager)
        game.progression=PlayerProgress(defaults:d);view.presentScene(game)
        let target=game.childNode(withName:"//storyPowerTarget") as! Enemy
        let player=game.childNode(withName:"//player")!;player.position=target.position;target.health=1
        game.activateBomb();#expect(target.parent != nil);#expect(manager.completedObjectives==0)
        manager.begin();game.activateBomb();#expect(target.parent == nil);#expect(manager.completedObjectives==1)
        view.presentScene(nil)
    }
    @Test @MainActor func missionArchiveFitsSmallPhoneAndKeepsLaunchVisible() {
        let size=CGSize(width:667,height:375),view=SKView(frame:CGRect(x:0,y:0,width:667,height:375))
        let scene=StoryMissionSelectScene(size:size);view.presentScene(scene)
        let button=scene.childNode(withName:"//launchMission")
        #expect(button != nil)
        if let button,let parent=button.parent {
            let position=parent.convert(button.position,to:scene)
            #expect(position.y>15 && position.y<size.height-15)
            #expect(position.x>0 && position.x<size.width)
        }
        #expect(scene.childNode(withName:"//missionPage_1") != nil)
        view.presentScene(nil)
    }
}

struct StoryTransitionTests {
    @Test @MainActor func checkpointRunsIntoNextArenaWithoutLosingProgress() async throws {
        let suite="StoryTransition.\(UUID().uuidString)"
        let d=UserDefaults(suiteName:suite)!
        defer {d.removePersistentDomain(forName:suite)}
        d.set(StoryCampaign.version,forKey:"storyCampaignVersion")
        let window=try #require(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.flatMap(\.windows).first{$0.isKeyWindow})
        let view=SKView(frame:window.bounds)
        let manager=StoryModeManager(missionIndex:0,defaults:d)
        let game=GameScene(size:view.bounds.size,storyModeManager:manager)
        window.addSubview(view);view.presentScene(game)
        defer {view.presentScene(nil);view.removeFromSuperview()}
        manager.begin();manager.complete()
        try await Task.sleep(nanoseconds:6_700_000_000)
        #expect(manager.stageIndex==1)
        #expect(manager.phase == .active)
        #expect(game.activeArena.phase==manager.stage.arenaPhase)
        #expect(game.childNode(withName:"worldNode")?.isPaused == false)
        #expect(game.childNode(withName:"worldNode")?.children.compactMap{$0 as? StoryObjectiveNode}.count==2)
    }
}

struct StoryFormationTests {
    @Test func everyCampaignArenaSupportsSafeFormationEntries() {
        for mission in StoryCampaign.missions {
            for stage in mission.stages {
                let arena=LivingArena(phase:stage.arenaPhase,center:.zero,variant:stage.arenaVariant)
                let player=arena.nearestFloor(to:CGPoint(x:-260,y:0))
                for pattern in 0..<4 {
                    let points=StoryFormation.positions(in:arena,pattern:pattern,group:1,count:6,player:player)
                    #expect(points.count==6)
                    for (i,point) in points.enumerated() {
                        #expect(arena.containsShip(at:point))
                        #expect(hypot(point.x-player.x,point.y-player.y)>420)
                        for other in points.prefix(i) {#expect(hypot(point.x-other.x,point.y-other.y)>65)}
                    }
                }
            }
        }
    }
}

struct HomeMovieTests {
    @Test @MainActor func homeContainsBundledMovieAndKeepsPlayAction() {
        #expect(Bundle.main.url(forResource:"InfiniteArenaPreview",withExtension:"m4v") != nil)
        let view=SKView(frame:CGRect(x:0,y:0,width:852,height:393)),scene=MainMenuScene(size:CGSize(width:852,height:393))
        view.presentScene(scene)
        #expect(scene.childNode(withName:"//infiniteArenaMovie") is SKVideoNode)
        #expect(scene.childNode(withName:"playPreview") != nil)
        view.presentScene(nil)
    }
}
