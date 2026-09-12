import SpriteKit
import UIKit
import AVFoundation

final class MainMenuScene: SKScene {
    private var previewPlayer: AVQueuePlayer?
    private var previewLooper: AVPlayerLooper?
    private var modeBriefing: SKNode?

    override func didMove(to view: SKView) {
        rebuild()
        DispatchQueue.main.async { [weak self, weak view] in
            guard let self, self.view === view else { return }
            self.rebuild()
        }
    }
    override func didChangeSize(_ oldSize: CGSize) { if view != nil { rebuild() } }

    private func rebuild() {
        previewPlayer?.pause()
        previewLooper = nil
        previewPlayer = nil
        modeBriefing = nil
        removeAllChildren()
        removeAllActions()
        backgroundColor = NeonColors.background
        buildBackdrop()
        buildDistantBattle()
        addInterfaceAtmosphere(to: self)
        var safe = view?.safeAreaInsets ?? .zero
        // The first SpriteKit frame can arrive before UIKit has calculated the
        // landscape cutout. Use conservative phone insets until UIKit refreshes.
        if UIDevice.current.userInterfaceIdiom == .phone && safe.left < 1 && safe.right < 1 {
            safe.left = 59
            safe.right = 59
            safe.bottom = max(safe.bottom, 21)
        }
        let leftEdge = safe.left + 18
        let rightEdge = size.width - safe.right - 18
        let bottomEdge = safe.bottom + 14
        let usableWidth = max(560, rightEdge - leftEdge)
        let usableHeight = max(280, size.height - safe.top - safe.bottom)
        let headerY = size.height - safe.top - 24
        label("SELECT MODE", x: leftEdge, y: headerY, size: 20, color: NeonColors.orange, alignment: .left)
        let headerRule = SKShapeNode(rectOf: CGSize(width: usableWidth, height: 1))
        headerRule.position = CGPoint(x: (leftEdge + rightEdge) / 2, y: headerY - 19)
        headerRule.fillColor = SKColor.white.withAlphaComponent(0.14)
        headerRule.strokeColor = .clear
        addChild(headerRule)

        let currentLevel = PlayerProgress.shared.rankLevel
        let rankIcon = RankEmblemNode(level: currentLevel, size: 34)
        rankIcon.position = CGPoint(x: rightEdge - 18, y: headerY - 1)
        rankIcon.zPosition = 5
        addChild(rankIcon)
        label("LEVEL \(currentLevel)", x: rightEdge - 42, y: headerY + 2, size: 9, color: .white, alignment: .right)
        label(PlayerProgress.rankTitle(for: currentLevel).uppercased(), x: rightEdge - 42, y: headerY - 11, size: 6, color: NeonColors.mutedText, alignment: .right)

        let gutter: CGFloat = 10
        let previewHeight = min(165, usableHeight * 0.41)
        let previewWidth = min((usableWidth - gutter) / 2, previewHeight * 1.62)
        let previewGroupWidth = previewWidth * 2 + gutter
        let previewLeft = leftEdge + (usableWidth - previewGroupWidth) / 2
        let previewY = headerY - 31 - previewHeight / 2
        buildArenaDisplay(at: CGPoint(x: previewLeft + previewWidth / 2, y: previewY), frameSize: CGSize(width: previewWidth, height: previewHeight))
        buildStoryPreview(at: CGPoint(x: previewLeft + previewWidth + gutter + previewWidth / 2, y: previewY), frameSize: CGSize(width: previewWidth, height: previewHeight))

        let gridTop = previewY - previewHeight / 2 - gutter
        let buttonHeight = max(40, min(49, (gridTop - bottomEdge - gutter) / 2))
        let buttonWidth = (usableWidth - gutter * 2) / 3
        let row1Y = gridTop - buttonHeight / 2
        let row2Y = row1Y - buttonHeight - gutter
        let column1 = leftEdge + buttonWidth / 2
        let column2 = leftEdge + buttonWidth + gutter + buttonWidth / 2
        let column3 = leftEdge + (buttonWidth + gutter) * 2 + buttonWidth / 2
        menuButton("INFINITE MODE", name: "play", x: column1, y: row1Y, color: .cyan, size: CGSize(width: buttonWidth, height: buttonHeight), selected: true)
        menuButton("STORY MODE", name: "storyMode", x: column2, y: row1Y, color: NeonColors.orange, size: CGSize(width: buttonWidth, height: buttonHeight))
        menuButton("STORE", name: "store", x: column3, y: row1Y, color: NeonColors.purple, size: CGSize(width: buttonWidth, height: buttonHeight))
        menuButton("BARRACKS", name: "barracks", x: column1, y: row2Y, color: NeonColors.green, size: CGSize(width: buttonWidth, height: buttonHeight))
        menuButton("SETTINGS", name: "settings", x: column2, y: row2Y, color: NeonColors.blue, size: CGSize(width: buttonWidth, height: buttonHeight))
        menuButton("LEADERBOARDS  /  SOON", name: "leaderboards", x: column3, y: row2Y, color: NeonColors.pink, size: CGSize(width: buttonWidth, height: buttonHeight), enabled: false)
        label("POLYSTRIKE / MAIN", x: leftEdge, y: bottomEdge - 2, size: 7, color: NeonColors.mutedText, alignment: .left)
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
        for i in 0..<12 {
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
            rail.glowWidth = 1
            addChild(rail)
        }
    }

