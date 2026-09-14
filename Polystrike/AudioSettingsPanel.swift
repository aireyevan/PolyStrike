import SpriteKit
import UIKit

final class AudioSliderNode:SKNode {
    let channel:AudioChannel
    private let trackWidth:CGFloat
    private let fill=SKShapeNode(),thumb=SKShapeNode(rectOf:CGSize(width:14,height:24),cornerRadius:3)
    private let readout=SKLabelNode(fontNamed:"AvenirNext-Bold")
    private(set) var value:Float
    init(channel:AudioChannel,width:CGFloat) {
        self.channel=channel;trackWidth=width;value=GameSettings.shared.volume(channel)
        super.init();name="volume_\(channel.rawValue)";isUserInteractionEnabled=true
        let hit=SKShapeNode(rectOf:CGSize(width:width+24,height:52));hit.fillColor=SKColor.white.withAlphaComponent(0.001);hit.strokeColor = .clear;addChild(hit)
        let label=SKLabelNode(fontNamed:"AvenirNext-DemiBold");label.text=channel.title;label.fontSize=10;label.fontColor = .white;label.horizontalAlignmentMode = .left;label.position=CGPoint(x:-width/2,y:16);addChild(label)
        readout.fontSize=10;readout.fontColor = .cyan;readout.horizontalAlignmentMode = .right;readout.position=CGPoint(x:width/2,y:16);addChild(readout)
        let track=SKShapeNode(rectOf:CGSize(width:width,height:6),cornerRadius:3);track.fillColor=SKColor(white:0.15,alpha:1);track.strokeColor=SKColor(white:0.3,alpha:1);track.position.y = -6;addChild(track)
        fill.fillColor = .cyan;fill.strokeColor = .clear;fill.position.y = -6;addChild(fill)
        for i in 0...10 {let tick=SKShapeNode(rectOf:CGSize(width:1,height:4));tick.position=CGPoint(x:-width/2+CGFloat(i)*width/10,y:-18);tick.fillColor=SKColor.white.withAlphaComponent(0.3);tick.strokeColor = .clear;addChild(tick)}
        thumb.fillColor=NeonColors.panel;thumb.strokeColor = .cyan;thumb.lineWidth=2;thumb.position.y = -6;addChild(thumb)
        isAccessibilityElement=true;accessibilityLabel=channel.title;accessibilityTraits = .adjustable
        render()
    }
    required init?(coder:NSCoder){fatalError()}
    static func normalized(x:CGFloat,width:CGFloat)->Float {guard width>0 else{return 0};return Float(max(0,min(1,(x+width/2)/width)))}
    func setValue(_ newValue:Float) {
        value=newValue.isFinite ? max(0,min(1,newValue)):0
        GameSettings.shared.setVolume(value,for:channel);GameAudio.shared.applyVolumes();render()
    }
    private func render() {
        let amount=CGFloat(value)*trackWidth
        fill.path=CGPath(roundedRect:CGRect(x:-trackWidth/2,y:-3,width:max(0.001,amount),height:6),cornerWidth:3,cornerHeight:3,transform:nil)
        thumb.position.x = -trackWidth/2+amount
        readout.text=value==0 ? "MUTED":"\(Int((value*100).rounded()))%";accessibilityValue=readout.text
    }
    override func touchesBegan(_ touches:Set<UITouch>,with event:UIEvent?) {adjust(touches)}
    override func touchesMoved(_ touches:Set<UITouch>,with event:UIEvent?) {adjust(touches)}
    override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?) {adjust(touches);GameAudio.shared.preview(channel)}
    private func adjust(_ touches:Set<UITouch>) {if let touch=touches.first {setValue(Self.normalized(x:touch.location(in:self).x,width:trackWidth))}}
    override func accessibilityIncrement(){setValue(value+0.05);GameAudio.shared.preview(channel)}
    override func accessibilityDecrement(){setValue(value-0.05);GameAudio.shared.preview(channel)}
}
final class AudioSettingsPanel:SKNode {
    init(size:CGSize) {
        super.init();name="audioSettings"
        for (i,channel) in AudioChannel.allCases.enumerated() {
            let slider=AudioSliderNode(channel:channel,width:max(80,size.width-32))
            slider.position.y=size.height/2-28-CGFloat(i)*size.height/3;addChild(slider)
        }
    }
    required init?(coder:NSCoder){fatalError()}
}
