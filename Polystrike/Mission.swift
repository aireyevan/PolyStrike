import Foundation

struct MissionStage {
    let title: String
    let type: MissionType
    let enemyCount: Int
    let duration: TimeInterval
    let objectiveCount: Int
    let arenaPhase: Int
    let arenaVariant: Int
    let formation: Int
    let hazard: Bool
    let bossType: BossType?
    let bossName: String?
    var instruction: String {
        switch type {
        case .elimination: return "BREAK THE FORMATIONS. CLEAR EVERY HOSTILE."
        case .capture: return "HOLD EACH RELAY. CLEAR HOSTILES TO UPLOAD."
        case .assault: return "DESTROY THE ARMORED POWER INSTALLATIONS."
        case .defense: return "PROTECT THE REACTOR. STAY CLOSE TO REPAIR IT."
        case .survival: return "SURVIVE THE SIEGE. AVOID MARKED IMPACTS."
        case .escape: return "HOLD OUT, THEN REACH THE EXTRACTION GATE."
        case .eliteHunt, .boss: return "READ THE ATTACKS. STRIKE THE EXPOSED CORE."
        }
    }
}

struct Mission: Identifiable {
    let sector: Int, number: Int
    let name: String
    let description: String
    let stages: [MissionStage]
    var id: String { "S\(sector)M\(number)" }
    var type: MissionType { stages.last?.type ?? .elimination }
    var enemyCount: Int { stages.reduce(0) { $0 + $1.enemyCount } }
    var duration: TimeInterval { stages.reduce(0) { $0 + $1.duration } }
    var objectiveCount: Int { stages.reduce(0) { $0 + $1.objectiveCount } }
    var bossName: String? { stages.compactMap(\.bossName).last }
    var difficulty: Int { (sector-1)*8+number }
    var reward: Int { 1000 + difficulty*175 + (number == 8 ? 2000 : 0) }
    var parTime: TimeInterval { stages.reduce(0) { $0 + max($1.duration+15, $1.type == .boss ? 100 : $1.type == .eliteHunt ? 70 : 50) } }
}

enum StoryCampaign {
    static let version = 2
    static let sectorNames = ["DEAD SIGNAL", "IRON CHOIR", "GLASS FRONT", "NIGHT ENGINE", "LAST FREQUENCY"]
    static let sectorStories = [
        "A rescue signal cuts through the silent grid. Follow it before the machines bury its source.",
        "The signal is a warning. Recover the reactors powering a city the network has turned into a weapon.",
        "Beyond the city, a mirrored defense lattice hides the route to the command network.",
        "The Architect is rebuilding the battlefield around you. Break its factories before they seal the route.",
        "The trapped fleet is still transmitting. Sever the Apex network and bring their ships home."
    ]
    static let missions: [Mission] = {
        // Every operation has a deliberate objective order; arenas and formations change at each checkpoint.
        let names = [
            ["FIRST CONTACT","SIGNAL TRACE","BREACH VECTOR","HUNTER SIGNAL","COLD RESTART","BROKEN ARRAY","EVACUATION LINE","GATEKEEPER"],
            ["CORE DUTY","IRON PROCESSION","TRIAD LINK","NULL VECTOR","BLACKOUT RUN","FOUNDRY SIEGE","LAST TRANSMISSION","NULL ENGINE"],
            ["BREAKOUT","MIRROR MAZE","NODEBREAKER","PREDATOR","REDLINE","PRISM LOCK","SHATTERED SKY","PRISM TYRANT"],
            ["LAST LIGHT","DEEP LINK","SIEGE VECTOR","DREAD ASSEMBLY","FACTORY ZERO","NIGHT SHIFT","FRACTURE LINE","CHROMA FORTRESS"],
            ["EXTINCTION","EVENT HORIZON","GHOST FLEET","EXECUTIONER","DEAD STAR","THE LONG RETURN","FINAL APPROACH","POLYSTRIKE"]
        ]
        let briefs = [
            ["Clear a landing route and recover the first signal relay.","Reconnect the listening posts while the grid wakes around you.","Punch through the power line and escape the counterattack.","Draw out the patrol commander and recover its navigation key.","Restart a stranded reactor, then cut the machines feeding on it.","Link the broken transmitters and hold the uplink open.","Keep the evacuation lane open for the ships behind you.","Disable the gate defenses and face the Hive Warden."],
            ["Bring the city's power spine back online under fire.","Intercept the machine columns marching on the reactor district.","Link three isolated stations before the network can silence them.","Hunt the fast attack engine inside its own supply route.","Destroy the relay batteries and run the blackout corridor.","Hold the foundry reactor while its defense grid comes online.","Send the city's warning through the last functioning transmitter.","Breach the engine chamber and stop the Pursuer Prime."],
            ["Escape the outer ring and establish a foothold in the glass front.","Read the mirrored routes and reconnect the scattered signal.","Dismantle the lattice anchors one installation at a time.","Break the ambush and force the Predator out of cover.","Weather the redline assault and seize its targeting relays.","Protect the decoder long enough to open the inner lattice.","Cut a path through the collapsing defense network.","Breach the prism vault and silence the Sentinel Tyrant."],
            ["Defend the last free reactor in the manufacturing belt.","Steal the production keys from the deep relay network.","Tear down the shield factories guarding the command route.","Confront the factory overseer before it completes its army.","Turn the assembly grid against its own power sources.","Keep the stolen uplink alive through a night of counterattacks.","Hold a route open while the factory network fractures.","Destroy the fortress feeds and duel the Architect."],
            ["Break the final legion's formations at the edge of the core.","Hold the fleet's entry point through the first collapse.","Reactivate the beacons guiding the stranded ships home.","Eliminate the fleet hunter before it reaches the survivors.","Cut the energy anchors feeding the dying star engine.","Protect the returning fleet's final navigation relay.","Breach the command perimeter and secure the core approach.","Defeat the Apex guard, sever the last feeds, and end the network."]
        ]
        let plans = [
            ["ecx","ced","asx","ehx","dax","cad","scx","adb"],
            ["edc","eax","cde","ahx","asx","dca","ecx","cab"],
            ["xea","ces","aex","shx","sce","dax","acx","eab"],
            ["eda","cae","ase","chx","adc","dsc","sax","dab"],
            ["eas","sdc","cax","ahx","asc","dce","eax","hab"]
        ]
        let maps = [[0,3,4,2,9,18,13,15], [2,9,18,6,8,14,12,7], [13,15,6,17,19,16,10,11], [8,14,12,7,5,3,18,9], [19,16,10,11,15,17,6,12]]
        let guardians: [BossType] = [.hive,.pursuer,.sentinel,.architect,.core]
        let eliteTypes: [BossType] = [.pursuer,.sentinel,.hive,.core,.architect]
        var result: [Mission] = []
        for sector in 1...5 {
            for number in 1...8 {
                var stages: [MissionStage] = []
                let codes = Array(plans[sector-1][number-1])
                for (index,code) in codes.enumerated() {
                    let type: MissionType
                    switch code { case "c":type = .capture;case "a":type = .assault;case "d":type = .defense;case "s":type = .survival;case "x":type = .escape;case "h":type = .eliteHunt;case "b":type = .boss;default:type = .elimination }
                    let boss = type == .boss ? guardians[sector-1] : type == .eliteHunt ? eliteTypes[sector-1] : nil
                    let labels: [MissionType:String] = [.elimination:"BREAK THE LINE",.capture:"LINK THE RELAYS",.assault:"CUT THE POWER",.defense:"HOLD THE REACTOR",.survival:"WEATHER THE SIEGE",.escape:"EXTRACTION RUN",.eliteHunt:"COMMANDER CONTACT",.boss:"GUARDIAN CHAMBER"]
                    let phase = boss != nil ? 20+(sector-1)%4 : maps[sector-1][(number-1+index*3)%8]
                    let objectives = type == .capture ? (sector>=3 ? 3:2) : type == .assault ? min(4,2+sector/2) : type == .defense ? 1:0
                    let duration: TimeInterval = [.survival,.defense].contains(type) ? Double(28+sector*6+index*4) : type == .escape ? Double(14+sector*3) : 0
                    stages.append(MissionStage(title:labels[type]!,type:type,enemyCount:type == .elimination ? 16+sector*5+number+index*3:0,duration:duration,objectiveCount:objectives,arenaPhase:phase,arenaVariant:(number+index+sector)%4,formation:(number+index*2+sector)%4,hazard:sector>=2 && [.assault,.survival,.escape].contains(type),bossType:boss,bossName:boss == nil ? nil : type == .boss ? names[sector-1][7] : "\(eliteTypes[sector-1].name) / INTERCEPT"))
                }
                result.append(Mission(sector:sector,number:number,name:names[sector-1][number-1],description:briefs[sector-1][number-1],stages:stages))
            }
        }
        return result
    }()

