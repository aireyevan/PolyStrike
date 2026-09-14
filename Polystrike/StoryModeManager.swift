import Foundation
import CoreGraphics

final class StoryModeManager {
    private(set) var missionIndex: Int
    private(set) var stageIndex = 0
    private(set) var phase: MissionPhase = .briefing
    private(set) var elapsed: TimeInterval = 0
    private(set) var totalElapsed: TimeInterval = 0
    private(set) var spawned = 0
    private(set) var pendingSpawns = 0
    private(set) var killed = 0
    private(set) var objectiveHealth: CGFloat = 100
    private(set) var completedObjectives = 0
    private(set) var captureProgress: [CGFloat] = []
    private(set) var extractionAvailable = false
    private(set) var eliteDefeated = false
    private(set) var eliteHealth: CGFloat = 1
    private var spawnClock: TimeInterval = 0
    private let defaults: UserDefaults
    let isReplay: Bool
    var mission: Mission { StoryCampaign.missions[missionIndex] }
    var stage: MissionStage { mission.stages[stageIndex] }
    var isLastMission: Bool { missionIndex == StoryCampaign.missions.count-1 }
    var enemyLimit: Int { min(32,10+mission.sector*3+stageIndex*2) }
    var formationSize: Int { min(6,2+mission.sector) }
    var spawnInterval: TimeInterval { max(1.25,3.1-Double(mission.sector)*0.26-Double(stageIndex)*0.12) }
    var pressure: CGFloat { CGFloat(mission.difficulty-1)/39 }

