import Foundation

enum FootballEndpoint {
    case liveFixtures
    case fixturesByDate(date: String, timezone: String)
    case fixturesByDateAndLeague(date: String, league: Int, season: Int, timezone: String)
    case fixturesByTeam(team: Int, league: Int?, season: Int?, last: Int?, next: Int?, timezone: String)
    case fixtureByID(id: Int, timezone: String)
    case teamByID(id: Int)
    case coachesByTeam(team: Int)
    case squadByTeam(team: Int)
    case fixtureLineups(fixture: Int)
    case fixtureStatistics(fixture: Int)
    case fixtureEvents(fixture: Int)
    case teamsByLeague(league: Int, season: Int)

    var path: String {
        switch self {
        case .liveFixtures, .fixturesByDate, .fixturesByDateAndLeague, .fixturesByTeam, .fixtureByID:
            return "/fixtures"
        case .teamsByLeague, .teamByID:
            return "/teams"
        case .coachesByTeam:
            return "/coachs"
        case .squadByTeam:
            return "/players/squads"
        case .fixtureLineups:
            return "/fixtures/lineups"
        case .fixtureStatistics:
            return "/fixtures/statistics"
        case .fixtureEvents:
            return "/fixtures/events"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .liveFixtures:
            return [URLQueryItem(name: "live", value: "all")]

        case .fixturesByDate(let date, let timezone):
            return [
                URLQueryItem(name: "date", value: date),
                URLQueryItem(name: "timezone", value: timezone)
            ]

        case .fixturesByDateAndLeague(let date, let league, let season, let timezone):
            return [
                URLQueryItem(name: "date", value: date),
                URLQueryItem(name: "league", value: "\(league)"),
                URLQueryItem(name: "season", value: "\(season)"),
                URLQueryItem(name: "timezone", value: timezone)
            ]

        case .fixturesByTeam(let team, let league, let season, let last, let next, let timezone):
            var items: [URLQueryItem] = [
                URLQueryItem(name: "team", value: "\(team)"),
                URLQueryItem(name: "timezone", value: timezone)
            ]
            if let league {
                items.append(URLQueryItem(name: "league", value: "\(league)"))
            }
            if let season {
                items.append(URLQueryItem(name: "season", value: "\(season)"))
            }
            if let last {
                items.append(URLQueryItem(name: "last", value: "\(last)"))
            }
            if let next {
                items.append(URLQueryItem(name: "next", value: "\(next)"))
            }
            return items

        case .fixtureByID(let id, let timezone):
            return [
                URLQueryItem(name: "id", value: "\(id)"),
                URLQueryItem(name: "timezone", value: timezone)
            ]

        case .teamByID(let id):
            return [
                URLQueryItem(name: "id", value: "\(id)")
            ]

        case .coachesByTeam(let team):
            return [
                URLQueryItem(name: "team", value: "\(team)")
            ]

        case .squadByTeam(let team):
            return [
                URLQueryItem(name: "team", value: "\(team)")
            ]

        case .teamsByLeague(let league, let season):
            return [
                URLQueryItem(name: "league", value: "\(league)"),
                URLQueryItem(name: "season", value: "\(season)")
            ]

        case .fixtureLineups(let fixture),
             .fixtureStatistics(let fixture),
             .fixtureEvents(let fixture):
            return [URLQueryItem(name: "fixture", value: "\(fixture)")]
        }
    }

    func makeURL(baseURL: URL) throws -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw FootballEndpointError.invalidBaseURL(baseURL.absoluteString)
        }

        components.path = path
        components.queryItems = queryItems

        guard let url = components.url else {
            throw FootballEndpointError.invalidComponents(path: path, queryItems: queryItems)
        }

        return url
    }
}

enum FootballEndpointError: Error, LocalizedError {
    case invalidBaseURL(String)
    case invalidComponents(path: String, queryItems: [URLQueryItem])

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL(let url):
            return "Invalid base URL: \(url)"
        case .invalidComponents(let path, _):
            return "Failed to build URL components for path: \(path)"
        }
    }
}
