import Foundation

enum ShipStyle: String, CaseIterable {
    case striker, viper, spectre, nova, eclipse, sovereign

    var title: String {
        switch self {
        case .striker: return "NEON STRIKER"
        case .viper: return "VOID VIPER"
        case .spectre: return "PHASE SPECTRE"
        case .nova: return "NOVA LANCER"
        case .eclipse: return "ECLIPSE REAPER"
        case .sovereign: return "FLUX SOVEREIGN"
        }
    }

    var subtitle: String {
        switch self {
        case .striker: return "ORIGINAL INTERCEPTOR"
        case .viper: return "RAZOR-WING HUNTER"
        case .spectre: return "GHOST PHASE FRAME"
        case .nova: return "STELLAR ASSAULT CRAFT"
        case .eclipse: return "DARK-MATTER PREDATOR"
        case .sovereign: return "ULTIMATE FLUX RELIC"
        }
    }

    var price: Int {
        switch self {
        case .striker: return 0
        case .viper: return 250_000
        case .spectre: return 500_000
        case .nova: return 850_000
        case .eclipse: return 1_250_000
        case .sovereign: return 2_000_000
        }
    }
}

class PlayerProgress {
    
    static let shared = PlayerProgress()
    
    // MARK: - Permanent Currency
    
    private(set) var points: Int = 0
    
    // MARK: - Permanent Upgrade Levels
    
    private(set) var fireRateLevel: Int = 0
    private(set) var healthLevel: Int = 0
    private(set) var damageLevel: Int = 0
    private(set) var speedLevel: Int = 0
    
    // MARK: - Special Upgrades
    
    private(set) var doubleShotUnlocked: Bool = false
    
    private let pointsKey = "playerPoints"
    private let fireRateKey = "fireRateLevel"
    private let healthKey = "healthLevel"
    private let damageKey = "damageLevel"
    private let speedKey = "speedLevel"
    private let doubleShotKey = "doubleShotUnlocked"
    private let ownedShipsKey = "ownedShipStyles"
    private let selectedShipKey = "selectedShipStyle"
    
    private let defaults: UserDefaults
    var flux: Int { points }
    var selectedShip: ShipStyle {
        let saved = defaults.string(forKey: selectedShipKey)
        let style = saved.flatMap(ShipStyle.init(rawValue:)) ?? .striker
        return owns(style) ? style : .striker
    }

    func owns(_ style: ShipStyle) -> Bool {
        style == .striker || Set(defaults.stringArray(forKey: ownedShipsKey) ?? []).contains(style.rawValue)
    }

    @discardableResult
    func buyShip(_ style: ShipStyle) -> Bool {
        guard !owns(style), style.price > 0, points >= style.price else { return false }
        points -= style.price
        var owned = Set(defaults.stringArray(forKey: ownedShipsKey) ?? [])
        owned.insert(style.rawValue)
        defaults.set(Array(owned), forKey: ownedShipsKey)
        defaults.set(style.rawValue, forKey: selectedShipKey)
        save()
        return true
    }

    @discardableResult
    func selectShip(_ style: ShipStyle) -> Bool {
        guard owns(style) else { return false }
        defaults.set(style.rawValue, forKey: selectedShipKey)
        return true
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }
    
    
    // MARK: - Add Points
    
    func addPoints(_ amount: Int) {
        guard amount > 0 else { return }
        points += amount
        save()
    }
    
    
    // MARK: - Upgrade Costs
    
    func fireRateCost() -> Int {
        return 500 + (fireRateLevel * 350) + max(0, fireRateLevel - 20) * max(0, fireRateLevel - 20) * 35
    }
    
    func healthCost() -> Int {
        return 750 + (healthLevel * 400) + max(0, healthLevel - 20) * max(0, healthLevel - 20) * 35
    }
    
    func damageCost() -> Int {
        return 1000 + (damageLevel * 500) + max(0, damageLevel - 20) * max(0, damageLevel - 20) * 35
    }
    
    func speedCost() -> Int {
        return 750 + (speedLevel * 400) + max(0, speedLevel - 20) * max(0, speedLevel - 20) * 35
    }
    
    func doubleShotCost() -> Int {
        return 50000
    }
    
    
    // MARK: - Purchase Upgrades
    
    @discardableResult
    func buyFireRate() -> Bool {
        
        guard fireRateLevel < 60 else {
            return false
        }
        
        let cost = fireRateCost()
        
        guard points >= cost else {
            return false
        }
        
        points -= cost
        fireRateLevel += 1
        
        save()
        
        return true
    }
    
    
    @discardableResult
    func buyHealth() -> Bool {
        
        guard healthLevel < 60 else {
            return false
        }
        
        let cost = healthCost()
        
        guard points >= cost else {
            return false
        }
        
        points -= cost
        healthLevel += 1
        
        save()
        
        return true
    }
    
    
    @discardableResult
    func buyDamage() -> Bool {
        
        guard damageLevel < 60 else {
            return false
        }
        
        let cost = damageCost()
        
        guard points >= cost else {
            return false
        }
        
        points -= cost
        damageLevel += 1
        
        save()
        
        return true
    }
    
    
    @discardableResult
    func buySpeed() -> Bool {
        
        guard speedLevel < 60 else {
            return false
        }
        
        let cost = speedCost()
        
        guard points >= cost else {
            return false
        }
        
        points -= cost
        speedLevel += 1
        
        save()
        
        return true
    }
    
    
    @discardableResult
    func buyDoubleShot() -> Bool {
        
        guard !doubleShotUnlocked else {
            return false
        }
        
        let cost = doubleShotCost()
        
        guard points >= cost else {
            return false
        }
        
        points -= cost
        doubleShotUnlocked = true
        
        save()
        
        return true
    }
    
    
    // MARK: - Player Stats
    
