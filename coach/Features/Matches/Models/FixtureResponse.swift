import Foundation

struct FixtureResponse: Decodable {
    let get: String?
    let parameters: [String: String]?
    let errors: FixturePayloadErrors?
    let results: Int?
    let response: [FixtureItem]
}

struct FixturePayloadErrors: Decodable {
    let values: [String: String]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let dictionary = try? container.decode([String: String].self) {
            values = dictionary
            return
        }

        if let array = try? container.decode([String].self) {
            var dictionary: [String: String] = [:]
            for (index, value) in array.enumerated() {
                dictionary["\(index)"] = value
            }
            values = dictionary
            return
        }

        values = [:]
    }
}

struct FixtureItem: Decodable {
    let fixture: FixtureDetails?
    let league: FixtureLeague?
    let teams: FixtureTeams?
    let goals: FixtureGoals?
}

struct FixtureDetails: Decodable {
    let id: Int?
    let date: String?
    let timestamp: Int?
    let timezone: String?
    let referee: String?
    let status: FixtureStatus?
    let venue: FixtureVenue?
}

struct FixtureStatus: Decodable {
    let long: String?
    let short: String?
    let elapsed: Int?
    let extra: Int?
}

struct FixtureVenue: Decodable {
    let name: String?
    let city: String?
}

struct FixtureLeague: Decodable {
    let id: Int?
    let name: String?
    let logo: String?
    let flag: String?
    let round: String?
}

struct FixtureTeams: Decodable {
    let home: FixtureTeam?
    let away: FixtureTeam?
}

struct FixtureTeam: Decodable {
    let id: Int?
    let name: String?
    let logo: String?
}

struct FixtureGoals: Decodable {
    let home: Int?
    let away: Int?
}
