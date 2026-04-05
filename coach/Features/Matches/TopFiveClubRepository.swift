import Foundation

protocol TopFiveClubRepositoryProtocol {
    func fetchTopFiveClubs(season: Int) async throws -> [TopFiveClubItem]
    func fetchClubFixtures(teamID: Int, leagueID: Int, season: Int) async throws -> TopFiveClubFixtures
}

enum TopFiveClubRepositoryError: Error, LocalizedError {
    case emptyClubIndex

    var errorDescription: String? {
        switch self {
        case .emptyClubIndex:
            return "Top five clubs list is currently unavailable."
        }
    }
}

struct TopFiveClubRepository: TopFiveClubRepositoryProtocol {
    private static let leagueIDs = Set(TopFiveClubLeagueDescriptor.topFive.map(\.id))
    private let apiClient: FootballAPIClientProtocol

    init(apiClient: FootballAPIClientProtocol = FootballAPIClient()) {
        self.apiClient = apiClient
    }

    func fetchTopFiveClubs(season: Int) async throws -> [TopFiveClubItem] {
        let staticClubs = TopFiveClubItem.fallbackTopFiveClubs
        let cachedClubs = TopFiveClubCacheStore.load()
        var mergedClubs = mergedAndSortedClubs([staticClubs, cachedClubs])

        let leagues = TopFiveClubLeagueDescriptor.topFive
        let seasonsToTry = seasonCandidates(around: season)
        let requiredLeagueIDs = Set(leagues.map(\.id))

        var remoteClubs: [TopFiveClubItem] = []
        var coveredLeagueIDs = Set<Int>()

        for seasonCandidate in seasonsToTry {
            let clubsForSeason = await fetchClubsForSeason(seasonCandidate, leagues: leagues)
            remoteClubs.append(contentsOf: clubsForSeason)
            coveredLeagueIDs.formUnion(clubsForSeason.map(\.leagueID))

            if coveredLeagueIDs.isSuperset(of: requiredLeagueIDs) {
                break
            }
        }

        if !remoteClubs.isEmpty {
            mergedClubs = mergedAndSortedClubs([mergedClubs, remoteClubs])
            TopFiveClubCacheStore.save(mergedClubs)
            debug("[TopFiveClubs] loaded \(remoteClubs.count) remote clubs, merged=\(mergedClubs.count)")
        } else {
            debug("[TopFiveClubs] using fallback clubs only, cached=\(cachedClubs.count), static=\(staticClubs.count)")
        }

        if mergedClubs.isEmpty {
            throw TopFiveClubRepositoryError.emptyClubIndex
        }

        return mergedClubs
    }

    func fetchClubFixtures(teamID: Int, leagueID: Int, season: Int) async throws -> TopFiveClubFixtures {
        async let lastResponse = apiClient.fetchFixtures(
            endpoint: .fixturesByTeam(
                team: teamID,
                league: leagueID,
                season: season,
                last: 5,
                next: nil,
                timezone: APIConfig.timezoneIdentifier
            )
        )

        async let nextResponse = apiClient.fetchFixtures(
            endpoint: .fixturesByTeam(
                team: teamID,
                league: leagueID,
                season: season,
                last: nil,
                next: 5,
                timezone: APIConfig.timezoneIdentifier
            )
        )

        var previous = mapToDisplayModels(try await lastResponse)
        var upcoming = mapToDisplayModels(try await nextResponse)

        if previous.isEmpty && upcoming.isEmpty {
            async let fallbackLast = apiClient.fetchFixtures(
                endpoint: .fixturesByTeam(
                    team: teamID,
                    league: nil,
                    season: nil,
                    last: 5,
                    next: nil,
                    timezone: APIConfig.timezoneIdentifier
                )
            )

            async let fallbackNext = apiClient.fetchFixtures(
                endpoint: .fixturesByTeam(
                    team: teamID,
                    league: nil,
                    season: nil,
                    last: nil,
                    next: 5,
                    timezone: APIConfig.timezoneIdentifier
                )
            )

            previous = mapToDisplayModels(try await fallbackLast)
            upcoming = mapToDisplayModels(try await fallbackNext)
        }

        let sortedPrevious = previous
            .sorted { $0.kickoffTimestamp > $1.kickoffTimestamp }
            .prefix(5)

        let sortedUpcoming = upcoming
            .sorted { $0.kickoffTimestamp < $1.kickoffTimestamp }
            .prefix(5)

        return TopFiveClubFixtures(
            previous: Array(sortedPrevious),
            upcoming: Array(sortedUpcoming)
        )
    }

    private func mapToDisplayModels(_ response: FixtureResponse) -> [MatchDisplayModel] {
        response.response.compactMap { MatchDisplayModel(fixture: $0) }
    }

    private func fetchClubsForSeason(
        _ season: Int,
        leagues: [TopFiveClubLeagueDescriptor]
    ) async -> [TopFiveClubItem] {
        await withTaskGroup(of: [TopFiveClubItem].self) { group in
            for league in leagues {
                group.addTask {
                    await fetchLeagueClubsWithRetry(league: league, season: season)
                }
            }

            var all: [TopFiveClubItem] = []
            for await chunk in group {
                all.append(contentsOf: chunk)
            }

            let unique = mergedAndSortedClubs([all])
            if !unique.isEmpty {
                debug("[TopFiveClubs] season \(season) clubs=\(unique.count)")
            }
            return unique
        }
    }

