import Foundation

nonisolated struct TopFiveClubLeagueDescriptor: Hashable {
    let id: Int
    let name: String

    static let topFive: [TopFiveClubLeagueDescriptor] = [
        TopFiveClubLeagueDescriptor(id: 39, name: "Premier League"),
        TopFiveClubLeagueDescriptor(id: 140, name: "La Liga"),
        TopFiveClubLeagueDescriptor(id: 135, name: "Serie A"),
        TopFiveClubLeagueDescriptor(id: 78, name: "Bundesliga"),
        TopFiveClubLeagueDescriptor(id: 61, name: "Ligue 1")
    ]
}

nonisolated struct TopFiveClubItem: Identifiable, Hashable {
    let id: Int
    let name: String
    let shortCode: String?
    let logoURL: URL?
    let leagueID: Int
    let leagueName: String
}

struct TopFiveClubFixtures {
    let previous: [MatchDisplayModel]
    let upcoming: [MatchDisplayModel]
}

nonisolated struct TopFiveTeamsResponse: Decodable {
    let errors: FixturePayloadErrors?
    let results: Int?
    let response: [TopFiveTeamsContainer]
}

nonisolated struct TopFiveTeamsContainer: Decodable {
    let team: TopFiveTeamPayload?
}

nonisolated struct TopFiveTeamPayload: Decodable {
    let id: Int?
    let name: String?
    let code: String?
    let logo: String?
}

