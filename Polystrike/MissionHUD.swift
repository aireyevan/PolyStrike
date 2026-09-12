import SpriteKit

final class MissionHUD: SKNode {
    private let title = SKLabelNode(fontNamed:"AvenirNext-DemiBold")
    private let value = SKLabelNode(fontNamed:"AvenirNext-Bold")
    private let fill = SKShapeNode(rectOf:CGSize(width:132,height:2))
    override init() {
        super.init()
        let panel=SKShapeNode(rectOf:CGSize(width:162,height:48),cornerRadius:2)
        panel.fillColor=NeonColors.panel.withAlphaComponent(0.94); panel.strokeColor=SKColor.cyan.withAlphaComponent(0.5); panel.lineWidth=1; addChild(panel)
        title.fontSize=7; title.fontColor=NeonColors.mutedText; title.position.y=9
        value.fontSize=11; value.fontColor = .white; value.position.y = -7; addChild(title); addChild(value)
        let track=SKShapeNode(rectOf:CGSize(width:132,height:2)); track.fillColor=SKColor.white.withAlphaComponent(0.1); track.strokeColor = .clear; track.position.y = -20; addChild(track)
        fill.fillColor = .cyan; fill.strokeColor = .clear; fill.position=CGPoint(x:-66,y:-20); fill.xScale=0; addChild(fill)
    }
    required init?(coder:NSCoder){fatalError()}
    func render(_ status:MissionStatus){title.text=status.title;value.text=status.value;fill.xScale=max(0.001,min(1,status.progress));fill.position.x = -66 + 66 * fill.xScale}
}
