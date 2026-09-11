import SpriteKit
import UIKit

final class MainMenuScene: SKScene {
    override func didMove(to view: SKView) { rebuild() }
    override func didChangeSize(_ oldSize: CGSize) { if view != nil { rebuild() } }

    private func rebuild() {
        removeAllChildren()
        removeAllActions()
        backgroundColor = NeonColors.background
        buildBackdrop()
        buildDistantBattle()
        addInterfaceAtmosphere(to: self)
        let left = size.width * 0.28
        label("POLY", x: left, y: size.height * 0.79, size: 45, color: .cyan)
        label("STRIKE", x: left, y: size.height * 0.665, size: 29, color: NeonColors.purple)
        buildArenaDisplay(at: CGPoint(x: left, y: size.height * 0.315))
        label("BEST  \(UserDefaults.standard.integer(forKey: "polystrikeBestScore"))", x: left, y: size.height * 0.085, size: 9, color: NeonColors.green)

        let x = size.width * 0.74
        let panel = SKShapeNode(rectOf: CGSize(width: size.width * 0.36, height: size.height * 0.70), cornerRadius: 16)
        panel.position = CGPoint(x: x, y: size.height * 0.51)
        panel.fillColor = SKColor(red: 0.012, green: 0.026, blue: 0.055, alpha: 0.96)
        panel.strokeColor = SKColor.cyan.withAlphaComponent(0.32)
        panel.lineWidth = 1.5
        panel.glowWidth = 2
        panel.zPosition = 1
        addChild(panel)
        button("PLAY INFINITE", name: "play", x: x, y: size.height * 0.69, color: .cyan)
        button("STORE", name: "store", x: x, y: size.height * 0.55, color: NeonColors.purple)
        button("BARRACKS", name: "barracks", x: x, y: size.height * 0.41, color: NeonColors.green)
        button("SETTINGS", name: "settings", x: x, y: size.height * 0.27, color: NeonColors.blue)
        label("LV \(PlayerProgress.shared.rankLevel)  •  ◈ \(PlayerProgress.shared.flux) FLUX", x: x, y: size.height * 0.175, size: 10, color: NeonColors.green)
        label("LEFT THUMB: MOVE     •     RIGHT THUMB: AIM", x: size.width / 2, y: 23, size: 8, color: NeonColors.mutedText)
    }

    private func buildBackdrop() {
        let grid = CGMutablePath()
        for x in stride(from: CGFloat(-size.height), through: size.width, by: 58) {
            grid.move(to: CGPoint(x: x, y: 0))
            grid.addLine(to: CGPoint(x: x + size.height * 0.5, y: size.height))
        }
        for y in stride(from: CGFloat(0), through: size.height, by: 45) {
            grid.move(to: CGPoint(x: 0, y: y))
            grid.addLine(to: CGPoint(x: size.width, y: y))
        }
        let lines = SKShapeNode(path: grid)
        lines.strokeColor = SKColor(red: 0.08, green: 0.20, blue: 0.30, alpha: 0.35)
        lines.lineWidth = 0.7
        lines.zPosition = -10
        addChild(lines)
        for i in 0..<18 {
            let mote = SKShapeNode(circleOfRadius: i % 3 == 0 ? 1.6 : 0.8)
            mote.fillColor = i % 2 == 0 ? .cyan : NeonColors.purple
            mote.strokeColor = .clear
            mote.alpha = 0.18
            let x = CGFloat((i * 137 + 43) % max(1, Int(size.width)))
            let y = CGFloat((i * 83 + 17) % max(1, Int(size.height)))
            mote.position = CGPoint(x: x, y: y)
            mote.zPosition = -5
            addChild(mote)
            mote.run(.repeatForever(.sequence([
                .group([.moveBy(x: 20, y: 30, duration: 4), .fadeAlpha(to: 0.55, duration: 4)]),
                .group([.moveBy(x: -20, y: -30, duration: 4), .fadeAlpha(to: 0.12, duration: 4)])
            ])))
        }
        for (x, color) in [(size.width * 0.05, SKColor.cyan), (size.width * 0.49, NeonColors.purple)] {
            let rail = SKShapeNode(rectOf: CGSize(width: 2, height: size.height * 0.45))
            rail.position = CGPoint(x: x, y: size.height * 0.50)
            rail.fillColor = color.withAlphaComponent(0.25)
            rail.strokeColor = .clear
            rail.glowWidth = 5
            addChild(rail)
        }
    }

