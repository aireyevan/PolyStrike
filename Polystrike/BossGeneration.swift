import Foundation
enum BossGeneration:Int,CaseIterable { case one=1,two,three,four,five
    static func infinite(tier:Int)->BossGeneration { BossGeneration(rawValue:min(5,max(1,(tier-10)/20+1))) ?? .one }
    var healthScale:CGFloat { 1+CGFloat(rawValue-1)*0.42 };var cadenceScale:Double { max(0.58,1-Double(rawValue-1)*0.09) };var projectileScale:CGFloat { 1+CGFloat(rawValue-1)*0.10 }
}
