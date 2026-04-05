import Foundation
import Combine

@MainActor
final class MatchesViewModel: ObservableObject {
    @Published var liveMatches: [MatchDisplayModel] = []
    @Published var otherMatches: [MatchDisplayModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var isEmpty: Bool {
        !isLoading && errorMessage == nil && liveMatches.isEmpty && otherMatches.isEmpty
    }

    private let repository: MatchesRepositoryProtocol
    private let triggerThrottleSeconds: TimeInterval
    private var lastLoadTriggerAt: Date?
    private var didRunInitialLoad = false

    init(
        repository: MatchesRepositoryProtocol? = nil,
        triggerThrottleSeconds: TimeInterval = 0.6
    ) {
        self.repository = repository ?? MatchesRepository.shared
        self.triggerThrottleSeconds = max(0.2, triggerThrottleSeconds)
    }

    func loadMatches(forceRefresh: Bool = false) async {
        if isLoading {
            MatchesLogger.log("load blocked reason=isLoading")
            return
        }

        let now = Date()
        if !forceRefresh,
           let lastLoadTriggerAt,
           now.timeIntervalSince(lastLoadTriggerAt) < triggerThrottleSeconds {
            MatchesLogger.log("load blocked reason=debounce")
            return
        }

        lastLoadTriggerAt = now
        isLoading = true
        defer { isLoading = false }

        if !forceRefresh && !didRunInitialLoad {
            didRunInitialLoad = true

            if let cached = await repository.loadCachedMatchesForToday() {
                apply(result: cached)
            }

            do {
                if let refreshed = try await repository.refreshMatchesIfNeeded() {
                    apply(result: refreshed)
                }
            } catch {
                handle(error: error)
            }

            return
        }

        do {
            let result = try await repository.loadMatches(forceRefresh: forceRefresh)
            apply(result: result)
        } catch {
            handle(error: error)
        }
    }

    func retry() {
        Task {
            await loadMatches(forceRefresh: true)
        }
    }

    private func apply(result: MatchesRepositoryResult) {
        liveMatches = result.liveMatches
        otherMatches = result.otherMatches

        if liveMatches.isEmpty && otherMatches.isEmpty {
            errorMessage = result.warningMessage
        } else {
            // Keep data visible; show explicit message only when there is no data.
            errorMessage = nil
        }

        MatchesLogger.log(
            "viewModel apply source=\(result.source.rawValue) networkRequests=\(result.networkRequestsCount) live=\(liveMatches.count) other=\(otherMatches.count)"
        )
    }

    private func handle(error: Error) {
        let message: String
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription,
           !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            message = description
        } else {
            message = error.localizedDescription
        }

        if liveMatches.isEmpty && otherMatches.isEmpty {
            errorMessage = "تعذر تحميل مباريات اليوم في البطولات المحددة.\n\(message)"
        } else {
            errorMessage = nil
        }

        MatchesLogger.log("viewModel error=\(message)")
    }
}
