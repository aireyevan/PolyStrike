import SpriteKit
import UIKit

// MARK: - Neon Colors

struct NeonColors {

    static let background = SKColor(
        red: 0.005,
        green: 0.008,
        blue: 0.02,
        alpha: 1.0
    )

    static let panel = SKColor(
        red: 0.045,
        green: 0.06,
        blue: 0.085,
        alpha: 1
    )

    static let cyan = SKColor(
        red: 0.0,
        green: 0.9,
        blue: 1.0,
        alpha: 1.0
    )

    static let blue = SKColor(
        red: 0.15,
        green: 0.45,
        blue: 1.0,
        alpha: 1.0
    )

    static let purple = SKColor(
        red: 0.65,
        green: 0.2,
        blue: 1.0,
        alpha: 1.0
    )

    static let pink = SKColor(
        red: 1.0,
        green: 0.15,
        blue: 0.65,
        alpha: 1.0
    )

    static let orange = SKColor(
        red: 1.0,
        green: 0.35,
        blue: 0.05,
        alpha: 1.0
    )

    static let yellow = SKColor(
        red: 1.0,
        green: 0.85,
        blue: 0.05,
        alpha: 1.0
    )

    static let green = SKColor(
        red: 0.1,
        green: 1.0,
        blue: 0.55,
        alpha: 1.0
    )

    static let text = SKColor(
        white: 0.92,
        alpha: 1.0
    )

    static let mutedText = SKColor(
        white: 0.66,
        alpha: 1.0
    )
}

// MARK: - Neon Background

func createNeonBackground(for scene: SKScene, gridSpacing: CGFloat = 45) {
    scene.backgroundColor = SKColor(red: 0.018, green: 0.025, blue: 0.038, alpha: 1)
    for side: CGFloat in [-1,1] {
        let panel = SKShapeNode(path: armorPath(size: CGSize(width: scene.size.width*0.52, height: scene.size.height*1.5), cut: 65))
        panel.fillColor = SKColor(red: 0.04, green: 0.055, blue: 0.075, alpha: 1)
        panel.strokeColor = SKColor(white: 0.3, alpha: 0.18)
        panel.zRotation = side * 0.25
        panel.position = CGPoint(x: scene.size.width*(side < 0 ? 0.02 : 0.98), y:scene.size.height*0.5)
        panel.zPosition = -20; scene.addChild(panel)
    }
    let mesh = CGMutablePath()
    for x in stride(from: CGFloat(0), through: scene.size.width, by: gridSpacing) {
        mesh.move(to: CGPoint(x:x,y:0)); mesh.addLine(to:CGPoint(x:x+scene.size.height,y:scene.size.height))
    }
    let lines = SKShapeNode(path:mesh); lines.strokeColor = SKColor.white.withAlphaComponent(0.025)
    lines.lineWidth = 0.5; lines.zPosition = -19; scene.addChild(lines)
}

func addInterfaceAtmosphere(to scene: SKScene) {
    for side: CGFloat in [-1,1] {
        let seam = SKShapeNode(rectOf:CGSize(width:2,height:scene.size.height*0.54))
        seam.position = CGPoint(x:scene.size.width*(side < 0 ? 0.035 : 0.965),y:scene.size.height*0.5)
        seam.fillColor = (side < 0 ? SKColor.cyan : NeonColors.orange).withAlphaComponent(0.35)
        seam.strokeColor = .clear; seam.zPosition = -10; scene.addChild(seam)
        seam.run(.repeatForever(.sequence([.fadeAlpha(to:0.35,duration:2.5),.fadeAlpha(to:1,duration:2.5)])))
    }
}

// MARK: - Neon Button

class NeonButton: SKNode {

    let background: SKShapeNode
    let titleLabel: SKLabelNode

    let buttonSize: CGSize
    let accentColor: SKColor

