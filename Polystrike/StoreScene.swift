import SpriteKit

final class StoreScene: SKScene {
    private var category = 0
    private var previewShip = PlayerProgress.shared.selectedShip
    private var notice = "PERMANENT UPGRADES • TAP A CARD TO INSTALL"
    private let groups: [[ShipUpgrade]] = [[.fire, .damage, .doubleShot, .bomb], [.health, .armor, .repair, .dash], [.speed, .magnet, .salvage]]

    override func didMove(to view: SKView) { rebuild() }
    override func didChangeSize(_ oldSize: CGSize) { if view != nil { rebuild() } }

    private func rebuild() {
        removeAllChildren()
        createNeonBackground(for: self, gridSpacing: 55)
        addInterfaceAtmosphere(to: self)
        let progress = PlayerProgress.shared
        label(category == 3 ? "SHIP VAULT" : "SHIP ARMORY", at: CGPoint(x: size.width * 0.20, y: size.height - 39), font: 22, color: .cyan)
        label(category == 3 ? "COLLECT • EQUIP • DOMINATE" : "LOADOUT ENGINEERING / PERMANENT SYSTEMS", at: CGPoint(x: size.width * 0.20, y: size.height - 61), font: 8, color: NeonColors.mutedText)
        let headerRail = SKShapeNode(rectOf: CGSize(width: size.width * 0.52, height: 1))
        headerRail.position = CGPoint(x: size.width * 0.54, y: size.height - 61)
        headerRail.fillColor = SKColor.cyan.withAlphaComponent(0.22)
        headerRail.strokeColor = .clear
        addChild(headerRail)
        let headerMarker = SKShapeNode(rectOf: CGSize(width: 7, height: 7))
        headerMarker.position = CGPoint(x: size.width * 0.28, y: size.height - 61)
        headerMarker.zRotation = .pi / 4
        headerMarker.fillColor = .cyan
        headerMarker.strokeColor = .clear
        addChild(headerMarker)

        let wallet = SKShapeNode(rectOf: CGSize(width: 176, height: 34), cornerRadius: 2)
        wallet.position = CGPoint(x: size.width - 109, y: size.height - 43)
        wallet.fillColor = SKColor(red: 0.008, green: 0.025, blue: 0.022, alpha: 0.96)
        wallet.strokeColor = NeonColors.green.withAlphaComponent(0.45)
        wallet.lineWidth = 0.8
        wallet.glowWidth = 0
        addChild(wallet)
        wallet.addChild(createNeonLabel(text: "◈  \(formatted(progress.flux)) FLUX", fontSize: 11, color: NeonColors.green))
        addTechnicalCorners(to: wallet, size: CGSize(width: 176, height: 34), color: NeonColors.green)

        addPreview(progress: progress)
        addTabs()
        if category == 3 { addShipCards(progress: progress) } else { addUpgradeCards(progress: progress) }

        let back = NeonButton(title: "BACK", size: CGSize(width: 122, height: 38), color: .cyan)
        back.name = "back"
        back.position = CGPoint(x: size.width * 0.23, y: 53)
        for shape in back.children.compactMap({ $0 as? SKShapeNode }) { shape.glowWidth = 1.5 }
        addChild(back)
        label(notice, at: CGPoint(x: size.width / 2, y: 25), font: 8, color: NeonColors.mutedText)
    }

