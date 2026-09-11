import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        print("GAME VIEW CONTROLLER LOADED")

        guard let skView = self.view as? SKView else {
            print("ERROR: VIEW IS NOT SKVIEW")
            print("ACTUAL VIEW TYPE:", type(of: self.view))
            return
        }

        skView.isUserInteractionEnabled = true

        // REQUIRED FOR TWIN-STICK CONTROLS
        skView.isMultipleTouchEnabled = true

        skView.ignoresSiblingOrder = true

        let scene = MainMenuScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill

        skView.presentScene(scene)

        print("MAIN MENU LOADED")
        print("SKVIEW SIZE:", skView.bounds.size)
        print("SCENE SIZE:", scene.size)
        print("SCENE PRESENTED:", skView.scene != nil)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
