import SpriteKit
import UIKit
import AVFoundation

final class MainMenuScene: SKScene {
    private var modeBriefing: SKNode?
    private var previewPlayer: AVQueuePlayer?
    private var previewLooper: AVPlayerLooper?
    private var previewTask: Task<Void,Never>?

    override func willMove(from view:SKView) {stopMoviePreview()}
    private func stopMoviePreview() {
        previewTask?.cancel();previewTask=nil
        previewPlayer?.pause();previewLooper?.disableLooping();previewLooper=nil
        previewPlayer?.removeAllItems();previewPlayer=nil
    }

    override func didMove(to view: SKView) {
        rebuild()
        DispatchQueue.main.async { [weak self, weak view] in
            guard let self, self.view === view else { return }
            self.rebuild()
        }
    }
    override func didChangeSize(_ oldSize: CGSize) { if view != nil { rebuild() } }

    private func rebuild() {
        stopMoviePreview()
        modeBriefing = nil
        removeAllChildren()
        removeAllActions()
        createNeonBackground(for: self)
        addInterfaceAtmosphere(to: self)
        let bounds = menuBounds(self)
        menuHeader("POLYSTRIKE", subtitle: "COMMAND DECK / SELECT YOUR NEXT BATTLE", on:self, bounds:bounds, color:.cyan)
        let level = PlayerProgress.shared.rankLevel
        let emblem = RankEmblemNode(level:level,size:38)
        emblem.position = CGPoint(x:bounds.maxX-20,y:bounds.maxY-17); addChild(emblem)
        label("LEVEL \(level)",x:bounds.maxX-48,y:bounds.maxY-10,size:10,color:.white,alignment:.right)
        label("COMBAT RECORD",x:bounds.maxX-48,y:bounds.maxY-26,size:7,color:NeonColors.mutedText,alignment:.right)
        let gap: CGFloat = 12
        let footerHeight: CGFloat = 46
        let heroHeight = max(100,bounds.height-126)
        let heroWidth = (bounds.width-gap)/2
        let heroY = bounds.maxY-60-heroHeight/2
        buildArenaDisplay(at:CGPoint(x:bounds.minX+heroWidth/2,y:heroY),frameSize:CGSize(width:heroWidth,height:heroHeight))
        buildStoryPreview(at:CGPoint(x:bounds.maxX-heroWidth/2,y:heroY),frameSize:CGSize(width:heroWidth,height:heroHeight))
        let titles = ["ARMORY", "BARRACKS", "SETTINGS", "LEADERBOARDS"]
        let names = ["store", "barracks", "settings", "leaderboards"]
        let colors: [SKColor] = [NeonColors.orange,.cyan,NeonColors.purple,NeonColors.mutedText]
        let width = (bounds.width-gap*3)/4
        for index in 0..<4 {
            let button = NeonButton(title:titles[index],size:CGSize(width:width,height:footerHeight),color:colors[index])
            button.name = names[index]
            button.position = CGPoint(x:bounds.minX+width/2+CGFloat(index)*(width+gap),y:bounds.minY+footerHeight/2+9)
            if index == 3 { button.alpha = 0.42; button.titleLabel.text = "LEADERBOARDS - SOON" }
            addChild(button)
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
        styleArmor(frame, size: frameSize, color: .cyan, selected: true)
        display.addChild(frame)
        let crop = SKCropNode()
        let cropMask = SKShapeNode(rectOf: CGSize(width: frameSize.width - 4, height: frameSize.height - 4), cornerRadius: 1)
        cropMask.fillColor = .white
        cropMask.strokeColor = .clear
        crop.maskNode = cropMask
        crop.zPosition = 2
        crop.name = "playPreview"
        display.addChild(crop)
        let arena = LivingArena(phase:9,center:.zero)
        let miniature = SKNode()
        let scale = min((frameSize.width-22)/arena.bounds.width,(frameSize.height-48)/arena.bounds.height)
        miniature.setScale(scale); miniature.position.y = 16
        crop.addChild(miniature)
        miniature.addChild(arena.makeBackdrop())
        let ship = Player(style:PlayerProgress.shared.selectedShip); ship.physicsBody = nil; ship.setScale(2)
        ship.position = CGPoint(x:-120,y:0); miniature.addChild(ship)
        ship.run(.repeatForever(.sequence([.moveTo(x:120,duration:2),.rotate(byAngle:.pi,duration:0.3),
                                          .moveTo(x:-120,duration:2),.rotate(byAngle:.pi,duration:0.3)])))
        for index in 0..<5 {
            let enemy = Enemy(); enemy.physicsBody = nil; enemy.configureVisual(archetype:index%3)
            enemy.setScale(1.6); enemy.position = CGPoint(x:CGFloat(index-2)*100,y:180)
            miniature.addChild(enemy)
            enemy.run(.repeatForever(.sequence([.moveBy(x:30,y:-55,duration:1.7),.moveBy(x:-30,y:55,duration:1.7)])))
        }
        if let url=Bundle.main.url(forResource:"InfiniteArenaPreview",withExtension:"m4v") {
            let player=AVQueuePlayer();player.isMuted=true;previewPlayer=player
            let video=SKVideoNode(avPlayer:player);video.name="infiniteArenaMovie";video.zPosition=3
            video.size=CGSize(width:frameSize.width-4,height:frameSize.height-44);video.position.y=20
            let movieCrop=SKCropNode();movieCrop.position.y=20
            let mask=SKShapeNode(rectOf:video.size);mask.fillColor = .white;mask.strokeColor = .clear;movieCrop.maskNode=mask
            movieCrop.name="playPreview";movieCrop.zPosition=3;crop.addChild(movieCrop);video.position = .zero;movieCrop.addChild(video)
            let asset=AVURLAsset(url:url)
            previewTask=Task { @MainActor [weak self,weak video,weak miniature] in
                do {
                    _ = try await asset.load(.duration)
                    guard let track=try await asset.loadTracks(withMediaType:.video).first else{return}
                    let naturalSize=try await track.load(.naturalSize),transform=try await track.load(.preferredTransform)
                    guard !Task.isCancelled,let self,self.previewPlayer === player,let video else{return}
                    let transformed=naturalSize.applying(transform)
                    let width=max(1,abs(transformed.width)),height=max(1,abs(transformed.height))
                    let scale=max((frameSize.width-4)/width,(frameSize.height-44)/height)
                    video.size=CGSize(width:width*scale,height:height*scale)
                    let item=AVPlayerItem(asset:asset);item.preferredMaximumResolution=CGSize(width:1280,height:720)
                    self.previewLooper=AVPlayerLooper(player:player,templateItem:item)
                    miniature?.removeFromParent()
                    player.play()
                } catch {
                    // Keep the lightweight arena preview when a bundled movie cannot be opened.
                    if !Task.isCancelled {video?.removeFromParent()}
                }
            }
        }
        let captionShade = SKShapeNode(rectOf: CGSize(width: frameSize.width - 2, height: 40))
        captionShade.position.y = -frameSize.height / 2 + 21
        captionShade.fillColor = SKColor(red: 0.025, green: 0.04, blue: 0.065, alpha: 0.96)
        captionShade.strokeColor = .clear
        frame.zPosition = 1
        captionShade.zPosition = 20
        frame.addChild(captionShade)
        let caption = createNeonLabel(text: "INFINITE ARENA", fontSize: 14, color: .white)
        caption.position.y = 5
        captionShade.addChild(caption)
        menuText("ENDLESS WAVES  /  DEPLOY →",on:captionShade,at:CGPoint(x:0,y:-11),size:8,color:.cyan,align:.center)


    }

    private func buildStoryPreview(at center: CGPoint, frameSize: CGSize) {
        let tile = armorPanel(size:frameSize,color:NeonColors.orange)
        tile.name = "storyMode"; tile.position = center; addChild(tile)
        let crest = RankEmblemNode(level:400,size:min(100,frameSize.height*0.62))
        crest.position = CGPoint(x:frameSize.width*0.27,y:9); crest.alpha = 0.8; tile.addChild(crest)
        let x = -frameSize.width/2+16
        menuText("02 / CAMPAIGN",on:tile,at:CGPoint(x:x,y:frameSize.height/2-17),size:8,color:NeonColors.orange)
        menuText("STORY MODE",on:tile,at:CGPoint(x:x,y:12),size:18,width:frameSize.width*0.6)
        menuText("5 SECTORS. 40 OPERATIONS.",on:tile,at:CGPoint(x:x,y:-10),size:8,color:NeonColors.mutedText,width:frameSize.width*0.58)
        menuText("120 STAGES. EVOLVING GUARDIANS.",on:tile,at:CGPoint(x:x,y:-26),size:7,color:NeonColors.mutedText,width:frameSize.width*0.58)
        menuText("OPEN CAMPAIGN →",on:tile,at:CGPoint(x:x,y:-frameSize.height/2+18),size:10,color:NeonColors.orange)
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
        styleArmor(panel,size:CGSize(width:panelWidth,height:panelHeight),color:.cyan)
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
            "DEFEAT EVERY ENEMY TO ADVANCE THE TIER.",
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
        let names = menuActionNames(at: point, in: self)
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
        for name in menuActionNames(at: point, in: self) {
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
    // All artwork fits a 100-point square, including wings and crowns.
    // Shared by Barracks, the menu and the in-game rank-up notification.
    private var accent: SKColor = .cyan
    private var trim: SKColor = .white
    private var lockedArtwork = false
    private let ink = SKColor(red: 0.025, green: 0.035, blue: 0.06, alpha: 1)
    private let steel = SKColor(red: 0.22, green: 0.27, blue: 0.34, alpha: 1)
    private let silver = SKColor(red: 0.69, green: 0.77, blue: 0.83, alpha: 1)

    init(level: Int, size: CGFloat, locked: Bool = false) {
        super.init()
        let rank = min(1000, max(1, level))
        let prestige = rank / 100
        let band = min(9, (rank - 1) / 10)
        lockedArtwork = locked
        let colors: [SKColor] = [.cyan, NeonColors.blue, NeonColors.purple, NeonColors.pink,
                                 NeonColors.green, NeonColors.orange, NeonColors.yellow,
                                 SKColor(red: 0.55, green: 0.39, blue: 1, alpha: 1), .cyan, NeonColors.yellow]
        accent = locked ? SKColor(white: 0.36, alpha: 1) : colors[prestige > 0 ? prestige - 1 : band]
        trim = locked ? SKColor(white: 0.31, alpha: 1) : (prestige >= 7 ? NeonColors.yellow : silver)
        let art = SKNode()
        art.name = "rankArtwork"
        art.setScale(max(1, size) / 100)
        addChild(art)
        if prestige == 0 {
            standardRank(level: rank, band: band, on: art)
        } else {
            prestigeRank(prestige, on: art)
        }
        // A separate dark tab protects numerals from busy central artwork.
        let tab = plate([(-27,-31),(27,-31),(24,-45),(-24,-45)], fill: ink, edge: trim, on: art)
        tab.zPosition = 20
        let label = createNeonLabel(text: locked ? "?" : "\(rank)", fontSize: max(12, 700 / max(1, size)), color: locked ? accent : .white)
        label.position = CGPoint(x: 0, y: -38)
        label.verticalAlignmentMode = .center
        label.zPosition = 21
        art.addChild(label)
        if locked {
            // A visible lock lets players preview the silhouette of the reward.
            let lock = plate([(-5,-27),(5,-27),(5,-20),(-5,-20)], fill: trim, edge: ink, on: art)
            lock.zPosition = 22
            let shackle = SKShapeNode(path: Self.path([(-3,-20),(-3,-16),(3,-16),(3,-20)], closed: false))
            shackle.strokeColor = trim; shackle.lineWidth = 2; shackle.zPosition = 22
            art.addChild(shackle)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @discardableResult
    private func plate(_ points: [(CGFloat, CGFloat)], fill: SKColor, edge: SKColor? = nil,
                       on parent: SKNode) -> SKShapeNode {
        let node = SKShapeNode(path: Self.path(points))
        node.fillColor = lockedArtwork ? SKColor(white: fill == ink ? 0.045 : (fill == silver ? 0.38 : (fill == steel ? 0.17 : 0.27)), alpha: 1) : fill
        node.strokeColor = edge ?? accent
        node.lineWidth = 1.5
        node.lineJoin = .miter
        parent.addChild(node)
        return node
    }

    private static func path(_ points: [(CGFloat, CGFloat)], closed: Bool = true) -> CGPath {
        let path = CGMutablePath()
        for (index, point) in points.enumerated() {
            if index == 0 { path.move(to: CGPoint(x: point.0, y: point.1)) }
            else { path.addLine(to: CGPoint(x: point.0, y: point.1)) }
        }
        if closed { path.closeSubpath() }
        return path
    }

    private func shield(on parent: SKNode) {
        plate([(-29,29),(-18,37),(18,37),(29,29),(25,-19),(0,-43),(-25,-19)], fill: steel, edge: trim, on: parent)
        plate([(-24,26),(0,32),(24,26),(20,-16),(0,-34),(-20,-16)], fill: ink, on: parent)
        for side: CGFloat in [-1,1] {
            plate([(side*26,24),(side*22,20),(side*19,-15),(side*23,-12)], fill: silver, edge: trim, on: parent)
        }
    }

    private func wings(count: Int, on parent: SKNode) {
        for side: CGFloat in [-1,1] {
            for index in 0..<count {
                let y = 26 - CGFloat(index) * 9
                let reach = 47 - CGFloat(index) * 3
                plate([(side*17,y-5),(side*reach,y+12),(side*(reach-5),y-2),
                       (side*26,y-12)], fill: index.isMultiple(of: 2) ? steel : ink, edge: trim, on: parent)
                plate([(side*28,y),(side*(reach-3),y+8),(side*(reach-6),y+3)], fill: accent, edge: accent, on: parent)
            }
        }
    }

    private func swords(on parent: SKNode) {
        for side: CGFloat in [-1,1] {
            let sword = SKNode(); sword.zRotation = side * 0.90; parent.addChild(sword)
            plate([(-3,-34),(3,-34),(3,32),(0,46),(-3,32)], fill: silver, edge: trim, on: sword)
            plate([(-12,-20),(12,-20),(12,-15),(-12,-15)], fill: steel, on: sword)
            plate([(-4,-35),(4,-35),(4,-25),(-4,-25)], fill: ink, on: sword)
        }
    }

    private func crown(points: Int, on parent: SKNode) {
        var outline: [(CGFloat, CGFloat)] = [(-22,25),(-25,43)]
        for index in 0..<points {
            let x = -22 + CGFloat(index) * 44 / CGFloat(max(1, points - 1))
            outline.append((x, index == points / 2 ? 49 : 44))
            if index < points - 1 { outline.append((x + 22 / CGFloat(points-1),32)) }
        }
        outline += [(25,43),(22,25)]
        plate(outline, fill: steel, edge: trim, on: parent)
        plate([(-20,28),(20,28),(18,23),(-18,23)], fill: accent, edge: trim, on: parent)
    }

    private func skull(beast: Bool = false, on parent: SKNode) {
        plate([(-20,18),(-12,27),(12,27),(20,18),(19,2),(13,-5),(12,-20),
               (0,-27),(-12,-20),(-13,-5),(-19,2)], fill: silver, edge: trim, on: parent)
        // Faceted temples and a recessed jaw create depth without a bright outer glow.
        for side: CGFloat in [-1,1] {
            plate([(side*18,17),(side*12,12),(side*13,-4),(side*19,2)], fill: steel, edge: steel, on: parent)
            plate([(side*3,6),(side*16,12),(side*13,0),(side*4,-2)], fill: ink, edge: ink, on: parent)
            let eye = plate([(side*5,5),(side*14,9),(side*11,3)], fill: accent, edge: accent, on: parent)
            eye.glowWidth = lockedArtwork ? 0 : 1.5
            if beast {
                plate([(side*12,-5),(side*19,-2),(side*14,-23),(side*8,-15)], fill: silver, edge: trim, on: parent)
            }
        }
        plate([(0,1),(-4,-7),(4,-7)], fill: ink, edge: ink, on: parent)
        plate([(-10,-10),(10,-10),(8,-19),(-8,-19)], fill: ink, edge: ink, on: parent)
        for x: CGFloat in [-7,-2,3] {
            plate([(x,-10),(x+3,-10),(x+3,-16),(x,-16)], fill: silver, edge: silver, on: parent)
        }
    }

    private func helmet(style: Int, on parent: SKNode) {
        plate([(-19,17),(-10,30),(10,30),(19,17),(17,-12),(0,-25),(-17,-12)], fill: steel, edge: trim, on: parent)
        plate([(-16,11),(0,6),(16,11),(13,-1),(0,-7),(-13,-1)], fill: ink, edge: ink, on: parent)
        let visor = plate([(-14,9),(0,4),(14,9),(11,3),(0,-1),(-11,3)], fill: accent, edge: accent, on: parent)
        visor.glowWidth = lockedArtwork ? 0 : 1.3
        plate([(-3,27),(3,27),(5,12),(0,8),(-5,12)], fill: silver, edge: trim, on: parent)
        if style > 1 {
            for side: CGFloat in [-1,1] {
                plate([(side*15,16),(side*30,40),(side*28,14),(side*17,2)], fill: steel, edge: trim, on: parent)
            }
        }
        for y: CGFloat in [-9,-14] {
            plate([(-7,y),(7,y),(5,y-2),(-5,y-2)], fill: ink, edge: ink, on: parent)
        }
    }

    private func star(radius: CGFloat, y: CGFloat, on parent: SKNode) {
        let vertices: [(CGFloat,CGFloat)] = (0..<10).map { i in
            let angle = CGFloat(i) * .pi / 5 + .pi / 2
            let r = i.isMultiple(of: 2) ? radius : radius * 0.45
            return (cos(angle) * r, sin(angle) * r + y)
        }
        plate(vertices, fill: trim, edge: accent, on: parent)
    }

    private func standardRank(level: Int, band: Int, on art: SKNode) {
        if band >= 3 { wings(count: 1 + (band - 3) / 2, on: art) }
        if band >= 8 { swords(on: art) }
        shield(on: art)
        if band >= 8 {
            let head = SKNode(); head.setScale(0.67); head.position.y = 9; art.addChild(head)
            helmet(style: band == 9 ? 2 : 1, on: head)
        } else if band >= 5 {
            star(radius: band >= 7 ? 15 : 12, y: 14, on: art)
        } else {
            plate([(0,27),(9,13),(0,17),(-9,13)], fill: silver, edge: trim, on: art)
        }
        let chevrons = 1 + band % 3
        for index in 0..<chevrons {
            let y = 1 - CGFloat(index) * 8
            plate([(-15,y+4),(0,y-3),(15,y+4),(15,y-1),(0,y-8),(-15,y-1)],
                  fill: index == 0 ? accent : steel, edge: trim, on: art)
        }
        // Ten inset service marks distinguish every level inside a rank family.
        let marks = (level - 1) % 10 + 1
        for index in 0..<10 {
            let side: CGFloat = index < 5 ? -1 : 1
            let y = 17 - CGFloat(index % 5) * 7
            plate([(side*21,y),(side*24,y+1),(side*24,y-2),(side*21,y-3)],
                  fill: index < marks ? accent : ink, edge: index < marks ? accent : steel, on: art)
        }
    }

    private func prestigeRank(_ tier: Int, on art: SKNode) {
        // Distinct silhouettes at each century, inspired by military medals and Polystrike machines.
        switch tier {
        case 1: // Elite Sentinel: armored helmet and compact wings.
            wings(count: 2, on: art); shield(on: art); helmet(style: 1, on: art)
        case 2: // Arena Vanguard: crossed swords and a steel death mask.
            swords(on: art); shield(on: art); skull(on: art)
        case 3: // Rift Admiral: split horned helm.
            wings(count: 2, on: art); shield(on: art); helmet(style: 2, on: art)
        case 4: // Neon Overlord: hooded executioner.
            swords(on: art)
            plate([(0,47),(24,23),(31,-25),(17,-17),(0,-35),(-17,-17),(-31,-25),(-24,23)], fill: steel, edge: trim, on: art)
            plate([(0,36),(21,16),(19,-22),(-19,-22),(-21,16)], fill: ink, on: art)
            let head = SKNode(); head.setScale(0.85); head.position.y = -1; art.addChild(head); skull(on: head)
        case 5: // Flux General: four-bladed mechanical eagle.
            wings(count: 4, on: art); shield(on: art); skull(on: art)
            star(radius: 8, y: 36, on: art)
        case 6: // Apex Commander: tusked war mask.
            swords(on: art); shield(on: art)
            for side: CGFloat in [-1,1] {
                plate([(side*15,18),(side*23,44),(side*36,31),(side*28,34),(side*26,11)], fill: steel, edge: trim, on: art)
            }
            skull(beast: true, on: art)
        case 7: // Nova Warlord: radiant reactor halo and crowned skull.
            for index in 0..<12 {
                let ray = plate([(-3,32),(0,48),(3,32)], fill: steel, edge: trim, on: art)
                ray.zRotation = CGFloat(index) * .pi / 6
            }
            shield(on: art); skull(on: art); crown(points: 3, on: art)
        case 8: // Void Marshal: a single watching eye in a fractured prism.
            wings(count: 3, on: art)
            plate([(0,48),(28,16),(23,-23),(0,-43),(-23,-23),(-28,16)], fill: steel, edge: trim, on: art)
            plate([(0,34),(20,13),(0,-26),(-20,13)], fill: ink, on: art)
            plate([(-19,10),(0,21),(19,10),(0,-2)], fill: silver, edge: trim, on: art)
            let pupil = plate([(0,19),(6,10),(0,0),(-6,10)], fill: accent, edge: accent, on: art)
            pupil.glowWidth = lockedArtwork ? 0 : 2
            plate([(0,16),(2,10),(0,3),(-2,10)], fill: ink, edge: ink, on: art)
        case 9: // Eternal Sovereign: tall crown and winged death mask.
            wings(count: 3, on: art); swords(on: art); shield(on: art)
            skull(on: art); crown(points: 5, on: art)
        default: // Polystrike Legend: gold phoenix armor, tusks and a royal crest.
            wings(count: 5, on: art); swords(on: art); shield(on: art)
            skull(beast: true, on: art); crown(points: 5, on: art)
            star(radius: 6, y: 37, on: art)
            for side: CGFloat in [-1,1] {
                plate([(side*24,-9),(side*40,-19),(side*28,-20),(side*32,-31),(side*19,-24)], fill: trim, edge: accent, on: art)
            }
        }
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
        let bounds = menuBounds(self)
        let left = bounds.minX
        let right = bounds.maxX
        let top = bounds.maxY
        let bottom = bounds.minY
        let contentWidth = bounds.width
        let gap: CGFloat = 12
        let rankWidth = contentWidth * 0.30
        let statsWidth = contentWidth - rankWidth - gap
        let panelsTop = top - 58
        let panelsBottom = bottom + 112
        let panelsHeight = max(110, panelsTop - panelsBottom)
        let panelsY = panelsBottom + panelsHeight / 2

        menuHeader("BARRACKS",subtitle:"CAREER RECORD / RANK PROGRESSION",on:self,bounds:bounds,color:.cyan)

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
        let cardHeight = max(20, (panelsHeight - 24) / 4 - 5)
        let rowStep = cardHeight + 5
        let firstRowY = panelsHeight / 2 - cardHeight / 2 - 12
        for (index, stat) in stats.enumerated() {
            let column = index % 2, row = index / 2
            let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 2)
            card.position = CGPoint(x: (column == 0 ? -1 : 1) * statsWidth * 0.25,
                                    y: firstRowY - CGFloat(row) * rowStep)
            card.fillColor = SKColor(red: 0.015, green: 0.025, blue: 0.055, alpha: 0.92)
            card.strokeColor = (column == 0 ? SKColor.cyan : NeonColors.purple).withAlphaComponent(0.32)
            styleArmor(card,size:CGSize(width:cardWidth,height:cardHeight),color:column == 0 ? .cyan : NeonColors.orange)
            statPanel.addChild(card)
            let title = createNeonLabel(text: stat.0, fontSize: 7, color: NeonColors.mutedText)
            title.position.y = cardHeight * 0.22
            card.addChild(title)
            let value = createNeonLabel(text: stat.1, fontSize: 12, color: .white)
            value.position.y = -cardHeight * 0.20
            card.addChild(value)
        }

        addLabel("PRESTIGE INSIGNIA", at: CGPoint(x: left + 72, y: bottom + 94), size: 9, color: NeonColors.mutedText)
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
        armorPanel(size:size,color:color)
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
        if menuActionNames(at:point,in:self).contains("back") {
            let scene = MainMenuScene(size: size)
            scene.scaleMode = .resizeFill
            view?.presentScene(scene, transition: .fade(withDuration: 0.2))
            return
        }
    }
}


final class SettingsScene: SKScene {
    override func didMove(to view: SKView) { rebuild() }
    override func didChangeSize(_ oldSize: CGSize) { if view != nil { rebuild() } }
    private func rebuild() {
        removeAllChildren(); createNeonBackground(for:self); addInterfaceAtmosphere(to:self)
        let b = menuBounds(self)
        menuHeader("SETTINGS",subtitle:"PILOT INTERFACE / CONTROL CONFIGURATION",on:self,bounds:b,color:NeonColors.purple)
        let back = NeonButton(title:"BACK",size:CGSize(width:108,height:36),color:.cyan)
        back.name = "back"; back.position = CGPoint(x:b.maxX-54,y:b.maxY-16); addChild(back)
        let height = b.height-62, width = b.width*0.32
        let preview = armorPanel(size:CGSize(width:width,height:height),color:NeonColors.purple)
        preview.position = CGPoint(x:b.minX+width/2,y:b.minY+height/2); addChild(preview)
        menuText("TWIN-STICK CONTROL",on:preview,at:CGPoint(x:0,y:height/2-24),size:10,color:NeonColors.purple,align:.center,width:width-24)
        for side: CGFloat in [-1,1] {
            let ring = SKShapeNode(circleOfRadius:min(26,width*0.16))
            ring.position = CGPoint(x:side*width*0.24,y:14); ring.strokeColor = SKColor.white.withAlphaComponent(0.35)
            ring.fillColor = NeonColors.background; ring.lineWidth = 2; preview.addChild(ring)
            let thumb = SKShapeNode(circleOfRadius:8); thumb.fillColor = .cyan; thumb.strokeColor = .white; ring.addChild(thumb)
            thumb.run(.repeatForever(.sequence([.move(to:CGPoint(x:side*8,y:6),duration:1.2),.move(to:.zero,duration:1.2)])))
            menuText(side < 0 ? "MOVE" : "AIM / FIRE",on:preview,at:CGPoint(x:side*width*0.24,y:-25),size:8,color:NeonColors.mutedText,align:.center)
        }
        let on = GameSettings.shared.hapticsEnabled
        let haptics = armorPanel(size:CGSize(width:width-22,height:42),color:on ? NeonColors.green : NeonColors.mutedText,selected:on)
        haptics.name = "toggleHaptics"; haptics.position.y = -height/2+33; preview.addChild(haptics)
        menuText("HAPTICS",on:haptics,at:CGPoint(x:-width/2+23,y:0),size:10)
        menuText(on ? "ON" : "OFF",on:haptics,at:CGPoint(x:width/2-23,y:0),size:10,color:on ? NeonColors.green : NeonColors.mutedText,align:.right)
        let listLeft = b.minX+width+12, listWidth = b.width-width-12
        let modes = JoystickVisibility.allCases
        let rowHeight = (height-CGFloat(modes.count-1)*10)/CGFloat(modes.count)
        for (index,mode) in modes.enumerated() {
            let selected = GameSettings.shared.joystickVisibility == mode
            let card = armorPanel(size:CGSize(width:listWidth,height:rowHeight),color:.cyan,selected:selected)
            card.name = mode.rawValue; card.position = CGPoint(x:listLeft+listWidth/2,y:b.maxY-62-rowHeight/2-CGFloat(index)*(rowHeight+10)); addChild(card)
            menuText(mode.title.uppercased(),on:card,at:CGPoint(x:-listWidth/2+16,y:10),size:12,width:listWidth-90)
            menuText(mode.detail,on:card,at:CGPoint(x:-listWidth/2+16,y:-12),size:9,color:NeonColors.mutedText,width:listWidth-32)
            menuText(selected ? "ACTIVE" : "SELECT",on:card,at:CGPoint(x:listWidth/2-16,y:10),size:8,color:selected ? NeonColors.green : NeonColors.mutedText,align:.right)
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in:self) else { return }
        for name in menuActionNames(at:point,in:self) {
            if name == "back" { transitionToScene(from:self,to:MainMenuScene(size:size)); return }
            if name == "toggleHaptics" {
                GameSettings.shared.hapticsEnabled.toggle()
                if GameSettings.shared.hapticsEnabled { UIImpactFeedbackGenerator(style:.light).impactOccurred(intensity:0.55) }
                rebuild(); return
            }
            if let mode = JoystickVisibility(rawValue:name) { GameSettings.shared.joystickVisibility = mode; rebuild(); return }
        }
    }
}
