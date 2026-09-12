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
        enemy.fillColor = type.color.withAlphaComponent(0.22)
        enemy.strokeColor = type.color
        enemy.lineWidth = 4
        enemy.glowWidth = 12
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

        let inner = SKShapeNode(path: Self.polygon(sides: max(3, sides), radius: radius * 0.55, rotation: .pi / 4))
        inner.fillColor = SKColor.black.withAlphaComponent(0.45)
        inner.strokeColor = .white
        inner.lineWidth = 2
        inner.glowWidth = 5
        enemy.addChild(inner)
        inner.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: type == .core ? 2.6 : 4.2)))

        let satellites = type == .hive ? 6 : (type == .sentinel ? 4 : (type == .core ? 8 : 3))
        let orbitNode = SKNode()
        enemy.addChild(orbitNode)
        for index in 0..<satellites {
            let angle = CGFloat(index) * .pi * 2 / CGFloat(satellites)
            let part = SKShapeNode(path: Self.polygon(sides: type == .pursuer ? 3 : 4, radius: type == .core ? 6 : 5, rotation: angle))
            part.position = CGPoint(x: cos(angle) * (radius + 7), y: sin(angle) * (radius + 7))
            part.fillColor = .white
            part.strokeColor = type.color
            part.glowWidth = 5
            orbitNode.addChild(part)
        }
        orbitNode.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: type == .pursuer ? 2.2 : 5.5)))
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
