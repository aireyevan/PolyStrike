import Foundation
import CoreGraphics

enum MissionPhase { case briefing, active, complete, failed }

struct MissionStatus {
    let title: String
    let value: String
    let progress: CGFloat
}
