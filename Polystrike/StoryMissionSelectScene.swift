import SpriteKit
import UIKit

final class StoryMissionSelectScene: SKScene {
    private var selectedSector = 1
    private var selectedMissionIndex: Int?
    private var missionPage = 0

    private var highestUnlocked: Int {
        StoryCampaign.migrateProgress()
        if UserDefaults.standard.bool(forKey: "polystrikeStoryComplete") { return StoryCampaign.missions.count - 1 }
        return max(0,min(StoryCampaign.missions.count - 1, UserDefaults.standard.integer(forKey: "polystrikeStoryMission")))
    }

    override func didMove(to view: SKView) {
        selectedSector = StoryCampaign.missions[highestUnlocked].sector
        selectedMissionIndex = highestUnlocked
        missionPage = (StoryCampaign.missions[highestUnlocked].number-1)/4
        rebuild()
        DispatchQueue.main.async { [weak self] in self?.rebuild() }
    }

    override func didChangeSize(_ oldSize: CGSize) { if view != nil { rebuild() } }

    private func rebuild() {
        removeAllChildren(); createNeonBackground(for: self, gridSpacing: 52); addInterfaceAtmosphere(to: self)
        let bounds = menuBounds(self)
        let left=bounds.minX,right=bounds.maxX,top=bounds.maxY,bottom=bounds.minY,width=bounds.width
        menuHeader("CAMPAIGN",subtitle:"FIVE FRONTS / 120 LINKED STAGES / CHECKPOINTS",on:self,bounds:bounds,color:NeonColors.orange)
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
            let tab=armorPanel(size:CGSize(width:tabWidth,height:34),color:NeonColors.orange,selected:sector==selectedSector);tab.name="sector_\(sector)";tab.position=CGPoint(x:left+tabWidth/2+CGFloat(sector-1)*(tabWidth+tabGap),y:tabY);tab.fillColor=(sector==selectedSector ? NeonColors.orange.withAlphaComponent(0.17):NeonColors.panel);tab.strokeColor=unlocked ? (sector==selectedSector ? NeonColors.orange:SKColor.white.withAlphaComponent(0.22)):SKColor.white.withAlphaComponent(0.08);addChild(tab)
            let label=createNeonLabel(text:unlocked ? String(format:"SECTOR %02d",sector):String(format:"SECTOR %02d  ◇",sector),fontSize:8,color:unlocked ? .white:NeonColors.mutedText);label.name=tab.name;tab.addChild(label)
        }

