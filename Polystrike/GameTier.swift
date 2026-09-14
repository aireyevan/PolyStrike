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

/// Hand-authored footprints on a common lattice keep transitions and collision exact.
/// The shape argument remains source-compatible; each blueprint owns its silhouette.
struct LivingArena {
    static let columns = 21
    static let rows = 15
    static let tile: CGFloat = 96
    static let blueprintCount = 24
    static let combatPhases = Array(0..<20)
    static let bossPhases = Array(20..<24)
    let phase: Int
    let center: CGPoint
    let shape: ArenaShape
    let variant: Int
    private let floorCells: Set<Int>
    let walls: [CGRect]
    let floorCenters: [CGPoint]

    init(phase: Int, center: CGPoint, shape: ArenaShape = .rectangle, variant: Int = 0) {
        let phase = ((phase % Self.blueprintCount) + Self.blueprintCount) % Self.blueprintCount
        self.phase = phase; self.center = center; self.shape = shape; self.variant = variant
        let origin = CGPoint(x:center.x-CGFloat(Self.columns)*Self.tile/2,y:center.y-CGFloat(Self.rows)*Self.tile/2)
        var cells = Set<Int>(), walls: [CGRect] = [], centers: [CGPoint] = []
        for row in 0..<Self.rows {
            for column in 0..<Self.columns {
                let x = variant % 2 == 1 ? 10-column : column-10
                let y = variant / 2 % 2 == 1 ? 7-row : row-7
                let rect = CGRect(x:origin.x+CGFloat(column)*Self.tile,y:origin.y+CGFloat(row)*Self.tile,width:Self.tile,height:Self.tile)
                if Self.blueprint(phase,x:x,y:y) {
                    cells.insert(row*Self.columns+column)
                    centers.append(CGPoint(x:rect.midX,y:rect.midY))
                } else { walls.append(rect) }
            }
        }
        floorCells = cells; self.walls = walls; floorCenters = centers
    }

    var bounds: CGRect {
        CGRect(x:center.x-CGFloat(Self.columns)*Self.tile/2,y:center.y-CGFloat(Self.rows)*Self.tile/2,
               width:CGFloat(Self.columns)*Self.tile,height:CGFloat(Self.rows)*Self.tile)
    }
    var name: String {
        ["LAUNCH CITADEL","VERTEBRA","SPLIT HALO","CRUCIBLE","SLIPSTREAM","TRIDENT DOCK",
         "HOURGLASS","CROWN ARRAY","TWIN TURBINES","PINWHEEL","CATHEDRAL","DELTA VAULT",
         "SHATTERED DISC","CARGO SPINE","BUTTERFLY","SIEGE ARCH","SWITCHYARD","DOUBLE HELIX",
         "HORIZON RELAY","FRACTURE GARDEN","DREADNOUGHT","STAR FORTRESS","ECLIPSE ENGINE","FINAL THRONE"][phase]
    }
    static func phases(for shape: ArenaShape) -> [Int] { combatPhases }
    func insideOutline(x: Int, y: Int) -> Bool { isFloor(x:x,y:y) }
    func isFloor(x: Int, y: Int) -> Bool {
        guard (0..<Self.columns).contains(x), (0..<Self.rows).contains(y) else { return false }
        return floorCells.contains(y*Self.columns+x)
    }
    func rect(x: Int, y: Int) -> CGRect {
        CGRect(x:bounds.minX+CGFloat(x)*Self.tile,y:bounds.minY+CGFloat(y)*Self.tile,width:Self.tile,height:Self.tile)
    }
    func containsShip(at point: CGPoint) -> Bool {
        bounds.insetBy(dx:22,dy:22).contains(point) && !walls.contains { $0.insetBy(dx:-22,dy:-22).contains(point) }
    }
    func nearestFloor(to point: CGPoint) -> CGPoint {
        floorCenters.min { hypot($0.x-point.x,$0.y-point.y) < hypot($1.x-point.x,$1.y-point.y) } ?? center
    }

