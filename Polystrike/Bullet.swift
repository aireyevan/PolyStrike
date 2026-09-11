import SpriteKit
import UIKit

class Bullet: SKShapeNode {
    
    var damage: CGFloat
    var bulletSpeed: CGFloat = 800
    var lifetime: TimeInterval = 2.0
    
    init(damage: CGFloat) {
        
        self.damage = damage
        
        super.init()
        
        let radius: CGFloat = 4
        
        let path = CGPath(
            ellipseIn: CGRect(
                x: -radius,
                y: -radius,
                width: radius * 2,
                height: radius * 2
            ),
            transform: nil
        )
        
        self.path = path
        
        fillColor = .white
        strokeColor = .cyan
        lineWidth = 1
        glowWidth = 7

        let streak = SKShapeNode(rectOf: CGSize(width: 30, height: 3), cornerRadius: 1.5)
        streak.position = CGPoint(x: -15, y: 0)
        streak.fillColor = SKColor.cyan.withAlphaComponent(0.7)
        streak.strokeColor = .clear
        streak.glowWidth = 5
        streak.zPosition = -1
        streak.name = "bulletStreak"
        addChild(streak)

        let core = SKShapeNode(circleOfRadius: 2)
        core.fillColor = .white
        core.strokeColor = .white
        core.glowWidth = 3
        addChild(core)

        let trail = SKEmitterNode()
        trail.particleTexture = Self.particleTexture
        trail.particleBirthRate = 90
        trail.particleLifetime = 0.18
        trail.particleLifetimeRange = 0.05
        trail.particlePositionRange = CGVector(dx: 2, dy: 2)
        trail.particleSpeed = 12
        trail.emissionAngle = .pi
        trail.emissionAngleRange = 0.3
        trail.particleAlpha = 0.8
        trail.particleAlphaSpeed = -4.2
        trail.particleScale = 0.75
        trail.particleScaleSpeed = -2.8
        trail.particleColor = .cyan
        trail.particleColorBlendFactor = 1
        trail.targetNode = nil
        trail.name = "bulletTrail"
        trail.zPosition = -2
        addChild(trail)
        
        name = "bullet"
        zPosition = 8
        
        physicsBody = SKPhysicsBody(
            circleOfRadius: radius
        )
        
        physicsBody?.affectedByGravity = false
        physicsBody?.allowsRotation = false
        
        physicsBody?.categoryBitMask = 1 << 2
        physicsBody?.collisionBitMask = 0
        physicsBody?.contactTestBitMask = 1 << 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func attachTrail(to world: SKNode) {
        (childNode(withName: "bulletTrail") as? SKEmitterNode)?.targetNode = world
    }

    private static let particleTexture: SKTexture = {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        return SKTexture(image: renderer.image { context in
            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: 4, height: 4))
        })
    }()
}
