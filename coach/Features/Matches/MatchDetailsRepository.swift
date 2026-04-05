import Foundation

protocol MatchDetailsRepositoryProtocol {
    func fetchFixture(matchId: Int) async throws -> FixtureItem
    func fetchLineups(matchId: Int) async throws -> [FixtureLineup]
    func fetchStatistics(matchId: Int) async throws -> [FixtureTeamStatistics]
    func fetchEvents(matchId: Int) async throws -> [FixtureEventItem]
}

enum MatchDetailsRepositoryError: Error, LocalizedError {
    case fixtureNotFound

    var errorDescription: String? {
        switch self {
        case .fixtureNotFound:
            return "Match details are not available right now."
        }
    }
}

struct MatchDetailsRepository: MatchDetailsRepositoryProtocol {
    private let apiClient: FootballAPIClientProtocol

    init(apiClient: FootballAPIClientProtocol = FootballAPIClient()) {
        self.apiClient = apiClient
    }

    func fetchFixture(matchId: Int) async throws -> FixtureItem {
        let response = try await apiClient.fetchFixtures(
            endpoint: .fixtureByID(id: matchId, timezone: APIConfig.timezoneIdentifier)
        )

        guard let fixture = response.response.first else {
            throw MatchDetailsRepositoryError.fixtureNotFound
        }

        return fixture
    }

    func fetchLineups(matchId: Int) async throws -> [FixtureLineup] {
        let response = try await apiClient.fetch(FixtureLineupsResponse.self, endpoint: .fixtureLineups(fixture: matchId))
        return response.response
    }

    func fetchStatistics(matchId: Int) async throws -> [FixtureTeamStatistics] {
        let response = try await apiClient.fetch(FixtureStatisticsResponse.self, endpoint: .fixtureStatistics(fixture: matchId))
        return response.response
    }

    func fetchEvents(matchId: Int) async throws -> [FixtureEventItem] {
        let response = try await apiClient.fetch(FixtureEventsResponse.self, endpoint: .fixtureEvents(fixture: matchId))
        return response.response
    }
}
