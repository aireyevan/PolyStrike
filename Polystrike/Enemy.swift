import SpriteKit
import UIKit

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

        let accent = strokeColor == .white ? fillColor : strokeColor
        if let hull = path {
            CombatSurface.add(to:self,path:hull,color:accent,variant:archetype,name:"enemyDetailSurface")
        }
        fillColor = SKColor(red:0.035,green:0.05,blue:0.075,alpha:1)
        lineWidth = 1.4
        glowWidth = 1.2
        let core = SKShapeNode(circleOfRadius: archetype == 2 ? 6 : 4)
        core.name = "enemyDetailCore"
        core.fillColor = accent
        core.strokeColor = strokeColor
        core.lineWidth = 1
        core.glowWidth = 1.5
        core.zPosition = 2
        addChild(core)
        core.run(.repeatForever(.sequence([
            .group([.scale(to: 1.13, duration: 0.55), .fadeAlpha(to: 0.55, duration: 0.35)]),
            .group([.scale(to: 0.92, duration: 0.55), .fadeAlpha(to: 1, duration: 0.35)])
        ])))

        switch archetype {
        case 1: // Interceptor: forward chevron and flickering drive fins.
            for y: CGFloat in [-8, 8] {
                let fin = SKShapeNode(rectOf: CGSize(width: 11, height: 2), cornerRadius: 1)
                fin.name = "enemyDetailFin"
                fin.position = CGPoint(x: -16, y: y)
                fin.fillColor = .orange
                fin.strokeColor = .clear
                fin.glowWidth = 1
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
            armor.glowWidth = 0.8
            armor.zPosition = 1
            addChild(armor)
            armor.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 3.8)))
        case 3: // Gunner: rotating targeting ring and four weapon nodes.
            let ring = SKShapeNode(circleOfRadius: 14)
            ring.name = "enemyDetailTargetingRing"
            ring.fillColor = .clear
            ring.strokeColor = .yellow
            ring.lineWidth = 1.5
            ring.glowWidth = 0.8
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
                shard.glowWidth = 0.6
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
            inner.glowWidth = 1
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
                arrow.glowWidth = 1
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
        for detail in children where detail.name?.hasPrefix("enemyDetail") == true && detail.name != "enemyDetailSurface" {
            detail.zPosition = max(1, detail.zPosition)
        }
    }
}

/// Cache static faceted armor once per hull/palette instead of redrawing many glowing paths.
enum CombatSurface {
    private static var cache: [String: SKTexture] = [:]
    static func add(to node: SKShapeNode, path: CGPath, color: SKColor, variant: Int, name: String) {
        let bounds = path.boundingBoxOfPath.insetBy(dx:-3,dy:-3)
        var key = "\(variant)/\(color.description)/"
        path.applyWithBlock { pointer in
            let element = pointer.pointee
            key += "\(element.type.rawValue):"
            let count: Int
            switch element.type { case .moveToPoint,.addLineToPoint: count=1;case .addQuadCurveToPoint:count=2;case .addCurveToPoint:count=3;case .closeSubpath:count=0;@unknown default:count=0 }
            for index in 0..<count { key += "\(element.points[index].x),\(element.points[index].y);" }
        }
        let texture: SKTexture
        if let stored = cache[key] { texture=stored } else {
            let format=UIGraphicsImageRendererFormat();format.scale=2
            let renderer=UIGraphicsImageRenderer(size:bounds.size,format:format)
            let image=renderer.image { context in
                let c=context.cgContext
                c.translateBy(x:-bounds.minX,y:bounds.maxY);c.scaleBy(x:1,y:-1)
                c.addPath(path);c.clip()
                SKColor(red:0.075,green:0.10,blue:0.15,alpha:1).setFill();c.fill(bounds)
                let mid=CGPoint(x:bounds.midX,y:bounds.midY)
                let corners=[CGPoint(x:bounds.minX,y:bounds.minY),CGPoint(x:bounds.maxX,y:bounds.minY),CGPoint(x:bounds.maxX,y:bounds.maxY),CGPoint(x:bounds.minX,y:bounds.maxY)]
                for i in 0..<4 {
                    c.beginPath();c.move(to:mid);c.addLine(to:corners[i]);c.addLine(to:corners[(i+1)%4]);c.closePath()
                    (i==2 ? SKColor(white:0.52,alpha:0.75) : color.withAlphaComponent(i==0 ? 0.12 : 0.30)).setFill();c.fillPath()
                }
                c.saveGState();c.translateBy(x:mid.x,y:mid.y);c.scaleBy(x:0.70,y:0.70);c.translateBy(x:-mid.x,y:-mid.y)
                c.addPath(path);c.setFillColor(SKColor(red:0.025,green:0.045,blue:0.08,alpha:1).cgColor)
                c.setStrokeColor(color.withAlphaComponent(0.8).cgColor);c.setLineWidth(1);c.drawPath(using:.fillStroke);c.restoreGState()
                c.setStrokeColor(SKColor.white.withAlphaComponent(0.25).cgColor);c.setLineWidth(0.7)
                for side: CGFloat in [-1,1] {
                    c.move(to:CGPoint(x:bounds.minX+6,y:mid.y+side*4))
                    c.addLine(to:CGPoint(x:mid.x,y:mid.y+side*7))
                    c.addLine(to:CGPoint(x:bounds.maxX-6,y:mid.y+side*2));c.strokePath()
                }
            }
            texture=SKTexture(image:image);texture.filteringMode = .linear
            if cache.count < 128 { cache[key]=texture }
        }
        let sprite=SKSpriteNode(texture:texture,size:bounds.size)
        sprite.position=CGPoint(x:bounds.midX,y:bounds.midY);sprite.name=name;sprite.zPosition=0.5
        node.addChild(sprite)
    }
}

