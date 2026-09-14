import SpriteKit
import UIKit

class Bullet: SKShapeNode {
    
    var damage: CGFloat
    var bulletSpeed: CGFloat = 800
    var lifetime: TimeInterval = 2.0
    
    init(damage: CGFloat, color: SKColor = .cyan) {
        
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
        
        fillColor = color
        strokeColor = color
        lineWidth = 1
        glowWidth = 1.5

        let streak = SKShapeNode(rectOf: CGSize(width: 30, height: 3), cornerRadius: 1.5)
        streak.position = CGPoint(x: -15, y: 0)
        streak.fillColor = color.withAlphaComponent(0.7)
        streak.strokeColor = .clear
        streak.glowWidth = 0.8
        streak.zPosition = -1
        streak.name = "bulletStreak"
        addChild(streak)

        let core = SKShapeNode(circleOfRadius: 2)
        core.fillColor = .white
        core.strokeColor = .white
        core.glowWidth = 0.5
        addChild(core)

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

    func attachTrail(to world: SKNode) { /* The bounded streak travels with the projectile. */ }
}