    private func addPreview(progress: PlayerProgress) {
        let panelSize = CGSize(width: size.width * 0.27, height: size.height * 0.57)
        let panel = SKShapeNode(rectOf: panelSize, cornerRadius: 2)
        panel.position = CGPoint(x: size.width * 0.23, y: size.height * 0.49)
        panel.fillColor = SKColor(red: 0.007, green: 0.014, blue: 0.027, alpha: 0.97)
        panel.strokeColor = (category == 3 ? shipColor(previewShip) : .cyan).withAlphaComponent(0.35)
        panel.lineWidth = 0.8
        panel.glowWidth = 0
        addChild(panel)
        addTechnicalCorners(to: panel, size: panelSize, color: category == 3 ? shipColor(previewShip) : .cyan)
        let previewID = createNeonLabel(text: category == 3 ? "FRAME / \(String(format: "%02d", ShipStyle.allCases.firstIndex(of: previewShip)! + 1))" : "SYSTEM CORE / LIVE", fontSize: 7, color: NeonColors.mutedText)
        previewID.horizontalAlignmentMode = .left
        previewID.position = CGPoint(x: -panelSize.width / 2 + 12, y: panelSize.height / 2 - 15)
        panel.addChild(previewID)
        for radius: CGFloat in [37, 54] {
            let ring = SKShapeNode(circleOfRadius: radius)
            ring.yScale = 0.62
            ring.strokeColor = shipColor(previewShip).withAlphaComponent(radius == 37 ? 0.34 : 0.18)
            ring.lineWidth = 1
            ring.position = CGPoint(x: 0, y: 17)
            panel.addChild(ring)
            ring.run(.repeatForever(.sequence([.fadeAlpha(to: 0.25, duration: 1.4), .fadeAlpha(to: 0.9, duration: 1.4)])))
        }
        let ship = Player(style: category == 3 ? previewShip : progress.selectedShip)
        ship.physicsBody = nil
        ship.position = CGPoint(x: 0, y: 17)
        ship.setScale(category == 3 ? 1.35 : 1.25)
        panel.addChild(ship)
        ship.run(.repeatForever(.sequence([
            .group([.moveBy(x: 7, y: 4, duration: 1.6), .rotate(toAngle: 0.07, duration: 1.6)]),
            .group([.moveBy(x: -7, y: -4, duration: 1.6), .rotate(toAngle: -0.04, duration: 1.6)])
        ])))
        if category == 3 {
            label(previewShip.title, at: CGPoint(x: size.width * 0.23, y: size.height * 0.325), font: 10, color: shipColor(previewShip))
            label(previewShip.subtitle, at: CGPoint(x: size.width * 0.23, y: size.height * 0.285), font: 7, color: NeonColors.mutedText)
            let status = progress.selectedShip == previewShip ? "◆ EQUIPPED" : (progress.owns(previewShip) ? "◇ OWNED" : "LOCKED")
            label(status, at: CGPoint(x: size.width * 0.23, y: size.height * 0.245), font: 8, color: progress.owns(previewShip) ? NeonColors.green : NeonColors.mutedText)
        } else {
            label("PERMANENT LOADOUT", at: CGPoint(x: size.width * 0.23, y: size.height * 0.315), font: 10, color: .white)
            label("SELECT A SYSTEM TO UPGRADE", at: CGPoint(x: size.width * 0.23, y: size.height * 0.275), font: 7, color: NeonColors.mutedText)
        }
    }

    private func addTabs() {
        for (index, title) in ["WEAPONS", "DEFENSE", "UTILITY", "SHIPS"].enumerated() {
            let width = size.width * 0.122
            let tab = SKShapeNode(rectOf: CGSize(width: width, height: 30), cornerRadius: 1)
            tab.name = "tab\(index)"
            tab.position = CGPoint(x: size.width * (0.493 + CGFloat(index) * 0.132), y: size.height - 78)
            tab.fillColor = index == category ? SKColor.cyan.withAlphaComponent(0.07) : SKColor.black.withAlphaComponent(0.55)
            tab.strokeColor = index == category ? .cyan : NeonColors.mutedText.withAlphaComponent(0.2)
            tab.lineWidth = 0.7
            let glyph = ["✦", "⬡", "◇", "◆"][index]
            let titleLabel = createNeonLabel(text: "\(glyph) \(title)", fontSize: 8, color: index == category ? .cyan : NeonColors.mutedText)
            tab.addChild(titleLabel); addChild(tab)
            if index == category {
                let marker = SKShapeNode(rectOf: CGSize(width: 6, height: 6))
                marker.position.x = -width / 2 + 9
                marker.zRotation = .pi / 4
                marker.fillColor = .cyan
                marker.strokeColor = .clear
                tab.addChild(marker)
            }
            if index == category { tab.run(.repeatForever(.sequence([.fadeAlpha(to: 0.72, duration: 0.8), .fadeAlpha(to: 1, duration: 0.8)]))) }
        }
    }

