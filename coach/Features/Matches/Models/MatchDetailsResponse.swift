import Foundation

struct FixtureLineupsResponse: Decodable {
    let response: [FixtureLineup]
}

struct FixtureLineup: Decodable {
    let team: FixtureTeam?
    let formation: String?
    let startXI: [FixtureLineupMember]?
    let substitutes: [FixtureLineupMember]?
    let coach: FixtureCoach?
}

struct FixtureLineupMember: Decodable {
    let player: FixtureLineupPlayer?
}

struct FixtureLineupPlayer: Decodable {
    let id: Int?
    let name: String?
    let number: Int?
    let pos: String?
    let grid: String?
    let photo: String?
}

struct FixtureCoach: Decodable {
    let id: Int?
    let name: String?
    let photo: String?
}

struct FixtureStatisticsResponse: Decodable {
    let response: [FixtureTeamStatistics]
}

struct FixtureTeamStatistics: Decodable {
    let team: FixtureTeam?
    let statistics: [FixtureStatisticItem]
}

struct FixtureStatisticItem: Decodable {
    let type: String?
    let value: FixtureStatisticValue?
}

enum FixtureStatisticValue: Decodable {
    case int(Int)
    case double(Double)
    case string(String)
    case bool(Bool)
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .unknown
            return
        }

        if let value = try? container.decode(Int.self) {
            self = .int(value)
            return
        }

        if let value = try? container.decode(Double.self) {
            self = .double(value)
            return
        }

        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
            return
        }

        if let value = try? container.decode(String.self) {
            self = .string(value)
            return
        }

        self = .unknown
    }

    var text: String {
        switch self {
        case .int(let value):
            return "\(value)"
        case .double(let value):
            let asInt = Int(value)
            return abs(value - Double(asInt)) < 0.001 ? "\(asInt)" : String(format: "%.2f", value)
        case .string(let value):
            return value
        case .bool(let value):
            return value ? "Yes" : "No"
        case .unknown:
            return "--"
        }
    }
}

struct FixtureEventsResponse: Decodable {
    let response: [FixtureEventItem]
}

struct FixtureEventItem: Decodable {
    let time: FixtureEventTime?
    let team: FixtureTeam?
    let player: FixtureEventPerson?
    let assist: FixtureEventPerson?
    let type: String?
    let detail: String?
    let comments: String?
}

struct FixtureEventTime: Decodable {
    let elapsed: Int?
    let extra: Int?
}

struct FixtureEventPerson: Decodable {
    let id: Int?
    let name: String?
}