        let contentTop=tabY-26,contentHeight=max(110,contentTop-bottom),gap:CGFloat=12,listWidth=min(360,width*0.47),detailWidth=width-listWidth-gap
        let listPanel=panel(size:CGSize(width:listWidth,height:contentHeight),color:NeonColors.orange);listPanel.position=CGPoint(x:left+listWidth/2,y:bottom+contentHeight/2);addChild(listPanel)
        let detail=panel(size:CGSize(width:detailWidth,height:contentHeight),color:NeonColors.cyan);detail.position=CGPoint(x:left+listWidth+gap+detailWidth/2,y:bottom+contentHeight/2);addChild(detail)
        buildMissionList(in:listPanel,size:CGSize(width:listWidth,height:contentHeight))
        buildDetail(in:detail,size:CGSize(width:detailWidth,height:contentHeight))
    }

    private func buildMissionList(in panel:SKNode,size:CGSize) {
        let all=StoryCampaign.missions.enumerated().filter{$0.element.sector==selectedSector}
        let missions=Array(all.dropFirst(missionPage*4).prefix(4))
        let rowGap:CGFloat=5,rowHeight=min(43,(size.height-57-15)/4)
        menuText(StoryCampaign.sectorNames[selectedSector-1],on:panel,at:CGPoint(x:0,y:size.height/2-15),size:9,color:NeonColors.orange,align:.center,width:size.width-24)
        var y=size.height/2-29-rowHeight/2
        for (index,mission) in missions {
            let unlocked=index<=highestUnlocked,selected=index==selectedMissionIndex
            let row=armorPanel(size:CGSize(width:size.width-18,height:rowHeight),color:NeonColors.orange,selected:selected)
            row.name="mission_\(index)";row.position=CGPoint(x:0,y:y);row.fillColor=selected ? NeonColors.cyan.withAlphaComponent(0.13):SKColor.black.withAlphaComponent(0.34);row.strokeColor=selected ? .cyan:SKColor.white.withAlphaComponent(unlocked ? 0.18:0.06);panel.addChild(row)
            addLabel(String(format:"%02d",mission.number),to:row,at:CGPoint(x:-size.width/2+23,y:3),size:11,color:unlocked ? NeonColors.orange:NeonColors.mutedText,alignment:.left,name:row.name)
            let title=menuText(mission.name,on:row,at:CGPoint(x:-size.width/2+51,y:5),size:9,color:unlocked ? .white:NeonColors.mutedText,width:size.width-74);title.name=row.name
            addLabel(unlocked ? "3 STAGES  /  \(mission.number==8 ? "GUARDIAN" : mission.number==4 ? "COMMANDER":"OPERATION")":"LOCKED",to:row,at:CGPoint(x:-size.width/2+51,y:-9),size:6,color:NeonColors.mutedText,alignment:.left,name:row.name)
            let stars=UserDefaults.standard.integer(forKey:"storyMedal.\(mission.id)")
            if stars>0 {addLabel(String(repeating:"★",count:stars),to:row,at:CGPoint(x:size.width/2-19,y:-9),size:8,color:NeonColors.yellow,alignment:.right,name:row.name)}
            y -= rowHeight+rowGap
        }
        for page in 0...1 {let button=NeonButton(title:page==0 ? "01–04":"05–08",size:CGSize(width:82,height:24),color:page==missionPage ? .cyan:NeonColors.purple);button.name="missionPage_\(page)";button.position=CGPoint(x:page==0 ? -46:46,y:-size.height/2+17);panel.addChild(button)}
    }

    private func buildDetail(in panel:SKNode,size:CGSize) {
        guard let index=selectedMissionIndex else{return}
        let mission=StoryCampaign.missions[index],x = -size.width/2+16,top=size.height/2,bottom = -size.height/2
        menuText("OPERATION \(index+1) / 40  •  THREAT \(mission.sector)",on:panel,at:CGPoint(x:x,y:top-18),size:8,color:NeonColors.orange,width:size.width-32)
        menuText(mission.name,on:panel,at:CGPoint(x:x,y:top-43),size:18,width:size.width-32)
        let description=menuText(mission.description,on:panel,at:CGPoint(x:x,y:top-63),size:9,color:NeonColors.mutedText)
        description.numberOfLines=2;description.preferredMaxLayoutWidth=size.width-32;description.verticalAlignmentMode = .top
        if size.height>250 {
            let objective=mission.stages.first{[MissionType.capture,.defense,.assault].contains($0.type)}?.type
            let model=StoryObjectiveNode(kind:objective == .defense ? .reactor : objective == .assault ? .installation:.relay)
            model.children.compactMap{$0 as? SKLabelNode}.forEach{$0.isHidden=true}
            model.setScale(0.35);model.position=CGPoint(x:0,y:top-113);panel.addChild(model)
        }
        let routeWidth=(size.width-40)/3
        for (i,stage) in mission.stages.enumerated() {
            let card=armorPanel(size:CGSize(width:routeWidth-4,height:44),color:stage.bossType != nil ? NeonColors.pink:.cyan)
            card.position=CGPoint(x:-size.width/2+20+routeWidth*(CGFloat(i)+0.5),y:bottom+104);panel.addChild(card)
            menuText("0\(i+1)",on:card,at:CGPoint(x:0,y:8),size:10,color:.cyan,align:.center)
            menuText(stage.type.title,on:card,at:CGPoint(x:0,y:-10),size:7,align:.center,width:routeWidth-12)
        }
        let best=UserDefaults.standard.double(forKey:"storyBest.\(mission.id)")
        menuText("+\(mission.reward) FLUX  •  PAR \(Int(mission.parTime)) SEC",on:panel,at:CGPoint(x:x,y:bottom+68),size:8,color:NeonColors.green,width:size.width-32)
        menuText(best>0 ? "PERSONAL BEST  \(Int(best)) SEC":"CHECKPOINT AFTER EVERY STAGE",on:panel,at:CGPoint(x:x,y:bottom+52),size:7,color:NeonColors.mutedText,width:size.width-32)
        let unlocked=index<=highestUnlocked
        let launch=NeonButton(title:unlocked ? (index<highestUnlocked ? "REPLAY OPERATION":"DEPLOY / RESUME") : "COMPLETE PREVIOUS OPERATION",size:CGSize(width:size.width-32,height:34),color:unlocked ? NeonColors.orange:NeonColors.mutedText)
        launch.name=unlocked ? "launchMission":nil;launch.position=CGPoint(x:0,y:bottom+25);panel.addChild(launch)
    }

    private func panel(size:CGSize,color:SKColor)->SKShapeNode { armorPanel(size:size,color:color) }
    private func addLabel(_ text:String,at point:CGPoint,size:CGFloat,color:SKColor,alignment:SKLabelHorizontalAlignmentMode = .center){addLabel(text,to:self,at:point,size:size,color:color,alignment:alignment)}
    private func addLabel(_ text:String,to parent:SKNode,at point:CGPoint,size:CGFloat,color:SKColor,alignment:SKLabelHorizontalAlignmentMode = .center,name:String?=nil){let l=createNeonLabel(text:text,fontSize:size,color:color);l.position=point;l.horizontalAlignmentMode=alignment;l.name=name;parent.addChild(l)}

    override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?){guard let p=touches.first?.location(in:self) else{return};let names=menuActionNames(at:p,in:self)
        if names.contains("storyBack"){let menu=MainMenuScene(size:size);menu.scaleMode = .resizeFill;view?.presentScene(menu,transition:.fade(withDuration:0.22));return}
        if names.contains("launchMission"),let index=selectedMissionIndex,index<=highestUnlocked{let game=GameScene(size:size,storyModeManager:StoryModeManager(missionIndex:index));game.scaleMode = .resizeFill;view?.presentScene(game,transition:.fade(withDuration:0.28));return}
        for name in names {if name.hasPrefix("missionPage_"),let page=Int(name.dropFirst(12)){missionPage=max(0,min(1,page));selectedMissionIndex=StoryCampaign.missions.firstIndex{$0.sector==selectedSector && $0.number==missionPage*4+1};rebuild();return};if name.hasPrefix("sector_"),let sector=Int(name.dropFirst(7)){selectedSector=sector;missionPage=0;selectedMissionIndex=StoryCampaign.missions.firstIndex{$0.sector==sector};rebuild();return};if name.hasPrefix("mission_"),let index=Int(name.dropFirst(8)){selectedMissionIndex=index;rebuild();return}}
    }
}