    private func buildArenaDisplay(at center: CGPoint) {
        let display = SKNode()
        display.name = "arenaDisplay"
        display.position = center
        display.zPosition = 1
        display.setScale(min(1, size.height / 430))
        addChild(display)
        let frame = SKShapeNode(rectOf: CGSize(width: 196, height: 118), cornerRadius: 12)
        frame.fillColor = NeonColors.panel.withAlphaComponent(0.7)
        frame.strokeColor = SKColor.cyan.withAlphaComponent(0.28)
        frame.lineWidth = 1
        display.addChild(frame)
        for radius: CGFloat in [38, 61] {
            let ring = SKShapeNode(circleOfRadius: radius)
            ring.yScale = 0.48
            ring.strokeColor = SKColor.cyan.withAlphaComponent(0.20)
            ring.lineWidth = 1
            display.addChild(ring)
            ring.run(.repeatForever(.sequence([.fadeAlpha(to: 0.25, duration: 1.3), .fadeAlpha(to: 0.8, duration: 1.3)])))
        }
        for i in 0..<4 {
            let wall = SKShapeNode(rectOf: CGSize(width: 28, height: 5), cornerRadius: 2)
            wall.position = CGPoint(x: i % 2 == 0 ? -74 : 74, y: i < 2 ? -26 : 26)
            wall.strokeColor = NeonColors.purple.withAlphaComponent(0.8)
            wall.fillColor = NeonColors.panel
            wall.glowWidth = 2
            display.addChild(wall)
        }
        let ship = Player()
        ship.physicsBody = nil
        ship.setScale(0.78)
        ship.glowWidth = 4
        ship.position = CGPoint(x: -24, y: 0)
        display.addChild(ship)
        ship.run(.repeatForever(.sequence([
            .group([.moveBy(x: 8, y: 4, duration: 1.6), .rotate(toAngle: 0.08, duration: 1.6)]),
            .group([.moveBy(x: -8, y: -4, duration: 1.6), .rotate(toAngle: -0.04, duration: 1.6)])
        ])))
        for i in 0..<3 {
            let foe = SKShapeNode(rectOf: CGSize(width: 9, height: 9))
            foe.zRotation = .pi / 4
            foe.strokeColor = .orange
            foe.fillColor = SKColor.orange.withAlphaComponent(0.25)
            foe.position = CGPoint(x: 28 + CGFloat(i) * 18, y: CGFloat(i - 1) * 17)
            display.addChild(foe)
            foe.run(.repeatForever(.sequence([.fadeAlpha(to: 0.4, duration: 1.5 + Double(i) * 0.2), .fadeAlpha(to: 1, duration: 1.5)])))
        }
    }

    private func label(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat, color: SKColor) {
        let node = createNeonLabel(text: text, fontSize: size, color: color)
        node.position = CGPoint(x: x, y: y)
        node.zPosition = 3
        addChild(node)
    }
    private func button(_ title: String, name: String, x: CGFloat, y: CGFloat, color: SKColor) {
        let node = NeonButton(title: title, size: CGSize(width: min(250, size.width * 0.30), height: 46), color: color)
        node.name = name
        node.position = CGPoint(x: x, y: y)
        node.zPosition = 3
        node.titleLabel.fontSize = 13
        for shape in node.children.compactMap({ $0 as? SKShapeNode }) {
            shape.glowWidth = 1.5
            shape.lineWidth = 1
            shape.fillColor = color.withAlphaComponent(0.07)
        }
        addChild(node)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        for node in nodes(at: point) {
            let name = node.name ?? node.parent?.name
            if name == "play" || name == "store" || name == "barracks" || name == "settings" {
                let scene: SKScene
                switch name {
                case "play": scene = GameScene(size: size)
                case "store": scene = StoreScene(size: size)
                case "barracks": scene = BarracksScene(size: size)
                default: scene = SettingsScene(size: size)
                }
                scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: .fade(withDuration: 0.2))
                return
            }
        }
    }
}

