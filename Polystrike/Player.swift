import SpriteKit

class Player: SKShapeNode {
    var health: CGFloat = 100
    var maxHealth: CGFloat = 100
    var moveSpeed: CGFloat = 300
    var damage: CGFloat = 10
    var fireRate: TimeInterval = 0.20
    var projectileSpeed: CGFloat = 800
    var lastShotTime: TimeInterval = 0
    let shipStyle: ShipStyle

    override init() {
        shipStyle = PlayerProgress.shared.selectedShip
        super.init()
        build(style: shipStyle)
    }

    init(style: ShipStyle) {
        shipStyle = style
        super.init()
        build(style: style)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build(style: ShipStyle) {
        let palette = colors(for: style)
        let hull = hullPath(for: style)
        path = hull
        fillColor = palette.main
        strokeColor = .white
        lineWidth = style == .sovereign ? 3 : 2
        glowWidth = style == .striker ? 8 : 10

        let innerHull = SKShapeNode(path: hull)
        innerHull.setScale(style == .sovereign ? 0.58 : 0.55)
        innerHull.fillColor = palette.dark
        innerHull.strokeColor = palette.accent.withAlphaComponent(0.9)
        innerHull.lineWidth = 1.2
        innerHull.glowWidth = 3
        innerHull.name = "playerInnerHull"
        addChild(innerHull)

        let core = SKShapeNode(circleOfRadius: style == .sovereign ? 5.5 : 4.5)
        core.position = CGPoint(x: style == .spectre ? 0 : 3, y: 0)
        core.fillColor = .white
        core.strokeColor = palette.accent
        core.glowWidth = style == .eclipse || style == .sovereign ? 8 : 5
        core.name = "playerCore"
        innerHull.addChild(core)
        core.run(.repeatForever(.sequence([
            .group([.scale(to: 1.28, duration: 0.42), .fadeAlpha(to: 0.58, duration: 0.42)]),
            .group([.scale(to: 0.88, duration: 0.42), .fadeAlpha(to: 1, duration: 0.42)])
        ])))

        addWingDetails(style: style, color: palette.accent)
        addEngine(color: palette.engine, premium: [.nova, .eclipse, .sovereign].contains(style))
        addSignatureAnimation(style: style, color: palette.accent)
        name = "player"
        zPosition = 10
        physicsBody = SKPhysicsBody(polygonFrom: hull)
        physicsBody?.affectedByGravity = false
        physicsBody?.allowsRotation = false
        physicsBody?.categoryBitMask = 1 << 0
        physicsBody?.collisionBitMask = 0
        physicsBody?.contactTestBitMask = 1 << 1
    }

    private func hullPath(for style: ShipStyle) -> CGPath {
        let points: [CGPoint]
        switch style {
        case .striker: points = [.init(x: 18, y: 0), .init(x: -13, y: 14), .init(x: -13, y: -14)]
        case .viper: points = [.init(x: 23, y: 0), .init(x: 4, y: 7), .init(x: -17, y: 17), .init(x: -10, y: 0), .init(x: -17, y: -17), .init(x: 4, y: -7)]
        case .spectre: points = [.init(x: 22, y: 0), .init(x: 2, y: 10), .init(x: -13, y: 16), .init(x: -7, y: 4), .init(x: -19, y: 0), .init(x: -7, y: -4), .init(x: -13, y: -16), .init(x: 2, y: -10)]
        case .nova: points = [.init(x: 25, y: 0), .init(x: 2, y: 8), .init(x: -8, y: 19), .init(x: -13, y: 7), .init(x: -19, y: 0), .init(x: -13, y: -7), .init(x: -8, y: -19), .init(x: 2, y: -8)]
        case .eclipse: points = [.init(x: 24, y: 0), .init(x: 8, y: 8), .init(x: -8, y: 20), .init(x: -5, y: 7), .init(x: -21, y: 11), .init(x: -13, y: 0), .init(x: -21, y: -11), .init(x: -5, y: -7), .init(x: -8, y: -20), .init(x: 8, y: -8)]
        case .sovereign: points = [.init(x: 27, y: 0), .init(x: 9, y: 7), .init(x: 2, y: 17), .init(x: -8, y: 12), .init(x: -18, y: 20), .init(x: -14, y: 5), .init(x: -23, y: 0), .init(x: -14, y: -5), .init(x: -18, y: -20), .init(x: -8, y: -12), .init(x: 2, y: -17), .init(x: 9, y: -7)]
        }
        let result = CGMutablePath()
        if let first = points.first { result.move(to: first) }
        points.dropFirst().forEach { result.addLine(to: $0) }
        result.closeSubpath()
        return result
    }

    private func colors(for style: ShipStyle) -> (main: SKColor, dark: SKColor, accent: SKColor, engine: SKColor) {
        switch style {
        case .striker: return (.cyan, .init(red: 0.02, green: 0.16, blue: 0.24, alpha: 0.95), .cyan, NeonColors.blue)
        case .viper: return (NeonColors.green, .init(red: 0.01, green: 0.18, blue: 0.12, alpha: 1), NeonColors.green, .cyan)
        case .spectre: return (NeonColors.purple, .init(red: 0.1, green: 0.02, blue: 0.22, alpha: 1), NeonColors.purple, NeonColors.pink)
        case .nova: return (NeonColors.orange, .init(red: 0.26, green: 0.04, blue: 0.01, alpha: 1), NeonColors.yellow, NeonColors.orange)
        case .eclipse: return (NeonColors.pink, .init(red: 0.16, green: 0.01, blue: 0.1, alpha: 1), NeonColors.pink, NeonColors.purple)
        case .sovereign: return (.white, .init(red: 0.07, green: 0.04, blue: 0.18, alpha: 1), NeonColors.cyan, NeonColors.purple)
        }
    }

    private func addWingDetails(style: ShipStyle, color: SKColor) {
        let offset: CGFloat = style == .striker ? 9 : 12
        for y in [-offset, offset] {
            let wing = SKShapeNode(rectOf: CGSize(width: style == .sovereign ? 17 : 13, height: style == .eclipse ? 3 : 2), cornerRadius: 1)
            wing.position = CGPoint(x: -7, y: y)
            wing.zRotation = y > 0 ? -0.28 : 0.28
            wing.fillColor = .white
            wing.strokeColor = color
            wing.glowWidth = 3
            addChild(wing)
        }
    }

    private func addEngine(color: SKColor, premium: Bool) {
        let engine = SKShapeNode(rectOf: CGSize(width: premium ? 18 : 13, height: premium ? 6 : 5), cornerRadius: 2.5)
        engine.position = CGPoint(x: -21, y: 0)
        engine.fillColor = .white
        engine.strokeColor = color
        engine.glowWidth = premium ? 10 : 7
        engine.name = "playerEngine"
        addChild(engine)
        engine.run(.repeatForever(.sequence([
            .group([.scaleX(to: premium ? 2 : 1.65, duration: 0.08), .fadeAlpha(to: 0.48, duration: 0.08)]),
            .group([.scaleX(to: 0.72, duration: 0.12), .fadeAlpha(to: 1, duration: 0.12)])
        ])))
    }

    private func addSignatureAnimation(style: ShipStyle, color: SKColor) {
        guard style != .striker else { return }
        let radius: CGFloat = style == .sovereign ? 25 : 21
        let ring = SKShapeNode(circleOfRadius: radius)
        ring.fillColor = .clear
        ring.strokeColor = color.withAlphaComponent(style == .eclipse ? 0.65 : 0.38)
        ring.lineWidth = style == .sovereign ? 1.6 : 1
        ring.glowWidth = style == .sovereign ? 6 : 3
        ring.zPosition = -2
        addChild(ring)
        ring.run(.repeatForever(.rotate(byAngle: style == .eclipse ? -.pi * 2 : .pi * 2, duration: style == .sovereign ? 1.8 : 3.2)))
        let counts: [ShipStyle: Int] = [.viper: 1, .spectre: 2, .nova: 2, .eclipse: 3, .sovereign: 4]
        let count = counts[style, default: 0]
        for index in 0..<count {
            let orb = SKShapeNode(circleOfRadius: style == .sovereign ? 2.6 : 2)
            let angle = CGFloat(index) * .pi * 2 / CGFloat(count)
            orb.position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            orb.fillColor = .white
            orb.strokeColor = color
            orb.glowWidth = 6
            ring.addChild(orb)
        }
        if style == .spectre {
            run(.repeatForever(.sequence([.fadeAlpha(to: 0.72, duration: 0.65), .fadeAlpha(to: 1, duration: 0.65)])), withKey: "signature")
        } else if style == .nova || style == .sovereign {
            ring.run(.repeatForever(.sequence([.scale(to: 1.12, duration: 0.55), .scale(to: 0.92, duration: 0.55)])), withKey: "pulse")
        }
    }
}
