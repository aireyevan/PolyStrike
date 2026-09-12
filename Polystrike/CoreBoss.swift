import SpriteKit

final class CoreBoss: BaseBoss {
    private enum State { case spiral, artillery, summon, overload }
    private var state = State.spiral
    private var shotClock: TimeInterval = 0
    private var summoned = false

    init(generation: BossGeneration, health: CGFloat, world: BossWorld) {
        super.init(type: .core, generation: generation, baseHealth: health, baseDamage: 21, world: world)
    }

    override func phaseChanged() { super.phaseChanged(); state = .spiral; actionClock=0;shotClock=0;summoned=false }

    override func perform(_ delta: TimeInterval) {
        shotClock += delta
        let center=world.arenaCenter()
        enemy.zRotation -= CGFloat(delta)*(0.35+CGFloat(phase)*0.12)
        switch state {
        case .spiral:
            setVulnerable(true,status:"SPIRAL ARRAY")
            orbit(center:center,radiusX:125,radiusY:90,speed:0.3,delta:delta)
            if shotClock>0.22*generation.cadenceScale{shotClock=0;radial(count:phase>=2 ? 4:3,speed:220,damage:enemy.damage*0.62,offset:CGFloat(clock)*1.2)}
            if actionClock>4.2{actionClock=0;shotClock=0;state = .artillery;telegraph(radius:190,duration:0.8)}
        case .artillery:
            setVulnerable(false,status:"ARTILLERY STORM")
            moveToward(center,speed:115,delta:delta)
            if shotClock>0.52{shotClock=0;aimed(spread:[-0.48,-0.24,0,0.24,0.48],speed:330,damage:enemy.damage)}
            if actionClock>3.2{actionClock=0;shotClock=0;summoned=false;state = phase>=2 ? .summon:.overload}
        case .summon:
            setVulnerable(false,status:"CORE REINFORCEMENTS")
            if !summoned{summoned=true;world.spawnMinions(enemy.position,3+phase);radial(count:12,speed:175,damage:enemy.damage*0.55)}
            if actionClock>2.2{actionClock=0;shotClock=0;state = .overload}
        case .overload:
            setVulnerable(true,status:"APEX CORE EXPOSED")
            if shotClock>0.58{shotClock=0;radial(count:12+phase*4,speed:245,damage:enemy.damage*0.78,offset:CGFloat(clock)*0.36);aimed(spread:[-0.16,0,0.16],speed:350,damage:enemy.damage)}
            if actionClock>3.6{actionClock=0;shotClock=0;state = .spiral}
        }
    }
}
