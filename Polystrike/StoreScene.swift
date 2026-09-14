import SpriteKit

final class StoreScene: SKScene {
    private var category = 0
    private var previewShip = PlayerProgress.shared.selectedShip
    private var notice = "PERMANENT UPGRADES • TAP A CARD TO INSTALL"
    private let groups: [[ShipUpgrade]] = [[.fire,.damage,.doubleShot,.tripleShot,.quadShot,.bomb],[.health,.armor,.repair,.dash],[.speed,.magnet,.salvage]]
    override func didMove(to view: SKView) { rebuild() }
    override func didChangeSize(_ oldSize: CGSize) { if view != nil { rebuild() } }

    private func rebuild() {
        removeAllChildren(); createNeonBackground(for:self); addInterfaceAtmosphere(to:self)
        let b = menuBounds(self), progress = PlayerProgress.shared
        menuHeader(category == 3 ? "SHIP VAULT" : "ARMORY",subtitle:"BUILD YOUR EDGE / PERMANENT UPGRADES",on:self,bounds:b,color:NeonColors.orange)
        let wallet = armorPanel(size:CGSize(width:175,height:36),color:NeonColors.green)
        wallet.position = CGPoint(x:b.maxX-87.5,y:b.maxY-16); addChild(wallet)
        menuText("◈  \(formatted(progress.flux)) FLUX",on:wallet,at:.zero,size:11,color:NeonColors.green,align:.center,width:151)
        let previewWidth = b.width*0.29, rightWidth = b.width-previewWidth-14
        let rightX = b.minX+previewWidth+14
        let panelHeight = b.height-108
        let preview = armorPanel(size:CGSize(width:previewWidth,height:panelHeight),color:NeonColors.orange)
        preview.position = CGPoint(x:b.minX+previewWidth/2,y:b.minY+48+panelHeight/2); addChild(preview)
        let style = category == 3 ? previewShip : progress.selectedShip
        menuText("EQUIPMENT BAY",on:preview,at:CGPoint(x:0,y:panelHeight/2-18),size:8,color:NeonColors.mutedText,align:.center)
        let ring = SKShapeNode(circleOfRadius:min(previewWidth*0.30,panelHeight*0.26))
        ring.yScale = 0.66; ring.position.y = 14; ring.strokeColor = shipColor(style).withAlphaComponent(0.4); ring.lineWidth = 1; preview.addChild(ring)
        let ship = Player(style:style); ship.physicsBody = nil; ship.setScale(min(1.55,panelHeight/125)); ship.position.y = 18; preview.addChild(ship)
        ship.run(.repeatForever(.sequence([.moveBy(x:0,y:5,duration:1.5),.moveBy(x:0,y:-5,duration:1.5)])))
        menuText(style.title,on:preview,at:CGPoint(x:0,y:-panelHeight/2+54),size:12,color:shipColor(style),align:.center,width:previewWidth-20)
        let state = progress.selectedShip == style ? "EQUIPPED" : (progress.owns(style) ? "OWNED" : "LOCKED FRAME")
        menuText(category == 3 ? state : "PERMANENT LOADOUT",on:preview,at:CGPoint(x:0,y:-panelHeight/2+32),size:8,color:NeonColors.mutedText,align:.center)
        let back = NeonButton(title:"BACK",size:CGSize(width:previewWidth,height:36),color:.cyan)
        back.name = "back"; back.position = CGPoint(x:b.minX+previewWidth/2,y:b.minY+23); addChild(back)
        let tabWidth = (rightWidth-18)/4
        for (index,title) in ["WEAPONS","DEFENSE","UTILITY","SHIPS"].enumerated() {
            let tab = armorPanel(size:CGSize(width:tabWidth,height:34),color:NeonColors.orange,selected:index == category)
            tab.name = "tab\(index)"; tab.position = CGPoint(x:rightX+tabWidth/2+CGFloat(index)*(tabWidth+6),y:b.maxY-77); addChild(tab)
            menuText(title,on:tab,at:.zero,size:9,color:index == category ? .white : NeonColors.mutedText,align:.center,width:tabWidth-14)
        }
        let gridTop = b.maxY-104, gridBottom = b.minY+30
        let rows = category == 0 || category == 3 ? 3 : 2
        let gap: CGFloat = 8, cardWidth = (rightWidth-gap)/2
        let cardHeight = (gridTop-gridBottom-CGFloat(rows-1)*gap)/CGFloat(rows)
        let count = category == 3 ? ShipStyle.allCases.count : groups[category].count
        for index in 0..<count {
            let center = CGPoint(x:rightX+cardWidth/2+CGFloat(index%2)*(cardWidth+gap),y:gridTop-cardHeight/2-CGFloat(index/2)*(cardHeight+gap))
            if category == 3 {
                let frame = ShipStyle.allCases[index], owned = progress.owns(frame)
                let card = armorPanel(size:CGSize(width:cardWidth,height:cardHeight),color:shipColor(frame),selected:progress.selectedShip == frame)
                card.name = "ship\(index)"; card.position = center; addChild(card)
                let miniature = Player(style:frame); miniature.physicsBody = nil; miniature.setScale(0.6)
                miniature.position.x = -cardWidth/2+24; card.addChild(miniature)
                menuText(frame.title,on:card,at:CGPoint(x:-cardWidth/2+47,y:10),size:9,width:cardWidth-57)
                let status = progress.selectedShip == frame ? "EQUIPPED" : (owned ? "TAP TO EQUIP" : "◈ \(formatted(frame.price))")
                menuText(status,on:card,at:CGPoint(x:-cardWidth/2+47,y:-10),size:8,color:owned ? NeonColors.green : NeonColors.mutedText,width:cardWidth-57)
            } else {
                let upgrade = groups[category][index], level = progress.level(upgrade), maxed = level >= upgrade.cap
                let available = progress.flux >= progress.cost(upgrade)
                let card = armorPanel(size:CGSize(width:cardWidth,height:cardHeight),color:maxed ? NeonColors.green : NeonColors.orange)
                card.name = "upgrade\(index)"; card.position = center; addChild(card)
                let left = -cardWidth/2+12
                menuText(upgrade.title,on:card,at:CGPoint(x:left,y:cardHeight/2-15),size:9,width:cardWidth-65)
                menuText("\(level)/\(upgrade.cap)",on:card,at:CGPoint(x:cardWidth/2-12,y:cardHeight/2-15),size:8,color:NeonColors.mutedText,align:.right)
                let needsDouble = upgrade == .tripleShot && !progress.doubleShotUnlocked
                let needsTriple = upgrade == .quadShot && !progress.tripleShotUnlocked
                let effect = needsDouble ? "Requires Double Shot" : (needsTriple ? "Requires Triple Shot" : upgrade.effect(at:maxed ? level : level+1))
                menuText(effect,on:card,at:CGPoint(x:left,y:0),size:8,color:NeonColors.mutedText,width:cardWidth-24)
                menuText(maxed ? "INSTALLED" : "◈ \(formatted(progress.cost(upgrade)))",on:card,at:CGPoint(x:left,y:-cardHeight/2+13),size:9,color:maxed ? NeonColors.green : (available ? .white : NeonColors.mutedText),width:cardWidth-24)
            }
        }
        menuText(notice,on:self,at:CGPoint(x:rightX,y:b.minY+10),size:8,color:NeonColors.mutedText,width:rightWidth)
    }
    private func formatted(_ amount: Int) -> String { NumberFormatter.localizedString(from:NSNumber(value:max(0,amount)),number:.decimal) }
    private func shipColor(_ style: ShipStyle) -> SKColor {
        switch style { case .striker:return .cyan; case .viper:return NeonColors.green; case .spectre:return NeonColors.purple; case .nova:return NeonColors.orange; case .eclipse:return NeonColors.pink; case .sovereign:return .white }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        for name in menuActionNames(at:point,in:self) {
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
                else if upgrade == .tripleShot && !progress.doubleShotUnlocked { notice = "DOUBLE SHOT REQUIRED FIRST" }
                else if upgrade == .quadShot && !progress.tripleShotUnlocked { notice = "TRIPLE SHOT REQUIRED FIRST" }
                else if progress.buy(upgrade) { notice = "\(upgrade.title) INSTALLED" + ([ShipUpgrade.dash, .bomb].contains(upgrade) ? " • TAP ITS BUTTON DURING A RUN" : "") }
                else { notice = "NEED \(formatted(progress.cost(upgrade) - progress.flux)) MORE FLUX" }
                rebuild(); return
            }
        }
    }
}
