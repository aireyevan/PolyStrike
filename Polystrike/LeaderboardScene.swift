import SpriteKit

final class LeaderboardScene: SKScene {
    private let rowsPerPage = 10
    private var scope: GameCenterManager.Scope = .global
    private var snapshot: GameCenterManager.Snapshot?
    private var page = 0
    private var loadTask: Task<Void, Never>?
    private var authenticationObserver: NSObjectProtocol?

    override func didMove(to view: SKView) {
        authenticationObserver = NotificationCenter.default.addObserver(
            forName: GameCenterManager.authenticationChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadRankings()
        }
        buildInterface()
        loadRankings()
    }

    override func willMove(from view: SKView) {
        loadTask?.cancel()
        if let authenticationObserver { NotificationCenter.default.removeObserver(authenticationObserver) }
        authenticationObserver = nil
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard view != nil else { return }
        buildInterface()
        renderRankings()
    }

    private func buildInterface() {
        removeAllChildren()
        createNeonBackground(for: self)
        addInterfaceAtmosphere(to: self)

        let bounds = menuBounds(self)
        menuHeader("POLYSTRIKE", subtitle: "GLOBAL RANKINGS / INFINITE MODE", on: self, bounds: bounds, color: .cyan)

        let tabWidth = min(150, (bounds.width - 20) / 3)
        addTab(title: "GLOBAL", name: "rankingsGlobal", x: bounds.midX - tabWidth / 2 - 5, selected: scope == .global)
        addTab(title: "FRIENDS", name: "rankingsFriends", x: bounds.midX + tabWidth / 2 + 5, selected: scope == .friends)

        let back = NeonButton(title: "BACK", size: CGSize(width: 105, height: 36), color: NeonColors.purple)
        back.name = "rankingsBack"
        back.position = CGPoint(x: bounds.minX + 52.5, y: bounds.minY + 22)
        back.zPosition = 5
        addChild(back)
    }

    private func addTab(title: String, name: String, x: CGFloat, selected: Bool) {
        let button = NeonButton(
            title: title,
            size: CGSize(width: min(150, size.width * 0.2), height: 32),
            color: selected ? .cyan : NeonColors.mutedText
        )
        button.name = name
        button.position = CGPoint(x: x, y: menuBounds(self).maxY - 62)
        button.alpha = selected ? 1 : 0.62
        button.zPosition = 5
        addChild(button)
    }

    private func loadRankings() {
        loadTask?.cancel()
        page = 0
        snapshot = nil
        renderRankings()

        guard GameCenterManager.shared.isAuthenticated else {
            GameCenterManager.shared.authenticatePlayer()
            renderMessage("GAME CENTER UNAVAILABLE", detail: "SIGN IN TO GAME CENTER TO VIEW RANKINGS")
            return
        }

        renderMessage("LOADING RANKINGS...", detail: scope == .global ? "FETCHING GLOBAL COMBAT RECORDS" : "FETCHING FRIEND COMBAT RECORDS")
        let requestedScope = scope
        loadTask = Task { [weak self] in
            do {
                let snapshot = try await GameCenterManager.shared.loadLeaderboard(scope: requestedScope, limit: 25)
                guard !Task.isCancelled, let self, self.scope == requestedScope else { return }
                self.snapshot = snapshot
                self.renderRankings()
            } catch {
                guard !Task.isCancelled, let self else { return }
                print("Game Center leaderboard load failed: \(error.localizedDescription)")
                self.renderMessage("GAME CENTER UNAVAILABLE", detail: "RANKINGS COULD NOT BE LOADED")
            }
        }
    }

    private func renderRankings() {
        childNode(withName: "rankingsContent")?.removeFromParent()
        guard let snapshot else {
            renderMessage("LOADING RANKINGS...", detail: "CONTACTING GAME CENTER")
            return
        }
        guard !snapshot.entries.isEmpty else {
            renderMessage("NO SCORES YET", detail: scope == .global ? "BE THE FIRST TO SET A COMBAT RECORD" : "NO FRIEND SCORES FOUND")
            return
        }

        let content = SKNode(); content.name = "rankingsContent"; content.zPosition = 3; addChild(content)
        let bounds = menuBounds(self)
        let panelWidth = min(720, bounds.width)
        let panelHeight = max(190, bounds.height - 128)
        let panel = armorPanel(size: CGSize(width: panelWidth, height: panelHeight), color: .cyan)
        panel.position = CGPoint(x: bounds.midX, y: bounds.midY - 7)
        content.addChild(panel)

        let left = -panelWidth / 2 + 24
        let right = panelWidth / 2 - 24
        addText("RANK", to: panel, at: CGPoint(x: left, y: panelHeight / 2 - 24), size: 8, color: .cyan, alignment: .left)
        addText("PLAYER", to: panel, at: CGPoint(x: left + 70, y: panelHeight / 2 - 24), size: 8, color: .cyan, alignment: .left)
        addText("SCORE", to: panel, at: CGPoint(x: right, y: panelHeight / 2 - 24), size: 8, color: .cyan, alignment: .right)

        let pageCount = max(1, Int(ceil(Double(snapshot.entries.count) / Double(rowsPerPage))))
        page = min(page, pageCount - 1)
        let start = page * rowsPerPage
        let visibleEntries = Array(snapshot.entries.dropFirst(start).prefix(rowsPerPage))
        let availableHeight = panelHeight - 102
        let rowSpacing = min(22, availableHeight / CGFloat(rowsPerPage))
        let firstY = panelHeight / 2 - 50

        for (index, entry) in visibleEntries.enumerated() {
            addRow(entry, to: panel, y: firstY - CGFloat(index) * rowSpacing, left: left, right: right, width: panelWidth - 28)
        }

        if pageCount > 1 {
            addPager(to: panel, pageCount: pageCount, y: -panelHeight / 2 + 21)
        }
        addLocalPlayer(snapshot.localPlayer, total: snapshot.totalPlayerCount, bounds: bounds, to: content)
    }

