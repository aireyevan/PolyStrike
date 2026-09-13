import SpriteKit
import UIKit

final class StoryMissionSelectScene: SKScene {
    private var selectedSector = 1
    private var selectedMissionIndex: Int?

    private var highestUnlocked: Int {
        if UserDefaults.standard.bool(forKey: "polystrikeStoryComplete") { return StoryCampaign.missions.count - 1 }
        return min(StoryCampaign.missions.count - 1, UserDefaults.standard.integer(forKey: "polystrikeStoryMission"))
    }

    override func didMove(to view: SKView) {
        selectedSector = StoryCampaign.missions[highestUnlocked].sector
        selectedMissionIndex = highestUnlocked
        rebuild()
        DispatchQueue.main.async { [weak self] in self?.rebuild() }
    }

    override func didChangeSize(_ oldSize: CGSize) { if view != nil { rebuild() } }

    private func rebuild() {
        removeAllChildren(); createNeonBackground(for: self, gridSpacing: 52); addInterfaceAtmosphere(to: self)
        var safe = view?.safeAreaInsets ?? .zero
        if UIDevice.current.userInterfaceIdiom == .phone && safe.left < 1 && safe.right < 1 { safe.left=59;safe.right=59;safe.bottom=max(21,safe.bottom) }
        let left=safe.left+18,right=size.width-safe.right-18,top=size.height-safe.top-17,bottom=safe.bottom+14,width=max(600,right-left)

        addLabel("STORY ARCHIVE", at:CGPoint(x:left,y:top), size:20,color:NeonColors.orange,alignment:.left)
        addLabel("SELECT AN OPERATION",at:CGPoint(x:left,y:top-24),size:7,color:NeonColors.mutedText,alignment:.left)
        let progress=SKShapeNode(rectOf:CGSize(width:190,height:32),cornerRadius:2);progress.position=CGPoint(x:right-95,y:top-8);progress.fillColor=NeonColors.panel;progress.strokeColor=NeonColors.green.withAlphaComponent(0.65);addChild(progress)
        let completed = UserDefaults.standard.bool(forKey:"polystrikeStoryComplete") ? StoryCampaign.missions.count : highestUnlocked
        let progressLabel=createNeonLabel(text:"CAMPAIGN  \(completed) / \(StoryCampaign.missions.count)",fontSize:9,color:.white);progress.addChild(progressLabel)

        let rule=SKShapeNode(rectOf:CGSize(width:width,height:1));rule.position=CGPoint(x:(left+right)/2,y:top-42);rule.fillColor=SKColor.white.withAlphaComponent(0.15);rule.strokeColor = .clear;addChild(rule)
        let tabY=top-67,tabGap:CGFloat=8,tabWidth=(width-tabGap*4)/5
        for sector in 1...5 {
            let first=StoryCampaign.missions.firstIndex{$0.sector==sector} ?? 0, unlocked=first<=highestUnlocked
            let tab=SKShapeNode(rectOf:CGSize(width:tabWidth,height:34),cornerRadius:2);tab.name=unlocked ? "sector_\(sector)":nil;tab.position=CGPoint(x:left+tabWidth/2+CGFloat(sector-1)*(tabWidth+tabGap),y:tabY);tab.fillColor=(sector==selectedSector ? NeonColors.orange.withAlphaComponent(0.17):NeonColors.panel);tab.strokeColor=unlocked ? (sector==selectedSector ? NeonColors.orange:SKColor.white.withAlphaComponent(0.22)):SKColor.white.withAlphaComponent(0.08);addChild(tab)
            let label=createNeonLabel(text:unlocked ? String(format:"SECTOR %02d",sector):String(format:"SECTOR %02d  ◇",sector),fontSize:8,color:unlocked ? .white:NeonColors.mutedText);label.name=tab.name;tab.addChild(label)
        }

        let contentTop=tabY-26,contentHeight=max(205,contentTop-bottom),gap:CGFloat=12,listWidth=min(360,width*0.47),detailWidth=width-listWidth-gap
        let listPanel=panel(size:CGSize(width:listWidth,height:contentHeight),color:NeonColors.orange);listPanel.position=CGPoint(x:left+listWidth/2,y:bottom+contentHeight/2);addChild(listPanel)
        let detail=panel(size:CGSize(width:detailWidth,height:contentHeight),color:NeonColors.cyan);detail.position=CGPoint(x:left+listWidth+gap+detailWidth/2,y:bottom+contentHeight/2);addChild(detail)
        buildMissionList(in:listPanel,size:CGSize(width:listWidth,height:contentHeight))
        buildDetail(in:detail,size:CGSize(width:detailWidth,height:contentHeight))
    }