    init(missionIndex: Int? = nil, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        StoryCampaign.migrateProgress(defaults:defaults)
        let saved=defaults.integer(forKey:"polystrikeStoryMission")
        self.missionIndex=min(max(0,missionIndex ?? saved),StoryCampaign.missions.count-1)
        isReplay=self.missionIndex<saved || defaults.bool(forKey:"polystrikeStoryComplete")
        if !isReplay && defaults.string(forKey:"storyCheckpointMission") == mission.id {
            stageIndex=min(max(0,defaults.integer(forKey:"storyCheckpointStage")),mission.stages.count-1)
            totalElapsed=max(0,defaults.double(forKey:"storyCheckpointTime"))
        }
        resetStage()
    }
    private func resetStage() {
        phase = .briefing;elapsed=0;spawned=0;pendingSpawns=0;killed=0;objectiveHealth=100
        completedObjectives=0;extractionAvailable=false;eliteDefeated=false;eliteHealth=1;spawnClock=0
        captureProgress=Array(repeating:0,count:stage.objectiveCount)
    }
    func reset() { stageIndex=0;totalElapsed=0;resetStage() }
    func retryCurrentStage() { resetStage() }
    func begin() { if phase == .briefing { phase = .active } }
    func tick(_ delta: TimeInterval,enemiesAlive: Int) {
        guard phase == .active else { return }
        let dt=max(0,min(delta,0.1));elapsed += dt;totalElapsed += dt;spawnClock += dt
        switch stage.type {
        case .elimination where spawned>=stage.enemyCount && pendingSpawns==0 && killed>=stage.enemyCount && enemiesAlive==0: complete()
        case .survival,.defense: if elapsed>=stage.duration { complete() }
        case .capture,.assault: if completedObjectives>=stage.objectiveCount { complete() }
        case .eliteHunt,.boss: if eliteDefeated { complete() }
        case .escape where elapsed>=stage.duration: extractionAvailable=true
        default: break
        }
    }
    func shouldSpawn(enemiesAlive: Int)->Bool {
        guard phase == .active,spawnClock>=spawnInterval,stage.bossType == nil,enemiesAlive+pendingSpawns<enemyLimit else {return false}
        return stage.type != .elimination || spawned<stage.enemyCount
    }
    func registeredSpawn() { spawned += 1;pendingSpawns += 1;spawnClock=0 }
    func spawnArrived() { pendingSpawns=max(0,pendingSpawns-1) }
    func enemyDefeated(elite:Bool,objectiveTarget:Bool) {
        guard phase == .active else {return}
        if objectiveTarget { completedObjectives=min(stage.objectiveCount,completedObjectives+1) } else { killed += 1 }
        if elite {eliteDefeated=true}
    }
    func updateEliteHealth(_ ratio:CGFloat) {eliteHealth=max(0,min(1,ratio))}
    func damageObjective(_ amount:CGFloat) {
        guard phase == .active,stage.type == .defense else {return}
        objectiveHealth=max(0,objectiveHealth-max(0,amount));if objectiveHealth<=0 {fail()}
    }
    func repairObjective(_ delta:TimeInterval) {
        guard phase == .active,stage.type == .defense else {return}
        objectiveHealth=min(100,objectiveHealth+CGFloat(max(0,delta))*2.5)
    }
    func holdCaptureZone(_ index:Int,delta:TimeInterval,contested:Bool=false) {
        guard phase == .active,stage.type == .capture,!contested,captureProgress.indices.contains(index),captureProgress[index]<1 else {return}
        captureProgress[index]=min(1,captureProgress[index]+CGFloat(max(0,delta)/(6+Double(mission.sector))))
        completedObjectives=captureProgress.filter{$0>=1}.count
    }
    func reachedExtraction() {if phase == .active && extractionAvailable {complete()}}
    func complete() {if phase == .active {phase=stageIndex+1<mission.stages.count ? .checkpoint:.complete}}
    func fail() {if phase == .active {phase = .failed}}
    @discardableResult func advanceStage()->Bool {
        guard phase == .checkpoint,stageIndex+1<mission.stages.count else {return false}
        stageIndex += 1
        if !isReplay {
            defaults.set(mission.id,forKey:"storyCheckpointMission");defaults.set(stageIndex,forKey:"storyCheckpointStage");defaults.set(totalElapsed,forKey:"storyCheckpointTime")
        }
        resetStage();return true
    }
    func recordVictory(healthRatio:CGFloat)->(stars:Int,reward:Int) {
        guard phase == .complete else {return (0,0)}
        let stars=1+(totalElapsed<=mission.parTime ? 1:0)+(healthRatio>=0.5 ? 1:0)
        let key="storyMedal.\(mission.id)",old=defaults.integer(forKey:key)
        defaults.set(max(old,stars),forKey:key)
        let bestKey="storyBest.\(mission.id)",best=defaults.double(forKey:bestKey)
        if best==0 || totalElapsed<best {defaults.set(totalElapsed,forKey:bestKey)}
        if !isReplay {
            defaults.set(max(defaults.integer(forKey:"polystrikeStoryMission"),min(StoryCampaign.missions.count-1,missionIndex+1)),forKey:"polystrikeStoryMission")
            defaults.removeObject(forKey:"storyCheckpointMission")
            if isLastMission {defaults.set(true,forKey:"polystrikeStoryComplete")}
        }
        return (stars,old==0 ? mission.reward:0)
    }
    func advance()->Bool {
        guard phase == .complete,!isLastMission else {return false}
        missionIndex += 1;stageIndex=0;totalElapsed=0;resetStage();return true
    }
    var status: MissionStatus {
        let prefix="\(stageIndex+1)/\(mission.stages.count) • "
        let value:String,progress:CGFloat
        switch stage.type {
        case .elimination:value="\(max(0,stage.enemyCount-killed)) HOSTILES";progress=CGFloat(killed)/CGFloat(max(1,stage.enemyCount))
        case .capture,.assault:value="\(completedObjectives) / \(stage.objectiveCount) SECURED";progress=CGFloat(completedObjectives)/CGFloat(max(1,stage.objectiveCount))
        case .defense:value="CORE \(Int(objectiveHealth))% • \(timeRemaining)";progress=objectiveHealth/100
        case .eliteHunt,.boss:value="CORE \(Int(eliteHealth*100))%";progress=eliteHealth
        case .escape:value=extractionAvailable ? "REACH THE GATE":timeRemaining;progress=min(1,CGFloat(elapsed/max(1,stage.duration)))
        case .survival:value=timeRemaining;progress=min(1,CGFloat(elapsed/max(1,stage.duration)))
        }
        return MissionStatus(title:prefix+stage.type.title,value:value,progress:min(1,progress))
    }
    private var timeRemaining:String {let s=max(0,Int(ceil(stage.duration-elapsed)));return String(format:"%02d:%02d",s/60,s%60)}
}
