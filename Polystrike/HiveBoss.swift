import SpriteKit

final class HiveBoss: BaseBoss {
    private var cycle: TimeInterval = 0
    private var volleyClock: TimeInterval = 0
    private var deployedThisCycle = false

    init(generation: BossGeneration, health: CGFloat, world: BossWorld) {
        super.init(type: .hive, generation: generation, baseHealth: health, baseDamage: 15, world: world)
    }

    override func phaseChanged() { super.phaseChanged(); cycle = 0; deployedThisCycle = false }

    override func perform(_ delta: TimeInterval) {
        cycle += delta
        volleyClock += delta
        orbit(center: world.arenaCenter(), radiusX: 205, radiusY: 135, speed: 0.23 + CGFloat(phase) * 0.035, delta: delta)
        enemy.zRotation += CGFloat(delta) * 0.25
        let adjusted = cycle / generation.cadenceScale
        if adjusted < 4.8 {
            setVulnerable(true, status: "BROOD CANNONS")
            if volleyClock > 1.15 - Double(phase) * 0.12 {
                volleyClock = 0
                aimed(spread: phase == 1 ? [-0.18, 0, 0.18] : [-0.34, -0.17, 0, 0.17, 0.34], speed: 255, damage: enemy.damage)
            }
        } else if adjusted < 7.5 {
            setVulnerable(false, status: "DEPLOYING BROOD")
            if !deployedThisCycle {
                deployedThisCycle = true
                telegraph(radius: 105, duration: 0.7)
                world.spawnMinions(enemy.position, min(7, 3 + phase + generation.rawValue / 2))
            }
        } else if adjusted < 11.5 {
            setVulnerable(true, status: "CORE OVERLOAD")
            if volleyClock > 0.82 {
                volleyClock = 0
                radial(count: 8 + phase * 3, speed: 205, damage: enemy.damage * 0.72, offset: CGFloat(clock) * 0.42)
            }
        } else {
            cycle = 0
            deployedThisCycle = false
        }
    }
}
