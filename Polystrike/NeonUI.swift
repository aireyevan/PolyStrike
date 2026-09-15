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
            fontNamed: "Menlo-Bold"
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
    if selected {
        let marker=SKShapeNode(rectOf:CGSize(width:2,height:max(8,size.height-18)))
        marker.position.x = -size.width/2+1
        marker.fillColor=color;marker.strokeColor = .clear;trim.addChild(marker)
    }
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
    if size>=12 {label.fontName="Menlo-Bold"}
    label.horizontalAlignmentMode = align; label.position = position; label.zPosition = 5
    if let width, label.frame.width > width { label.setScale(max(0.1,width / label.frame.width)) }
    parent.addChild(label); return label
}

func menuHeader(_ title: String, subtitle: String, on scene: SKScene, bounds: CGRect, color: SKColor) {
    let heading=AngularTitleNode(title == "POLYSTRIKE" ? "PolyStrike" : title,height:25,color:color)
    heading.name="menuHeading";heading.position=CGPoint(x:bounds.minX,y:bounds.maxY-22)
    if heading.calculateAccumulatedFrame().width>bounds.width-190 {heading.setScale((bounds.width-190)/heading.calculateAccumulatedFrame().width)}
    scene.addChild(heading)
    menuText(subtitle, on: scene, at: CGPoint(x:bounds.minX,y:bounds.maxY-32),size:8,color:color,width:bounds.width-145)
    let rule = SKShapeNode(rectOf: CGSize(width:bounds.width,height:1))
    rule.position = CGPoint(x:bounds.midX,y:bounds.maxY-48)
    rule.fillColor = SKColor.white.withAlphaComponent(0.15); rule.strokeColor = .clear; scene.addChild(rule)
}

/// A restrained progress track: color communicates progress rather than decorating every card.
func menuProgressBar(width:CGFloat,ratio:CGFloat,color:SKColor,height:CGFloat=4)->SKNode {
    let node=SKNode()
    let track=SKShapeNode(rect:CGRect(x:0,y:0,width:width,height:height),cornerRadius:height/2)
    track.fillColor=SKColor(white:0.25,alpha:0.6);track.strokeColor = .clear;node.addChild(track)
    let amount=max(0,min(1,ratio))
    if amount>0 {
        let fill=SKShapeNode(rect:CGRect(x:0,y:0,width:width*amount,height:height),cornerRadius:min(height/2,width*amount/2))
        fill.name="progressFill";fill.fillColor=color;fill.strokeColor = .clear;node.addChild(fill)
    }
    return node
}

/// Original angular lettering, built from cut-corner strokes and a subtle beveled edge.
final class AngularTitleNode:SKNode {
    private static let glyphs:[Character:[[(CGFloat,CGFloat)]]] = [
        "A":[[(0,0),(0,5),(2,7),(4,5),(4,0)],[(0,3),(4,3)]],
        "B":[[(0,0),(0,7),(3,7),(4,6),(4,5),(3,4),(0,4)],[(3,4),(4,3),(4,1),(3,0),(0,0)]],
        "C":[[(4,7),(1,7),(0,6),(0,1),(1,0),(4,0)]],
        "D":[[(0,0),(0,7),(2,7),(4,5),(4,2),(2,0),(0,0)]],
        "E":[[(4,7),(0,7),(0,0),(4,0)],[(0,4),(3,4)]],
        "F":[[(0,0),(0,7),(4,7)],[(0,4),(3,4)]],
        "G":[[(4,7),(1,7),(0,6),(0,1),(1,0),(4,0),(4,3),(2,3)]],
        "H":[[(0,7),(0,0)],[(4,7),(4,0)],[(0,3),(4,3)]],
        "I":[[(0,7),(4,7)],[(2,7),(2,0)],[(0,0),(4,0)]],
        "J":[[(0,7),(4,7),(4,1),(3,0),(1,0),(0,1)]],
        "K":[[(0,7),(0,0)],[(4,7),(0,3),(4,0)]],
        "L":[[(0,7),(0,0),(4,0)]],
        "M":[[(0,0),(0,7),(2,4),(4,7),(4,0)]],
        "N":[[(0,0),(0,7),(4,0),(4,7)]],
        "O":[[(1,7),(3,7),(4,6),(4,1),(3,0),(1,0),(0,1),(0,6),(1,7)]],
        "P":[[(0,0),(0,7),(3,7),(4,6),(4,4),(3,3),(0,3)]],
        "Q":[[(1,7),(3,7),(4,6),(4,1),(3,0),(1,0),(0,1),(0,6),(1,7)],[(2,2),(4,-1)]],
        "R":[[(0,0),(0,7),(3,7),(4,6),(4,4),(3,3),(0,3)],[(2,3),(4,0)]],
        "S":[[(4,7),(1,7),(0,6),(0,4),(4,3),(4,1),(3,0),(0,0)]],
        "T":[[(0,7),(4,7)],[(2,7),(2,0)]],
        "U":[[(0,7),(0,1),(1,0),(3,0),(4,1),(4,7)]],
        "V":[[(0,7),(0,3),(2,0),(4,3),(4,7)]],
        "W":[[(0,7),(0,0),(2,3),(4,0),(4,7)]],
        "X":[[(0,7),(4,0)],[(4,7),(0,0)]],
        "Y":[[(0,7),(2,4),(4,7)],[(2,4),(2,0)]],
        "Z":[[(0,7),(4,7),(0,0),(4,0)]]
    ]
    init(_ text:String,height:CGFloat,color:SKColor) {
        super.init();isAccessibilityElement=true;accessibilityLabel=text
        let unit=height/7,path=CGMutablePath()
        for (index,character) in text.uppercased().enumerated() {
            for stroke in Self.glyphs[character] ?? [] {
                for (i,p) in stroke.enumerated() {
                    let point=CGPoint(x:(CGFloat(index)*6+p.0+p.1*0.16)*unit,y:p.1*unit)
                    if i==0 {path.move(to:point)} else {path.addLine(to:point)}
                }
            }
        }
        for (width,tint,offset) in [(CGFloat(1.15),SKColor.black,CGFloat(-1.5)),(CGFloat(0.78),color,CGFloat(0)),(CGFloat(0.22),SKColor.white.withAlphaComponent(0.85),CGFloat(0.6))] {
            let layer=SKShapeNode(path:path);layer.strokeColor=tint;layer.lineWidth=unit*width
            layer.lineJoin = .bevel;layer.lineCap = .square;layer.position.y=offset;addChild(layer)
        }
    }
    required init?(coder:NSCoder) {fatalError("init(coder:) has not been implemented")}
}
