import Foundation

protocol TeamDetailsRepositoryProtocol {
    func fetchOverview(for club: TopFiveClubItem) async throws -> TeamDetailsOverview
}

enum TeamDetailsRepositoryError: Error, LocalizedError {
    case teamNotFound

    var errorDescription: String? {
        switch self {
        case .teamNotFound:
            return "Club details are unavailable right now."
        }
    }
}

struct TeamDetailsRepository: TeamDetailsRepositoryProtocol {
    private let apiClient: FootballAPIClientProtocol

    init(
        apiClient: FootballAPIClientProtocol = FootballAPIClient()
    ) {
        self.apiClient = apiClient
    }

    func fetchOverview(for club: TopFiveClubItem) async throws -> TeamDetailsOverview {
        let payload = try await apiClient.fetch(TeamProfileResponse.self, endpoint: .teamByID(id: club.id))

        guard let container = payload.response.first else {
            throw TeamDetailsRepositoryError.teamNotFound
        }

        let team = container.team
        let venue = container.venue
        let coach = try? await fetchCoach(teamID: club.id)

        return TeamDetailsOverview(
            teamID: team?.id ?? club.id,
            teamName: clean(team?.name) ?? club.name,
            teamLogoURL: safeURL(team?.logo) ?? club.logoURL,
            leagueID: club.leagueID,
            leagueName: club.leagueName,
            country: clean(team?.country),
            city: clean(venue?.city),
            founded: team?.founded,
            stadiumName: clean(venue?.name),
            stadiumAddress: clean(venue?.address),
            stadiumCapacity: venue?.capacity,
            stadiumSurface: clean(venue?.surface),
            stadiumImageURL: safeURL(venue?.image),
            coachName: clean(coach?.name),
            coachPhotoURL: safeURL(coach?.photo),
            teamCode: clean(team?.code) ?? club.shortCode
        )
    }

    private func fetchCoach(teamID: Int) async throws -> TeamCoachItem? {
        let payload = try await apiClient.fetch(TeamCoachResponse.self, endpoint: .coachesByTeam(team: teamID))

        if let direct = payload.response.first(where: { $0.team?.id == teamID }) {
            return direct
        }

        return payload.response.first
    }

    private func clean(_ text: String?) -> String? {
        guard let value = text?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }

    private func safeURL(_ raw: String?) -> URL? {
        guard let clean = clean(raw) else { return nil }
        return URL(string: clean)
    }

}
