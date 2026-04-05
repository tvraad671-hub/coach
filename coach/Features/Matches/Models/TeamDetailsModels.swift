import Foundation

struct TeamDetailsOverview {
    let teamID: Int
    let teamName: String
    let teamLogoURL: URL?
    let leagueID: Int
    let leagueName: String
    let country: String?
    let city: String?
    let founded: Int?
    let stadiumName: String?
    let stadiumAddress: String?
    let stadiumCapacity: Int?
    let stadiumSurface: String?
    let stadiumImageURL: URL?
    let coachName: String?
    let coachPhotoURL: URL?
    let teamCode: String?

    static func fallback(from club: TopFiveClubItem) -> TeamDetailsOverview {
        TeamDetailsOverview(
            teamID: club.id,
            teamName: club.name,
            teamLogoURL: club.logoURL,
            leagueID: club.leagueID,
            leagueName: club.leagueName,
            country: nil,
            city: nil,
            founded: nil,
            stadiumName: nil,
            stadiumAddress: nil,
            stadiumCapacity: nil,
            stadiumSurface: nil,
            stadiumImageURL: nil,
            coachName: nil,
            coachPhotoURL: nil,
            teamCode: club.shortCode
        )
    }
}

struct TeamDetailsPlayerItem: Identifiable, Hashable {
    let id: String
    let playerID: Int?
    let name: String
    let number: Int?
    let position: String?
    let nationality: String?
    let photoURL: URL?
}

struct TeamDetailsSpotlightFixtures {
    let last: MatchDisplayModel?
    let next: MatchDisplayModel?
}

nonisolated struct TeamProfileResponse: Decodable {
    let response: [TeamProfileContainer]
}

nonisolated struct TeamProfileContainer: Decodable {
    let team: TeamProfileItem?
    let venue: TeamVenueItem?
}

nonisolated struct TeamProfileItem: Decodable {
    let id: Int?
    let name: String?
    let code: String?
    let country: String?
    let founded: Int?
    let logo: String?
}

nonisolated struct TeamVenueItem: Decodable {
    let id: Int?
    let name: String?
    let address: String?
    let city: String?
    let capacity: Int?
    let surface: String?
    let image: String?
}

nonisolated struct TeamCoachResponse: Decodable {
    let response: [TeamCoachItem]
}

nonisolated struct TeamCoachItem: Decodable {
    let id: Int?
    let name: String?
    let photo: String?
    let team: TeamCoachClubItem?
}

nonisolated struct TeamCoachClubItem: Decodable {
    let id: Int?
    let name: String?
}

nonisolated struct TeamSquadResponse: Decodable {
    let response: [TeamSquadContainer]
}

nonisolated struct TeamSquadContainer: Decodable {
    let team: TeamSquadTeamPayload?
    let players: [TeamSquadPlayerPayload]
}

nonisolated struct TeamSquadTeamPayload: Decodable {
    let id: Int?
    let name: String?
    let logo: String?
}

nonisolated struct TeamSquadPlayerPayload: Decodable {
    let id: Int?
    let name: String?
    let number: Int?
    let position: String?
    let nationality: String?
    let photo: String?
}