    /// Preserve the player's unlocked operation when the shorter campaign is expanded.
    static func migrateProgress(defaults: UserDefaults = .standard) {
        guard defaults.integer(forKey:"storyCampaignVersion") < version else { return }
        let legacy = [0,1,3,7,8,9,10,15,16,18,20,19,23,24,25,26,31,32,33,35,39]
        let old = max(0,min(legacy.count-1,defaults.integer(forKey:"polystrikeStoryMission")))
        let unlocked = defaults.bool(forKey:"polystrikeStoryComplete") ? missions.count-1 : legacy[old]
        defaults.set(unlocked,forKey:"polystrikeStoryMission")
        defaults.set(version,forKey:"storyCampaignVersion")
    }
}

/// Deterministic, separated entry points; all arrivals are telegraphed in the scene.
enum StoryFormation {
    static func positions(in arena:LivingArena,pattern:Int,group:Int,count:Int,player:CGPoint)->[CGPoint] {
        let far=arena.floorCenters.filter{hypot($0.x-player.x,$0.y-player.y)>420}
        var occupied:[CGPoint]=[]
        for index in 0..<max(0,count) {
            let side=(group+pattern+(pattern==1 ? (index%2)*2:0))%4
            var angle=CGFloat(side) * .pi/2
            let rank=CGFloat(index)-CGFloat(count-1)/2
            var distance:CGFloat=720,offset=rank*80
            switch pattern {
            case 0:distance += abs(rank)*55
            case 1:offset=CGFloat(index/2)*90-45
            case 2:angle += rank*0.22;offset=0
            default:distance=520+CGFloat(index)*80;offset=index.isMultiple(of:2) ? -45:45
            }
            let desired=CGPoint(x:arena.center.x+cos(angle)*distance-sin(angle)*offset,y:arena.center.y+sin(angle)*distance+cos(angle)*offset)
            let available=far.filter{point in occupied.allSatisfy{hypot($0.x-point.x,$0.y-point.y)>65}}
            if let position=available.min(by:{hypot($0.x-desired.x,$0.y-desired.y)<hypot($1.x-desired.x,$1.y-desired.y)}) {occupied.append(position)}
        }
        return occupied
    }
}