final class RankEmblemNode: SKNode {
    init(level: Int, size: CGFloat, locked: Bool = false) {
        super.init()
        let prestige = min(10, max(0, level / 100))
        let rankBand = min(9, max(0, (level - 1) / 10))
        let complexity = prestige > 0 ? prestige : rankBand
        let primary = locked ? SKColor(white: 0.25, alpha: 0.7) : Self.primaryColor(prestige: prestige, rankBand: rankBand)
        let secondary = locked ? SKColor(white: 0.14, alpha: 0.8) : Self.secondaryColor(prestige: prestige, rankBand: rankBand)
        let glow: CGFloat = locked ? 0 : (prestige > 0 ? 8 : 3 + CGFloat(rankBand) * 0.35)

        // A dark armored backing keeps every emblem legible over the arena grid.
        let outer = SKShapeNode(path: Self.polygon(sides: min(12, 5 + complexity / 2),
                                                   radius: size * 0.48,
                                                   rotation: -.pi / 2))
        outer.fillColor = SKColor(red: 0.012, green: 0.022, blue: 0.055, alpha: 0.98)
        outer.strokeColor = primary
        outer.lineWidth = prestige > 0 ? 2.4 : 1.5
        outer.glowWidth = glow
        addChild(outer)

        let inner = SKShapeNode(path: Self.polygon(sides: 4 + complexity % 4,
                                                   radius: size * 0.31,
                                                   rotation: .pi / 4))
        inner.fillColor = secondary.withAlphaComponent(locked ? 0.08 : 0.25)
        inner.strokeColor = locked ? primary : .white
        inner.lineWidth = prestige > 0 ? 1.8 : 1.2
        inner.glowWidth = locked ? 0 : glow * 0.45
        addChild(inner)

        // Rank 1–99 gains chevrons, and side laurels every ten levels.
        if prestige == 0 {
            let chevrons = 1 + rankBand / 2
            for index in 0..<chevrons {
                let y = -size * 0.33 - CGFloat(index) * size * 0.075
                let path = CGMutablePath()
                path.move(to: CGPoint(x: -size * 0.22, y: y + size * 0.07))
                path.addLine(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size * 0.22, y: y + size * 0.07))
                let chevron = SKShapeNode(path: path)
                chevron.strokeColor = primary
                chevron.lineWidth = max(1, size * 0.025)
                chevron.glowWidth = glow * 0.45
                addChild(chevron)
            }
        }

        if complexity >= 1 {
            for direction: CGFloat in [-1, 1] {
                let wing = SKShapeNode(path: Self.wing(direction: direction, size: size, blades: min(5, 2 + complexity / 2)))
                wing.fillColor = secondary.withAlphaComponent(locked ? 0.07 : 0.22)
                wing.strokeColor = primary
                wing.lineWidth = prestige > 0 ? 1.7 : 1.1
                wing.glowWidth = locked ? 0 : glow * 0.55
                wing.zPosition = -1
                addChild(wing)
            }
        }

