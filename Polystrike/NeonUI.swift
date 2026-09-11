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
        line.strokeColor = SKColor(
            white: 0.2,
            alpha: 0.08
        )
        line.lineWidth = 1
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
        line.strokeColor = SKColor(
            white: 0.2,
            alpha: 0.08
        )
        line.lineWidth = 1
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

        background = SKShapeNode(
            rectOf: size,
            cornerRadius: 12
        )

        titleLabel = SKLabelNode(
            fontNamed: "AvenirNext-Bold"
        )

        super.init()

        background.fillColor = NeonColors.panel
        background.strokeColor = color
        background.lineWidth = 2
        background.glowWidth = 5

        titleLabel.text = title
        titleLabel.fontSize = 20
        titleLabel.fontColor = NeonColors.text

        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center

        background.zPosition = 0
        titleLabel.zPosition = 1

        addChild(background)
        addChild(titleLabel)

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

    let panel = SKShapeNode(
        rectOf: size,
        cornerRadius: 14
    )

    panel.fillColor = NeonColors.panel
    panel.strokeColor = color
    panel.lineWidth = 1.5
    panel.glowWidth = 3

    return panel
}

// MARK: - Neon Label

func createNeonLabel(
    text: String,
    fontSize: CGFloat,
    color: SKColor
) -> SKLabelNode {

    let label = SKLabelNode(
        fontNamed: "AvenirNext-Bold"
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
