import SpriteKit

struct GameTier {
    
    let number: Int
    let name: String
    
    let minimumScore: Int
    
    let enemyHealth: CGFloat
    let enemySpeed: CGFloat
    let spawnInterval: TimeInterval
    
    let killScore: Int
    
    let backgroundBrightness: CGFloat
    
    let hasBarrier: Bool
    let barrierStyle: Int
    
    
    // MARK: - Tiers
    
    static let tiers: [GameTier] = [
        
        // Tier 1
        GameTier(
            number: 1,
            name: "NEON GRID",
            minimumScore: 0,
            enemyHealth: 30,
            enemySpeed: 80,
            spawnInterval: 1.0,
            killScore: 100,
            backgroundBrightness: 0.02,
            hasBarrier: false,
            barrierStyle: 0
        ),
        
        // Tier 2
        GameTier(
            number: 2,
            name: "NEON GRID II",
            minimumScore: 5000,
            enemyHealth: 45,
            enemySpeed: 105,
            spawnInterval: 0.80,
            killScore: 150,
            backgroundBrightness: 0.025,
            hasBarrier: true,
            barrierStyle: 1
        ),
        
        // Tier 3
        GameTier(
            number: 3,
            name: "REACTOR",
            minimumScore: 10000,
            enemyHealth: 65,
            enemySpeed: 130,
            spawnInterval: 0.65,
            killScore: 225,
            backgroundBrightness: 0.03,
            hasBarrier: true,
            barrierStyle: 2
        ),
        
        // Tier 4
        GameTier(
            number: 4,
            name: "CORE",
            minimumScore: 20000,
            enemyHealth: 90,
            enemySpeed: 155,
            spawnInterval: 0.52,
            killScore: 325,
            backgroundBrightness: 0.035,
            hasBarrier: true,
            barrierStyle: 3
        ),
        
        // Tier 5
        GameTier(
            number: 5,
            name: "OVERLOAD",
            minimumScore: 35000,
            enemyHealth: 125,
            enemySpeed: 185,
            spawnInterval: 0.42,
            killScore: 450,
            backgroundBrightness: 0.04,
            hasBarrier: true,
            barrierStyle: 4
        )
    ]
    
    
    // MARK: - Find Tier
    
    static func tier(for score: Int) -> GameTier {
        
        var current = tiers[0]
        
        for tier in tiers {
            
            if score >= tier.minimumScore {
                current = tier
            }
        }
        
        if score >= 50000 {
            let extra = (score - 35000) / 15000
            return GameTier(number: 5 + extra, name: "OVERLOAD \(extra + 1)",
                minimumScore: 35000 + extra * 15000,
                enemyHealth: 125 + CGFloat(extra) * 18,
                enemySpeed: min(260, 185 + CGFloat(extra) * 7),
                spawnInterval: max(0.16, 0.42 * pow(0.92, Double(extra))),
                killScore: 450 + extra * 50, backgroundBrightness: 0.04,
                hasBarrier: true, barrierStyle: 4)
        }
        return current
    }

    /// Tier progression is wave-driven in gameplay. This lookup keeps difficulty
    /// deterministic without tying advancement to score or survival time.
    static func tier(number: Int) -> GameTier {
        let number = max(1, number)
        if number <= tiers.count { return tiers[number - 1] }
        let extra = number - 5
        return GameTier(
            number: number,
            name: "OVERLOAD \(extra + 1)",
            minimumScore: 35000 + extra * 15000,
            enemyHealth: 125 + CGFloat(extra) * 18,
            enemySpeed: min(260, 185 + CGFloat(extra) * 7),
            spawnInterval: max(0.16, 0.42 * pow(0.92, Double(extra))),
            killScore: 450 + extra * 50,
            backgroundBrightness: 0.04,
            hasBarrier: true,
            barrierStyle: 4
        )
    }
}

/// A finite combat contract for a tier. The next arena cannot begin until the
/// complete budget has spawned and every surviving enemy has been destroyed.
struct TierWavePlan: Equatable {
    let regularEnemies: Int
    let bossCount: Int

    var totalEnemies: Int { regularEnemies + bossCount }

    static func forTier(_ tier: Int) -> TierWavePlan {
        let tier = max(1, tier)
        if tier.isMultiple(of: 10) {
            return TierWavePlan(regularEnemies: 0, bossCount: 1)
        }
        // Increase the finite budget after tier 10 without changing the live
        // spawn cap. Later rounds last longer instead of flooding the arena.
        let lateTierExtension = max(0, tier - 10) * 3
        let regular = min(180, 8 + tier * 4 + (tier / 4) * 3 + lateTierExtension)
        let bosses: Int
        if tier >= 3 && (tier.isMultiple(of: 3) || tier.isMultiple(of: 5)) {
            bosses = 1
        } else {
            bosses = 0
        }
        return TierWavePlan(regularEnemies: regular, bossCount: bosses)
    }

