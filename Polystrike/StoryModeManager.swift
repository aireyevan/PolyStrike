import Foundation
import CoreGraphics

final class StoryModeManager {
    private(set) var missionIndex: Int
    private(set) var phase: MissionPhase = .briefing
    private(set) var elapsed: TimeInterval = 0
    private(set) var spawned = 0
    private(set) var killed = 0
    private(set) var objectiveHealth: CGFloat = 100
    private(set) var completedObjectives = 0
    private(set) var captureProgress: [CGFloat] = []
    private(set) var extractionAvailable = false
    private(set) var eliteDefeated = false
    private(set) var eliteHealth: CGFloat = 1
    private var spawnClock: TimeInterval = 0
    let isReplay: Bool

    var mission: Mission { StoryCampaign.missions[missionIndex] }
    var isLastMission: Bool { missionIndex == StoryCampaign.missions.count - 1 }

    init(missionIndex: Int? = nil) {
        let saved = UserDefaults.standard.integer(forKey: "polystrikeStoryMission")
        self.missionIndex = min(max(0, missionIndex ?? saved), StoryCampaign.missions.count - 1)
        self.isReplay = missionIndex != nil && (self.missionIndex < saved || UserDefaults.standard.bool(forKey: "polystrikeStoryComplete"))
        reset()
    }
    func reset() {
        phase = .briefing; elapsed = 0; spawned = 0; killed = 0; objectiveHealth = 100
        completedObjectives = 0; extractionAvailable = false; eliteDefeated = false; eliteHealth = 1; spawnClock = 0
        captureProgress = Array(repeating: 0, count: mission.objectiveCount)
    }
    func begin() { phase = .active }
    func tick(_ delta: TimeInterval, enemiesAlive: Int) {
        guard phase == .active else { return }
        elapsed += delta; spawnClock += delta
        switch mission.type {
        case .elimination where spawned >= mission.enemyCount && killed >= mission.enemyCount && enemiesAlive == 0: complete()
        case .survival, .defense: if elapsed >= mission.duration { complete() }
        case .capture, .assault: if completedObjectives >= mission.objectiveCount { complete() }
        case .eliteHunt, .boss: if eliteDefeated { complete() }
        case .escape where elapsed >= mission.duration: extractionAvailable = true
        default: break
        }
    }
    func shouldSpawn(enemiesAlive: Int) -> Bool {
        guard phase == .active, spawnClock >= spawnInterval else { return false }
        if mission.type == .boss { return false }
        if mission.type == .elimination { return spawned < mission.enemyCount && enemiesAlive < 10 }
        return enemiesAlive < (mission.type == .eliteHunt ? 10 + mission.sector : 10 + mission.sector * 3)
    }
    func registeredSpawn() { spawned += 1; spawnClock = 0 }
    func enemyDefeated(elite: Bool, objectiveTarget: Bool) {
        if objectiveTarget { completedObjectives += 1 } else { killed += 1 }
        if elite { eliteDefeated = true }
    }
    func updateEliteHealth(_ ratio: CGFloat) { eliteHealth = max(0, min(1, ratio)) }
    func damageObjective(_ amount: CGFloat) {
        guard phase == .active, mission.type == .defense else { return }
        objectiveHealth = max(0, objectiveHealth - amount)
        if objectiveHealth <= 0 { fail() }
    }
    func holdCaptureZone(_ index: Int, delta: TimeInterval) {
        guard phase == .active, captureProgress.indices.contains(index), captureProgress[index] < 1 else { return }
        captureProgress[index] = min(1, captureProgress[index] + CGFloat(delta / 7.5))
        completedObjectives = captureProgress.filter { $0 >= 1 }.count
    }
    func reachedExtraction() { if extractionAvailable { complete() } }
    func complete() { if phase == .active { phase = .complete } }
    func fail() { if phase == .active { phase = .failed } }
    func advance() -> Bool {
        guard !isLastMission else { return false }
        missionIndex += 1
        let previous = UserDefaults.standard.integer(forKey: "polystrikeStoryMission")
        UserDefaults.standard.set(max(previous, missionIndex), forKey: "polystrikeStoryMission")
        reset(); return true
    }
    var spawnInterval: TimeInterval { max(0.48, 1.05 - Double(mission.sector) * 0.10) }
    var status: MissionStatus {
        switch mission.type {
        case .elimination: return MissionStatus(title:"ENEMIES REMAINING",value:"\(max(0,mission.enemyCount-killed))",progress:CGFloat(killed)/CGFloat(max(1,mission.enemyCount)))
        case .survival: return timed("SURVIVE")
        case .defense: return MissionStatus(title:"PROTECT REACTOR",value:"\(Int(objectiveHealth))%  •  \(timeRemaining)",progress:objectiveHealth/100)
        case .capture: return counted("CAPTURE ZONES")
        case .eliteHunt: return MissionStatus(title:"ELITE HUNT",value:"\(mission.bossName ?? "ELITE")  \(Int(eliteHealth * 100))%",progress:eliteHealth)
        case .escape: return MissionStatus(title:extractionAvailable ? "EXTRACT":"EXTRACTION IN",value:extractionAvailable ? "REACH THE PORTAL":timeRemaining,progress:min(1,CGFloat(elapsed/mission.duration)))
        case .assault: return counted("TARGETS DESTROYED")
        case .boss: return MissionStatus(title:mission.bossName ?? "BOSS",value:"HEALTH  \(Int(eliteHealth * 100))%",progress:eliteHealth)
        }
    }
    private func counted(_ title:String)->MissionStatus { MissionStatus(title:title,value:"\(completedObjectives) / \(mission.objectiveCount)",progress:CGFloat(completedObjectives)/CGFloat(max(1,mission.objectiveCount))) }
    private func timed(_ title:String)->MissionStatus { MissionStatus(title:title,value:timeRemaining,progress:min(1,CGFloat(elapsed/mission.duration))) }
    private var timeRemaining:String { let s=max(0,Int(ceil(mission.duration-elapsed))); return String(format:"%02d:%02d",s/60,s%60) }
}
