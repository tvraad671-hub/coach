import Foundation
import Combine

@MainActor
final class MatchDetailsViewModel: ObservableObject {
    @Published private(set) var fixture: FixtureItem?
    @Published private(set) var lineups: [FixtureLineup] = []
    @Published private(set) var statistics: [FixtureTeamStatistics] = []
    @Published private(set) var events: [FixtureEventItem] = []

    @Published var isLoading = false
    @Published var errorMessage: String?

    let matchId: Int

    private let repository: MatchDetailsRepositoryProtocol

    init(matchId: Int, repository: MatchDetailsRepositoryProtocol? = nil) {
        self.matchId = matchId
        self.repository = repository ?? MatchDetailsRepository()
    }

    func fetchDetails() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fixture = try await repository.fetchFixture(matchId: matchId)
            self.fixture = fixture
            self.errorMessage = nil

            async let lineupsTask = softFetch { [self] in
                try await repository.fetchLineups(matchId: matchId)
            }
            async let statisticsTask = softFetch { [self] in
                try await repository.fetchStatistics(matchId: matchId)
            }
            async let eventsTask = softFetch { [self] in
                try await repository.fetchEvents(matchId: matchId)
            }

            let fetchedLineups = await lineupsTask ?? []
            let fetchedStatistics = await statisticsTask ?? []
            let fetchedEvents = await eventsTask ?? []

            self.lineups = sortLineupsByFixtureOrder(fetchedLineups)
            self.statistics = sortStatisticsByFixtureOrder(fetchedStatistics)
            self.events = fetchedEvents.sorted(by: isEarlierEvent)
        } catch {
            self.fixture = nil
            self.lineups = []
            self.statistics = []
            self.events = []
            self.errorMessage = error.localizedDescription
        }
    }

    func retry() {
        Task {
            await fetchDetails()
        }
    }

    private func softFetch<T>(_ operation: @escaping () async throws -> T) async -> T? {
        do {
            return try await operation()
        } catch {
            return nil
        }
    }

    private func sortLineupsByFixtureOrder(_ source: [FixtureLineup]) -> [FixtureLineup] {
        let teamOrder = orderedTeamIDs()
        guard !teamOrder.isEmpty else { return source }
        return source.sorted { lhs, rhs in
            let left = teamOrder.firstIndex(of: lhs.team?.id ?? -1) ?? Int.max
            let right = teamOrder.firstIndex(of: rhs.team?.id ?? -1) ?? Int.max
            return left < right
        }
    }

    private func sortStatisticsByFixtureOrder(_ source: [FixtureTeamStatistics]) -> [FixtureTeamStatistics] {
        let teamOrder = orderedTeamIDs()
        guard !teamOrder.isEmpty else { return source }
        return source.sorted { lhs, rhs in
            let left = teamOrder.firstIndex(of: lhs.team?.id ?? -1) ?? Int.max
            let right = teamOrder.firstIndex(of: rhs.team?.id ?? -1) ?? Int.max
            return left < right
        }
    }

    private func orderedTeamIDs() -> [Int] {
        let awayID = fixture?.teams?.away?.id
        let homeID = fixture?.teams?.home?.id
        return [awayID, homeID].compactMap { $0 }
    }

    private func isEarlierEvent(_ lhs: FixtureEventItem, _ rhs: FixtureEventItem) -> Bool {
        let leftElapsed = lhs.time?.elapsed ?? 0
        let rightElapsed = rhs.time?.elapsed ?? 0
        if leftElapsed != rightElapsed {
            return leftElapsed < rightElapsed
        }

        let leftExtra = lhs.time?.extra ?? 0
        let rightExtra = rhs.time?.extra ?? 0
        return leftExtra < rightExtra
    }
}