/// Short-lived, bounded effects; these nodes never participate in gameplay physics.
enum CombatEffects {
    static func dash(from start: CGPoint, to end: CGPoint, hull: CGPath, angle: CGFloat, color: SKColor) -> SKNode {
        let root=SKNode();root.name="dashVisual";root.zPosition=9
        let distance=hypot(end.x-start.x,end.y-start.y)
        guard distance>1 else {root.run(.removeFromParent());return root}
        for index in 0..<6 {
            let t=CGFloat(index)/6
            let ghost=SKShapeNode(path:hull);ghost.position=CGPoint(x:start.x+(end.x-start.x)*t,y:start.y+(end.y-start.y)*t)
            ghost.zRotation=angle;ghost.fillColor=color.withAlphaComponent(0.08);ghost.strokeColor=color
            ghost.lineWidth=1;ghost.glowWidth=1;ghost.alpha=0.15+t*0.5
            root.addChild(ghost)
            ghost.run(.group([.fadeOut(withDuration:0.22+Double(t)*0.14),.scale(to:0.84,duration:0.35)]))
        }
        let lines=CGMutablePath()
        let dx=(end.x-start.x)/distance,dy=(end.y-start.y)/distance
        for side: CGFloat in [-1,1] {
            lines.move(to:CGPoint(x:start.x-dy*side*12,y:start.y+dx*side*12))
            lines.addLine(to:CGPoint(x:end.x-dy*side*5,y:end.y+dx*side*5))
        }
        let wake=SKShapeNode(path:lines);wake.strokeColor=color;wake.lineWidth=2;wake.glowWidth=1.5;root.addChild(wake)
        wake.run(.fadeOut(withDuration:0.24))
        root.run(.sequence([.wait(forDuration:0.4),.removeFromParent()]));return root
    }
    static func shockwave(radius: CGFloat, color: SKColor) -> SKNode {
        let root=SKNode();root.name="shockwaveVisual";root.zPosition=20
        for index in 0..<3 {
            let ring=SKShapeNode(circleOfRadius:radius)
            ring.fillColor=index==0 ? color.withAlphaComponent(0.025) : .clear
            ring.strokeColor=index==0 ? .white : color
            ring.lineWidth=index==0 ? 2 : 3;ring.glowWidth=1.5;ring.setScale(0.06)
            root.addChild(ring)
            let expand=SKAction.scale(to:index==2 ? 0.92 : 1,duration:0.34);expand.timingMode = .easeOut
            ring.run(.sequence([.wait(forDuration:Double(index)*0.045),.group([expand,.fadeOut(withDuration:0.36)])]))
        }
        let spokes=CGMutablePath()
        for i in 0..<16 {
            let angle=CGFloat(i) * .pi/8
            spokes.move(to:CGPoint(x:cos(angle)*radius*0.72,y:sin(angle)*radius*0.72))
            spokes.addLine(to:CGPoint(x:cos(angle)*radius*0.96,y:sin(angle)*radius*0.96))
        }
        let debris=SKShapeNode(path:spokes);debris.strokeColor=color;debris.lineWidth=2;debris.setScale(0.1);root.addChild(debris)
        debris.run(.group([.scale(to:1,duration:0.4),.fadeOut(withDuration:0.4)]))
        root.run(.sequence([.wait(forDuration:0.55),.removeFromParent()]));return root
    }
}