    private func buildArenaDisplay(at center: CGPoint, frameSize: CGSize) {
        let display = SKNode()
        display.name = "playPreview"
        display.position = center
        display.zPosition = 1
        addChild(display)
        let frame = SKShapeNode(rectOf: frameSize, cornerRadius: 1)
        frame.name = "playPreview"
        frame.fillColor = NeonColors.panel.withAlphaComponent(0.7)
        frame.strokeColor = SKColor.cyan.withAlphaComponent(0.28)
        frame.lineWidth = 1
        display.addChild(frame)
        let crop = SKCropNode()
        let cropMask = SKShapeNode(rectOf: CGSize(width: frameSize.width - 4, height: frameSize.height - 4), cornerRadius: 1)
        cropMask.fillColor = .white
        cropMask.strokeColor = .clear
        crop.maskNode = cropMask
        crop.zPosition = 2
        crop.name = "playPreview"
        display.addChild(crop)
        if let url = Bundle.main.url(forResource: "InfiniteArenaPreview", withExtension: "m4v") {
            let player = AVQueuePlayer()
            player.isMuted = true
            player.actionAtItemEnd = .none
            let item = AVPlayerItem(url: url)
            previewLooper = AVPlayerLooper(player: player, templateItem: item)
            previewPlayer = player

            let video = SKVideoNode(avPlayer: player)
            let aspectHeight = frameSize.width * 9 / 16
            video.size = CGSize(width: frameSize.width, height: max(frameSize.height, aspectHeight))
            video.zPosition = 1
            crop.addChild(video)
            player.play()
        } else {
            let unavailable = createNeonLabel(text: "PREVIEW OFFLINE", fontSize: 10, color: NeonColors.mutedText)
            crop.addChild(unavailable)
        }
        let captionShade = SKShapeNode(rectOf: CGSize(width: frameSize.width - 2, height: 40))
        captionShade.position.y = -frameSize.height / 2 + 21
        captionShade.fillColor = SKColor.black.withAlphaComponent(0.58)
        captionShade.strokeColor = .clear
        frame.zPosition = 1
        captionShade.zPosition = 20
        frame.addChild(captionShade)
        let caption = createNeonLabel(text: "INFINITE ARENA", fontSize: 14, color: .white)
        caption.position.y = -4
        captionShade.addChild(caption)
    }

