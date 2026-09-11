import SpriteKit
import UIKit

final class Barrier: SKShapeNode {

    let barrierRect: CGRect
    let collisionWidth: CGFloat
    let collisionHeight: CGFloat

    init(
        rect: CGRect,
        style: Int,
        rotation: CGFloat = 0
    ) {
        self.barrierRect = rect
        self.collisionWidth = rect.width
        self.collisionHeight = rect.height

        super.init()

        let localRect = CGRect(
            x: -rect.width / 2,
            y: -rect.height / 2,
            width: rect.width,
            height: rect.height
        )

        let path = CGPath(
            roundedRect: localRect,
            cornerWidth: min(8, rect.height / 2),
            cornerHeight: min(8, rect.height / 2),
            transform: nil
        )

        self.path = path

        position = CGPoint(
            x: rect.midX,
            y: rect.midY
        )

        zRotation = rotation

        configureStyle(style)

        name = "barrier"
        zPosition = 2
        alpha = 0

        run(
            SKAction.fadeIn(
                withDuration: 0.5
            )
        )
    }

    // MARK: - Styling

    private func configureStyle(_ style: Int) {

        switch style {

        case 1:
            fillColor = SKColor(
                red: 0.05,
                green: 0.25,
                blue: 0.35,
                alpha: 0.9
            )

            strokeColor = .cyan
            lineWidth = 3
            glowWidth = 10

        case 2:
            fillColor = SKColor(
                red: 0.25,
                green: 0.05,
                blue: 0.35,
                alpha: 0.9
            )

            strokeColor = .purple
            lineWidth = 3
            glowWidth = 12

        case 3:
            fillColor = SKColor(
                red: 0.35,
                green: 0.08,
                blue: 0.05,
                alpha: 0.9
            )

            strokeColor = .orange
            lineWidth = 3
            glowWidth = 14

        case 4:
            fillColor = SKColor(
                red: 0.4,
                green: 0.03,
                blue: 0.15,
                alpha: 0.9
            )

            strokeColor = .red
            lineWidth = 4
            glowWidth = 16

        default:
            fillColor = SKColor(
                white: 0.15,
                alpha: 0.9
            )

            strokeColor = .white
            lineWidth = 2
            glowWidth = 6
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
