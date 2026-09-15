import SpriteKit
import UIKit

// Shared raster art keeps facets and glow to one draw node per projectile/pickup.
enum CombatPickupArt {
    private static func texture(_ size:CGSize,draw:(CGContext)->Void)->SKTexture {
        let format=UIGraphicsImageRendererFormat();format.scale=2
        let image=UIGraphicsImageRenderer(size:size,format:format).image {draw($0.cgContext)}
        let texture=SKTexture(image:image);texture.filteringMode = .linear;return texture
    }
    private static func polygon(_ c:CGContext,_ points:[CGPoint],_ color:UIColor) {
        c.beginPath();c.addLines(between:points);c.closePath();c.setFillColor(color.cgColor);c.fillPath()
    }
    static let gem:SKTexture = texture(CGSize(width:40,height:48)) { c in
        let top=CGPoint(x:20,y:7),left=CGPoint(x:8,y:18),right=CGPoint(x:32,y:18),tip=CGPoint(x:20,y:40)
        let a=CGPoint(x:15,y:18),b=CGPoint(x:25,y:18)
        c.setShadow(offset:.zero,blur:5,color:UIColor.systemGreen.withAlphaComponent(0.65).cgColor)
        polygon(c,[top,right,tip,left],UIColor(red:0.04,green:0.65,blue:0.42,alpha:1))
        c.setShadow(offset:.zero,blur:0,color:nil)
        polygon(c,[top,left,a],UIColor(red:0.46,green:1,blue:0.76,alpha:1))
        polygon(c,[top,a,b],UIColor(red:0.85,green:1,blue:0.94,alpha:1))
        polygon(c,[top,b,right],UIColor(red:0.08,green:0.8,blue:0.58,alpha:1))
        polygon(c,[left,a,tip],UIColor(red:0.02,green:0.42,blue:0.3,alpha:1))
        polygon(c,[a,b,tip],UIColor(red:0.16,green:0.95,blue:0.62,alpha:1))
        polygon(c,[b,right,tip],UIColor(red:0.02,green:0.57,blue:0.44,alpha:1))
        c.setStrokeColor(UIColor(red:0.63,green:1,blue:0.83,alpha:1).cgColor);c.setLineWidth(0.8)
        c.beginPath();c.addLines(between:[top,left,tip,right,top]);c.move(to:left);c.addLine(to:right);c.move(to:top);c.addLine(to:a);c.addLine(to:tip);c.move(to:top);c.addLine(to:b);c.addLine(to:tip);c.strokePath()
    }
    static let lance:SKTexture = texture(CGSize(width:64,height:22)) { c in
        c.setShadow(offset:.zero,blur:4,color:UIColor.white.withAlphaComponent(0.7).cgColor)
        polygon(c,[CGPoint(x:3,y:11),CGPoint(x:42,y:6),CGPoint(x:58,y:11),CGPoint(x:42,y:16)],UIColor.white.withAlphaComponent(0.35))
        c.setShadow(offset:.zero,blur:0,color:nil)
        polygon(c,[CGPoint(x:14,y:11),CGPoint(x:44,y:8),CGPoint(x:56,y:11),CGPoint(x:44,y:14)],.white)
        polygon(c,[CGPoint(x:28,y:4),CGPoint(x:41,y:6),CGPoint(x:34,y:7)],UIColor.white.withAlphaComponent(0.7))
        polygon(c,[CGPoint(x:28,y:18),CGPoint(x:41,y:16),CGPoint(x:34,y:15)],UIColor.white.withAlphaComponent(0.7))
    }
    static let flare:SKTexture = texture(CGSize(width:64,height:40)) { c in
        c.setShadow(offset:.zero,blur:4,color:UIColor.white.withAlphaComponent(0.7).cgColor)
        polygon(c,[CGPoint(x:5,y:20),CGPoint(x:22,y:16),CGPoint(x:51,y:20),CGPoint(x:22,y:24)],.white)
        polygon(c,[CGPoint(x:15,y:20),CGPoint(x:26,y:6),CGPoint(x:24,y:18),CGPoint(x:38,y:11),CGPoint(x:28,y:20),CGPoint(x:38,y:29),CGPoint(x:24,y:22),CGPoint(x:26,y:34)],UIColor.white.withAlphaComponent(0.8))
    }
    static let glint:SKTexture = texture(CGSize(width:18,height:18)) { c in
        polygon(c,[CGPoint(x:9,y:0),CGPoint(x:11,y:7),CGPoint(x:18,y:9),CGPoint(x:11,y:11),CGPoint(x:9,y:18),CGPoint(x:7,y:11),CGPoint(x:0,y:9),CGPoint(x:7,y:7)],.white)
    }
}

class Bullet: SKShapeNode {
    var damage:CGFloat
    var bulletSpeed:CGFloat=800
    var lifetime:TimeInterval=2
    init(damage:CGFloat,color:SKColor = .cyan) {
        self.damage=damage;super.init()
        let bolt=SKSpriteNode(texture:CombatPickupArt.lance)
        bolt.name="bulletStreak";bolt.size=CGSize(width:48,height:16.5)
        // The luminous tip stays aligned with the original four-point collision radius.
        bolt.position.x = -16.5;bolt.color=color;bolt.colorBlendFactor=0.65;bolt.blendMode = .add
        addChild(bolt)
        bolt.xScale=0.65
        bolt.run(.scaleX(to:1,duration:0.045))
        name="bullet";zPosition=8
        physicsBody=SKPhysicsBody(circleOfRadius:4)
        physicsBody?.affectedByGravity=false;physicsBody?.allowsRotation=false
        physicsBody?.categoryBitMask=1 << 2;physicsBody?.collisionBitMask=0;physicsBody?.contactTestBitMask=1 << 1
    }
    required init?(coder:NSCoder) {fatalError("init(coder:) has not been implemented")}
    func attachTrail(to world:SKNode) { /* The reusable lance texture travels with the projectile. */ }
}
