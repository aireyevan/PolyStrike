import SpriteKit
enum BossType:String,CaseIterable { case hive,pursuer,sentinel,architect,core
    var name:String { switch self {case .hive:return "THE HIVE";case .pursuer:return "THE PURSUER";case .sentinel:return "THE SENTINEL";case .architect:return "THE ARCHITECT";case .core:return "THE CORE"} }
    var color:SKColor { switch self {case .hive:return .magenta;case .pursuer:return .orange;case .sentinel:return .cyan;case .architect:return SKColor(red:0.65,green:0.2,blue:1,alpha:1);case .core:return SKColor(red:1,green:0.12,blue:0.45,alpha:1)} }
}
