import SpriteKit

enum BossGameMode { case story, infinite }

struct BossEncounterContext {
    let mode: BossGameMode
    let storySector: Int?
    let storyMission: Int?
    let infiniteTier: Int?
    let bossType: BossType
    let generation: BossGeneration
}

struct BossWorld {
    let world: SKNode
    let playerPosition: () -> CGPoint
    let arenaCenter: () -> CGPoint
    let arenaBounds: () -> CGRect
    let nearestFloor: (CGPoint) -> CGPoint
    let navigationTarget: (CGPoint, CGPoint) -> CGPoint
    let resolveCollision: (Enemy) -> Void
    let fire: (CGPoint, CGFloat, CGFloat, CGFloat, SKColor) -> Void
    let spawnMinions: (CGPoint, Int) -> Void
    let addTemporaryWall: (CGRect, TimeInterval, SKColor) -> Void
    let effect: (CGPoint, SKColor) -> Void
}

class BaseBoss {
    let type: BossType
    let generation: BossGeneration
    let enemy: Enemy
    let world: BossWorld
    private(set) var phase = 1
    var clock: TimeInterval = 0
    var attackClock: TimeInterval = 0
    var actionClock: TimeInterval = 0
    var introRemaining: TimeInterval = 1.7
    var status = "EXPOSED"
    private var vulnerable = true

    init(type: BossType, generation: BossGeneration, baseHealth: CGFloat, baseDamage: CGFloat, world: BossWorld) {
        self.type = type
        self.generation = generation
        self.world = world
        enemy = Enemy()
        enemy.health = baseHealth * generation.healthScale
        enemy.maxHealth = enemy.health
        enemy.damage = baseDamage * generation.projectileScale
        enemy.moveSpeed = 0
        enemy.scoreValue = 12_000 * generation.rawValue
        enemy.userData = ["managedBoss": true, "sentinel": true, "bossType": type.rawValue,
                          "bossGeneration": generation.rawValue, "vulnerable": true]
        buildVisual()
    }

    var healthRatio: CGFloat { max(0, enemy.health / max(1, enemy.maxHealth)) }

    func update(_ delta: TimeInterval) {
        guard introRemaining <= 0 else {
            introRemaining -= delta
            enemy.zRotation += CGFloat(delta) * 0.6
            return
        }
        clock += delta
        attackClock += delta
        actionClock += delta
        let newPhase = healthRatio > 0.70 ? 1 : (healthRatio > 0.35 ? 2 : 3)
        if newPhase != phase {
            phase = newPhase
            phaseChanged()
        }
        perform(delta)
    }

    func perform(_ delta: TimeInterval) { }
    func cleanup() { world.world.enumerateChildNodes(withName: "bossHazard") { node, _ in node.removeFromParent() } }

    func phaseChanged() {
        attackClock = 0
        actionClock = 0
        world.effect(enemy.position, type.color)
        enemy.childNode(withName: "bossCracks")?.run(.fadeAlpha(to: phase == 3 ? 1 : 0.55, duration: 0.3))
        enemy.childNode(withName: "bossArmor")?.speed = phase == 3 ? 1.8 : 1.35
        enemy.run(.sequence([.scale(to: 1.34, duration: 0.12), .scale(to: 1, duration: 0.25)]))
    }

    func setVulnerable(_ value: Bool, status newStatus: String) {
        guard vulnerable != value || status != newStatus else { return }
        vulnerable = value
        status = newStatus
        enemy.userData?["vulnerable"] = value
        if let shield = enemy.childNode(withName: "bossShield") {
            shield.removeAllActions()
            shield.run(.fadeAlpha(to: value ? 0 : 0.55, duration: 0.18))
        }
    }

    func moveToward(_ target: CGPoint, speed: CGFloat, delta: TimeInterval) {
        let waypoint = world.navigationTarget(enemy.position, target)
        let dx = waypoint.x - enemy.position.x, dy = waypoint.y - enemy.position.y
        let length = max(1, hypot(dx, dy))
        let next = CGPoint(x: enemy.position.x + dx / length * speed * CGFloat(delta),
                           y: enemy.position.y + dy / length * speed * CGFloat(delta))
        enemy.position = world.nearestFloor(next)
        world.resolveCollision(enemy)
    }

