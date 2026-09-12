import SpriteKit

final class SentinelBoss: BaseBoss {
    private enum State { case reposition, cannon, lattice, exposed }
    private var state = State.reposition
    private var shotClock: TimeInterval = 0
    private var anchorIndex = 0

    init(generation: BossGeneration, health: CGFloat, world: BossWorld) {
        super.init(type: .sentinel, generation: generation, baseHealth: health, baseDamage: 18, world: world)
    }

    override func phaseChanged() { super.phaseChanged(); state = .reposition; actionClock = 0 }

    override func perform(_ delta: TimeInterval) {
        shotClock += delta
        let center = world.arenaCenter()
        let anchors = [CGPoint(x:center.x-185,y:center.y+105),CGPoint(x:center.x+185,y:center.y+105),
                       CGPoint(x:center.x+185,y:center.y-105),CGPoint(x:center.x-185,y:center.y-105)]
        switch state {
        case .reposition:
            setVulnerable(false, status: "REPOSITIONING")
            moveToward(world.nearestFloor(anchors[anchorIndex % anchors.count]), speed: 180, delta: delta)
            if actionClock > 1.25 { actionClock=0;shotClock=0;state = .cannon }
        case .cannon:
            setVulnerable(true, status: "TRACKING CANNONS")
            if shotClock > 0.48 * generation.cadenceScale {
                shotClock=0
                let width:CGFloat = phase == 1 ? 0.18:0.25
                aimed(spread:[-width,0,width],speed:300,damage:enemy.damage)
            }
            if actionClock > 3.8 { actionClock=0;shotClock=0;state = .lattice;telegraph(radius:155,duration:0.7) }
        case .lattice:
            setVulnerable(false, status: "LASER LATTICE")
            if shotClock > 0.34 {
                shotClock=0
                let spokes = phase == 3 ? 8:6
                radial(count:spokes,speed:250,damage:enemy.damage*0.78,offset:CGFloat(actionClock)*0.7)
            }
            if actionClock > 2.5 { actionClock=0;shotClock=0;state = .exposed }
        case .exposed:
            setVulnerable(true, status: "POWER CORE EXPOSED")
            orbit(center:center,radiusX:80,radiusY:55,speed:0.8,delta:delta)
            if shotClock > 0.9 { shotClock=0;radial(count:7+phase*2,speed:180,damage:enemy.damage*0.58,offset:CGFloat(clock)*0.2) }
            if actionClock > 3.1 { actionClock=0;anchorIndex += 1;state = .reposition }
        }
    }
}
