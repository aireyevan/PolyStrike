import Foundation

struct Mission: Identifiable {
    let sector: Int, number: Int
    let name: String
    let type: MissionType
    let description: String
    let enemyCount: Int
    let duration: TimeInterval
    let objectiveCount: Int
    let arena: StoryArenaLayout
    let bossName: String?
    var id: String { "S\(sector)M\(number)" }
}

enum StoryCampaign {
    private static func m(_ s: Int, _ n: Int, _ name: String, _ type: MissionType, _ description: String,
                          enemies: Int = 0, time: TimeInterval = 0, objectives: Int = 0,
                          arena: StoryArenaLayout, boss: String? = nil) -> Mission {
        Mission(sector: s, number: n, name: name, type: type, description: description,
                enemyCount: enemies, duration: time, objectiveCount: objectives, arena: arena, bossName: boss)
    }
    static let missions: [Mission] = [
        m(1,1,"FIRST CONTACT",.elimination,"DESTROY ALL ENEMIES",enemies:28,arena:.openGrid),
        m(1,2,"PRESSURE WAVE",.survival,"SURVIVE THE ONSLAUGHT",time:60,arena:.crossfire),
        m(1,3,"HUNTER SIGNAL",.eliteHunt,"DESTROY THE ELITE",arena:.pursuitLanes,boss:"VANGUARD"),
        m(1,4,"GATEKEEPER",.boss,"DEFEAT THE SECTOR GUARDIAN",arena:.bossHex,boss:"HEX WARDEN"),
        m(2,1,"CORE DUTY",.defense,"PROTECT THE REACTOR",time:70,objectives:1,arena:.reactorRing),
        m(2,2,"CLEAN SWEEP",.elimination,"PURGE THE OCCUPATION",enemies:42,arena:.crossfire),
        m(2,3,"TRIAD LINK",.capture,"SECURE ALL THREE CONTROL POINTS",objectives:3,arena:.controlTriangle),
        m(2,4,"NULL ENGINE",.boss,"BREAK THE SECTOR ENGINE",arena:.bossHex,boss:"NULL ENGINE"),
        m(3,1,"BREAKOUT",.escape,"SURVIVE, THEN REACH EXTRACTION",time:55,objectives:1,arena:.pursuitLanes),
        m(3,2,"NODEBREAKER",.assault,"DESTROY ALL ENEMY NODES",objectives:4,arena:.fortress),
        m(3,3,"REDLINE",.survival,"ENDURE THE REDLINE",time:90,arena:.crossfire),
        m(3,4,"PREDATOR",.eliteHunt,"TERMINATE THE PREDATOR",arena:.pursuitLanes,boss:"PREDATOR"),
        m(3,5,"PRISM TYRANT",.boss,"DEFEAT THE PRISM TYRANT",arena:.bossHex,boss:"PRISM TYRANT"),
        m(4,1,"LAST LIGHT",.defense,"HOLD THE REACTOR LINE",time:90,objectives:1,arena:.reactorRing),
        m(4,2,"DEEP LINK",.capture,"CAPTURE THE GRID",objectives:3,arena:.controlTriangle),
        m(4,3,"SIEGE VECTOR",.assault,"DESTROY THE SHIELD NETWORK",objectives:5,arena:.fortress),
        m(4,4,"CHROMA FORTRESS",.boss,"SHATTER THE FORTRESS",arena:.bossHex,boss:"CHROMA FORTRESS"),
        m(5,1,"EXTINCTION",.elimination,"DESTROY THE FINAL LEGION",enemies:65,arena:.finalCore),
        m(5,2,"EVENT HORIZON",.survival,"SURVIVE THE COLLAPSE",time:90,arena:.finalCore),
        m(5,3,"EXECUTIONER",.eliteHunt,"DESTROY THE EXECUTIONER",arena:.fortress,boss:"EXECUTIONER"),
        m(5,4,"POLYSTRIKE",.boss,"DESTROY THE APEX CORE",arena:.finalCore,boss:"THE APEX CORE")
    ]
}