    func orbit(center: CGPoint, radiusX: CGFloat, radiusY: CGFloat, speed: CGFloat, delta: TimeInterval) {
        let target = CGPoint(x: center.x + cos(CGFloat(clock) * speed) * radiusX,
                             y: center.y + sin(CGFloat(clock) * speed) * radiusY)
        moveToward(target, speed: 105 + CGFloat(phase) * 14, delta: delta)
    }

    func telegraph(radius: CGFloat, duration: TimeInterval, at point: CGPoint? = nil) {
        let ring = SKShapeNode(circleOfRadius: radius)
        ring.name = "bossHazard"
        ring.position = point ?? enemy.position
        ring.strokeColor = type.color
        ring.fillColor = type.color.withAlphaComponent(0.025)
        ring.lineWidth = 2.5
        ring.glowWidth = 7
        ring.zPosition = 18
        world.world.addChild(ring)
        ring.setScale(0.18)
        ring.run(.sequence([.group([.scale(to: 1, duration: duration), .fadeAlpha(to: 0.28, duration: duration)]), .removeFromParent()]))
    }

    func radial(count: Int, speed: CGFloat, damage: CGFloat, offset: CGFloat = 0) {
        for index in 0..<count {
            world.fire(enemy.position, CGFloat(index) * .pi * 2 / CGFloat(count) + offset, speed, damage, type.color)
        }
    }

    func aimed(spread: [CGFloat], speed: CGFloat, damage: CGFloat) {
        let player = world.playerPosition()
        let angle = atan2(player.y - enemy.position.y, player.x - enemy.position.x)
        spread.forEach { world.fire(enemy.position, angle + $0, speed, damage, type.color) }
    }

