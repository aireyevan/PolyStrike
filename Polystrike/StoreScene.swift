import SpriteKit

final class StoreScene: SKScene {
    var progress=PlayerProgress.shared
    private(set) var pendingShip:ShipStyle?
    private(set) var pendingUpgrade:ShipUpgrade?
    private var category = 0
    private var previewShip = PlayerProgress.shared.selectedShip
    private var notice = "SELECT A SYSTEM • REVIEW THE NEXT UPGRADE"
    private let groups: [[ShipUpgrade]] = [[.fire,.damage,.doubleShot,.tripleShot,.quadShot,.bomb],[.health,.armor,.repair,.dash],[.speed,.magnet,.salvage]]
    override func didMove(to view: SKView) { rebuild() }
    override func didChangeSize(_ oldSize: CGSize) { if view != nil { rebuild();if pendingShip != nil || pendingUpgrade != nil {review(ship:pendingShip,upgrade:pendingUpgrade)} } }

    private func rebuild() {
        removeAllChildren(); createNeonBackground(for:self); addInterfaceAtmosphere(to:self)
        let b = menuBounds(self), progress = self.progress
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
                let card = armorPanel(size:CGSize(width:cardWidth,height:cardHeight),color:shipColor(frame),selected:previewShip == frame)
                card.name = "ship\(index)"; card.position = center; addChild(card)
                let miniature = Player(style:frame); miniature.physicsBody = nil; miniature.setScale(0.6)
                miniature.position.x = -cardWidth/2+24; card.addChild(miniature)
                menuText(frame.title,on:card,at:CGPoint(x:-cardWidth/2+47,y:10),size:9,width:cardWidth-57)
                let status = progress.selectedShip == frame ? "EQUIPPED" : (owned ? "REVIEW / EQUIP" : "VIEW • ◈ \(formatted(frame.price))")
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
                menuText(maxed ? "INSTALLED" : "◈ \(formatted(progress.cost(upgrade)))",on:card,at:CGPoint(x:left,y:-cardHeight/2+17),size:9,color:maxed ? NeonColors.green : (available ? .white : NeonColors.mutedText),width:cardWidth-24)
            }
                if category != 3 {
                    let upgrade=groups[category][index]
                    let bar=menuProgressBar(width:cardWidth-24,ratio:CGFloat(progress.level(upgrade))/CGFloat(upgrade.cap),color:NeonColors.orange,height:3)
                    bar.name="upgradeProgress\(index)";bar.position=CGPoint(x:center.x-cardWidth/2+12,y:center.y-cardHeight/2+6);addChild(bar)
                }
        }
        menuText(notice,on:self,at:CGPoint(x:rightX,y:b.minY+10),size:8,color:NeonColors.mutedText,width:rightWidth)
    }
    private func formatted(_ amount: Int) -> String { NumberFormatter.localizedString(from:NSNumber(value:max(0,amount)),number:.decimal) }
    private func shipColor(_ style: ShipStyle) -> SKColor {
        switch style { case .striker:return .cyan; case .viper:return NeonColors.green; case .spectre:return NeonColors.purple; case .nova:return NeonColors.orange; case .eclipse:return NeonColors.pink; case .sovereign:return .white }
    }
    override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?) {
        guard let point=touches.first?.location(in:self) else{return}
        let modal=childNode(withName:"purchaseReview")
        for name in menuActionNames(at:modal?.convert(point,from:self) ?? point,in:modal ?? self) {
            if handleAction(name) {return}
        }
    }
    @discardableResult func handleAction(_ name:String)->Bool {
        if pendingShip != nil || pendingUpgrade != nil {
            if name=="cancelPurchase" {pendingShip=nil;pendingUpgrade=nil;childNode(withName:"purchaseReview")?.removeFromParent();return true}
            if name=="confirmPurchase" {
                if let ship=pendingShip {
                    let success=progress.owns(ship) ? progress.selectShip(ship) : progress.buyShip(ship)
                    notice=success ? "\(ship.title) EQUIPPED" : "NOT ENOUGH FLUX • PURCHASE CANCELLED"
                } else if let upgrade=pendingUpgrade {
                    notice=progress.buy(upgrade) ? "\(upgrade.title) INSTALLED" : "UPGRADE UNAVAILABLE • NO FLUX SPENT"
                }
                pendingShip=nil;pendingUpgrade=nil;rebuild();return true
            }
            return false
        }
        if name=="back" {let scene=MainMenuScene(size:size);scene.scaleMode = .resizeFill;view?.presentScene(scene,transition:.fade(withDuration:0.2));return true}
        if name.hasPrefix("tab"),let index=Int(name.dropFirst(3)),(0..<4).contains(index) {
            category=index;notice=index==3 ? "SELECT A FRAME • REVIEW BEFORE PURCHASING" : "SELECT A SYSTEM • REVIEW THE NEXT UPGRADE";rebuild();return true
        }
        if category==3,name.hasPrefix("ship"),let index=Int(name.dropFirst(4)),ShipStyle.allCases.indices.contains(index) {
            previewShip=ShipStyle.allCases[index];rebuild();review(ship:previewShip);return true
        }
        if category<groups.count,name.hasPrefix("upgrade"),let index=Int(name.dropFirst(7)),groups[category].indices.contains(index) {
            let upgrade=groups[category][index]
            if progress.level(upgrade)>=upgrade.cap {notice="SYSTEM FULLY UPGRADED";rebuild()}
            else if upgrade == .tripleShot && !progress.doubleShotUnlocked {notice="INSTALL DOUBLE SHOT FIRST";rebuild()}
            else if upgrade == .quadShot && !progress.tripleShotUnlocked {notice="INSTALL TRIPLE SHOT FIRST";rebuild()}
            else {review(upgrade:upgrade)}
            return true
        }
        return false
    }
    func review(ship:ShipStyle?=nil,upgrade:ShipUpgrade?=nil) {
        pendingShip=ship;pendingUpgrade=upgrade
        childNode(withName:"purchaseReview")?.removeFromParent()
        let b=menuBounds(self),w=min(430,b.width),h=min(292,b.height)
        let shade=SKShapeNode(rectOf:size);shade.fillColor=SKColor.black.withAlphaComponent(0.92);shade.strokeColor = .clear
        shade.name="purchaseReview";shade.position=CGPoint(x:size.width/2,y:size.height/2);shade.zPosition=1000;addChild(shade)
        let panel=armorPanel(size:CGSize(width:w,height:h),color:NeonColors.orange,selected:true);shade.addChild(panel)
        let owned=ship.map {progress.owns($0)} ?? false
        let price=ship.map {owned ? 0:$0.price} ?? upgrade.map {progress.cost($0)} ?? 0
        let title=ship?.title ?? upgrade?.title ?? "REVIEW"
        menuText(title,on:panel,at:CGPoint(x:0,y:h/2-24),size:16,align:.center,width:w-32)
        if let ship {
            let art=Player(style:ship);art.physicsBody=nil;art.position.y=h*0.13;art.setScale(min(1.3,h/210));panel.addChild(art)
            menuText(ship.subtitle,on:panel,at:CGPoint(x:0,y:-h*0.08),size:9,color:NeonColors.mutedText,align:.center,width:w-30)
        } else if let upgrade {
            let level=progress.level(upgrade)
            menuText("LEVEL \(level) → \(level+1) / \(upgrade.cap)",on:panel,at:CGPoint(x:0,y:h*0.2),size:12,align:.center)
            menuText("NOW  \(upgrade.effect(at:level))",on:panel,at:CGPoint(x:0,y:h*0.09),size:10,color:NeonColors.mutedText,align:.center)
            menuText("NEXT  \(upgrade.effect(at:level+1))",on:panel,at:CGPoint(x:0,y:-h*0.02),size:11,color:NeonColors.green,align:.center)
            let bar=menuProgressBar(width:w-48,ratio:CGFloat(level)/CGFloat(upgrade.cap),color:NeonColors.orange)
            bar.position=CGPoint(x:-w/2+24,y:-h*0.1);panel.addChild(bar)
        }
        let affordable=progress.flux>=price
        menuText(price==0 ? "OWNED • EQUIP THIS FRAME" : "COST  ◈ \(formatted(price)) FLUX",on:panel,at:CGPoint(x:0,y:-h*0.22),size:12,color:affordable ? .white:NeonColors.orange,align:.center,width:w-32)
        menuText(affordable ? "BALANCE AFTER: \(formatted(progress.flux-price)) FLUX" : "NEED \(formatted(price-progress.flux)) MORE FLUX",on:panel,at:CGPoint(x:0,y:-h*0.31),size:9,color:NeonColors.mutedText,align:.center,width:w-32)
        for (i,title) in ["CANCEL",affordable ? (owned ? "EQUIP SHIP":"CONFIRM PURCHASE") : "INSUFFICIENT FLUX"].enumerated() {
            let button=NeonButton(title:title,size:CGSize(width:(w-42)/2,height:34),color:i==0 ? .gray:NeonColors.green)
            button.name=i==0 ? "cancelPurchase" : (affordable ? "confirmPurchase":"unavailablePurchase")
            button.alpha=i==1 && !affordable ? 0.45:1;button.position=CGPoint(x:(i==0 ? -1:1)*(w-18)/4,y:-h/2+25);panel.addChild(button)
        }
    }
}