    private func fetchLeagueClubsWithRetry(
        league: TopFiveClubLeagueDescriptor,
        season: Int,
        attempts: Int = 2
    ) async -> [TopFiveClubItem] {
        var lastError: Error?

        for attempt in 1...max(1, attempts) {
            do {
                let payload = try await apiClient.fetch(
                    TopFiveTeamsResponse.self,
                    endpoint: .teamsByLeague(league: league.id, season: season)
                )

                if let errors = payload.errors, !errors.values.isEmpty {
                    debug("[TopFiveClubs][PayloadErrors] league=\(league.id) season=\(season) errors=\(Array(errors.values))")
                }

                let mapped = payload.response.compactMap { item -> TopFiveClubItem? in
                    guard let team = item.team,
                          let id = team.id,
                          let name = team.name?.trimmingCharacters(in: .whitespacesAndNewlines),
                          !name.isEmpty else {
                        return nil
                    }

                    let code = team.code?.trimmingCharacters(in: .whitespacesAndNewlines)
                    let cleanCode = (code?.isEmpty == false) ? code : nil
                    let logoURL = team.logo.flatMap(URL.init(string:))

                    return TopFiveClubItem(
                        id: id,
                        name: name,
                        shortCode: cleanCode,
                        logoURL: logoURL,
                        leagueID: league.id,
                        leagueName: league.name
                    )
                }

                if !mapped.isEmpty {
                    return mapped
                }

                if let payloadErrors = payload.errors, !payloadErrors.values.isEmpty {
                    return []
                }
            } catch {
                lastError = error
                debug("[TopFiveClubs][Retry] league=\(league.id) season=\(season) attempt=\(attempt) error=\(error.localizedDescription)")
            }

            if attempt < attempts {
                try? await Task.sleep(nanoseconds: 220_000_000)
            }
        }

        if let lastError {
            debug("[TopFiveClubs][Failed] league=\(league.id) season=\(season) error=\(lastError.localizedDescription)")
        }
        return []
    }

    private func leaguePriority(_ leagueID: Int) -> Int {
        switch leagueID {
        case 39: return 1
        case 140: return 2
        case 135: return 3
        case 78: return 4
        case 61: return 5
        default: return 99
        }
    }

    private func seasonCandidates(around preferred: Int) -> [Int] {
        var candidates: [Int] = [preferred, preferred - 1, preferred - 2, preferred - 3, 2024, 2023]
        candidates = candidates.filter { $0 >= 2018 }

        var unique: [Int] = []
        var seen = Set<Int>()
        for candidate in candidates {
            if seen.insert(candidate).inserted {
                unique.append(candidate)
            }
        }
        return unique
    }

    private func mergedAndSortedClubs(_ groups: [[TopFiveClubItem]]) -> [TopFiveClubItem] {
        var uniqueByID: [Int: TopFiveClubItem] = [:]
        var fallbackByNameLeague: [String: TopFiveClubItem] = [:]

        for group in groups {
            for club in group {
                guard Self.leagueIDs.contains(club.leagueID) else { continue }
                if uniqueByID[club.id] == nil {
                    uniqueByID[club.id] = club
                } else if let existing = uniqueByID[club.id], existing.logoURL == nil, club.logoURL != nil {
                    uniqueByID[club.id] = club
                }

                let key = normalizedClubKey(club.name, leagueID: club.leagueID)
                if fallbackByNameLeague[key] == nil {
                    fallbackByNameLeague[key] = club
                }
            }
        }

        // Keep distinct names even if fallback IDs are missing/wrong.
        for (nameLeagueKey, club) in fallbackByNameLeague where !uniqueByID.values.contains(where: { normalizedClubKey($0.name, leagueID: $0.leagueID) == nameLeagueKey }) {
            uniqueByID[club.id] = club
        }

        return uniqueByID.values.sorted { lhs, rhs in
            if lhs.leagueID != rhs.leagueID {
                return leaguePriority(lhs.leagueID) < leaguePriority(rhs.leagueID)
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private func normalizedClubKey(_ name: String, leagueID: Int) -> String {
        let cleaned = name
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return "\(leagueID)-\(cleaned)"
    }

    private func debug(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }
}

private enum TopFiveClubCacheStore {
    private static let key = "top_five_clubs_cache_v1"
    private static let maxAge: TimeInterval = 14 * 24 * 60 * 60

    private struct Payload: Codable {
        let savedAt: TimeInterval
        let clubs: [Record]
    }

    private struct Record: Codable {
        let id: Int
        let name: String
        let shortCode: String?
        let logoURL: String?
        let leagueID: Int
        let leagueName: String

        init(club: TopFiveClubItem) {
            self.id = club.id
            self.name = club.name
            self.shortCode = club.shortCode
            self.logoURL = club.logoURL?.absoluteString
            self.leagueID = club.leagueID
            self.leagueName = club.leagueName
        }

        var asClub: TopFiveClubItem {
            TopFiveClubItem(
                id: id,
                name: name,
                shortCode: shortCode,
                logoURL: logoURL.flatMap(URL.init(string:)),
                leagueID: leagueID,
                leagueName: leagueName
            )
        }
    }

    static func load() -> [TopFiveClubItem] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            return []
        }

        guard Date().timeIntervalSince1970 - payload.savedAt <= maxAge else {
            return []
        }

        return payload.clubs.map(\.asClub)
    }

    static func save(_ clubs: [TopFiveClubItem]) {
        let payload = Payload(
            savedAt: Date().timeIntervalSince1970,
            clubs: clubs.map(Record.init(club:))
        )

        guard let encoded = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(encoded, forKey: key)
    }
}

enum FootballSeasonResolver {
    nonisolated static func currentSeason(referenceDate: Date = Date()) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: referenceDate)
        let month = calendar.component(.month, from: referenceDate)
        return month >= 7 ? year : (year - 1)
    }
}
