import Foundation
import Combine

@MainActor
final class TodayMatchesViewModel: ObservableObject {
    @Published var liveMatches: [MatchDisplayModel] = []
    @Published var upcomingOrFinishedMatches: [MatchDisplayModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var todayMatches: [MatchDisplayModel] {
        upcomingOrFinishedMatches
    }

    var isEmpty: Bool {
        !isLoading && errorMessage == nil && liveMatches.isEmpty && upcomingOrFinishedMatches.isEmpty
    }

    private let repository: TodayMatchesRepositoryProtocol
    private var autoRefreshTask: Task<Void, Never>?
    private var todaySnapshot: [MatchDisplayModel] = []

    init(repository: TodayMatchesRepositoryProtocol? = nil) {
        self.repository = repository ?? TodayMatchesRepository()
    }

    deinit {
        autoRefreshTask?.cancel()
    }

    func fetchMatches() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let todayCandidates = try await repository.fetchMatchesForToday()
            let liveCandidates = todayCandidates.filter(\.isLive)

            applySnapshot(liveCandidates: liveCandidates, todayCandidates: todayCandidates)
            errorMessage = nil
        } catch {
            let message = error.localizedDescription
            if message.localizedCaseInsensitiveContains("الحد اليومي") {
                stopAutoRefresh()
            }

            if liveMatches.isEmpty && upcomingOrFinishedMatches.isEmpty {
                errorMessage = "تعذر تحميل مباريات اليوم في البطولات المحددة.\n\(message)"
            } else {
                errorMessage = message
            }
        }
    }

    func refreshLiveOnly() async {
        await fetchMatches()
    }

    func startAutoRefresh() {
        stopAutoRefresh()

        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 300_000_000_000)
                guard !Task.isCancelled else { break }
                await self?.refreshLiveOnly()
            }
        }
    }

    func stopAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
    }

    func retry() {
        Task {
            await fetchMatches()
        }
    }

    private func applySnapshot(liveCandidates: [MatchDisplayModel], todayCandidates: [MatchDisplayModel]) {
        let filteredLiveCandidates = liveCandidates.filter { TodayMatchesLeagueConfig.contains(leagueID: $0.leagueID) }
        let filteredTodayCandidates = todayCandidates.filter { TodayMatchesLeagueConfig.contains(leagueID: $0.leagueID) }

        todaySnapshot = sortToday(uniqueMatches(filteredTodayCandidates))

        let mergedLive = mergeLive(liveCandidates: filteredLiveCandidates, todayCandidates: todaySnapshot)
        let nextLive = sortLive(uniqueMatches(mergedLive.filter(\.isLive)))
        let liveIDs = Set(nextLive.map(\.id))
        let nextToday = sortToday(todaySnapshot.filter { !liveIDs.contains($0.id) })

        updateCollections(live: nextLive, today: nextToday)
    }

    private func updateCollections(live: [MatchDisplayModel], today: [MatchDisplayModel]) {
        if liveMatches != live {
            liveMatches = live
        }
        if upcomingOrFinishedMatches != today {
            upcomingOrFinishedMatches = today
        }
    }

    private func mergeLive(liveCandidates: [MatchDisplayModel], todayCandidates: [MatchDisplayModel]) -> [MatchDisplayModel] {
        let extraLiveFromToday = todayCandidates.filter(\.isLive)
        return liveCandidates + extraLiveFromToday
    }

    private func uniqueMatches(_ source: [MatchDisplayModel]) -> [MatchDisplayModel] {
        var ordered: [MatchDisplayModel] = []
        var seen = Set<Int>()

        for item in source {
            if seen.insert(item.id).inserted {
                ordered.append(item)
            }
        }

        return ordered
    }

    private func sortLive(_ source: [MatchDisplayModel]) -> [MatchDisplayModel] {
        source.sorted { lhs, rhs in
            if lhs.kickoffTimestamp != rhs.kickoffTimestamp {
                return lhs.kickoffTimestamp < rhs.kickoffTimestamp
            }

            let leftMinute = minuteValue(from: lhs.minuteText)
            let rightMinute = minuteValue(from: rhs.minuteText)

            if leftMinute != rightMinute {
                return leftMinute > rightMinute
            }

            let leftPriority = TodayMatchesLeagueConfig.priority(for: lhs.leagueID)
            let rightPriority = TodayMatchesLeagueConfig.priority(for: rhs.leagueID)
            if leftPriority != rightPriority {
                return leftPriority < rightPriority
            }

            return lhs.id < rhs.id
        }
    }

    private func sortToday(_ source: [MatchDisplayModel]) -> [MatchDisplayModel] {
        source.sorted { lhs, rhs in
            let leftBucket = statusBucket(for: lhs)
            let rightBucket = statusBucket(for: rhs)

            if leftBucket != rightBucket {
                return leftBucket < rightBucket
            }

            if leftBucket == 2 {
                if lhs.kickoffTimestamp != rhs.kickoffTimestamp {
                    return lhs.kickoffTimestamp > rhs.kickoffTimestamp
                }

                let leftPriority = TodayMatchesLeagueConfig.priority(for: lhs.leagueID)
                let rightPriority = TodayMatchesLeagueConfig.priority(for: rhs.leagueID)
                if leftPriority != rightPriority {
                    return leftPriority < rightPriority
                }

                return lhs.id < rhs.id
            }

            if lhs.kickoffTimestamp != rhs.kickoffTimestamp {
                return lhs.kickoffTimestamp < rhs.kickoffTimestamp
            }

            let leftPriority = TodayMatchesLeagueConfig.priority(for: lhs.leagueID)
            let rightPriority = TodayMatchesLeagueConfig.priority(for: rhs.leagueID)
            if leftPriority != rightPriority {
                return leftPriority < rightPriority
            }

            return lhs.id < rhs.id
        }
    }

    private func statusBucket(for match: MatchDisplayModel) -> Int {
        if match.isLive { return 0 }
        if match.isFinished { return 2 }
        return 1
    }

    private func minuteValue(from minuteText: String?) -> Int {
        guard let minuteText else { return 0 }
        let digitsOnly = minuteText.filter { $0.isNumber }
        return Int(digitsOnly) ?? 0
    }

}