    static func isFinalBossTier(_ tier: Int) -> Bool {
        tier > 0 && tier.isMultiple(of: 10)
    }
}


/// Compact, separated cover pieces avoid sealing the arena's connecting routes.
enum ArenaEvolution {
    static func obstacles(tier: Int, center: CGPoint) -> [CGRect] {
        guard tier >= 2 else { return [] }
        let count = min(8, tier + 2)
        let phase = CGFloat(tier % 4) * .pi / 4
        return (0..<count).map { index in
            let angle = CGFloat(index) * 2 * .pi / CGFloat(count) + phase
            let width: CGFloat = tier % 2 == 0 ? 70 : 38
            let height: CGFloat = tier % 2 == 0 ? 38 : 70
            return CGRect(x: center.x + cos(angle) * 290 - width / 2,
                          y: center.y + sin(angle) * 220 - height / 2,
                          width: width, height: height)
        }
    }
}

/// Tile-based layouts share a central refuge and have connected, ship-sized routes.
enum ArenaShape: String, CaseIterable {
    case rectangle = "RECTANGLE", octagon = "OCTAGON", square = "SQUARE", triangle = "TRIANGLE"
    static func forTier(_ tier: Int) -> ArenaShape {
        guard tier >= 5 else { return .rectangle }
        return [ArenaShape.octagon, .square, .triangle][((tier - 5) / 3) % 3]
    }
}

struct LivingArena {
    static let columns = 15
    static let rows = 11
    static let tile: CGFloat = 96
    let phase: Int
    let center: CGPoint
    let shape: ArenaShape
    let variant: Int
    init(phase: Int, center: CGPoint, shape: ArenaShape = .rectangle, variant: Int = 0) {
        self.phase = phase; self.center = center; self.shape = shape; self.variant = variant
    }
    var bounds: CGRect {
        CGRect(x: center.x - 720, y: center.y - 528, width: 1440, height: 1056)
    }
    var name: String {
        let names = ["OPEN CIRCUIT", "CROSSFIRE", "CHANNELS", "SWITCHBACK", "OUTER REACTOR", "TWIN CORES", "QUADRANTS", "SLALOM", "SPLIT GATES", "SATELLITES", "CHEVRON", "DRIFT BLOCKS"]
        return shape == .rectangle ? names[phase % 12] : shape.rawValue + " / " + names[phase % 12]
    }
    static func phases(for shape: ArenaShape) -> [Int] {
        // Broad cover patterns keep the smaller outlines comfortable to navigate.
        if shape == .rectangle { return Array(0..<12) }
        // Chevron cuts can isolate tiny pockets at the triangle's sloped edges.
        return shape == .triangle ? [0, 5, 6, 7, 8, 9, 11] : [0, 5, 6, 7, 8, 9, 10, 11]
    }
    func insideOutline(x: Int, y: Int) -> Bool {
        guard (0..<Self.columns).contains(x), (0..<Self.rows).contains(y) else { return false }
        let dx = abs(x - 7), dy = abs(y - 5)
        switch shape {
        case .rectangle: return true
        case .octagon: return dx + dy <= 9
        case .square: return dx <= 5
        case .triangle: return Double(dx) <= 7 - Double(y) * 0.6
        }
    }
    func isFloor(x: Int, y: Int) -> Bool {
        guard insideOutline(x: x, y: y) else { return false }
        if (6...8).contains(x) && (4...6).contains(y) { return true }
        if shape != .rectangle && (6...8).contains(x) { return true }
        let x = variant % 2 == 1 ? 14 - x : x
        let y = variant / 2 % 2 == 1 ? 10 - y : y
        switch phase % 12 {
        case 0: return !([3, 7, 11].contains(x) && [2, 8].contains(y))
        case 1: return (6...8).contains(x) || (4...6).contains(y)
        case 2: return [1, 2, 5, 6, 9, 10].contains(y) || [1, 2, 12, 13].contains(x)
        case 3:
            return [1, 2, 5, 6, 9, 10].contains(y) ||
                ((12...13).contains(x) && (2...6).contains(y)) ||
                ((1...2).contains(x) && (5...10).contains(y))
        case 4: return x < 2 || x > 12 || y < 2 || y > 8 || (6...8).contains(x) || (4...6).contains(y)
        case 5: return !([4, 10].contains(x) && [2, 3, 7, 8].contains(y))
        case 6: return !([3, 4, 10, 11].contains(x) && [2, 8].contains(y))
        case 7: return !((x == 4 && (2...4).contains(y)) || (x == 10 && (6...8).contains(y)))
        case 8: return !([3, 7].contains(y) && [2, 3, 4, 10, 11, 12].contains(x))
        case 9: return !(([3, 11].contains(x) && (4...6).contains(y)) || ([1, 9].contains(y) && (6...8).contains(x)))
        case 10: return !(abs(x - 7) == abs(y - 5) + 2 && [2, 3, 7, 8].contains(y))
        default: return !(([3, 4].contains(x) && [2, 7].contains(y)) || ([10, 11].contains(x) && [4, 8].contains(y)))
        }
    }
    func rect(x: Int, y: Int) -> CGRect {
        CGRect(x: bounds.minX + CGFloat(x) * Self.tile, y: bounds.minY + CGFloat(y) * Self.tile, width: Self.tile, height: Self.tile)
    }
    var walls: [CGRect] {
        (0..<Self.rows).flatMap { y in (0..<Self.columns).compactMap { x in isFloor(x: x, y: y) ? nil : rect(x: x, y: y) } }
    }
    var floorCenters: [CGPoint] {
        (0..<Self.rows).flatMap { y in (0..<Self.columns).compactMap { x in
            guard isFloor(x: x, y: y) else { return nil }
            let r = rect(x: x, y: y); return CGPoint(x: r.midX, y: r.midY)
        } }
    }
    func containsShip(at point: CGPoint) -> Bool {
        bounds.insetBy(dx: 22, dy: 22).contains(point) && !walls.contains { $0.insetBy(dx: -22, dy: -22).contains(point) }
    }
    func nearestFloor(to point: CGPoint) -> CGPoint {
        floorCenters.min { hypot($0.x - point.x, $0.y - point.y) < hypot($1.x - point.x, $1.y - point.y) } ?? center
    }
}

