import SpriteKit
import UIKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    private var frameDelta: TimeInterval = 1.0 / 60
    private var arenaDeck: [Int] = [1]
    private var deckShape = ArenaShape.rectangle
    private var activeArena = LivingArena(phase: 0, center: .zero)
    private var incomingArena: LivingArena?
    private var wavePlan = TierWavePlan.forTier(1)
    private var regularEnemiesRemaining = 0
    private var bossesRemaining = 0
    private var tierTransitionRemaining: TimeInterval?
    private let arenaStatus = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private var bombReadyAt: TimeInterval = 0
    private var dashReadyAt: TimeInterval = 0
    private var dashUntil: TimeInterval = 0
    private var repairClock: TimeInterval = 0
    private var elapsed: TimeInterval = 0
    private(set) var runCoins = 0
    var progression = PlayerProgress.shared
    private var navigationClock: TimeInterval = 0
    private var navDistances: [Int: Int] = [:]
    private var blockedCells = Set<Int>()
    private var wallRects: [CGRect] = []
    private let cellSize: CGFloat = 48
    private var navColumns = 0
    private var navRows = 0
    private let coinLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private var pausedRun = false
    private var pausePanel: SKNode?
    // MARK: - Physics Categories

    private let playerCategory: UInt32 = 1 << 0
    private let enemyCategory: UInt32 = 1 << 1
    private let bulletCategory: UInt32 = 1 << 2
    private let barrierCategory: UInt32 = 1 << 3

    // MARK: - Gameplay

    private var player: Player!
    private var moveJoystick: VirtualJoystick!
    private var aimJoystick: VirtualJoystick!

    private var currentTier: GameTier = GameTier.tier(for: 0)

    private(set) var score: Int = 0

    private var spawnInterval: TimeInterval = 1.0
    private var enemySpeed: CGFloat = 80
    private var enemyHealth: CGFloat = 30

    private var lastSpawnTime: TimeInterval = 0
    private var gameTime: TimeInterval = 0
    private var lastDamageTime: TimeInterval = -10

    private let damageCooldown: TimeInterval = 0.48
    private let enemyContactCooldown: TimeInterval = 0.58

    private var gameOver = false
    private var isTransitioning = false

    // MARK: - Joystick Visibility

    private var joystickVisibilityTimer: TimeInterval = 0
    private let joystickVisibleDuration: TimeInterval = 3.0
    private var joysticksHidden = false

    // MARK: - Touches

    private var movementTouch: UITouch?
    private var aimingTouch: UITouch?

    // MARK: - World

    private var playableRect: CGRect = .zero

    private var worldNode = SKNode()
    private let backgroundNode = SKNode()
    private let barrierNode = SKNode()
    private let effectNode = SKNode()

    // ================================================================
    // WORLD EXPANSION
    // ================================================================

    private var cameraNode: SKCameraNode!

    /*
     The starting zone is intentionally larger than the visible screen.

     We are NOT generating additional sections yet.

     This gives us a real world coordinate system that we can build
     the procedural map system on top of in Step 2.
     */

    private var worldBounds: CGRect = .zero

    private let worldExpansionMultiplier: CGFloat = 4.0

    // Distance from the edge at which we will eventually generate
    // a new map section.
    //
    // We are not using this yet in Step 1, but keeping the value here
    // makes the next phase easier to integrate.

    private let mapGenerationMargin: CGFloat = 250

    // MARK: - HUD

    private var scorePanel: SKShapeNode!
    private var scoreLabel: SKLabelNode!

    private var tierPanel: SKShapeNode!
    private var tierLabel: SKLabelNode!

    private var healthPanel: SKShapeNode!
    private var healthLabel: SKLabelNode!
    private var healthBackground: SKShapeNode!
    private var healthFill: SKShapeNode!

    // MARK: - Game Over UI

    private var gameOverOverlay: SKShapeNode!
    private var gameOverPanel: SKShapeNode!
    private var gameOverLabel: SKLabelNode!
    private var finalScoreLabel: SKLabelNode!
    private var pointsEarnedLabel: SKLabelNode!

    private var mainMenuButton: SKShapeNode!
    private var mainMenuLabel: SKLabelNode!

    private var tierAnnouncementNode: SKNode?

    // MARK: - Z Positions

    private let hudZ: CGFloat = 500
    private let joystickZ: CGFloat = 400
    private let effectZ: CGFloat = 300

    // MARK: - Colors

    private let backgroundColorDark = SKColor(
        red: 0.008,
        green: 0.012,
        blue: 0.022,
        alpha: 1.0
    )

    private let cyanColor = SKColor(
        red: 0.05,
        green: 0.90,
        blue: 1.0,
        alpha: 1.0
    )

    private let purpleColor = SKColor(
        red: 0.65,
        green: 0.20,
        blue: 1.0,
        alpha: 1.0
    )

    private let pinkColor = SKColor(
        red: 1.0,
        green: 0.12,
        blue: 0.55,
        alpha: 1.0
    )

    private let orangeColor = SKColor(
        red: 1.0,
        green: 0.45,
        blue: 0.08,
        alpha: 1.0
    )

    // MARK: - Scene Setup

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        backgroundColor = backgroundColorDark

        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        removeAllChildren()

        gameOver = false
        isTransitioning = false

        movementTouch = nil
        aimingTouch = nil

        score = 0
        gameTime = 0
        lastSpawnTime = 0
        lastDamageTime = -10

        joystickVisibilityTimer = 0
        joysticksHidden = false

        currentTier = GameTier.tier(for: score)

        prepareWave(for: currentTier.number)

        spawnInterval = currentTier.spawnInterval
        enemySpeed = currentTier.enemySpeed
        enemyHealth = currentTier.enemyHealth

        createWorld()

        // WORLD EXPANSION
        createCamera()

        createArena()
        createPlayer()
        installArena(activeArena)
        buildNavigation()

        // HUD and joysticks now belong to the camera so they stay
        // fixed on the screen while the world moves underneath them.
        createHUD()
        createJoysticks()
        styleHUD()
        createAbilityButtons()
        arenaStatus.fontSize = 9
        arenaStatus.position = CGPoint(x: 0, y: size.height / 2 - currentSafeAreaInsets().top - 63)
        arenaStatus.zPosition = hudZ
        cameraNode.addChild(arenaStatus)
        let pause = makeLabel(text: "Ⅱ", fontSize: 22, fontName: "AvenirNext-Bold", color: .white)
        pause.name = "pauseRun"
        pause.position = CGPoint(x: size.width / 2 - currentSafeAreaInsets().right - 24, y: 0)
        pause.zPosition = hudZ
        cameraNode.addChild(pause)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationInterrupted), name: UIApplication.willResignActiveNotification, object: nil)

        updateHUD()
    }

    // MARK: - World

    private func createWorld() {

        worldNode = SKNode()
        worldNode.name = "worldNode"
        worldNode.zPosition = 0

        addChild(worldNode)

        backgroundNode.removeAllChildren()
        barrierNode.removeAllChildren()
        effectNode.removeAllChildren()

        worldNode.addChild(backgroundNode)
        worldNode.addChild(barrierNode)
        worldNode.addChild(effectNode)
    }

    // ================================================================
    // WORLD EXPANSION
    // Camera
    // ================================================================

    private func createCamera() {

        cameraNode = SKCameraNode()

        cameraNode.name = "worldCamera"

        cameraNode.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2
        )

        addChild(cameraNode)

        camera = cameraNode
    }

    private func updateCamera() {

        guard player != nil,
              cameraNode != nil else {
            return
        }

        /*
         For Step 1 the camera follows the player directly.

         Later we can add:
         - camera smoothing
         - camera look-ahead
         - combat shake
         - section transitions
        */

        let targetPosition = CGPoint(
            x: max(worldBounds.minX + size.width / 2, min(worldBounds.maxX - size.width / 2, player.position.x)),
            y: max(worldBounds.minY + size.height / 2, min(worldBounds.maxY - size.height / 2, player.position.y)))

        let smoothing = CGFloat(1 - exp(-10 * min(frameDelta, 0.05)))

        let newX =
            cameraNode.position.x +
            (targetPosition.x - cameraNode.position.x) *
            smoothing

        let newY =
            cameraNode.position.y +
            (targetPosition.y - cameraNode.position.y) *
            smoothing

        cameraNode.position = CGPoint(
            x: newX,
            y: newY
        )
    }

    // MARK: - Arena

    private func createArena() {

        let safeInsets = currentSafeAreaInsets()

        /*
         This rectangle remains the original starting zone.

         It is NO LONGER the player's movement boundary.

         It is simply the first section of the larger world.
        */

        playableRect = CGRect(
            x: 25 + safeInsets.left,
            y: 25 + safeInsets.bottom,
            width: max(
                100,
                size.width - 50 - safeInsets.left - safeInsets.right
            ),
            height: max(
                100,
                size.height - 70 - safeInsets.top - safeInsets.bottom
            )
        )

        // ============================================================
        // WORLD EXPANSION
        //
        // Create a large world around the original starting zone.
        // ============================================================

        activeArena = LivingArena(phase: 0, center: CGPoint(x: playableRect.midX, y: playableRect.midY))
        worldBounds = activeArena.bounds

        createWorldGrid()
        createArenaBorder()
        // Keep the battlefield clear of decorative foreground geometry.
    }

    private func currentSafeAreaInsets() -> UIEdgeInsets {

        guard let view = view else {
            return .zero
        }

        return view.safeAreaInsets
    }

    // ================================================================
    // WORLD EXPANSION
    // Large world grid
    // ================================================================

    private func createWorldGrid() {
        let path = CGMutablePath()
        for x in stride(from: worldBounds.minX, through: worldBounds.maxX, by: 64) {
            path.move(to: CGPoint(x: x, y: worldBounds.minY))
            path.addLine(to: CGPoint(x: x, y: worldBounds.maxY))
        }
        for y in stride(from: worldBounds.minY, through: worldBounds.maxY, by: 64) {
            path.move(to: CGPoint(x: worldBounds.minX, y: y))
            path.addLine(to: CGPoint(x: worldBounds.maxX, y: y))
        }
        let grid = SKShapeNode(path: path)
        grid.strokeColor = SKColor(red: 0.13, green: 0.28, blue: 0.35, alpha: 0.24)
        grid.lineWidth = 0.7
        backgroundNode.addChild(grid)
    }

    private func createArenaBorder() {

        let borderPath = CGPath(
            roundedRect: worldBounds,
            cornerWidth: 12,
            cornerHeight: 12,
            transform: nil
        )

        let glowBorder = SKShapeNode(
            path: borderPath
        )

        glowBorder.strokeColor = SKColor(
            red: 0.05,
            green: 0.75,
            blue: 1.0,
            alpha: 0.10
        )

        glowBorder.lineWidth = 8
        glowBorder.fillColor = .clear
        glowBorder.zPosition = -5

        backgroundNode.addChild(glowBorder)

        let border = SKShapeNode(
            path: borderPath
        )

        border.strokeColor = SKColor(
            red: 0.15,
            green: 0.8,
            blue: 1.0,
            alpha: 0.35
        )

        border.lineWidth = 2
        border.fillColor = .clear
        border.zPosition = -4

        backgroundNode.addChild(border)
    }

    private func createCornerDetails() {

        let length: CGFloat = 22

        let corners: [
            (CGPoint, CGFloat, CGFloat)
        ] = [

            (
                CGPoint(
                    x: playableRect.minX + 8,
                    y: playableRect.maxY - 8
                ),
                1,
                -1
            ),

            (
                CGPoint(
                    x: playableRect.maxX - 8,
                    y: playableRect.maxY - 8
                ),
                -1,
                -1
            ),

            (
                CGPoint(
                    x: playableRect.minX + 8,
                    y: playableRect.minY + 8
                ),
                1,
                1
            ),

            (
                CGPoint(
                    x: playableRect.maxX - 8,
                    y: playableRect.minY + 8
                ),
                -1,
                1
            )
        ]

        for corner in corners {

            let horizontalPath = CGMutablePath()

            horizontalPath.move(
                to: corner.0
            )

            horizontalPath.addLine(
                to: CGPoint(
                    x: corner.0.x +
                        length * corner.1,
                    y: corner.0.y
                )
            )

            let horizontal = SKShapeNode(
                path: horizontalPath
            )

            horizontal.strokeColor =
                cyanColor.withAlphaComponent(0.65)

            horizontal.lineWidth = 2

            backgroundNode.addChild(horizontal)

            let verticalPath = CGMutablePath()

            verticalPath.move(
                to: corner.0
            )

            verticalPath.addLine(
                to: CGPoint(
                    x: corner.0.x,
                    y: corner.0.y +
                        length * corner.2
                )
            )

            let vertical = SKShapeNode(
                path: verticalPath
            )

            vertical.strokeColor =
                cyanColor.withAlphaComponent(0.65)

            vertical.lineWidth = 2

            backgroundNode.addChild(vertical)
        }
    }

    // MARK: - Player

    private func createPlayer() {

        player = Player()

        player.health =
            progression.playerHealth()

        player.maxHealth =
            progression.playerHealth()

        player.damage =
            progression.playerDamage()

        player.moveSpeed =
            progression.playerMoveSpeed()

        player.fireRate =
            progression.playerFireRate()

        player.position = CGPoint(
            x: playableRect.midX,
            y: playableRect.midY
        )

        player.zPosition = 20

        worldNode.addChild(player)

        player.glowWidth = 4
    }

    private func createPlayerAura() {

        let aura = SKShapeNode(
            circleOfRadius: 25
        )

        aura.fillColor = .clear

        aura.strokeColor =
            cyanColor.withAlphaComponent(0.12)

        aura.lineWidth = 2
        aura.zPosition = -1
        aura.name = "playerAura"

        player.addChild(aura)

        let pulseUp = SKAction.scale(
            to: 1.15,
            duration: 0.8
        )

        pulseUp.timingMode = .easeInEaseOut

        let pulseDown = SKAction.scale(
            to: 0.95,
            duration: 0.8
        )

        pulseDown.timingMode = .easeInEaseOut

        aura.run(
            SKAction.repeatForever(
                SKAction.sequence([
                    pulseUp,
                    pulseDown
                ])
            )
        )
    }

    // MARK: - HUD

    private func createHUD() {
        createScoreHUD()
        createTierHUD()
        createHealthHUD()
    }

    private func createScoreHUD() {

        scorePanel = createHUDPanel(
            size: CGSize(
                width: 120,
                height: 42
            ),
            strokeColor: cyanColor
        )

        scorePanel.position = CGPoint(
            x: playableRect.minX + 70,
            y: size.height - 34
        )

        // WORLD EXPANSION
        cameraNode.addChild(scorePanel)

        let title = makeLabel(
            text: "SCORE",
            fontSize: 8,
            fontName: "AvenirNext-Bold",
            color: cyanColor
        )

        title.horizontalAlignmentMode = .left

        title.position = CGPoint(
            x: -50,
            y: 9
        )

        scorePanel.addChild(title)

        scoreLabel = makeLabel(
            text: "0",
            fontSize: 17,
            fontName: "AvenirNext-Bold",
            color: .white
        )

        scoreLabel.horizontalAlignmentMode = .left

        scoreLabel.position = CGPoint(
            x: -50,
            y: -10
        )

        scorePanel.addChild(scoreLabel)
    }

    private func createTierHUD() {

        tierPanel = createHUDPanel(
            size: CGSize(
                width: 155,
                height: 42
            ),
            strokeColor: purpleColor
        )

        tierPanel.position = CGPoint(
            x: size.width / 2,
            y: size.height - 34
        )

        // WORLD EXPANSION
        cameraNode.addChild(tierPanel)

        tierLabel = makeLabel(
            text: "TIER 1 • NEON GRID",
            fontSize: 10,
            fontName: "AvenirNext-Bold",
            color: .white
        )

        tierLabel.position = .zero

        tierPanel.addChild(tierLabel)
    }

    private func createHealthHUD() {

        healthPanel = createHUDPanel(
            size: CGSize(
                width: 120,
                height: 42
            ),
            strokeColor: pinkColor
        )

        healthPanel.position = CGPoint(
            x: playableRect.maxX - 70,
            y: size.height - 34
        )

        // WORLD EXPANSION
        cameraNode.addChild(healthPanel)

        healthLabel = makeLabel(
            text: "♥ 100",
            fontSize: 15,
            fontName: "AvenirNext-Bold",
            color: .white
        )

        healthLabel.position = CGPoint(
            x: 0,
            y: 7
        )

        healthPanel.addChild(healthLabel)

        healthBackground = SKShapeNode(
            rectOf: CGSize(
                width: 90,
                height: 5
            ),
            cornerRadius: 2.5
        )

        healthBackground.position = CGPoint(
            x: 0,
            y: -10
        )

        healthBackground.fillColor = SKColor(
            white: 0.08,
            alpha: 0.9
        )

        healthBackground.strokeColor = SKColor(
            white: 0.3,
            alpha: 0.25
        )

        healthBackground.lineWidth = 1

        healthPanel.addChild(
            healthBackground
        )

        healthFill = SKShapeNode(
            rectOf: CGSize(
                width: 90,
                height: 3
            ),
            cornerRadius: 1.5
        )

        healthFill.position = CGPoint(
            x: -45,
            y: -10
        )

        healthFill.fillColor = cyanColor
        healthFill.strokeColor = .clear

        healthPanel.addChild(
            healthFill
        )
    }

    private func createHUDPanel(
        size panelSize: CGSize,
        strokeColor: SKColor
    ) -> SKShapeNode {

        let panel = SKShapeNode(
            rectOf: panelSize,
            cornerRadius: 8
        )

        panel.fillColor = SKColor(
            red: 0.015,
            green: 0.025,
            blue: 0.045,
            alpha: 0.90
        )

        panel.strokeColor =
            strokeColor.withAlphaComponent(0.30)

        panel.lineWidth = 1
        panel.zPosition = hudZ

        return panel
    }

    private func makeLabel(
        text: String,
        fontSize: CGFloat,
        fontName: String,
        color: SKColor
    ) -> SKLabelNode {

        let label = SKLabelNode(
            fontNamed: fontName
        )

        label.text = text
        label.fontSize = fontSize
        label.fontColor = color

        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center

        label.zPosition = hudZ + 1

        return label
    }

    private func updateHUD() {

        guard player != nil else {
            return
        }

        scoreLabel.text = "SCORE   \(score)"

        // Keep one stable contract in this panel. Previously this temporarily
        // replaced the hostile counter whenever another HUD value changed.
        updateTierProgressLabel()

        let health = max(
            0,
            player.health
        )

        let maxHealth = max(
            1,
            player.maxHealth
        )

        healthLabel.text =
            "♥   \(Int(health))"

        let ratio = max(
            0,
            min(
                1,
                health / maxHealth
            )
        )

        healthFill.xScale = ratio
        healthFill.position.x = -45 + 45 * ratio

        if ratio > 0.5 {
            healthFill.fillColor = cyanColor
        } else if ratio > 0.25 {
            healthFill.fillColor = orangeColor
        } else {
            healthFill.fillColor = pinkColor
        }
    }

    // MARK: - Joysticks

    private func createJoysticks() {

        moveJoystick = VirtualJoystick()
        aimJoystick = VirtualJoystick()

        /*
         Joysticks are attached to the camera.

         Their coordinates are therefore screen-relative instead
         of world-relative.
        */

        let insets = currentSafeAreaInsets()
        moveJoystick.position = CGPoint(x: -size.width / 2 + insets.left + 90, y: -size.height / 2 + insets.bottom + 90)
        aimJoystick.position = CGPoint(x: size.width / 2 - insets.right - 90, y: -size.height / 2 + insets.bottom + 90)

        moveJoystick.zPosition = joystickZ
        aimJoystick.zPosition = joystickZ

        moveJoystick.refreshVisibility()
        aimJoystick.refreshVisibility()
        cameraNode.addChild(moveJoystick)
        cameraNode.addChild(aimJoystick)
    }

    private func showJoystick(_ joystick: VirtualJoystick) {
        joystick.refreshVisibility()
    }

    // MARK: - Update

    override func update(
        _ currentTime: TimeInterval
    ) {

        super.update(currentTime)

        guard !gameOver, !pausedRun else {
            gameTime = currentTime
            return
        }

        if gameTime == 0 {

            gameTime = currentTime
            lastSpawnTime = currentTime
        }

        let deltaTime = min(
            max(
                currentTime - gameTime,
                0
            ),
            0.05
        )

        gameTime = currentTime
        frameDelta = deltaTime
        elapsed += deltaTime
        updateAbilities(deltaTime: deltaTime)
        updateLivingArena(deltaTime: deltaTime)
        navigationClock += deltaTime
        if navigationClock >= 0.25 {
            updateNavigation()
            navigationClock = 0
        }
        updatePickups(deltaTime: deltaTime)
        coinLabel.text = "\(runCoins)"
        updateTierProgressLabel()

        updateMovement(
            deltaTime: deltaTime
        )

        updateEnemies(
            deltaTime: deltaTime
        )

        updateShooting(
            currentTime: currentTime
        )

        updateSpawning(
            currentTime: currentTime
        )

        updatePlayerVisuals()

        // WORLD EXPANSION
        updateCamera()
    }

    // MARK: - Movement

    private func updateMovement(
        deltaTime: TimeInterval
    ) {

        guard movementTouch != nil else {
            return
        }

        let direction = moveJoystick.direction

        if direction.dx == 0 &&
            direction.dy == 0 {
            return
        }

        let speed = player.moveSpeed

        let movementX =
            direction.dx *
            speed *
            CGFloat(deltaTime)

        let movementY =
            direction.dy *
            speed *
            CGFloat(deltaTime)

        var newPosition =
            player.position

        newPosition.x += movementX
        newPosition.y += movementY

        // ============================================================
        // WORLD EXPANSION
        //
        // The old playableRect clamp has been removed.
        //
        // The player can now leave the starting arena.
        // ============================================================

        let playerRadius: CGFloat = 18

        newPosition.x = max(
            worldBounds.minX + playerRadius,
            min(
                worldBounds.maxX - playerRadius,
                newPosition.x
            )
        )

        newPosition.y = max(
            worldBounds.minY + playerRadius,
            min(
                worldBounds.maxY - playerRadius,
                newPosition.y
            )
        )

        player.position = newPosition

        resolvePlayerBarrierCollision()
    }

    private func resolvePlayerBarrierCollision() {

        guard let player = player else {
            return
        }

        let playerRadius: CGFloat = 18

        for child in barrierNode.children {

            guard let barrier = child as? Barrier else {
                continue
            }

            let barrierFrame = barrier.barrierRect

            let closestX = max(
                barrierFrame.minX,
                min(
                    player.position.x,
                    barrierFrame.maxX
                )
            )

            let closestY = max(
                barrierFrame.minY,
                min(
                    player.position.y,
                    barrierFrame.maxY
                )
            )

            let dx =
                player.position.x -
                closestX

            let dy =
                player.position.y -
                closestY

            let distanceSquared =
                dx * dx +
                dy * dy

            if distanceSquared <
                playerRadius * playerRadius {

                let distance = sqrt(
                    distanceSquared
                )

                if distance > 0.001 {

                    let overlap =
                        playerRadius - distance

                    let pushX =
                        dx / distance

                    let pushY =
                        dy / distance

                    player.position.x +=
                        pushX * overlap

                    player.position.y +=
                        pushY * overlap

                } else {

                    let left =
                        abs(
                            player.position.x -
                            barrierFrame.minX
                        )

                    let right =
                        abs(
                            barrierFrame.maxX -
                            player.position.x
                        )

                    let bottom =
                        abs(
                            player.position.y -
                            barrierFrame.minY
                        )

                    let top =
                        abs(
                            barrierFrame.maxY -
                            player.position.y
                        )

                    let minimum =
                        min(
                            min(left, right),
                            min(bottom, top)
                        )

                    if minimum == left {

                        player.position.x =
                            barrierFrame.minX -
                            playerRadius

                    } else if minimum == right {

                        player.position.x =
                            barrierFrame.maxX +
                            playerRadius

                    } else if minimum == bottom {

                        player.position.y =
                            barrierFrame.minY -
                            playerRadius

                    } else {

                        player.position.y =
                            barrierFrame.maxY +
                            playerRadius
                    }
                }
            }
        }
    }

    // MARK: - Enemies

    private func updateEnemies(
        deltaTime: TimeInterval
    ) {

        let enemies =
            worldNode.children.compactMap {
                $0 as? Enemy
            }
        let enemyPositions = enemies.map(\.position)

        for (enemyIndex, enemy) in enemies.enumerated() {

            if let health = enemy.childNode(withName: "sentinelHealth") as? SKLabelNode {
                let title = enemy.userData?["finalBoss"] as? Bool == true ? "APEX SENTINEL" : "SENTINEL"
                let phase = enemy.userData?["phaseTitle"] as? String
                health.text = "\(title)  \(Int(max(0, enemy.health))) / \(Int(enemy.maxHealth))\(phase.map { "  •  \($0)" } ?? "")"
                health.zRotation = -enemy.zRotation
                if let fill = enemy.childNode(withName: "sentinelBar") {
                    let ratio = max(0, enemy.health / enemy.maxHealth)
                    let width = enemy.userData?["healthBarWidth"] as? CGFloat ?? 50
                    fill.xScale = ratio
                    fill.position.x = -width / 2 + width / 2 * ratio
                }
            }
            let target = navigationTarget(from: enemy.position)
            let dx = target.x - enemy.position.x
            let dy = target.y - enemy.position.y

            let distance =
                sqrt(
                    dx * dx +
                    dy * dy
                )

            guard distance > 0.1 else {
                continue
            }

            let pursuitX =
                dx / distance

            let pursuitY =
                dy / distance

            let separation = EnemyCrowdSteering.separationVector(
                for: enemyIndex,
                positions: enemyPositions,
                preferredSpacing: enemy.userData?["sentinel"] as? Bool == true ? 76 : 50
            )
            var desiredX = pursuitX + separation.dx * 1.7
            var desiredY = pursuitY + separation.dy * 1.7
            let desiredMagnitude = max(0.001, hypot(desiredX, desiredY))
            desiredX /= desiredMagnitude
            desiredY /= desiredMagnitude

            // Navigation updates and neighboring agents can change the desired heading
            // abruptly. A persistent, frame-rate-independent blend produces curved paths
            // instead of visible left/right corrections.
            let previousX = enemy.userData?["steeringX"] as? CGFloat ?? desiredX
            let previousY = enemy.userData?["steeringY"] as? CGFloat ?? desiredY
            let responsiveness: CGFloat = enemy.userData?["archetype"] as? Int == 2 ? 5.5 : 8
            let blend = 1 - exp(-responsiveness * CGFloat(deltaTime))
            var directionX = previousX + (desiredX - previousX) * blend
            var directionY = previousY + (desiredY - previousY) * blend
            let steeredMagnitude = max(0.001, hypot(directionX, directionY))
            directionX /= steeredMagnitude
            directionY /= steeredMagnitude
            enemy.userData?["steeringX"] = directionX
            enemy.userData?["steeringY"] = directionY
            if enemy.userData?["archetype"] as? Int == 1 {
                enemy.zRotation = atan2(directionY, directionX)
            }

            let isFinalBoss = enemy.userData?["finalBoss"] as? Bool == true
            if isFinalBoss { updateFinalBoss(enemy) }
            let isShooter = enemy.userData?["ranged"] as? Bool == true
            let canShoot = !isFinalBoss && isShooter && hypot(player.position.x - enemy.position.x, player.position.y - enemy.position.y) < 420 && clearPath(from: enemy.position, to: player.position)
            if canShoot {
                let last = enemy.userData?["lastFire"] as? Double ?? -10
                if elapsed - last > 2.5 {
                    enemy.userData?["lastFire"] = elapsed
                    if enemy.userData?["bossKind"] as? String == "pulse" {
                        for angle in stride(from: CGFloat(0), to: .pi * 2, by: .pi / 3) {
                            fireEnemyProjectile(from: enemy, angleOffset: angle)
                        }
                    } else if enemy.userData?["sentinel"] as? Bool == true {
                        for angle: CGFloat in [-0.24, 0, 0.24] {
                            fireEnemyProjectile(from: enemy, angleOffset: angle)
                        }
                    } else {
                        fireEnemyProjectile(from: enemy)
                    }
                }
            }
            let isArrowHive = enemy.userData?["arrowHive"] as? Bool == true
            if isArrowHive {
                let lastAttacked = enemy.userData?["lastHiveAttacked"] as? Double ?? elapsed
                let lastLaunch = enemy.userData?["lastHiveLaunch"] as? Double ?? elapsed
                if elapsed - lastAttacked >= 6.5, elapsed - lastLaunch >= 5.5 {
                    launchHiveVolleyIfReady(from: enemy, minimumCooldown: 5.5)
                }
            }
            let movementScale: CGFloat = isArrowHive ? 0 : (isFinalBoss ? 0.32 : (canShoot ? 0.25 : 1))
            enemy.position.x +=
                directionX * movementScale *
                enemy.moveSpeed *
                CGFloat(deltaTime)

            enemy.position.y +=
                directionY * movementScale *
                enemy.moveSpeed *
                CGFloat(deltaTime)

            resolveEnemyBarrierCollision(enemy)
            let occupiedCell = navIndex(enemy.position)
            if !activeArena.containsShip(at: enemy.position) || navDistances[occupiedCell] == nil {
                enemy.position = nearestReachableNavigationPoint(to: enemy.position)
                enemy.userData?.removeObject(forKey: "steeringX")
                enemy.userData?.removeObject(forKey: "steeringY")
            }
            if hypot(enemy.position.x - player.position.x, enemy.position.y - player.position.y) < 33,
               let body = enemy.physicsBody { handlePlayerEnemyContact(enemyBody: body) }
        }
    }

    private func resolveEnemyBarrierCollision(
        _ enemy: Enemy
    ) {

        for child in barrierNode.children {

            guard let barrier =
                child as? Barrier else {
                continue
            }

            let rect = barrier.barrierRect

            let closestX = max(
                rect.minX,
                min(
                    enemy.position.x,
                    rect.maxX
                )
            )

            let closestY = max(
                rect.minY,
                min(
                    enemy.position.y,
                    rect.maxY
                )
            )

            let dx =
                enemy.position.x -
                closestX

            let dy =
                enemy.position.y -
                closestY

            if dx * dx + dy * dy < 17 * 17 {

                let centerX = rect.midX
                let centerY = rect.midY

                if abs(
                    enemy.position.x -
                    centerX
                ) >
                    abs(
                        enemy.position.y -
                        centerY
                    ) {

                    if enemy.position.x >
                        centerX {

                        enemy.position.x =
                            rect.maxX + 18

                    } else {

                        enemy.position.x =
                            rect.minX - 18
                    }

                } else {

                    if enemy.position.y >
                        centerY {

                        enemy.position.y =
                            rect.maxY + 18

                    } else {

                        enemy.position.y =
                            rect.minY - 18
                    }
                }
            }
        }
    }

    // MARK: - Shooting

    private func updateShooting(
        currentTime: TimeInterval
    ) {

        guard aimingTouch != nil else {
            return
        }

        let direction =
            aimJoystick.direction

        let magnitude =
            sqrt(
                direction.dx *
                direction.dx +
                direction.dy *
                direction.dy
            )

        guard magnitude > 0.15 else {
            return
        }

        guard currentTime -
                player.lastShotTime >=
                player.fireRate else {
            return
        }

        player.lastShotTime =
            currentTime

        if progression.doubleShotUnlocked {
            let angle = atan2(direction.dy, direction.dx)
            for offset: CGFloat in [-0.065, 0.065] {
                fireBullet(direction: CGVector(dx: cos(angle + offset), dy: sin(angle + offset)))
            }
        } else {
            fireBullet(direction: direction)
        }
    }

    private func fireBullet(
        direction: CGVector
    ) {

        let bullet = Bullet(
            damage: player.damage
        )

        bullet.bulletSpeed =
            player.projectileSpeed

        let normalized =
            normalize(direction)

        let spawnDistance: CGFloat = 28

        bullet.position = CGPoint(
            x: player.position.x +
                normalized.dx *
                spawnDistance,

            y: player.position.y +
                normalized.dy *
                spawnDistance
        )

        bullet.zPosition = 15

        worldNode.addChild(
            bullet
        )
        bullet.attachTrail(to: worldNode)

        let angle =
            atan2(
                normalized.dy,
                normalized.dx
            )

        bullet.zRotation = angle

        let distance: CGFloat = 1200

        let destination = CGPoint(
            x: bullet.position.x +
                normalized.dx *
                distance,

            y: bullet.position.y +
                normalized.dy *
                distance
        )

        let duration =
            TimeInterval(
                distance /
                max(
                    1,
                    bullet.bulletSpeed
                )
            )

        bullet.physicsBody?.usesPreciseCollisionDetection = true
        let move = SKAction.move(
            to: destination,
            duration: duration
        )

        move.timingMode = .linear

        bullet.run(
            SKAction.sequence([
                move,
                SKAction.removeFromParent()
            ])
        )

        createMuzzleFlash(
            direction: normalized
        )
    }

    private func normalize(
        _ vector: CGVector
    ) -> CGVector {

        let magnitude =
            sqrt(
                vector.dx *
                vector.dx +
                vector.dy *
                vector.dy
            )

        guard magnitude > 0 else {

            return CGVector(
                dx: 0,
                dy: 0
            )
        }

        return CGVector(
            dx: vector.dx / magnitude,
            dy: vector.dy / magnitude
        )
    }

    // MARK: - Muzzle Flash

    private func createMuzzleFlash(
        direction: CGVector
    ) {

        let flash = SKShapeNode(
            circleOfRadius: 7
        )

        flash.fillColor = .white
        flash.strokeColor = cyanColor
        flash.lineWidth = 1

        flash.position = CGPoint(
            x: player.position.x +
                direction.dx * 28,

            y: player.position.y +
                direction.dy * 28
        )

        flash.zPosition = effectZ

        worldNode.addChild(
            flash
        )

        let scale = SKAction.scale(
            to: 2.2,
            duration: 0.07
        )

        let fade = SKAction.fadeOut(
            withDuration: 0.07
        )

        flash.run(
            SKAction.sequence([
                SKAction.group([
                    scale,
                    fade
                ]),
                SKAction.removeFromParent()
            ])
        )

        let beamPath = CGMutablePath()

        beamPath.move(
            to: CGPoint(
                x: player.position.x +
                    direction.dx * 20,

                y: player.position.y +
                    direction.dy * 20
            )
        )

        beamPath.addLine(
            to: CGPoint(
                x: player.position.x +
                    direction.dx * 48,

                y: player.position.y +
                    direction.dy * 48
            )
        )

        let beam = SKShapeNode(
            path: beamPath
        )

        beam.strokeColor =
            cyanColor.withAlphaComponent(0.7)

        beam.lineWidth = 2
        beam.zPosition = effectZ - 1

        worldNode.addChild(
            beam
        )

        beam.run(
            SKAction.sequence([
                SKAction.fadeOut(
                    withDuration: 0.06
                ),
                SKAction.removeFromParent()
            ])
        )
    }

    // MARK: - Spawning

    private func updateSpawning(currentTime: TimeInterval) {
        guard tierTransitionRemaining == nil else { return }
        let pacing = OpeningPacing(progress: progression)
        let opening = pacing.multiplier(at: elapsed)
        guard currentTime - lastSpawnTime >= spawnInterval * opening else { return }
        lastSpawnTime = currentTime
        let count = worldNode.children.filter { $0 is Enemy }.count
        let spatialLimit = activeArena.shape == .rectangle ? 130 : max(32, activeArena.floorCenters.count)
        let available = min(pacing.enemyLimit(at: elapsed), spatialLimit) - count
        guard available > 0 else { return }
        if bossesRemaining > 0 {
            bossesRemaining -= 1
            spawnSentinel(tier: currentTier.number)
            return
        }
        let batch = min(regularEnemiesRemaining, min(available, min(4, 1 + currentTier.number / 4)))
        guard batch > 0 else { return }
        for _ in 0..<batch {
            regularEnemiesRemaining -= 1
            createEnemy()
        }
    }

    private func createEnemy() {

        let enemy = Enemy()

        enemy.health =
            enemyHealth

        enemy.maxHealth =
            enemyHealth

        enemy.moveSpeed =
            enemySpeed

        enemy.scoreValue =
            currentTier.killScore

        enemy.position =
            randomSpawnPosition()

        applyEnemyAppearance(
            enemy
        )

        worldNode.addChild(
            enemy
        )

        let variant: Int
        let activeHives = worldNode.children.reduce(into: 0) {
            if $1 is Enemy, $1.userData?["arrowHive"] as? Bool == true { $0 += 1 }
        }
        if currentTier.number >= 5,
           activeHives < 4,
           Int.random(in: 0..<100) < 6 {
            // Hives remain uncommon, but a later wave can build to a maximum of
            // four simultaneous priority targets.
            variant = 6
        } else if currentTier.number >= 4 {
            variant = Int.random(in: 0...5)
        } else {
            variant = currentTier.number > 1 ? Int.random(in: 0...4) : 0
        }
        if variant == 1 {
            enemy.moveSpeed *= 1.35
            enemy.health *= 0.65
            enemy.strokeColor = .orange
            enemy.fillColor = SKColor.orange.withAlphaComponent(0.25)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 19, y: 0))
            path.addLine(to: CGPoint(x: -14, y: 14))
            path.addLine(to: CGPoint(x: -14, y: -14))
            path.closeSubpath()
            enemy.path = path
        } else if variant == 2 && currentTier.number >= 3 {
            enemy.moveSpeed *= 0.65
            enemy.health *= 2.2
            enemy.damage = 18
            enemy.strokeColor = .magenta
            enemy.path = CGPath(rect: CGRect(x: -18, y: -18, width: 36, height: 36), transform: nil)
        }
        if variant == 3 && currentTier.number >= 3 {
            enemy.userData = ["ranged": true, "lastFire": elapsed]
            enemy.strokeColor = .yellow
            enemy.fillColor = SKColor.yellow.withAlphaComponent(0.2)
            enemy.moveSpeed *= 0.75
        }
        if variant == 5 {
            enemy.userData = enemy.userData ?? NSMutableDictionary()
            enemy.userData?["splitsIntoOctagons"] = true
            enemy.health *= 1.45
            enemy.moveSpeed *= 0.82
            enemy.damage = 12
            enemy.strokeColor = SKColor(red: 0.2, green: 0.72, blue: 1, alpha: 1)
            enemy.fillColor = SKColor(red: 0.03, green: 0.20, blue: 0.48, alpha: 0.82)
            let octagon = CGMutablePath()
            for index in 0..<8 {
                let angle = CGFloat(index) * .pi / 4 + .pi / 8
                let point = CGPoint(x: cos(angle) * 20, y: sin(angle) * 20)
                if index == 0 { octagon.move(to: point) } else { octagon.addLine(to: point) }
            }
            octagon.closeSubpath()
            enemy.path = octagon
        }
        if variant == 6 {
            enemy.userData = enemy.userData ?? NSMutableDictionary()
            enemy.userData?["arrowHive"] = true
            enemy.userData?["lastHiveLaunch"] = elapsed - 1.8
            enemy.userData?["lastHiveAttacked"] = elapsed
            enemy.health *= 3.2
            enemy.moveSpeed = 0
            enemy.damage = 15
            enemy.scoreValue *= 3
            enemy.strokeColor = NeonColors.orange
            enemy.fillColor = SKColor(red: 0.30, green: 0.025, blue: 0.12, alpha: 0.92)
            enemy.path = CGPath(ellipseIn: CGRect(x: -25, y: -25, width: 50, height: 50), transform: nil)
            enemy.physicsBody = SKPhysicsBody(circleOfRadius: 25)
            enemy.physicsBody?.affectedByGravity = false
            enemy.physicsBody?.allowsRotation = false
            enemy.physicsBody?.categoryBitMask = enemyCategory
            enemy.physicsBody?.collisionBitMask = 0
            enemy.physicsBody?.contactTestBitMask = bulletCategory | playerCategory
        }
        enemy.maxHealth = enemy.health
        enemy.glowWidth = 3
        let archetype = currentTier.number < 3 && (variant == 2 || variant == 3) ? 0 : variant
        enemy.configureVisual(archetype: archetype)
        createEnemySpawnEffect(at: enemy.position)
    }

    private func randomSpawnPosition() -> CGPoint {
        let safe = activeArena.floorCenters.filter {
            activeArena.bounds.insetBy(dx: 80, dy: 80).contains($0) &&
            navDistances[navIndex($0)] != nil &&
            neighbors(navIndex($0)).filter { navDistances[$0] != nil }.count >= 2
        }
        let candidates = safe.filter {
            hypot($0.x - player.position.x, $0.y - player.position.y) > 320
        }
        let offscreen = candidates.filter {
            abs($0.x - cameraNode.position.x) > size.width / 2 + 24 || abs($0.y - cameraNode.position.y) > size.height / 2 + 24
        }
        if let spawn = (offscreen.isEmpty ? candidates : offscreen).randomElement() { return spawn }
        return safe.max(by: {
            hypot($0.x - player.position.x, $0.y - player.position.y) <
            hypot($1.x - player.position.x, $1.y - player.position.y)
        }) ?? nearestReachableNavigationPoint(to: activeArena.center)
    }

    private func applyEnemyAppearance(
        _ enemy: Enemy
    ) {

        switch currentTier.number {

        case 1:

            enemy.fillColor = SKColor(
                red: 1.0,
                green: 0.08,
                blue: 0.35,
                alpha: 1
            )

            enemy.strokeColor = .white

        case 2:

            enemy.fillColor = SKColor(
                red: 1.0,
                green: 0.15,
                blue: 0.65,
                alpha: 1
            )

            enemy.strokeColor = pinkColor

        case 3:

            enemy.fillColor = SKColor(
                red: 0.7,
                green: 0.15,
                blue: 1.0,
                alpha: 1
            )

            enemy.strokeColor = purpleColor

        case 4:

            enemy.fillColor = orangeColor
            enemy.strokeColor = .yellow

        default:

            enemy.fillColor = SKColor(
                red: 1.0,
                green: 0.05,
                blue: 0.08,
                alpha: 1
            )

            enemy.strokeColor = pinkColor
        }

        enemy.lineWidth = 2
        enemy.glowWidth = 8
    }

    private func createEnemySpawnEffect(
        at position: CGPoint
    ) {

        let ring = SKShapeNode(
            circleOfRadius: 10
        )

        ring.position = position
        ring.fillColor = .clear
        ring.strokeColor = cyanColor
        ring.lineWidth = 2
        ring.zPosition = effectZ

        worldNode.addChild(
            ring
        )

        for index in 0..<6 {
            let angle = CGFloat(index) * .pi / 3
            let spoke = SKShapeNode(rectOf: CGSize(width: 16, height: 2), cornerRadius: 1)
            spoke.position = CGPoint(x: position.x + cos(angle) * 16, y: position.y + sin(angle) * 16)
            spoke.zRotation = angle
            spoke.fillColor = index.isMultiple(of: 2) ? cyanColor : purpleColor
            spoke.strokeColor = .clear
            spoke.glowWidth = 3
            spoke.zPosition = effectZ
            worldNode.addChild(spoke)
            spoke.run(.sequence([
                .group([.moveBy(x: cos(angle) * 28, y: sin(angle) * 28, duration: 0.22), .fadeOut(withDuration: 0.22)]),
                .removeFromParent()
            ]))
        }

        ring.run(
            SKAction.sequence([
                SKAction.group([
                    SKAction.scale(
                        to: 2.5,
                        duration: 0.18
                    ),

                    SKAction.fadeOut(
                        withDuration: 0.18
                    )
                ]),

                SKAction.removeFromParent()
            ])
        )
    }

    // MARK: - Physics

    func didBegin(
        _ contact: SKPhysicsContact
    ) {

        guard !gameOver, !pausedRun else { return }
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if categories == (16 | playerCategory) || categories == (16 | barrierCategory) {
            let shotBody = contact.bodyA.categoryBitMask == 16 ? contact.bodyA : contact.bodyB
            guard let shot = shotBody.node, shot.parent != nil else { return }
            shot.removeFromParent()
            if categories == (16 | playerCategory), gameTime - lastDamageTime >= damageCooldown, elapsed >= dashUntil {
                lastDamageTime = gameTime
                player.health -= 9 * progression.damageMultiplier
                createPlayerDamageEffect()
                updateHUD()
                if player.health <= 0 { endGame() }
            }
            return
        }
        if categories == bulletCategory | barrierCategory {
            let body = contact.bodyA.categoryBitMask == bulletCategory ? contact.bodyA : contact.bodyB
            if let bullet = body.node, bullet.parent != nil {
                createHitFlash(at: bullet.position)
                bullet.removeFromParent()
            }
            return
        }
        let categoryA =
            contact.bodyA.categoryBitMask

        let categoryB =
            contact.bodyB.categoryBitMask

        if categoryA == bulletCategory &&
            categoryB == enemyCategory {

            handleBulletEnemyContact(
                bulletBody: contact.bodyA,
                enemyBody: contact.bodyB
            )

            return
        }

        if categoryA == enemyCategory &&
            categoryB == bulletCategory {

            handleBulletEnemyContact(
                bulletBody: contact.bodyB,
                enemyBody: contact.bodyA
            )

            return
        }

        if categoryA == playerCategory &&
            categoryB == enemyCategory {

            handlePlayerEnemyContact(
                enemyBody: contact.bodyB
            )

            return
        }

        if categoryA == enemyCategory &&
            categoryB == playerCategory {

            handlePlayerEnemyContact(
                enemyBody: contact.bodyA
            )
        }
    }

    private func handleBulletEnemyContact(
        bulletBody: SKPhysicsBody,
        enemyBody: SKPhysicsBody
    ) {

        guard let bullet =
            bulletBody.node as? Bullet else {
            return
        }

        guard let enemy =
            enemyBody.node as? Enemy else {
            return
        }

        guard enemy.parent != nil, bullet.parent != nil else {
            return
        }

        let hitPosition =
            enemy.position

        if enemy.userData?["finalBoss"] as? Bool == true,
           enemy.userData?["vulnerable"] as? Bool != true {
            bullet.removeFromParent()
            createHitFlash(at: hitPosition)
            if let shield = enemy.childNode(withName: "bossShield") {
                shield.run(.sequence([.fadeAlpha(to: 1, duration: 0.03), .fadeAlpha(to: 0.35, duration: 0.16)]))
            }
            return
        }

        enemy.health -=
            bullet.damage

        bullet.removeFromParent()

        createHitFlash(
            at: hitPosition
        )

        if enemy.health > 0,
           enemy.userData?["arrowHive"] as? Bool == true {
            enemy.userData?["lastHiveAttacked"] = elapsed
            launchHiveVolleyIfReady(from: enemy, minimumCooldown: 1.8)
        }

        if enemy.health <= 0 {

            destroyEnemy(
                enemy
            )

        } else {

            enemy.run(
                SKAction.sequence([
                    SKAction.scale(
                        to: 1.15,
                        duration: 0.05
                    ),

                    SKAction.scale(
                        to: 1.0,
                        duration: 0.07
                    )
                ])
            )
        }
    }

    private func handlePlayerEnemyContact(
        enemyBody: SKPhysicsBody
    ) {

        guard elapsed >= dashUntil else { return }
        guard !gameOver else {
            return
        }

        guard let enemy =
            enemyBody.node as? Enemy else {
            return
        }

        guard gameTime - lastDamageTime >= damageCooldown else { return }
        let enemyLastHit = enemy.userData?["lastContactDamage"] as? Double ?? -10
        guard gameTime - enemyLastHit >= enemyContactCooldown else { return }

        lastDamageTime =
            gameTime
        enemy.userData = enemy.userData ?? NSMutableDictionary()
        enemy.userData?["lastContactDamage"] = gameTime

        player.health -=
            enemy.damage * 0.8 * progression.damageMultiplier

        updateHUD()

        createPlayerDamageEffect()

        if player.health <= 0 {
            endGame()
        }
    }

    // MARK: - Enemy Destruction

    private func destroyEnemy(
        _ enemy: Enemy
    ) {

        let position =
            enemy.position

        let earnedScore =
            enemy.scoreValue

        let releasesSwarm = enemy.userData?["bossKind"] as? String == "carrier"
        let releasesOctagons = enemy.userData?["splitsIntoOctagons"] as? Bool == true

        enemy.removeAllActions()
        enemy.removeFromParent()

        if releasesSwarm {
            spawnCarrierMinions(at: position, count: 4)
        }
        if releasesOctagons {
            spawnOctagonFragments(at: position, count: 3)
        }

        score += earnedScore

        updateHUD()

        animateScoreChange()

        let isSentinel = enemy.userData?["sentinel"] as? Bool == true
        createPickup(at: position, value: isSentinel ? 400 + currentTier.number * 100 : max(15, earnedScore / 4))

        createExplosion(
            at: position
        )

        checkForTierCompletion()
    }

    private func animateScoreChange() {

        guard let label =
            scoreLabel else {
            return
        }

        label.removeAction(
            forKey: "scorePulse"
        )

        label.setScale(1.0)

        let pulse =
            SKAction.sequence([
                SKAction.scale(
                    to: 1.22,
                    duration: 0.07
                ),

                SKAction.scale(
                    to: 1.0,
                    duration: 0.12
                )
            ])

        label.run(
            pulse,
            withKey: "scorePulse"
        )
    }

    // MARK: - Hit Effect

    private func createHitFlash(
        at position: CGPoint
    ) {

        let flash = SKShapeNode(
            circleOfRadius: 8
        )

        flash.position = position
        flash.fillColor = .white
        flash.strokeColor = cyanColor
        flash.lineWidth = 2
        flash.zPosition = effectZ

        worldNode.addChild(
            flash
        )

        flash.run(
            SKAction.sequence([
                SKAction.group([
                    SKAction.scale(
                        to: 1.8,
                        duration: 0.08
                    ),

                    SKAction.fadeOut(
                        withDuration: 0.08
                    )
                ]),

                SKAction.removeFromParent()
            ])
        )
    }

    // MARK: - Explosion

    private func createExplosion(
        at position: CGPoint
    ) {

        let outerRing =
            SKShapeNode(
                circleOfRadius: 9
            )

        outerRing.position = position
        outerRing.fillColor = .clear
        outerRing.strokeColor = orangeColor
        outerRing.lineWidth = 3
        outerRing.zPosition = effectZ

        worldNode.addChild(
            outerRing
        )

        outerRing.run(
            SKAction.sequence([
                SKAction.group([
                    SKAction.scale(
                        to: 3.5,
                        duration: 0.20
                    ),

                    SKAction.fadeOut(
                        withDuration: 0.20
                    )
                ]),

                SKAction.removeFromParent()
            ])
        )

        let core =
            SKShapeNode(
                circleOfRadius: 7
            )

        core.position = position
        core.fillColor = .white
        core.strokeColor = orangeColor
        core.lineWidth = 2
        core.zPosition = effectZ + 1

        worldNode.addChild(
            core
        )

        core.run(
            SKAction.sequence([
                SKAction.group([
                    SKAction.scale(
                        to: 2.4,
                        duration: 0.12
                    ),

                    SKAction.fadeOut(
                        withDuration: 0.12
                    )
                ]),

                SKAction.removeFromParent()
            ])
        )

        for _ in 0..<8 {

            createExplosionParticle(
                at: position
            )
        }
    }

    private func createExplosionParticle(
        at position: CGPoint
    ) {

        let radius = CGFloat(
            Double.random(
                in: 1.5...3.0
            )
        )

        let particle = SKShapeNode(
            circleOfRadius: radius
        )

        particle.position = position

        particle.fillColor =
            Bool.random()
            ? orangeColor
            : cyanColor

        particle.strokeColor = .clear
        particle.zPosition = effectZ

        worldNode.addChild(
            particle
        )

        let angle = CGFloat(
            Double.random(
                in: 0...(Double.pi * 2)
            )
        )

        let distance = CGFloat(
            Double.random(
                in: 18...42
            )
        )

        let destination = CGPoint(
            x: position.x +
                cos(angle) *
                distance,

            y: position.y +
                sin(angle) *
                distance
        )

        let move = SKAction.move(
            to: destination,
            duration: 0.20
        )

        move.timingMode =
            SKActionTimingMode.easeOut

        let fade = SKAction.fadeOut(
            withDuration: 0.20
        )

        let scale = SKAction.scale(
            to: 0.2,
            duration: 0.20
        )

        particle.run(
            SKAction.sequence([
                SKAction.group([
                    move,
                    fade,
                    scale
                ]),

                SKAction.removeFromParent()
            ])
        )
    }

    // MARK: - Score Popup

    private func createScorePopup(
        amount: Int,
        at position: CGPoint
    ) {

        let label = makeLabel(
            text: "+\(amount)",
            fontSize: 14,
            fontName: "AvenirNext-Bold",
            color: .yellow
        )

        label.position = CGPoint(
            x: position.x,
            y: position.y + 20
        )

        label.zPosition =
            effectZ + 2

        worldNode.addChild(
            label
        )

        let move =
            SKAction.moveBy(
                x: 0,
                y: 28,
                duration: 0.45
            )

        move.timingMode =
            SKActionTimingMode.easeOut

        let fade =
            SKAction.fadeOut(
                withDuration: 0.45
            )

        let scale =
            SKAction.sequence([
                SKAction.scale(
                    to: 1.15,
                    duration: 0.08
                ),

                SKAction.scale(
                    to: 1.0,
                    duration: 0.10
                )
            ])

        label.run(
            SKAction.sequence([
                SKAction.group([
                    move,
                    fade,
                    scale
                ]),

                SKAction.removeFromParent()
            ])
        )
    }

    // MARK: - Player Damage

    private func createPlayerDamageEffect() {

        player.removeAction(
            forKey: "damageFlash"
        )

        let originalColor =
            player.fillColor

        let flash =
            SKAction.run {

                self.player.fillColor =
                    self.pinkColor

                self.player.strokeColor =
                    .white
            }

        let restore =
            SKAction.run {

                self.player.fillColor =
                    originalColor

                self.player.strokeColor =
                    .white
            }

        player.run(
            SKAction.sequence([
                flash,

                SKAction.wait(
                    forDuration: 0.08
                ),

                restore
            ]),

            withKey: "damageFlash"
        )

        createDamageOverlay()

        playDamageHaptic()
    }

    private func playDamageHaptic() {
        guard GameSettings.shared.hapticsEnabled else { return }
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.prepare()
        feedback.impactOccurred(intensity: 0.72)
    }

    private func createDamageOverlay() {

        let overlay =
            SKShapeNode(
                rectOf: size
            )

        overlay.position =
            CGPoint(
                x: 0,
                y: 0
            )

        overlay.fillColor =
            pinkColor.withAlphaComponent(
                0.16
            )

        overlay.strokeColor = .clear
        overlay.zPosition = 800

        cameraNode.addChild(
            overlay
        )

        overlay.run(
            SKAction.sequence([
                SKAction.fadeOut(
                    withDuration: 0.18
                ),

                SKAction.removeFromParent()
            ])
        )
    }

    private func screenShake() {

        guard !gameOver else {
            return
        }

        cameraNode.removeAction(
            forKey: "screenShake"
        )

        let originalPosition =
            cameraNode.position

        let actions: [SKAction] = [

            SKAction.moveBy(
                x: 5,
                y: 2,
                duration: 0.035
            ),

            SKAction.moveBy(
                x: -9,
                y: -4,
                duration: 0.035
            ),

            SKAction.moveBy(
                x: 7,
                y: 5,
                duration: 0.035
            ),

            SKAction.moveBy(
                x: -3,
                y: -3,
                duration: 0.035
            ),

            SKAction.move(
                to: originalPosition,
                duration: 0.035
            )
        ]

        cameraNode.run(
            SKAction.sequence(actions),
            withKey: "screenShake"
        )
    }

    // MARK: - Player Visuals

    private func updatePlayerVisuals() {

        guard player != nil else {
            return
        }

        let direction =
            aimJoystick.direction

        let magnitude =
            sqrt(
                direction.dx *
                direction.dx +
                direction.dy *
                direction.dy
            )

        if aimingTouch != nil &&
            magnitude > 0.15 {

            let angle =
                atan2(
                    direction.dy,
                    direction.dx
                )

            player.zRotation =
                angle
        }
    }

    // MARK: - Tier System

    private func prepareWave(for tier: Int) {
        wavePlan = TierWavePlan.forTier(tier)
        regularEnemiesRemaining = wavePlan.regularEnemies
        bossesRemaining = wavePlan.bossCount
        lastSpawnTime = gameTime - spawnInterval
    }

    private func checkForTierCompletion() {
        guard regularEnemiesRemaining == 0,
              bossesRemaining == 0,
              !worldNode.children.contains(where: { $0 is Enemy }),
              tierTransitionRemaining == nil else { return }
        tierTransitionRemaining = 2.2
        beginArenaShift(forTier: currentTier.number + 1)
    }

    private func advanceTierAfterClear() {
        let newTier = GameTier.tier(number: currentTier.number + 1)
        currentTier = newTier

        spawnInterval =
            newTier.spawnInterval

        enemySpeed =
            newTier.enemySpeed

        enemyHealth =
            newTier.enemyHealth

        updateTierAppearance()

        showTierAnnouncement()
        prepareWave(for: newTier.number)
        updateTierProgressLabel()
    }

    private func updateTierProgressLabel() {
        guard tierLabel != nil else { return }
        let alive = worldNode.children.reduce(into: 0) { if $1 is Enemy { $0 += 1 } }
        let remaining = regularEnemiesRemaining + bossesRemaining + alive
        tierLabel.text = "TIER \(currentTier.number)   /   \(remaining) HOSTILES"
    }

    private func updateTierAppearance() {

        let flash =
            SKShapeNode(
                rectOf: size
            )

        flash.position =
            CGPoint(
                x: 0,
                y: 0
            )

        flash.fillColor =
            purpleColor.withAlphaComponent(
                0.12
            )

        flash.strokeColor = .clear
        flash.zPosition = 700

        cameraNode.addChild(
            flash
        )

        flash.run(
            SKAction.sequence([
                SKAction.fadeOut(
                    withDuration: 0.35
                ),

                SKAction.removeFromParent()
            ])
        )

        tierLabel.removeAction(
            forKey: "tierPulse"
        )

        tierLabel.run(
            SKAction.sequence([
                SKAction.scale(
                    to: 1.2,
                    duration: 0.12
                ),

                SKAction.scale(
                    to: 1.0,
                    duration: 0.18
                )
            ]),

            withKey: "tierPulse"
        )

        updateHUD()
    }

    private func showTierAnnouncement() {

        tierAnnouncementNode?
            .removeFromParent()

        let container =
            SKNode()

        container.zPosition = 750

        let panel =
            SKShapeNode(
                rectOf: CGSize(
                    width: 210,
                    height: 48
                ),
                cornerRadius: 9
            )

        panel.fillColor =
            SKColor(
                red: 0.01,
                green: 0.02,
                blue: 0.05,
                alpha: 0.96
            )

        panel.strokeColor =
            purpleColor

        panel.lineWidth = 2

        container.addChild(
            panel
        )

        let small =
            makeLabel(
                text:
                    "TIER \(currentTier.number)",

                fontSize: 8,

                fontName:
                    "AvenirNext-Bold",

                color:
                    purpleColor
            )

        small.position =
            CGPoint(
                x: 0,
                y: 10
            )

        container.addChild(
            small
        )

        let title =
            makeLabel(
                text:
                    currentTier.name,

                fontSize: 13,

                fontName:
                    "AvenirNext-Bold",

                color:
                    .white
            )

        title.position =
            CGPoint(
                x: 0,
                y: -9
            )

        container.addChild(
            title
        )

        let hiddenY = size.height / 2 + 32
        let visibleY = size.height / 2 - currentSafeAreaInsets().top - 66
        container.position = CGPoint(x: 0, y: hiddenY)

        container.alpha = 0

        container.setScale(0.96)

        cameraNode.addChild(
            container
        )

        tierAnnouncementNode =
            container

        let slideDown = SKAction.moveTo(y: visibleY, duration: 0.24)
        slideDown.timingMode = .easeOut
        let appear = SKAction.group([
                SKAction.fadeIn(
                    withDuration: 0.16
                ),
                slideDown,
                SKAction.scale(
                    to: 1.0,
                    duration: 0.20
                )
            ])

        let wait =
            SKAction.wait(
                forDuration: 0.72
            )

        let retract = SKAction.moveTo(y: hiddenY, duration: 0.22)
        retract.timingMode = .easeIn
        let disappear = SKAction.group([
                SKAction.fadeOut(
                    withDuration: 0.18
                ),
                retract
            ])

        container.run(
            SKAction.sequence([
                appear,
                wait,
                disappear,
                SKAction.removeFromParent()
            ])
        )
    }

    // MARK: - Barriers

    private func removeBarriers() {

        let oldBarriers = barrierNode.children

        for barrier in oldBarriers {

            barrier.removeAllActions()

            barrier.run(
                SKAction.sequence([
                    SKAction.group([
                        SKAction.scale(
                            to: 0.85,
                            duration: 0.18
                        ),
                        SKAction.fadeOut(
                            withDuration: 0.18
                        )
                    ]),
                    SKAction.removeFromParent()
                ])
            )
        }
    }

    private func createBarriers(style: Int) {

        switch style {

        case 1:

            createSplitArena()

        case 2:

            createSpiralArena()

        case 3:

            createCrossfireArena()

        case 4:

            createHexRingArena()

        default:
            break
        }
    }

    // MARK: - Tier 2

    private func createSplitArena() {

        let cx = playableRect.midX
        let cy = playableRect.midY

        let wallWidth: CGFloat = min(
            145,
            playableRect.width * 0.20
        )

        let wallHeight: CGFloat = 22

        let verticalOffset: CGFloat = min(
            72,
            playableRect.height * 0.20
        )

        createBarrier(
            x: cx - 80,
            y: cy + verticalOffset,
            width: wallWidth,
            height: wallHeight,
            style: 1
        )

        createBarrier(
            x: cx + 80,
            y: cy - verticalOffset,
            width: wallWidth,
            height: wallHeight,
            style: 1
        )

        createBarrier(
            x: playableRect.minX + 105,
            y: cy - 78,
            width: 22,
            height: 65,
            style: 1
        )

        createBarrier(
            x: playableRect.maxX - 105,
            y: cy + 78,
            width: 22,
            height: 65,
            style: 1
        )
    }

    // MARK: - Tier 3

    private func createSpiralArena() {

        let cx = playableRect.midX
        let cy = playableRect.midY

        let horizontalLength = min(
            150,
            playableRect.width * 0.22
        )

        let verticalLength = min(
            105,
            playableRect.height * 0.30
        )

        let thickness: CGFloat = 20

        createBarrier(
            x: cx - 92,
            y: cy + 82,
            width: horizontalLength,
            height: thickness,
            style: 2
        )

        createBarrier(
            x: cx + 112,
            y: cy + 38,
            width: thickness,
            height: verticalLength,
            style: 2
        )

        createBarrier(
            x: cx + 65,
            y: cy - 62,
            width: horizontalLength,
            height: thickness,
            style: 2
        )

        createBarrier(
            x: cx - 48,
            y: cy - 82,
            width: thickness,
            height: verticalLength,
            style: 2
        )

        createBarrier(
            x: cx - 38,
            y: cy + 12,
            width: 72,
            height: thickness,
            style: 2
        )
    }

    // MARK: - Tier 4

    private func createCrossfireArena() {

        let cx = playableRect.midX
        let cy = playableRect.midY

        let longWall: CGFloat = min(
            130,
            playableRect.width * 0.19
        )

        let shortWall: CGFloat = min(
            82,
            playableRect.height * 0.24
        )

        let thickness: CGFloat = 20

        createBarrier(
            x: cx - 105,
            y: cy + 82,
            width: longWall,
            height: thickness,
            style: 3
        )

        createBarrier(
            x: cx - 155,
            y: cy + 40,
            width: thickness,
            height: shortWall,
            style: 3
        )

        createBarrier(
            x: cx + 105,
            y: cy + 82,
            width: longWall,
            height: thickness,
            style: 3
        )

        createBarrier(
            x: cx + 155,
            y: cy + 40,
            width: thickness,
            height: shortWall,
            style: 3
        )

        createBarrier(
            x: cx - 105,
            y: cy - 82,
            width: longWall,
            height: thickness,
            style: 3
        )

        createBarrier(
            x: cx - 155,
            y: cy - 40,
            width: thickness,
            height: shortWall,
            style: 3
        )

        createBarrier(
            x: cx + 105,
            y: cy - 82,
            width: longWall,
            height: thickness,
            style: 3
        )

        createBarrier(
            x: cx + 155,
            y: cy - 40,
            width: thickness,
            height: shortWall,
            style: 3
        )
    }

    // MARK: - Tier 5

    private func createHexRingArena() {

        let cx = playableRect.midX
        let cy = playableRect.midY

        let horizontalLength: CGFloat = min(
            100,
            playableRect.width * 0.15
        )

        let diagonalLength: CGFloat = min(
            78,
            playableRect.height * 0.22
        )

        let thickness: CGFloat = 18

        createAngledBarrier(
            center: CGPoint(
                x: cx - 70,
                y: cy + 78
            ),
            length: horizontalLength,
            thickness: thickness,
            angle: .pi / 6,
            style: 4
        )

        createAngledBarrier(
            center: CGPoint(
                x: cx + 70,
                y: cy + 78
            ),
            length: horizontalLength,
            thickness: thickness,
            angle: -.pi / 6,
            style: 4
        )

        createAngledBarrier(
            center: CGPoint(
                x: cx + 128,
                y: cy
            ),
            length: diagonalLength,
            thickness: thickness,
            angle: .pi / 2,
            style: 4
        )

        createAngledBarrier(
            center: CGPoint(
                x: cx + 70,
                y: cy - 78
            ),
            length: horizontalLength,
            thickness: thickness,
            angle: .pi / 6,
            style: 4
        )

        createAngledBarrier(
            center: CGPoint(
                x: cx - 70,
                y: cy - 78
            ),
            length: horizontalLength,
            thickness: thickness,
            angle: -.pi / 6,
            style: 4
        )

        createAngledBarrier(
            center: CGPoint(
                x: cx - 128,
                y: cy
            ),
            length: diagonalLength,
            thickness: thickness,
            angle: .pi / 2,
            style: 4
        )

        createAngledBarrier(
            center: CGPoint(
                x: cx - 35,
                y: cy + 32
            ),
            length: 48,
            thickness: 16,
            angle: -.pi / 4,
            style: 4
        )

        createAngledBarrier(
            center: CGPoint(
                x: cx + 35,
                y: cy - 32
            ),
            length: 48,
            thickness: 16,
            angle: -.pi / 4,
            style: 4
        )
    }

    // MARK: - Standard Barrier

    private func createBarrier(
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        style: Int
    ) {

        let edgePadding: CGFloat = 38

        let safeMinX =
            playableRect.minX +
            edgePadding +
            width / 2

        let safeMaxX =
            playableRect.maxX -
            edgePadding -
            width / 2

        let safeMinY =
            playableRect.minY +
            edgePadding +
            height / 2

        let safeMaxY =
            playableRect.maxY -
            edgePadding -
            height / 2

        let safeX = max(
            safeMinX,
            min(safeMaxX, x)
        )

        let safeY = max(
            safeMinY,
            min(safeMaxY, y)
        )

        let rect = CGRect(
            x: safeX - width / 2,
            y: safeY - height / 2,
            width: width,
            height: height
        )

        let barrier = Barrier(
            rect: rect,
            style: style
        )

        barrier.position = CGPoint(
            x: safeX,
            y: safeY
        )

        barrier.physicsBody = SKPhysicsBody(
            rectangleOf: CGSize(
                width: width,
                height: height
            )
        )

        barrier.physicsBody?.isDynamic = false

        barrier.physicsBody?.categoryBitMask =
            barrierCategory

        barrier.physicsBody?.collisionBitMask =
            playerCategory |
            enemyCategory |
            bulletCategory

        barrier.physicsBody?.contactTestBitMask =
            playerCategory |
            enemyCategory |
            bulletCategory

        barrier.physicsBody?.friction = 1.0
        barrier.physicsBody?.restitution = 0.0

        barrierNode.addChild(
            barrier
        )

        createBarrierGlow(
            for: barrier
        )

        createBarrierDetails(
            for: barrier,
            style: style
        )

        animateBarrierEntrance(
            barrier
        )
    }

    // MARK: - Angled Barrier

    private func createAngledBarrier(
        center: CGPoint,
        length: CGFloat,
        thickness: CGFloat,
        angle: CGFloat,
        style: Int
    ) {

        let edgePadding: CGFloat = 42

        let clampedX = max(
            playableRect.minX + edgePadding,
            min(
                playableRect.maxX - edgePadding,
                center.x
            )
        )

        let clampedY = max(
            playableRect.minY + edgePadding,
            min(
                playableRect.maxY - edgePadding,
                center.y
            )
        )

        let barrier = Barrier(
            rect: CGRect(
                x: -length / 2,
                y: -thickness / 2,
                width: length,
                height: thickness
            ),
            style: style
        )

        barrier.position = CGPoint(
            x: clampedX,
            y: clampedY
        )

        barrier.zRotation = angle

        barrier.physicsBody = SKPhysicsBody(
            rectangleOf: CGSize(
                width: length,
                height: thickness
            )
        )

        barrier.physicsBody?.isDynamic = false

        barrier.physicsBody?.categoryBitMask =
            barrierCategory

        barrier.physicsBody?.collisionBitMask =
            playerCategory |
            enemyCategory |
            bulletCategory

        barrier.physicsBody?.contactTestBitMask =
            playerCategory |
            enemyCategory |
            bulletCategory

        barrier.physicsBody?.friction = 1.0
        barrier.physicsBody?.restitution = 0.0

        barrierNode.addChild(
            barrier
        )

        createBarrierGlow(
            for: barrier
        )

        createBarrierDetails(
            for: barrier,
            style: style
        )

        animateBarrierEntrance(
            barrier
        )
    }

    // MARK: - Barrier Details

    private func createBarrierDetails(
        for barrier: Barrier,
        style: Int
    ) {

        guard let path = barrier.path else {
            return
        }

        let innerLine = SKShapeNode(
            path: path
        )

        innerLine.position = barrier.position

        innerLine.fillColor = .clear

        innerLine.strokeColor =
            barrier.strokeColor.withAlphaComponent(0.55)

        innerLine.lineWidth = 1

        innerLine.zPosition = 0

        barrierNode.addChild(
            innerLine
        )

        let halfWidth =
            barrier.barrierRect.width / 2

        let points: [CGPoint] = [

            CGPoint(
                x: -halfWidth,
                y: 0
            ),

            CGPoint(
                x: halfWidth,
                y: 0
            )
        ]

        for point in points {

            let node = SKShapeNode(
                circleOfRadius: 2.5
            )

            node.position = point

            node.fillColor = cyanColor
            node.strokeColor = .clear
            node.glowWidth = 4
            node.zPosition = 2

            barrier.addChild(
                node
            )

            let pulse = SKAction.sequence([

                SKAction.fadeAlpha(
                    to: 0.35,
                    duration: 0.6
                ),

                SKAction.fadeAlpha(
                    to: 1.0,
                    duration: 0.6
                )
            ])

            node.run(
                SKAction.repeatForever(
                    pulse
                )
            )
        }
    }

    // MARK: - Barrier Glow

    private func createBarrierGlow(
        for barrier: Barrier
    ) {

        guard let path = barrier.path else {
            return
        }

        let glow = SKShapeNode(
            path: path
        )

        glow.position =
            barrier.position

        glow.fillColor = .clear

        glow.strokeColor =
            barrier.strokeColor.withAlphaComponent(
                0.16
            )

        glow.lineWidth =
            barrier.lineWidth + 10

        glow.zPosition = -1
        glow.blendMode = .add

        barrierNode.addChild(
            glow
        )

        let pulse = SKAction.sequence([

            SKAction.fadeAlpha(
                to: 0.35,
                duration: 0.9
            ),

            SKAction.fadeAlpha(
                to: 0.75,
                duration: 0.9
            )
        ])

        glow.run(
            SKAction.repeatForever(
                pulse
            )
        )
    }

    // MARK: - Barrier Entrance Animation

    private func animateBarrierEntrance(
        _ barrier: Barrier
    ) {

        barrier.alpha = 0
        barrier.setScale(0.92)

        let appear = SKAction.group([

            SKAction.fadeIn(
                withDuration: 0.20
            ),

            SKAction.scale(
                to: 1.0,
                duration: 0.20
            )
        ])

        barrier.run(
            appear
        )
    }

    // MARK: - Game Over

    private func endGame() {

        guard !gameOver else {
            return
        }

        gameOver = true
        UserDefaults.standard.set(max(score, UserDefaults.standard.integer(forKey: "polystrikeBestScore")), forKey: "polystrikeBestScore")
        worldNode.isPaused = true

        moveJoystick.end()
        aimJoystick.end()

        movementTouch = nil
        aimingTouch = nil

        updateHUD()

        createGameOverScreen()
    }

    private func createGameOverScreen() {

        gameOverOverlay =
            SKShapeNode(
                rectOf: size
            )

        gameOverOverlay.position =
            CGPoint(
                x: 0,
                y: 0
            )

        gameOverOverlay.fillColor =
            SKColor(
                red: 0,
                green: 0,
                blue: 0,
                alpha: 0.72
            )

        gameOverOverlay.strokeColor = .clear
        gameOverOverlay.zPosition = 900
        gameOverOverlay.alpha = 0

        cameraNode.addChild(
            gameOverOverlay
        )

        gameOverPanel =
            SKShapeNode(
                rectOf: CGSize(
                    width: 400,
                    height: 285
                ),
                cornerRadius: 18
            )

        gameOverPanel.position =
            CGPoint(
                x: 0,
                y: 5
            )

        gameOverPanel.fillColor =
            SKColor(
                red: 0.01,
                green: 0.015,
                blue: 0.035,
                alpha: 0.98
            )

        gameOverPanel.strokeColor =
            pinkColor.withAlphaComponent(
                0.65
            )

        gameOverPanel.lineWidth = 2
        gameOverPanel.zPosition = 901
        gameOverPanel.alpha = 0

        gameOverPanel.setScale(
            0.85
        )

        cameraNode.addChild(
            gameOverPanel
        )

        gameOverLabel =
            makeLabel(
                text: "GAME OVER",
                fontSize: 34,
                fontName: "AvenirNext-Bold",
                color: pinkColor
            )

        gameOverLabel.position =
            CGPoint(
                x: 0,
                y: 78
            )

        gameOverPanel.addChild(
            gameOverLabel
        )

        let divider =
            SKShapeNode(
                rectOf: CGSize(
                    width: 220,
                    height: 1
                )
            )

        divider.fillColor =
            pinkColor.withAlphaComponent(
                0.35
            )

        divider.strokeColor = .clear

        divider.position =
            CGPoint(
                x: 0,
                y: 50
            )

        gameOverPanel.addChild(
            divider
        )

        let scoreTitle =
            makeLabel(
                text: "FINAL SCORE",
                fontSize: 9,
                fontName: "AvenirNext-Bold",
                color: SKColor(
                    white: 0.55,
                    alpha: 1
                )
            )

        scoreTitle.position =
            CGPoint(
                x: 0,
                y: 26
            )

        gameOverPanel.addChild(
            scoreTitle
        )

        finalScoreLabel =
            makeLabel(
                text: "\(score)",
                fontSize: 29,
                fontName: "AvenirNext-Bold",
                color: .white
            )

        finalScoreLabel.position =
            CGPoint(
                x: 0,
                y: -4
            )

        gameOverPanel.addChild(
            finalScoreLabel
        )

        pointsEarnedLabel =
            makeLabel(
                text: "\(runCoins) FLUX BANKED • BEST \(UserDefaults.standard.integer(forKey: "polystrikeBestScore"))",
                fontSize: 11,
                fontName: "AvenirNext-Bold",
                color: .yellow
            )

        pointsEarnedLabel.position =
            CGPoint(
                x: 0,
                y: -35
            )

        gameOverPanel.addChild(
            pointsEarnedLabel
        )

        mainMenuButton =
            SKShapeNode(
                rectOf: CGSize(
                    width: 250,
                    height: 48
                ),
                cornerRadius: 10
            )

        mainMenuButton.position =
            CGPoint(
                x: 0,
                y: -91
            )

        mainMenuButton.fillColor =
            SKColor(
                red: 0.02,
                green: 0.08,
                blue: 0.12,
                alpha: 1
            )

        mainMenuButton.strokeColor =
            cyanColor

        mainMenuButton.lineWidth = 2

        mainMenuButton.name =
            "mainMenuButton"

        gameOverPanel.addChild(
            mainMenuButton
        )

        mainMenuLabel =
            makeLabel(
                text: "MAIN MENU",
                fontSize: 14,
                fontName: "AvenirNext-Bold",
                color: cyanColor
            )

        mainMenuLabel.position = .zero

        mainMenuLabel.name =
            "mainMenuButton"

        mainMenuButton.addChild(
            mainMenuLabel
        )

        gameOverOverlay.run(
            SKAction.fadeIn(
                withDuration: 0.25
            )
        )

        gameOverPanel.run(
            SKAction.sequence([
                SKAction.wait(
                    forDuration: 0.05
                ),

                SKAction.group([
                    SKAction.fadeIn(
                        withDuration: 0.25
                    ),

                    SKAction.scale(
                        to: 1.0,
                        duration: 0.25
                    )
                ])
            ])
        )

        pulseMainMenuButton()
    }

    private func pulseMainMenuButton() {

        guard gameOver else {
            return
        }

        let pulse =
            SKAction.sequence([
                SKAction.fadeAlpha(
                    to: 0.70,
                    duration: 0.75
                ),

                SKAction.fadeAlpha(
                    to: 1.0,
                    duration: 0.75
                )
            ])

        mainMenuButton.run(
            SKAction.repeatForever(
                pulse
            ),
            withKey: "buttonPulse"
        )
    }

    // MARK: - Touches

    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {

        for touch in touches {

            let location =
                touch.location(
                    in: cameraNode
                )

            if gameOver {

                handleGameOverTouch(
                    at: location
                )

                continue
            }

            if pausedRun { resumeRun(); continue }
            let tappedNames = cameraNode.nodes(at: location).compactMap { $0.name ?? $0.parent?.name }
            if tappedNames.contains("dashAbility") { activateDash(); continue }
            if tappedNames.contains("bombAbility") { activateBomb(); continue }
            if cameraNode.nodes(at: location).contains(where: { $0.name == "pauseRun" }) {
                pauseRun(); continue
            }


            let leftHalf =
                location.x < 0

            if leftHalf &&
                movementTouch == nil {

                movementTouch =
                    touch

                moveJoystick.begin(
                    at: location
                )

                showJoystick(
                    moveJoystick
                )

                continue
            }

            if !leftHalf &&
                aimingTouch == nil {

                aimingTouch =
                    touch

                aimJoystick.begin(
                    at: location
                )

                showJoystick(
                    aimJoystick
                )

                continue
            }
        }
    }

    override func touchesMoved(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {

        for touch in touches {

            let location =
                touch.location(
                    in: cameraNode
                )

            if touch === movementTouch {

                moveJoystick.update(
                    at: location
                )
            }

            if touch === aimingTouch {

                aimJoystick.update(
                    at: location
                )
            }
        }
    }

    override func touchesEnded(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {

        for touch in touches {

            if touch === movementTouch {

                movementTouch = nil

                moveJoystick.end()

            }

            if touch === aimingTouch {

                aimingTouch = nil

                aimJoystick.end()

            }
        }
    }

    override func touchesCancelled(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {

        touchesEnded(
            touches,
            with: event
        )
    }

    // MARK: - Game Over Touch

    private func handleGameOverTouch(
        at location: CGPoint
    ) {

        guard mainMenuButton != nil else {
            return
        }

        /*
         Touches arrive in scene coordinates.

         Convert them into camera coordinates because the game-over
         UI now belongs to the camera.
        */

        let cameraLocation = location

        if mainMenuButton.contains(
            cameraLocation
        ) {

            returnToMainMenu()
        }
    }

    private func returnToMainMenu() {

        guard !isTransitioning else {
            return
        }

        isTransitioning = true

        mainMenuButton.removeAction(
            forKey: "buttonPulse"
        )

        let menu =
            MainMenuScene(
                size: size
            )

        menu.scaleMode =
            scaleMode

        let transition =
            SKTransition.fade(
                withDuration: 0.35
            )

        view?.presentScene(
            menu,
            transition: transition
        )
    }

    // MARK: - Restart

    func restartGame() {

        guard let currentView =
                view else {
            return
        }

        let newScene =
            GameScene(
                size:
                    currentView.bounds.size
            )

        newScene.scaleMode =
            scaleMode

        currentView.presentScene(
            newScene,
            transition:
                SKTransition.fade(
                    withDuration: 0.25
                )
        )
    }
}

private extension GameScene {
    func createDesignedArena() {
        // Four linked courts around a generous central clearing. Gaps remain wider
        // than the navigation cells and ship diameter, so every court has exits.
        let cx = worldBounds.midX, cy = worldBounds.midY
        for sx: CGFloat in [-1, 1] {
            for sy: CGFloat in [-1, 1] {
                let x = cx + sx * worldBounds.width * 0.24
                let y = cy + sy * worldBounds.height * 0.25
                let w = min(460, worldBounds.width * 0.18)
                let h = min(220, worldBounds.height * 0.20)
                addArenaWall(CGRect(x: x - w / 2, y: y - h / 2, width: w, height: 26), style: sx == sy ? 1 : 2)
                addArenaWall(CGRect(x: x - w / 2, y: y + h / 2, width: w, height: 26), style: sx == sy ? 1 : 2)
                addArenaWall(CGRect(x: x + sx * (w / 2 + 100), y: y - 45, width: 28, height: 90), style: 1)
            }
        }
        for sx: CGFloat in [-1, 1] {
            addArenaWall(CGRect(x: cx + sx * 240 - 24, y: cy - 60, width: 48, height: 120), style: 1)
        }
    }

    func addArenaWall(_ rect: CGRect, style: Int) {
        wallRects.append(rect)
        let barrier = Barrier(rect: rect, style: style)
        barrier.glowWidth = 2
        barrier.lineWidth = 1.5
        barrier.fillColor = SKColor(red: 0.02, green: 0.06, blue: 0.09, alpha: 1)
        barrier.physicsBody = SKPhysicsBody(rectangleOf: rect.size)
        barrier.physicsBody?.isDynamic = false
        barrier.physicsBody?.categoryBitMask = barrierCategory
        barrier.physicsBody?.collisionBitMask = 0
        barrier.physicsBody?.contactTestBitMask = bulletCategory
        barrierNode.addChild(barrier)
    }

    func navIndex(_ point: CGPoint) -> Int {
        let x = max(0, min(navColumns - 1, Int((point.x - worldBounds.minX) / cellSize)))
        let y = max(0, min(navRows - 1, Int((point.y - worldBounds.minY) / cellSize)))
        return y * navColumns + x
    }
    func navPoint(_ index: Int) -> CGPoint {
        CGPoint(x: worldBounds.minX + (CGFloat(index % navColumns) + 0.5) * cellSize,
                y: worldBounds.minY + (CGFloat(index / navColumns) + 0.5) * cellSize)
    }
    func neighbors(_ index: Int) -> [Int] {
        let x = index % navColumns, y = index / navColumns
        var result: [Int] = []
        if x > 0 { result.append(index - 1) }
        if x + 1 < navColumns { result.append(index + 1) }
        if y > 0 { result.append(index - navColumns) }
        if y + 1 < navRows { result.append(index + navColumns) }
        return result.filter { !blockedCells.contains($0) }    }
    func buildNavigation() {
        navColumns = Int(ceil(worldBounds.width / cellSize))
        navRows = Int(ceil(worldBounds.height / cellSize))
        blockedCells.removeAll()
        for index in 0..<(navColumns * navRows) {
            let p = navPoint(index)
            if !worldBounds.insetBy(dx: 20, dy: 20).contains(p) ||
                wallRects.contains(where: { $0.insetBy(dx: -24, dy: -24).contains(p) }) {
                blockedCells.insert(index)
            }
        }
        updateNavigation()
    }
    func updateNavigation() {
        var goal = navIndex(player.position)
        if blockedCells.contains(goal) {
            guard let nearest = (0..<(navColumns * navRows)).filter({ !blockedCells.contains($0) }).min(by: {
                hypot(navPoint($0).x - player.position.x, navPoint($0).y - player.position.y) <
                hypot(navPoint($1).x - player.position.x, navPoint($1).y - player.position.y)
            }) else { return }
            goal = nearest
        }
        navDistances = [goal: 0]
        var queue = [goal], cursor = 0
        while cursor < queue.count {
            let current = queue[cursor]; cursor += 1
            for next in neighbors(current) where navDistances[next] == nil {
                navDistances[next] = navDistances[current, default: 0] + 1
                queue.append(next)
            }
        }
    }
    func clearPath(from a: CGPoint, to b: CGPoint) -> Bool {
        let steps = max(1, Int(ceil(hypot(b.x - a.x, b.y - a.y) / 16)))
        for step in 0...steps {
            let t = CGFloat(step) / CGFloat(steps)
            let p = CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
            if wallRects.contains(where: { $0.insetBy(dx: -22, dy: -22).contains(p) }) { return false }
        }
        return true
    }
    func navigationTarget(from point: CGPoint) -> CGPoint {
        if clearPath(from: point, to: player.position) { return player.position }
        let rawIndex = navIndex(point)
        let index: Int
        if blockedCells.contains(rawIndex) || navDistances[rawIndex] == nil {
            guard let reachable = navDistances.keys.min(by: {
                hypot(navPoint($0).x - point.x, navPoint($0).y - point.y) <
                hypot(navPoint($1).x - point.x, navPoint($1).y - point.y)
            }) else { return player.position }
            index = reachable
        } else {
            index = rawIndex
        }
        guard let next = neighbors(index).min(by: { navDistances[$0, default: Int.max] < navDistances[$1, default: Int.max] }),
              navDistances[next] != nil else { return navPoint(index) }
        return navPoint(next)
    }

    func nearestReachableNavigationPoint(to point: CGPoint) -> CGPoint {
        navDistances.keys.min(by: {
            hypot(navPoint($0).x - point.x, navPoint($0).y - point.y) <
            hypot(navPoint($1).x - point.x, navPoint($1).y - point.y)
        }).map(navPoint) ?? activeArena.nearestFloor(to: point)
    }

    func createPickup(at point: CGPoint, value: Int) {
        // Bound dormant drops during long runs without awarding uncollected currency.
        let drops = worldNode.children.filter { $0.name == "fluxPickup" }
        if drops.count >= 180 { drops.first?.removeFromParent() }
        let coin = FluxPickup(value: value)
        coin.position = point
        worldNode.addChild(coin)
        coin.run(.sequence([.wait(forDuration: 25), .fadeOut(withDuration: 3), .removeFromParent()]))
    }
    func updatePickups(deltaTime: TimeInterval) {
        for coin in worldNode.children where coin.name == "fluxPickup" {
            let dx = player.position.x - coin.position.x, dy = player.position.y - coin.position.y
            let distance = hypot(dx, dy)
            if distance < 25 {
                if let pickup = coin as? FluxPickup { collectPickup(pickup) }
            } else if distance < progression.magnetRange && clearPath(from: coin.position, to: player.position) {
                let step = min(distance, CGFloat(deltaTime) * 420)
                coin.position.x += dx / distance * step
                coin.position.y += dy / distance * step
            }
        }
    }
    @objc func applicationInterrupted() { if !gameOver { pauseRun() } }
    func pauseRun() {
        guard !pausedRun else { return }
        pausedRun = true
        worldNode.isPaused = true
        movementTouch = nil; aimingTouch = nil
        moveJoystick.end(); aimJoystick.end()
        moveJoystick.alpha = 0; aimJoystick.alpha = 0
        let shade = SKShapeNode(rectOf: size)
        shade.fillColor = SKColor.black.withAlphaComponent(0.8)
        shade.strokeColor = .clear
        shade.zPosition = 850
        let label = makeLabel(text: "PAUSED • TAP TO RESUME", fontSize: 20, fontName: "AvenirNext-Bold", color: .cyan)
        shade.addChild(label)
        cameraNode.addChild(shade)
        pausePanel = shade
    }
    func resumeRun() {
        pausedRun = false
        moveJoystick.refreshVisibility()
        aimJoystick.refreshVisibility()
        worldNode.isPaused = false
        pausePanel?.removeFromParent()
        pausePanel = nil
        gameTime = 0
    }
}

private extension GameScene {
    func launchHiveVolleyIfReady(from enemy: Enemy, minimumCooldown: TimeInterval) {
        let lastLaunch = enemy.userData?["lastHiveLaunch"] as? Double ?? -10
        guard elapsed - lastLaunch >= minimumCooldown else { return }
        enemy.userData?["lastHiveLaunch"] = elapsed

        if let orbit = enemy.childNode(withName: "enemyDetailHiveOrbit") {
            orbit.run(.sequence([
                .group([.scale(to: 1.28, duration: 0.10), .fadeAlpha(to: 0.55, duration: 0.10)]),
                .group([.scale(to: 1.0, duration: 0.14), .fadeAlpha(to: 1.0, duration: 0.14)])
            ]), withKey: "hiveLaunch")
        }

        let spreads: [CGFloat] = [-0.24, -0.14, -0.05, 0.05, 0.14, 0.24]
        for index in 0..<6 {
            let launchAngle = CGFloat(index) * .pi / 3
            let missilePath = CGMutablePath()
            missilePath.move(to: CGPoint(x: 13, y: 0))
            missilePath.addLine(to: CGPoint(x: -8, y: 7))
            missilePath.addLine(to: CGPoint(x: -3, y: 0))
            missilePath.addLine(to: CGPoint(x: -8, y: -7))
            missilePath.closeSubpath()
            let missile = SKShapeNode(path: missilePath)
            missile.name = "hiveMissile"
            missile.position = CGPoint(
                x: enemy.position.x + cos(launchAngle) * 19,
                y: enemy.position.y + sin(launchAngle) * 19
            )
            missile.zRotation = launchAngle
            missile.fillColor = index.isMultiple(of: 2) ? NeonColors.orange : NeonColors.pink
            missile.strokeColor = .white
            missile.lineWidth = 1.5
            missile.glowWidth = 7
            missile.zPosition = 15
            missile.setScale(0.25)

            let exhaust = SKShapeNode(rectOf: CGSize(width: 18, height: 3), cornerRadius: 1.5)
            exhaust.position = CGPoint(x: -11, y: 0)
            exhaust.fillColor = .white
            exhaust.strokeColor = .clear
            exhaust.glowWidth = 5
            exhaust.zPosition = -1
            missile.addChild(exhaust)
            exhaust.run(.repeatForever(.sequence([.scaleX(to: 1.45, duration: 0.07), .scaleX(to: 0.7, duration: 0.09)])))

            missile.physicsBody = SKPhysicsBody(polygonFrom: missilePath)
            missile.physicsBody?.affectedByGravity = false
            missile.physicsBody?.categoryBitMask = 16
            missile.physicsBody?.collisionBitMask = 0
            missile.physicsBody?.contactTestBitMask = playerCategory | barrierCategory
            missile.physicsBody?.usesPreciseCollisionDetection = true
            worldNode.addChild(missile)

            let spread = spreads[index]
            missile.run(.sequence([
                .wait(forDuration: Double(index) * 0.025),
                .group([
                    .scale(to: 1.0, duration: 0.16),
                    .sequence([.fadeAlpha(to: 0.65, duration: 0.08), .fadeAlpha(to: 1.0, duration: 0.08)])
                ]),
                .run { [weak self, weak missile] in
                    guard let self, let missile, missile.parent != nil else { return }
                    let angle = atan2(self.player.position.y - missile.position.y, self.player.position.x - missile.position.x) + spread
                    missile.zRotation = angle
                    let direction = CGVector(dx: cos(angle), dy: sin(angle))
                    missile.run(.sequence([
                        .moveBy(x: direction.dx * 1_250, y: direction.dy * 1_250, duration: 1.55),
                        .removeFromParent()
                    ]), withKey: "flight")
                },
                .wait(forDuration: 1.7),
                .removeFromParent()
            ]))
        }
    }

    func fireEnemyProjectile(from enemy: Enemy, angleOffset: CGFloat = 0) {
        guard !gameOver else { return }
        let angle = atan2(player.position.y - enemy.position.y, player.position.x - enemy.position.x) + angleOffset
        let direction = CGVector(dx: cos(angle), dy: sin(angle))
        let shot = SKShapeNode(circleOfRadius: 5)
        shot.fillColor = .yellow
        shot.strokeColor = .orange
        shot.glowWidth = 3
        shot.zPosition = 14
        shot.position = enemy.position
        let tail = SKShapeNode(rectOf: CGSize(width: 20, height: 3), cornerRadius: 1.5)
        tail.position = CGPoint(x: -10, y: 0)
        tail.fillColor = SKColor.orange.withAlphaComponent(0.75)
        tail.strokeColor = .clear
        tail.glowWidth = 4
        tail.zPosition = -1
        shot.addChild(tail)
        shot.zRotation = angle
        shot.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        shot.physicsBody?.affectedByGravity = false
        shot.physicsBody?.categoryBitMask = 16
        shot.physicsBody?.collisionBitMask = 0
        shot.physicsBody?.contactTestBitMask = playerCategory | barrierCategory
        shot.physicsBody?.usesPreciseCollisionDetection = true
        worldNode.addChild(shot)
        shot.run(.sequence([.moveBy(x: direction.dx * 1100, y: direction.dy * 1100, duration: 3.7), .removeFromParent()]))
    }
}

private extension GameScene {
    func spawnSentinel(tier: Int) {
        let enemy = Enemy()
        let isFinal = TierWavePlan.isFinalBossTier(tier)
        let kind = isFinal ? "apex" : ["gunner", "carrier", "pulse"][tier % 3]
        enemy.health = isFinal ? enemyHealth * 18 + 500 : enemyHealth * 5 + 100
        enemy.maxHealth = enemy.health
        enemy.moveSpeed = isFinal ? min(105, enemySpeed * 0.48) : min(145, enemySpeed * (kind == "carrier" ? 0.62 : 0.78))
        enemy.damage = isFinal ? 30 : 22
        enemy.scoreValue = currentTier.killScore * (isFinal ? 24 : 8)
        enemy.position = randomSpawnPosition()
        enemy.userData = [
            "sentinel": true,
            "bossKind": kind,
            "ranged": kind != "carrier",
            "lastFire": elapsed,
            "healthBarWidth": isFinal ? CGFloat(86) : CGFloat(50)
        ]
        if isFinal {
            enemy.userData?["finalBoss"] = true
            enemy.userData?["bossPhase"] = 0
            enemy.userData?["phaseEnds"] = elapsed + 5.5
            enemy.userData?["phaseTitle"] = "EXPOSED"
            enemy.userData?["vulnerable"] = true
        }
        let path = CGMutablePath()
        let sides = kind == "carrier" ? 8 : 6
        let radius: CGFloat = isFinal ? 38 : 25
        for i in 0..<sides {
            let angle = CGFloat(i) * .pi * 2 / CGFloat(sides)
            let p = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        enemy.path = path
        enemy.strokeColor = .orange
        enemy.fillColor = SKColor(red: 0.3, green: 0.04, blue: 0.02, alpha: 1)
        enemy.lineWidth = 3
        enemy.glowWidth = 5
        enemy.configureVisual(archetype: kind == "carrier" ? 4 : (kind == "pulse" ? 0 : 3))
        if let ring = enemy.childNode(withName: "enemyDetailTargetingRing") as? SKShapeNode {
            ring.setScale(isFinal ? 2.1 : 1.35)
            ring.strokeColor = .orange
        }
        if isFinal {
            let shield = SKShapeNode(circleOfRadius: 44)
            shield.name = "bossShield"
            shield.fillColor = SKColor.cyan.withAlphaComponent(0.05)
            shield.strokeColor = .cyan
            shield.lineWidth = 2
            shield.glowWidth = 5
            shield.alpha = 0
            enemy.addChild(shield)
        }
        let health = makeLabel(text: isFinal ? "APEX SENTINEL" : "SENTINEL", fontSize: 9, fontName: "AvenirNext-Bold", color: .orange)
        health.name = "sentinelHealth"
        health.position = CGPoint(x: 0, y: isFinal ? 54 : 36)
        enemy.addChild(health)
        let bar = SKShapeNode(rectOf: CGSize(width: isFinal ? 86 : 50, height: isFinal ? 5 : 3))
        bar.name = "sentinelBar"
        bar.fillColor = .orange
        bar.strokeColor = .clear
        bar.position = CGPoint(x: 0, y: isFinal ? 45 : 29)
        enemy.addChild(bar)
        worldNode.addChild(enemy)
        createEnemySpawnEffect(at: enemy.position)
    }

    func spawnCarrierMinions(at position: CGPoint, count: Int) {
        for index in 0..<count {
            let angle = CGFloat(index) * .pi * 2 / CGFloat(count)
            let minion = Enemy()
            minion.health = max(18, enemyHealth * 0.45)
            minion.maxHealth = minion.health
            minion.moveSpeed = min(220, enemySpeed * 1.12)
            minion.damage = 8
            minion.scoreValue = max(25, currentTier.killScore / 3)
            minion.position = activeArena.nearestFloor(to: CGPoint(
                x: position.x + cos(angle) * 55,
                y: position.y + sin(angle) * 55
            ))
            minion.strokeColor = .magenta
            minion.fillColor = SKColor.magenta.withAlphaComponent(0.28)
            minion.configureVisual(archetype: 4)
            worldNode.addChild(minion)
        }
    }

    func spawnOctagonFragments(at position: CGPoint, count: Int) {
        for index in 0..<count {
            let angle = CGFloat(index) * .pi * 2 / CGFloat(count)
            let fragment = Enemy()
            fragment.health = max(12, enemyHealth * 0.34)
            fragment.maxHealth = fragment.health
            fragment.moveSpeed = min(245, enemySpeed * 1.22)
            fragment.damage = 6
            fragment.scoreValue = max(20, currentTier.killScore / 4)
            let proposed = CGPoint(x: position.x + cos(angle) * 42, y: position.y + sin(angle) * 42)
            fragment.position = activeArena.containsShip(at: proposed) ? proposed : activeArena.nearestFloor(to: proposed)
            fragment.strokeColor = SKColor(red: 0.38, green: 0.84, blue: 1, alpha: 1)
            fragment.fillColor = SKColor(red: 0.02, green: 0.16, blue: 0.42, alpha: 0.86)
            let octagon = CGMutablePath()
            for vertex in 0..<8 {
                let vertexAngle = CGFloat(vertex) * .pi / 4 + .pi / 8
                let point = CGPoint(x: cos(vertexAngle) * 12, y: sin(vertexAngle) * 12)
                if vertex == 0 { octagon.move(to: point) } else { octagon.addLine(to: point) }
            }
            octagon.closeSubpath()
            fragment.path = octagon
            fragment.physicsBody = SKPhysicsBody(circleOfRadius: 12)
            fragment.physicsBody?.affectedByGravity = false
            fragment.physicsBody?.allowsRotation = false
            fragment.physicsBody?.categoryBitMask = enemyCategory
            fragment.physicsBody?.collisionBitMask = 0
            fragment.physicsBody?.contactTestBitMask = bulletCategory | playerCategory
            fragment.configureVisual(archetype: 5)
            fragment.setScale(0.82)
            worldNode.addChild(fragment)
            createEnemySpawnEffect(at: fragment.position)
        }
    }

    func updateFinalBoss(_ enemy: Enemy) {
        let phase = enemy.userData?["bossPhase"] as? Int ?? 0
        let phaseEnds = enemy.userData?["phaseEnds"] as? Double ?? elapsed
        if elapsed >= phaseEnds {
            beginFinalBossPhase((phase + 1) % 3, for: enemy)
            return
        }

        guard phase == 1 else { return }
        let lastFire = enemy.userData?["lastFire"] as? Double ?? -10
        guard elapsed - lastFire >= 0.42 else { return }
        enemy.userData?["lastFire"] = elapsed
        let volley = enemy.userData?["volley"] as? Int ?? 0
        enemy.userData?["volley"] = volley + 1
        let sweep = CGFloat((volley % 5) - 2) * 0.09
        for offset: CGFloat in [-0.2, 0, 0.2] {
            fireEnemyProjectile(from: enemy, angleOffset: offset + sweep)
        }
    }

    func beginFinalBossPhase(_ phase: Int, for enemy: Enemy) {
        enemy.userData?["bossPhase"] = phase
        enemy.userData?["lastFire"] = elapsed
        let shield = enemy.childNode(withName: "bossShield")
        switch phase {
        case 0:
            enemy.userData?["phaseTitle"] = "EXPOSED"
            enemy.userData?["phaseEnds"] = elapsed + 5.5
            enemy.userData?["vulnerable"] = true
            shield?.run(.fadeOut(withDuration: 0.25))
        case 1:
            enemy.userData?["phaseTitle"] = "BARRAGE"
            enemy.userData?["phaseEnds"] = elapsed + 4.2
            enemy.userData?["vulnerable"] = false
            shield?.run(.fadeAlpha(to: 0.35, duration: 0.2))
        default:
            enemy.userData?["phaseTitle"] = "REINFORCEMENTS"
            enemy.userData?["phaseEnds"] = elapsed + 3.2
            enemy.userData?["vulnerable"] = false
            shield?.run(.fadeAlpha(to: 0.35, duration: 0.2))
            let existingAdds = worldNode.children.filter {
                $0 is Enemy && $0 !== enemy && $0.userData?["finalBoss"] as? Bool != true
            }.count
            spawnCarrierMinions(at: enemy.position, count: max(0, min(3, 6 - existingAdds)))
        }
        createEnemySpawnEffect(at: enemy.position)
    }
}


final class FluxPickup: SKShapeNode {
    let value: Int
    init(value: Int) {
        self.value = max(0, value)
        super.init()
        path = CGPath(roundedRect: CGRect(x: -6, y: -6, width: 12, height: 12), cornerWidth: 1, cornerHeight: 1, transform: nil)
        name = "fluxPickup"
        zRotation = .pi / 4
        fillColor = NeonColors.green
        strokeColor = NeonColors.green
        glowWidth = 2
        zPosition = 12
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

extension GameScene {
    /// A reward is banked once, on collection, and never changes the run score.
    func collectPickup(_ pickup: FluxPickup) {
        guard pickup.parent != nil else { return }
        pickup.removeFromParent()
        let reward = pickup.value + pickup.value * progression.level(.salvage) / 50
        runCoins += reward
        progression.addPoints(reward)
        coinLabel.text = "\(runCoins)"
    }
}

private extension GameScene {
    func styleHUD() {
        let insets = currentSafeAreaInsets()
        let left = -size.width / 2 + insets.left + 16
        let right = size.width / 2 - insets.right - 16
        let top = size.height / 2 - insets.top - 32
        scorePanel.position = CGPoint(x: left + 82, y: top)
        scorePanel.path = CGPath(roundedRect: CGRect(x: -82, y: -24, width: 164, height: 48), cornerWidth: 8, cornerHeight: 8, transform: nil)
        tierPanel.position = CGPoint(x: (left + right) / 2, y: top)
        healthPanel.position = CGPoint(x: right - 60, y: top)
        for panel in [scorePanel!, tierPanel!, healthPanel!] {
            panel.fillColor = SKColor(red: 0.015, green: 0.025, blue: 0.045, alpha: 0.93)
            panel.strokeColor = SKColor(red: 0.18, green: 0.28, blue: 0.35, alpha: 0.7)
            panel.lineWidth = 0.8
            panel.glowWidth = 0
        }
        scorePanel.children.filter { $0 !== scoreLabel }.forEach { $0.removeFromParent() }
        let icon = SKShapeNode(rectOf: CGSize(width: 7, height: 7), cornerRadius: 1)
        icon.zRotation = .pi / 4
        icon.fillColor = NeonColors.green
        icon.strokeColor = .clear
        icon.position = CGPoint(x: -64, y: -11)
        scorePanel.addChild(icon)
        coinLabel.name = "runFlux"
        coinLabel.fontSize = 11
        coinLabel.fontColor = NeonColors.green
        coinLabel.horizontalAlignmentMode = .left
        coinLabel.verticalAlignmentMode = .center
        coinLabel.position = CGPoint(x: -52, y: -11)
        coinLabel.text = "\(runCoins)"
        scorePanel.addChild(coinLabel)
        scoreLabel.fontSize = 14
        scoreLabel.fontColor = SKColor(white: 0.8, alpha: 1)
        scoreLabel.position = CGPoint(x: -67, y: 8)
        tierLabel.fontSize = 11
        tierLabel.fontColor = SKColor(white: 0.88, alpha: 1)
        healthLabel.fontSize = 11
        healthLabel.fontColor = .white
    }
}

extension GameScene {
    func installArena(_ layout: LivingArena) {
        barrierNode.removeAllChildren()
        wallRects.removeAll()
        for rect in layout.walls { addArenaWall(rect, style: layout.phase % 2 + 1) }
        // Treat adjacent tiles as a continuous mass rather than glowing checkerboard blocks.
        for wall in barrierNode.children.compactMap({ $0 as? Barrier }) {
            wall.glowWidth = 0
            wall.lineWidth = 1
            wall.fillColor = SKColor(red: 0.035, green: 0.065, blue: 0.10, alpha: 1)
            wall.strokeColor = SKColor(red: 0.09, green: 0.20, blue: 0.28, alpha: 1)
            let x = Int((wall.barrierRect.midX - layout.bounds.minX) / LivingArena.tile)
            let y = Int((wall.barrierRect.midY - layout.bounds.minY) / LivingArena.tile)
            if !layout.insideOutline(x: x, y: y) {
                wall.fillColor = backgroundColorDark
                wall.strokeColor = backgroundColorDark
            }
        }
        let edgePath = CGMutablePath()
        for y in 0..<LivingArena.rows {
            for x in 0..<LivingArena.columns where !layout.isFloor(x: x, y: y) {
                let r = layout.rect(x: x, y: y)
                if layout.isFloor(x: x - 1, y: y) { edgePath.move(to: CGPoint(x: r.minX, y: r.minY)); edgePath.addLine(to: CGPoint(x: r.minX, y: r.maxY)) }
                if layout.isFloor(x: x + 1, y: y) { edgePath.move(to: CGPoint(x: r.maxX, y: r.minY)); edgePath.addLine(to: CGPoint(x: r.maxX, y: r.maxY)) }
                if layout.isFloor(x: x, y: y - 1) { edgePath.move(to: CGPoint(x: r.minX, y: r.minY)); edgePath.addLine(to: CGPoint(x: r.maxX, y: r.minY)) }
                if layout.isFloor(x: x, y: y + 1) { edgePath.move(to: CGPoint(x: r.minX, y: r.maxY)); edgePath.addLine(to: CGPoint(x: r.maxX, y: r.maxY)) }
            }
        }
        let edges = SKShapeNode(path: edgePath)
        edges.strokeColor = layout.phase % 2 == 0 ? .cyan : NeonColors.purple
        edges.lineWidth = 2
        edges.glowWidth = 2
        edges.zPosition = 3
        barrierNode.addChild(edges)
    }

    func updateLivingArena(deltaTime: TimeInterval) {
        if let remaining = tierTransitionRemaining {
            let next = max(0, remaining - deltaTime)
            tierTransitionRemaining = next
            arenaStatus.fontColor = .systemRed
            arenaStatus.text = "TIER CLEAR  /  MORPH \(Int(ceil(next)))s"
            if next == 0 {
                commitArenaShift()
                tierTransitionRemaining = nil
                advanceTierAfterClear()
            }
        } else {
            arenaStatus.fontColor = SKColor(white: 0.55, alpha: 1)
            arenaStatus.text = "\(activeArena.name)  /  CLEAR ALL HOSTILES"
        }
    }

    func beginArenaShift() {
        beginArenaShift(forTier: currentTier.number + 1)
    }

    private func beginArenaShift(forTier tier: Int) {
        let shape = ArenaShape.forTier(tier)
        if arenaDeck.isEmpty || deckShape != shape {
            arenaDeck = LivingArena.phases(for: shape).shuffled()
            if arenaDeck.first == activeArena.phase { arenaDeck.append(arenaDeck.removeFirst()) }
            deckShape = shape
        }
        let next = LivingArena(phase: arenaDeck.removeFirst(), center: activeArena.center, shape: shape, variant: Int.random(in: 0..<4))
        incomingArena = next
        // Release outgoing walls immediately so the warning period always opens escape routes.
        let retained = activeArena.walls.filter { next.walls.contains($0) }
        barrierNode.removeAllChildren()
        wallRects.removeAll()
        for rect in retained { addArenaWall(rect, style: 1) }
        buildNavigation()
        let newWalls = next.walls.filter { !activeArena.walls.contains($0) }
        for rect in newWalls {
            let tile = SKShapeNode(rect: rect.insetBy(dx: 2, dy: 2), cornerRadius: 3)
            tile.name = "shiftWarning"
            tile.fillColor = SKColor.red.withAlphaComponent(0.22)
            tile.strokeColor = SKColor.red.withAlphaComponent(0.8)
            tile.lineWidth = 1
            tile.zPosition = 1
            worldNode.addChild(tile)
            tile.run(.repeatForever(.sequence([.fadeAlpha(to: 0.2, duration: 0.22), .fadeAlpha(to: 1, duration: 0.22)])))
        }
    }

    func commitArenaShift() {
        guard let next = incomingArena else { return }
        worldNode.children.filter { $0.name == "shiftWarning" }.forEach { $0.removeFromParent() }
        let caught = !next.containsShip(at: player.position)
        if caught {
            player.position = next.nearestFloor(to: player.position)
            player.health -= min(30, max(12, player.maxHealth * 0.10)) * progression.damageMultiplier
            lastDamageTime = gameTime
            createPlayerDamageEffect()
            updateHUD()
        }
        for node in worldNode.children where node is Enemy || node is FluxPickup {
            if !next.containsShip(at: node.position) {
                if node is Enemy {
                    let safe = next.floorCenters.filter { hypot($0.x - player.position.x, $0.y - player.position.y) > 140 }
                    node.position = safe.min { hypot($0.x - node.position.x, $0.y - node.position.y) < hypot($1.x - node.position.x, $1.y - node.position.y) } ?? next.nearestFloor(to: node.position)
                } else { node.position = next.nearestFloor(to: node.position) }
            }
        }
        for node in worldNode.children where node is Bullet || node.physicsBody?.categoryBitMask == 16 {
            if !next.containsShip(at: node.position) { node.removeFromParent() }
        }
        activeArena = next
        incomingArena = nil
        installArena(next)
        buildNavigation()
        if player.health <= 0 { endGame() }
    }
}

extension GameScene {
    func createAbilityButtons() {
        for (upgrade, x, name) in [(ShipUpgrade.dash, CGFloat(-66), "dashAbility"), (.bomb, CGFloat(66), "bombAbility")] where progression.level(upgrade) > 0 {
            let panel = SKShapeNode(rectOf: CGSize(width: 112, height: 42), cornerRadius: 10)
            panel.name = name
            panel.fillColor = NeonColors.panel.withAlphaComponent(0.9)
            panel.strokeColor = upgrade == .dash ? .cyan : .orange
            panel.position = CGPoint(x: x, y: -size.height / 2 + currentSafeAreaInsets().bottom + 32)
            panel.zPosition = hudZ
            let label = makeLabel(text: upgrade == .dash ? "DASH" : "SHOCKWAVE", fontSize: 10, fontName: "AvenirNext-Bold", color: .white)
            panel.addChild(label)
            cameraNode.addChild(panel)
        }
    }
    func updateAbilities(deltaTime: TimeInterval) {
        repairClock += deltaTime
        if repairClock >= 0.5 {
            if gameTime - lastDamageTime > 4, player.health < player.maxHealth {
                player.health = min(player.maxHealth, player.health + progression.repairPerSecond * CGFloat(repairClock))
                updateHUD()
            }
            repairClock = 0
        }
        for (name, ready, title) in [("dashAbility", dashReadyAt, "DASH"), ("bombAbility", bombReadyAt, "SHOCKWAVE")] {
            if let panel = cameraNode.childNode(withName: name), let label = panel.children.first as? SKLabelNode {
                label.text = elapsed >= ready ? title : "\(title) \(Int(ceil(ready - elapsed)))s"
                panel.alpha = elapsed >= ready ? 1 : 0.45
            }
        }
    }
    func activateDash() {
        guard !gameOver, !pausedRun, progression.level(.dash) > 0, elapsed >= dashReadyAt else { return }
        dashReadyAt = elapsed + progression.dashCooldown
        dashUntil = elapsed + 0.35
        let input = moveJoystick.direction
        let direction = hypot(input.dx, input.dy) > 0.1 ? normalize(input) : CGVector(dx: cos(player.zRotation), dy: sin(player.zRotation))
        for _ in 0..<9 {
            let candidate = CGPoint(x: player.position.x + direction.dx * 18, y: player.position.y + direction.dy * 18)
            guard worldBounds.insetBy(dx: 20, dy: 20).contains(candidate), !wallRects.contains(where: { $0.insetBy(dx: -20, dy: -20).contains(candidate) }) else { break }
            let trail = SKShapeNode(circleOfRadius: 10)
            trail.position = player.position
            trail.strokeColor = .cyan
            trail.fillColor = .clear
            trail.zPosition = 10
            worldNode.addChild(trail)
            trail.run(.sequence([.fadeOut(withDuration: 0.25), .removeFromParent()]))
            player.position = candidate
        }
    }
    func activateBomb() {
        guard !gameOver, !pausedRun, progression.level(.bomb) > 0, elapsed >= bombReadyAt else { return }
        bombReadyAt = elapsed + progression.bombCooldown
        let radius: CGFloat = 180 + CGFloat(progression.level(.bomb)) * 5
        let ring = SKShapeNode(circleOfRadius: radius)
        ring.position = player.position
        ring.strokeColor = .orange
        ring.lineWidth = 4
        ring.fillColor = SKColor.orange.withAlphaComponent(0.08)
        ring.zPosition = effectZ
        ring.setScale(0.1)
        worldNode.addChild(ring)
        ring.run(.sequence([.group([.scale(to: 1, duration: 0.3), .fadeOut(withDuration: 0.3)]), .removeFromParent()]))
        for node in worldNode.children where hypot(node.position.x - player.position.x, node.position.y - player.position.y) <= radius {
            if node.physicsBody?.categoryBitMask == 16 { node.removeFromParent() }
            if let enemy = node as? Enemy {
                enemy.health -= CGFloat(80 + progression.level(.bomb) * 20)
                if enemy.health <= 0 { destroyEnemy(enemy) }
            }
        }
    }
}
