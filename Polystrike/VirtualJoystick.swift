import SpriteKit

class VirtualJoystick: SKNode {
    
    var visibility = GameSettings.shared.joystickVisibility

    private let base: SKShapeNode
    private let knob: SKShapeNode
    
    private let radius: CGFloat = 60
    private let knobRadius: CGFloat = 28
    
    private(set) var isActive = false
    
    private(set) var direction = CGVector(
        dx: 0,
        dy: 0
    )
    
    private let deadZone: CGFloat = 0.15
    
    override init() {
        
        base = SKShapeNode(
            circleOfRadius: radius
        )
        
        knob = SKShapeNode(
            circleOfRadius: knobRadius
        )
        
        super.init()
        
        // Base
        
        base.fillColor = SKColor(
            white: 0.06,
            alpha: 0.35
        )
        
        base.strokeColor = SKColor(
            white: 0.7,
            alpha: 0.8
        )
        
        base.lineWidth = 2
        
        base.zPosition = 100
        
        // Knob
        
        knob.fillColor = SKColor(
            white: 0.8,
            alpha: 0.8
        )
        
        knob.strokeColor = .white
        
        knob.lineWidth = 2
        
        knob.glowWidth = 2
        
        knob.zPosition = 101
        
        addChild(base)
        addChild(knob)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(
            "init(coder:) has not been implemented"
        )
    }
    
    // MARK: - Begin
    
    func begin(at touchPosition: CGPoint) {
        
        self.position = touchPosition
        
        isActive = true
        
        direction = CGVector(
            dx: 0,
            dy: 0
        )
        
        knob.position = .zero
        
        refreshVisibility()
    }
    
    // MARK: - Update
    
    func update(at touchPosition: CGPoint) {
        
        let dx =
            touchPosition.x -
            self.position.x
        
        let dy =
            touchPosition.y -
            self.position.y
        
        let distance = sqrt(
            dx * dx +
            dy * dy
        )
        
        // Finger hasn't moved
        
        if distance == 0 {
            
            direction = CGVector(
                dx: 0,
                dy: 0
            )
            
            knob.position = .zero
            
            return
        }
        
        // Don't let knob move outside the base
        
        let clampedDistance = min(
            distance,
            radius
        )
        
        let angle = atan2(
            dy,
            dx
        )
        
        knob.position = CGPoint(
            x: cos(angle) * clampedDistance,
            y: sin(angle) * clampedDistance
        )
        
        // Convert to -1...1
        
        let normalizedX =
            cos(angle) *
            clampedDistance /
            radius
        
        let normalizedY =
            sin(angle) *
            clampedDistance /
            radius
        
        let magnitude = sqrt(
            normalizedX * normalizedX +
            normalizedY * normalizedY
        )
        
        // Dead zone
        
        if magnitude < deadZone {
            
            direction = CGVector(
                dx: 0,
                dy: 0
            )
            
            return
        }
        
        direction = CGVector(
            dx: normalizedX,
            dy: normalizedY
        )
    }
    
    // MARK: - End
    
    func end() {
        
        isActive = false
        
        direction = CGVector(
            dx: 0,
            dy: 0
        )
        
        knob.position = .zero
        refreshVisibility()
    }
}


extension VirtualJoystick {
    func refreshVisibility() {
        removeAction(forKey: "visibility")
        switch visibility {
        case .always:
            alpha = 1
        case .fade:
            alpha = isActive ? 1 : 0
            if isActive {
                run(.sequence([.wait(forDuration: 0.7), .fadeOut(withDuration: 0.6)]), withKey: "visibility")
            }
        case .hidden:
            alpha = 0
        }
    }
}

enum JoystickVisibility: String, CaseIterable {
    case always, fade, hidden
    var title: String {
        switch self {
        case .always: return "ALWAYS VISIBLE"
        case .fade: return "FADE AFTER TOUCH"
        case .hidden: return "INVISIBLE"
        }
    }
    var detail: String {
        switch self {
        case .always: return "Both controls stay visible throughout the run."
        case .fade: return "Appear when touched, then fade while you play."
        case .hidden: return "Move and aim normally, with no controls drawn."
        }
    }
}

final class GameSettings {
    static let shared = GameSettings()
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    var joystickVisibility: JoystickVisibility {
        get { JoystickVisibility(rawValue: defaults.string(forKey: "joystickVisibility") ?? "") ?? .fade }
        set { defaults.set(newValue.rawValue, forKey: "joystickVisibility") }
    }
    var hapticsEnabled: Bool {
        get { defaults.object(forKey: "hapticsEnabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "hapticsEnabled") }
    }
}