        // Every prestige receives another crown layer, orbital detail, and gem.
        if prestige > 0 {
            let spikeCount = 6 + prestige
            let crown = SKShapeNode(path: Self.star(points: spikeCount,
                                                    outer: size * (0.55 + CGFloat(prestige) * 0.012),
                                                    inner: size * 0.43,
                                                    rotation: -.pi / 2))
            crown.fillColor = primary.withAlphaComponent(locked ? 0.03 : 0.08)
            crown.strokeColor = primary.withAlphaComponent(locked ? 0.3 : 0.82)
            crown.lineWidth = prestige >= 5 ? 1.5 : 1
            crown.glowWidth = locked ? 0 : glow * 0.6
            crown.zPosition = -3
            addChild(crown)
            if !locked && prestige >= 4 {
                crown.run(.repeatForever(.rotate(byAngle: prestige >= 8 ? -.pi * 2 : .pi * 2,
                                                 duration: max(5, 11 - Double(prestige) * 0.5))))
            }
            let gem = SKShapeNode(path: Self.polygon(sides: prestige >= 7 ? 8 : 6,
                                                     radius: size * (prestige >= 8 ? 0.16 : 0.12),
                                                     rotation: .pi / 2))
            gem.fillColor = locked ? primary.withAlphaComponent(0.12) : .white
            gem.strokeColor = secondary
            gem.lineWidth = 1.5
            gem.glowWidth = locked ? 0 : 6 + CGFloat(prestige) * 0.5
            gem.zPosition = 2
            addChild(gem)
            if !locked { gem.run(.repeatForever(.sequence([.scale(to: 1.16, duration: 0.55), .scale(to: 0.88, duration: 0.55)]))) }
        }

        let label = createNeonLabel(text: locked ? "?" : "\(level)", fontSize: max(7, size * (prestige > 0 ? 0.15 : 0.18)), color: locked ? primary : .white)
        label.position.y = prestige > 0 ? -size * 0.02 : size * 0.02
        label.zPosition = 3
        addChild(label)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private static func polygon(sides: Int, radius: CGFloat, rotation: CGFloat) -> CGPath {
        let path = CGMutablePath()
        for index in 0..<sides {
            let angle = CGFloat(index) * .pi * 2 / CGFloat(sides) + rotation
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    private static func star(points: Int, outer: CGFloat, inner: CGFloat, rotation: CGFloat) -> CGPath {
        let path = CGMutablePath()
        for index in 0..<(points * 2) {
            let radius = index.isMultiple(of: 2) ? outer : inner
            let angle = CGFloat(index) * .pi / CGFloat(points) + rotation
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    private static func wing(direction: CGFloat, size: CGFloat, blades: Int) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: direction * size * 0.30, y: size * 0.20))
        for index in 0..<blades {
            let spread = CGFloat(index) / CGFloat(max(1, blades - 1))
            path.addLine(to: CGPoint(x: direction * size * (0.48 + spread * 0.18),
                                     y: size * (0.34 - spread * 0.19)))
            path.addLine(to: CGPoint(x: direction * size * (0.37 + spread * 0.08),
                                     y: size * (0.18 - spread * 0.20)))
        }
        path.addLine(to: CGPoint(x: direction * size * 0.30, y: -size * 0.24))
        path.closeSubpath()
        return path
    }

    private static func primaryColor(prestige: Int, rankBand: Int) -> SKColor {
        guard prestige > 0 else {
            return [.cyan, NeonColors.green, NeonColors.blue, .cyan, NeonColors.purple,
                    NeonColors.pink, NeonColors.orange, NeonColors.yellow, .white, .cyan][rankBand]
        }
        return [NeonColors.green, NeonColors.blue, .cyan, NeonColors.purple, NeonColors.pink,
                NeonColors.orange, NeonColors.yellow, .magenta, .white, .white][prestige - 1]
    }

    private static func secondaryColor(prestige: Int, rankBand: Int) -> SKColor {
        guard prestige > 0 else { return rankBand >= 6 ? NeonColors.orange : NeonColors.purple }
        return [NeonColors.blue, .cyan, NeonColors.purple, NeonColors.pink, NeonColors.orange,
                NeonColors.yellow, .white, .cyan, NeonColors.purple, NeonColors.yellow][prestige - 1]
    }
}

final class BarracksScene: SKScene {
    override func didMove(to view: SKView) { rebuild() }
    override func didChangeSize(_ oldSize: CGSize) { if view != nil { rebuild() } }

