import SpriteKit

class Enemy: SKShapeNode {
    
    // MARK: - Stats
    
    var health: CGFloat = 30
    var maxHealth: CGFloat = 30
    
    var moveSpeed: CGFloat = 80
    var damage: CGFloat = 10
    
    var scoreValue: Int = 100
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        
        let radius: CGFloat = 18
        
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
        
        // Appearance
        
        fillColor = .red
        strokeColor = .white
        lineWidth = 2
        
        glowWidth = 6
        
        name = "enemy"
        
        zPosition = 4
        
        // Physics
        
        physicsBody = SKPhysicsBody(
            circleOfRadius: radius
        )
        
        physicsBody?.affectedByGravity = false
        physicsBody?.allowsRotation = false
        
        physicsBody?.categoryBitMask = 1 << 1
        
        physicsBody?.collisionBitMask = 0
        
        physicsBody?.contactTestBitMask =
            (1 << 2) | (1 << 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureVisual(archetype: Int) {
        children.filter { $0.name?.hasPrefix("enemyDetail") == true }.forEach { $0.removeFromParent() }
        userData = userData ?? NSMutableDictionary()
        userData?["archetype"] = archetype

        let core = SKShapeNode(circleOfRadius: archetype == 2 ? 6 : 4)
        core.name = "enemyDetailCore"
        core.fillColor = .white
        core.strokeColor = strokeColor
        core.lineWidth = 1
        core.glowWidth = 4
        core.zPosition = 2
        addChild(core)
        core.run(.repeatForever(.sequence([
            .group([.scale(to: 1.3, duration: 0.35), .fadeAlpha(to: 0.55, duration: 0.35)]),
            .group([.scale(to: 0.85, duration: 0.35), .fadeAlpha(to: 1, duration: 0.35)])
        ])))

        switch archetype {
        case 1: // Interceptor: forward chevron and flickering drive fins.
            for y: CGFloat in [-8, 8] {
                let fin = SKShapeNode(rectOf: CGSize(width: 11, height: 2), cornerRadius: 1)
                fin.name = "enemyDetailFin"
                fin.position = CGPoint(x: -16, y: y)
                fin.fillColor = .orange
                fin.strokeColor = .clear
                fin.glowWidth = 4
                addChild(fin)
                fin.run(.repeatForever(.sequence([.fadeAlpha(to: 0.3, duration: 0.1), .fadeAlpha(to: 1, duration: 0.13)])))
            }
        case 2: // Tank: counter-rotating armored diamond.
            let armor = SKShapeNode(rectOf: CGSize(width: 22, height: 22), cornerRadius: 2)
            armor.name = "enemyDetailArmor"
            armor.zRotation = .pi / 4
            armor.fillColor = .clear
            armor.strokeColor = .magenta
            armor.lineWidth = 2
            armor.glowWidth = 3
            armor.zPosition = 1
            addChild(armor)
            armor.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 3.8)))
        case 3: // Gunner: rotating targeting ring and four weapon nodes.
            let ring = SKShapeNode(circleOfRadius: 14)
            ring.name = "enemyDetailTargetingRing"
            ring.fillColor = .clear
            ring.strokeColor = .yellow
            ring.lineWidth = 1.5
            ring.glowWidth = 3
            addChild(ring)
            for angle in stride(from: CGFloat(0), to: .pi * 2, by: .pi / 2) {
                let node = SKShapeNode(rectOf: CGSize(width: 7, height: 3), cornerRadius: 1)
                node.position = CGPoint(x: cos(angle) * 17, y: sin(angle) * 17)
                node.zRotation = angle
                node.fillColor = .yellow
                node.strokeColor = .clear
                ring.addChild(node)
            }
            ring.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 2.7)))
        case 4: // Shard: orbiting satellites communicate erratic movement.
            let orbit = SKNode()
            orbit.name = "enemyDetailOrbit"
            addChild(orbit)
            for angle: CGFloat in [0, .pi * 2 / 3, .pi * 4 / 3] {
                let shard = SKShapeNode(rectOf: CGSize(width: 5, height: 5))
                shard.zRotation = .pi / 4
                shard.position = CGPoint(x: cos(angle) * 17, y: sin(angle) * 17)
                shard.fillColor = strokeColor
                shard.strokeColor = .white
                shard.glowWidth = 2
                orbit.addChild(shard)
            }
            orbit.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 2.1)))
        case 5: // Splitting octagon: blue nested armor makes its behavior readable.
            let path = CGMutablePath()
            for index in 0..<8 {
                let angle = CGFloat(index) * .pi / 4 + .pi / 8
                let point = CGPoint(x: cos(angle) * 12, y: sin(angle) * 12)
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
            let inner = SKShapeNode(path: path)
            inner.name = "enemyDetailOctagon"
            inner.fillColor = SKColor(red: 0.03, green: 0.25, blue: 0.58, alpha: 0.6)
            inner.strokeColor = SKColor(red: 0.35, green: 0.82, blue: 1, alpha: 1)
            inner.lineWidth = 1.5
            inner.glowWidth = 4
            addChild(inner)
            inner.run(.repeatForever(.sequence([
                .rotate(byAngle: .pi / 4, duration: 0.8),
                .wait(forDuration: 0.25)
            ])))
        case 6: // Arrow hive: an anchored cluster that sheds missiles when attacked.
            core.fillColor = NeonColors.orange
            core.strokeColor = .white
            let orbit = SKNode()
            orbit.name = "enemyDetailHiveOrbit"
            addChild(orbit)
            for index in 0..<6 {
                let angle = CGFloat(index) * .pi / 3
                let arrowPath = CGMutablePath()
                arrowPath.move(to: CGPoint(x: 9, y: 0))
                arrowPath.addLine(to: CGPoint(x: -6, y: 6))
                arrowPath.addLine(to: CGPoint(x: -2, y: 0))
                arrowPath.addLine(to: CGPoint(x: -6, y: -6))
                arrowPath.closeSubpath()
                let arrow = SKShapeNode(path: arrowPath)
                arrow.name = "enemyDetailHiveArrow"
                arrow.position = CGPoint(x: cos(angle) * 19, y: sin(angle) * 19)
                arrow.zRotation = angle
                arrow.fillColor = index.isMultiple(of: 2) ? NeonColors.orange : NeonColors.pink
                arrow.strokeColor = .white
                arrow.lineWidth = 1
                arrow.glowWidth = 4
                orbit.addChild(arrow)
            }
            orbit.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 4.2)))
            orbit.run(.repeatForever(.sequence([
                .scale(to: 1.08, duration: 0.55),
                .scale(to: 0.94, duration: 0.55)
            ])), withKey: "hiveBreath")
        default: // Drone: readable concentric pulse.
            let ring = SKShapeNode(circleOfRadius: 12)
            ring.name = "enemyDetailPulseRing"
            ring.fillColor = .clear
            ring.strokeColor = strokeColor.withAlphaComponent(0.9)
            ring.lineWidth = 1.5
            addChild(ring)
            ring.run(.repeatForever(.sequence([
                .group([.scale(to: 1.25, duration: 0.55), .fadeAlpha(to: 0.25, duration: 0.55)]),
                .group([.scale(to: 0.8, duration: 0), .fadeAlpha(to: 1, duration: 0)])
            ])))
        }
    }
}