    private func addRow(_ entry: GameCenterManager.Entry, to panel: SKNode, y: CGFloat, left: CGFloat, right: CGFloat, width: CGFloat) {
        if entry.isLocalPlayer {
            let highlight = SKShapeNode(rectOf: CGSize(width: width, height: 19), cornerRadius: 2)
            highlight.position.y = y + 2
            highlight.fillColor = NeonColors.cyan.withAlphaComponent(0.11)
            highlight.strokeColor = NeonColors.cyan.withAlphaComponent(0.42)
            highlight.lineWidth = 0.7
            panel.addChild(highlight)
        }
        let color: SKColor = entry.isLocalPlayer ? .cyan : .white
        addText("\(entry.rank)", to: panel, at: CGPoint(x: left, y: y), size: 10, color: color, alignment: .left)
        addText(trimmed(entry.displayName, length: 22), to: panel, at: CGPoint(x: left + 70, y: y), size: 10, color: color, alignment: .left)
        addText(formatted(entry.score), to: panel, at: CGPoint(x: right, y: y), size: 10, color: color, alignment: .right)
    }

    private func addLocalPlayer(_ entry: GameCenterManager.Entry?, total: Int, bounds: CGRect, to content: SKNode) {
        let footerY = bounds.minY + 23
        let label = entry.map { "YOUR RANK  \($0.rank) / \(max(total, $0.rank))    \(trimmed($0.displayName, length: 18))    \(formatted($0.score))" }
            ?? "YOUR RANK  --    NO SCORE SUBMITTED"
        addText(label, to: content, at: CGPoint(x: bounds.midX, y: footerY), size: 9, color: .yellow, alignment: .center)
    }

    private func addPager(to panel: SKNode, pageCount: Int, y: CGFloat) {
        if page > 0 {
            let previous = NeonButton(title: "PREV", size: CGSize(width: 72, height: 26), color: NeonColors.purple)
            previous.name = "rankingsPrevious"; previous.position = CGPoint(x: -92, y: y); panel.addChild(previous)
        }
        addText("PAGE \(page + 1) / \(pageCount)", to: panel, at: CGPoint(x: 0, y: y - 3), size: 8, color: NeonColors.mutedText, alignment: .center)
        if page + 1 < pageCount {
            let next = NeonButton(title: "NEXT", size: CGSize(width: 72, height: 26), color: .cyan)
            next.name = "rankingsNext"; next.position = CGPoint(x: 92, y: y); panel.addChild(next)
        }
    }

    private func renderMessage(_ message: String, detail: String) {
        childNode(withName: "rankingsContent")?.removeFromParent()
        let content = SKNode(); content.name = "rankingsContent"; content.zPosition = 3; addChild(content)
        let bounds = menuBounds(self)
        let panel = armorPanel(size: CGSize(width: min(620, bounds.width), height: max(150, bounds.height - 150)), color: .cyan)
        panel.position = CGPoint(x: bounds.midX, y: bounds.midY - 8)
        content.addChild(panel)
        addText(message, to: panel, at: CGPoint(x: 0, y: 10), size: 16, color: .white, alignment: .center)
        addText(detail, to: panel, at: CGPoint(x: 0, y: -18), size: 8, color: NeonColors.mutedText, alignment: .center)
    }

    private func addText(_ text: String, to parent: SKNode, at point: CGPoint, size: CGFloat, color: SKColor, alignment: SKLabelHorizontalAlignmentMode) {
        let label = createNeonLabel(text: text, fontSize: size, color: color)
        label.horizontalAlignmentMode = alignment
        label.position = point
        label.zPosition = 4
        parent.addChild(label)
    }

    private func formatted(_ score: Int) -> String {
        score.formatted(.number.grouping(.automatic))
    }

    private func trimmed(_ text: String, length: Int) -> String {
        text.count > length ? String(text.prefix(max(1, length - 1))) + "…" : text
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        let names = menuActionNames(at: point, in: self)
        if names.contains("rankingsBack") {
            let scene = MainMenuScene(size: size); scene.scaleMode = .resizeFill
            view?.presentScene(scene, transition: .fade(withDuration: 0.2))
        } else if names.contains("rankingsGlobal"), scope != .global {
            scope = .global; buildInterface(); loadRankings()
        } else if names.contains("rankingsFriends"), scope != .friends {
            scope = .friends; buildInterface(); loadRankings()
        } else if names.contains("rankingsPrevious"), page > 0 {
            page -= 1; renderRankings()
        } else if names.contains("rankingsNext"), let snapshot,
                  (page + 1) * rowsPerPage < snapshot.entries.count {
            page += 1; renderRankings()
        }
    }
}
