import Foundation

enum StandingsServiceError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Missing FOOTBALL_API_KEY in Secrets.plist."
        case .invalidURL:
            return "Invalid standings API URL."
        case .invalidResponse:
            return "Invalid standings API response."
        case .httpStatus(let code):
            return "Standings API returned HTTP \(code)."
        case .decodingFailed:
            return "Failed to decode standings payload."
        }
    }
}

protocol StandingsServiceProtocol {
    func fetchStandings(for league: LiveTopLeague) async throws -> [LiveStandingRow]
}

struct StandingsService: StandingsServiceProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
        APIConfig.configureURLCacheIfNeeded()
    }

    func fetchStandings(for league: LiveTopLeague) async throws -> [LiveStandingRow] {
        let apiKey = APIConfig.footballAPIKey
        guard !apiKey.isEmpty else {
            throw StandingsServiceError.missingAPIKey
        }

        let leagueID = leagueID(for: league)
        let season = 2025

        #if DEBUG
        print("League ID:", leagueID)
        print("Season:", season)
        #endif

        guard var components = URLComponents(url: APIConfig.footballBaseURL, resolvingAgainstBaseURL: false) else {
            throw StandingsServiceError.invalidURL
        }

        components.path = "/standings"
        components.queryItems = [
            URLQueryItem(name: "league", value: "\(leagueID)"),
            URLQueryItem(name: "season", value: "\(season)")
        ]

        guard let url = components.url else {
            throw StandingsServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue(apiKey, forHTTPHeaderField: "x-apisports-key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        debugLog("GET \(url.absoluteString)")
        debugLog("key: \(APIKeyMasker.mask(apiKey))")

        let data: Data
        let urlResponse: URLResponse

        do {
            (data, urlResponse) = try await session.data(for: request)
        } catch {
            debugError("network: \(error.localizedDescription)")
            throw error
        }

        guard let http = urlResponse as? HTTPURLResponse else {
            debugError("invalid response type")
            throw StandingsServiceError.invalidResponse
        }

        debugLog("status: \(http.statusCode)")
        debugLog("response size: \(data.count) bytes")

        guard (200...299).contains(http.statusCode) else {
            if let snippet = String(data: data.prefix(300), encoding: .utf8), !snippet.isEmpty {
                debugError("payload: \(snippet)")
            }
            throw StandingsServiceError.httpStatus(http.statusCode)
        }

        let decoded: StandingsResponse
        do {
            decoded = try JSONDecoder().decode(StandingsResponse.self, from: data)
        } catch {
            debugError("decoding: \(error.localizedDescription)")
            throw StandingsServiceError.decodingFailed
        }

        let response = decoded.response
        #if DEBUG
        print(response)
        #endif

        let rows = extractStandingsRows(from: response)
            .compactMap(mapStandingRow)
            .sorted { $0.rank < $1.rank }

        #if DEBUG
        print("Standings count:", rows.count)
        #endif
        debugLog("decoded standings count: \(rows.count)")
        return rows
    }

    private func extractStandingsRows(from response: [StandingsLeagueContainer]) -> [StandingsRow] {
        if let primary = response.first?.league.standings.first, !primary.isEmpty {
            return primary
        }

        let fallbackRows = response
            .flatMap { $0.league.standings }
            .flatMap { $0 }

        #if DEBUG
        if fallbackRows.isEmpty {
            print("No standings data found")
        }
        #endif

        return fallbackRows
    }

    private func mapStandingRow(_ row: StandingsRow) -> LiveStandingRow? {
        guard let rank = row.rank,
              let team = row.team,
              let teamName = team.name else {
            return nil
        }

        let played = row.all?.played ?? 0
        let wins = row.all?.win ?? 0
        let draws = row.all?.draw ?? 0
        let losses = row.all?.lose ?? 0
        let goalsFor = row.all?.goals?.goalsFor ?? 0
        let goalsAgainst = row.all?.goals?.against ?? 0
        let goalDiff = row.goalsDiff ?? (goalsFor - goalsAgainst)
        let points = row.points ?? (wins * 3 + draws)

        let form = (row.form ?? "")
            .uppercased()
            .filter { ["W", "D", "L"].contains($0) }
            .prefix(5)

        return LiveStandingRow(
            id: "\(team.id ?? rank)-\(teamName)",
            rank: rank,
            teamName: teamName,
            played: played,
            wins: wins,
            draws: draws,
            losses: losses,
            goalsFor: goalsFor,
            goalsAgainst: goalsAgainst,
            goalDiff: goalDiff,
            points: points,
            form: Array(form),
            badgeURL: team.logo.flatMap(URL.init(string:))
        )
    }

    private func leagueID(for league: LiveTopLeague) -> Int {
        switch league {
        case .premierLeague:
            return 39
        case .laliga:
            return 140
        case .serieA:
            return 135
        case .championsLeague:
            return 2
        case .bundesliga:
            return 78
        case .ligue1:
            return 61
        }
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[StandingsAPI] \(message)")
        #endif
    }

    private func debugError(_ message: String) {
        #if DEBUG
        print("[StandingsAPI][Error] \(message)")
        #endif
    }
}