extension TopFiveClubItem {
    nonisolated static let fallbackTopFiveClubs: [TopFiveClubItem] = [
        // Premier League
        .init(id: 33, name: "Manchester United", shortCode: "MUN", logoURL: URL(string: "https://media.api-sports.io/football/teams/33.png"), leagueID: 39, leagueName: "Premier League"),
        .init(id: 40, name: "Liverpool", shortCode: "LIV", logoURL: URL(string: "https://media.api-sports.io/football/teams/40.png"), leagueID: 39, leagueName: "Premier League"),
        .init(id: 42, name: "Arsenal", shortCode: "ARS", logoURL: URL(string: "https://media.api-sports.io/football/teams/42.png"), leagueID: 39, leagueName: "Premier League"),
        .init(id: 47, name: "Tottenham", shortCode: "TOT", logoURL: URL(string: "https://media.api-sports.io/football/teams/47.png"), leagueID: 39, leagueName: "Premier League"),
        .init(id: 49, name: "Chelsea", shortCode: "CHE", logoURL: URL(string: "https://media.api-sports.io/football/teams/49.png"), leagueID: 39, leagueName: "Premier League"),
        .init(id: 50, name: "Manchester City", shortCode: "MCI", logoURL: URL(string: "https://media.api-sports.io/football/teams/50.png"), leagueID: 39, leagueName: "Premier League"),
        .init(id: 51, name: "Brighton", shortCode: "BHA", logoURL: URL(string: "https://media.api-sports.io/football/teams/51.png"), leagueID: 39, leagueName: "Premier League"),
        .init(id: 52, name: "Crystal Palace", shortCode: "CRY", logoURL: URL(string: "https://media.api-sports.io/football/teams/52.png"), leagueID: 39, leagueName: "Premier League"),
        .init(id: 55, name: "Brentford", shortCode: "BRE", logoURL: URL(string: "https://media.api-sports.io/football/teams/55.png"), leagueID: 39, leagueName: "Premier League"),
        .init(id: 66, name: "Aston Villa", shortCode: "AVL", logoURL: URL(string: "https://media.api-sports.io/football/teams/66.png"), leagueID: 39, leagueName: "Premier League"),
        .init(id: 34, name: "Newcastle United", shortCode: "NEW", logoURL: URL(string: "https://media.api-sports.io/football/teams/34.png"), leagueID: 39, leagueName: "Premier League"),
        .init(id: 45, name: "Everton", shortCode: "EVE", logoURL: URL(string: "https://media.api-sports.io/football/teams/45.png"), leagueID: 39, leagueName: "Premier League"),

        // La Liga
        .init(id: 529, name: "Barcelona", shortCode: "BAR", logoURL: URL(string: "https://media.api-sports.io/football/teams/529.png"), leagueID: 140, leagueName: "La Liga"),
        .init(id: 530, name: "Atletico Madrid", shortCode: "ATM", logoURL: URL(string: "https://media.api-sports.io/football/teams/530.png"), leagueID: 140, leagueName: "La Liga"),
        .init(id: 531, name: "Athletic Club", shortCode: "ATH", logoURL: URL(string: "https://media.api-sports.io/football/teams/531.png"), leagueID: 140, leagueName: "La Liga"),
        .init(id: 532, name: "Valencia", shortCode: "VAL", logoURL: URL(string: "https://media.api-sports.io/football/teams/532.png"), leagueID: 140, leagueName: "La Liga"),
        .init(id: 536, name: "Sevilla", shortCode: "SEV", logoURL: URL(string: "https://media.api-sports.io/football/teams/536.png"), leagueID: 140, leagueName: "La Liga"),
        .init(id: 541, name: "Real Madrid", shortCode: "RMA", logoURL: URL(string: "https://media.api-sports.io/football/teams/541.png"), leagueID: 140, leagueName: "La Liga"),
        .init(id: 548, name: "Real Sociedad", shortCode: "RSO", logoURL: URL(string: "https://media.api-sports.io/football/teams/548.png"), leagueID: 140, leagueName: "La Liga"),

        // Serie A
        .init(id: 487, name: "Lazio", shortCode: "LAZ", logoURL: URL(string: "https://media.api-sports.io/football/teams/487.png"), leagueID: 135, leagueName: "Serie A"),
        .init(id: 489, name: "AC Milan", shortCode: "MIL", logoURL: URL(string: "https://media.api-sports.io/football/teams/489.png"), leagueID: 135, leagueName: "Serie A"),
        .init(id: 492, name: "Napoli", shortCode: "NAP", logoURL: URL(string: "https://media.api-sports.io/football/teams/492.png"), leagueID: 135, leagueName: "Serie A"),
        .init(id: 496, name: "Juventus", shortCode: "JUV", logoURL: URL(string: "https://media.api-sports.io/football/teams/496.png"), leagueID: 135, leagueName: "Serie A"),
        .init(id: 497, name: "AS Roma", shortCode: "ROM", logoURL: URL(string: "https://media.api-sports.io/football/teams/497.png"), leagueID: 135, leagueName: "Serie A"),
        .init(id: 499, name: "Atalanta", shortCode: "ATA", logoURL: URL(string: "https://media.api-sports.io/football/teams/499.png"), leagueID: 135, leagueName: "Serie A"),
        .init(id: 500, name: "Bologna", shortCode: "BOL", logoURL: URL(string: "https://media.api-sports.io/football/teams/500.png"), leagueID: 135, leagueName: "Serie A"),
        .init(id: 505, name: "Inter", shortCode: "INT", logoURL: URL(string: "https://media.api-sports.io/football/teams/505.png"), leagueID: 135, leagueName: "Serie A"),

        // Bundesliga
        .init(id: 157, name: "Bayern Munich", shortCode: "BAY", logoURL: URL(string: "https://media.api-sports.io/football/teams/157.png"), leagueID: 78, leagueName: "Bundesliga"),
        .init(id: 165, name: "Borussia Dortmund", shortCode: "BVB", logoURL: URL(string: "https://media.api-sports.io/football/teams/165.png"), leagueID: 78, leagueName: "Bundesliga"),
        .init(id: 168, name: "Bayer Leverkusen", shortCode: "B04", logoURL: URL(string: "https://media.api-sports.io/football/teams/168.png"), leagueID: 78, leagueName: "Bundesliga"),
        .init(id: 169, name: "Eintracht Frankfurt", shortCode: "SGE", logoURL: URL(string: "https://media.api-sports.io/football/teams/169.png"), leagueID: 78, leagueName: "Bundesliga"),
        .init(id: 172, name: "VfB Stuttgart", shortCode: "VFB", logoURL: URL(string: "https://media.api-sports.io/football/teams/172.png"), leagueID: 78, leagueName: "Bundesliga"),
        .init(id: 173, name: "RB Leipzig", shortCode: "RBL", logoURL: URL(string: "https://media.api-sports.io/football/teams/173.png"), leagueID: 78, leagueName: "Bundesliga"),

        // Ligue 1
        .init(id: 79, name: "Lille", shortCode: "LIL", logoURL: URL(string: "https://media.api-sports.io/football/teams/79.png"), leagueID: 61, leagueName: "Ligue 1"),
        .init(id: 80, name: "Lyon", shortCode: "OL", logoURL: URL(string: "https://media.api-sports.io/football/teams/80.png"), leagueID: 61, leagueName: "Ligue 1"),
        .init(id: 81, name: "Marseille", shortCode: "OM", logoURL: URL(string: "https://media.api-sports.io/football/teams/81.png"), leagueID: 61, leagueName: "Ligue 1"),
        .init(id: 84, name: "Nice", shortCode: "OGCN", logoURL: URL(string: "https://media.api-sports.io/football/teams/84.png"), leagueID: 61, leagueName: "Ligue 1"),
        .init(id: 85, name: "Paris Saint Germain", shortCode: "PSG", logoURL: URL(string: "https://media.api-sports.io/football/teams/85.png"), leagueID: 61, leagueName: "Ligue 1"),
        .init(id: 91, name: "Monaco", shortCode: "ASM", logoURL: URL(string: "https://media.api-sports.io/football/teams/91.png"), leagueID: 61, leagueName: "Ligue 1")
    ]
}