    private func addUpgradeCards(progress: PlayerProgress) {
        let width = size.width * 0.52
        let step = min(65, (size.height - 133) / 4)
        for (index, upgrade) in groups[category].enumerated() {
            let level = progress.level(upgrade), maxed = level >= upgrade.cap
            let card = SKShapeNode(rectOf: CGSize(width: width, height: step - 6), cornerRadius: 2)
            card.name = "upgrade\(index)"
            card.position = CGPoint(x: size.width * 0.687, y: size.height - 124 - CGFloat(index) * step)
            card.fillColor = SKColor(red: 0.008, green: 0.015, blue: 0.03, alpha: 0.96)
            card.strokeColor = maxed ? NeonColors.green.withAlphaComponent(0.35) : (progress.flux >= progress.cost(upgrade) ? .cyan.withAlphaComponent(0.6) : NeonColors.mutedText.withAlphaComponent(0.3))
            addChild(card)
            let accent = SKShapeNode(rectOf: CGSize(width: 3, height: step - 16))
            accent.position.x = -width / 2 + 5
            accent.fillColor = maxed ? NeonColors.green : (progress.flux >= progress.cost(upgrade) ? .cyan : NeonColors.mutedText)
            accent.strokeColor = .clear
            card.addChild(accent)
            let heading = createNeonLabel(text: "\(upgrade.title)  \(level)/\(upgrade.cap)", fontSize: 10, color: .white)
            heading.horizontalAlignmentMode = .left; heading.position = CGPoint(x: -width / 2 + 12, y: 11); card.addChild(heading)
            let effect = createNeonLabel(text: maxed ? upgrade.effect(at: level) : upgrade.effect(at: level) + " → " + upgrade.effect(at: level + 1), fontSize: 9, color: NeonColors.mutedText)
            effect.horizontalAlignmentMode = .left; effect.position = CGPoint(x: -width / 2 + 12, y: -10)
            if effect.frame.width > width - 105 { effect.setScale((width - 105) / effect.frame.width) }
            card.addChild(effect)
            let price = createNeonLabel(text: maxed ? "MAX" : "◈ \(progress.cost(upgrade))", fontSize: 10, color: NeonColors.green)
            price.horizontalAlignmentMode = .right; price.position = CGPoint(x: width / 2 - 12, y: -10); card.addChild(price)
            let progressWidth = width - 24
            let track = SKShapeNode(rectOf: CGSize(width: progressWidth, height: 1))
            track.position = CGPoint(x: 0, y: -(step - 6) / 2 + 5)
            track.fillColor = SKColor.white.withAlphaComponent(0.08)
            track.strokeColor = .clear
            card.addChild(track)
            let ratio = CGFloat(level) / CGFloat(max(1, upgrade.cap))
            let fillWidth = max(1, progressWidth * ratio)
            let fill = SKShapeNode(rectOf: CGSize(width: fillWidth, height: 1.5))
            fill.position.x = -progressWidth / 2 + fillWidth / 2
            fill.fillColor = maxed ? NeonColors.green : .cyan
            fill.strokeColor = .clear
            track.addChild(fill)
        }
    }