    private func rebuild() {
        removeAllChildren()
        createNeonBackground(for: self, gridSpacing: 54)
        addInterfaceAtmosphere(to: self)
        let progress = PlayerProgress.shared

        addLabel("BARRACKS", at: CGPoint(x: size.width * 0.15, y: size.height - 40), size: 23, color: .cyan)
        addLabel("CAREER RECORD  /  RANK PROGRESSION", at: CGPoint(x: size.width * 0.15, y: size.height - 62), size: 8, color: NeonColors.mutedText)

        let rankPanel = panel(size: CGSize(width: size.width * 0.29, height: size.height * 0.49), color: .cyan)
        rankPanel.position = CGPoint(x: size.width * 0.19, y: size.height * 0.55)
        addChild(rankPanel)
        let emblem = RankEmblemNode(level: progress.rankLevel, size: min(122, size.height * 0.24))
        emblem.position = CGPoint(x: 0, y: size.height * 0.08)
        rankPanel.addChild(emblem)
        addPanelLabel("LEVEL \(progress.rankLevel)", to: rankPanel, y: -size.height * 0.105, size: 17, color: .white)
        addPanelLabel(progress.rankTitle, to: rankPanel, y: -size.height * 0.15, size: 9, color: .cyan)

        let trackWidth = size.width * 0.22
        let track = SKShapeNode(rectOf: CGSize(width: trackWidth, height: 7), cornerRadius: 3.5)
        track.position = CGPoint(x: 0, y: -size.height * 0.205)
        track.fillColor = SKColor.white.withAlphaComponent(0.08)
        track.strokeColor = .clear
        rankPanel.addChild(track)
        let ratio = progress.rankLevel >= 1000 ? 1 : CGFloat(progress.xpIntoLevel) / CGFloat(max(1, progress.xpForNextLevel))
        let fillWidth = max(3, trackWidth * ratio)
        let fill = SKShapeNode(rectOf: CGSize(width: fillWidth, height: 7), cornerRadius: 3.5)
        fill.position.x = -trackWidth / 2 + fillWidth / 2
        fill.fillColor = .cyan
        fill.strokeColor = .clear
        fill.glowWidth = 5
        track.addChild(fill)
        let xpText = progress.rankLevel >= 1000 ? "MAXIMUM RANK" : "\(number(progress.xpIntoLevel)) / \(number(progress.xpForNextLevel)) XP"
        addPanelLabel(xpText, to: rankPanel, y: -size.height * 0.245, size: 8, color: NeonColors.mutedText)

        let statPanel = panel(size: CGSize(width: size.width * 0.53, height: size.height * 0.49), color: NeonColors.purple)
        statPanel.position = CGPoint(x: size.width * 0.66, y: size.height * 0.55)
        addChild(statPanel)
        let stats: [(String, String)] = [
            ("TIME IN BATTLE", duration(progress.totalBattleTime)),
            ("ENEMIES KILLED", number(progress.totalEnemiesKilled)),
            ("TIERS COMPLETED", number(progress.totalTiersCompleted)),
            ("HIGHEST TIER", "TIER \(max(1, progress.highestTier))"),
            ("HIGHEST SCORE", number(progress.highestScore)),
            ("TOTAL FLUX", number(progress.totalFluxEarned)),
            ("CAREER XP", number(progress.totalXP)),
            ("CURRENT FLUX", number(progress.flux))
        ]
        for (index, stat) in stats.enumerated() {
            let column = index % 2, row = index / 2
            let cardWidth = size.width * 0.225
            let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: size.height * 0.09), cornerRadius: 8)
            card.position = CGPoint(x: (column == 0 ? -1 : 1) * size.width * 0.125,
                                    y: size.height * 0.15 - CGFloat(row) * size.height * 0.105)
            card.fillColor = SKColor(red: 0.015, green: 0.025, blue: 0.055, alpha: 0.92)
            card.strokeColor = (column == 0 ? SKColor.cyan : NeonColors.purple).withAlphaComponent(0.32)
            statPanel.addChild(card)
            let title = createNeonLabel(text: stat.0, fontSize: 7, color: NeonColors.mutedText)
            title.position.y = 10
            card.addChild(title)
            let value = createNeonLabel(text: stat.1, fontSize: 12, color: .white)
            value.position.y = -9
            card.addChild(value)
        }