    private func buildMissionList(in panel:SKNode,size:CGSize) {
        let missions=StoryCampaign.missions.enumerated().filter{$0.element.sector==selectedSector},rowGap:CGFloat=6,rowHeight=min(47,(size.height-26-CGFloat(max(0,missions.count-1))*rowGap)/CGFloat(missions.count))
        var y=size.height/2-13-rowHeight/2
        for (index,mission) in missions {
            let unlocked=index<=highestUnlocked,completed=index<highestUnlocked || UserDefaults.standard.bool(forKey:"polystrikeStoryComplete"),selected=index==selectedMissionIndex
            let row=SKShapeNode(rectOf:CGSize(width:size.width-18,height:rowHeight),cornerRadius:2);row.name=unlocked ? "mission_\(index)":nil;row.position=CGPoint(x:0,y:y);row.fillColor=selected ? NeonColors.cyan.withAlphaComponent(0.13):SKColor.black.withAlphaComponent(0.34);row.strokeColor=selected ? NeonColors.cyan:(unlocked ? SKColor.white.withAlphaComponent(0.18):SKColor.white.withAlphaComponent(0.06));panel.addChild(row)
            addLabel(String(format:"%02d",mission.number),to:row,at:CGPoint(x:-size.width/2+25,y:4),size:11,color:unlocked ? NeonColors.orange:NeonColors.mutedText,alignment:.left,name:row.name)
            addLabel(mission.name,to:row,at:CGPoint(x:-size.width/2+55,y:5),size:9,color:unlocked ? .white:NeonColors.mutedText,alignment:.left,name:row.name)
            addLabel(unlocked ? mission.type.title : "LOCKED",to:row,at:CGPoint(x:-size.width/2+55,y:-10),size:6,color:unlocked ? NeonColors.mutedText:SKColor.white.withAlphaComponent(0.2),alignment:.left,name:row.name)
            if completed { addLabel("COMPLETE",to:row,at:CGPoint(x:size.width/2-16,y:-2),size:6,color:NeonColors.green,alignment:.right,name:row.name) }
            else if unlocked { addLabel("CURRENT",to:row,at:CGPoint(x:size.width/2-16,y:-2),size:6,color:NeonColors.orange,alignment:.right,name:row.name) }
            y -= rowHeight+rowGap
        }
    }

    private func buildDetail(in panel:SKNode,size:CGSize) {
        guard let index=selectedMissionIndex,index<=highestUnlocked else { addLabel("SELECT AN UNLOCKED MISSION",to:panel,at:.zero,size:10,color:NeonColors.mutedText);return }
        let mission=StoryCampaign.missions[index],x = -size.width/2+22
        addLabel(String(format:"SECTOR %02d  /  MISSION %02d",mission.sector,mission.number),to:panel,at:CGPoint(x:x,y:size.height/2-32),size:7,color:NeonColors.orange,alignment:.left)
        addLabel(mission.name,to:panel,at:CGPoint(x:x,y:size.height/2-58),size:18,color:.white,alignment:.left)
        addLabel(mission.type.title,to:panel,at:CGPoint(x:x,y:size.height/2-80),size:8,color:NeonColors.cyan,alignment:.left)
        addLabel(mission.description,to:panel,at:CGPoint(x:x,y:size.height/2-111),size:9,color:NeonColors.mutedText,alignment:.left)
        let metadata=mission.duration>0 ? "TIME  \(Int(mission.duration)) SEC" : (mission.enemyCount>0 ? "ENEMIES  \(mission.enemyCount)":"TACTICAL OBJECTIVE")
        addLabel(metadata,to:panel,at:CGPoint(x:x,y:size.height/2-140),size:7,color:NeonColors.green,alignment:.left)
        let launch=SKShapeNode(rectOf:CGSize(width:min(245,size.width-44),height:42),cornerRadius:2);launch.name="launchMission";launch.position=CGPoint(x:0,y:-size.height/2+34);launch.fillColor=NeonColors.orange.withAlphaComponent(0.15);launch.strokeColor=NeonColors.orange;launch.glowWidth=3;panel.addChild(launch)
        let label=createNeonLabel(text:index<highestUnlocked ? "REPLAY MISSION":"DEPLOY",fontSize:10,color:.white);label.name="launchMission";launch.addChild(label)
        let back=createNeonLabel(text:"‹  BACK",fontSize:8,color:NeonColors.mutedText);back.name="storyBack";back.position=CGPoint(x:size.width/2-22,y:-size.height/2+10);back.horizontalAlignmentMode = .right;panel.addChild(back)
    }

    private func panel(size:CGSize,color:SKColor)->SKShapeNode { let p=SKShapeNode(rectOf:size,cornerRadius:2);p.fillColor=NeonColors.panel.withAlphaComponent(0.82);p.strokeColor=color.withAlphaComponent(0.42);p.lineWidth=1;return p }
    private func addLabel(_ text:String,at point:CGPoint,size:CGFloat,color:SKColor,alignment:SKLabelHorizontalAlignmentMode = .center){addLabel(text,to:self,at:point,size:size,color:color,alignment:alignment)}
    private func addLabel(_ text:String,to parent:SKNode,at point:CGPoint,size:CGFloat,color:SKColor,alignment:SKLabelHorizontalAlignmentMode = .center,name:String?=nil){let l=createNeonLabel(text:text,fontSize:size,color:color);l.position=point;l.horizontalAlignmentMode=alignment;l.name=name;parent.addChild(l)}

    override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?){guard let p=touches.first?.location(in:self) else{return};let names=nodes(at:p).flatMap{[$0.name,$0.parent?.name]}.compactMap{$0}
        if names.contains("storyBack"){let menu=MainMenuScene(size:size);menu.scaleMode = .resizeFill;view?.presentScene(menu,transition:.fade(withDuration:0.22));return}
        if names.contains("launchMission"),let index=selectedMissionIndex,index<=highestUnlocked{let game=GameScene(size:size,storyModeManager:StoryModeManager(missionIndex:index));game.scaleMode = .resizeFill;view?.presentScene(game,transition:.fade(withDuration:0.28));return}
        for name in names {if name.hasPrefix("sector_"),let sector=Int(name.dropFirst(7)){selectedSector=sector;selectedMissionIndex=StoryCampaign.missions.enumerated().first(where:{$0.element.sector==sector && $0.offset<=highestUnlocked})?.offset;rebuild();return};if name.hasPrefix("mission_"),let index=Int(name.dropFirst(8)),index<=highestUnlocked{selectedMissionIndex=index;rebuild();return}}
    }
}
