import SpriteKit

final class PursuerBoss: BaseBoss {
    private enum State { case hunt, warning, charge, stunned }
    private var state = State.hunt
    private var direction = CGVector.zero
    private var burstClock: TimeInterval = 0

    init(generation: BossGeneration, health: CGFloat, world: BossWorld) {
        super.init(type: .pursuer, generation: generation, baseHealth: health, baseDamage: 23, world: world)
    }

    override func phaseChanged() { super.phaseChanged(); state = .hunt; actionClock = 0 }

    override func perform(_ delta: TimeInterval) {
        burstClock += delta
        switch state {
        case .hunt:
            setVulnerable(true, status: "HUNTING")
            moveToward(world.playerPosition(), speed: 125 + CGFloat(phase) * 18, delta: delta)
            let p = world.playerPosition(); enemy.zRotation = atan2(p.y - enemy.position.y, p.x - enemy.position.x)
            if burstClock > 1.6 {
                burstClock = 0
                aimed(spread: phase == 1 ? [-0.22, 0.22] : [-0.32, -0.1, 0.1, 0.32], speed: 270, damage: enemy.damage * 0.72)
            }
            if actionClock > (4.8 - Double(phase) * 0.45) * generation.cadenceScale {
                actionClock = 0; state = .warning; telegraph(radius: 82, duration: 0.85)
            }
        case .warning:
            setVulnerable(false, status: "CHARGE LOCK")
            if actionClock > 0.9 {
                let p = world.playerPosition(), angle = atan2(p.y - enemy.position.y, p.x - enemy.position.x)
                direction = CGVector(dx: cos(angle), dy: sin(angle)); actionClock = 0; state = .charge
            }
        case .charge:
            setVulnerable(false, status: "IMPACT CHARGE")
            let next = CGPoint(x: enemy.position.x + direction.dx * CGFloat(delta) * (500 + CGFloat(phase) * 70),
                               y: enemy.position.y + direction.dy * CGFloat(delta) * (500 + CGFloat(phase) * 70))
            let clamped = world.nearestFloor(next)
            enemy.position = clamped
            world.resolveCollision(enemy)
            let collisionCorrection = hypot(enemy.position.x - clamped.x, enemy.position.y - clamped.y)
            if hypot(clamped.x - next.x, clamped.y - next.y) > 6 || collisionCorrection > 5 || actionClock > 1.0 {
                actionClock = 0; state = .stunned
                world.effect(enemy.position, .orange)
                radial(count: 6 + phase * 2, speed: 210, damage: enemy.damage * 0.62)
            }
        case .stunned:
            setVulnerable(true, status: "STUNNED — FIRE")
            enemy.strokeColor = .white
            if actionClock > 2.25 { actionClock = 0; state = .hunt; enemy.strokeColor = type.color }
        }
    }
}
