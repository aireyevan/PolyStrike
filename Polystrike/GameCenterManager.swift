import GameKit
import UIKit

@MainActor
final class GameCenterManager {
    static let shared = GameCenterManager()
    static let authenticationChanged = Notification.Name("PolystrikeGameCenterAuthenticationChanged")

    static let leaderboardID = "com.polystrike.highscore"

    enum Scope {
        case global
        case friends

        var gameKitScope: GKLeaderboard.PlayerScope {
            switch self {
            case .global: return .global
            case .friends: return .friendsOnly
            }
        }
    }

    struct Entry: Equatable {
        let rank: Int
        let playerID: String
        let displayName: String
        let score: Int
        let isLocalPlayer: Bool
    }

    struct Snapshot {
        let entries: [Entry]
        let localPlayer: Entry?
        let totalPlayerCount: Int
    }

    private(set) var isAuthenticated = false
    private(set) var lastError: Error?
    private var authenticationHandlerInstalled = false

    private init() {}

    func authenticatePlayer() {
        guard !authenticationHandlerInstalled else { return }
        authenticationHandlerInstalled = true

        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                guard let self else { return }

                if let viewController {
                    self.presentAuthentication(viewController)
                    return
                }

                self.lastError = error
                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                if self.isAuthenticated {
                    print("Game Center authenticated")
                } else {
                    print("Game Center unavailable\(error.map { ": \($0.localizedDescription)" } ?? "")")
                }
                NotificationCenter.default.post(name: Self.authenticationChanged, object: self)
            }
        }
    }

    func submitScore(_ score: Int) {
        guard isAuthenticated, GKLocalPlayer.local.isAuthenticated else {
            print("Game Center unavailable: score not submitted")
            return
        }

        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [Self.leaderboardID]
                )
                print("Score submitted: \(score)")
            } catch {
                lastError = error
                print("Game Center score submission failed: \(error.localizedDescription)")
            }
        }
    }

    func loadLeaderboard(scope: Scope = .global, limit: Int = 25) async throws -> Snapshot {
        guard isAuthenticated, GKLocalPlayer.local.isAuthenticated else {
            throw GameCenterError.notAuthenticated
        }

        let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [Self.leaderboardID])
        guard let leaderboard = leaderboards.first else {
            throw GameCenterError.leaderboardUnavailable
        }

        let (localEntry, entries, totalPlayerCount) = try await leaderboard.loadEntries(
            for: scope.gameKitScope,
            timeScope: .allTime,
            range: NSRange(location: 1, length: max(1, min(100, limit)))
        )
        print("Leaderboard loaded")

        return Snapshot(
            entries: entries.map(makeEntry),
            localPlayer: localEntry.map(makeEntry),
            totalPlayerCount: totalPlayerCount
        )
    }

    func loadLeaderboard(
        scope: Scope = .global,
        limit: Int = 25,
        completion: @escaping (Result<Snapshot, Error>) -> Void
    ) {
        Task {
            do { completion(.success(try await loadLeaderboard(scope: scope, limit: limit))) }
            catch { completion(.failure(error)) }
        }
    }

    func loadLocalPlayerRank() async throws -> Entry? {
        try await loadLeaderboard(scope: .global, limit: 1).localPlayer
    }

    func loadLocalPlayerRank(completion: @escaping (Result<Entry?, Error>) -> Void) {
        Task {
            do { completion(.success(try await loadLocalPlayerRank())) }
            catch { completion(.failure(error)) }
        }
    }

    private func makeEntry(_ entry: GKLeaderboard.Entry) -> Entry {
        Entry(
            rank: entry.rank,
            playerID: entry.player.gamePlayerID,
            displayName: entry.player.displayName,
            score: entry.score,
            isLocalPlayer: entry.player.gamePlayerID == GKLocalPlayer.local.gamePlayerID
        )
    }

    private func presentAuthentication(_ viewController: UIViewController) {
        guard viewController.presentingViewController == nil,
              let presenter = Self.topViewController() else { return }
        presenter.present(viewController, animated: true)
    }

    private static func topViewController() -> UIViewController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController

        func top(from controller: UIViewController?) -> UIViewController? {
            if let presented = controller?.presentedViewController { return top(from: presented) }
            if let navigation = controller as? UINavigationController { return top(from: navigation.visibleViewController) }
            if let tabs = controller as? UITabBarController { return top(from: tabs.selectedViewController) }
            return controller
        }
        return top(from: root)
    }
}

enum GameCenterError: LocalizedError {
    case notAuthenticated
    case leaderboardUnavailable

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Game Center is not authenticated."
        case .leaderboardUnavailable: return "The Polystrike leaderboard is unavailable."
        }
    }
}
