import Foundation

struct MatchesServiceResult {
    let response: FixtureResponse
    let requestID: Int
    let endpointDescription: String
}

protocol MatchesServiceProtocol {
    func fetchFixtures(date: String, timezone: String) async throws -> MatchesServiceResult
}

actor MatchesService: MatchesServiceProtocol {
    private let apiClient: FootballAPIClientProtocol
    private var sentRequestsCount = 0

    init(apiClient: FootballAPIClientProtocol = FootballAPIClient(maxAttempts: 1)) {
        self.apiClient = apiClient
    }

    func fetchFixtures(date: String, timezone: String) async throws -> MatchesServiceResult {
        sentRequestsCount += 1
        let requestID = sentRequestsCount
        let endpointDescription = "/fixtures?date=\(date)&timezone=\(timezone)"

        MatchesLogger.log("send request #\(requestID) endpoint=\(endpointDescription)")

        let response = try await apiClient.fetchFixtures(
            endpoint: .fixturesByDate(
                date: date,
                timezone: timezone
            )
        )

        MatchesLogger.log(
            "response request #\(requestID) endpoint=\(endpointDescription) results=\(response.response.count)"
        )

        return MatchesServiceResult(
            response: response,
            requestID: requestID,
            endpointDescription: endpointDescription
        )
    }
}