    private static func blueprint(_ phase: Int, x: Int, y: Int) -> Bool {
        let dx = abs(x), dy = abs(y)
        // A shared landing pad is the safe anchor for spawning, defense and shape shifts.
        if dx <= 1 && dy <= 1 { return true }
        func box(_ cx: Int,_ cy: Int,_ w: Int,_ h: Int) -> Bool { abs(x-cx)<=w && abs(y-cy)<=h }
        func diamond(_ cx: Int,_ cy: Int,_ r: Int) -> Bool { abs(x-cx)+abs(y-cy)<=r }
        func disc(_ cx: Int,_ cy: Int,_ r: Int) -> Bool { (x-cx)*(x-cx)+(y-cy)*(y-cy)<=r*r }
        func lane(_ ax: Double,_ ay: Double,_ bx: Double,_ by: Double,_ radius: Double) -> Bool {
            let vx=bx-ax,vy=by-ay,px=Double(x)-ax,py=Double(y)-ay
            let t=max(0,min(1,(px*vx+py*vy)/max(1,vx*vx+vy*vy)))
            return hypot(px-t*vx,py-t*vy)<=radius
        }
        switch phase {
        case 0: // A spacious first encounter, with four perimeter cover islands.
            return dx<=9 && dy<=6 && dx+dy<=13 && !(dx>=5 && dx<=6 && dy==3)
        case 1: // Three faceted chambers, connected by a broad central artery.
            return diamond(-6,0,6) || diamond(6,0,6) || diamond(0,0,5) || box(0,0,9,1)
        case 2: // Four void cuts create a hub, bypasses and an outer loop.
            return dx+dy<=14 && !(dx>=3 && dx<=5 && dy>=2 && dy<=3)
        case 3: // Offset corner courts enter the central crucible from four directions.
            return box(0,0,3,5) || box(0,0,8,2) || box(-6,4,3,2) || box(6,-4,3,2)
        case 4: // A sweeping S with large turning bays and two shortcuts.
            return lane(-7,-4,0,0,2.5) || lane(0,0,7,4,2.5) || box(-6,-4,3,2) || box(6,4,3,2) || box(0,0,3,3)
        case 5: // Three launch fingers join a generous lower assembly court.
            return box(0,-3,9,3) || box(-7,2,2,5) || box(0,2,2,5) || box(7,2,2,5)
        case 6:
            return dx<=min(9,3+dy) && dy<=6
        case 7: // Crowned outline with a tapered southern approach.
            return (y<=2 && y>=(-6) && dx<=min(9,9+y+3)) || box(-7,4,2,3) || box(0,4,2,3) || box(7,4,2,3)
        case 8: // Two engines with independent circulation and a connecting bridge.
            return (disc(-5,0,6) || disc(5,0,6) || box(0,0,5,2)) && !box(-5,0,1,1) && !box(5,0,1,1)
        case 9: // Four broad bent arms wind around the landing hub.
            return box(0,0,3,3) || box(-5,2,4,1) || box(-7,-1,2,3) || box(5,-2,4,1) || box(7,1,2,3) || box(2,5,1,2) || box(-2,-5,1,2)
        case 10: // Tall nave, flanking transepts and a double entrance.
            return (dx<=4 && dy<=7 && dx+dy<=10) || box(0,1,9,2) || box(-6,-4,2,2) || box(6,-4,2,2) || box(0,-4,6,1)
        case 11: // Delta platform and two offset cover islands.
            return y>=(-6) && Double(dx)<=9-Double(y+6)*0.46 && !(dx==4 && y>=(-3) && y<=(-2))
        case 12:
            return dx*dx+dy*dy<=102 && !(x>=5 && y>=3) && !(x<=(-6) && y<=(-2)) && !box(-3,3,1,1) && !box(4,-3,1,1)
        case 13: // Three loading bays on either side of a central spine.
            return box(0,0,2,7) || box(0,-5,9,1) || box(0,0,10,1) || box(0,5,9,1) || box(-8,0,2,5)
        case 14:
            return diamond(-5,-3,5) || diamond(5,-3,5) || diamond(-5,3,5) || diamond(5,3,5) || box(0,0,3,3)
        case 15: // Horseshoe ring with two protected passages through the middle.
            return (dx<=9 && dy<=6 && dx+dy<=14) && !(dx>=3 && dx<=5 && y>=(-3) && y<=3)
        case 16:
            return lane(-8,-4,8,4,2) || lane(-8,4,8,-4,2) || box(-8,0,1,4) || box(8,0,1,4)
        case 17: // Paired curved lanes rejoin at three crossover courts.
            return abs(Double(x)-4*sin(Double(y)*0.48))<=2.1 || abs(Double(x)+4*sin(Double(y)*0.48))<=2.1 || box(0,0,6,1) || box(0,-5,5,1) || box(0,5,5,1)
        case 18:
            return diamond(-6,-3,5) || diamond(6,-3,5) || diamond(0,4,5) || lane(-6,-3,6,-3,1.7) || lane(-6,-3,0,4,1.7) || lane(6,-3,0,4,1.7)
        case 19: // An asymmetrical garden of connected terraces.
            return box(-6,2,3,4) || diamond(5,-2,6) || box(0,0,5,2) || box(4,5,4,1) || box(7,3,1,3)
        case 20: // Boss decks retain a large unobstructed central combat space.
            return dx<=10 && dy<=6 && dx+dy<=14 && !(dx==7 && dy>=3 && dy<=4)
        case 21:
            return (dx<=6 && dy<=6) || (dx<=10 && dy<=2) || (dx<=2 && dy<=7)
        case 22:
            return dx*dx+dy*dy<=108 && !(dx>=4 && dx<=5 && dy>=3 && dy<=4)
        default:
            return (dy<=6 && dx<=9 && dx+dy<=13) && !(dx>=6 && y>=(-3) && y<=(-2))
        }
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
extension LivingArena {
    var accentColor: SKColor {
        let colors: [SKColor] = [.cyan, NeonColors.orange, NeonColors.purple, NeonColors.green,
            NeonColors.blue, NeonColors.yellow, NeonColors.pink, NeonColors.orange,
            NeonColors.green, .cyan, NeonColors.purple, NeonColors.yellow,
            NeonColors.pink, NeonColors.blue, .cyan, NeonColors.orange,
            NeonColors.green, NeonColors.purple, NeonColors.blue, NeonColors.pink,
            NeonColors.orange, .cyan, NeonColors.purple, NeonColors.yellow]
        return colors[phase]
    }
    var floorPath: CGPath {
        let path = CGMutablePath()
        for y in 0..<Self.rows {
            // Merge horizontal spans so there are no seams between floor tiles.
            var x = 0
            while x < Self.columns {
                guard isFloor(x:x,y:y) else { x += 1; continue }
                let start = x
                while x < Self.columns && isFloor(x:x,y:y) { x += 1 }
                let r = rect(x:start,y:y)
                path.addRect(CGRect(x:r.minX,y:r.minY,width:CGFloat(x-start)*Self.tile,height:Self.tile))
            }
        }
        return path
    }
    var edgePath: CGPath {
        let path = CGMutablePath()
        for y in 0..<Self.rows {
            for x in 0..<Self.columns where isFloor(x:x,y:y) {
                let r = rect(x:x,y:y)
                for (nx,ny,a,b) in [
                    (x-1,y,CGPoint(x:r.minX,y:r.minY),CGPoint(x:r.minX,y:r.maxY)),
                    (x+1,y,CGPoint(x:r.maxX,y:r.minY),CGPoint(x:r.maxX,y:r.maxY)),
                    (x,y-1,CGPoint(x:r.minX,y:r.minY),CGPoint(x:r.maxX,y:r.minY)),
                    (x,y+1,CGPoint(x:r.minX,y:r.maxY),CGPoint(x:r.maxX,y:r.maxY))
                ] where !isFloor(x:nx,y:ny) { path.move(to:a); path.addLine(to:b) }
            }
        }
        return path
    }

    /// Batched geometry and one clipped motif layer keep visual cost bounded.
    /// Every decorative layer stays below enemies, pickups and projectiles.
    func makeBackdrop() -> SKNode {
        let root = SKNode(); root.name = "arenaBackdrop"; root.zPosition = -30
        let void = SKShapeNode(rect:bounds.insetBy(dx:-600,dy:-600))
        void.fillColor = SKColor(red:0.006,green:0.009,blue:0.018,alpha:1); void.strokeColor = .clear
        root.addChild(void)
        let stars = CGMutablePath()
        for index in 0..<90 {
            let x=bounds.minX+CGFloat((index*389+phase*67)%2416)-200
            let y=bounds.minY+CGFloat((index*233+phase*113)%1840)-200
            stars.addRect(CGRect(x:x,y:y,width:index%5 == 0 ? 3 : 1,height:index%5 == 0 ? 3 : 1))
        }
        let dust=SKShapeNode(path:stars);dust.fillColor=accentColor.withAlphaComponent(0.23);dust.strokeColor = .clear;dust.zPosition=1;root.addChild(dust)
        let machinery = SKNode(); machinery.position = center; machinery.zPosition = 1; root.addChild(machinery)
        let rings = CGMutablePath()
        for radius: CGFloat in [570,760,1040] {
            for sector in 0..<8 {
                let start = CGFloat(sector) * .pi / 4 + CGFloat(phase) * 0.06
                rings.addArc(center:.zero,radius:radius,startAngle:start,endAngle:start + .pi/6,clockwise:false)
            }
        }
        let orbit = SKShapeNode(path:rings); orbit.strokeColor = accentColor.withAlphaComponent(0.10)
        orbit.lineWidth = 3; machinery.addChild(orbit)
        machinery.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 160 + Double(phase)*4)))
        let silhouette = floorPath
        let underlay=SKShapeNode(path:silhouette)
        underlay.fillColor=SKColor(red:0.065,green:0.095,blue:0.13,alpha:1)
        underlay.strokeColor = .clear;underlay.position.y = -14;underlay.zPosition=2;root.addChild(underlay)
        let floor=SKShapeNode(path:silhouette)
        let tints: [SKColor] = [SKColor(red:0.022,green:0.048,blue:0.066,alpha:1),
            SKColor(red:0.052,green:0.037,blue:0.025,alpha:1),SKColor(red:0.035,green:0.025,blue:0.063,alpha:1),
            SKColor(red:0.019,green:0.049,blue:0.042,alpha:1)]
        floor.fillColor=tints[phase%4];floor.strokeColor = .clear;floor.zPosition=3;root.addChild(floor)
        let crop=SKCropNode();let mask=SKShapeNode(path:silhouette);mask.fillColor = .white;mask.strokeColor = .clear
        crop.maskNode=mask;crop.zPosition=4;root.addChild(crop)
        let motif=CGMutablePath()
        let motifStyle = [0,3,1,3,4,5,5,0,1,3,5,2,2,0,4,5,0,4,1,2,0,3,1,5][phase]
        switch motifStyle {
        case 0: // Etched circuit trunks.
            for row in -7...7 {
                let y=center.y+CGFloat(row)*103
                motif.move(to:CGPoint(x:bounds.minX,y:y))
                for column in 0...10 {
                    let x=bounds.minX+CGFloat(column)*210
                    motif.addLine(to:CGPoint(x:x,y:y));motif.addLine(to:CGPoint(x:x+36,y:y+28));motif.addLine(to:CGPoint(x:x+145,y:y+28))
                }
            }
        case 1: // Concentric turbine vanes.
            for radius in stride(from:CGFloat(120),through:1500,by:110) {
                motif.addEllipse(in:CGRect(x:center.x-radius,y:center.y-radius,width:radius*2,height:radius*2))
            }
            for i in 0..<16 {
                let a=CGFloat(i) * .pi/8+0.12
                motif.move(to:center);motif.addLine(to:CGPoint(x:center.x+cos(a)*1700,y:center.y+sin(a)*1700))
            }
        case 2: // Offset hexagonal armor panels.
            for row in -6...6 {
                for column in -7...7 {
                    let cx=center.x+CGFloat(column)*170+CGFloat(abs(row)%2)*85,cy=center.y+CGFloat(row)*148
                    for i in 0..<6 {
                        let a=CGFloat(i) * .pi/3
                        let p=CGPoint(x:cx+cos(a)*90,y:cy+sin(a)*90)
                        if i==0 { motif.move(to:p) } else { motif.addLine(to:p) }
                    }
                    motif.closeSubpath()
                }
            }
        case 3: // Interlocking directional ribs.
            for row in -10...10 {
                let y=center.y+CGFloat(row)*90
                for column in -6...6 {
                    let x=center.x+CGFloat(column)*180
                    motif.move(to:CGPoint(x:x-80,y:y+40));motif.addLine(to:CGPoint(x:x,y:y));motif.addLine(to:CGPoint(x:x+80,y:y+40))
                }
            }
        case 4: // Long flowing field contours.
            for row in -10...10 {
                for step in 0...64 {
                    let x=bounds.minX+CGFloat(step)*bounds.width/64
                    let y=center.y+CGFloat(row)*95+sin((x-center.x)/190+CGFloat(row)*0.3)*55
                    if step==0 {motif.move(to:CGPoint(x:x,y:y))}else{motif.addLine(to:CGPoint(x:x,y:y))}
                }
            }
        default: // Nested diamonds and diagonal bracing.
            for radius in stride(from:CGFloat(100),through:1800,by:120) {
                motif.move(to:CGPoint(x:center.x-radius,y:center.y))
                motif.addLine(to:CGPoint(x:center.x,y:center.y+radius*0.65))
                motif.addLine(to:CGPoint(x:center.x+radius,y:center.y))
                motif.addLine(to:CGPoint(x:center.x,y:center.y-radius*0.65));motif.closeSubpath()
            }
        }
        let pattern=SKShapeNode(path:motif);pattern.strokeColor=accentColor.withAlphaComponent(0.17)
        pattern.lineWidth=1.3;pattern.fillColor = .clear;crop.addChild(pattern)
        // A faceted, recessed landmark makes the arena center recognizable while moving.
        let sigil=CGMutablePath()
        let sides=phase>=20 ? 8 : 3+phase%5
        for radius:CGFloat in [92,108,166] {
            for index in 0..<sides {
                let angle=CGFloat(index)*2 * .pi/CGFloat(sides) + .pi/2
                let p=CGPoint(x:center.x+cos(angle)*radius,y:center.y+sin(angle)*radius)
                if index==0 {sigil.move(to:p)}else{sigil.addLine(to:p)}
            }
            sigil.closeSubpath()
        }
        let crest=SKShapeNode(path:sigil);crest.strokeColor=accentColor.withAlphaComponent(0.19)
        crest.lineWidth=2;crest.fillColor = .clear;crest.zPosition=1;crop.addChild(crest)
        let lip=SKShapeNode(path:edgePath);lip.strokeColor=SKColor(red:0.15,green:0.22,blue:0.28,alpha:1)
        lip.lineWidth=10;lip.glowWidth=0;lip.zPosition=5;root.addChild(lip)
        let rim=SKShapeNode(path:edgePath);rim.strokeColor=accentColor.withAlphaComponent(0.82)
        rim.lineWidth=2;rim.glowWidth=1.5;rim.zPosition=6;root.addChild(rim)
        return root
    }
}

