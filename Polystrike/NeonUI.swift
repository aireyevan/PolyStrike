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
        red: 0.02,
        green: 0.035,
        blue: 0.07,
        alpha: 0.94
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
        white: 0.55,
        alpha: 1.0
    )
}

// MARK: - Neon Background

func createNeonBackground(
    for scene: SKScene,
    gridSpacing: CGFloat = 45
) {
    scene.backgroundColor = NeonColors.background

    // Grid

    var x: CGFloat = 0

    while x <= scene.size.width {

        let path = CGMutablePath()

        path.move(
            to: CGPoint(
                x: x,
                y: 0
            )
        )

        path.addLine(
            to: CGPoint(
                x: x,
                y: scene.size.height
            )
        )

        let line = SKShapeNode()
        line.path = path
        line.strokeColor = SKColor(white: 0.34, alpha: 0.055)
        line.lineWidth = 0.55
        line.zPosition = -20

        scene.addChild(line)

        x += gridSpacing
    }

    var y: CGFloat = 0

    while y <= scene.size.height {

        let path = CGMutablePath()

        path.move(
            to: CGPoint(
                x: 0,
                y: y
            )
        )

        path.addLine(
            to: CGPoint(
                x: scene.size.width,
                y: y
            )
        )

        let line = SKShapeNode()
        line.path = path
        line.strokeColor = SKColor(white: 0.34, alpha: 0.055)
        line.lineWidth = 0.55
        line.zPosition = -20

        scene.addChild(line)

        y += gridSpacing
    }

    // Center glow

    let glow = SKShapeNode(
        circleOfRadius: scene.size.width * 0.35
    )

    glow.fillColor = SKColor(
        red: 0,
        green: 0.4,
        blue: 0.6,
        alpha: 0.025
    )

    glow.strokeColor = .clear

    glow.position = CGPoint(
        x: scene.size.width / 2,
        y: scene.size.height / 2
    )

    glow.zPosition = -19

    scene.addChild(glow)

    // Sparse triangular circuitry breaks up the grid without turning menus
    // into a second gameplay scene.
    let facets = CGMutablePath()
    let step = gridSpacing * 2
    for x in stride(from: -step, through: scene.size.width + step, by: step) {
        let offset = Int(x / step).isMultiple(of: 2) ? CGFloat(0) : gridSpacing
        for y in stride(from: offset, through: scene.size.height, by: step) {
            facets.move(to: CGPoint(x: x, y: y))
            facets.addLine(to: CGPoint(x: x + gridSpacing, y: y + gridSpacing))
            facets.addLine(to: CGPoint(x: x + step, y: y))
        }
    }
    let facetLines = SKShapeNode(path: facets)
    facetLines.strokeColor = NeonColors.purple.withAlphaComponent(0.055)
    facetLines.lineWidth = 0.5
    facetLines.zPosition = -18
    scene.addChild(facetLines)

    let pulse = SKAction.sequence([
        SKAction.fadeAlpha(
            to: 0.3,
            duration: 2
        ),
        SKAction.fadeAlpha(
            to: 0.7,
            duration: 2
        )
    ])

    glow.run(
        SKAction.repeatForever(pulse)
    )
}

/// Shared command-deck motion used by menus. It adds life without competing
/// with labels or controls and keeps all animation behind interactive content.
func addInterfaceAtmosphere(to scene: SKScene) {
    let scanner = SKShapeNode(rectOf: CGSize(width: scene.size.width * 0.82, height: 1))
    scanner.position = CGPoint(x: scene.size.width / 2, y: 22)
    scanner.fillColor = SKColor.cyan.withAlphaComponent(0.18)
    scanner.strokeColor = .clear
    scanner.glowWidth = 5
    scanner.zPosition = -9
    scene.addChild(scanner)
    scanner.run(.repeatForever(.sequence([
        .group([.moveTo(y: scene.size.height - 22, duration: 5.5), .fadeAlpha(to: 0.04, duration: 5.5)]),
        .group([.moveTo(y: 22, duration: 0), .fadeAlpha(to: 0.2, duration: 0)]),
        .wait(forDuration: 1.2)
    ])))

    for index in 0..<12 {
        let mote = SKShapeNode(circleOfRadius: index.isMultiple(of: 3) ? 1.4 : 0.7)
        mote.position = CGPoint(
            x: CGFloat((index * 113 + 29) % max(1, Int(scene.size.width))),
            y: CGFloat((index * 71 + 43) % max(1, Int(scene.size.height)))
        )
        mote.fillColor = index.isMultiple(of: 2) ? .cyan : NeonColors.purple
        mote.strokeColor = .clear
        mote.alpha = 0.16
        mote.zPosition = -7
        scene.addChild(mote)
        mote.run(.repeatForever(.sequence([
            .group([.moveBy(x: 8, y: 13, duration: 2.4 + Double(index % 4)), .fadeAlpha(to: 0.48, duration: 2.4)]),
            .group([.moveBy(x: -8, y: -13, duration: 2.4 + Double(index % 4)), .fadeAlpha(to: 0.12, duration: 2.4)])
        ])))
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

        background.fillColor = SKColor(red: 0.008, green: 0.014, blue: 0.028, alpha: 0.96)
        background.strokeColor = color.withAlphaComponent(0.68)
        background.lineWidth = 0.9
        background.glowWidth = 1

        titleLabel.text = title
        titleLabel.fontSize = 20
        titleLabel.fontColor = NeonColors.text

        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position.x = -size.width / 2 + 30

        background.zPosition = 0
        titleLabel.zPosition = 1

        addChild(background)
        addChild(titleLabel)

        let selector = SKShapeNode(rectOf: CGSize(width: 7, height: 7), cornerRadius: 0.5)
        selector.zRotation = .pi / 4
        selector.position.x = -size.width / 2 + 15
        selector.fillColor = color
        selector.strokeColor = .white
        selector.lineWidth = 0.5
        selector.glowWidth = 3
        selector.zPosition = 2
        addChild(selector)

        let terminal = SKShapeNode(rectOf: CGSize(width: 22, height: 1))
        terminal.position.x = size.width / 2 - 18
        terminal.fillColor = color.withAlphaComponent(0.65)
        terminal.strokeColor = .clear
        terminal.zPosition = 2
        addChild(terminal)

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
