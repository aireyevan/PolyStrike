import GoogleMobileAds
import UIKit

@MainActor
final class RewardedReviveAd: NSObject, FullScreenContentDelegate {
    static let shared = RewardedReviveAd()

#if DEBUG
    // Google requires test inventory during development.
    private let adUnitID = "ca-app-pub-3940256099942544/1712485313"
#else
    private let adUnitID = "ca-app-pub-9166370124762963/6773034669"
#endif

    enum Result {
        case earnedReward
        case dismissed
        case failed(String)
    }

    private var rewardedAd: RewardedAd?
    private var isLoading = false
    private var loadCompletions: [(Bool) -> Void] = []
    private var presentationCompletion: ((Result) -> Void)?
    private var rewardEarned = false

    var isReady: Bool { rewardedAd != nil }

    private override init() {
        super.init()
    }

    func preload() {
        loadIfNeeded()
    }

    func loadIfNeeded(completion: ((Bool) -> Void)? = nil) {
        if let completion { loadCompletions.append(completion) }

        if rewardedAd != nil {
            finishLoad(ready: true)
            return
        }
        guard !isLoading else { return }

        isLoading = true
        Task {
            do {
                let ad = try await RewardedAd.load(with: adUnitID, request: Request())
                ad.fullScreenContentDelegate = self
                rewardedAd = ad
                isLoading = false
                finishLoad(ready: true)
            } catch {
                isLoading = false
                print("Rewarded revive ad failed to load: \(error.localizedDescription)")
                finishLoad(ready: false)
            }
        }
    }

    func present(from viewController: UIViewController, completion: @escaping (Result) -> Void) {
        guard presentationCompletion == nil else { return }
        guard let rewardedAd else {
            completion(.failed("AD NOT READY — TRY AGAIN"))
            loadIfNeeded()
            return
        }

        presentationCompletion = completion
        rewardEarned = false
        rewardedAd.present(from: viewController) { [weak self] in
            self?.rewardEarned = true
        }
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        let result: Result = rewardEarned ? .earnedReward : .dismissed
        rewardedAd = nil
        rewardEarned = false
        let completion = presentationCompletion
        presentationCompletion = nil
        completion?(result)
        loadIfNeeded()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        rewardedAd = nil
        rewardEarned = false
        let completion = presentationCompletion
        presentationCompletion = nil
        completion?(.failed("AD UNAVAILABLE — TRY AGAIN"))
        print("Rewarded revive ad failed to present: \(error.localizedDescription)")
        loadIfNeeded()
    }

    private func finishLoad(ready: Bool) {
        let completions = loadCompletions
        loadCompletions.removeAll()
        completions.forEach { $0(ready) }
    }
}