    init(
        title: String,
        size: CGSize,
        color: SKColor
    ) {

        self.buttonSize = size
        self.accentColor = color

        background = SKShapeNode(rectOf: size, cornerRadius: 2)

        titleLabel = SKLabelNode(
            fontNamed: "AvenirNext-Bold"
        )

        super.init()

        styleArmor(background, size: size, color: color)
        titleLabel.text = title
        titleLabel.fontSize = min(14, max(9, size.width * 0.085))
        titleLabel.fontColor = NeonColors.text
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position.x = -size.width / 2 + 18
        titleLabel.zPosition = 3
        if titleLabel.frame.width > size.width - 44 { titleLabel.setScale((size.width-44)/titleLabel.frame.width) }
        addChild(background); addChild(titleLabel)
        let arrow = SKShapeNode(path: {
            let p = CGMutablePath(); p.move(to:CGPoint(x:-3,y:4)); p.addLine(to:CGPoint(x:1,y:0)); p.addLine(to:CGPoint(x:-3,y:-4)); return p
        }())
        arrow.position.x = size.width/2-14; arrow.strokeColor = color; arrow.lineWidth = 1.5
        addChild(arrow)

        name = "neonButton"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func press() {

        removeAction(
            forKey: "buttonPress"
        )

        let animation = SKAction.sequence([
            SKAction.scale(
                to: 0.94,
                duration: 0.06
            ),
            SKAction.scale(
                to: 1.0,
                duration: 0.10
            )
        ])

        run(
            animation,
            withKey: "buttonPress"
        )
    }
}

// MARK: - Neon Panel

func createNeonPanel(
    size: CGSize,
    color: SKColor
) -> SKShapeNode {

    let panel = SKShapeNode(rectOf: size, cornerRadius: 2)

    panel.fillColor = NeonColors.panel
    panel.strokeColor = color
    panel.lineWidth = 0.8
    panel.glowWidth = 0

    return panel
}

// MARK: - Neon Label

func createNeonLabel(
    text: String,
    fontSize: CGFloat,
    color: SKColor
) -> SKLabelNode {

    let label = SKLabelNode(
        fontNamed: "AvenirNext-DemiBold"
    )

    label.text = text
    label.fontSize = fontSize
    label.fontColor = color

    label.horizontalAlignmentMode = .center
    label.verticalAlignmentMode = .center

    return label
}

// MARK: - Scene Transition

func transitionToScene(
    from scene: SKScene,
    to nextScene: SKScene
) {

    guard let view = scene.view else {
        print("❌ ERROR: Scene has no SKView")
        return
    }

    nextScene.scaleMode = scene.scaleMode

    let transition = SKTransition.fade(
        withDuration: 0.25
    )

    view.presentScene(
        nextScene,
        transition: transition
    )
}

// Shared cut-metal surfaces used only by menu and overlay UI.
func armorPath(size: CGSize, cut: CGFloat = 10) -> CGPath {
    let w = size.width / 2, h = size.height / 2, c = min(cut, min(w,h) * 0.45)
    let p = CGMutablePath()
    p.move(to: CGPoint(x: -w+c, y: h))
    for point in [CGPoint(x:w,y:h),CGPoint(x:w,y:-h+c),CGPoint(x:w-c,y:-h),
                  CGPoint(x:-w,y:-h),CGPoint(x:-w,y:h-c)] { p.addLine(to: point) }
    p.closeSubpath(); return p
}

func styleArmor(_ node: SKShapeNode, size: CGSize, color: SKColor, selected: Bool = false) {
    node.path = armorPath(size: size)
    node.fillColor = selected ? SKColor(red: 0.075, green: 0.12, blue: 0.16, alpha: 1) : NeonColors.panel
    node.strokeColor = selected ? color : SKColor(red: 0.25, green: 0.31, blue: 0.38, alpha: 0.85)
    node.lineWidth = selected ? 1.5 : 1
    node.glowWidth = 0
    node.childNode(withName: "armorTrim")?.removeFromParent()
    let trim = SKNode(); trim.name = "armorTrim"; node.addChild(trim)
    let seam = SKShapeNode(rectOf: CGSize(width: max(8,size.width-24), height: 1))
    seam.position.y = size.height / 2 - 5
    seam.fillColor = SKColor.white.withAlphaComponent(0.12); seam.strokeColor = .clear
    trim.addChild(seam)
    let strip = SKShapeNode(rectOf: CGSize(width: min(34,size.width*0.17), height: 2))
    strip.position = CGPoint(x: -size.width/2+12+min(34,size.width*0.17)/2, y: size.height/2)
    strip.fillColor = color; strip.strokeColor = .clear; trim.addChild(strip)
    // Decorative children intentionally have no action names; hit testing walks ancestors.
}

func armorPanel(size: CGSize, color: SKColor, selected: Bool = false) -> SKShapeNode {
    let node = SKShapeNode(); styleArmor(node, size: size, color: color, selected: selected); return node
}

func menuBounds(_ scene: SKScene) -> CGRect {
    var safe = scene.view?.safeAreaInsets ?? .zero
    if UIDevice.current.userInterfaceIdiom == .phone && safe.left < 1 && safe.right < 1 {
        safe.left = 59; safe.right = 59; safe.bottom = max(21,safe.bottom)
    }
    return CGRect(x: safe.left+18, y: safe.bottom+14,
                  width: max(1,scene.size.width-safe.left-safe.right-36),
                  height: max(1,scene.size.height-safe.top-safe.bottom-28))
}

func menuActionNames(at point: CGPoint, in node: SKNode) -> [String] {
    node.nodes(at: point).flatMap { hit -> [String] in
        var names: [String] = []; var current: SKNode? = hit
        while let item = current, item !== node { if let name = item.name { names.append(name) }; current = item.parent }
        return names
    }
}

@discardableResult
func menuText(_ text: String, on parent: SKNode, at position: CGPoint, size: CGFloat = 10,
              color: SKColor = .white, align: SKLabelHorizontalAlignmentMode = .left,
              width: CGFloat? = nil) -> SKLabelNode {
    let label = createNeonLabel(text: text, fontSize: size, color: color)
    label.horizontalAlignmentMode = align; label.position = position; label.zPosition = 5
    if let width, label.frame.width > width { label.setScale(max(0.1,width / label.frame.width)) }
    parent.addChild(label); return label
}

func menuHeader(_ title: String, subtitle: String, on scene: SKScene, bounds: CGRect, color: SKColor) {
    menuText(title, on: scene, at: CGPoint(x:bounds.minX,y:bounds.maxY-9),size:24,width:bounds.width-145)
    menuText(subtitle, on: scene, at: CGPoint(x:bounds.minX,y:bounds.maxY-32),size:8,color:color,width:bounds.width-145)
    let rule = SKShapeNode(rectOf: CGSize(width:bounds.width,height:1))
    rule.position = CGPoint(x:bounds.midX,y:bounds.maxY-48)
    rule.fillColor = SKColor.white.withAlphaComponent(0.15); rule.strokeColor = .clear; scene.addChild(rule)
}
