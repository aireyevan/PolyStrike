import SpriteKit

final class BossManager {
    private(set) var activeBoss: BaseBoss?
    private var lastInfiniteType: BossType?
    private let hud = SKNode(), fill = SKShapeNode(rectOf: CGSize(width: 246, height: 6), cornerRadius: 3)
    private let title = SKLabelNode(fontNamed: "AvenirNext-Heavy"), percent = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var context: BossEncounterContext?
    var onDefeated: ((BossEncounterContext) -> Void)?
    var isActive: Bool { activeBoss != nil }
    var enemy: Enemy? { activeBoss?.enemy }

    func attachHUD(to camera: SKCameraNode, screenSize: CGSize, topInset: CGFloat) {
        hud.removeFromParent(); hud.removeAllChildren(); hud.name="bossHUD"; hud.zPosition=760; hud.position=CGPoint(x:0,y:screenSize.height/2-topInset-38)
        let panel=SKShapeNode(rectOf:CGSize(width:290,height:48),cornerRadius:3);panel.fillColor=SKColor.black.withAlphaComponent(0.76);panel.strokeColor=SKColor.white.withAlphaComponent(0.24);hud.addChild(panel)
        let bg=SKShapeNode(rectOf:CGSize(width:246,height:6),cornerRadius:3);bg.fillColor=SKColor.white.withAlphaComponent(0.12);bg.strokeColor = .clear;bg.position=CGPoint(x:0,y:-11);hud.addChild(bg)
        fill.position=CGPoint(x:0,y:-11);fill.strokeColor = .clear;hud.addChild(fill)
        title.fontSize=11;title.fontColor = .white;title.position=CGPoint(x:-122,y:7);title.horizontalAlignmentMode = .left;hud.addChild(title)
        percent.fontSize=9;percent.fontColor = .white;percent.position=CGPoint(x:122,y:7);percent.horizontalAlignmentMode = .right;hud.addChild(percent)
        hud.alpha=0;camera.addChild(hud)
    }

    func startStory(mission: Mission, baseHealth: CGFloat, world: BossWorld) {
        let types:[BossType]=[.hive,.pursuer,.sentinel,.architect,.core], type=types[min(4,mission.sector-1)]
        start(BossEncounterContext(mode:.story,storySector:mission.sector,storyMission:mission.number,infiniteTier:nil,bossType:type,generation:BossGeneration(rawValue:min(5,mission.sector)) ?? .one),baseHealth:baseHealth,world:world,displayName:mission.bossName)
    }
    func startInfinite(tier:Int,baseHealth:CGFloat,world:BossWorld) {
        let choices=BossType.allCases.filter{$0 != lastInfiniteType};let type=choices.randomElement() ?? .sentinel;lastInfiniteType=type
        start(BossEncounterContext(mode:.infinite,storySector:nil,storyMission:nil,infiniteTier:tier,bossType:type,generation:.infinite(tier:tier)),baseHealth:baseHealth,world:world,displayName:nil)
    }
    private func start(_ encounter:BossEncounterContext,baseHealth:CGFloat,world:BossWorld,displayName:String?) {
        cleanup();context=encounter
        let boss:BaseBoss
        switch encounter.bossType {case .hive:boss=HiveBoss(generation:encounter.generation,health:baseHealth,world:world);case .pursuer:boss=PursuerBoss(generation:encounter.generation,health:baseHealth,world:world);case .sentinel:boss=SentinelBoss(generation:encounter.generation,health:baseHealth,world:world);case .architect:boss=ArchitectBoss(generation:encounter.generation,health:baseHealth,world:world);case .core:boss=CoreBoss(generation:encounter.generation,health:baseHealth,world:world)}
        activeBoss=boss;boss.enemy.position=world.nearestFloor(CGPoint(x:world.arenaCenter().x,y:world.arenaBounds().maxY-115));boss.enemy.userData?["storyElite"] = encounter.mode == .story;world.world.addChild(boss.enemy);world.effect(boss.enemy.position,boss.type.color)
        title.text=(displayName ?? boss.type.name)+"  //  GEN \(encounter.generation.rawValue)";fill.fillColor=boss.type.color;fill.glowWidth=5;hud.run(.fadeIn(withDuration:0.28))
    }
    func update(_ delta:TimeInterval) {
        guard let boss=activeBoss else{return}
        boss.update(delta)
        let ratio=boss.healthRatio
        fill.xScale=ratio
        fill.position.x = -123 + 123*ratio
        percent.text="\(Int(ratio*100))%  •  PHASE \(boss.phase)"
    }
    func defeated(_ enemy:Enemy) -> Bool { guard let boss=activeBoss,boss.enemy===enemy,let encounter=context else{return false};boss.cleanup();activeBoss=nil;context=nil;hud.run(.fadeOut(withDuration:0.35));onDefeated?(encounter);return true }
    func cleanup(){activeBoss?.cleanup();activeBoss=nil;context=nil;hud.removeAllActions();hud.alpha=0}
}