    func playerHealth() -> CGFloat {
        return 100 + CGFloat(healthLevel * 10)
    }
    
    func playerDamage() -> CGFloat {
        return 10 + CGFloat(damageLevel * 2)
    }
    
    func playerMoveSpeed() -> CGFloat {
        return 300 + CGFloat(min(20, speedLevel) * 12 + max(0, speedLevel - 20) * 3)
    }
    
    func playerFireRate() -> TimeInterval {
        
        let reduction = Double(min(20, fireRateLevel)) * 0.005 + Double(max(0, fireRateLevel - 20)) * 0.001125
        
        return max(
            0.055,
            0.20 - reduction
        )
    }
    
    
    // MARK: - Save
    
    private func save() {
        

        
        defaults.set(points, forKey: pointsKey)
        defaults.set(fireRateLevel, forKey: fireRateKey)
        defaults.set(healthLevel, forKey: healthKey)
        defaults.set(damageLevel, forKey: damageKey)
        defaults.set(speedLevel, forKey: speedKey)
        defaults.set(doubleShotUnlocked, forKey: doubleShotKey)
    }
    
    
    // MARK: - Load
    
    private func load() {
        

        
        points = defaults.integer(
            forKey: pointsKey
        )
        
        fireRateLevel = defaults.integer(
            forKey: fireRateKey
        )
        
        healthLevel = defaults.integer(
            forKey: healthKey
        )
        
        damageLevel = defaults.integer(
            forKey: damageKey
        )
        
        speedLevel = defaults.integer(
            forKey: speedKey
        )
        
        doubleShotUnlocked = defaults.bool(
            forKey: doubleShotKey
        )
    }
}


enum ShipUpgrade: String, CaseIterable {
    case fire, damage, doubleShot, bomb, health, armor, repair, dash, speed, magnet, salvage
    var title: String {
        switch self {
        case .fire: return "RAPID FIRE"
        case .damage: return "HEAVY ROUNDS"
        case .doubleShot: return "DOUBLE SHOT"
        case .bomb: return "SHOCKWAVE"
        case .health: return "REINFORCED HULL"
        case .armor: return "ARMOR PLATING"
        case .repair: return "NANITE REPAIR"
        case .dash: return "PHASE DASH"
        case .speed: return "THRUSTERS"
        case .magnet: return "FLUX MAGNET"
        case .salvage: return "SALVAGE ARRAY"
        }
    }
    var cap: Int {
        switch self {
        case .fire, .damage, .health, .speed: return 60
        case .doubleShot: return 1
        default: return 20
        }
    }
    func effect(at level: Int) -> String {
        switch self {
        case .fire: return String(format: "%.3fs / shot", max(0.055, 0.20 - Double(min(20, level)) * 0.005 - Double(max(0, level-20)) * 0.001125))
        case .damage: return "\(10 + level * 2) damage"
        case .health: return "\(100 + level * 10) HP"
        case .speed: return "\(300 + min(20, level) * 12 + max(0, level-20) * 3) speed"
        case .doubleShot: return level == 0 ? "1 projectile" : "2 projectiles"
        case .armor: return "\(level * 2)% resistance"
        case .repair: return String(format: "%.2f HP/s", Double(level) * 0.25)
        case .magnet: return "\(110 + level * 8) range"
        case .salvage: return "+\(level * 2)% Flux"
        case .bomb: return level == 0 ? "Locked" : "\(80 + level * 20) dmg / \(Int(max(12, 32 - Double(level) * 0.8)))s"
        case .dash: return level == 0 ? "Locked" : String(format: "%.1fs recharge", max(2.5, 9 - Double(level) * 0.3))
        }
    }
}

extension PlayerProgress {
    func level(_ upgrade: ShipUpgrade) -> Int {
        switch upgrade {
        case .fire: return fireRateLevel
        case .damage: return damageLevel
        case .health: return healthLevel
        case .speed: return speedLevel
        case .doubleShot: return doubleShotUnlocked ? 1 : 0
        default: return min(upgrade.cap, max(0, defaults.integer(forKey: "shipUpgrade." + upgrade.rawValue)))
        }
    }
    func cost(_ upgrade: ShipUpgrade) -> Int {
        switch upgrade {
        case .fire: return fireRateCost()
        case .damage: return damageCost()
        case .health: return healthCost()
        case .speed: return speedCost()
        case .doubleShot: return doubleShotCost()
        default:
            let l = level(upgrade)
            return (upgrade == .dash ? 1500 : 1200) + l * 700 + l * l * 50
        }
    }
    @discardableResult func buy(_ upgrade: ShipUpgrade) -> Bool {
        switch upgrade {
        case .fire: return buyFireRate()
        case .damage: return buyDamage()
        case .health: return buyHealth()
        case .speed: return buySpeed()
        case .doubleShot: return buyDoubleShot()
        default:
            let l = level(upgrade), price = cost(upgrade)
            guard l < upgrade.cap, points >= price else { return false }
            points -= price
            defaults.set(l + 1, forKey: "shipUpgrade." + upgrade.rawValue)
            save()
            return true
        }
    }
    var damageMultiplier: CGFloat { 1 - CGFloat(level(.armor)) * 0.02 }
    var repairPerSecond: CGFloat { CGFloat(level(.repair)) * 0.25 }
    var magnetRange: CGFloat { 110 + CGFloat(level(.magnet)) * 8 }
    var bombCooldown: TimeInterval { max(12, 32 - Double(level(.bomb)) * 0.8) }
    var dashCooldown: TimeInterval { max(2.5, 9 - Double(level(.dash)) * 0.3) }
}
