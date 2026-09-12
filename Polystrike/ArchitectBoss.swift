import SpriteKit

final class ArchitectBoss: BaseBoss {
    private enum State { case shaping, crossfire, exposed }
    private var state = State.shaping
    private var built = false
    private var shotClock: TimeInterval = 0

    init(generation: BossGeneration, health: CGFloat, world: BossWorld) {
        super.init(type: .architect, generation: generation, baseHealth: health, baseDamage: 19, world: world)
    }

    override func phaseChanged() { super.phaseChanged(); state = .shaping; built = false; actionClock = 0 }

    override func perform(_ delta: TimeInterval) {
        shotClock += delta
        let center=world.arenaCenter()
        switch state {
        case .shaping:
            setVulnerable(false,status:"REWRITING ARENA")
            moveToward(center,speed:135,delta:delta)
            if !built {
                built=true;telegraph(radius:185,duration:0.85)
                let vertical = phase.isMultiple(of:2)
                let first = vertical ? CGRect(x:center.x-125,y:center.y-125,width:18,height:175):CGRect(x:center.x-205,y:center.y+72,width:175,height:18)
                let second = vertical ? CGRect(x:center.x+107,y:center.y-50,width:18,height:175):CGRect(x:center.x+30,y:center.y-90,width:175,height:18)
                world.addTemporaryWall(first,5.2,type.color);world.addTemporaryWall(second,5.2,type.color)
            }
            if actionClock>1.4{actionClock=0;shotClock=0;state = .crossfire}
        case .crossfire:
            setVulnerable(true,status:"PRISM CROSSFIRE")
            orbit(center:center,radiusX:195,radiusY:130,speed:0.44,delta:delta)
            if shotClock>0.62*generation.cadenceScale{shotClock=0;aimed(spread:[-0.42,-0.14,0.14,0.42],speed:265,damage:enemy.damage*0.8)}
            if actionClock>4.0{actionClock=0;shotClock=0;state = .exposed}
        case .exposed:
            setVulnerable(true,status:"GEOMETRY CORE EXPOSED")
            moveToward(center,speed:90,delta:delta)
            if shotClock>0.75{shotClock=0;radial(count:8+phase*3,speed:205,damage:enemy.damage*0.65,offset:CGFloat(clock)*0.5)}
            if actionClock>3.0{actionClock=0;built=false;state = .shaping}
        }
    }
}
