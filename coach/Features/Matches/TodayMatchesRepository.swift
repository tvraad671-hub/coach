import Foundation

protocol TodayMatchesRepositoryProtocol {
    func fetchLiveMatches() async throws -> [MatchDisplayModel]
    func fetchMatchesForToday() async throws -> [MatchDisplayModel]
}

enum TodayMatchesRepositoryError: Error, LocalizedError {
    case apiPayload(String)

    var errorDescription: String? {
        switch self {
        case .apiPayload(let message):
            return message
        }
    }
}

struct TodayMatchesRepository: TodayMatchesRepositoryProtocol {
    private let apiClient: FootballAPIClientProtocol

    init(apiClient: FootballAPIClientProtocol = FootballAPIClient()) {
        self.apiClient = apiClient
    }

    func fetchLiveMatches() async throws -> [MatchDisplayModel] {
        let response = try await apiClient.fetchFixtures(endpoint: .liveFixtures)

        if let payloadMessage = payloadErrorMessage(from: response), response.response.isEmpty {
            throw TodayMatchesRepositoryError.apiPayload(payloadMessage)
        }

        let localTimeZone = TimeZone.current
        let localDate = MatchesDateFormatter.todayDateString(in: localTimeZone)

        let filtered = mapToDisplayModels(response)
            .filter(\.isLive)
            .filter { TodayMatchesLeagueConfig.contains(leagueID: $0.leagueID) }
            .filter { isMatchInLocalToday($0, localDate: localDate, timeZone: localTimeZone) }

        return uniqueMatches(from: filtered)
    }

    func fetchMatchesForToday() async throws -> [MatchDisplayModel] {
        let localTimeZone = TimeZone.current
        let utcTimeZone = TimeZone(secondsFromGMT: 0) ?? .current

        let localDate = MatchesDateFormatter.todayDateString(in: localTimeZone)
        let utcDate = MatchesDateFormatter.todayDateString(in: utcTimeZone)
        let localTimezoneIdentifier = APIConfig.timezoneIdentifier

        var scenarios: [(date: String, timezone: String)] = [
            (date: localDate, timezone: localTimezoneIdentifier)
        ]

        if localTimezoneIdentifier != "UTC" || utcDate != localDate {
            scenarios.append((date: utcDate, timezone: "UTC"))
        }

        var payloadMessages: [String] = []

        for scenario in scenarios {
            let response = try await apiClient.fetchFixtures(
                endpoint: .fixturesByDate(
                    date: scenario.date,
                    timezone: scenario.timezone
                )
            )

            if let payloadMessage = payloadErrorMessage(from: response), response.response.isEmpty {
                payloadMessages.append(payloadMessage)
                continue
            }

            let filtered = mapToDisplayModels(response)
                .filter { TodayMatchesLeagueConfig.contains(leagueID: $0.leagueID) }
                .filter { isMatchInLocalToday($0, localDate: localDate, timeZone: localTimeZone) }

            if !filtered.isEmpty {
                return uniqueMatches(from: filtered)
            }
        }

        if let payloadMessage = payloadMessages.first {
            throw TodayMatchesRepositoryError.apiPayload(payloadMessage)
        }

        return []
    }

    private func mapToDisplayModels(_ response: FixtureResponse) -> [MatchDisplayModel] {
        response.response.compactMap { MatchDisplayModel(fixture: $0) }
    }

    private func uniqueMatches(from source: [MatchDisplayModel]) -> [MatchDisplayModel] {
        var ordered: [MatchDisplayModel] = []
        var seen = Set<Int>()

        for item in source {
            if seen.insert(item.id).inserted {
                ordered.append(item)
            }
        }

        return ordered
    }

    private func isMatchInLocalToday(_ match: MatchDisplayModel, localDate: String, timeZone: TimeZone) -> Bool {
        guard match.kickoffTimestamp > 0 else { return true }

        let kickoffDate = Date(timeIntervalSince1970: TimeInterval(match.kickoffTimestamp))
        let kickoffDateString = MatchesDateFormatter.dateString(for: kickoffDate, in: timeZone)
        return kickoffDateString == localDate
    }

    private func payloadErrorMessage(from response: FixtureResponse) -> String? {
        guard let payloadErrors = response.errors?.values,
              !payloadErrors.isEmpty else {
            return nil
        }

        let normalizedMessages = payloadErrors.values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !normalizedMessages.isEmpty else {
            return nil
        }

        if let requestLimitMessage = normalizedMessages.first(where: { $0.localizedCaseInsensitiveContains("request limit") }) {
            return "تم تجاوز الحد اليومي لطلبات API. \(requestLimitMessage)"
        }

        if let planMessage = normalizedMessages.first(where: { $0.localizedCaseInsensitiveContains("Free plans") || $0.localizedCaseInsensitiveContains("plan") }) {
            return "الخطة الحالية في API لا تدعم هذا الطلب. \(planMessage)"
        }

        return normalizedMessages.joined(separator: "\n")
    }
}