    private func buildVisual() {
        let radius: CGFloat
        let sides: Int
        switch type {
        case .hive: radius = 53; sides = 8
        case .pursuer: radius = 48; sides = 3
        case .sentinel: radius = 50; sides = 6
        case .architect: radius = 52; sides = 4
        case .core: radius = 60; sides = 12
        }
        enemy.path = Self.polygon(sides: sides, radius: radius, rotation: -.pi / 2)
        enemy.fillColor = SKColor(red: 0.065, green: 0.075, blue: 0.10, alpha: 1)
        enemy.strokeColor = type.color
        enemy.lineWidth = 2
        enemy.glowWidth = 2
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        enemy.physicsBody?.affectedByGravity = false
        enemy.physicsBody?.categoryBitMask = 1 << 1
        enemy.physicsBody?.collisionBitMask = 0
        enemy.physicsBody?.contactTestBitMask = (1 << 2) | (1 << 0)

        let shield = SKShapeNode(circleOfRadius: radius + 13)
        shield.name = "bossShield"
        shield.fillColor = type.color.withAlphaComponent(0.08)
        shield.strokeColor = .white
        shield.lineWidth = 2
        shield.glowWidth = 9
        shield.alpha = 0
        enemy.addChild(shield)

        // Armor remains within the collision radius except for decorative tips.
        let armor = SKNode()
        armor.name = "bossArmor"
        enemy.addChild(armor)
        let steel = SKColor(red: 0.16, green: 0.18, blue: 0.23, alpha: 1)
        let dark = SKColor(red: 0.035, green: 0.04, blue: 0.065, alpha: 1)
        func plate(_ values: [(CGFloat, CGFloat)], parent: SKNode, fill: SKColor) -> SKShapeNode {
            let path = CGMutablePath()
            for (index, value) in values.enumerated() {
                let point = CGPoint(x: value.0 * radius, y: value.1 * radius)
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
            let node = SKShapeNode(path: path)
            node.fillColor = fill
            node.strokeColor = type.color.withAlphaComponent(0.6)
            node.lineWidth = 1.2
            node.glowWidth = 0.5
            parent.addChild(node)
            return node
        }
        switch type {
        case .pursuer:
            enemy.path = Self.polygon(sides: 3, radius: radius, rotation: 0)
            for side: CGFloat in [-1, 1] {
                let claw = plate([(-0.75, side * 0.32), (-0.55, side * 0.90),
                                  (0.72, side * 0.68), (1.10, side * 0.18),
                                  (0.46, side * 0.40), (-0.05, side * 0.25)], parent: armor, fill: steel)
                claw.run(.repeatForever(.sequence([.rotate(byAngle: side * 0.08, duration: 0.8),
                                                   .rotate(byAngle: -side * 0.08, duration: 0.8)])))
            }
            _ = plate([(-0.92, 0), (-0.38, 0.36), (0.60, 0.19), (0.87, 0),
                       (0.60, -0.19), (-0.38, -0.36)], parent: armor, fill: dark)
        case .sentinel:
            for side: CGFloat in [-1, 1] {
                _ = plate([(side * 0.18, 0.43), (side * 0.50, 1.13), (side * 0.60, 0.57),
                           (side * 0.94, 0.30), (side * 0.80, -0.60),
                           (side * 0.40, -0.83), (side * 0.31, 0.03)], parent: armor, fill: steel)
                _ = plate([(side * 0.57, 0.20), (side * 0.83, 0.18),
                           (side * 0.83, -0.69), (side * 0.57, -0.69)], parent: armor, fill: dark)
            }
        case .hive:
            for side: CGFloat in [-1, 1] {
                for index in 0..<3 {
                    let y = CGFloat(index) * 0.46 - 0.52
                    let limb = plate([(side * 0.34, y + 0.20), (side * 0.83, y + 0.32),
                                      (side * 1.09, y - 0.08), (side * 0.74, y + 0.03),
                                      (side * 0.32, y - 0.03)], parent: armor, fill: steel)
                    let duration = 0.65 + Double(index) * 0.1
                    limb.run(.repeatForever(.sequence([.rotate(byAngle: side * 0.05, duration: duration),
                                                       .rotate(byAngle: -side * 0.05, duration: duration)])))
                }
            }
            _ = plate([(0, 0.95), (0.49, 0.40), (0.42, -0.52), (0, -0.96),
                       (-0.42, -0.52), (-0.49, 0.40)], parent: armor, fill: dark)
        case .architect, .core:
            let count = type == .core ? 8 : 4
            for index in 0..<count {
                let blade = plate([(0.35, -0.18), (0.80, -0.29), (1.10, 0.13),
                                   (0.77, 0.03), (0.61, 0.37), (0.35, 0.18)], parent: armor, fill: steel)
                blade.zRotation = CGFloat(index) * .pi * 2 / CGFloat(count)
            }
            armor.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: type == .core ? 18 : 24)))
        }

        // Recessed face and teeth retain a hostile expression at gameplay scale.
        let face = SKNode()
        face.zPosition = 3
        face.zRotation = type == .pursuer ? .pi / 2 : 0
        enemy.addChild(face)
        _ = plate([(-0.37, 0.35), (0, 0.49), (0.37, 0.35), (0.30, -0.35),
                   (0, -0.55), (-0.30, -0.35)], parent: face, fill: dark)
        let eyes = SKNode()
        eyes.name = "bossEyes"
        face.addChild(eyes)
        for side: CGFloat in [-1, 1] {
            let eye = plate([(side * 0.06, 0.08), (side * 0.29, 0.22),
                             (side * 0.24, 0.02), (side * 0.07, -0.02)], parent: eyes, fill: type.color)
            eye.strokeColor = .white
            eye.lineWidth = 0.6
            eye.glowWidth = 5
            for index in 0..<3 {
                let x = side * (0.06 + CGFloat(index) * 0.075)
                _ = plate([(x, -0.19), (x + side * 0.05, -0.17),
                           (x + side * 0.02, -0.34)], parent: face, fill: steel)
            }
        }
        eyes.run(.repeatForever(.sequence([.fadeAlpha(to: 0.55, duration: 0.9), .fadeAlpha(to: 1, duration: 0.35)])))

        let cracks = SKNode()
        cracks.name = "bossCracks"
        cracks.zPosition = 2
        cracks.alpha = 0.15
        enemy.addChild(cracks)
        for index in 0..<6 {
            let crack = plate([(0.35, -0.015), (0.56, 0.08), (0.67, 0.02),
                               (0.91, 0.12), (0.66, 0.06), (0.55, 0.12)], parent: cracks, fill: type.color)
            crack.zRotation = CGFloat(index) * .pi / 3
            crack.glowWidth = 3
        }
    }

    private static func polygon(sides: Int, radius: CGFloat, rotation: CGFloat) -> CGPath {
        let path = CGMutablePath()
        for index in 0..<sides {
            let angle = CGFloat(index) * .pi * 2 / CGFloat(sides) + rotation
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}