struct ArenaClock {
    enum Event { case warning, commit }
    private(set) var remaining: TimeInterval = 16
    private(set) var warning = false
    mutating func advance(_ dt: TimeInterval, tier: Int) -> Event? {
        remaining -= max(0, dt)
        guard remaining <= 0 else { return nil }
        warning.toggle()
        remaining = warning ? 3 : max(7, 13 - Double(tier) * 0.7)
        return warning ? .warning : .commit
    }
}

/// Front-loads action, then rejoins normal pacing without scaling enemy stats.
struct OpeningPacing {
    let strength: Double
    init(progress: PlayerProgress) {
        let combat = Double(progress.damageLevel + progress.fireRateLevel)
            + Double(progress.healthLevel) * 0.25
            + Double(progress.level(.bomb)) * 0.5
            + (progress.doubleShotUnlocked ? 10 : 0)
        strength = min(1, max(0, combat / 50))
    }
    func multiplier(at elapsed: TimeInterval) -> Double {
        let opening = 1.05 - strength * 0.55
        let start = min(1, max(0, elapsed / 6))
        let blend = min(1, max(0, (elapsed - 75) / 105))
        let smooth = blend * blend * (3 - 2 * blend)
        return (1.1 + (opening - 1.1) * start) * (1 - smooth) + 1.3 * smooth
    }
    func enemyLimit(at elapsed: TimeInterval) -> Int {
        let early = 8 + Int(strength * 18)
        let blend = min(1, max(0, (elapsed - 75) / 105))
        return early + Int(Double(130 - early) * blend)
    }
}

/// Lightweight flocking used by enemies so a chase remains a moving swarm
/// instead of collapsing into one overlapping point.
enum EnemyCrowdSteering {
    static func separationVector(
        for index: Int,
        positions: [CGPoint],
        preferredSpacing: CGFloat = 48
    ) -> CGVector {
        guard positions.indices.contains(index) else { return .zero }
        var x: CGFloat = 0
        var y: CGFloat = 0
        var neighborCount: CGFloat = 0
        let origin = positions[index]

        for otherIndex in positions.indices where otherIndex != index {
            var dx = origin.x - positions[otherIndex].x
            var dy = origin.y - positions[otherIndex].y
            var distance = hypot(dx, dy)
            guard distance < preferredSpacing else { continue }

            // Give perfectly stacked enemies stable opposing escape directions.
            if distance < 0.01 {
                let angle = CGFloat((index * 97 + otherIndex * 53) % 360) * .pi / 180
                dx = cos(angle)
                dy = sin(angle)
                distance = 1
            }

            let pressure = (preferredSpacing - distance) / preferredSpacing
            x += dx / distance * pressure
            y += dy / distance * pressure
            neighborCount += 1
        }

        let magnitude = hypot(x, y)
        guard magnitude > 0.001 else { return .zero }
        // Preserve pressure rather than normalizing every contact to full force.
        // This prevents tiny changes at the spacing boundary from flipping direction.
        let scale = min(1, magnitude / max(1, neighborCount)) / magnitude
        return CGVector(dx: x * scale, dy: y * scale)
    }
}
