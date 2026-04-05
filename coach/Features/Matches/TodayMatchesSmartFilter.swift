import Foundation

struct TodayMatchesSmartFilter {
    func filter(_ matches: [MatchDisplayModel]) -> [MatchDisplayModel] {
        matches.filter(shouldInclude)
    }

    func shouldInclude(_ match: MatchDisplayModel) -> Bool {
        let leagueKey = normalizeKey(match.leagueName)
        let isImportantLeague = isImportantLeagueMatch(match, leagueKey: leagueKey)

        if hasExcludedLeagueKeyword(leagueKey), !isImportantLeague {
            return false
        }

        if isImportantLeague {
            return true
        }

        return knownTeamCount(in: match) > 0
    }

    func priority(for match: MatchDisplayModel) -> Int {
        if let leagueID = match.leagueID,
           let priority = SmartFilterConfig.leaguePriorityByID[leagueID] {
            return priority
        }

        let leagueKey = normalizeKey(match.leagueName)
        if let byName = leaguePriorityFromName(leagueKey) {
            return byName
        }

        let teamsCount = knownTeamCount(in: match)
        if teamsCount == 2 { return 50 }
        if teamsCount == 1 { return 60 }
        return 99
    }

    private func isImportantLeagueMatch(_ match: MatchDisplayModel, leagueKey: String) -> Bool {
        if let leagueID = match.leagueID,
           SmartFilterConfig.importantLeagueIDs.contains(leagueID) {
            return true
        }

        return SmartFilterConfig.importantLeagueKeywords.contains { leagueKey.contains($0) }
    }

    private func hasExcludedLeagueKeyword(_ leagueKey: String) -> Bool {
        SmartFilterConfig.excludedLeagueKeywords.contains { leagueKey.contains($0) }
    }

    private func leaguePriorityFromName(_ leagueKey: String) -> Int? {
        SmartFilterConfig.leaguePriorityByName.first(where: { leagueKey.contains($0.keyword) })?.priority
    }

    private func knownTeamCount(in match: MatchDisplayModel) -> Int {
        [match.homeTeamName, match.awayTeamName].reduce(0) { partial, team in
            partial + (isKnownTeamName(team) ? 1 : 0)
        }
    }

    private func isKnownTeamName(_ teamName: String) -> Bool {
        let key = normalizeKey(teamName)
        guard !key.isEmpty else { return false }

        if hasExcludedTeamKeyword(key) {
            return false
        }

        if SmartFilterConfig.knownTeamKeys.contains(key) {
            return true
        }

        for known in SmartFilterConfig.knownTeamKeys {
            if key.hasPrefix("\(known) ") || key.hasSuffix(" \(known)") {
                return true
            }
        }

        return false
    }

    private func hasExcludedTeamKeyword(_ teamKey: String) -> Bool {
        SmartFilterConfig.excludedTeamKeywords.contains { teamKey.contains($0) }
    }
}

private enum SmartFilterConfig {
    static let importantLeagueIDs: Set<Int> = [
        1,   // FIFA World Cup
        4,   // World Cup Qualification
        2,   // UEFA Champions League
        39,  // Premier League
        140, // La Liga
        135, // Serie A
        78   // Bundesliga
    ]

    static let importantLeagueKeywords: [String] = [
        "fifa world cup",
        "world cup qualification",
        "world cup qualifier",
        "uefa champions league",
        "champions league",
        "premier league",
        "la liga",
        "serie a",
        "bundesliga"
    ]

    static let excludedLeagueKeywords: [String] = [
        "u20",
        "u 20",
        "u21",
        "u 21",
        "u23",
        "u 23",
        "youth",
        "women",
        "feminine",
        "reserve",
        "reserves",
        "friendly",
        "friendlies",
        "amateur",
        "regional",
        "group",
        "division 2",
        "division ii",
        "division 3",
        "division iii"
    ]

    static let excludedTeamKeywords: [String] = [
        "u20",
        "u 20",
        "u21",
        "u 21",
        "u23",
        "u 23",
        "youth",
        "women",
        "feminine",
        "reserve",
        "reserves"
    ]

    static let leaguePriorityByID: [Int: Int] = [
        2: 1,   // UEFA Champions League
        39: 2,  // Premier League
        140: 3, // La Liga
        135: 4, // Serie A
        78: 5,  // Bundesliga
        1: 6,   // FIFA World Cup
        4: 7    // World Cup Qualification
    ]

    static let leaguePriorityByName: [(keyword: String, priority: Int)] = [
        ("uefa champions league", 1),
        ("champions league", 1),
        ("premier league", 2),
        ("la liga", 3),
        ("serie a", 4),
        ("bundesliga", 5),
        ("fifa world cup", 6),
        ("world cup qualification", 7),
        ("world cup qualifier", 7)
    ]

    static let knownTeamKeys: Set<String> = Set(
        knownTeamNames.map { normalizeKey($0) }
    )

    private static let knownTeamNames: [String] = [
        "Real Madrid",
        "Barcelona",
        "Atletico Madrid",
        "Sevilla",
        "Valencia",
        "Athletic Club",
        "Real Sociedad",
        "Villarreal",
        "Real Betis",
        "Girona",
        "Manchester City",
        "Manchester United",
        "Liverpool",
        "Arsenal",
        "Chelsea",
        "Tottenham",
        "Newcastle United",
        "Aston Villa",
        "West Ham",
        "Brighton",
        "Inter",
        "Inter Milan",
        "AC Milan",
        "Juventus",
        "Napoli",
        "Roma",
        "Lazio",
        "Atalanta",
        "Fiorentina",
        "Bayern Munich",
        "Borussia Dortmund",
        "Bayer Leverkusen",
        "RB Leipzig",
        "Stuttgart",
        "Eintracht Frankfurt",
        "Paris Saint Germain",
        "PSG",
        "Benfica",
        "Porto",
        "Sporting CP",
        "Ajax",
        "PSV",
        "Feyenoord",
        "Celtic",
        "Rangers",
        "Galatasaray",
        "Fenerbahce",
        "Besiktas",
        "Argentina",
        "Brazil",
        "France",
        "Spain",
        "Germany",
        "England",
        "Portugal",
        "Italy",
        "Netherlands",
        "Belgium",
        "Croatia",
        "Uruguay",
        "Mexico",
        "United States",
        "USA",
        "Morocco",
        "Saudi Arabia",
        "Japan",
        "South Korea",
        "Iran",
        "Qatar",
        "Egypt",
        "Senegal",
        "Algeria",
        "Tunisia",
        "Cameroon",
        "Nigeria",
        "Switzerland",
        "Denmark",
        "Poland",
        "Serbia",
        "Austria",
        "Ukraine",
        "Turkey",
        "Colombia",
        "Chile"
    ]
}

private func normalizeKey(_ raw: String) -> String {
    let folded = raw
        .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

    let sanitized = folded.unicodeScalars.map { scalar -> String in
        CharacterSet.alphanumerics.contains(scalar) ? String(scalar) : " "
    }.joined()

    return sanitized
        .split(whereSeparator: \.isWhitespace)
        .joined(separator: " ")
}
