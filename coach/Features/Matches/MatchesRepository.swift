import Foundation

enum MatchesLoadSource: String {
    case cache
    case network
}

struct MatchesRepositoryResult {
    let liveMatches: [MatchDisplayModel]
    let otherMatches: [MatchDisplayModel]
    let source: MatchesLoadSource
    let networkRequestsCount: Int
    let warningMessage: String?
}

protocol MatchesRepositoryProtocol {
    func loadCachedMatchesForToday() async -> MatchesRepositoryResult?
    func refreshMatchesIfNeeded() async throws -> MatchesRepositoryResult?
    func loadMatches(forceRefresh: Bool) async throws -> MatchesRepositoryResult
}

enum MatchesRepositoryError: Error, LocalizedError {
    case limitExceeded(String)
    case apiPlan(String)
    case apiMessage(String)

    var errorDescription: String? {
        switch self {
        case .limitExceeded(let raw):
            return "تم تجاوز الحد اليومي لطلبات المباريات. \(raw)"
        case .apiPlan(let raw):
            return "الخطة الحالية في مزود المباريات لا تسمح بهذا الطلب. \(raw)"
        case .apiMessage(let raw):
            return raw
        }
    }
}

actor MatchesRepository: MatchesRepositoryProtocol {
    static let shared = MatchesRepository()

    private let service: MatchesServiceProtocol
    private let cacheManager: MatchesCacheManager
    private let networkThrottleSeconds: TimeInterval

    private var inFlightLoadTask: Task<MatchesRepositoryResult, Error>?
    private var lastNetworkAttemptAt: Date?

    init(
        service: MatchesServiceProtocol = MatchesService(),
        cacheManager: MatchesCacheManager = .shared,
        networkThrottleSeconds: TimeInterval = 8
    ) {
        self.service = service
        self.cacheManager = cacheManager
        self.networkThrottleSeconds = max(2, networkThrottleSeconds)
    }

    func loadCachedMatchesForToday() async -> MatchesRepositoryResult? {
        let localDate = MatchesDateFormatter.todayDateString(in: .current)
        guard let cachedSnapshot = await cacheManager.loadSnapshot(),
              cachedSnapshot.sourceDateKey == localDate else {
            return nil
        }

        MatchesLogger.log("load immediate source=cache reason=initial-display")
        return Self.makeResult(
            matches: cachedSnapshot.matches,
            source: .cache,
            networkRequestsCount: 0,
            warningMessage: nil
        )
    }

    func refreshMatchesIfNeeded() async throws -> MatchesRepositoryResult? {
        let now = Date()
        let localDate = MatchesDateFormatter.todayDateString(in: .current)
        let timezone = APIConfig.timezoneIdentifier
        let cachedSnapshot = await cacheManager.loadSnapshot()

        if let inFlightLoadTask {
            MatchesLogger.log("refresh deduplicated reason=in-flight")
            return try await inFlightLoadTask.value
        }

        if let cachedSnapshot,
           cachedSnapshot.isFresh(for: localDate, now: now) {
            MatchesLogger.log("refresh skipped reason=fresh-cache")
            return nil
        }

        if let cachedSnapshot,
           let lastNetworkAttemptAt,
           now.timeIntervalSince(lastNetworkAttemptAt) < networkThrottleSeconds {
            MatchesLogger.log("refresh skipped reason=throttle")
            return Self.makeResult(
                matches: cachedSnapshot.matches,
                source: .cache,
                networkRequestsCount: 0,
                warningMessage: nil
            )
        }

        lastNetworkAttemptAt = now
        return try await performNetworkLoad(
            localDate: localDate,
            timezone: timezone,
            fallbackSnapshot: cachedSnapshot
        )
    }

    func loadMatches(forceRefresh: Bool = false) async throws -> MatchesRepositoryResult {
        let now = Date()
        let localDate = MatchesDateFormatter.todayDateString(in: .current)
        let timezone = APIConfig.timezoneIdentifier

        let cachedSnapshot = await cacheManager.loadSnapshot()

        if !forceRefresh,
           let cachedSnapshot,
           cachedSnapshot.isFresh(for: localDate, now: now) {
            MatchesLogger.log("load blocked network reason=fresh-cache")
            return Self.makeResult(
                matches: cachedSnapshot.matches,
                source: .cache,
                networkRequestsCount: 0,
                warningMessage: nil
            )
        }

        if let inFlightLoadTask {
            MatchesLogger.log("load deduplicated reason=in-flight")
            return try await inFlightLoadTask.value
        }

        if !forceRefresh,
           let cachedSnapshot,
           let lastNetworkAttemptAt,
           now.timeIntervalSince(lastNetworkAttemptAt) < networkThrottleSeconds {
            MatchesLogger.log("load blocked network reason=throttle using=cache")
            return Self.makeResult(
                matches: cachedSnapshot.matches,
                source: .cache,
                networkRequestsCount: 0,
                warningMessage: nil
            )
        }

        lastNetworkAttemptAt = now
        return try await performNetworkLoad(
            localDate: localDate,
            timezone: timezone,
            fallbackSnapshot: cachedSnapshot
        )
    }

    private func performNetworkLoad(
        localDate: String,
        timezone: String,
        fallbackSnapshot: MatchesCacheSnapshot?
    ) async throws -> MatchesRepositoryResult {
        if let inFlightLoadTask {
            MatchesLogger.log("load deduplicated reason=in-flight")
            return try await inFlightLoadTask.value
        }

        let task = Task<MatchesRepositoryResult, Error> { [service, cacheManager] in
            let serviceResult = try await service.fetchFixtures(date: localDate, timezone: timezone)
            let response = serviceResult.response

            if response.response.isEmpty,
               let payloadMessage = Self.payloadErrorMessage(from: response) {
                throw Self.errorFromPayload(payloadMessage)
            }

            if let payloadWarning = Self.payloadErrorMessage(from: response),
               !response.response.isEmpty {
                MatchesLogger.log("payload warning ignored because fixtures exist: \(payloadWarning)")
            }

            let filteredMatches = Self.filterAllowedMatches(
                from: response.response,
                localDate: localDate,
                localTimeZone: .current
            )
            let sortedMatches = Self.sortMatches(filteredMatches)

            await cacheManager.save(matches: sortedMatches, sourceDateKey: localDate, savedAt: Date())

            MatchesLogger.log(
                "load source=network request=\(serviceResult.requestID) endpoint=\(serviceResult.endpointDescription) matches=\(sortedMatches.count)"
            )

            return Self.makeResult(
                matches: sortedMatches,
                source: .network,
                networkRequestsCount: 1,
                warningMessage: nil
            )
        }

        inFlightLoadTask = task

        defer {
            inFlightLoadTask = nil
        }

        do {
            return try await task.value
        } catch {
            let message = Self.localizedMessage(from: error)
            MatchesLogger.log("load network failed error=\(message)")

            if let fallbackSnapshot {
                MatchesLogger.log("load fallback source=cache reason=network-failure")
                return Self.makeResult(
                    matches: fallbackSnapshot.matches,
                    source: .cache,
                    networkRequestsCount: 0,
                    warningMessage: message
                )
            }

            throw error
        }
    }

    private static func filterAllowedMatches(
        from fixtureItems: [FixtureItem],
        localDate: String,
        localTimeZone: TimeZone
    ) -> [MatchDisplayModel] {
        fixtureItems
            .compactMap { MatchDisplayModel(fixture: $0) }
            .filter { MatchesLeagueConfig.contains(leagueID: $0.leagueID) }
            .filter { isMatchInLocalDate($0, localDate: localDate, timeZone: localTimeZone) }
    }

    private static func isMatchInLocalDate(_ match: MatchDisplayModel, localDate: String, timeZone: TimeZone) -> Bool {
        guard match.kickoffTimestamp > 0 else { return true }

        let kickoffDate = Date(timeIntervalSince1970: TimeInterval(match.kickoffTimestamp))
        let kickoffDateString = MatchesDateFormatter.dateString(for: kickoffDate, in: timeZone)
        return kickoffDateString == localDate
    }

    private static func sortMatches(_ matches: [MatchDisplayModel]) -> [MatchDisplayModel] {
        matches.sorted { lhs, rhs in
            let leftBucket = statusBucket(for: lhs)
            let rightBucket = statusBucket(for: rhs)

            if leftBucket != rightBucket {
                return leftBucket < rightBucket
            }

            if lhs.kickoffTimestamp != rhs.kickoffTimestamp {
                if leftBucket == 2 {
                    return lhs.kickoffTimestamp > rhs.kickoffTimestamp
                }
                return lhs.kickoffTimestamp < rhs.kickoffTimestamp
            }

            let leftPriority = MatchesLeagueConfig.priority(for: lhs.leagueID)
            let rightPriority = MatchesLeagueConfig.priority(for: rhs.leagueID)
            if leftPriority != rightPriority {
                return leftPriority < rightPriority
            }

            return lhs.id < rhs.id
        }
    }

    private static func statusBucket(for match: MatchDisplayModel) -> Int {
        if match.isLive { return 0 }
        if match.isFinished { return 2 }
        return 1
    }

    private static func payloadErrorMessage(from response: FixtureResponse) -> String? {
        guard let payloadErrors = response.errors?.values,
              !payloadErrors.isEmpty else {
            return nil
        }

        let normalized = payloadErrors.values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !normalized.isEmpty else {
            return nil
        }

        return normalized.joined(separator: "\n")
    }

    private static func errorFromPayload(_ payloadMessage: String) -> MatchesRepositoryError {
        if payloadMessage.localizedCaseInsensitiveContains("request limit") {
            return .limitExceeded(payloadMessage)
        }

        if payloadMessage.localizedCaseInsensitiveContains("free plans")
            || payloadMessage.localizedCaseInsensitiveContains("plan") {
            return .apiPlan(payloadMessage)
        }

        return .apiMessage(payloadMessage)
    }

    private static func makeResult(
        matches: [MatchDisplayModel],
        source: MatchesLoadSource,
        networkRequestsCount: Int,
        warningMessage: String?
    ) -> MatchesRepositoryResult {
        let liveMatches = matches.filter(\.isLive)
        let otherMatches = matches.filter { !$0.isLive }

        MatchesLogger.log(
            "load source=\(source.rawValue) networkRequests=\(networkRequestsCount) live=\(liveMatches.count) other=\(otherMatches.count)"
        )

        return MatchesRepositoryResult(
            liveMatches: liveMatches,
            otherMatches: otherMatches,
            source: source,
            networkRequestsCount: networkRequestsCount,
            warningMessage: warningMessage
        )
    }

    private static func localizedMessage(from error: Error) -> String {
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription,
           !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return description
        }

        let description = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if description.isEmpty {
            return "تعذر تحميل مباريات اليوم حالياً."
        }

        return description
    }
}
