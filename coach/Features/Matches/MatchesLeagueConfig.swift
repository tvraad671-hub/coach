import Foundation

struct MatchesLeagueDescriptor: Hashable {
    let id: Int
    let name: String
    let priority: Int
}

enum MatchesLeagueConfig {
    static let allowedLeagues: [MatchesLeagueDescriptor] = [
        .init(id: 39, name: "Premier League", priority: 1),
        .init(id: 140, name: "La Liga", priority: 2),
        .init(id: 135, name: "Serie A", priority: 3),
        .init(id: 78, name: "Bundesliga", priority: 4),
        .init(id: 61, name: "Ligue 1", priority: 5),
        .init(id: 307, name: "Saudi Pro League", priority: 6)
    ]

    static let allowedLeagueIDs = Set(allowedLeagues.map(\.id))

    static let priorityByLeagueID: [Int: Int] = Dictionary(
        uniqueKeysWithValues: allowedLeagues.map { ($0.id, $0.priority) }
    )

    static func contains(leagueID: Int?) -> Bool {
        guard let leagueID else { return false }
        return allowedLeagueIDs.contains(leagueID)
    }

    static func priority(for leagueID: Int?) -> Int {
        guard let leagueID else { return 99 }
        return priorityByLeagueID[leagueID] ?? 99
    }
}
