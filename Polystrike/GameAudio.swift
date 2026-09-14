import AVFoundation
import UIKit

// Three persistent, independent buses. Zero is a true mute.
enum AudioChannel: String, CaseIterable {
    case music, weapons, effects
    var title:String {switch self {case .music:return "MUSIC";case .weapons:return "WEAPON NOISE";case .effects:return "IN-GAME NOISE"}}
    var defaultVolume:Float {self == .music ? 0.6:0.8}
}
enum GameSound:String,CaseIterable {
    case weapon,enemyWeapon,impact,explosion,bossExplosion,dash,shockwave,damage,pickup,warning,complete,defeat
    var channel:AudioChannel {self == .weapon || self == .enemyWeapon ? .weapons:.effects}
    var cooldown:TimeInterval {
        switch self {case .weapon:return 0.055;case .enemyWeapon:return 0.12;case .impact:return 0.075;case .explosion:return 0.09;case .pickup:return 0.1;default:return 0.2}
    }
}

/// Main-thread admission is cheap; all decoding and AVFoundation work stays on one audio queue.
final class GameAudio {
    static let shared=GameAudio()
    private let queue=DispatchQueue(label:"com.polystrike.audio",qos:.userInitiated)
    private let capacity=DispatchSemaphore(value:8)
    // Accessed exclusively by queue, including initialization of the audio graph.
    private var renderer:AudioRenderer?
    private var volumes:[AudioChannel:Float]=[:]
    private var lastPlayed:[GameSound:TimeInterval]=[:]
    private var bossActive=false
    private(set) var running=false
    private init() {
        refreshVolumes()
        NotificationCenter.default.addObserver(self,selector:#selector(interrupted),name:UIApplication.willResignActiveNotification,object:nil)
    }
    static func url(_ name:String,extension ext:String)->URL? {
        Bundle.main.url(forResource:name,withExtension:ext,subdirectory:"Audio") ?? Bundle.main.url(forResource:name,withExtension:ext)
    }
    private func refreshVolumes() {for channel in AudioChannel.allCases {volumes[channel]=GameSettings.shared.volume(channel)}}
    private func enqueue(_ action:@escaping (AudioRenderer)->Void) {
        queue.async { [self] in
            if renderer == nil {renderer=AudioRenderer()}
            action(renderer!)
        }
    }
    func applyVolumes() {
        refreshVolumes();let values=volumes
        enqueue {$0.volumes=values;$0.applyVolumes()}
    }
    func beginRun() {
        running=true;bossActive=false;lastPlayed.removeAll();applyVolumes()
        enqueue {$0.beginRun()}
    }
    func setBossActive(_ boss:Bool) {
        guard boss != bossActive else{return};bossActive=boss
        enqueue {$0.setBossActive(boss)}
    }
    func play(_ sound:GameSound,pan:Float=0,preview:Bool=false) {
        guard running || preview,volumes[sound.channel,default:0]>0 else{return}
        let now=ProcessInfo.processInfo.systemUptime
        guard now-lastPlayed[sound,default: -100]>sound.cooldown else{return}
        guard capacity.wait(timeout:.now()) == .success else{return}
        lastPlayed[sound]=now
        enqueue { [capacity] renderer in
            defer {capacity.signal()}
            // Never replay a burst that became stale while loading audio or changing scenes.
            guard ProcessInfo.processInfo.systemUptime-now<0.12 else{return}
            renderer.play(sound,pan:pan,preview:preview)
        }
    }
    func preview(_ channel:AudioChannel) {
        applyVolumes()
        if channel == .music {enqueue {$0.preview(.music)}}
        else {play(channel == .weapons ? .weapon:.explosion,preview:true)}
    }
    func pause() {running=false;enqueue {$0.pause()}}
    func resume() {running=true;applyVolumes();enqueue {$0.resume()}}
    func endPreview() {if !running {pause()}}
    func stop() {running=false;lastPlayed.removeAll();enqueue {$0.stop()}}
    @objc private func interrupted() {pause()}
}

/// Audio is decoded once; twelve reusable voices bound the cost of dense combat.
private final class AudioRenderer {
    private let engine=AVAudioEngine(),weaponBus=AVAudioMixerNode(),effectBus=AVAudioMixerNode()
    private var voices:[AudioChannel:[AVAudioPlayerNode]]=[:]
    private var busyUntil:[ObjectIdentifier:TimeInterval]=[:]
    private var buffers:[GameSound:AVAudioPCMBuffer]=[:]
    private var lastPlayed:[GameSound:TimeInterval]=[:]
    private var music:[String:AVAudioPlayer]=[:]
    private var activeTrack="GridPulse"
    private(set) var running=false
    private(set) var prepared=false
    private var musicPreview=false
    var volumes:[AudioChannel:Float]=[:]
    init() {}
    static func url(_ name:String,extension ext:String)->URL? {
        Bundle.main.url(forResource:name,withExtension:ext,subdirectory:"Audio") ?? Bundle.main.url(forResource:name,withExtension:ext)
    }
    private func prepare() {
        guard !prepared else{return}
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient,mode:.default,options:[.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            for sound in GameSound.allCases {
                guard let url=Self.url(sound.rawValue,extension:"wav") else{continue}
                let file=try AVAudioFile(forReading:url)
                if let buffer=AVAudioPCMBuffer(pcmFormat:file.processingFormat,frameCapacity:AVAudioFrameCount(file.length)) {try file.read(into:buffer);buffers[sound]=buffer}
            }
            guard let format=buffers[.weapon]?.format else{return}
            engine.attach(weaponBus);engine.attach(effectBus)
            engine.connect(weaponBus,to:engine.mainMixerNode,format:format)
            engine.connect(effectBus,to:engine.mainMixerNode,format:format)
            for channel:AudioChannel in [.weapons,.effects] {
                voices[channel]=(0..<(channel == .weapons ? 4:8)).map{_ in
                    let node=AVAudioPlayerNode();engine.attach(node);engine.connect(node,to:channel == .weapons ? weaponBus:effectBus,format:format);node.volume=0.22;return node
                }
            }
            engine.mainMixerNode.outputVolume=0.33
            prepared=true
            for name in ["GridPulse","CoreOverdrive"] {
                if let url=Self.url(name,extension:"m4a") {let player=try AVAudioPlayer(contentsOf:url);player.numberOfLoops = -1;player.prepareToPlay();music[name]=player}
            }
            prepared=true;applyVolumes();engine.prepare()
        } catch {print("Audio unavailable: \(error.localizedDescription)")}
    }
    func beginRun() {prepare();stop();activeTrack="GridPulse";running=true;resume()}
    func setBossActive(_ boss:Bool) {
        let next=boss ? "CoreOverdrive":"GridPulse"
        guard next != activeTrack else{return}
        let previous=music[activeTrack];activeTrack=next
        guard running else{return}
        previous?.pause()
        if let player=music[next],musicVolume>0 {player.currentTime=0;player.volume=musicVolume;player.play()}
    }

