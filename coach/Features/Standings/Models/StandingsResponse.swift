import Foundation

struct StandingsResponse: Decodable {
    let response: [StandingsLeagueContainer]
}

struct StandingsLeagueContainer: Decodable {
    let league: StandingsLeague
}

struct StandingsLeague: Decodable {
    let standings: [[StandingsRow]]
}

struct StandingsRow: Decodable {
    let rank: Int?
    let team: StandingsTeam?
    let points: Int?
    let goalsDiff: Int?
    let all: StandingsAllRecord?
    let form: String?
}

struct StandingsTeam: Decodable {
    let id: Int?
    let name: String?
    let logo: String?
}

struct StandingsAllRecord: Decodable {
    let played: Int?
    let win: Int?
    let draw: Int?
    let lose: Int?
    let goals: StandingsGoals?
}

struct StandingsGoals: Decodable {
    let goalsFor: Int?
    let against: Int?

    private enum CodingKeys: String, CodingKey {
        case goalsFor = "for"
        case against
    }
}
