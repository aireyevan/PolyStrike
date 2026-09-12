import Foundation

enum MissionType: String, Codable, CaseIterable {
    case elimination, survival, defense, capture, eliteHunt, escape, assault, boss
    var title: String { self == .eliteHunt ? "ELITE HUNT" : rawValue.uppercased() }
}

enum StoryArenaLayout: String, Codable {
    case openGrid, crossfire, reactorRing, controlTriangle, pursuitLanes, fortress, bossHex, finalCore
}