/// Broad-phase lookups retain exact collision/separation math but skip distant objects.
struct CombatCell: Hashable {
    let x: Int
    let y: Int
}
struct WallSpatialIndex {
    private let size: CGFloat = 192
    private var buckets: [CombatCell: [Int]] = [:]
    private var walls: [CGRect] = []
    init(walls: [CGRect] = []) {
        self.walls = walls
        for (index,r) in walls.enumerated() {
            for y in Int(floor(r.minY/size))...Int(floor(r.maxY/size)) {
                for x in Int(floor(r.minX/size))...Int(floor(r.maxX/size)) {
                    buckets[CombatCell(x:x,y:y),default:[]].append(index)
                }
            }
        }
    }
    func candidates(in rect: CGRect) -> [CGRect] {
        var indices = Set<Int>()
        for y in Int(floor(rect.minY/size))...Int(floor(rect.maxY/size)) {
            for x in Int(floor(rect.minX/size))...Int(floor(rect.maxX/size)) {
                indices.formUnion(buckets[CombatCell(x:x,y:y)] ?? [])
            }
        }
        return indices.sorted().map { walls[$0] }
    }
    func contains(_ point: CGPoint, clearance: CGFloat) -> Bool {
        candidates(in:CGRect(x:point.x-clearance,y:point.y-clearance,width:clearance*2,height:clearance*2))
            .contains { $0.insetBy(dx:-clearance,dy:-clearance).contains(point) }
    }
    func clearPath(from a: CGPoint, to b: CGPoint, clearance: CGFloat = 22) -> Bool {
        let box=CGRect(x:min(a.x,b.x)-clearance,y:min(a.y,b.y)-clearance,
                       width:abs(a.x-b.x)+2*clearance,height:abs(a.y-b.y)+2*clearance)
        for wall in candidates(in:box) {
            let rect=wall.insetBy(dx:-clearance,dy:-clearance)
            var enter: CGFloat = 0, leave: CGFloat = 1
            var misses = false
            for (start,delta,low,high) in [(a.x,b.x-a.x,rect.minX,rect.maxX),(a.y,b.y-a.y,rect.minY,rect.maxY)] {
                if abs(delta)<0.00001 {
                    if start<low || start>high { misses=true;break }
                } else {
                    let first=(low-start)/delta, second=(high-start)/delta
                    enter=max(enter,min(first,second));leave=min(leave,max(first,second))
                    if enter>leave {misses=true;break}
                }
            }
            if !misses { return false }
        }
        return true
    }
}
