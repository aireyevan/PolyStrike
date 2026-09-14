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
        let bounds = menuBounds(self)
        let left=bounds.minX,right=bounds.maxX,top=bounds.maxY,bottom=bounds.minY,width=bounds.width
        menuHeader("CAMPAIGN",subtitle:"OPERATIONS ARCHIVE / SELECT YOUR MISSION",on:self,bounds:bounds,color:NeonColors.orange)
        let back = NeonButton(title:"BACK",size:CGSize(width:104,height:36),color:.cyan)
        back.name = "storyBack"; back.position = CGPoint(x:right-52,y:top-16); addChild(back)
        let progress=armorPanel(size:CGSize(width:155,height:32),color:NeonColors.green)
        progress.position=CGPoint(x:right-197,y:top-16);addChild(progress)

        let completed = UserDefaults.standard.bool(forKey:"polystrikeStoryComplete") ? StoryCampaign.missions.count : highestUnlocked
        let progressLabel=createNeonLabel(text:"CAMPAIGN  \(completed) / \(StoryCampaign.missions.count)",fontSize:9,color:.white);progress.addChild(progressLabel)

        let rule=SKShapeNode(rectOf:CGSize(width:width,height:1));rule.position=CGPoint(x:(left+right)/2,y:top-42);rule.fillColor=SKColor.white.withAlphaComponent(0.15);rule.strokeColor = .clear;addChild(rule)
        let tabY=top-67,tabGap:CGFloat=8,tabWidth=(width-tabGap*4)/5
        for sector in 1...5 {
            let first=StoryCampaign.missions.firstIndex{$0.sector==sector} ?? 0, unlocked=first<=highestUnlocked
            let tab=armorPanel(size:CGSize(width:tabWidth,height:34),color:NeonColors.orange,selected:sector==selectedSector);tab.name=unlocked ? "sector_\(sector)":nil;tab.position=CGPoint(x:left+tabWidth/2+CGFloat(sector-1)*(tabWidth+tabGap),y:tabY);tab.fillColor=(sector==selectedSector ? NeonColors.orange.withAlphaComponent(0.17):NeonColors.panel);tab.strokeColor=unlocked ? (sector==selectedSector ? NeonColors.orange:SKColor.white.withAlphaComponent(0.22)):SKColor.white.withAlphaComponent(0.08);addChild(tab)
            let label=createNeonLabel(text:unlocked ? String(format:"SECTOR %02d",sector):String(format:"SECTOR %02d  ◇",sector),fontSize:8,color:unlocked ? .white:NeonColors.mutedText);label.name=tab.name;tab.addChild(label)
        }

        let contentTop=tabY-26,contentHeight=max(110,contentTop-bottom),gap:CGFloat=12,listWidth=min(360,width*0.47),detailWidth=width-listWidth-gap
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
            let row=armorPanel(size:CGSize(width:size.width-18,height:rowHeight),color:NeonColors.orange,selected:selected);row.name=unlocked ? "mission_\(index)":nil;row.position=CGPoint(x:0,y:y);row.fillColor=selected ? NeonColors.cyan.withAlphaComponent(0.13):SKColor.black.withAlphaComponent(0.34);row.strokeColor=selected ? NeonColors.cyan:(unlocked ? SKColor.white.withAlphaComponent(0.18):SKColor.white.withAlphaComponent(0.06));panel.addChild(row)
            addLabel(String(format:"%02d",mission.number),to:row,at:CGPoint(x:-size.width/2+25,y:4),size:11,color:unlocked ? NeonColors.orange:NeonColors.mutedText,alignment:.left,name:row.name)
            addLabel(mission.name,to:row,at:CGPoint(x:-size.width/2+55,y:5),size:9,color:unlocked ? .white:NeonColors.mutedText,alignment:.left,name:row.name)
            addLabel(unlocked ? mission.type.title : "LOCKED",to:row,at:CGPoint(x:-size.width/2+55,y:-10),size:7,color:unlocked ? NeonColors.mutedText:SKColor.white.withAlphaComponent(0.2),alignment:.left,name:row.name)
            if completed { addLabel("COMPLETE",to:row,at:CGPoint(x:size.width/2-16,y:-10),size:6,color:NeonColors.green,alignment:.right,name:row.name) }
            else if unlocked { addLabel("CURRENT",to:row,at:CGPoint(x:size.width/2-16,y:-10),size:6,color:NeonColors.orange,alignment:.right,name:row.name) }
            y -= rowHeight+rowGap
        }
    }

    private func buildDetail(in panel:SKNode,size:CGSize) {
        guard let index=selectedMissionIndex,index<=highestUnlocked else {
            menuText("SELECT A MISSION",on:panel,at:.zero,size:12,color:NeonColors.mutedText,align:.center);return
        }
        let mission=StoryCampaign.missions[index], x = -size.width/2+18, top=size.height/2
        menuText(String(format:"SECTOR %02d / OPERATION %02d",mission.sector,mission.number),on:panel,at:CGPoint(x:x,y:top-20),size:8,color:NeonColors.orange,width:size.width-36)
        menuText(mission.name,on:panel,at:CGPoint(x:x,y:top-46),size:18,width:size.width-36)
        menuText(mission.type.title,on:panel,at:CGPoint(x:x,y:top-67),size:9,color:.cyan,width:size.width-36)
        let description = menuText(mission.description,on:panel,at:CGPoint(x:x,y:top-94),size:10,color:NeonColors.mutedText)
        description.numberOfLines = 2; description.preferredMaxLayoutWidth = size.width-36
        description.verticalAlignmentMode = .top
        let metadata=mission.duration>0 ? "TIME LIMIT  \(Int(mission.duration)) SEC" : (mission.enemyCount>0 ? "ENEMIES  \(mission.enemyCount)":"TACTICAL OBJECTIVE")
        menuText(metadata,on:panel,at:CGPoint(x:x,y:-size.height/2+65),size:8,color:NeonColors.green,width:size.width-36)
        let launch=NeonButton(title:index<highestUnlocked ? "REPLAY MISSION":"DEPLOY",size:CGSize(width:size.width-36,height:38),color:NeonColors.orange)
        launch.name="launchMission";launch.position=CGPoint(x:0,y:-size.height/2+29);panel.addChild(launch)
    }

    private func panel(size:CGSize,color:SKColor)->SKShapeNode { armorPanel(size:size,color:color) }
    private func addLabel(_ text:String,at point:CGPoint,size:CGFloat,color:SKColor,alignment:SKLabelHorizontalAlignmentMode = .center){addLabel(text,to:self,at:point,size:size,color:color,alignment:alignment)}
    private func addLabel(_ text:String,to parent:SKNode,at point:CGPoint,size:CGFloat,color:SKColor,alignment:SKLabelHorizontalAlignmentMode = .center,name:String?=nil){let l=createNeonLabel(text:text,fontSize:size,color:color);l.position=point;l.horizontalAlignmentMode=alignment;l.name=name;parent.addChild(l)}

    override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?){guard let p=touches.first?.location(in:self) else{return};let names=menuActionNames(at:p,in:self)
        if names.contains("storyBack"){let menu=MainMenuScene(size:size);menu.scaleMode = .resizeFill;view?.presentScene(menu,transition:.fade(withDuration:0.22));return}
        if names.contains("launchMission"),let index=selectedMissionIndex,index<=highestUnlocked{let game=GameScene(size:size,storyModeManager:StoryModeManager(missionIndex:index));game.scaleMode = .resizeFill;view?.presentScene(game,transition:.fade(withDuration:0.28));return}
        for name in names {if name.hasPrefix("sector_"),let sector=Int(name.dropFirst(7)){selectedSector=sector;selectedMissionIndex=StoryCampaign.missions.enumerated().first(where:{$0.element.sector==sector && $0.offset<=highestUnlocked})?.offset;rebuild();return};if name.hasPrefix("mission_"),let index=Int(name.dropFirst(8)),index<=highestUnlocked{selectedMissionIndex=index;rebuild();return}}
    }
}