    private func addShipCards(progress: PlayerProgress) {
        let styles = ShipStyle.allCases
        // Keep the complete vault grid inside the space between the tabs and
        // footer controls. The previous percentage positions let the final row
        // drift into the bottom navigation on shorter iPhones.
        let contentLeft = size.width * 0.425
        let contentRight = size.width * 0.955
        let columnGap = max(8, size.width * 0.012)
        let cardWidth = (contentRight - contentLeft - columnGap) / 2
        let contentTop = size.height - 101
        let contentBottom = max(82, size.height * 0.205)
        let rowGap: CGFloat = 7
        let cardHeight = min(70, (contentTop - contentBottom - rowGap * 2) / 3)
        let firstCenterY = contentTop - cardHeight / 2
        for (index, style) in styles.enumerated() {
            let row = index / 2, column = index % 2
            let selected = previewShip == style
            let owned = progress.owns(style)
            let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 2)
            card.name = "ship\(index)"
            card.position = CGPoint(
                x: contentLeft + cardWidth / 2 + CGFloat(column) * (cardWidth + columnGap),
                y: firstCenterY - CGFloat(row) * (cardHeight + rowGap)
            )
            card.fillColor = selected ? shipColor(style).withAlphaComponent(0.08) : SKColor(red: 0.008, green: 0.015, blue: 0.03, alpha: 0.96)
            card.strokeColor = selected ? shipColor(style) : (owned ? NeonColors.green.withAlphaComponent(0.5) : NeonColors.mutedText.withAlphaComponent(0.28))
            card.lineWidth = selected ? 1.2 : 0.7
            card.glowWidth = selected ? 1 : 0
            addChild(card)
            let selector = SKShapeNode(rectOf: CGSize(width: 6, height: 6))
            selector.position = CGPoint(x: -cardWidth / 2 + 9, y: cardHeight / 2 - 9)
            selector.zRotation = .pi / 4
            selector.fillColor = selected ? shipColor(style) : NeonColors.mutedText.withAlphaComponent(0.35)
            selector.strokeColor = .clear
            card.addChild(selector)
            let miniature = Player(style: style); miniature.physicsBody = nil; miniature.setScale(0.52)
            miniature.position = CGPoint(x: -cardWidth / 2 + 28, y: 1); card.addChild(miniature)
            let title = createNeonLabel(text: style.title, fontSize: 8, color: owned ? .white : shipColor(style))
            title.horizontalAlignmentMode = .left; title.position = CGPoint(x: -cardWidth / 2 + 52, y: 10); card.addChild(title)
            let state: String
            if progress.selectedShip == style { state = "EQUIPPED" }
            else if owned { state = "TAP TO EQUIP" }
            else { state = "◈ \(formatted(style.price))" }
            let status = createNeonLabel(text: state, fontSize: 7, color: owned ? NeonColors.green : NeonColors.mutedText)
            status.horizontalAlignmentMode = .left; status.position = CGPoint(x: -cardWidth / 2 + 52, y: -10); card.addChild(status)
        }
    }

    private func label(_ text: String, at position: CGPoint, font: CGFloat, color: SKColor) {
        let node = createNeonLabel(text: text, fontSize: font, color: color)
        node.position = position; addChild(node)
    }

    private func addTechnicalCorners(to node: SKNode, size: CGSize, color: SKColor) {
        let length: CGFloat = 11
        for x: CGFloat in [-1, 1] {
            for y: CGFloat in [-1, 1] {
                let path = CGMutablePath()
                let corner = CGPoint(x: x * size.width / 2, y: y * size.height / 2)
                path.move(to: CGPoint(x: corner.x - x * length, y: corner.y))
                path.addLine(to: corner)
                path.addLine(to: CGPoint(x: corner.x, y: corner.y - y * length))
                let bracket = SKShapeNode(path: path)
                bracket.strokeColor = color.withAlphaComponent(0.85)
                bracket.lineWidth = 1.2
                bracket.glowWidth = 1
                node.addChild(bracket)
            }
        }
    }

    private func formatted(_ amount: Int) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: max(0, amount)), number: .decimal)
    }

    private func shipColor(_ style: ShipStyle) -> SKColor {
        switch style { case .striker: return .cyan; case .viper: return NeonColors.green; case .spectre: return NeonColors.purple; case .nova: return NeonColors.orange; case .eclipse: return NeonColors.pink; case .sovereign: return .white }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        for node in nodes(at: point) {
            let name = node.name ?? node.parent?.name ?? ""
            if name == "back" {
                let scene = MainMenuScene(size: size); scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: .fade(withDuration: 0.2)); return
            }
            if name.hasPrefix("tab"), let index = Int(name.dropFirst(3)), (0..<4).contains(index) {
                category = index
                if index == 3 { previewShip = PlayerProgress.shared.selectedShip; notice = "SELECT A FRAME • OWNED SHIPS EQUIP INSTANTLY" }
                else { notice = index == 1 ? "REPAIR STARTS AFTER 4s UNHARMED • DASH GRANTS BRIEF INVULNERABILITY" : "PERMANENT UPGRADES • TAP A CARD TO INSTALL" }
                rebuild(); return
            }
            if category == 3, name.hasPrefix("ship"), let index = Int(name.dropFirst(4)), ShipStyle.allCases.indices.contains(index) {
                let style = ShipStyle.allCases[index]
                previewShip = style
                let progress = PlayerProgress.shared
                if progress.owns(style) {
                    _ = progress.selectShip(style)
                    notice = "\(style.title) EQUIPPED"
                } else if progress.buyShip(style) {
                    notice = "\(style.title) UNLOCKED + EQUIPPED"
                } else {
                    notice = "NEED \(formatted(style.price - progress.flux)) MORE FLUX"
                }
                rebuild(); return
            }
            if category < groups.count, name.hasPrefix("upgrade"), let index = Int(name.dropFirst(7)), groups[category].indices.contains(index) {
                let upgrade = groups[category][index]
                let progress = PlayerProgress.shared
                if progress.level(upgrade) >= upgrade.cap { notice = "SYSTEM FULLY UPGRADED" }
                else if progress.buy(upgrade) { notice = "\(upgrade.title) INSTALLED" + ([ShipUpgrade.dash, .bomb].contains(upgrade) ? " • TAP ITS BUTTON DURING A RUN" : "") }
                else { notice = "NEED \(formatted(progress.cost(upgrade) - progress.flux)) MORE FLUX" }
                rebuild(); return
            }
        }
    }
}
