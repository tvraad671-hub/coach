import Foundation

struct MatchDisplayModel: Identifiable, Hashable {
    let id: Int
    let leagueID: Int?
    let leagueName: String
    let leagueLogoURL: URL?
    let leagueFlagURL: URL?
    let homeTeamID: Int?
    let homeTeamName: String
    let homeTeamLogoURL: URL?
    let awayTeamID: Int?
    let awayTeamName: String
    let awayTeamLogoURL: URL?
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

    init(
        id: Int,
        leagueID: Int?,
        leagueName: String,
        leagueLogoURL: URL?,
        leagueFlagURL: URL?,
        homeTeamID: Int?,
        homeTeamName: String,
        homeTeamLogoURL: URL?,
        awayTeamID: Int?,
        awayTeamName: String,
        awayTeamLogoURL: URL?,
        homeScore: String,
        awayScore: String,
        statusText: String,
        minuteText: String?,
        venueName: String,
        kickoffLocalText: String,
        isLive: Bool,
        badgeText: String,
        statusShort: String,
        kickoffTimestamp: Int,
        isFinished: Bool,
        isUpcoming: Bool
    ) {
        self.id = id
        self.leagueID = leagueID
        self.leagueName = leagueName
        self.leagueLogoURL = leagueLogoURL
        self.leagueFlagURL = leagueFlagURL
        self.homeTeamID = homeTeamID
        self.homeTeamName = homeTeamName
        self.homeTeamLogoURL = homeTeamLogoURL
        self.awayTeamID = awayTeamID
        self.awayTeamName = awayTeamName
        self.awayTeamLogoURL = awayTeamLogoURL
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.statusText = statusText
        self.minuteText = minuteText
        self.venueName = venueName
        self.kickoffLocalText = kickoffLocalText
        self.isLive = isLive
        self.badgeText = badgeText
        self.statusShort = statusShort
        self.kickoffTimestamp = kickoffTimestamp
        self.isFinished = isFinished
        self.isUpcoming = isUpcoming
    }

    init?(fixture item: FixtureItem) {
        guard let fixture = item.fixture,
              let fixtureID = fixture.id else {
            return nil
        }

        let statusShort = (fixture.status?.short ?? "NS").uppercased()
        let statusKind = FixtureStatusMapper.kind(for: statusShort)

        let kickoffLocalText = MatchesDateFormatter.formatKickoff(
            isoDateString: fixture.date ?? ""
        )

        let minuteText = FixtureStatusMapper.minuteText(
            for: statusKind,
            elapsed: fixture.status?.elapsed
        )

        self.id = fixtureID
        self.leagueID = item.league?.id
        self.leagueName = item.league?.name?.trimmedNonEmpty ?? "Unknown League"
        self.leagueLogoURL = URL.safe(item.league?.logo)
        self.leagueFlagURL = URL.safe(item.league?.flag)
        self.homeTeamID = item.teams?.home?.id
        self.homeTeamName = item.teams?.home?.name?.trimmedNonEmpty ?? "Home"
        self.homeTeamLogoURL = URL.safe(item.teams?.home?.logo)
        self.awayTeamID = item.teams?.away?.id
        self.awayTeamName = item.teams?.away?.name?.trimmedNonEmpty ?? "Away"
        self.awayTeamLogoURL = URL.safe(item.teams?.away?.logo)
        self.homeScore = ScoreMapper.text(from: item.goals?.home, statusKind: statusKind)
        self.awayScore = ScoreMapper.text(from: item.goals?.away, statusKind: statusKind)
        self.statusText = FixtureStatusMapper.statusText(
            for: statusKind,
            minuteText: minuteText,
            kickoffLocalText: kickoffLocalText,
            statusShort: statusShort
        )
        self.minuteText = minuteText
        self.venueName = fixture.venue?.name?.trimmedNonEmpty ?? "--"
        self.kickoffLocalText = kickoffLocalText
        self.isLive = FixtureStatusMapper.isLive(kind: statusKind)
        self.badgeText = FixtureStatusMapper.badgeText(
            for: statusKind,
            kickoffLocalText: kickoffLocalText,
            statusShort: statusShort
        )
        self.statusShort = statusShort
        self.kickoffTimestamp = fixture.timestamp ?? 0
        self.isFinished = FixtureStatusMapper.isFinished(kind: statusKind)
        self.isUpcoming = statusKind == .upcoming
    }
}

private enum FixtureStatusKind {
    case live
    case halftime
    case finished
    case upcoming
    case postponed
    case cancelled
    case other
}

private enum FixtureStatusMapper {
    private static let liveCodes: Set<String> = ["LIVE", "1H", "2H", "ET", "BT", "P"]
    private static let finishedCodes: Set<String> = ["FT", "AET", "PEN"]
    private static let upcomingCodes: Set<String> = ["NS", "TBD"]
    private static let postponedCodes: Set<String> = ["PST"]
    private static let cancelledCodes: Set<String> = ["CANC", "ABD", "AWD", "WO"]

    static func kind(for shortStatus: String) -> FixtureStatusKind {
        if liveCodes.contains(shortStatus) {
            return .live
        }
        if shortStatus == "HT" {
            return .halftime
        }
        if finishedCodes.contains(shortStatus) {
            return .finished
        }
        if upcomingCodes.contains(shortStatus) {
            return .upcoming
        }
        if postponedCodes.contains(shortStatus) {
            return .postponed
        }
        if cancelledCodes.contains(shortStatus) {
            return .cancelled
        }
        return .other
    }

    static func isLive(kind: FixtureStatusKind) -> Bool {
        kind == .live || kind == .halftime
    }

    static func isFinished(kind: FixtureStatusKind) -> Bool {
        kind == .finished
    }

    static func badgeText(
        for kind: FixtureStatusKind,
        kickoffLocalText: String,
        statusShort: String
    ) -> String {
        switch kind {
        case .live:
            return "LIVE"
        case .halftime:
            return "HT"
        case .finished:
            return "FT"
        case .upcoming:
            return kickoffLocalText
        case .postponed:
            return "PST"
        case .cancelled:
            return "CANC"
        case .other:
            return statusShort
        }
    }

    static func minuteText(for kind: FixtureStatusKind, elapsed: Int?) -> String? {
        switch kind {
        case .live:
            guard let elapsed else { return nil }
            return "\(elapsed)'"
        case .halftime:
            return "HT"
        case .finished:
            return "FT"
        case .upcoming, .postponed, .cancelled, .other:
            return nil
        }
    }

    static func statusText(
        for kind: FixtureStatusKind,
        minuteText: String?,
        kickoffLocalText: String,
        statusShort: String
    ) -> String {
        switch kind {
        case .live:
            return minuteText ?? "LIVE"
        case .halftime:
            return "HT"
        case .finished:
            return "FT"
        case .upcoming:
            return kickoffLocalText
        case .postponed:
            return "PST"
        case .cancelled:
            return "CANC"
        case .other:
            return statusShort
        }
    }
}

private enum ScoreMapper {
    static func text(from score: Int?, statusKind: FixtureStatusKind) -> String {
        if let score {
            return "\(score)"
        }

        switch statusKind {
        case .live, .halftime, .finished:
            return "0"
        case .upcoming, .postponed, .cancelled, .other:
            return "-"
        }
    }
}

private extension URL {
    static func safe(_ raw: String?) -> URL? {
        guard let value = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return URL(string: value)
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
