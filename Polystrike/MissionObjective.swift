import SpriteKit

enum MissionPhase { case briefing, active, checkpoint, complete, failed }
struct MissionStatus { let title: String; let value: String; let progress: CGFloat }

/// Physical-looking objective machinery with a bounded number of animated parts.
final class StoryObjectiveNode: SKNode {
    enum Kind { case reactor, relay, installation, gate }
    let kind: Kind
    private let energy=SKNode()
    private let progressArc=SKShapeNode()
    private let stateLabel=SKLabelNode(fontNamed:"AvenirNext-Bold")
    private var renderedState=""
    private var renderedPercent = -1
    private let tint: SKColor
    private let radius: CGFloat

    init(kind:Kind,index:Int=0) {
        self.kind=kind
        tint = kind == .installation ? NeonColors.orange : kind == .gate ? NeonColors.green : .cyan
        radius = kind == .reactor ? 43 : kind == .relay ? 49 : kind == .installation ? 31:48
        super.init();zPosition=5;name="storyMachine"
        let shadow=SKShapeNode(ellipseOf:CGSize(width:radius*2.3,height:radius*1.7));shadow.position.y = -8
        shadow.fillColor=SKColor.black.withAlphaComponent(0.65);shadow.strokeColor = .clear;addChild(shadow)
        let base=SKShapeNode(path:Self.polygon(sides:kind == .installation ? 4:8,radius:radius,rotation:.pi/8))
        base.fillColor=NeonColors.panel;base.strokeColor=SKColor(white:0.4,alpha:1);base.lineWidth=2;addChild(base)
        CombatSurface.add(to:base,path:base.path!,color:tint,variant:400+index%2,name:"machineArmor")
        let hub=SKShapeNode(circleOfRadius:radius*0.53);hub.fillColor=SKColor(red:0.015,green:0.025,blue:0.05,alpha:1);hub.strokeColor=tint.withAlphaComponent(0.6);hub.lineWidth=2;hub.zPosition=1;addChild(hub)
        for i in 0..<4 {
            let angle=CGFloat(i) * .pi/2 + .pi/4
            let arm=SKShapeNode(rectOf:CGSize(width:radius*0.72,height:11),cornerRadius:2)
            arm.position=CGPoint(x:cos(angle)*radius*0.78,y:sin(angle)*radius*0.78);arm.zRotation=angle
            arm.fillColor=SKColor(white:0.20,alpha:1);arm.strokeColor=SKColor(white:0.55,alpha:1);arm.lineWidth=1;arm.zPosition=2;addChild(arm)
            let slot=SKShapeNode(rectOf:CGSize(width:radius*0.35,height:3),cornerRadius:1);slot.fillColor=tint;slot.strokeColor = .clear;slot.glowWidth=0.8;arm.addChild(slot)
        }
        energy.zPosition=3;addChild(energy)
        switch kind {
        case .reactor:
            for i in 0..<3 {
                let coil=SKShapeNode(ellipseOf:CGSize(width:47,height:17));coil.zRotation=CGFloat(i) * .pi/3;coil.strokeColor=tint;coil.lineWidth=1.5;coil.glowWidth=1;energy.addChild(coil)
            }
            energy.run(.repeatForever(.rotate(byAngle:.pi*2,duration:8)))
        case .relay:
            for i in 0..<3 {
                let dish=SKShapeNode(path:Self.arc(radius:CGFloat(10+i*6),start:0.25,end:2.9));dish.strokeColor=tint;dish.lineWidth=2;energy.addChild(dish)
            }
            energy.run(.repeatForever(.rotate(byAngle:-.pi*2,duration:6)))
        case .installation:
            for side:CGFloat in [-1,1] {
                let battery=SKShapeNode(rectOf:CGSize(width:9,height:32),cornerRadius:2);battery.position.x=side*10;battery.fillColor=SKColor(red:0.16,green:0.07,blue:0.035,alpha:1);battery.strokeColor=tint;battery.lineWidth=1.5;energy.addChild(battery)
                for y in [-9,0,9] {let vent=SKShapeNode(rectOf:CGSize(width:5,height:2));vent.position.y=CGFloat(y);vent.fillColor=tint;vent.strokeColor = .clear;battery.addChild(vent)}
            }
        case .gate:
            for i in 0..<3 {let ring=SKShapeNode(path:Self.polygon(sides:6,radius:CGFloat(16+i*6),rotation:0));ring.strokeColor=tint.withAlphaComponent(CGFloat(1)-CGFloat(i)*0.2);ring.lineWidth=1.5;energy.addChild(ring)}
            energy.run(.repeatForever(.rotate(byAngle:.pi*2,duration:9)))
        }
        let core=SKShapeNode(path:Self.polygon(sides:kind == .installation ? 4:6,radius:7,rotation:0));core.fillColor = .white;core.strokeColor=tint;core.glowWidth=2;core.zPosition=4;addChild(core)
        core.run(.repeatForever(.sequence([.fadeAlpha(to:0.4,duration:0.7),.fadeAlpha(to:1,duration:0.7)])))
        let track=SKShapeNode(circleOfRadius:radius+11);track.strokeColor=SKColor.white.withAlphaComponent(0.16);track.lineWidth=2;addChild(track)
        progressArc.lineWidth=3;progressArc.strokeColor=tint;progressArc.glowWidth=0.6;progressArc.zPosition=6;addChild(progressArc)
        let title=SKLabelNode(fontNamed:"AvenirNext-Heavy");title.fontSize=8;title.fontColor = .white;title.position.y=radius+24
        title.text=kind == .reactor ? "REACTOR" : kind == .relay ? "RELAY 0\(index+1)" : kind == .installation ? "POWER NODE 0\(index+1)":"EXTRACTION";addChild(title)
        stateLabel.fontSize=7;stateLabel.fontColor=tint;stateLabel.position.y = -radius-23;addChild(stateLabel)
        render(progress:kind == .relay ? 0:1,state:kind == .relay ? "AWAITING LINK":kind == .installation ? "DESTROY":kind == .gate ? "GATE ONLINE":"INTEGRITY 100%")
    }
    required init?(coder:NSCoder) {fatalError()}
    func render(progress:CGFloat,state:String,contested:Bool=false) {
        let percent=Int(max(0,min(1,progress))*100)
        if renderedPercent != percent {
            renderedPercent=percent
            progressArc.path=Self.arc(radius:radius+11,start:.pi/2,end:.pi/2+CGFloat(max(1,percent))/100 * .pi*2)
        }
        let key=state+(contested ? "!":"")
        if renderedState != key {
            renderedState=key;stateLabel.text=state
            let color=(contested || (kind == .installation && percent<35)) ? NeonColors.pink : (kind == .relay && percent==100 ? NeonColors.green:tint)
            progressArc.strokeColor=color;stateLabel.fontColor=color
            energy.alpha=contested ? 0.45:1
        }
    }
    private static func polygon(sides:Int,radius:CGFloat,rotation:CGFloat)->CGPath {
        let p=CGMutablePath();for i in 0..<sides {let a=CGFloat(i)*2 * .pi/CGFloat(sides)+rotation;let point=CGPoint(x:cos(a)*radius,y:sin(a)*radius);if i==0 {p.move(to:point)}else{p.addLine(to:point)}};p.closeSubpath();return p
    }
    private static func arc(radius:CGFloat,start:CGFloat,end:CGFloat)->CGPath {let p=CGMutablePath();p.addArc(center:.zero,radius:radius,startAngle:start,endAngle:end,clockwise:false);return p}
}
