import Foundation

struct MatchesCacheSnapshot {
    let matches: [MatchDisplayModel]
    let savedAt: Date
    let sourceDateKey: String

    var hasLiveMatches: Bool {
        matches.contains(where: \.isLive)
    }

    var timeToLive: TimeInterval {
        hasLiveMatches ? 3 * 60 : 12 * 60
    }

    func isFresh(for dateKey: String, now: Date = Date()) -> Bool {
        guard sourceDateKey == dateKey else { return false }
        return now.timeIntervalSince(savedAt) <= timeToLive
    }
}

actor MatchesCacheManager {
    static let shared = MatchesCacheManager()

    private let cacheFileURL: URL
    private var inMemoryPayload: PersistedPayload?
    private var hasLoadedDiskPayload = false

    init(cacheFileURL: URL? = nil) {
        if let cacheFileURL {
            self.cacheFileURL = cacheFileURL
        } else {
            let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            self.cacheFileURL = directory.appendingPathComponent("matches-fixtures-cache-v1.json")
        }
    }

    func loadSnapshot() -> MatchesCacheSnapshot? {
        let payload = loadPayloadIfNeeded()
        guard let payload else { return nil }

        let matches = payload.matches.map { $0.toMatchDisplayModel() }
        return MatchesCacheSnapshot(
            matches: matches,
            savedAt: payload.savedAt,
            sourceDateKey: payload.sourceDateKey
        )
    }

    func save(matches: [MatchDisplayModel], sourceDateKey: String, savedAt: Date = Date()) {
        let payload = PersistedPayload(
            savedAt: savedAt,
            sourceDateKey: sourceDateKey,
            matches: matches.map(CachedMatchRecord.init(match:))
        )

        inMemoryPayload = payload
        hasLoadedDiskPayload = true

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(payload)
            try data.write(to: cacheFileURL, options: .atomic)
            MatchesLogger.log("cache save source=network matches=\(matches.count) file=\(cacheFileURL.lastPathComponent)")
        } catch {
            MatchesLogger.log("cache save failed error=\(error.localizedDescription)")
        }
    }

    private func loadPayloadIfNeeded() -> PersistedPayload? {
        if hasLoadedDiskPayload {
            return inMemoryPayload
        }

        hasLoadedDiskPayload = true

        do {
            let data = try Data(contentsOf: cacheFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let payload = try decoder.decode(PersistedPayload.self, from: data)
            inMemoryPayload = payload
            MatchesLogger.log("cache load source=disk matches=\(payload.matches.count)")
            return payload
        } catch {
            MatchesLogger.log("cache miss source=disk reason=\(error.localizedDescription)")
            inMemoryPayload = nil
            return nil
        }
    }
}

private struct PersistedPayload: Codable {
    let savedAt: Date
    let sourceDateKey: String
    let matches: [CachedMatchRecord]
}

private struct CachedMatchRecord: Codable {
    let id: Int
    let leagueID: Int?
    let leagueName: String
    let leagueLogoURLString: String?
    let leagueFlagURLString: String?
    let homeTeamID: Int?
    let homeTeamName: String
    let homeTeamLogoURLString: String?
    let awayTeamID: Int?
    let awayTeamName: String
    let awayTeamLogoURLString: String?
    let homeScore: String
    let awayScore: String
    let statusText: String
    let minuteText: String?
    let venueName: String
    let kickoffLocalText: String
    let isLive: Bool
    let badgeText: String
    let statusShort: String
    let kickoffTimestamp: Int
    let isFinished: Bool
    let isUpcoming: Bool

    init(match: MatchDisplayModel) {
        self.id = match.id
        self.leagueID = match.leagueID
        self.leagueName = match.leagueName
        self.leagueLogoURLString = match.leagueLogoURL?.absoluteString
        self.leagueFlagURLString = match.leagueFlagURL?.absoluteString
        self.homeTeamID = match.homeTeamID
        self.homeTeamName = match.homeTeamName
        self.homeTeamLogoURLString = match.homeTeamLogoURL?.absoluteString
        self.awayTeamID = match.awayTeamID
        self.awayTeamName = match.awayTeamName
        self.awayTeamLogoURLString = match.awayTeamLogoURL?.absoluteString
        self.homeScore = match.homeScore
        self.awayScore = match.awayScore
        self.statusText = match.statusText
        self.minuteText = match.minuteText
        self.venueName = match.venueName
        self.kickoffLocalText = match.kickoffLocalText
        self.isLive = match.isLive
        self.badgeText = match.badgeText
        self.statusShort = match.statusShort
        self.kickoffTimestamp = match.kickoffTimestamp
        self.isFinished = match.isFinished
        self.isUpcoming = match.isUpcoming
    }

    func toMatchDisplayModel() -> MatchDisplayModel {
        MatchDisplayModel(
            id: id,
            leagueID: leagueID,
            leagueName: leagueName,
            leagueLogoURL: URL(string: leagueLogoURLString ?? ""),
            leagueFlagURL: URL(string: leagueFlagURLString ?? ""),
            homeTeamID: homeTeamID,
            homeTeamName: homeTeamName,
            homeTeamLogoURL: URL(string: homeTeamLogoURLString ?? ""),
            awayTeamID: awayTeamID,
            awayTeamName: awayTeamName,
            awayTeamLogoURL: URL(string: awayTeamLogoURLString ?? ""),
            homeScore: homeScore,
            awayScore: awayScore,
            statusText: statusText,
            minuteText: minuteText,
            venueName: venueName,
            kickoffLocalText: kickoffLocalText,
            isLive: isLive,
            badgeText: badgeText,
            statusShort: statusShort,
            kickoffTimestamp: kickoffTimestamp,
            isFinished: isFinished,
            isUpcoming: isUpcoming
        )
    }
}