    private func startMusic() {if musicVolume>0 {music[activeTrack]?.play()}}
    private var musicVolume:Float {pow(volumes[.music,default:0],2)*0.28}
    func applyVolumes() {
        weaponBus.outputVolume=pow(volumes[.weapons,default:0],2)
        effectBus.outputVolume=pow(volumes[.effects,default:0],2)
        for (name,player) in music {player.volume=name==activeTrack ? musicVolume:0;if musicVolume==0 {player.pause()}}
        if running || musicPreview {startMusic()}
    }
    func play(_ sound:GameSound,pan:Float=0,preview:Bool=false) {
        guard running || preview else{return}
        if preview {prepare()}
        guard volumes[sound.channel,default:0]>0,let buffer=buffers[sound],let pool=voices[sound.channel],!pool.isEmpty else{return}
        let now=ProcessInfo.processInfo.systemUptime
        guard now-lastPlayed[sound,default: -100]>sound.cooldown else{return};lastPlayed[sound]=now
        if !engine.isRunning {do {try engine.start()}catch{return}}
        // Drop excess sounds instead of interrupting voices and synchronizing the render graph.
        guard let voice=pool.first(where:{busyUntil[ObjectIdentifier($0),default:0] <= now}) else{return}
        busyUntil[ObjectIdentifier(voice)]=now+Double(buffer.frameLength)/buffer.format.sampleRate+0.02
        voice.pan=max(-0.65,min(0.65,pan));voice.scheduleBuffer(buffer)
        if !voice.isPlaying {voice.play()}
    }
    func preview(_ channel:AudioChannel) {
        prepare();applyVolumes()
        switch channel {
        case .music:musicPreview=true;startMusic()
        case .weapons:play(.weapon,preview:true)
        case .effects:play(.explosion,preview:true)
        }
    }
    func pause() {
        running=false;musicPreview=false
        music.values.forEach{$0.pause()};voices.values.flatMap{$0}.forEach{$0.stop()};busyUntil.removeAll();engine.pause()
    }
    func resume() {prepare();running=true;musicPreview=false;applyVolumes();startMusic()}
    func endPreview() {if !running {pause()}}
    func stop() {pause();music.values.forEach{$0.currentTime=0};lastPlayed.removeAll()}
    @objc private func interrupted() {pause()}
}