    private func buildStoryPreview(at center: CGPoint, frameSize: CGSize) {
        let tile = SKShapeNode(rectOf: frameSize, cornerRadius: 1)
        tile.name = "storyMode"
        tile.position = center
        tile.fillColor = SKColor(red: 0.035, green: 0.012, blue: 0.055, alpha: 0.96)
        tile.strokeColor = NeonColors.orange.withAlphaComponent(0.42)
        tile.lineWidth = 1
        tile.zPosition = 1
        addChild(tile)

        for scale: CGFloat in [0.30, 0.52, 0.76] {
            let diamond = SKShapeNode(rectOf: CGSize(width: frameSize.height * scale, height: frameSize.height * scale))
            diamond.zRotation = .pi / 4
            diamond.strokeColor = NeonColors.orange.withAlphaComponent(0.10 + scale * 0.18)
            diamond.lineWidth = 1
            tile.addChild(diamond)
            diamond.run(.repeatForever(.sequence([.fadeAlpha(to: 0.32, duration: 1.4), .fadeAlpha(to: 1, duration: 1.4)])))
        }

        let lock = SKShapeNode(path: {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -10, y: 2))
            path.addLine(to: CGPoint(x: 0, y: 12))
            path.addLine(to: CGPoint(x: 10, y: 2))
            path.addLine(to: CGPoint(x: 0, y: -8))
            path.closeSubpath()
            return path
        }())
        lock.fillColor = NeonColors.orange.withAlphaComponent(0.14)
        lock.strokeColor = NeonColors.orange
        lock.glowWidth = 3
        lock.position.y = 16
        tile.addChild(lock)

        let title = createNeonLabel(text: "STORY MODE", fontSize: 14, color: .white)
        title.position.y = -16
        tile.addChild(title)
        let status = createNeonLabel(text: "5 SECTORS  •  21 MISSIONS", fontSize: 8, color: NeonColors.orange)
        status.position.y = -37
        tile.addChild(status)

        let scan = SKShapeNode(rectOf: CGSize(width: frameSize.width - 22, height: 1))
        scan.fillColor = NeonColors.orange.withAlphaComponent(0.45)
        scan.strokeColor = .clear
        scan.position.y = -frameSize.height / 2 + 9
        tile.addChild(scan)
        scan.run(.repeatForever(.sequence([
            .moveTo(y: frameSize.height / 2 - 9, duration: 2.4),
            .moveTo(y: -frameSize.height / 2 + 9, duration: 0)
        ])))
    }

    private func label(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat, color: SKColor, alignment: SKLabelHorizontalAlignmentMode = .center) {
        let node = createNeonLabel(text: text, fontSize: size, color: color)
        node.horizontalAlignmentMode = alignment
        node.position = CGPoint(x: x, y: y)
        node.zPosition = 3
        addChild(node)
    }
    private func menuButton(_ title: String, name: String, x: CGFloat, y: CGFloat, color: SKColor, size: CGSize, selected: Bool = false, enabled: Bool = true) {
        let node = NeonButton(title: title, size: size, color: color)
        node.name = name
        node.position = CGPoint(x: x, y: y)
        node.zPosition = 3
        node.titleLabel.fontSize = enabled ? 10 : 8
        node.alpha = enabled ? 1 : 0.52
        for shape in node.children.compactMap({ $0 as? SKShapeNode }) {
            shape.glowWidth = 1.5
            shape.lineWidth = 1
            shape.fillColor = color.withAlphaComponent(selected ? 0.10 : 0.035)
        }
        addChild(node)
        if selected {
            let marker = SKShapeNode(rectOf: CGSize(width: 9, height: 9))
            marker.zRotation = .pi / 4
            marker.position = CGPoint(x: x, y: y - size.height / 2)
            marker.fillColor = color
            marker.strokeColor = NeonColors.background
            marker.lineWidth = 1
            marker.zPosition = 5
            addChild(marker)
        }
    }

    private func showInfiniteBriefing() {
        guard modeBriefing == nil else { return }
        let overlay = SKNode()
        overlay.zPosition = 100
        addChild(overlay)
        modeBriefing = overlay

        let shade = SKShapeNode(rectOf: size)
        shade.position = CGPoint(x: size.width / 2, y: size.height / 2)
        shade.fillColor = SKColor.black.withAlphaComponent(0.86)
        shade.strokeColor = .clear
        overlay.addChild(shade)

        let safe = view?.safeAreaInsets ?? .zero
        let panelWidth = min(540, size.width - safe.left - safe.right - 64)
        let panelHeight = min(285, size.height - safe.top - safe.bottom - 44)
        let panel = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 2)
        panel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        panel.fillColor = SKColor(red: 0.009, green: 0.019, blue: 0.04, alpha: 0.98)
        panel.strokeColor = SKColor.cyan.withAlphaComponent(0.72)
        panel.lineWidth = 1
        overlay.addChild(panel)

        let marker = SKShapeNode(rectOf: CGSize(width: 8, height: 8))
        marker.zRotation = .pi / 4
        marker.fillColor = .cyan
        marker.strokeColor = .clear
        marker.position = CGPoint(x: -panelWidth / 2 + 20, y: panelHeight / 2 - 20)
        panel.addChild(marker)
        let system = createNeonLabel(text: "MODE BRIEFING / 01", fontSize: 8, color: NeonColors.mutedText)
        system.horizontalAlignmentMode = .left
        system.position = CGPoint(x: -panelWidth / 2 + 35, y: panelHeight / 2 - 24)
        panel.addChild(system)
        let title = createNeonLabel(text: "INFINITE MODE", fontSize: 24, color: .white)
        title.position.y = panelHeight * 0.27
        panel.addChild(title)
        let subtitle = createNeonLabel(text: "SURVIVE • ADAPT • ESCALATE", fontSize: 8, color: .cyan)
        subtitle.position.y = panelHeight * 0.15
        panel.addChild(subtitle)

        let briefing = [
            "CLEAR EVERY HOSTILE TO ADVANCE THE TIER.",
            "THE ARENA SHIFTS BETWEEN WAVES.",
            "FACE ELITES, HIVES AND BOSSES AS THE RUN ESCALATES.",
            "COLLECT FLUX, FIND POWER-UPS AND CHASE A NEW HIGH SCORE."
        ]
        for (index, line) in briefing.enumerated() {
            let text = createNeonLabel(text: line, fontSize: 8, color: index == 3 ? NeonColors.green : NeonColors.mutedText)
            text.position.y = 25 - CGFloat(index) * 19
            if text.frame.width > panelWidth - 44 { text.setScale((panelWidth - 44) / text.frame.width) }
            panel.addChild(text)
        }

        let buttonWidth = (panelWidth - 58) / 2
        let start = NeonButton(title: "START RUN", size: CGSize(width: buttonWidth, height: 42), color: .cyan)
        start.name = "startInfinite"
        start.position = CGPoint(x: -buttonWidth / 2 - 5, y: -panelHeight / 2 + 32)
        panel.addChild(start)
        let back = NeonButton(title: "BACK", size: CGSize(width: buttonWidth, height: 42), color: NeonColors.purple)
        back.name = "closeBriefing"
        back.position = CGPoint(x: buttonWidth / 2 + 5, y: -panelHeight / 2 + 32)
        panel.addChild(back)
        overlay.alpha = 0
        overlay.run(.fadeIn(withDuration: 0.16))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        let names = nodes(at: point).compactMap { $0.name ?? $0.parent?.name }
        if modeBriefing != nil {
            if names.contains("startInfinite") {
                let scene = GameScene(size: size)
                scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: .fade(withDuration: 0.25))
            } else if names.contains("closeBriefing") {
                modeBriefing?.run(.sequence([.fadeOut(withDuration: 0.12), .removeFromParent()]))
                modeBriefing = nil
            }
            return
        }
        if names.contains("play") || names.contains("playPreview") {
            showInfiniteBriefing()
            return
        }
        if names.contains("storyMode") {
            let scene = StoryMissionSelectScene(size: size)
            scene.scaleMode = .resizeFill
            view?.presentScene(scene, transition: .fade(withDuration: 0.3))
            return
        }
        for node in nodes(at: point) {
            let name = node.name ?? node.parent?.name
            if name == "store" || name == "barracks" || name == "settings" {
                let scene: SKScene
                switch name {
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

        if prestige == 0 {
            buildStandardRank(level: level, band: rankBand, size: size,
                              primary: primary, secondary: secondary, locked: locked)
            return
        }

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

    private func buildStandardRank(level: Int, band: Int, size: CGFloat,
                                   primary: SKColor, secondary: SKColor, locked: Bool) {
        let shield = CGMutablePath()
        shield.move(to: CGPoint(x: 0, y: size * 0.48))
        shield.addLine(to: CGPoint(x: size * 0.39, y: size * 0.29))
        shield.addLine(to: CGPoint(x: size * 0.34, y: -size * 0.18))
        shield.addLine(to: CGPoint(x: 0, y: -size * 0.50))
        shield.addLine(to: CGPoint(x: -size * 0.34, y: -size * 0.18))
        shield.addLine(to: CGPoint(x: -size * 0.39, y: size * 0.29))
        shield.closeSubpath()
        let plate = SKShapeNode(path: shield)
        plate.fillColor = locked ? SKColor(white: 0.04, alpha: 0.96) : SKColor(red: 0.012, green: 0.025, blue: 0.055, alpha: 0.98)
        plate.strokeColor = primary
        plate.lineWidth = 1.5 + CGFloat(band) * 0.08
        plate.glowWidth = locked ? 0 : 3 + CGFloat(band) * 0.35
        addChild(plate)

        let inset = SKShapeNode(path: Self.polygon(sides: band >= 6 ? 6 : 4,
                                                   radius: size * 0.25,
                                                   rotation: .pi / 4))
        inset.fillColor = secondary.withAlphaComponent(locked ? 0.06 : 0.18)
        inset.strokeColor = primary.withAlphaComponent(0.75)
        inset.lineWidth = 1
        addChild(inset)

        if band >= 3 {
            for direction: CGFloat in [-1, 1] {
                let rail = CGMutablePath()
                rail.move(to: CGPoint(x: direction * size * 0.31, y: size * 0.22))
                rail.addLine(to: CGPoint(x: direction * size * (0.48 + CGFloat(band) * 0.012), y: size * 0.10))
                rail.addLine(to: CGPoint(x: direction * size * 0.34, y: -size * 0.05))
                let wing = SKShapeNode(path: rail)
                wing.strokeColor = primary
                wing.lineWidth = band >= 7 ? 2 : 1.2
                wing.glowWidth = locked ? 0 : 3
                wing.zPosition = -1
                addChild(wing)
            }
        }

        let chevrons = 1 + band % 3
        for index in 0..<chevrons {
            let y = -size * 0.18 - CGFloat(index) * size * 0.075
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -size * 0.17, y: y + size * 0.065))
            path.addLine(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size * 0.17, y: y + size * 0.065))
            let mark = SKShapeNode(path: path)
            mark.strokeColor = locked ? primary : .white
            mark.lineWidth = max(1, size * 0.022)
            mark.glowWidth = locked ? 0 : 2
            mark.zPosition = 2
            addChild(mark)
        }

        if band >= 6 {
            let crown = SKShapeNode(path: Self.star(points: min(8, 4 + band / 2),
                                                    outer: size * 0.19,
                                                    inner: size * 0.09,
                                                    rotation: -.pi / 2))
            crown.position.y = size * 0.15
            crown.fillColor = locked ? primary.withAlphaComponent(0.1) : .white
            crown.strokeColor = primary
            crown.lineWidth = 1
            crown.glowWidth = locked ? 0 : 4
            crown.zPosition = 2
            addChild(crown)
        } else {
            let core = SKShapeNode(path: Self.polygon(sides: 4, radius: size * 0.09, rotation: .pi / 4))
            core.position.y = size * 0.14
            core.fillColor = locked ? primary.withAlphaComponent(0.12) : .white
            core.strokeColor = primary
            core.glowWidth = locked ? 0 : 3
            core.zPosition = 2
            addChild(core)
        }

        let levelLabel = createNeonLabel(text: locked ? "?" : "\(level)",
                                         fontSize: max(7, size * 0.14),
                                         color: locked ? primary : .white)
        levelLabel.position.y = size * 0.01
        levelLabel.zPosition = 4
        addChild(levelLabel)
    }

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
        let insets = view?.safeAreaInsets ?? .zero
        let left = insets.left + 20
        let right = size.width - insets.right - 20
        let top = size.height - insets.top - 18
        let bottom = insets.bottom + 12
        let contentWidth = max(620, right - left)
        let gap: CGFloat = 12
        let rankWidth = contentWidth * 0.30
        let statsWidth = contentWidth - rankWidth - gap
        let panelsTop = top - 58
        let panelsBottom = bottom + 112
        let panelsHeight = max(150, panelsTop - panelsBottom)
        let panelsY = panelsBottom + panelsHeight / 2

        addLabel("BARRACKS", at: CGPoint(x: left + 76, y: top - 9), size: 23, color: .cyan)
        addLabel("CAREER RECORD  /  RANK PROGRESSION", at: CGPoint(x: left + 118, y: top - 32), size: 8, color: NeonColors.mutedText)

        let rankPanel = panel(size: CGSize(width: rankWidth, height: panelsHeight), color: .cyan)
        rankPanel.position = CGPoint(x: left + rankWidth / 2, y: panelsY)
        addChild(rankPanel)
        let emblem = RankEmblemNode(level: progress.rankLevel, size: min(108, panelsHeight * 0.48))
        emblem.position = CGPoint(x: 0, y: panelsHeight * 0.18)
        rankPanel.addChild(emblem)
        addPanelLabel("LEVEL \(progress.rankLevel)", to: rankPanel, y: -panelsHeight * 0.17, size: 16, color: .white)
        addPanelLabel(progress.rankTitle, to: rankPanel, y: -panelsHeight * 0.28, size: 8, color: .cyan)

        let trackWidth = rankWidth * 0.76
        let track = SKShapeNode(rectOf: CGSize(width: trackWidth, height: 7), cornerRadius: 3.5)
        track.position = CGPoint(x: 0, y: -panelsHeight * 0.39)
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
        addPanelLabel(xpText, to: rankPanel, y: -panelsHeight * 0.46, size: 7, color: NeonColors.mutedText)

        let statPanel = panel(size: CGSize(width: statsWidth, height: panelsHeight), color: NeonColors.purple)
        statPanel.position = CGPoint(x: left + rankWidth + gap + statsWidth / 2, y: panelsY)
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
        let cardWidth = statsWidth * 0.46
        let cardHeight = max(28, (panelsHeight - 32) / 4 - 5)
        let rowStep = cardHeight + 5
        let firstRowY = panelsHeight / 2 - cardHeight / 2 - 12
        for (index, stat) in stats.enumerated() {
            let column = index % 2, row = index / 2
            let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 2)
            card.position = CGPoint(x: (column == 0 ? -1 : 1) * statsWidth * 0.25,
                                    y: firstRowY - CGFloat(row) * rowStep)
            card.fillColor = SKColor(red: 0.015, green: 0.025, blue: 0.055, alpha: 0.92)
            card.strokeColor = (column == 0 ? SKColor.cyan : NeonColors.purple).withAlphaComponent(0.32)
            statPanel.addChild(card)
            let title = createNeonLabel(text: stat.0, fontSize: 7, color: NeonColors.mutedText)
            title.position.y = cardHeight * 0.22
            card.addChild(title)
            let value = createNeonLabel(text: stat.1, fontSize: 12, color: .white)
            value.position.y = -cardHeight * 0.20
            card.addChild(value)
        }

        addLabel("CENTURY EMBLEMS", at: CGPoint(x: left + 72, y: bottom + 94), size: 9, color: NeonColors.mutedText)
        for index in 1...10 {
            let milestone = index * 100
            let locked = progress.rankLevel < milestone
            let emblemSize = min(48, contentWidth / 13)
            let x = left + contentWidth * (CGFloat(index) - 0.5) / 10
            let emblem = RankEmblemNode(level: milestone, size: emblemSize, locked: locked)
            emblem.position = CGPoint(x: x, y: bottom + 47)
            addChild(emblem)
            addLabel("\(milestone)", at: CGPoint(x: x, y: bottom + 7), size: 7,
                     color: locked ? SKColor(white: 0.28, alpha: 1) : .white)
        }

        let back = NeonButton(title: "BACK", size: CGSize(width: 118, height: 36), color: .cyan)
        back.name = "back"
        back.position = CGPoint(x: right - 59, y: top - 10)
        back.zPosition = 8
        addChild(back)
    }

    private func panel(size: CGSize, color: SKColor) -> SKShapeNode {
        let node = SKShapeNode(rectOf: size, cornerRadius: 2)
        node.fillColor = NeonColors.panel.withAlphaComponent(0.95)
        node.strokeColor = color.withAlphaComponent(0.38)
        node.lineWidth = 1.5
        node.glowWidth = 0
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
        let preview = SKShapeNode(rectOf: CGSize(width: previewWidth, height: size.height * 0.54), cornerRadius: 2)
        preview.position = CGPoint(x: 36 + previewWidth / 2, y: size.height * 0.48)
        preview.fillColor = NeonColors.panel
        preview.strokeColor = NeonColors.purple.withAlphaComponent(0.45)
        preview.glowWidth = 0
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
        let haptics = SKShapeNode(rectOf: CGSize(width: previewWidth - 22, height: 32), cornerRadius: 2)
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
            let card = SKShapeNode(rectOf: CGSize(width: width, height: 62), cornerRadius: 2)
            card.name = mode.rawValue
            card.position = CGPoint(x: contentLeft + width / 2, y: size.height - 105 - CGFloat(index) * 72)
            card.fillColor = selected ? SKColor.cyan.withAlphaComponent(0.10) : NeonColors.panel
            card.strokeColor = selected ? .cyan : NeonColors.mutedText.withAlphaComponent(0.26)
            card.lineWidth = selected ? 1.7 : 1
            card.glowWidth = selected ? 1 : 0
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