        addLabel("CENTURY EMBLEMS", at: CGPoint(x: size.width * 0.12, y: size.height * 0.245), size: 9, color: NeonColors.mutedText)
        for index in 1...10 {
            let milestone = index * 100
            let locked = progress.rankLevel < milestone
            let emblem = RankEmblemNode(level: milestone, size: min(53, size.width * 0.058), locked: locked)
            emblem.position = CGPoint(x: size.width * (0.08 + CGFloat(index - 1) * 0.093), y: size.height * 0.13)
            addChild(emblem)
            addLabel("\(milestone)", at: CGPoint(x: emblem.position.x, y: size.height * 0.045), size: 7,
                     color: locked ? SKColor(white: 0.28, alpha: 1) : .white)
        }

        let back = NeonButton(title: "BACK", size: CGSize(width: 118, height: 36), color: .cyan)
        back.name = "back"
        back.position = CGPoint(x: size.width - 78, y: size.height - 43)
        back.zPosition = 8
        addChild(back)
    }

    private func panel(size: CGSize, color: SKColor) -> SKShapeNode {
        let node = SKShapeNode(rectOf: size, cornerRadius: 14)
        node.fillColor = NeonColors.panel.withAlphaComponent(0.95)
        node.strokeColor = color.withAlphaComponent(0.38)
        node.lineWidth = 1.5
        node.glowWidth = 2
        return node
    }

    private func addLabel(_ text: String, at point: CGPoint, size: CGFloat, color: SKColor) {
        let label = createNeonLabel(text: text, fontSize: size, color: color)
        label.position = point
        label.zPosition = 6
        addChild(label)
    }

    private func addPanelLabel(_ text: String, to panel: SKNode, y: CGFloat, size: CGFloat, color: SKColor) {
        let label = createNeonLabel(text: text, fontSize: size, color: color)
        label.position.y = y
        panel.addChild(label)
    }

    private func number(_ value: Int) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: value), number: .decimal)
    }

    private func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        return String(format: "%02dh %02dm %02ds", total / 3600, (total / 60) % 60, total % 60)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        for node in nodes(at: point) where node.name == "back" || node.parent?.name == "back" {
            let scene = MainMenuScene(size: size)
            scene.scaleMode = .resizeFill
            view?.presentScene(scene, transition: .fade(withDuration: 0.2))
            return
        }
    }
}


private extension MainMenuScene {
    func buildDistantBattle() {
        for i in 0..<8 {
            let group = SKNode()
            group.position = CGPoint(x: size.width * CGFloat(i + 1) / 9, y: size.height * (i % 2 == 0 ? 0.82 : 0.18))
            group.zPosition = -4
            group.alpha = i % 3 == 0 ? 0.24 : 0.17
            addChild(group)
            let shape: SKShapeNode
            if i % 3 == 0 {
                let path = CGMutablePath()
                for vertex in 0..<6 {
                    let angle = CGFloat(vertex) * .pi / 3
                    let point = CGPoint(x: cos(angle) * 22, y: sin(angle) * 22)
                    if vertex == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
                path.closeSubpath()
                shape = SKShapeNode(path: path)
                shape.strokeColor = .orange
            } else if i % 3 == 1 {
                shape = Player()
                shape.physicsBody = nil
                shape.strokeColor = .cyan
            } else {
                shape = SKShapeNode(circleOfRadius: 13)
                shape.strokeColor = NeonColors.pink
            }
            shape.fillColor = shape.strokeColor.withAlphaComponent(0.16)
            shape.lineWidth = 1.5
            shape.glowWidth = 2
            group.addChild(shape)
            let dx: CGFloat = i % 2 == 0 ? 32 : -32
            group.run(.repeatForever(.sequence([.moveBy(x: dx, y: 20, duration: 7), .moveBy(x: -dx, y: -20, duration: 7)])))
            shape.run(.repeatForever(.sequence([
                .group([.moveBy(x: 5, y: 3, duration: 2.8 + Double(i) * 0.2), .fadeAlpha(to: 0.55, duration: 2.8)]),
                .group([.moveBy(x: -5, y: -3, duration: 2.8 + Double(i) * 0.2), .fadeAlpha(to: 1, duration: 2.8)])
            ])))
            // A bounded repeating trail suggests distant fire without cluttering the controls.
            for shotIndex in 0..<2 {
                let shot = SKShapeNode(rectOf: CGSize(width: 8, height: 2), cornerRadius: 1)
                shot.fillColor = shape.strokeColor
                shot.strokeColor = .clear
                shot.alpha = 0
                group.addChild(shot)
                shot.run(.repeatForever(.sequence([
                    .wait(forDuration: Double(i) * 0.2 + Double(shotIndex) * 0.35 + 1),
                    .run { [weak shot] in shot?.position = .zero; shot?.alpha = 0.8 },
                    .group([.moveBy(x: dx * 3, y: 15, duration: 1.1), .fadeOut(withDuration: 1.1)]),
                    .wait(forDuration: 2)
                ])))
            }
        }
    }
}

final class SettingsScene: SKScene {
    override func didMove(to view: SKView) { rebuild() }
    override func didChangeSize(_ oldSize: CGSize) { if view != nil { rebuild() } }
    private func rebuild() {
        removeAllChildren()
        createNeonBackground(for: self, gridSpacing: 55)
        addInterfaceAtmosphere(to: self)
        let title = createNeonLabel(text: "CONTROL SYSTEMS", fontSize: 22, color: .cyan)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: 34, y: size.height - 40)
        addChild(title)
        let subtitle = createNeonLabel(text: "VISUAL FEEDBACK / TWIN-STICK INTERFACE", fontSize: 8, color: NeonColors.mutedText)
        subtitle.horizontalAlignmentMode = .left
        subtitle.position = CGPoint(x: 36, y: size.height - 62)
        addChild(subtitle)

        let previewWidth = min(210, size.width * 0.27)
        let preview = SKShapeNode(rectOf: CGSize(width: previewWidth, height: size.height * 0.54), cornerRadius: 14)
        preview.position = CGPoint(x: 36 + previewWidth / 2, y: size.height * 0.48)
        preview.fillColor = NeonColors.panel
        preview.strokeColor = NeonColors.purple.withAlphaComponent(0.45)
        preview.glowWidth = 2
        addChild(preview)
        let previewTitle = createNeonLabel(text: "INPUT LINK", fontSize: 10, color: NeonColors.purple)
        previewTitle.position = CGPoint(x: 0, y: size.height * 0.19)
        preview.addChild(previewTitle)
        for (x, caption) in [(-previewWidth * 0.23, "MOVE"), (previewWidth * 0.23, "AIM")] {
            let outer = SKShapeNode(circleOfRadius: 26)
            outer.position = CGPoint(x: x, y: 4)
            outer.fillColor = SKColor.cyan.withAlphaComponent(0.035)
            outer.strokeColor = SKColor.cyan.withAlphaComponent(0.4)
            outer.lineWidth = 1
            preview.addChild(outer)
            let thumb = SKShapeNode(circleOfRadius: 9)
            thumb.fillColor = .cyan
            thumb.strokeColor = .white
            thumb.glowWidth = 5
            outer.addChild(thumb)
            thumb.run(.repeatForever(.sequence([
                .move(to: CGPoint(x: x < 0 ? 10 : -8, y: x < 0 ? 6 : 10), duration: 1.4),
                .move(to: CGPoint(x: -5, y: -7), duration: 1.4),
                .move(to: .zero, duration: 0.8)
            ])))
            let label = createNeonLabel(text: caption, fontSize: 8, color: NeonColors.mutedText)
            label.position = CGPoint(x: x, y: -42)
            preview.addChild(label)
        }
        let hapticsOn = GameSettings.shared.hapticsEnabled
        let haptics = SKShapeNode(rectOf: CGSize(width: previewWidth - 22, height: 32), cornerRadius: 7)
        haptics.name = "toggleHaptics"
        haptics.position = CGPoint(x: 0, y: -size.height * 0.19)
        haptics.fillColor = hapticsOn ? SKColor.cyan.withAlphaComponent(0.09) : NeonColors.panel
        haptics.strokeColor = hapticsOn ? .cyan : NeonColors.mutedText.withAlphaComponent(0.35)
        preview.addChild(haptics)
        let hapticsTitle = createNeonLabel(text: "HAPTICS", fontSize: 9, color: .white)
        hapticsTitle.horizontalAlignmentMode = .left
        hapticsTitle.position = CGPoint(x: -(previewWidth - 22) / 2 + 11, y: 0)
        haptics.addChild(hapticsTitle)
        let hapticsState = createNeonLabel(text: hapticsOn ? "ON" : "OFF", fontSize: 9, color: hapticsOn ? NeonColors.green : NeonColors.mutedText)
        hapticsState.horizontalAlignmentMode = .right
        hapticsState.position = CGPoint(x: (previewWidth - 22) / 2 - 11, y: 0)
        haptics.addChild(hapticsState)
        let contentLeft = 56 + previewWidth
        let width = max(300, size.width - contentLeft - 34)
        for (index, mode) in JoystickVisibility.allCases.enumerated() {
            let selected = GameSettings.shared.joystickVisibility == mode
            let card = SKShapeNode(rectOf: CGSize(width: width, height: 62), cornerRadius: 10)
            card.name = mode.rawValue
            card.position = CGPoint(x: contentLeft + width / 2, y: size.height - 105 - CGFloat(index) * 72)
            card.fillColor = selected ? SKColor.cyan.withAlphaComponent(0.10) : NeonColors.panel
            card.strokeColor = selected ? .cyan : NeonColors.mutedText.withAlphaComponent(0.26)
            card.lineWidth = selected ? 1.7 : 1
            card.glowWidth = selected ? 3 : 0
            addChild(card)
            let heading = createNeonLabel(text: (selected ? "◆  " : "◇  ") + mode.title.uppercased(), fontSize: 11, color: selected ? .cyan : .white)
            heading.horizontalAlignmentMode = .left
            heading.position = CGPoint(x: -width / 2 + 18, y: 10)
            card.addChild(heading)
            let detail = createNeonLabel(text: mode.detail, fontSize: 10, color: NeonColors.mutedText)
            detail.horizontalAlignmentMode = .left
            detail.position = CGPoint(x: -width / 2 + 18, y: -12)
            card.addChild(detail)
            if selected {
                let active = createNeonLabel(text: "ACTIVE", fontSize: 8, color: NeonColors.green)
                active.horizontalAlignmentMode = .right
                active.position = CGPoint(x: width / 2 - 16, y: 0)
                card.addChild(active)
            }
        }
        let back = NeonButton(title: "BACK", size: CGSize(width: 122, height: 38), color: .cyan)
        back.name = "back"
        back.position = CGPoint(x: size.width - 120, y: 43)
        addChild(back)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        for node in nodes(at: point) {
            let name = node.name ?? node.parent?.name ?? ""
            if name == "back" {
                let scene = MainMenuScene(size: size); scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: .fade(withDuration: 0.2)); return
            }
            if name == "toggleHaptics" {
                GameSettings.shared.hapticsEnabled.toggle()
                if GameSettings.shared.hapticsEnabled {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.55)
                }
                rebuild(); return
            }
            if let mode = JoystickVisibility(rawValue: name) {
                GameSettings.shared.joystickVisibility = mode
                rebuild(); return
            }
        }
    }
}
