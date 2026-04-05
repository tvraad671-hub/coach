import SwiftUI
import Combine
import zlib
#if canImport(UIKit)
import UIKit
#endif

private enum FootballTheme {
    static let backgroundPrimary = Color(hex: 0x120022)
    static let backgroundSecondary = Color(hex: 0x054A91)
    static let cardBase = Color(hex: 0x32206D)
    static let cardGlow = Color(hex: 0xFF58DF)
    static let pitchGreen = Color(hex: 0xC1FF1A)
    static let accentGreen = Color(hex: 0x62FF9E)
    static let accentCyan = Color(hex: 0x30F2FF)
    static let pointsYellow = Color(hex: 0xFFE25C)
    static let dangerRed = Color(hex: 0xFF5B88)
    static let textPrimary = Color(hex: 0xF8F7FF)
    static let textSecondary = Color(hex: 0xD8CCFF)
    static let muted = Color(hex: 0x8E7BC5)
}

private extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

private let blockedSportsDBKeys: Set<String> = [
    "3",
    "123",
    "1",
    "test",
    "demo",
    "apikey",
    "free"
]

private func configuredSportsDBAPIKey() -> String? {
    let candidates: [String?] = [
        UserDefaults.standard.string(forKey: "coach.sportsdb.apiKey"),
        Bundle.main.object(forInfoDictionaryKey: "SPORTSDB_API_KEY") as? String,
        ProcessInfo.processInfo.environment["SPORTSDB_API_KEY"]
    ]

    for candidate in candidates {
        guard let candidate else { continue }
        let key = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { continue }
        guard !blockedSportsDBKeys.contains(key.lowercased()) else { continue }
        return key
    }

    return nil
}

private enum AppLanguage: String, CaseIterable, Identifiable {
    case arabic
    case english
    case hindi
    case chinese
    case kurdish

    var id: String { rawValue }

    static var userSelectableLanguages: [AppLanguage] {
        [.english, .arabic, .kurdish, .chinese, .hindi]
    }

    var nativeName: String {
        switch self {
        case .arabic: return "العربية"
        case .english: return "English"
        case .hindi: return "हिन्दी"
        case .chinese: return "中文"
        case .kurdish: return "کوردی"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .arabic: return "ar"
        case .english: return "en"
        case .hindi: return "hi"
        case .chinese: return "zh-Hans"
        case .kurdish: return "ckb_IQ"
        }
    }

    var layoutDirection: LayoutDirection {
        switch self {
        case .arabic, .kurdish:
            return .rightToLeft
        case .english, .hindi, .chinese:
            return .leftToRight
        }
    }

    func text(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        switch self {
        case .arabic: return ar
        case .english: return en
        case .hindi: return hi
        case .chinese: return zh
        case .kurdish: return ku
        }
    }
}

private enum GameStep {
    case welcome
    case leagueSelection
    case teamSelection
    case dashboard
}

private enum HomeRoute {
    case settings
    case leagues
}

private enum MainMenuAction: String, CaseIterable, Identifiable {
    case quickMatch
    case careerMode
    case teamManagement
    case trainingTactics
    case competitions
    case settings

    var id: String { rawValue }
}

private struct MainMenuResourceItem: Identifiable {
    let symbol: String
    let label: String
    let value: String

    var id: String {
        "\(symbol)-\(label)"
    }
}

private struct MainMenuCardStyle {
    let symbol: String
    let backgroundAsset: String
    let colors: [Color]
    let glow: Color
    let size: MainMenuCardSize
}

private enum MainMenuCardSize {
    case featured
    case medium
    case small
}

private enum DashboardTab: String, CaseIterable {
    case simulator = "محاكي"
    case team = "الفريق"
    case management = "الإدارة"

    var icon: String {
        switch self {
        case .simulator: return "play.rectangle.fill"
        case .team: return "person.3.fill"
        case .management: return "briefcase.fill"
        }
    }

    func title(in language: AppLanguage) -> String {
        switch self {
        case .simulator:
            return language.text(ar: "المركز", en: "Hub", hi: "हब", zh: "中心", ku: "ناوەند")
        case .team:
            return language.text(ar: "الفريق", en: "Team", hi: "टीम", zh: "球队", ku: "تیم")
        case .management:
            return language.text(ar: "الإدارة", en: "Management", hi: "प्रबंधन", zh: "管理", ku: "بەڕێوەبردن")
        }
    }
}

private enum TacticalPlan: String, CaseIterable, Codable {
    case fourThreeThree = "4-3-3"
    case fourTwoThreeOne = "4-2-3-1"
    case threeFiveTwo = "3-5-2"

    var styleName: String {
        switch self {
        case .fourThreeThree: return "هجومي متوازن"
        case .fourTwoThreeOne: return "سيطرة وسط"
        case .threeFiveTwo: return "ضغط مباشر"
        }
    }

    var attackBoost: Int {
        switch self {
        case .fourThreeThree: return 7
        case .fourTwoThreeOne: return 4
        case .threeFiveTwo: return 6
        }
    }

    var defenseBoost: Int {
        switch self {
        case .fourThreeThree: return 3
        case .fourTwoThreeOne: return 7
        case .threeFiveTwo: return 4
        }
    }

    func localizedStyleName(in language: AppLanguage) -> String {
        switch self {
        case .fourThreeThree:
            return language.text(ar: "هجومي متوازن", en: "Balanced Attack", hi: "संतुलित आक्रमण", zh: "均衡进攻", ku: "هێرشی هاوسەنگ")
        case .fourTwoThreeOne:
            return language.text(ar: "سيطرة وسط", en: "Midfield Control", hi: "मिडफ़ील्ड नियंत्रण", zh: "中场控制", ku: "کۆنترۆڵی ناوەڕاست")
        case .threeFiveTwo:
            return language.text(ar: "ضغط مباشر", en: "Direct Press", hi: "सीधा प्रेस", zh: "直接压迫", ku: "فشاری ڕاستەوخۆ")
        }
    }
}

private struct League: Identifiable {
    let id = UUID()
    let name: String
    let teams: [String]
}

enum LiveTopLeague: String, CaseIterable, Identifiable {
    case championsLeague
    case premierLeague
    case laliga
    case serieA
    case bundesliga
    case ligue1

    var id: String { rawValue }

    static var allCases: [LiveTopLeague] {
        [.premierLeague, .laliga, .serieA, .championsLeague]
    }

    var title: String {
        switch self {
        case .championsLeague: return "دوري الأبطال"
        case .premierLeague: return "الإنجليزي"
        case .laliga: return "الإسباني"
        case .serieA: return "الإيطالي"
        case .bundesliga: return "الألماني"
        case .ligue1: return "الفرنسي"
        }
    }

    fileprivate func localizedTitle(in language: AppLanguage) -> String {
        switch self {
        case .championsLeague:
            return language.text(ar: "دوري الأبطال", en: "Champions League", hi: "चैंपियंस लीग", zh: "欧冠", ku: "لیگی پاڵەوانان")
        case .premierLeague:
            return language.text(ar: "الإنجليزي", en: "Premier League", hi: "प्रीमियर लीग", zh: "英超", ku: "پریمیەر لیگ")
        case .laliga:
            return language.text(ar: "الإسباني", en: "La Liga", hi: "ला लीगा", zh: "西甲", ku: "لا لیگا")
        case .serieA:
            return language.text(ar: "الإيطالي", en: "Serie A", hi: "सीरी ए", zh: "意甲", ku: "سێری ئا")
        case .bundesliga:
            return language.text(ar: "الألماني", en: "Bundesliga", hi: "बुंडेसलीगा", zh: "德甲", ku: "بوندسلیگا")
        case .ligue1:
            return language.text(ar: "الفرنسي", en: "Ligue 1", hi: "लीग 1", zh: "法甲", ku: "لیگ ١")
        }
    }

    // IDs from TheSportsDB
    var sportsDBLeagueId: String {
        switch self {
        case .championsLeague: return "4480"
        case .premierLeague: return "4328"
        case .laliga: return "4335"
        case .serieA: return "4332"
        case .bundesliga: return "4331"
        case .ligue1: return "4334"
        }
    }

    // IDs from API-Football (API-SPORTS)
    var apiFootballLeagueID: Int {
        switch self {
        case .championsLeague: return 2
        case .premierLeague: return 39
        case .laliga: return 140
        case .serieA: return 135
        case .bundesliga: return 78
        case .ligue1: return 61
        }
    }
}

struct LiveStandingRow: Identifiable {
    let id: String
    let rank: Int
    let teamName: String
    let played: Int
    let wins: Int
    let draws: Int
    let losses: Int
    let goalsFor: Int
    let goalsAgainst: Int
    let goalDiff: Int
    let points: Int
    let form: [Character]
    let badgeURL: URL?
}

private struct TeamHubCard: Identifiable {
    let id: String
    let title: String
    let icon: String
    let colors: [Color]
    let glowColor: Color
    let phase: Double

    init(title: String, icon: String, colors: [Color], glowColor: Color, phase: Double) {
        self.id = title
        self.title = title
        self.icon = icon
        self.colors = colors
        self.glowColor = glowColor
        self.phase = phase
    }
}

private struct SportsDBStandingsResponse: Decodable {
    let table: [SportsDBStanding]?
}

private struct SportsDBStanding: Decodable {
    let idStanding: String?
    let idTeam: String?
    let intRank: String?
    let strTeam: String?
    let strTeamBadge: String?
    let strBadge: String?
    let intPlayed: String?
    let intWin: String?
    let intDraw: String?
    let intLoss: String?
    let intGoalsFor: String?
    let intGoalsAgainst: String?
    let intGoalDifference: String?
    let intPoints: String?
    let strForm: String?
}

private struct SportsDBEventsResponse: Decodable {
    let events: [SportsDBEvent]?
}

private struct SportsDBEvent: Decodable {
    let idEvent: String?
    let strHomeTeam: String?
    let strAwayTeam: String?
    let intHomeScore: String?
    let intAwayScore: String?
    let strTimestamp: String?
    let dateEvent: String?
    let strTime: String?
    let strStatus: String?
}

private struct UCLFixtureRow: Identifiable {
    let id: String
    let home: String
    let away: String
    let homeScore: String?
    let awayScore: String?
    let dateText: String
    let timeText: String
    let status: String
}

private struct TeamStanding: Codable {
    var played = 0
    var wins = 0
    var draws = 0
    var losses = 0
    var goalsFor = 0
    var goalsAgainst = 0
    var points = 0

    var goalDifference: Int { goalsFor - goalsAgainst }

    mutating func apply(goalsFor: Int, goalsAgainst: Int) {
        played += 1
        self.goalsFor += goalsFor
        self.goalsAgainst += goalsAgainst

        if goalsFor > goalsAgainst {
            wins += 1
            points += 3
        } else if goalsFor == goalsAgainst {
            draws += 1
            points += 1
        } else {
            losses += 1
        }
    }
}

private struct TransferOption: Identifiable, Codable {
    let id: UUID
    let name: String
    let costM: Int
    let boost: Int
    var purchased = false

    init(id: UUID = UUID(), name: String, costM: Int, boost: Int, purchased: Bool = false) {
        self.id = id
        self.name = name
        self.costM = costM
        self.boost = boost
        self.purchased = purchased
    }
}

private struct MarketPlayer: Identifiable, Codable {
    let id: UUID
    let name: String
    let costM: Int
    let boost: Int
    var signed = false

    init(id: UUID = UUID(), name: String, costM: Int, boost: Int, signed: Bool = false) {
        self.id = id
        self.name = name
        self.costM = costM
        self.boost = boost
        self.signed = signed
    }
}

private struct TeamPlayer: Identifiable, Equatable, Codable {
    let id: UUID
    let name: String
    let role: String
    let number: Int

    init(id: UUID = UUID(), name: String, role: String, number: Int) {
        self.id = id
        self.name = name
        self.role = role
        self.number = number
    }
}

private struct MatchEvent: Identifiable {
    let id = UUID()
    let minute: Int
    let text: String
}

private struct MatchFixture {
    let home: String
    let away: String
    let opponent: String
    let date: Date
}

private enum TeamMatchResult: String, Codable {
    case win
    case draw
    case loss
}

private struct TeamMatchHistoryEntry: Identifiable, Codable {
    let id: UUID
    let opponent: String
    let date: Date
    let result: TeamMatchResult
    let goalsFor: Int
    let goalsAgainst: Int

    init(
        id: UUID = UUID(),
        opponent: String,
        date: Date,
        result: TeamMatchResult,
        goalsFor: Int,
        goalsAgainst: Int
    ) {
        self.id = id
        self.opponent = opponent
        self.date = date
        self.result = result
        self.goalsFor = goalsFor
        self.goalsAgainst = goalsAgainst
    }
}

private struct ClubNewsItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let summary: String
    let date: Date
    let icon: String

    init(id: UUID = UUID(), title: String, summary: String, date: Date, icon: String) {
        self.id = id
        self.title = title
        self.summary = summary
        self.date = date
        self.icon = icon
    }
}

private struct RemoteLogoDownloadItem: Identifiable {
    let id: String
    let clubName: String
    let fileName: String
    let remoteURL: URL
}

private struct GameSaveData: Codable {
    let stepRaw: String
    let selectedLeagueName: String?
    let selectedTeam: String?
    let currentTabRaw: String
    let seasonTable: [String: TeamStanding]
    let matchWeek: Int
    let totalWeeks: Int
    let previousResult: String
    let managerNote: String
    let budgetM: Int
    let fanSatisfaction: Int
    let squadStrength: Int
    let injuries: Int
    let seasonTarget: String
    let transferTargets: [TransferOption]
    let marketPlayers: [MarketPlayer]
    let seasonStartDate: Date
    let currentDate: Date
    let calendarDisplayDate: Date
    let contractEndDate: Date
    let lineup: [TeamPlayer]
    let bench: [TeamPlayer]
    let selectedLiveLeagueRaw: String
    let tacticalPlanRaw: String?
    let leagueTitlesWon: Int?
    let coachOfMonthAwards: Int?
    let goldenBootAwards: Int?
    let topScorerName: String?
    let topScorerGoals: Int?
    let playerSeasonGoals: [String: Int]?
    let achievementLog: [String]?
    let recentFormPoints: [Int]?
    let clubNewsFeed: [ClubNewsItem]?
    let teamMatchHistory: [String: [TeamMatchHistoryEntry]]?
}

private let topLeagues: [League] = [
    League(name: "الدوري الإنجليزي", teams: ["مانشستر سيتي", "أرسنال", "ليفربول", "تشيلسي", "مانشستر يونايتد", "توتنهام", "نيوكاسل", "أستون فيلا", "برايتون", "وست هام", "ولفرهامبتون", "فولهام", "كريستال بالاس", "برينتفورد", "إيفرتون", "نوتنغهام فورست", "بورنموث", "بيرنلي", "شيفيلد يونايتد", "لوتون تاون"]),
    League(name: "الدوري الإسباني", teams: ["برشلونة", "ريال مدريد", "أتلتيكو مدريد", "فياريال", "ريال بيتيس", "سيلتا فيغو", "ريال سوسيداد", "إسبانيول", "خيتافي", "أتلتيك بلباو", "أوساسونا", "جيرونا", "رايو فاليكانو", "فالنسيا", "إشبيلية", "ريال مايوركا", "ألافيس", "إلتشي", "ليفانتي", "ريال أوفييدو"]),
    League(name: "الدوري الإيطالي", teams: ["إنتر ميلان", "يوفنتوس", "ميلان", "نابولي", "روما", "لاتسيو", "أتلانتا", "فيورنتينا", "بولونيا", "تورينو", "ساسولو", "أودينيزي", "جنوى", "مونزا", "إمبولي", "ليتشي", "فروزينوني", "هيلاس فيرونا", "كالياري", "ساليرنيتانا"]),
    League(name: "الدوري الألماني", teams: ["بايرن ميونخ", "بوروسيا دورتموند", "لايبزيغ", "باير ليفركوزن", "شتوتغارت", "فولفسبورغ", "آينتراخت فرانكفورت", "هوفنهايم", "فرايبورغ", "ماينز", "أوغسبورغ", "بوروسيا مونشنغلادباخ", "فيردر بريمن", "يونيون برلين", "كولن", "بوخوم", "دارمشتات", "هايدنهايم", "سانت باولي", "هامبورغ"]),
    League(name: "الدوري الفرنسي", teams: ["باريس سان جيرمان", "مارسيليا", "ليون", "موناكو", "ليل", "رين", "نيس", "لانس", "ستاد ريمس", "مونبلييه", "ستراسبورغ", "نانت", "بريست", "تولوز", "لوهافر", "ميتز", "أنجيه", "لوريان", "كليرمون", "أوكسير"])
]

private let englishDisplayNames: [String: String] = [
    "الدوري الإنجليزي": "Premier League",
    "الدوري الإسباني": "La Liga",
    "الدوري الإيطالي": "Serie A",
    "الدوري الألماني": "Bundesliga",
    "الدوري الفرنسي": "Ligue 1",
    "مانشستر سيتي": "Manchester City",
    "أرسنال": "Arsenal",
    "ليفربول": "Liverpool",
    "تشيلسي": "Chelsea",
    "مانشستر يونايتد": "Manchester United",
    "توتنهام": "Tottenham Hotspur",
    "نيوكاسل": "Newcastle United",
    "أستون فيلا": "Aston Villa",
    "برايتون": "Brighton",
    "وست هام": "West Ham United",
    "ولفرهامبتون": "Wolverhampton",
    "فولهام": "Fulham",
    "كريستال بالاس": "Crystal Palace",
    "برينتفورد": "Brentford",
    "إيفرتون": "Everton",
    "نوتنغهام فورست": "Nottingham Forest",
    "بورنموث": "Bournemouth",
    "بيرنلي": "Burnley",
    "شيفيلد يونايتد": "Sheffield United",
    "لوتون تاون": "Luton Town",
    "ريال مدريد": "Real Madrid",
    "برشلونة": "Barcelona",
    "أتلتيكو مدريد": "Atletico Madrid",
    "إشبيلية": "Sevilla",
    "ريال سوسيداد": "Real Sociedad",
    "ريال بيتيس": "Real Betis",
    "فياريال": "Villarreal",
    "فالنسيا": "Valencia",
    "أتلتيك بلباو": "Athletic Bilbao",
    "خيتافي": "Getafe",
    "أوساسونا": "Osasuna",
    "جيرونا": "Girona",
    "سيلتا فيغو": "Celta Vigo",
    "إسبانيول": "Espanyol",
    "ريال مايوركا": "Mallorca",
    "ألافيس": "Alaves",
    "رايو فاليكانو": "Rayo Vallecano",
    "إلتشي": "Elche",
    "ليفانتي": "Levante",
    "ريال أوفييدو": "Real Oviedo",
    "غرناطة": "Granada",
    "قادش": "Cadiz",
    "لاس بالماس": "Las Palmas",
    "ألميريا": "Almeria",
    "إنتر ميلان": "Inter Milan",
    "يوفنتوس": "Juventus",
    "ميلان": "AC Milan",
    "نابولي": "Napoli",
    "روما": "Roma",
    "لاتسيو": "Lazio",
    "أتلانتا": "Atalanta",
    "فيورنتينا": "Fiorentina",
    "بولونيا": "Bologna",
    "تورينو": "Torino",
    "ساسولو": "Sassuolo",
    "أودينيزي": "Udinese",
    "جنوى": "Genoa",
    "مونزا": "Monza",
    "إمبولي": "Empoli",
    "ليتشي": "Lecce",
    "فروزينوني": "Frosinone",
    "هيلاس فيرونا": "Hellas Verona",
    "كالياري": "Cagliari",
    "ساليرنيتانا": "Salernitana",
    "بايرن ميونخ": "Bayern Munich",
    "بوروسيا دورتموند": "Borussia Dortmund",
    "دورتموند": "Borussia Dortmund",
    "لايبزيغ": "RB Leipzig",
    "باير ليفركوزن": "Bayer Leverkusen",
    "ليفركوزن": "Bayer Leverkusen",
    "شتوتغارت": "Stuttgart",
    "فولفسبورغ": "Wolfsburg",
    "آينتراخت فرانكفورت": "Eintracht Frankfurt",
    "فرانكفورت": "Eintracht Frankfurt",
    "هوفنهايم": "Hoffenheim",
    "فرايبورغ": "Freiburg",
    "ماينز": "Mainz",
    "أوغسبورغ": "Augsburg",
    "بوروسيا مونشنغلادباخ": "Borussia Monchengladbach",
    "فيردر بريمن": "Werder Bremen",
    "يونيون برلين": "Union Berlin",
    "كولن": "Koln",
    "بوخوم": "Bochum",
    "دارمشتات": "Darmstadt",
    "هايدنهايم": "Heidenheim",
    "سانت باولي": "St. Pauli",
    "هامبورغ": "Hamburg",
    "باريس سان جيرمان": "Paris Saint-Germain",
    "مارسيليا": "Marseille",
    "ليون": "Lyon",
    "موناكو": "Monaco",
    "ليل": "Lille",
    "رين": "Rennes",
    "نيس": "Nice",
    "لانس": "Lens",
    "ستاد ريمس": "Reims",
    "مونبلييه": "Montpellier",
    "ستراسبورغ": "Strasbourg",
    "نانت": "Nantes",
    "بريست": "Brest",
    "تولوز": "Toulouse",
    "لوهافر": "Le Havre",
    "ميتز": "Metz",
    "أنجيه": "Angers",
    "لوريان": "Lorient",
    "كليرمون": "Clermont",
    "أوكسير": "Auxerre",
    "مهاجم هداف": "Clinical Striker",
    "صانع ألعاب": "Playmaker",
    "مدافع صلب": "Solid Defender",
    "حارس مميز": "Elite Goalkeeper",
    "كيليان مبابي": "Kylian Mbappe",
    "إيرلينغ هالاند": "Erling Haaland",
    "جود بيلينغهام": "Jude Bellingham",
    "فينيسيوس جونيور": "Vinicius Junior",
    "جمال موسيالا": "Jamal Musiala",
    "رودري": "Rodri",
    "محمد صلاح": "Mohamed Salah",
    "لاعب شاب واعد": "Promising Young Player",
    "مهاجم سريع": "Fast Striker",
    "قلب دفاع صلب": "Strong Centre-Back",
    "ظهير أيمن": "Right Back",
    "قلب دفاع 1": "Centre-Back 1",
    "قلب دفاع 2": "Centre-Back 2",
    "ظهير أيسر": "Left Back",
    "محور": "Defensive Midfielder",
    "وسط 1": "Midfielder 1",
    "وسط 2": "Midfielder 2",
    "جناح أيمن": "Right Winger",
    "مهاجم": "Striker",
    "جناح أيسر": "Left Winger",
    "حارس احتياط": "Reserve Goalkeeper",
    "دفاع احتياط": "Reserve Defender",
    "وسط احتياط 1": "Reserve Midfielder 1",
    "وسط احتياط 2": "Reserve Midfielder 2",
    "جناح احتياط": "Reserve Winger",
    "مهاجم احتياط": "Reserve Striker",
    "ورقة رابحة": "Impact Player"
]

private func localizedLeagueName(_ name: String, in language: AppLanguage) -> String {
    switch name {
    case "الدوري الإنجليزي":
        return language.text(ar: "الدوري الإنجليزي", en: "Premier League", hi: "प्रीमियर लीग", zh: "英格兰超级联赛", ku: "لیگی ئینگلیزی")
    case "الدوري الإسباني":
        return language.text(ar: "الدوري الإسباني", en: "La Liga", hi: "ला लीगा", zh: "西班牙甲级联赛", ku: "لیگی ئیسپانی")
    case "الدوري الإيطالي":
        return language.text(ar: "الدوري الإيطالي", en: "Serie A", hi: "सीरी ए", zh: "意大利甲级联赛", ku: "لیگی ئیتالیا")
    case "الدوري الألماني":
        return language.text(ar: "الدوري الألماني", en: "Bundesliga", hi: "बुंडेसलीगा", zh: "德国甲级联赛", ku: "لیگی ئەڵمانیا")
    case "الدوري الفرنسي":
        return language.text(ar: "الدوري الفرنسي", en: "Ligue 1", hi: "लीग 1", zh: "法国甲级联赛", ku: "لیگی فەرەنسی")
    default:
        return localizedDisplayName(name, in: language)
    }
}

private func localizedDisplayName(_ name: String, in language: AppLanguage) -> String {
    guard language != .arabic, language != .kurdish else { return name }

    if let english = englishDisplayNames[name] {
        return english
    }

    if name.hasPrefix("حارس ") {
        let teamName = String(name.dropFirst("حارس ".count))
        return "Goalkeeper \(localizedDisplayName(teamName, in: language))"
    }

    return name
}

private func localizedDisplayText(_ text: String, in language: AppLanguage) -> String {
    guard language != .arabic, language != .kurdish else { return text }

    let replacements = englishDisplayNames.keys.sorted { $0.count > $1.count }
    var localized = text

    for key in replacements {
        if let replacement = englishDisplayNames[key] {
            localized = localized.replacingOccurrences(of: key, with: replacement)
        }
    }

    if localized == "لم تُلعب أي مباراة بعد" {
        return language.text(ar: localized, en: "No match has been played yet", hi: "अभी तक कोई मैच नहीं खेला गया", zh: "尚未进行任何比赛", ku: localized)
    }

    return localized
}

private func localizedSeasonTargetValue(_ value: String, in language: AppLanguage) -> String {
    if value == "إنهاء الموسم ضمن أول 4" {
        return language.text(
            ar: "إنهاء الموسم ضمن أول 4",
            en: "Finish the season in the top 4",
            hi: "सीज़न को शीर्ष 4 में समाप्त करें",
            zh: "赛季结束时进入前4名",
            ku: "وەرزەکە لە یەکەم 4 دا تەواو بکە"
        )
    }

    return localizedDisplayText(value, in: language)
}

private func localizedAchievement(_ text: String, in language: AppLanguage) -> String {
    if language == .arabic {
        return text
    }

    if text == "بطل الدوري" {
        return language.text(ar: text, en: "League Champion", hi: "लीग चैंपियन", zh: "联赛冠军", ku: "پاڵەوانی لیگ")
    }

    if text == "موسم تاريخي للمدرب" {
        return language.text(ar: text, en: "A historic season for the coach", hi: "कोच के लिए ऐतिहासिक सीज़न", zh: "属于教练的历史级赛季", ku: "وەرزێکی مێژوویی بۆ ڕاهێنەر")
    }

    if let week = text.split(separator: "الجولة ").last, text.contains("جائزة مدرب الشهر") {
        return language.text(
            ar: text,
            en: "Coach of the Month Award - Round \(week)",
            hi: "महीने का कोच पुरस्कार - राउंड \(week)",
            zh: "月度最佳教练奖 - 第\(week)轮",
            ku: "خەڵاتی ڕاهێنەری مانگ - دەوری \(week)"
        )
    }

    if text.hasPrefix("الحذاء الذهبي: ") {
        let payload = String(text.dropFirst("الحذاء الذهبي: ".count))
        let parts = payload.components(separatedBy: " - ")
        if parts.count == 2 {
            let scorer = localizedDisplayName(parts[0], in: language)
            let goals = parts[1].replacingOccurrences(of: " هدف", with: "")
            return language.text(
                ar: text,
                en: "Golden Boot: \(scorer) - \(goals) goals",
                hi: "गोल्डन बूट: \(scorer) - \(goals) गोल",
                zh: "金靴奖：\(scorer) - \(goals)球",
                ku: "پێڵاوی زێڕین: \(scorer) - \(goals) گۆڵ"
            )
        }
    }

    if text.hasPrefix("صفقة ناجحة: ") {
        let player = localizedDisplayName(String(text.dropFirst("صفقة ناجحة: ".count)), in: language)
        return language.text(
            ar: text,
            en: "Successful signing: \(player)",
            hi: "सफल साइनिंग: \(player)",
            zh: "成功签约：\(player)",
            ku: "واژۆکردنی سەرکەوتوو: \(player)"
        )
    }

    return localizedDisplayText(text, in: language)
}

private func localizedManagerNote(_ text: String, in language: AppLanguage) -> String {
    if language == .arabic {
        return text
    }

    switch text {
    case "اختر فريقك وابدأ الموسم":
        return language.text(ar: text, en: "Choose your team and start the season", hi: "अपनी टीम चुनें और सीज़न शुरू करें", zh: "选择你的球队并开始赛季", ku: "تیمەکەت هەڵبژێرە و وەرزەکە دەستپێبکە")
    case "تم حفظ اللعبة بنجاح":
        return language.text(ar: text, en: "Game saved successfully", hi: "गेम सफलतापूर्वक सेव हो गई", zh: "游戏已成功保存", ku: "یارییەکە بە سەرکەوتوویی هەڵگیرا")
    case "فشل الحفظ، حاول مرة ثانية":
        return language.text(ar: text, en: "Save failed, try again", hi: "सेव असफल रहा, फिर प्रयास करें", zh: "保存失败，请重试", ku: "هەڵگرتن سەرکەوتوو نەبوو، دووبارە هەوڵبدە")
    case "الميزانية غير كافية لهذه الصفقة":
        return language.text(ar: text, en: "The budget is not enough for this signing", hi: "इस सौदे के लिए बजट पर्याप्त नहीं है", zh: "预算不足，无法完成这笔签约", ku: "بودجە بۆ ئەم واژۆکردنە بەس نییە")
    default:
        break
    }

    if text.hasPrefix("موسم جديد بدأ مع ") {
        let team = localizedDisplayName(String(text.dropFirst("موسم جديد بدأ مع ".count)), in: language)
        return language.text(
            ar: text,
            en: "A new season has started with \(team)",
            hi: "\(team) के साथ नया सीज़न शुरू हो गया है",
            zh: "与\(team)一起开始了新赛季",
            ku: "وەرزێکی نوێ لەگەڵ \(team) دەستی پێکرد"
        )
    }

    if text.hasPrefix("انتهى الموسم - المركز النهائي #") {
        let payload = String(text.dropFirst("انتهى الموسم - المركز النهائي #".count))
        let parts = payload.components(separatedBy: " | الإنجازات: ")
        if parts.count == 2 {
            return language.text(
                ar: text,
                en: "Season finished - Final rank #\(parts[0]) | Achievements: \(parts[1])",
                hi: "सीज़न समाप्त - अंतिम रैंक #\(parts[0]) | उपलब्धियाँ: \(parts[1])",
                zh: "赛季结束 - 最终排名 #\(parts[0]) | 成就：\(parts[1])",
                ku: "وەرزەکە کۆتایی هات - پلەی کۆتایی #\(parts[0]) | دەستکەوت: \(parts[1])"
            )
        }
    }

    if text.hasPrefix("تم التوقيع مع ") {
        let name = localizedDisplayName(String(text.dropFirst("تم التوقيع مع ".count)), in: language)
        return language.text(
            ar: text,
            en: "Signed \(name)",
            hi: "\(name) के साथ साइनिंग पूरी हुई",
            zh: "已签下\(name)",
            ku: "\(name) واژۆ کرا"
        )
    }

    if text.hasPrefix("الميزانية لا تكفي لعرض ") {
        let name = localizedDisplayName(String(text.dropFirst("الميزانية لا تكفي لعرض ".count)), in: language)
        return language.text(
            ar: text,
            en: "The budget is not enough to offer \(name)",
            hi: "\(name) को ऑफर देने के लिए बजट पर्याप्त नहीं है",
            zh: "预算不足，无法向\(name)报价",
            ku: "بودجە بۆ پێشنیاری \(name) بەس نییە"
        )
    }

    if text.hasPrefix("نجحت المفاوضات مع ") {
        let payload = String(text.dropFirst("نجحت المفاوضات مع ".count))
        let parts = payload.components(separatedBy: " | عقد ")
        if parts.count == 2 {
            let name = localizedDisplayName(parts[0], in: language)
            let years = parts[1].replacingOccurrences(of: " سنوات", with: "")
            return language.text(
                ar: text,
                en: "Negotiations with \(name) succeeded | \(years)-year contract",
                hi: "\(name) के साथ बातचीत सफल रही | \(years) साल का अनुबंध",
                zh: "与\(name)谈判成功 | \(years)年合同",
                ku: "دانوستان لەگەڵ \(name) سەرکەوتوو بوو | گرێبەستی \(years) ساڵ"
            )
        }
    }

    if text.hasPrefix("فشلت المفاوضات مع "), text.contains("، اللاعب رفض العرض") {
        let name = localizedDisplayName(
            text
                .replacingOccurrences(of: "فشلت المفاوضات مع ", with: "")
                .replacingOccurrences(of: "، اللاعب رفض العرض", with: ""),
            in: language
        )
        return language.text(
            ar: text,
            en: "Negotiations with \(name) failed, the player rejected the offer",
            hi: "\(name) के साथ बातचीत असफल रही, खिलाड़ी ने ऑफर ठुकरा दिया",
            zh: "与\(name)谈判失败，球员拒绝了报价",
            ku: "دانوستان لەگەڵ \(name) سەرکەوتوو نەبوو، یاریزانەکە پێشنیارەکە ڕەتکردەوە"
        )
    }

    return localizedDisplayText(text, in: language)
}

private struct SyntheticBadgeStyle {
    let start: Color
    let end: Color
    let accent: Color
    let pattern: Int
    let symbol: String
}

private func normalizedTeamKey(_ name: String) -> String {
    name
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
}

private let syntheticBadgePalettes: [(start: Color, end: Color, accent: Color)] = [
    (Color(hex: 0x1F8A70), Color(hex: 0x0E3B43), Color(hex: 0xB8FFDB)),
    (Color(hex: 0xEF476F), Color(hex: 0x7E1F45), Color(hex: 0xFFD2DE)),
    (Color(hex: 0x3A86FF), Color(hex: 0x1D2D8C), Color(hex: 0xC8DAFF)),
    (Color(hex: 0xFF9F1C), Color(hex: 0x8D4A0E), Color(hex: 0xFFE0B0)),
    (Color(hex: 0x6A4C93), Color(hex: 0x2F1B54), Color(hex: 0xDAC8FF)),
    (Color(hex: 0x06D6A0), Color(hex: 0x0B5A5E), Color(hex: 0xBAFFE8))
]

private func teamBadgeSeed(_ teamName: String) -> Int {
    normalizedTeamKey(teamName).unicodeScalars.reduce(0) { partial, scalar in
        ((partial * 33) + Int(scalar.value)) & 0x7fffffff
    }
}

private func syntheticBadgeStyle(for teamName: String) -> SyntheticBadgeStyle {
    let seed = teamBadgeSeed(teamName)
    let palette = syntheticBadgePalettes[seed % syntheticBadgePalettes.count]
    let symbols = ["sparkles", "bolt.fill", "flame.fill", "star.fill", "shield.fill"]

    return SyntheticBadgeStyle(
        start: palette.start,
        end: palette.end,
        accent: palette.accent,
        pattern: seed % 5,
        symbol: symbols[(seed / syntheticBadgePalettes.count) % symbols.count]
    )
}

private struct CrestShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let w = rect.width
            let h = rect.height

            path.move(to: CGPoint(x: 0.18 * w, y: 0.08 * h))
            path.addQuadCurve(
                to: CGPoint(x: 0.82 * w, y: 0.08 * h),
                control: CGPoint(x: 0.50 * w, y: -0.02 * h)
            )
            path.addLine(to: CGPoint(x: 0.90 * w, y: 0.44 * h))
            path.addQuadCurve(
                to: CGPoint(x: 0.50 * w, y: 0.96 * h),
                control: CGPoint(x: 0.84 * w, y: 0.80 * h)
            )
            path.addQuadCurve(
                to: CGPoint(x: 0.10 * w, y: 0.44 * h),
                control: CGPoint(x: 0.16 * w, y: 0.80 * h)
            )
            path.closeSubpath()
        }
    }
}

private struct VMarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let w = rect.width
            let h = rect.height
            path.move(to: CGPoint(x: 0.10 * w, y: 0.18 * h))
            path.addLine(to: CGPoint(x: 0.50 * w, y: 0.78 * h))
            path.addLine(to: CGPoint(x: 0.90 * w, y: 0.18 * h))
            path.addLine(to: CGPoint(x: 0.72 * w, y: 0.18 * h))
            path.addLine(to: CGPoint(x: 0.50 * w, y: 0.52 * h))
            path.addLine(to: CGPoint(x: 0.28 * w, y: 0.18 * h))
            path.closeSubpath()
        }
    }
}

@MainActor
private final class ClubLogoStore: ObservableObject {
    enum ImportError: Error {
        case unsupportedSelection
        case cannotReadSelection
        case invalidZipArchive
        case noValidImages
        case downloadFailed
        case forbiddenRequest
        case resourceNotFound
        case networkFailure
        case decodingFailed
        case invalidImageData
        case invalidManifest
    }

    private struct ZipCentralDirectoryEntry {
        let fileName: String
        let compressionMethod: UInt16
        let compressedSize: UInt32
        let uncompressedSize: UInt32
        let localHeaderOffset: UInt32
    }

    private struct RemoteLogosManifest: Decodable {
        let clubs: [String: String]

        private enum CodingKeys: String, CodingKey {
            case clubs
            case teams
            case logos
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            if let clubs = try container.decodeIfPresent([String: String].self, forKey: .clubs), !clubs.isEmpty {
                self.clubs = clubs
                return
            }

            if let teams = try container.decodeIfPresent([String: String].self, forKey: .teams), !teams.isEmpty {
                self.clubs = teams
                return
            }

            if let logos = try container.decodeIfPresent([String: String].self, forKey: .logos), !logos.isEmpty {
                self.clubs = logos
                return
            }

            if let rootDictionary = try? decoder.singleValueContainer().decode([String: String].self), !rootDictionary.isEmpty {
                self.clubs = rootDictionary
                return
            }

            self.clubs = [:]
        }
    }

    private struct RemoteLogoCacheEntry: Codable {
        let sourceURL: String
        let etag: String?
        let lastModified: String?
        let fileExtension: String
    }

    static let shared = ClubLogoStore()

    @Published private(set) var refreshToken = UUID()
    @Published private(set) var importedLogoCount = 0

    private let fileManager = FileManager.default
    private let supportedImageExtensions = ["png", "jpg", "jpeg"]
    private let preferredPackFolderName = "club_logos_pack"
    private let preferredPackZipName = "club_logos_pack.zip"
#if canImport(UIKit)
    private var imageCache: [String: UIImage] = [:]
#endif

    private init() {
        _ = try? ensureLogosDirectory()
        ensureDefaultLogoFileIfNeeded()
        importedLogoCount = countStoredCustomLogos()
        _ = prepareImportsDirectoryForPicker()
    }

    @discardableResult
    func prepareImportsDirectoryForPicker() -> URL? {
        guard let importsDirectory = appImportsDirectoryURL() else { return nil }
        seedKnownPackIfNeeded(into: importsDirectory)
        return importsDirectory
    }

    func localImportPackURL() -> URL? {
        guard let importsDirectory = prepareImportsDirectoryForPicker() else { return nil }

        let zipURL = importsDirectory.appendingPathComponent(preferredPackZipName, isDirectory: false)
        if fileManager.fileExists(atPath: zipURL.path) {
            return zipURL
        }

        let folderCandidates = [
            importsDirectory.appendingPathComponent(preferredPackFolderName, isDirectory: true),
            importsDirectory.appendingPathComponent("club_logos_pack 2", isDirectory: true),
            importsDirectory.appendingPathComponent("logos", isDirectory: true)
        ]

        for folderURL in folderCandidates where directoryExists(folderURL) {
            return folderURL
        }

        return nil
    }

    func importFromPickedItem(_ pickedURL: URL) async throws -> Int {
        let scopedAccessGranted = pickedURL.startAccessingSecurityScopedResource()
        defer {
            if scopedAccessGranted {
                pickedURL.stopAccessingSecurityScopedResource()
            }
        }

        let tempRoot = fileManager.temporaryDirectory.appendingPathComponent("club-logo-import-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempRoot) }

        let sourceDirectory: URL
        if pickedURL.hasDirectoryPath {
            sourceDirectory = pickedURL
        } else if pickedURL.pathExtension.lowercased() == "zip" {
            let extractedDirectory = tempRoot.appendingPathComponent("unzipped", isDirectory: true)
            try fileManager.createDirectory(at: extractedDirectory, withIntermediateDirectories: true)

            let archiveData: Data
            do {
                archiveData = try Data(contentsOf: pickedURL, options: .mappedIfSafe)
            } catch {
                throw ImportError.cannotReadSelection
            }

            try extractZipArchive(archiveData, to: extractedDirectory)
            sourceDirectory = extractedDirectory
        } else {
            throw ImportError.unsupportedSelection
        }

        let sourceLogosDirectory = try resolveLogoDirectory(from: sourceDirectory)
        let imageFiles = try imageFilesRecursively(in: sourceLogosDirectory)
        guard !imageFiles.isEmpty else {
            throw ImportError.noValidImages
        }

        let destinationDirectory = try ensureLogosDirectory()
        _ = try clearStoredLogos(in: destinationDirectory, preserveDefault: false)

        var importedCount = 0
        for imageURL in imageFiles {
            let imageExtension = imageURL.pathExtension.lowercased()
            guard supportedImageExtensions.contains(imageExtension) else { continue }

            let sourceBaseName = imageURL.deletingPathExtension().lastPathComponent
            let normalizedBaseName = normalizedLogoKey(from: sourceBaseName)
            guard !normalizedBaseName.isEmpty else { continue }

            let destinationURL = destinationDirectory.appendingPathComponent("\(normalizedBaseName).\(imageExtension)")
            if fileManager.fileExists(atPath: destinationURL.path) {
                try? fileManager.removeItem(at: destinationURL)
            }

            do {
                try fileManager.copyItem(at: imageURL, to: destinationURL)
                importedCount += 1
            } catch {
                continue
            }
        }

        guard importedCount > 0 else {
            throw ImportError.noValidImages
        }

        ensureDefaultLogoFileIfNeeded()
#if canImport(UIKit)
        imageCache.removeAll()
#endif
        importedLogoCount = countStoredCustomLogos()
        refreshToken = UUID()
        return importedCount
    }

    func fetchRemoteManifest(from manifestURL: URL) async throws -> [RemoteLogoDownloadItem] {
        let resolvedManifestURL = normalizedRawGitHubURL(from: manifestURL) ?? manifestURL
        logLogoSyncDebug("manifest url: \(resolvedManifestURL.absoluteString)")

        var request = URLRequest(url: resolvedManifestURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let data: Data
        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                logLogoSyncDebug("manifest failure: invalid HTTP response")
                throw ImportError.downloadFailed
            }

            logLogoSyncDebug("manifest status: \(http.statusCode)")

            guard (200...299).contains(http.statusCode) else {
                let snippet = responseSnippet(from: responseData)
                if !snippet.isEmpty {
                    logLogoSyncDebug("manifest failure payload: \(snippet)")
                }

                switch http.statusCode {
                case 403:
                    throw ImportError.forbiddenRequest
                case 404:
                    throw ImportError.resourceNotFound
                default:
                    throw ImportError.downloadFailed
                }
            }
            data = responseData
        } catch let importError as ImportError {
            throw importError
        } catch {
            logLogoSyncDebug("manifest network error: \(type(of: error)) - \(error.localizedDescription)")
            throw ImportError.networkFailure
        }

        let manifest: RemoteLogosManifest
        do {
            manifest = try JSONDecoder().decode(RemoteLogosManifest.self, from: data)
        } catch {
            logLogoSyncDebug("manifest decoding error: \(type(of: error)) - \(error.localizedDescription)")
            let snippet = responseSnippet(from: data)
            if !snippet.isEmpty {
                logLogoSyncDebug("manifest decoding payload: \(snippet)")
            }
            throw ImportError.decodingFailed
        }

        var items: [RemoteLogoDownloadItem] = []
        for (clubName, urlString) in manifest.clubs {
            let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let parsedURL = URL(string: trimmedURL) else { continue }
            let remoteURL = normalizedRawGitHubURL(from: parsedURL) ?? parsedURL
            let fileName = remoteURL.lastPathComponent.isEmpty ? "\(normalizedLogoKey(from: clubName)).png" : remoteURL.lastPathComponent
            items.append(
                RemoteLogoDownloadItem(
                    id: normalizedLogoKey(from: clubName),
                    clubName: clubName,
                    fileName: fileName,
                    remoteURL: remoteURL
                )
            )
        }

        let filtered = items.filter { !$0.id.isEmpty }
        guard !filtered.isEmpty else { throw ImportError.invalidManifest }
        return filtered.sorted { $0.clubName.localizedCaseInsensitiveCompare($1.clubName) == .orderedAscending }
    }

    func importFromRemotePack(_ items: [RemoteLogoDownloadItem]) async throws -> Int {
        guard !items.isEmpty else { throw ImportError.noValidImages }

        let destinationDirectory = try ensureLogosDirectory()
        var cache = loadRemoteLogoCache()
        var activeKeys = Set<String>()
        var importedCount = 0

        for item in items {
            let normalizedBaseName = normalizedLogoKey(from: item.clubName)
            guard !normalizedBaseName.isEmpty else { continue }
            activeKeys.insert(normalizedBaseName)

            let resolvedRemoteURL = normalizedRawGitHubURL(from: item.remoteURL) ?? item.remoteURL
            logLogoSyncDebug("logo url [\(item.clubName)]: \(resolvedRemoteURL.absoluteString)")

            let urlExtension = resolvedRemoteURL.pathExtension.lowercased()
            let fileNameExtension = URL(fileURLWithPath: item.fileName).pathExtension.lowercased()
            let finalExtension = supportedImageExtensions.contains(urlExtension)
                ? urlExtension
                : (supportedImageExtensions.contains(fileNameExtension) ? fileNameExtension : "png")

            let cacheEntry = cache[normalizedBaseName]
            var request = URLRequest(url: resolvedRemoteURL)
            request.cachePolicy = .reloadIgnoringLocalCacheData

            if cacheEntry?.sourceURL == resolvedRemoteURL.absoluteString {
                if let etag = cacheEntry?.etag {
                    request.setValue(etag, forHTTPHeaderField: "If-None-Match")
                }
                if let lastModified = cacheEntry?.lastModified {
                    request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
                }
            }

            let statusCode: Int
            let responseData: Data
            let responseHeaders: [AnyHashable: Any]
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    logLogoSyncDebug("logo failure [\(item.clubName)]: invalid HTTP response")
                    throw ImportError.downloadFailed
                }
                statusCode = http.statusCode
                responseData = data
                responseHeaders = http.allHeaderFields
                logLogoSyncDebug("logo status [\(item.clubName)]: \(statusCode)")
            } catch let importError as ImportError {
                throw importError
            } catch {
                logLogoSyncDebug("logo network error [\(item.clubName)]: \(type(of: error)) - \(error.localizedDescription)")
                throw ImportError.networkFailure
            }

            if statusCode == 304 {
                if logoURL(forKey: normalizedBaseName) != nil {
                    importedCount += 1
                    continue
                }
                throw ImportError.downloadFailed
            }

            guard (200...299).contains(statusCode) else {
                let snippet = responseSnippet(from: responseData)
                if !snippet.isEmpty {
                    logLogoSyncDebug("logo failure payload [\(item.clubName)]: \(snippet)")
                }

                switch statusCode {
                case 403:
                    throw ImportError.forbiddenRequest
                case 404:
                    throw ImportError.resourceNotFound
                default:
                    throw ImportError.downloadFailed
                }
            }

            guard !responseData.isEmpty else {
                throw ImportError.invalidImageData
            }

#if canImport(UIKit)
            guard UIImage(data: responseData) != nil else {
                let snippet = responseSnippet(from: responseData)
                if !snippet.isEmpty {
                    logLogoSyncDebug("logo decoding failure payload [\(item.clubName)]: \(snippet)")
                }
                throw ImportError.invalidImageData
            }
#endif

            removeStoredLogoFiles(forKey: normalizedBaseName, in: destinationDirectory)
            let destinationURL = destinationDirectory.appendingPathComponent("\(normalizedBaseName).\(finalExtension)")
            do {
                try responseData.write(to: destinationURL, options: .atomic)
            } catch {
                throw ImportError.cannotReadSelection
            }

            let etag = responseHeaders.first { String(describing: $0.key).lowercased() == "etag" }?.value as? String
            let lastModified = responseHeaders.first { String(describing: $0.key).lowercased() == "last-modified" }?.value as? String

            cache[normalizedBaseName] = RemoteLogoCacheEntry(
                sourceURL: resolvedRemoteURL.absoluteString,
                etag: etag,
                lastModified: lastModified,
                fileExtension: finalExtension
            )
            importedCount += 1
        }

        guard importedCount > 0 else {
            throw ImportError.noValidImages
        }

        let existingFiles = (try? fileManager.contentsOfDirectory(
            at: destinationDirectory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        for fileURL in existingFiles {
            let ext = fileURL.pathExtension.lowercased()
            guard supportedImageExtensions.contains(ext) else { continue }
            let baseName = fileURL.deletingPathExtension().lastPathComponent.lowercased()
            if baseName == "default_logo" { continue }
            if !activeKeys.contains(baseName) {
                try? fileManager.removeItem(at: fileURL)
            }
        }

        cache = cache.filter { activeKeys.contains($0.key) }
        saveRemoteLogoCache(cache)

        ensureDefaultLogoFileIfNeeded()
#if canImport(UIKit)
        imageCache.removeAll()
#endif
        importedLogoCount = countStoredCustomLogos()
        refreshToken = UUID()
        return importedCount
    }

    func deleteImportedLogos() throws -> Int {
        let destinationDirectory = try ensureLogosDirectory()
        let removedCount = try clearStoredLogos(in: destinationDirectory, preserveDefault: true)
        ensureDefaultLogoFileIfNeeded()
#if canImport(UIKit)
        imageCache.removeAll()
#endif
        importedLogoCount = countStoredCustomLogos()
        refreshToken = UUID()
        return removedCount
    }

    func applyLocalFallbackPlaceholders() {
        ensureDefaultLogoFileIfNeeded()
#if canImport(UIKit)
        imageCache.removeAll()
#endif
        importedLogoCount = countStoredCustomLogos()
        refreshToken = UUID()
    }

    func preferredPickerStartDirectory() -> URL? {
        if let preparedImports = prepareImportsDirectoryForPicker() {
            return preparedImports
        }

        let searchDirectories = candidateImportDirectories()
        let expectedNames = ["club_logos_pack.zip", "club_logos_pack", "club_logos_pack 2", "logos"]

        for directory in searchDirectories {
            for expectedName in expectedNames {
                let candidate = directory.appendingPathComponent(expectedName)
                if fileManager.fileExists(atPath: candidate.path) {
                    return directory
                }
            }
        }

        if let iCloudDocs = iCloudDocumentsDirectory() {
            return iCloudDocs
        }
        return appImportsDirectoryURL()
    }

    func appImportsDirectoryURL() -> URL? {
        try? ensureAppImportsDirectory()
    }

#if canImport(UIKit)
    func image(forTeam teamName: String) -> UIImage? {
        _ = refreshToken

        let key = normalizedLogoKey(from: teamName)
        if let cached = imageCache[key] {
            return cached
        }

        if !key.isEmpty, let logoURL = logoURL(forKey: key), let logoImage = UIImage(contentsOfFile: logoURL.path) {
            imageCache[key] = logoImage
            return logoImage
        }

        if let defaultImage = defaultLogoImage() {
            imageCache[key] = defaultImage
            return defaultImage
        }

        return nil
    }
#endif

    private func resolveLogoDirectory(from rootDirectory: URL) throws -> URL {
        if try containsSupportedImages(in: rootDirectory) {
            return rootDirectory
        }

        let directLogosDirectory = rootDirectory.appendingPathComponent("logos", isDirectory: true)
        if directoryExists(directLogosDirectory), try containsSupportedImages(in: directLogosDirectory) {
            return directLogosDirectory
        }

        if let nestedLogosDirectory = try findNestedLogosDirectory(in: rootDirectory) {
            return nestedLogosDirectory
        }

        throw ImportError.noValidImages
    }

    private func findNestedLogosDirectory(in rootDirectory: URL) throws -> URL? {
        guard let enumerator = fileManager.enumerator(
            at: rootDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        for case let candidateURL as URL in enumerator {
            guard candidateURL.lastPathComponent.lowercased() == "logos" else { continue }
            if directoryExists(candidateURL), try containsSupportedImages(in: candidateURL) {
                return candidateURL
            }
        }

        return nil
    }

    private func containsSupportedImages(in directory: URL) throws -> Bool {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return false
        }

        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            guard supportedImageExtensions.contains(ext) else { continue }
            let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey])
            if values?.isRegularFile == true {
                return true
            }
        }

        return false
    }

    private func imageFilesRecursively(in directory: URL) throws -> [URL] {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var files: [URL] = []
        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            guard supportedImageExtensions.contains(ext) else { continue }
            let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey])
            if values?.isRegularFile == true {
                files.append(fileURL)
            }
        }
        return files
    }

    private func clearStoredLogos(in directory: URL, preserveDefault: Bool) throws -> Int {
        let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
        var removedCount = 0
        for fileURL in files {
            let ext = fileURL.pathExtension.lowercased()
            let baseName = fileURL.deletingPathExtension().lastPathComponent.lowercased()
            let shouldPreserve = preserveDefault && baseName == "default_logo"
            if supportedImageExtensions.contains(ext) && !shouldPreserve {
                try? fileManager.removeItem(at: fileURL)
                removedCount += 1
            }
        }
        return removedCount
    }

    private func ensureLogosDirectory() throws -> URL {
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let logosDirectory = appSupport.appendingPathComponent("logos", isDirectory: true)
        if !fileManager.fileExists(atPath: logosDirectory.path) {
            try fileManager.createDirectory(at: logosDirectory, withIntermediateDirectories: true)
        }
        return logosDirectory
    }

    private func remoteLogoCacheFileURL() throws -> URL {
        try ensureLogosDirectory().appendingPathComponent("remote_logo_cache.json", isDirectory: false)
    }

    private func loadRemoteLogoCache() -> [String: RemoteLogoCacheEntry] {
        guard let cacheURL = try? remoteLogoCacheFileURL() else { return [:] }
        guard let data = try? Data(contentsOf: cacheURL) else { return [:] }
        return (try? JSONDecoder().decode([String: RemoteLogoCacheEntry].self, from: data)) ?? [:]
    }

    private func saveRemoteLogoCache(_ cache: [String: RemoteLogoCacheEntry]) {
        guard let cacheURL = try? remoteLogoCacheFileURL() else { return }
        guard let data = try? JSONEncoder().encode(cache) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }

    private func directoryExists(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return false
        }
        return isDirectory.boolValue
    }

    private func logoURL(forKey key: String) -> URL? {
        guard !key.isEmpty else { return nil }
        guard let logosDirectory = try? ensureLogosDirectory() else { return nil }
        for ext in supportedImageExtensions {
            let candidate = logosDirectory.appendingPathComponent("\(key).\(ext)")
            if fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }

    private func removeStoredLogoFiles(forKey key: String, in directory: URL) {
        guard !key.isEmpty else { return }
        for ext in supportedImageExtensions {
            let candidate = directory.appendingPathComponent("\(key).\(ext)")
            if fileManager.fileExists(atPath: candidate.path) {
                try? fileManager.removeItem(at: candidate)
            }
        }
    }

    private func countStoredCustomLogos() -> Int {
        guard let logosDirectory = try? ensureLogosDirectory() else { return 0 }
        let files = (try? fileManager.contentsOfDirectory(at: logosDirectory, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])) ?? []
        return files.reduce(into: 0) { count, fileURL in
            let ext = fileURL.pathExtension.lowercased()
            let baseName = fileURL.deletingPathExtension().lastPathComponent.lowercased()
            if supportedImageExtensions.contains(ext) && baseName != "default_logo" {
                count += 1
            }
        }
    }

    private func ensureAppImportsDirectory() throws -> URL {
        let documents = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let imports = documents.appendingPathComponent("Imports", isDirectory: true)
        let logos = imports.appendingPathComponent("Logos", isDirectory: true)
        try fileManager.createDirectory(at: logos, withIntermediateDirectories: true)
        return logos
    }

    private func seedKnownPackIfNeeded(into importsDirectory: URL) {
        let expectedFolder = importsDirectory.appendingPathComponent(preferredPackFolderName, isDirectory: true)
        let expectedZip = importsDirectory.appendingPathComponent(preferredPackZipName, isDirectory: false)

        if fileManager.fileExists(atPath: expectedFolder.path) || fileManager.fileExists(atPath: expectedZip.path) {
            return
        }

        for source in knownPackSourceCandidates() {
            let path = source.path
            if path.isEmpty || !fileManager.fileExists(atPath: path) {
                continue
            }

            if directoryExists(source) {
                do {
                    try fileManager.copyItem(at: source, to: expectedFolder)
                    return
                } catch {
                    continue
                }
            }

            if source.pathExtension.lowercased() == "zip" {
                do {
                    try fileManager.copyItem(at: source, to: expectedZip)
                    return
                } catch {
                    continue
                }
            }
        }
    }

    private func knownPackSourceCandidates() -> [URL] {
        var candidates: [URL] = []

        if let bundleZip = Bundle.main.url(forResource: "club_logos_pack", withExtension: "zip") {
            candidates.append(bundleZip)
        }

        if let bundleFolder = Bundle.main.url(forResource: preferredPackFolderName, withExtension: nil) {
            candidates.append(bundleFolder)
        }

        if let legacyBundleFolder = Bundle.main.url(forResource: "club_logos_pack 2", withExtension: nil) {
            candidates.append(legacyBundleFolder)
        }

        if let documents = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            candidates.append(documents.appendingPathComponent(preferredPackZipName, isDirectory: false))
            candidates.append(documents.appendingPathComponent(preferredPackFolderName, isDirectory: true))
            candidates.append(documents.appendingPathComponent("club_logos_pack 2", isDirectory: true))
            candidates.append(documents.appendingPathComponent("club_logos_pack", isDirectory: true))
            candidates.append(documents.appendingPathComponent("logos", isDirectory: true))
        }

        if let iCloudDocs = iCloudDocumentsDirectory() {
            candidates.append(iCloudDocs.appendingPathComponent(preferredPackZipName, isDirectory: false))
            candidates.append(iCloudDocs.appendingPathComponent(preferredPackFolderName, isDirectory: true))
            candidates.append(iCloudDocs.appendingPathComponent("club_logos_pack 2", isDirectory: true))
            candidates.append(iCloudDocs.appendingPathComponent("club_logos_pack", isDirectory: true))
            candidates.append(iCloudDocs.appendingPathComponent("logos", isDirectory: true))
        }

#if targetEnvironment(simulator)
        let desktop = URL(fileURLWithPath: "/Users/\(NSUserName())/Desktop", isDirectory: true)
        candidates.append(desktop.appendingPathComponent(preferredPackZipName, isDirectory: false))
        candidates.append(desktop.appendingPathComponent(preferredPackFolderName, isDirectory: true))
        candidates.append(desktop.appendingPathComponent("club_logos_pack 2", isDirectory: true))
        candidates.append(desktop.appendingPathComponent("club_logos_pack", isDirectory: true))
        candidates.append(desktop.appendingPathComponent("logos", isDirectory: true))
#endif

        var unique: [URL] = []
        var seen = Set<String>()
        for candidate in candidates {
            if seen.insert(candidate.path).inserted {
                unique.append(candidate)
            }
        }
        return unique
    }

    private func iCloudDocumentsDirectory() -> URL? {
        guard let ubiquity = fileManager.url(forUbiquityContainerIdentifier: nil) else { return nil }
        let iCloudDocs = ubiquity.appendingPathComponent("Documents", isDirectory: true)
        if !fileManager.fileExists(atPath: iCloudDocs.path) {
            try? fileManager.createDirectory(at: iCloudDocs, withIntermediateDirectories: true)
        }
        return iCloudDocs
    }

    private func candidateImportDirectories() -> [URL] {
        var dirs: [URL] = []

        if let iCloudDocs = iCloudDocumentsDirectory() {
            dirs.append(iCloudDocs)
        }

        if let documents = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            dirs.append(documents)
            dirs.append(documents.appendingPathComponent("Inbox", isDirectory: true))
        }

        if let appImports = appImportsDirectoryURL() {
            dirs.append(appImports)
        }

        var seen = Set<String>()
        return dirs.filter { seen.insert($0.path).inserted }
    }

#if canImport(UIKit)
    private func defaultLogoImage() -> UIImage? {
        if let cachedDefault = imageCache["default_logo"] {
            return cachedDefault
        }

        if let fileDefault = logoURL(forKey: "default_logo"), let image = UIImage(contentsOfFile: fileDefault.path) {
            imageCache["default_logo"] = image
            return image
        }

        if let bundled = UIImage(named: "default_logo") {
            imageCache["default_logo"] = bundled
            return bundled
        }

        if let generated = generatedDefaultLogoImage() {
            imageCache["default_logo"] = generated
            return generated
        }

        return nil
    }

    private func ensureDefaultLogoFileIfNeeded() {
        guard logoURL(forKey: "default_logo") == nil else { return }
        guard let logosDirectory = try? ensureLogosDirectory() else { return }
        guard let generated = generatedDefaultLogoImage(), let pngData = generated.pngData() else { return }

        let destination = logosDirectory.appendingPathComponent("default_logo.png")
        try? pngData.write(to: destination, options: .atomic)
    }

    private func generatedDefaultLogoImage() -> UIImage? {
        let canvas = CGSize(width: 240, height: 240)
        let renderer = UIGraphicsImageRenderer(size: canvas)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: canvas)

            let colors = [UIColor(red: 0.07, green: 0.17, blue: 0.38, alpha: 1.0).cgColor, UIColor(red: 0.10, green: 0.50, blue: 0.82, alpha: 1.0).cgColor]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0]) {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: canvas.width, y: canvas.height),
                    options: []
                )
            }

            let badgeRect = rect.insetBy(dx: 24, dy: 24)
            let shieldPath = UIBezierPath(
                roundedRect: badgeRect,
                byRoundingCorners: [.topLeft, .topRight, .bottomLeft, .bottomRight],
                cornerRadii: CGSize(width: 42, height: 42)
            )
            UIColor.white.withAlphaComponent(0.16).setFill()
            shieldPath.fill()

            let config = UIImage.SymbolConfiguration(pointSize: 84, weight: .black)
            let symbol = UIImage(systemName: "shield.fill", withConfiguration: config)
            let symbolRect = CGRect(x: 70, y: 66, width: 100, height: 108)
            symbol?.withTintColor(.white.withAlphaComponent(0.92), renderingMode: .alwaysOriginal).draw(in: symbolRect)
        }
    }
#else
    private func ensureDefaultLogoFileIfNeeded() {}
#endif

    private func normalizedLogoKey(from rawName: String) -> String {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        let compact = trimmed
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")

        if compact == "defaultlogo" {
            return "default_logo"
        }

        let englishCandidate = englishDisplayNames[trimmed] ?? trimmed
        let latinCandidate = englishCandidate.applyingTransform(.toLatin, reverse: false) ?? englishCandidate
        var normalized = latinCandidate
            .folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
            .replacingOccurrences(of: "&", with: "and")

        let filteredScalars = normalized.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }
        normalized = String(String.UnicodeScalarView(filteredScalars))

        if normalized == "defaultlogo" {
            return "default_logo"
        }

        return normalized
    }

    private func normalizedRawGitHubURL(from url: URL) -> URL? {
        guard let host = url.host?.lowercased() else { return nil }
        if host == "raw.githubusercontent.com" {
            return url
        }

        guard host == "github.com" else { return nil }

        let components = url.pathComponents.filter { $0 != "/" }
        guard components.count >= 5, components[2].lowercased() == "blob" else { return nil }

        let owner = components[0]
        let repository = components[1]
        let branch = components[3]
        let filePath = components.dropFirst(4).joined(separator: "/")
        guard !filePath.isEmpty else { return nil }

        var rawComponents = URLComponents()
        rawComponents.scheme = "https"
        rawComponents.host = "raw.githubusercontent.com"
        rawComponents.path = "/\(owner)/\(repository)/\(branch)/\(filePath)"
        return rawComponents.url
    }

    private func responseSnippet(from data: Data, maxLength: Int = 220) -> String {
        guard !data.isEmpty else { return "" }

        if let utf8Text = String(data: data, encoding: .utf8) {
            let compact = utf8Text.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "\r", with: " ")
            return String(compact.prefix(maxLength))
        }

        if let asciiText = String(data: data, encoding: .ascii) {
            let compact = asciiText.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "\r", with: " ")
            return String(compact.prefix(maxLength))
        }

        return "<binary \(data.count) bytes>"
    }

    private func logLogoSyncDebug(_ message: String) {
#if DEBUG
        print("[LogoSync] \(message)")
#endif
    }

    private func extractZipArchive(_ archiveData: Data, to destinationDirectory: URL) throws {
        let entries = try parseZipCentralDirectory(archiveData)
        guard !entries.isEmpty else {
            throw ImportError.invalidZipArchive
        }

        for entry in entries {
            try extractZipEntry(entry, from: archiveData, into: destinationDirectory)
        }
    }

    private func parseZipCentralDirectory(_ archiveData: Data) throws -> [ZipCentralDirectoryEntry] {
        guard let endOffset = endOfCentralDirectoryOffset(in: archiveData) else {
            throw ImportError.invalidZipArchive
        }

        guard let entryCount = readUInt16LE(from: archiveData, at: endOffset + 10),
              let centralDirectoryOffset = readUInt32LE(from: archiveData, at: endOffset + 16) else {
            throw ImportError.invalidZipArchive
        }

        var entries: [ZipCentralDirectoryEntry] = []
        var cursor = Int(centralDirectoryOffset)

        for _ in 0..<Int(entryCount) {
            guard readUInt32LE(from: archiveData, at: cursor) == 0x02014b50 else {
                throw ImportError.invalidZipArchive
            }

            guard let compressionMethod = readUInt16LE(from: archiveData, at: cursor + 10),
                  let compressedSize = readUInt32LE(from: archiveData, at: cursor + 20),
                  let uncompressedSize = readUInt32LE(from: archiveData, at: cursor + 24),
                  let fileNameLength = readUInt16LE(from: archiveData, at: cursor + 28),
                  let extraLength = readUInt16LE(from: archiveData, at: cursor + 30),
                  let commentLength = readUInt16LE(from: archiveData, at: cursor + 32),
                  let localHeaderOffset = readUInt32LE(from: archiveData, at: cursor + 42) else {
                throw ImportError.invalidZipArchive
            }

            let nameStart = cursor + 46
            let nameEnd = nameStart + Int(fileNameLength)
            guard nameEnd <= archiveData.count else {
                throw ImportError.invalidZipArchive
            }

            let nameData = archiveData.subdata(in: nameStart..<nameEnd)
            let decodedName = String(data: nameData, encoding: .utf8)
                ?? String(data: nameData, encoding: .isoLatin1)
                ?? ""

            entries.append(
                ZipCentralDirectoryEntry(
                    fileName: decodedName,
                    compressionMethod: compressionMethod,
                    compressedSize: compressedSize,
                    uncompressedSize: uncompressedSize,
                    localHeaderOffset: localHeaderOffset
                )
            )

            cursor = nameEnd + Int(extraLength) + Int(commentLength)
        }

        return entries
    }

    private func extractZipEntry(_ entry: ZipCentralDirectoryEntry, from archiveData: Data, into destinationDirectory: URL) throws {
        guard !entry.fileName.isEmpty else { return }
        guard !entry.fileName.hasPrefix("__MACOSX/") else { return }
        guard !entry.fileName.hasSuffix("/") else { return }

        let pathComponents = entry.fileName.split(separator: "/").map(String.init)
        guard !pathComponents.isEmpty else { return }
        guard !pathComponents.contains("..") else { return }

        let localHeaderStart = Int(entry.localHeaderOffset)
        guard readUInt32LE(from: archiveData, at: localHeaderStart) == 0x04034b50 else {
            throw ImportError.invalidZipArchive
        }

        guard let localNameLength = readUInt16LE(from: archiveData, at: localHeaderStart + 26),
              let localExtraLength = readUInt16LE(from: archiveData, at: localHeaderStart + 28) else {
            throw ImportError.invalidZipArchive
        }

        let compressedDataStart = localHeaderStart + 30 + Int(localNameLength) + Int(localExtraLength)
        let compressedDataEnd = compressedDataStart + Int(entry.compressedSize)
        guard compressedDataStart >= 0, compressedDataEnd <= archiveData.count else {
            throw ImportError.invalidZipArchive
        }

        let compressedData = archiveData.subdata(in: compressedDataStart..<compressedDataEnd)
        let extractedData: Data
        switch entry.compressionMethod {
        case 0:
            extractedData = compressedData
        case 8:
            extractedData = try inflateRawDeflate(compressedData, expectedSize: Int(entry.uncompressedSize))
        default:
            return
        }

        var outputDirectory = destinationDirectory
        for component in pathComponents.dropLast() {
            outputDirectory.appendPathComponent(component, isDirectory: true)
        }
        try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        let outputURL = outputDirectory.appendingPathComponent(pathComponents.last ?? "logo")
        try extractedData.write(to: outputURL, options: .atomic)
    }

    private func inflateRawDeflate(_ compressedData: Data, expectedSize: Int) throws -> Data {
        if compressedData.isEmpty {
            return Data()
        }

        var stream = z_stream()
        let initStatus = inflateInit2_(
            &stream,
            -MAX_WBITS,
            ZLIB_VERSION,
            Int32(MemoryLayout<z_stream>.size)
        )
        guard initStatus == Z_OK else {
            throw ImportError.invalidZipArchive
        }
        defer { inflateEnd(&stream) }

        var output = Data()
        let chunkSize = max(32_768, min(max(expectedSize, 32_768), 1_048_576))

        return try compressedData.withUnsafeBytes { rawBuffer in
            guard let sourcePointer = rawBuffer.baseAddress?.assumingMemoryBound(to: Bytef.self) else {
                throw ImportError.invalidZipArchive
            }

            stream.next_in = UnsafeMutablePointer<Bytef>(mutating: sourcePointer)
            stream.avail_in = uInt(compressedData.count)

            while true {
                var chunk = [UInt8](repeating: 0, count: chunkSize)
                let status = chunk.withUnsafeMutableBytes { destinationBuffer -> Int32 in
                    guard let destinationPointer = destinationBuffer.baseAddress?.assumingMemoryBound(to: Bytef.self) else {
                        return Z_DATA_ERROR
                    }
                    stream.next_out = destinationPointer
                    stream.avail_out = uInt(destinationBuffer.count)
                    return inflate(&stream, Z_NO_FLUSH)
                }

                let producedBytes = chunkSize - Int(stream.avail_out)
                if producedBytes > 0 {
                    output.append(contentsOf: chunk.prefix(producedBytes))
                }

                if status == Z_STREAM_END {
                    break
                }

                if status != Z_OK {
                    throw ImportError.invalidZipArchive
                }
            }

            return output
        }
    }

    private func endOfCentralDirectoryOffset(in archiveData: Data) -> Int? {
        guard archiveData.count >= 22 else { return nil }

        let minimumOffset = max(0, archiveData.count - 22 - 65_535)
        var cursor = archiveData.count - 22

        while cursor >= minimumOffset {
            if readUInt32LE(from: archiveData, at: cursor) == 0x06054b50 {
                return cursor
            }
            cursor -= 1
        }

        return nil
    }

    private func readUInt16LE(from data: Data, at offset: Int) -> UInt16? {
        guard offset >= 0, offset + 1 < data.count else { return nil }
        return UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }

    private func readUInt32LE(from data: Data, at offset: Int) -> UInt32? {
        guard offset >= 0, offset + 3 < data.count else { return nil }
        return UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }
}

private struct LogoImporterScreen: View {
    let language: AppLanguage
    let isManifestLoading: Bool
    let isImporting: Bool
    let statusText: String
    let statusIsSuccess: Bool
    let onClose: () -> Void
    let onDownload: () -> Void

    private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
    }


    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    FootballTheme.backgroundPrimary.opacity(0.98),
                    FootballTheme.cardBase.opacity(0.96),
                    FootballTheme.backgroundSecondary.opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
                .ignoresSafeArea()

            Circle()
                .fill(FootballTheme.cardGlow.opacity(0.18))
                .blur(radius: 50)
                .frame(width: 260, height: 260)
                .offset(x: 130, y: -280)

            Circle()
                .fill(FootballTheme.accentCyan.opacity(0.14))
                .blur(radius: 42)
                .frame(width: 240, height: 240)
                .offset(x: -140, y: 330)

            VStack(spacing: 20) {
                HStack(spacing: 12) {
                    Button(action: onClose) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.10))
                                .frame(width: 44, height: 44)

                            Image(systemName: language.layoutDirection == .rightToLeft ? "arrow.right" : "arrow.left")
                                .font(.system(size: 19, weight: .black))
                                .foregroundStyle(Color.white.opacity(0.95))
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Text(t(ar: "مركز الأندية", en: "Clubs Center", hi: "क्लब सेंटर", zh: "俱乐部中心", ku: "ناوەندی یانەکان"))
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 2)

                Spacer(minLength: 10)

                Button(action: onDownload) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.14))
                                .frame(width: 72, height: 72)

                            if isManifestLoading || isImporting {
                                ProgressView()
                                    .tint(.white)
                            } else if statusIsSuccess {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 34, weight: .black))
                                    .foregroundStyle(FootballTheme.accentGreen)
                            } else {
                                Image(systemName: "square.stack.3d.up.fill")
                                    .font(.system(size: 34, weight: .black))
                                    .foregroundStyle(FootballTheme.accentCyan)
                            }
                        }

                        Text(t(ar: "الحزمة الأساسية", en: "Core Pack", hi: "मुख्य पैक", zh: "基础包", ku: "پەکیجی سەرەکی"))
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text(t(ar: "إدارة بيانات الأندية والمحتوى", en: "Manage clubs data and content", hi: "क्लब डेटा और सामग्री प्रबंधित करें", zh: "管理俱乐部数据与内容", ku: "بەڕێوەبردنی داتای یانەکان و ناوەڕۆک"))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(FootballTheme.textSecondary.opacity(0.95))

                        Group {
                            if isManifestLoading {
                                HStack(spacing: 8) {
                                    ProgressView().tint(.white)
                                    Text(t(ar: "جاري تحديث الحزمة...", en: "Refreshing pack...", hi: "पैक अपडेट हो रहा है...", zh: "正在更新包...", ku: "پەکیج نوێ دەکرێتەوە..."))
                                }
                            } else if isImporting {
                                HStack(spacing: 8) {
                                    ProgressView().tint(.white)
                                    Text(t(ar: "جاري التحميل والتفعيل...", en: "Downloading and activating...", hi: "डाउनलोड और सक्रिय किया जा रहा है...", zh: "正在下载并启用...", ku: "لە داگرتن و چالاککردندایە..."))
                                }
                            } else if statusIsSuccess {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text(t(ar: "تم التفعيل", en: "Activated", hi: "सक्रिय हुआ", zh: "已启用", ku: "چالاککرا"))
                                }
                            } else if !statusText.isEmpty {
                                Text(statusText)
                            } else {
                                Text(t(ar: "اضغط لبدء التفعيل", en: "Tap to start activation", hi: "सक्रिय करने के लिए टैप करें", zh: "点击开始启用", ku: "بۆ دەستپێکردنی چالاککردن پەنجە بدە"))
                            }
                        }
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(
                            statusIsSuccess
                                ? FootballTheme.accentGreen
                                : (!statusText.isEmpty ? FootballTheme.dangerRed : Color.white.opacity(0.95))
                        )
                        .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 26)
                    .padding(.vertical, 34)
                    .frame(maxWidth: .infinity, minHeight: 320)
                    .background(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        FootballTheme.cardBase.opacity(0.96),
                                        FootballTheme.backgroundSecondary.opacity(0.90)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(FootballTheme.cardGlow.opacity(0.36), lineWidth: 1.2)
                    )
                    .shadow(color: FootballTheme.cardGlow.opacity(0.18), radius: 18, x: 0, y: 10)
                }
                .buttonStyle(.plain)
                .disabled(isImporting)
                .padding(.horizontal, 20)

                Spacer(minLength: 30)
            }
        }
    }
}

private struct TeamLogoView: View {
    @AppStorage("coach.downloadClubLogosEnabled") private var downloadClubLogosEnabled = false
    @ObservedObject private var logoStore = ClubLogoStore.shared
    let teamName: String
    let size: CGFloat

    var body: some View {
        let customBadge = syntheticBadgeStyle(for: teamName)
        let borderWidth = max(1, size * (downloadClubLogosEnabled ? 0.10 : 0.07))

#if canImport(UIKit)
        if let importedLogo = logoStore.image(forTeam: teamName) {
            let cornerRadius = max(8, size * 0.18)

            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(downloadClubLogosEnabled ? 0.10 : 0.06))

                Image(uiImage: importedLogo)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
                    .frame(width: size * 0.84, height: size * 0.84)
                    .padding(size * 0.08)
            }
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(downloadClubLogosEnabled ? 0.24 : 0.14), lineWidth: max(1, size * 0.026))
            )
            .shadow(color: Color.black.opacity(0.20), radius: max(2, size * 0.16), x: 0, y: max(1, size * 0.08))
        } else {
            ZStack {
                CrestShape()
                    .fill(
                        LinearGradient(
                            colors: [customBadge.start, customBadge.end],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                patternLayer(style: customBadge)
                    .clipShape(CrestShape())

                CrestShape()
                    .stroke(
                        customBadge.accent.opacity(downloadClubLogosEnabled ? 0.98 : 0.72),
                        lineWidth: borderWidth
                    )

                CrestShape()
                    .stroke(Color.white.opacity(downloadClubLogosEnabled ? 0.22 : 0.10), lineWidth: max(0.8, size * 0.02))
                    .padding(size * 0.09)
            }
            .frame(width: size, height: size)
            .shadow(color: customBadge.accent.opacity(downloadClubLogosEnabled ? 0.42 : 0.22), radius: max(2, size * 0.30), x: 0, y: max(1, size * 0.12))
        }
#else
        ZStack {
            CrestShape()
                .fill(
                    LinearGradient(
                        colors: [customBadge.start, customBadge.end],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            patternLayer(style: customBadge)
                .clipShape(CrestShape())

            CrestShape()
                .stroke(
                    customBadge.accent.opacity(downloadClubLogosEnabled ? 0.98 : 0.72),
                    lineWidth: borderWidth
                )

            CrestShape()
                .stroke(Color.white.opacity(downloadClubLogosEnabled ? 0.22 : 0.10), lineWidth: max(0.8, size * 0.02))
                .padding(size * 0.09)
        }
        .frame(width: size, height: size)
        .shadow(color: customBadge.accent.opacity(downloadClubLogosEnabled ? 0.42 : 0.22), radius: max(2, size * 0.30), x: 0, y: max(1, size * 0.12))
#endif
    }

    @ViewBuilder
    private func patternLayer(style: SyntheticBadgeStyle) -> some View {
        let strong = downloadClubLogosEnabled
        let lightOpacity = strong ? 0.30 : 0.18
        let mediumOpacity = strong ? 0.40 : 0.24

        ZStack {
            Capsule()
                .fill(Color.white.opacity(strong ? 0.18 : 0.10))
                .frame(width: size * 0.92, height: max(2, size * 0.15))
                .rotationEffect(.degrees(-18))
                .offset(y: -size * 0.18)

            switch style.pattern {
            case 0:
                HStack(spacing: size * 0.06) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: size * 0.03)
                            .fill(Color.white.opacity(lightOpacity))
                    }
                }
                .padding(.horizontal, size * 0.20)
                .frame(maxHeight: .infinity, alignment: .center)
            case 1:
                Rectangle()
                    .fill(Color.white.opacity(mediumOpacity))
                    .frame(width: size * 0.26, height: size * 1.30)
                    .rotationEffect(.degrees(-24))
                    .offset(x: -size * 0.03)
            case 2:
                HStack(spacing: 0) {
                    Rectangle().fill(Color.white.opacity(lightOpacity))
                    Rectangle().fill(Color.black.opacity(strong ? 0.12 : 0.08))
                    Rectangle().fill(Color.white.opacity(lightOpacity))
                }
                .padding(.horizontal, size * 0.18)
                .padding(.vertical, size * 0.18)
            case 3:
                VMarkShape()
                    .fill(Color.white.opacity(mediumOpacity))
                    .padding(size * 0.22)
            default:
                if strong {
                    Image(systemName: style.symbol)
                        .font(.system(size: max(6, size * 0.24), weight: .black))
                        .foregroundStyle(Color.white.opacity(0.95))
                        .padding(size * 0.20)
                        .background(Circle().fill(Color.black.opacity(0.14)))
                } else {
                    DiamondShape()
                        .fill(Color.white.opacity(mediumOpacity))
                        .padding(size * 0.32)
                }
            }
        }
    }
}

private struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let w = rect.width
            let h = rect.height
            path.move(to: CGPoint(x: 0.50 * w, y: 0.05 * h))
            path.addLine(to: CGPoint(x: 0.95 * w, y: 0.50 * h))
            path.addLine(to: CGPoint(x: 0.50 * w, y: 0.95 * h))
            path.addLine(to: CGPoint(x: 0.05 * w, y: 0.50 * h))
            path.closeSubpath()
        }
    }
}

struct ContentView: View {
    @AppStorage("coach.selectedLanguage") private var selectedLanguageRaw = AppLanguage.english.rawValue
    @AppStorage("coach.downloadClubLogosEnabled") private var downloadClubLogosEnabled = false
    @ObservedObject private var logoStore = ClubLogoStore.shared
    @State private var step: GameStep = .welcome
    @State private var selectedLeague: League?
    @State private var selectedTeam: String?
    @State private var currentTab: DashboardTab = .simulator

    @State private var showSettingsScreen = false
    @State private var showCompetitions = false
    @State private var showTodayMatchesScreen = false
    @State private var showMatchCenter = false
    @State private var showTeamRecord = false
    @State private var showLeagueStandingsSheet = false
    @State private var showTeamManagementScreen = false
    @State private var showTeamCenterScreen = false
    @State private var showTransferCenterScreen = false
    @State private var showPlayerSearch = false
    @State private var showMonthlyNews = false
    @State private var showMainMenuPlaceholderAlert = false
    @State private var mainMenuPlaceholderMessage = ""

    // Simulation state
    @State private var isSimulatingDays = false
    @State private var simulationTask: Task<Void, Never>?
    @State private var simulationDateToken = 0
    @State private var simulationMatchFocus = false

    @State private var seasonTable: [String: TeamStanding] = [:]
    @State private var matchWeek = 1
    @State private var totalWeeks = 38
    @State private var previousResult = "لم تُلعب أي مباراة بعد"
    @State private var managerNote = "اختر فريقك وابدأ الموسم"

    @State private var budgetM = 120
    @State private var fanSatisfaction = 85
    @State private var squadStrength = 74
    @State private var tacticalPlan: TacticalPlan = .fourThreeThree
    @State private var injuries = 1
    @State private var seasonTarget = "إنهاء الموسم ضمن أول 4"
    @State private var transferTargets: [TransferOption] = []
    @State private var marketPlayers: [MarketPlayer] = []
    @State private var negotiationPlayerIndex: Int?
    @State private var showNegotiationSheet = false

    @State private var leagueTitlesWon = 0
    @State private var coachOfMonthAwards = 0
    @State private var goldenBootAwards = 0
    @State private var topScorerName = "لا يوجد"
    @State private var topScorerGoals = 0
    @State private var playerSeasonGoals: [String: Int] = [:]
    @State private var achievementLog: [String] = []
    @State private var recentFormPoints: [Int] = []
    @State private var clubNewsFeed: [ClubNewsItem] = []
    @State private var teamMatchHistory: [String: [TeamMatchHistoryEntry]] = [:]

    @State private var seasonStartDate = Date()
    @State private var currentDate = Date()
    @State private var calendarDisplayDate = Date()
    @State private var contractEndDate = Calendar.current.date(byAdding: .day, value: 365, to: Date()) ?? Date()

    @State private var lineup: [TeamPlayer] = []
    @State private var bench: [TeamPlayer] = []

    @State private var selectedLiveLeague: LiveTopLeague = .championsLeague
    @State private var liveStandings: [LiveStandingRow] = []
    @State private var liveLoading = false
    @State private var liveErrorMessage = ""
    @State private var liveLastUpdated: Date?
    @State private var liveLoadedLeague: LiveTopLeague?
    private let standingsService: StandingsServiceProtocol = StandingsService()
    @State private var hasAttemptedRestore = false
    @State private var savedCareerSnapshot: GameSaveData?
    @State private var showLogoImporter = false
    @State private var remoteLogoManifestItems: [RemoteLogoDownloadItem] = []
    @State private var isImportingLogos = false
    @State private var isLoadingLogoManifest = false
    @State private var logoImporterStatusText = ""
    @State private var logoImporterStatusIsSuccess = false
    @State private var showDeleteImportedLogosConfirmation = false
    @State private var showLogoImportAlert = false
    @State private var logoImportAlertTitle = ""
    @State private var logoImportAlertMessage = ""
    private let liveAutoRefreshTimer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
    private let gameSaveKey = "coach.saved.game.v1"
    private let logosManifestURL = URL(string: "https://raw.githubusercontent.com/tvraad671-hub/logo-packs/main/logos.json")!

    private var language: AppLanguage {
        AppLanguage(rawValue: selectedLanguageRaw) ?? .english
    }

    private var appLocale: Locale {
        Locale(identifier: language.localeIdentifier)
    }

    private var selectedLanguageBinding: Binding<AppLanguage> {
        Binding(
            get: { language },
            set: { selectedLanguageRaw = $0.rawValue }
        )
    }

    private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
    }

    var body: some View {
        ZStack {
            appBackground

            content
                .padding(.horizontal, step == .welcome ? 14 : 18)
                .padding(.top, step == .welcome ? 14 : 24)
                .padding(.bottom, step == .welcome ? 14 : 8)
        }
        .fullScreenCover(isPresented: $showLogoImporter) {
            LogoImporterScreen(
                language: language,
                isManifestLoading: isLoadingLogoManifest,
                isImporting: isImportingLogos,
                statusText: logoImporterStatusText,
                statusIsSuccess: logoImporterStatusIsSuccess,
                onClose: {
                    showLogoImporter = false
                },
                onDownload: {
                    downloadCustomLogosFromServer()
                }
            )
        }
        .confirmationDialog(
            t(ar: "حذف الشعارات المستوردة", en: "Delete Imported Logos", hi: "इम्पोर्ट किए लोगो हटाएं", zh: "删除已导入队徽", ku: "سڕینەوەی شعارە هاوردەکراوەکان"),
            isPresented: $showDeleteImportedLogosConfirmation,
            titleVisibility: .visible
        ) {
            Button(t(ar: "حذف", en: "Delete", hi: "हटाएँ", zh: "删除", ku: "سڕینەوە"), role: .destructive) {
                removeImportedLogos()
            }
            Button(t(ar: "إلغاء", en: "Cancel", hi: "रद्द करें", zh: "取消", ku: "هەڵوەشاندنەوە"), role: .cancel) {}
        }
        .alert(isPresented: $showLogoImportAlert) {
            Alert(
                title: Text(logoImportAlertTitle),
                message: Text(logoImportAlertMessage),
                dismissButton: .default(Text(t(ar: "حسنًا", en: "OK", hi: "ठीक है", zh: "好的", ku: "باشە")))
            )
        }
        .alert(
            t(ar: "تنبيه", en: "Notice", hi: "सूचना", zh: "提示", ku: "ئاگاداری"),
            isPresented: $showMainMenuPlaceholderAlert
        ) {
            Button(t(ar: "حسنًا", en: "OK", hi: "ठीक है", zh: "好的", ku: "باشە"), role: .cancel) {}
        } message: {
            Text(mainMenuPlaceholderMessage)
        }
        .environment(\.layoutDirection, language.layoutDirection)
        .sheet(isPresented: $showCompetitions) {
            CompetitionsView(language: language)
        }
        .sheet(isPresented: $showTeamRecord) {
            TeamRecordView(
                language: language,
                teamName: selectedTeam ?? "",
                wins: seasonTable[selectedTeam ?? ""]?.wins ?? 0,
                losses: seasonTable[selectedTeam ?? ""]?.losses ?? 0,
                draws: seasonTable[selectedTeam ?? ""]?.draws ?? 0,
                titles: teamTitlesCount(),
                goalsFor: seasonTable[selectedTeam ?? ""]?.goalsFor ?? 0,
                goalsAgainst: seasonTable[selectedTeam ?? ""]?.goalsAgainst ?? 0,
                coachAwards: coachOfMonthAwards,
                goldenBoots: goldenBootAwards,
                topScorerName: topScorerName,
                topScorerGoals: topScorerGoals,
                achievements: achievementLog
            )
        }
        .sheet(isPresented: $showLeagueStandingsSheet) {
            LeagueStandingsSheetView(
                language: language,
                leagueDisplayName: localizedLeagueName(selectedLeague?.name ?? "", in: language),
                selectedTeam: selectedTeam,
                seasonTable: $seasonTable,
                currentWeek: matchWeek,
                totalWeeks: totalWeeks
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPlayerSearch) {
            PlayerSearchView(
                language: language,
                players: $marketPlayers,
                budgetM: budgetM,
                onNegotiatePlayer: { idx in
                    startNegotiation(for: idx)
                }
            )
        }
        .sheet(isPresented: $showNegotiationSheet) {
            if let idx = negotiationPlayerIndex, marketPlayers.indices.contains(idx) {
                ContractNegotiationView(
                    language: language,
                    player: marketPlayers[idx],
                    budgetM: budgetM,
                    onSubmit: { salaryM, years, bonusM in
                        finalizeNegotiation(for: idx, salaryM: salaryM, years: years, bonusM: bonusM)
                        showNegotiationSheet = false
                        negotiationPlayerIndex = nil
                    },
                    onCancel: {
                        showNegotiationSheet = false
                        negotiationPlayerIndex = nil
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showMatchCenter) {
            if let fixture = nextFixture(), let team = selectedTeam {
                MatchCenterView(
                    language: language,
                    teamName: team,
                    opponentName: fixture.opponent,
                    matchDate: fixture.date,
                    teamRank: rankForTeam(team),
                    opponentRank: rankForTeam(fixture.opponent),
                    teamRecentHistory: recentHistoryForMatchView(team: team),
                    opponentRecentHistory: recentHistoryForMatchView(team: fixture.opponent),
                    lineup: $lineup,
                    bench: $bench,
                    tacticalPlan: tacticalPlan,
                    squadStrength: squadStrength,
                    fanSatisfaction: fanSatisfaction,
                    onClose: { showMatchCenter = false },
                    onFinish: { myGoals, oppGoals, summary in
                        applyMatchResult(myGoals: myGoals, oppGoals: oppGoals, summary: summary)
                        showMatchCenter = false
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showTeamManagementScreen) {
            TeamManagementPortraitView(
                language: language,
                lineup: $lineup,
                bench: $bench,
                tacticalPlan: $tacticalPlan,
                onClose: {
                    showTeamManagementScreen = false
                }
            )
        }
        .fullScreenCover(isPresented: $showTeamCenterScreen) {
            TeamCenterPlayersView(
                language: language,
                lineup: lineup,
                bench: bench,
                onClose: {
                    showTeamCenterScreen = false
                }
            )
        }
        .fullScreenCover(isPresented: $showTransferCenterScreen) {
            TransferCenterPremiumView(
                language: language,
                selectedTeam: selectedTeam,
                budgetM: $budgetM,
                lineup: $lineup,
                bench: $bench,
                onClose: {
                    showTransferCenterScreen = false
                }
            )
        }
        .fullScreenCover(isPresented: $showTodayMatchesScreen) {
            TodayMatchesScreen(language: language)
        }
        .fullScreenCover(isPresented: $showSettingsScreen) {
            SettingsSheetView(
                selectedLanguage: selectedLanguageBinding,
                onOpenClubCenter: {
                    showSettingsScreen = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        presentLogoImporter()
                    }
                }
            )
        }
        .onAppear {
            restoreSavedGameIfNeeded()
        }
    }

    private var appBackground: some View {
        ZStack {
            LinearGradient(
                colors: [FootballTheme.backgroundPrimary, FootballTheme.cardBase, FootballTheme.backgroundSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if step == .welcome {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.06),
                        Color.clear,
                        Color.black.opacity(0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .blendMode(.softLight)

                RadialGradient(
                    colors: [FootballTheme.cardGlow.opacity(0.24), .clear],
                    center: UnitPoint(x: 0.14, y: 0.08),
                    startRadius: 12,
                    endRadius: 420
                )
                .blendMode(.screen)

                RadialGradient(
                    colors: [FootballTheme.accentCyan.opacity(0.18), .clear],
                    center: UnitPoint(x: 0.86, y: 0.14),
                    startRadius: 20,
                    endRadius: 500
                )
                .blendMode(.screen)

                RadialGradient(
                    colors: [Color.white.opacity(0.08), .clear],
                    center: UnitPoint(x: 0.5, y: 1.04),
                    startRadius: 14,
                    endRadius: 560
                )

                GeometryReader { proxy in
                    let lines = max(20, Int(proxy.size.height / 30))
                    let spacing = max(11, proxy.size.height / CGFloat(lines + 5))

                    VStack(spacing: spacing) {
                        ForEach(0..<lines, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.white.opacity(0.012))
                                .frame(height: 1)
                        }
                    }
                    .frame(width: proxy.size.width * 1.3, height: proxy.size.height * 1.2)
                    .rotationEffect(.degrees(-6))
                    .offset(x: -proxy.size.width * 0.16, y: -proxy.size.height * 0.08)
                    .blendMode(.softLight)
                    .opacity(0.72)
                }
                .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
    }

    private var settingsButton: some View {
        Button {
            openRoute(.settings)
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 19, weight: .black))
                .foregroundStyle(FootballTheme.textPrimary)
                .frame(width: 46, height: 46)
                .background(
                    Circle()
                        .fill(FootballTheme.cardBase.opacity(0.55))
                )
                .overlay(
                    Circle()
                        .stroke(FootballTheme.cardGlow.opacity(0.35), lineWidth: 1.2)
                )
                .shadow(color: .black.opacity(0.24), radius: 10, x: 0, y: 6)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .zIndex(20)
        .accessibilityLabel(t(ar: "الإعدادات", en: "Settings", hi: "सेटिंग्स", zh: "设置", ku: "ڕێکخستن"))
    }

    private var footballScreenButton: some View {
        Button {
            withAnimation(.spring(response: 0.40, dampingFraction: 0.86)) {
                showTodayMatchesScreen = true
            }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xF5F8FF), Color(hex: 0xBFD2FF)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .stroke(Color.white.opacity(0.62), lineWidth: 1.2)

                Image("12")
                    .resizable()
                    .scaledToFit()
                    .padding(6)
            }
            .frame(width: 46, height: 46)
            .shadow(color: Color(hex: 0xB7CAFF).opacity(0.44), radius: 10, x: 0, y: 5)
            .shadow(color: Color.white.opacity(0.18), radius: 4, x: 0, y: -1)
        }
        .buttonStyle(InteractivePressButtonStyle())
        .accessibilityLabel(t(ar: "مباريات اليوم", en: "Today Matches", hi: "आज के मैच", zh: "今日比赛", ku: "یارییەکانی ئەمڕۆ"))
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:
            welcomeView
        case .leagueSelection:
            leagueSelectionView
        case .teamSelection:
            teamSelectionView
        case .dashboard:
            dashboardView
        }
    }

    private var welcomeView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                welcomeSimpleTopBar
                    .zIndex(20)
                welcomeEntryCard
                    .zIndex(10)
                continueCareerCard
                welcomeStandingsSection
            }
            .padding(.bottom, 10)
        }
        .refreshable {
            await loadLiveStandings(force: true)
        }
    }

    private var welcomeSimpleTopBar: some View {
        let isRTL = language.layoutDirection == .rightToLeft

        return HStack(spacing: 10) {
            if isRTL {
                settingsButton
                footballScreenButton
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(mainMenuText(.screenTitle))
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text(mainMenuText(.screenTitle))
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                footballScreenButton
                settingsButton
            }
        }
        .padding(.horizontal, 2)
        .padding(.top, 2)
    }

    private var welcomeStandingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            standingsSectionHeader
            standingsTabs
            standingsSectionContent

            if !liveErrorMessage.isEmpty {
                Text(localizedDisplayText(liveErrorMessage, in: language))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(FootballTheme.pointsYellow.opacity(0.92))
                    .frame(maxWidth: .infinity, alignment: language.layoutDirection == .rightToLeft ? .trailing : .leading)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [FootballTheme.cardBase.opacity(0.92), FootballTheme.backgroundSecondary.opacity(0.86)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(FootballTheme.cardGlow.opacity(0.34), lineWidth: 1.1)
        )
        .shadow(color: FootballTheme.cardGlow.opacity(0.16), radius: 14, x: 0, y: 8)
        .onAppear {
            Task { await loadLiveStandings(force: true) }
        }
        .onReceive(liveAutoRefreshTimer) { _ in
            guard step == .welcome else { return }
            Task { await loadLiveStandings(force: true) }
        }
    }

    private var standingsSectionHeader: some View {
        HStack(spacing: 10) {
            Button {
                Task { await loadLiveStandings(force: true) }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .black))
                    Text(t(ar: "تحديث", en: "Refresh", hi: "रीफ्रेश", zh: "刷新", ku: "نوێکردنەوە"))
                        .font(.system(size: 12, weight: .black))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.20), lineWidth: 1)
                )
            }
            .buttonStyle(InteractivePressButtonStyle())

            Spacer(minLength: 0)

            VStack(alignment: language.layoutDirection == .rightToLeft ? .trailing : .leading, spacing: 2) {
                Text(t(ar: "ترتيب الفرق", en: "Team Standings", hi: "टीम स्टैंडिंग्स", zh: "球队排名", ku: "ڕیزبەندی تیمەکان"))
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                if let liveLastUpdated {
                    Text("\(t(ar: "آخر تحديث", en: "Last update", hi: "आख़िरी अपडेट", zh: "最后更新", ku: "دوایین نوێکردنەوە")): \(liveUpdatedText(from: liveLastUpdated))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(FootballTheme.textSecondary.opacity(0.8))
                        .lineLimit(1)
                }
            }
        }
    }

    private var standingsTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LiveTopLeague.allCases) { league in
                    Button {
                        selectedLiveLeague = league
                        Task { await loadLiveStandings(force: false) }
                    } label: {
                        Text(league.localizedTitle(in: language))
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(selectedLiveLeague == league ? .black : .white.opacity(0.92))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(
                                        selectedLiveLeague == league
                                        ? FootballTheme.pitchGreen.opacity(0.96)
                                        : FootballTheme.backgroundPrimary.opacity(0.52)
                                    )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        selectedLiveLeague == league
                                        ? FootballTheme.pitchGreen.opacity(0.96)
                                        : Color.white.opacity(0.18),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(InteractivePressButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private var standingsSectionContent: some View {
        if liveLoading {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(.white)
                Text(t(ar: "جاري تحديث الترتيب...", en: "Updating standings...", hi: "स्टैंडिंग अपडेट हो रही है...", zh: "正在更新排名...", ku: "ڕیزبەندی نوێ دەکرێتەوە..."))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.86))
            }
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .center)
        } else if liveStandings.isEmpty {
            if !liveErrorMessage.isEmpty {
                standingsErrorState
            } else {
                Text(t(ar: "لا توجد بيانات ترتيب حالياً", en: "No standings data right now", hi: "अभी कोई स्टैंडिंग डेटा नहीं", zh: "当前暂无排名数据", ku: "ئێستا هیچ داتای ڕیزبەندی نییە"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.88))
                    .frame(maxWidth: .infinity, minHeight: 92, alignment: .center)
            }
        } else {
            welcomeStandingsTable
        }
    }

    private var standingsErrorState: some View {
        VStack(spacing: 9) {
            Text(localizedDisplayText(liveErrorMessage, in: language))
                .font(.system(size: 13, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(FootballTheme.pointsYellow.opacity(0.94))
                .frame(maxWidth: .infinity, alignment: .center)

            Button {
                Task { await loadLiveStandings(force: true) }
            } label: {
                Text(t(ar: "إعادة المحاولة", en: "Retry", hi: "फिर प्रयास करें", zh: "重试", ku: "دووبارە هەوڵبدە"))
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.14))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.24), lineWidth: 1)
                    )
            }
            .buttonStyle(InteractivePressButtonStyle())
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .center)
    }

    private var welcomeStandingsTable: some View {
        let rankWidth: CGFloat = 30
        let teamWidth: CGFloat = 136
        let statWidth: CGFloat = 34
        let gdWidth: CGFloat = 44
        let ptsWidth: CGFloat = 44
        let formWidth: CGFloat = 100
        let isRTL = language.layoutDirection == .rightToLeft

        return ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    liveHeaderCell("#", width: rankWidth)
                    liveHeaderCell(t(ar: "الفريق", en: "Team", hi: "टीम", zh: "球队", ku: "تیم"), width: teamWidth)
                    liveHeaderCell("P", width: statWidth)
                    liveHeaderCell("W", width: statWidth)
                    liveHeaderCell("D", width: statWidth)
                    liveHeaderCell("L", width: statWidth)
                    liveHeaderCell("GD", width: gdWidth)
                    liveHeaderCell(t(ar: "ن", en: "Pts", hi: "अंक", zh: "分", ku: "خاڵ"), width: ptsWidth)
                    liveHeaderCell(t(ar: "آخر 5", en: "Form", hi: "फॉर्म", zh: "状态", ku: "فۆرم"), width: formWidth)
                }
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.09))
                )

                ForEach(Array(liveStandings.prefix(8).enumerated()), id: \.element.id) { index, row in
                    let rankColor: Color = row.rank <= 4 ? FootballTheme.pitchGreen : .white.opacity(0.92)

                    HStack(spacing: 0) {
                        liveValueCell("\(row.rank)", width: rankWidth, bold: true, color: rankColor)

                        Text(row.teamName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(FootballTheme.textPrimary)
                            .lineLimit(1)
                            .frame(width: teamWidth, alignment: isRTL ? .trailing : .leading)

                        liveValueCell("\(row.played)", width: statWidth)
                        liveValueCell("\(row.wins)", width: statWidth)
                        liveValueCell("\(row.draws)", width: statWidth)
                        liveValueCell("\(row.losses)", width: statWidth)
                        liveValueCell("\(row.goalDiff)", width: gdWidth)
                        liveValueCell("\(row.points)", width: ptsWidth, bold: true, color: FootballTheme.pointsYellow)

                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { idx in
                                if idx < row.form.count {
                                    formBadge(row.form[idx])
                                } else {
                                    Circle()
                                        .fill(Color.white.opacity(0.14))
                                        .frame(width: 20, height: 20)
                                }
                            }
                        }
                        .frame(width: formWidth)
                    }
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(index.isMultiple(of: 2) ? Color.white.opacity(0.04) : Color.clear)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mainMenuResources: [MainMenuResourceItem] {
        guard let saved = savedCareerSnapshot, hasSavedCareer() else { return [] }

        return [
            MainMenuResourceItem(
                symbol: "banknote.fill",
                label: mainMenuText(.resourceBudget),
                value: "$\(saved.budgetM)M"
            ),
            MainMenuResourceItem(
                symbol: "person.2.fill",
                label: mainMenuText(.resourceFans),
                value: "\(saved.fanSatisfaction)%"
            ),
            MainMenuResourceItem(
                symbol: "chart.line.uptrend.xyaxis",
                label: mainMenuText(.resourceStrength),
                value: "\(saved.squadStrength)"
            )
        ]
    }

    private var mainMenuProfileName: String {
        if let savedTeam = savedCareerSnapshot?.selectedTeam, hasSavedCareer() {
            return localizedDisplayName(savedTeam, in: language)
        }
        return mainMenuText(.profileGuestName)
    }

    private var mainMenuProfileSubtitle: String {
        if let savedLeague = savedCareerSnapshot?.selectedLeagueName, hasSavedCareer() {
            return "\(mainMenuText(.profileClubLabel)): \(localizedLeagueName(savedLeague, in: language))"
        }
        return mainMenuText(.profileGuestRole)
    }

    private func mainMenuCard(for action: MainMenuAction) -> some View {
        let style = mainMenuCardStyle(for: action)

        return Button {
            handleMainMenuAction(action)
        } label: {
            MainMenuCardView(
                title: mainMenuTitle(for: action),
                subtitle: mainMenuSubtitle(for: action),
                symbol: style.symbol,
                backgroundAsset: style.backgroundAsset,
                colors: style.colors,
                glow: style.glow,
                tag: style.size == .featured ? mainMenuText(.featuredTag) : nil,
                size: style.size,
                language: language
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(MainMenuTilePressStyle())
        .hoverEffect(.lift)
        .accessibilityLabel(mainMenuTitle(for: action))
    }

    private func mainMenuCardStyle(for action: MainMenuAction) -> MainMenuCardStyle {
        switch action {
        case .quickMatch:
            return MainMenuCardStyle(
                symbol: "soccerball.inverse",
                backgroundAsset: "menu_quick_match_bg",
                colors: [Color(hex: 0x0A1A35), Color(hex: 0x154680), Color(hex: 0x2272C7)],
                glow: Color(hex: 0x7FDBFF),
                size: .featured
            )
        case .careerMode:
            return MainMenuCardStyle(
                symbol: "briefcase.fill",
                backgroundAsset: "menu_career_bg",
                colors: [Color(hex: 0x241D31), Color(hex: 0x49376A)],
                glow: Color(hex: 0x9D7CFF),
                size: .medium
            )
        case .teamManagement:
            return MainMenuCardStyle(
                symbol: "person.3.sequence.fill",
                backgroundAsset: "menu_team_bg",
                colors: [Color(hex: 0x0A2A35), Color(hex: 0x1E5E70)],
                glow: Color(hex: 0x62D6B6),
                size: .medium
            )
        case .trainingTactics:
            return MainMenuCardStyle(
                symbol: "list.clipboard.fill",
                backgroundAsset: "menu_training_bg",
                colors: [Color(hex: 0x222735), Color(hex: 0x3D4D70)],
                glow: Color(hex: 0xF2A6FF),
                size: .small
            )
        case .competitions:
            return MainMenuCardStyle(
                symbol: "trophy.fill",
                backgroundAsset: "menu_competitions_bg",
                colors: [Color(hex: 0x31250B), Color(hex: 0x775717)],
                glow: Color(hex: 0xFFD56A),
                size: .medium
            )
        case .settings:
            return MainMenuCardStyle(
                symbol: "gearshape.2.fill",
                backgroundAsset: "menu_settings_bg",
                colors: [Color(hex: 0x172533), Color(hex: 0x2F4A66)],
                glow: Color(hex: 0x8CA6DB),
                size: .small
            )
        }
    }

    private func mainMenuTitle(for action: MainMenuAction) -> String {
        switch action {
        case .quickMatch: return mainMenuText(.quickMatchTitle)
        case .careerMode: return mainMenuText(.careerModeTitle)
        case .teamManagement: return mainMenuText(.teamManagementTitle)
        case .trainingTactics: return mainMenuText(.trainingTitle)
        case .competitions: return mainMenuText(.competitionsTitle)
        case .settings: return mainMenuText(.settingsTitle)
        }
    }

    private func mainMenuSubtitle(for action: MainMenuAction) -> String {
        switch action {
        case .quickMatch: return mainMenuText(.quickMatchSubtitle)
        case .careerMode: return mainMenuText(.careerModeSubtitle)
        case .teamManagement: return mainMenuText(.teamManagementSubtitle)
        case .trainingTactics: return mainMenuText(.trainingSubtitle)
        case .competitions: return mainMenuText(.competitionsSubtitle)
        case .settings: return mainMenuText(.settingsSubtitle)
        }
    }

    private func openRoute(_ route: HomeRoute) {
        switch route {
        case .settings:
            openSettingsScreen()
        case .leagues:
            openLeagueSelectionScreen()
        }
    }

    private func openSettingsScreen() {
        showSettingsScreen = true
    }

    private func openLeagueSelectionScreen() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.84)) {
            step = .leagueSelection
        }
    }

    private func handleMainMenuAction(_ action: MainMenuAction) {
        switch action {
        case .quickMatch:
            if hasSavedCareer() {
                continueSavedCareer()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                    currentTab = .simulator
                    if isTodayMatchDay() {
                        openMatchCenterFromHub()
                    } else {
                        managerNote = mainMenuText(.quickMatchFallbackNote)
                    }
                }
            } else {
                openRoute(.leagues)
            }

        case .careerMode:
            openRoute(.leagues)

        case .teamManagement:
            openMainMenuSectionRequiringCareer(
                placeholderMessage: mainMenuText(.placeholderTeamManagementRequired)
            ) {
                showTeamManagementScreen = true
            }

        case .trainingTactics:
            openMainMenuSectionRequiringCareer(
                placeholderMessage: mainMenuText(.placeholderTrainingRequired)
            ) {
                currentTab = .management
            }

        case .competitions:
            showCompetitions = true

        case .settings:
            openRoute(.settings)
        }
    }

    private func openMainMenuSectionRequiringCareer(
        placeholderMessage: String,
        action: @escaping () -> Void
    ) {
        guard hasSavedCareer() else {
            mainMenuPlaceholderMessage = placeholderMessage
            showMainMenuPlaceholderAlert = true
            return
        }

        continueSavedCareer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            action()
        }
    }

    private var welcomeEntryCard: some View {
        let supportedLeagues = topLeagues.count

        return Button {
            openRoute(.leagues)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                FootballTheme.backgroundPrimary,
                                FootballTheme.backgroundSecondary,
                                FootballTheme.accentCyan.opacity(0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.16), Color.clear, Color.black.opacity(0.22)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .fill(FootballTheme.accentCyan.opacity(0.36))
                    .frame(width: 220, height: 220)
                    .blur(radius: 28)
                    .offset(x: -140, y: -92)

                Circle()
                    .fill(FootballTheme.pitchGreen.opacity(0.30))
                    .frame(width: 170, height: 170)
                    .blur(radius: 28)
                    .offset(x: 124, y: 88)

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        welcomeHeroPill(
                            text: t(ar: "طور المهنة", en: "Career Mode", hi: "करियर मोड", zh: "生涯模式", ku: "مۆدی پیشە"),
                            icon: "sparkles"
                        )

                        Text("2026")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.84))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.10))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(t(ar: "مهنة مدرب", en: "Coach Career", hi: "कोच करियर", zh: "教练生涯", ku: "پیشەی ڕاهێنەر"))
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.74)
                            .shadow(color: Color.black.opacity(0.24), radius: 10, x: 0, y: 6)

                        Text(t(ar: "اختر ناديك، ابنِ تشكيلتك، وابدأ رحلة الألقاب.", en: "Choose your club, build your squad, and begin the road to trophies.", hi: "अपना क्लब चुनें, टीम बनाएं और ट्रॉफियों की राह शुरू करें।", zh: "选择你的俱乐部，打造阵容，开启冠军之路。", ku: "یانەکەت هەڵبژێرە، تیمەکەت دروست بکە و ڕێگای پاڵەوانی دەستپێبکە."))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.80))
                            .lineLimit(2)
                    }

                    HStack(spacing: 8) {
                        welcomeHeroPill(
                            text: t(ar: "\(supportedLeagues) دوريات", en: "\(supportedLeagues) Leagues", hi: "\(supportedLeagues) लीग", zh: "\(supportedLeagues)个联赛", ku: "\(supportedLeagues) لیگ"),
                            icon: "flag.fill"
                        )

                        welcomeHeroPill(
                            text: t(ar: "اضغط للدخول", en: "Tap to Enter", hi: "दबाकर शुरू करें", zh: "点击进入", ku: "بۆ چوونە ژوورەوە پەنجە بنێ"),
                            icon: "play.fill"
                        )
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 242)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [FootballTheme.cardGlow.opacity(0.58), Color.white.opacity(0.14)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.3
                    )
            )
            .shadow(color: Color.black.opacity(0.26), radius: 20, x: 0, y: 12)
            .shadow(color: FootballTheme.accentCyan.opacity(0.30), radius: 22, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }

    private var continueCareerCard: some View {
        let hasSave = hasSavedCareer()

        return Button {
            continueSavedCareer()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: hasSave
                            ? [
                                FootballTheme.backgroundSecondary,
                                FootballTheme.cardBase,
                                FootballTheme.accentCyan.opacity(0.9)
                            ]
                            : [
                                FootballTheme.cardBase.opacity(0.84),
                                FootballTheme.backgroundSecondary.opacity(0.82)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(hasSave ? 0.18 : 0.14), .clear, .clear],
                            startPoint: .topLeading,
                            endPoint: .bottom
                        )
                    )

                if hasSave {
                    continueCareerShine(width: 170, height: 36, tint: Color.white.opacity(0.12))
                        .offset(x: 66, y: -28)

                    continueCareerShine(width: 120, height: 28, tint: FootballTheme.accentCyan.opacity(0.16))
                        .offset(x: -72, y: 30)
                } else {
                    continueCareerShine(width: 160, height: 34, tint: FootballTheme.cardGlow.opacity(0.14))
                        .offset(x: 40, y: -22)
                }

                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(hasSave ? 0.28 : 0.12),
                                Color.white.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.1
                    )

                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: hasSave
                                    ? [FootballTheme.pitchGreen.opacity(0.96), FootballTheme.accentCyan.opacity(0.92)]
                                    : [FootballTheme.accentCyan.opacity(0.65), FootballTheme.cardGlow.opacity(0.55)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)

                        Circle()
                            .fill(Color.white.opacity(hasSave ? 0.16 : 0.08))
                            .frame(width: 24, height: 24)
                            .offset(x: 12, y: -12)

                        Image(systemName: hasSave ? "arrow.trianglehead.clockwise.circle.fill" : "tray.fill")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(hasSave ? Color.black : .white.opacity(0.84))
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            Text(t(ar: "متابعة المهنة", en: "Continue Career", hi: "करियर जारी रखें", zh: "继续生涯", ku: "بەردەوامبوونی پیشە"))
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            Spacer(minLength: 0)

                            Text(
                                hasSave
                                ? t(ar: "محفوظة", en: "Saved", hi: "सेव", zh: "已保存", ku: "هەڵگیراو")
                                : t(ar: "فارغة", en: "Empty", hi: "खाली", zh: "空", ku: "بەتاڵ")
                            )
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(hasSave ? Color.black : FootballTheme.textPrimary.opacity(0.86))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(hasSave ? Color.white.opacity(0.95) : FootballTheme.cardBase.opacity(0.86))
                            )
                        }

                        if let saved = savedCareerSnapshot,
                           let savedTeam = saved.selectedTeam,
                           let savedLeague = saved.selectedLeagueName {
                            Text(localizedDisplayName(savedTeam, in: language))
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            HStack(spacing: 8) {
                                Text(localizedLeagueName(savedLeague, in: language))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.72))
                                    .lineLimit(1)

                                saveInfoPill(
                                    "\(t(ar: "الجولة", en: "Round", hi: "राउंड", zh: "轮次", ku: "دەور")) \(min(saved.matchWeek, saved.totalWeeks))/\(saved.totalWeeks)",
                                    active: true
                                )
                            }
                        } else {
                            Text(t(ar: "احفظ مهنة أولاً حتى تظهر هنا.", en: "Save a career first and it will appear here.", hi: "पहले करियर सेव करें، फिर यह यहाँ दिखेगा।", zh: "先保存一个生涯，它就会显示在这里。", ku: "سەرەتا پیشەیەک هەڵبگرە، ئەنجا لێرە دەردەکەوێت."))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(FootballTheme.textSecondary.opacity(0.92))
                                .lineLimit(2)
                        }
                    }

                    if hasSave {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.13))
                                .frame(width: 38, height: 38)

                            Image(systemName: language.layoutDirection == .rightToLeft ? "chevron.backward" : "chevron.forward")
                                .font(.system(size: 15, weight: .black))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .frame(height: hasSave ? 128 : 104)
            .shadow(color: hasSave ? FootballTheme.accentCyan.opacity(0.22) : FootballTheme.cardGlow.opacity(0.14), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .disabled(!hasSave)
        .contextMenu {
            if hasSave {
                Button(role: .destructive) {
                    deleteSavedCareer()
                } label: {
                    Label(
                        t(ar: "حذف المهنة", en: "Delete Career", hi: "करियर हटाएं", zh: "删除生涯", ku: "سڕینەوەی پیشە"),
                        systemImage: "trash"
                    )
                }
            }
        }
    }

    private func welcomeHeroPill(text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .black))
            Text(text)
                .font(.system(size: 11, weight: .black))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [FootballTheme.cardBase.opacity(0.92), FootballTheme.backgroundSecondary.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            Capsule()
                .stroke(FootballTheme.cardGlow.opacity(0.30), lineWidth: 1)
        )
    }

    private func continueCareerShine(width: CGFloat, height: CGFloat, tint: Color) -> some View {
        Capsule()
            .fill(tint)
            .frame(width: width, height: height)
            .rotationEffect(.degrees(-18))
    }

    private var importLogosCard: some View {
        VStack(spacing: 12) {
            Button {
                presentLogoImporter()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [FootballTheme.pitchGreen.opacity(0.94), FootballTheme.accentCyan.opacity(0.92)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 54, height: 54)

                        Image(systemName: isImportingLogos ? "arrow.down.circle.fill" : "square.and.arrow.down.fill")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(.black.opacity(0.86))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(t(ar: "استيراد شعارات مخصصة", en: "Import Custom Logos", hi: "कस्टम लोगो इम्पोर्ट", zh: "导入自定义队徽", ku: "هاوردەکردنی شعارە تایبەتیەکان"))
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text(t(ar: "يتم قراءة logos.json ثم تفعيل الشعارات من GitHub", en: "Reads logos.json then activates logos from GitHub", hi: "पहले logos.json पढ़ता है फिर GitHub से लोगो सक्रिय करता है", zh: "先读取 logos.json，再从 GitHub 启用队徽", ku: "سەرەتا logos.json دەخوێنێتەوە، پاشان شعارەکان لە GitHub چالاک دەکات"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(FootballTheme.textSecondary.opacity(0.92))
                            .lineLimit(2)
                    }

                    Spacer(minLength: 8)

                    if isImportingLogos {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: language.layoutDirection == .rightToLeft ? "chevron.backward.circle.fill" : "chevron.forward.circle.fill")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(FootballTheme.accentCyan.opacity(0.94))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [FootballTheme.cardBase.opacity(0.92), FootballTheme.backgroundSecondary.opacity(0.86)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(FootballTheme.cardGlow.opacity(0.36), lineWidth: 1.1)
                )
                .shadow(color: FootballTheme.cardGlow.opacity(0.18), radius: 14, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(isImportingLogos)
            .accessibilityLabel(t(ar: "استيراد الشعارات", en: "Import logos", hi: "लोगो इम्पोर्ट", zh: "导入队徽", ku: "هاوردەکردنی شعارەکان"))

            if logoStore.importedLogoCount > 0 {
                HStack(spacing: 10) {
                    Button {
                        presentLogoImporter()
                    } label: {
                        Text(t(ar: "استبدال الحزمة", en: "Replace Pack", hi: "पैक बदलें", zh: "替换包", ku: "گۆڕینی پەکیج"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(FootballTheme.pitchGreen.opacity(0.95))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isImportingLogos)

                    Button(role: .destructive) {
                        showDeleteImportedLogosConfirmation = true
                    } label: {
                        Text(t(ar: "حذف الشعارات المستوردة", en: "Delete Imported Logos", hi: "इम्पोर्ट लोगो हटाएं", zh: "删除已导入队徽", ku: "سڕینەوەی شعارە هاوردەکراوەکان"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(FootballTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(FootballTheme.dangerRed.opacity(0.52))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isImportingLogos)
                }
            }
        }
    }

    private func presentLogoImporter() {
        _ = logoStore.prepareImportsDirectoryForPicker()
        logoImporterStatusText = ""
        logoImporterStatusIsSuccess = false
        showLogoImporter = true
        loadRemoteLogoManifest()
    }

    private func loadRemoteLogoManifest() {
        isLoadingLogoManifest = true
        Task {
            defer { isLoadingLogoManifest = false }
            do {
                let manifestItems = try await ClubLogoStore.shared.fetchRemoteManifest(from: logosManifestURL)
                remoteLogoManifestItems = manifestItems
            } catch let importError as ClubLogoStore.ImportError {
                ClubLogoStore.shared.applyLocalFallbackPlaceholders()
                logoImporterStatusIsSuccess = false
                logoImporterStatusText = localizedLogoImportError(importError)
            } catch {
                ClubLogoStore.shared.applyLocalFallbackPlaceholders()
                logoImporterStatusIsSuccess = false
                logoImporterStatusText = t(
                    ar: "تعذر قراءة ملف الحزمة من الخادم.",
                    en: "Couldn't read pack manifest from server.",
                    hi: "सर्वर से पैक manifest पढ़ा नहीं जा सका।",
                    zh: "无法读取服务器中的包清单。",
                    ku: "نەتوانرا لیستی پەکیج لە سێرڤەرەوە بخوێنرێتەوە."
                )
            }
        }
    }

    private func downloadCustomLogosFromServer() {
        isImportingLogos = true
        Task {
            defer { isImportingLogos = false }
            do {
                var manifestItems = remoteLogoManifestItems
                if manifestItems.isEmpty {
                    manifestItems = try await ClubLogoStore.shared.fetchRemoteManifest(from: logosManifestURL)
                    remoteLogoManifestItems = manifestItems
                }

                let importedCount = try await ClubLogoStore.shared.importFromRemotePack(manifestItems)
                managerNote = t(
                    ar: "تم تفعيل \(importedCount) شعار بنجاح",
                    en: "\(importedCount) logos activated successfully",
                    hi: "\(importedCount) लोगो सफलतापूर्वक सक्रिय हुए",
                    zh: "成功启用 \(importedCount) 个队徽",
                    ku: "\(importedCount) شعار بە سەرکەوتوویی چالاککران"
                )
                logoImporterStatusIsSuccess = true
                logoImporterStatusText = t(
                    ar: "تم تفعيل الشعارات بنجاح",
                    en: "Logos activated successfully",
                    hi: "लोगो सफलतापूर्वक सक्रिय हुए",
                    zh: "队徽启用成功",
                    ku: "شعارەکان بە سەرکەوتوویی چالاککران"
                )
            } catch let importError as ClubLogoStore.ImportError {
                ClubLogoStore.shared.applyLocalFallbackPlaceholders()
                logoImporterStatusIsSuccess = false
                logoImporterStatusText = localizedLogoImportError(importError)
            } catch {
                ClubLogoStore.shared.applyLocalFallbackPlaceholders()
                logoImporterStatusIsSuccess = false
                logoImporterStatusText = t(
                    ar: "فشل تحميل الشعارات من الخادم.",
                    en: "Failed to download logos from server.",
                    hi: "सर्वर से लोगो डाउनलोड नहीं हो सके।",
                    zh: "从服务器下载队徽失败。",
                    ku: "داگرتنی شعارەکان لە سێرڤەر سەرکەوتوو نەبوو."
                )
            }
        }
    }

    private func removeImportedLogos() {
        do {
            let removedCount = try ClubLogoStore.shared.deleteImportedLogos()
            managerNote = t(ar: "تم حذف الشعارات المستوردة", en: "Imported logos were removed", hi: "इम्पोर्ट किए लोगो हटा दिए गए", zh: "已删除导入队徽", ku: "شعارە هاوردەکراوەکان سڕدرانەوە")
            logoImportAlertTitle = t(ar: "تم الحذف", en: "Deleted", hi: "हटा दिया गया", zh: "已删除", ku: "سڕدرایەوە")
            logoImportAlertMessage = t(
                ar: "تم حذف \(removedCount) شعار مخصص. سيتم استخدام default_logo.png عند عدم وجود شعار مستورد.",
                en: "\(removedCount) custom logos were deleted. The app will use default_logo.png when no imported logo exists.",
                hi: "\(removedCount) कस्टम लोगो हटा दिए गए। अब जहां लोगो नहीं होगा वहां default_logo.png उपयोग होगा।",
                zh: "已删除 \(removedCount) 个自定义队徽。没有导入队徽时将使用 default_logo.png。",
                ku: "\(removedCount) شعارە تایبەتی سڕدرانەوە. کاتێک شعارێکی هاوردەکراو نەبێت default_logo.png بەکاردهێنرێت."
            )
            showLogoImportAlert = true
        } catch {
            logoImportAlertTitle = t(ar: "فشل الحذف", en: "Delete Failed", hi: "हटाना असफल", zh: "删除失败", ku: "سڕینەوە سەرکەوتوو نەبوو")
            logoImportAlertMessage = t(ar: "تعذر حذف الشعارات المستوردة الآن.", en: "Couldn't delete imported logos right now.", hi: "अभी इम्पोर्ट लोगो हटाए नहीं जा सके।", zh: "当前无法删除导入队徽。", ku: "ئێستا نەتوانرا شعارە هاوردەکراوەکان بسڕدرێنەوە.")
            showLogoImportAlert = true
        }
    }

    private func localizedLogoImportError(_ error: ClubLogoStore.ImportError) -> String {
        switch error {
        case .unsupportedSelection:
            return t(ar: "اختر ملف ZIP أو مجلد شعارات.", en: "Choose a ZIP file or a logos folder.", hi: "ZIP फ़ाइल या logos फ़ोल्डर चुनें।", zh: "请选择 ZIP 文件或 logos 文件夹。", ku: "پەڕگەی ZIP یان فولدەری logos هەڵبژێرە.")
        case .cannotReadSelection:
            return t(ar: "تعذر قراءة الملف المحدد.", en: "Couldn't read the selected file.", hi: "चुनी गई फ़ाइल पढ़ी नहीं जा सकी।", zh: "无法读取所选文件。", ku: "نەتوانرا پەڕگەی هەڵبژێردراو بخوێنرێتەوە.")
        case .invalidZipArchive:
            return t(ar: "ملف ZIP غير صالح أو تالف.", en: "ZIP file is invalid or corrupted.", hi: "ZIP फ़ाइल अमान्य या खराब है।", zh: "ZIP 文件无效或损坏。", ku: "پەڕگەی ZIP دروست نییە یان تێکچووە.")
        case .noValidImages:
            return t(ar: "لم يتم العثور على صور شعارات صالحة (PNG/JPG).", en: "No valid logo images were found (PNG/JPG).", hi: "कोई मान्य लोगो इमेज नहीं मिली (PNG/JPG)।", zh: "未找到有效队徽图片（PNG/JPG）。", ku: "هیچ وێنەی شعارێکی دروست نەدۆزرایەوە (PNG/JPG).")
        case .downloadFailed:
            return t(ar: "فشل تحميل بيانات الأندية من GitHub.", en: "Failed to load club data from GitHub.", hi: "GitHub से क्लब डेटा लोड नहीं हो सका।", zh: "从 GitHub 加载俱乐部数据失败。", ku: "بارکردنی داتای یانەکان لە GitHub سەرکەوتوو نەبوو.")
        case .forbiddenRequest:
            return t(ar: "تم رفض الوصول من GitHub (403). تحقق من الصلاحيات أو حدّ الطلبات.", en: "GitHub access was denied (403). Check permissions or rate limits.", hi: "GitHub ने एक्सेस अस्वीकार किया (403)। अनुमति या रेट लिमिट जांचें।", zh: "GitHub 拒绝访问（403），请检查权限或请求频率。", ku: "دەستگەیشتن لەلایەن GitHubەوە ڕەتکرایەوە (403). مۆڵەت یان سنووری داواکاری بپشکنە.")
        case .resourceNotFound:
            return t(ar: "ملف بيانات الأندية غير موجود على GitHub (404). تحقق من الرابط أو الفرع.", en: "Club data file was not found on GitHub (404). Check URL or branch.", hi: "GitHub पर क्लब डेटा फ़ाइल नहीं मिली (404)। URL या ब्रांच जांचें।", zh: "GitHub 上未找到俱乐部数据文件（404），请检查链接或分支。", ku: "پەڕگەی داتای یانەکان لە GitHub نەدۆزرایەوە (404). لینک یان بڕانچ بپشکنە.")
        case .networkFailure:
            return t(ar: "فشل الاتصال بـ GitHub. تحقق من الشبكة ثم أعد المحاولة.", en: "Network error while reaching GitHub. Check connection and retry.", hi: "GitHub से कनेक्शन में नेटवर्क त्रुटि हुई। कनेक्शन जांचकर दोबारा प्रयास करें।", zh: "连接 GitHub 时发生网络错误，请检查网络后重试。", ku: "هەڵەی تۆڕ ڕوویدا لە پەیوەندی بە GitHub. پاش پشکنینی تۆڕ دووبارە هەوڵبدە.")
        case .decodingFailed:
            return t(ar: "تعذّر تحليل بيانات الأندية القادمة من GitHub.", en: "Couldn't decode clubs data from GitHub.", hi: "GitHub से आए क्लब डेटा को पढ़ा नहीं जा सका।", zh: "无法解析来自 GitHub 的俱乐部数据。", ku: "نەتوانرا داتای یانەکان لە GitHub شیبکرێتەوە.")
        case .invalidImageData:
            return t(ar: "الملف المحمّل ليس صورة صالحة.", en: "Downloaded file is not a valid image.", hi: "डाउनलोड की गई फ़ाइल मान्य इमेज नहीं है।", zh: "下载的文件不是有效图片。", ku: "پەڕگەی داگیراو وێنەیەکی دروست نییە.")
        case .invalidManifest:
            return t(ar: "ملف بيانات الأندية غير صالح أو لا يحتوي روابط صحيحة.", en: "Club data manifest is invalid or has no valid links.", hi: "क्लब डेटा manifest अमान्य है या इसमें सही लिंक नहीं हैं।", zh: "俱乐部数据清单无效或不包含有效链接。", ku: "مانیفێستی داتای یانەکان دروست نییە یان لینکێکی دروستی تێدا نییە.")
        }
    }

    private func liveHeaderCell(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .black))
            .foregroundStyle(FootballTheme.textSecondary)
            .frame(width: width)
    }

    private func liveValueCell(_ text: String, width: CGFloat, bold: Bool = false, color: Color = FootballTheme.textPrimary) -> some View {
        Text(text)
            .font(.system(size: 14, weight: bold ? .black : .semibold))
            .foregroundStyle(color)
            .frame(width: width)
    }

    private func formBadge(_ result: Character) -> some View {
        let symbol: String
        let bgColor: Color

        switch result {
        case "W":
            symbol = "checkmark"
            bgColor = FootballTheme.pitchGreen
        case "D":
            symbol = "minus"
            bgColor = FootballTheme.muted
        case "L":
            symbol = "xmark"
            bgColor = FootballTheme.dangerRed
        default:
            symbol = "minus"
            bgColor = FootballTheme.muted
        }

        return Circle()
            .fill(bgColor.opacity(0.95))
            .frame(width: 20, height: 20)
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
            )
    }

    private func liveUpdatedText(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.dateFormat = "d MMM - HH:mm"
        return formatter.string(from: date)
    }

    private func localizedStandingsError(_ error: Error) -> String {
        if let standingsError = error as? StandingsServiceError {
            switch standingsError {
            case .missingAPIKey:
                return t(ar: "مفتاح API غير موجود. أضف FOOTBALL_API_KEY في Secrets.plist.", en: "API key is missing. Add FOOTBALL_API_KEY in Secrets.plist.", hi: "API key गायब है। Secrets.plist में FOOTBALL_API_KEY जोड़ें।", zh: "缺少 API key，请在 Secrets.plist 添加 FOOTBALL_API_KEY。", ku: "کلیلەکەی API نییە. FOOTBALL_API_KEY لە Secrets.plist زیاد بکە.")
            case .httpStatus(let code):
                return t(ar: "فشل تحميل الترتيب من الخادم (HTTP \(code)).", en: "Failed to load standings from server (HTTP \(code)).", hi: "सर्वर से स्टैंडिंग लोड नहीं हुई (HTTP \(code)).", zh: "从服务器加载排名失败（HTTP \(code)）。", ku: "بارکردنی ڕیزبەندی لە سێرڤەر شکستی هێنا (HTTP \(code)).")
            case .invalidURL, .invalidResponse, .decodingFailed:
                return t(ar: "تعذر قراءة بيانات الترتيب من المصدر المباشر.", en: "Couldn't parse standings from the live source.", hi: "लाइव स्रोत से स्टैंडिंग डेटा पढ़ा नहीं जा सका।", zh: "无法解析实时来源的排名数据。", ku: "نەتوانرا داتای ڕیزبەندی لە سەرچاوەی ڕاستەوخۆ بخوێنرێتەوە.")
            }
        }

        if error is URLError {
            return t(ar: "مشكلة اتصال أثناء تحميل الترتيب. تحقق من الإنترنت وحاول مجددًا.", en: "Network issue while loading standings. Check internet and retry.", hi: "स्टैंडिंग लोड करते समय नेटवर्क समस्या आई। इंटरनेट जांचें और दोबारा प्रयास करें।", zh: "加载排名时网络异常，请检查网络后重试。", ku: "کێشەی تۆڕ ڕوویدا لە بارکردنی ڕیزبەندی. ئینتەرنێت بپشکنە و دووبارە هەوڵبدە.")
        }

        return t(ar: "حدث خطأ أثناء جلب الترتيب.", en: "An error occurred while fetching standings.", hi: "स्टैंडिंग लाते समय त्रुटि हुई।", zh: "获取排名时发生错误。", ku: "هەڵەیەک ڕوویدا لە کاتی هێنانی ڕیزبەندی.")
    }

    private func loadLiveStandings(force: Bool) async {
        if liveLoading { return }
        if !force && !liveStandings.isEmpty && liveLoadedLeague == selectedLiveLeague { return }

        let league = selectedLiveLeague
        let changedLeague = liveLoadedLeague != league
        let previousRows = liveStandings

        await MainActor.run {
            liveLoading = true
            liveErrorMessage = ""
            if changedLeague {
                liveStandings = []
            }
        }

        do {
            let rows = try await standingsService.fetchStandings(for: league)

            await MainActor.run {
                liveStandings = rows
                liveLastUpdated = Date()
                liveLoadedLeague = league
                liveLoading = false

                if rows.isEmpty {
                    liveErrorMessage = t(ar: "لا توجد بيانات ترتيب متاحة لهذا الدوري حالياً.", en: "No standings available for this league right now.", hi: "इस लीग के लिए अभी कोई स्टैंडिंग उपलब्ध नहीं है।", zh: "当前该联赛暂无排名数据。", ku: "بۆ ئەم لیگە ئێستا هیچ داتای ڕیزبەندییەک بەردەست نییە.")
                }
            }
        } catch {
            let message = localizedStandingsError(error)
            await MainActor.run {
                liveLoading = false
                liveLoadedLeague = league
                liveErrorMessage = message

                if changedLeague {
                    liveStandings = []
                } else {
                    liveStandings = previousRows
                }
            }
        }
    }

    private var leagueSelectionView: some View {
        VStack(spacing: 16) {
            headerTitle(t(ar: "اختر أحد الدوريات الخمسة الكبرى", en: "Choose One of the Top Five Leagues", hi: "शीर्ष पाँच लीगों में से एक चुनें", zh: "选择五大联赛之一", ku: "یەکێک لە پێنج لیگە گەورەکان هەڵبژێرە"))

            ScrollView {
                VStack(spacing: 14) {
                    ForEach(topLeagues) { league in
                        Button {
                            selectedLeague = league
                            withAnimation {
                                step = .teamSelection
                            }
                        } label: {
                            HStack {
                                Image(systemName: "trophy.fill")
                                Text(localizedLeagueName(league.name, in: language))
                                    .font(.system(size: 21, weight: .bold))
                                Spacer()
                            }
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(FootballTheme.cardBase.opacity(0.70))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(FootballTheme.cardGlow.opacity(0.45), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var teamSelectionView: some View {
        VStack(spacing: 14) {
            headerTitle("\(t(ar: "فرق", en: "Teams", hi: "टीमें", zh: "球队", ku: "تیمەکان")) \(localizedLeagueName(selectedLeague?.name ?? "", in: language))")

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(selectedLeague?.teams ?? [], id: \.self) { team in
                        Button {
                            startCareer(with: team)
                        } label: {
                            HStack {
                                TeamLogoView(teamName: team, size: 28)
                                Text(localizedDisplayName(team, in: language))
                                    .font(.system(size: 19, weight: .semibold))
                                Spacer()
                            }
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(FootballTheme.cardBase.opacity(0.64))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var dashboardView: some View {
        ZStack {
            Group {
                switch currentTab {
                case .simulator:
                    simulatorView
                case .team:
                    teamView
                case .management:
                    managementView
                }
            }

            if showMonthlyNews {
                MonthlyNewsView(
                    language: language,
                    monthTitle: currentMonthTitle(),
                    items: currentMonthNewsItems()
                ) {
                    closeMonthlyNews()
                }
                .zIndex(5)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    )
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.easeInOut(duration: 0.34), value: showMonthlyNews)
        .safeAreaInset(edge: .bottom) {
            if !showMonthlyNews {
                BottomNavBar(language: language, currentTab: $currentTab)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
            }
        }
    }

    private var simulatorView: some View {
        let noMatchPlayedText = localizedDisplayText("لم تُلعب أي مباراة بعد", in: language)
        let playedMatchText = localizedDisplayText(previousResult, in: language)
        let previousMatchText = previousResult == "لم تُلعب أي مباراة بعد" ? noMatchPlayedText : playedMatchText
        let roundText = "\(t(ar: "الجولة", en: "Round", hi: "राउंड", zh: "轮次", ku: "دەور")) \(min(matchWeek, totalWeeks))/\(totalWeeks)"
        let upcomingFixture = nextFixture()
        let daysToMatch = daysUntilNextMatch()
        let isCurrentMatchDay = isTodayMatchDay()
        let matchCardHighlighted = simulationMatchFocus || (daysToMatch != nil && daysToMatch! <= 1) || isCurrentMatchDay
        let nextMatchAnimationKey = "\(upcomingFixture?.opponent ?? "none")-\(Int(upcomingFixture?.date.timeIntervalSince1970 ?? 0))-\(matchWeek)"
        let newsAnimationKey = latestNewsAnimationKey()

        return GeometryReader { proxy in
            let availableHeight = proxy.size.height
            let mergedCardHeight = min(170, max(142, availableHeight * 0.245))
            let newsCardHeight = isCurrentMatchDay
                ? min(164, max(130, availableHeight * 0.235))
                : min(182, max(142, availableHeight * 0.275))

            VStack(spacing: 12) {
                HubHeader(
                    roundText: roundText,
                    selectedTeam: selectedTeam,
                    standingsLabel: t(ar: "ترتيب الدوري", en: "League Table", hi: "लीग तालिका", zh: "联赛排名", ku: "ڕیزبەندی لیگ"),
                    mainMenuLabel: t(ar: "القائمة الرئيسية", en: "Main Menu", hi: "मुख्य मेन्यू", zh: "主菜单", ku: "لیستی سەرەکی"),
                    saveLabel: t(ar: "حفظ", en: "Save", hi: "सेव", zh: "保存", ku: "هەڵگرتن"),
                    onMainMenu: goBackToMainMenu,
                    onSave: saveGame,
                    onStandings: {
                        showLeagueStandingsSheet = true
                    }
                )

                HubDateMatchCard(
                    date: currentDate,
                    language: language,
                    isSimulating: isSimulatingDays,
                    isMatchDay: isCurrentMatchDay,
                    dateToken: simulationDateToken,
                    dateLabel: t(ar: "التاريخ", en: "Date", hi: "तारीख", zh: "日期", ku: "بەروار"),
                    title: t(ar: "المباراة القادمة", en: "Next Match", hi: "अगला मैच", zh: "下一场比赛", ku: "یاریی داهاتوو"),
                    matchDayLabel: t(ar: "يوم مباراة", en: "Match Day", hi: "मैच डे", zh: "比赛日", ku: "ڕۆژی یاری"),
                    opponent: upcomingFixture.map { localizedDisplayName($0.opponent, in: language) },
                    matchDateText: upcomingFixture.map { hubDateText(for: $0.date) },
                    timeText: upcomingFixture.flatMap { hubTimeText(for: $0.date) },
                    previousMatchText: previousMatchText,
                    noUpcomingMatchText: t(ar: "لا توجد مباريات متبقية", en: "No matches remaining", hi: "कोई मैच बाकी नहीं है", zh: "没有剩余比赛", ku: "هیچ یارییەکی ماوە نییە"),
                    previousMatchLabel: t(ar: "المباراة السابقة", en: "Previous Match", hi: "पिछला मैच", zh: "上一场比赛", ku: "یاریی پێشوو"),
                    isHighlighted: matchCardHighlighted
                )
                .padding(.top, 24)
                .frame(height: mergedCardHeight)
                .id(nextMatchAnimationKey)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.97)),
                        removal: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 1.02))
                    )
                )
                .animation(.spring(response: 0.36, dampingFraction: 0.84), value: nextMatchAnimationKey)
                .animation(.easeInOut(duration: 0.26), value: matchCardHighlighted)

                if isCurrentMatchDay && matchWeek <= totalWeeks {
                    PlayMatchButton(
                        title: t(ar: "ابدأ المباراة", en: "Play Match", hi: "मैच शुरू करें", zh: "开始比赛", ku: "یاری دەستپێبکە"),
                        onTap: openMatchCenterFromHub
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                SimulateDaysButton(
                    title: t(ar: "محاكاة الأيام", en: "Simulate Days", hi: "दिनों का सिमुलेशन", zh: "模拟天数", ku: "شبیه‌کردنی ڕۆژەکان"),
                    disabled: matchWeek > totalWeeks || (isCurrentMatchDay && !isSimulatingDays),
                    isRunning: isSimulatingDays,
                    isMatchDay: isCurrentMatchDay,
                    onTap: runSimulateDays
                )
                .padding(.top, isCurrentMatchDay ? 12 : 28)

                NewsCard(
                    title: t(ar: "الأخبار", en: "News", hi: "समाचार", zh: "新闻", ku: "هەواڵەکان"),
                    headline: hubNewsHeadline(),
                    summary: hubNewsSummary(),
                    timeText: hubNewsTimestamp(),
                    selectedTeam: selectedTeam,
                    compact: true
                ) {
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
                        showMonthlyNews = true
                    }
                }
                .frame(height: newsCardHeight)
                .padding(.top, 12)
                .id(newsAnimationKey)
                .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.95)))
                .animation(.spring(response: 0.42, dampingFraction: 0.80), value: newsAnimationKey)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var teamView: some View {
        GeometryReader { proxy in
            let boxWidth = min(proxy.size.width * 0.9, 362)

            VStack(spacing: 26) {
                ForEach(teamHubCards) { card in
                    Button {
                        handleTeamHubCardTap(card)
                    } label: {
                        TeamHubPremiumCard(card: card)
                            .frame(width: boxWidth, height: 138)
                    }
                    .buttonStyle(PremiumTilePressStyle())
                    .hoverEffect(.lift)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, 10)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func handleTeamHubCardTap(_ card: TeamHubCard) {
        switch card.title {
        case "إدارة الفريق":
            showTeamManagementScreen = true
        case "مركز الفريق":
            showTeamCenterScreen = true
        case "مركز الانتقالات":
            showTransferCenterScreen = true
        default:
            break
        }
    }

    private var teamHubCards: [TeamHubCard] {
        [
            TeamHubCard(
                title: "إدارة الفريق",
                icon: "sportscourt.fill",
                colors: [Color(hex: 0x3A2DA8), Color(hex: 0x2D4DCE)],
                glowColor: Color(hex: 0x7D79FF),
                phase: 0.0
            ),
            TeamHubCard(
                title: "مركز الفريق",
                icon: "person.3.fill",
                colors: [Color(hex: 0x1F3C99), Color(hex: 0x1E6CD9)],
                glowColor: Color(hex: 0x55C7FF),
                phase: 1.7
            ),
            TeamHubCard(
                title: "مركز الانتقالات",
                icon: "arrow.left.arrow.right.circle.fill",
                colors: [Color(hex: 0x6A2DBD), Color(hex: 0xC94DB9)],
                glowColor: Color(hex: 0x6EE8E4),
                phase: 3.2
            )
        ]
    }

    private var managementView: some View {
        VStack(spacing: 14) {
            headerTitle(t(ar: "الإدارة", en: "Management", hi: "प्रबंधन", zh: "管理", ku: "بەڕێوەبردن"))

            contractBudgetCard

            infoRow(t(ar: "الميزانية", en: "Budget", hi: "बजट", zh: "预算", ku: "بودجە"), "$\(budgetM)M")
            infoRow(t(ar: "رضا الجماهير", en: "Fan Satisfaction", hi: "प्रशंसक संतुष्टि", zh: "球迷满意度", ku: "ڕەزامەندی هاندەران"), "\(fanSatisfaction)%")
            infoRow(t(ar: "هدف الموسم", en: "Season Target", hi: "सीज़न लक्ष्य", zh: "赛季目标", ku: "ئامانجی وەرز"), localizedSeasonTargetValue(seasonTarget, in: language))
            infoRow(t(ar: "حالة الهدف", en: "Target Status", hi: "लक्ष्य की स्थिति", zh: "目标状态", ku: "دۆخی ئامانج"), seasonTargetStatus())

            Button {
                showPlayerSearch = true
            } label: {
                Text(t(ar: "بحث وتفاوض على عقد لاعب", en: "Search and Negotiate a Player Contract", hi: "खिलाड़ी खोजें और अनुबंध पर बातचीत करें", zh: "搜索并谈判球员合同", ku: "گەڕان و دانوستان بۆ گرێبەستی یاریزان"))
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(FootballTheme.pitchGreen)
                    )
            }
            .buttonStyle(.plain)

            HStack {
                Text(t(ar: "الانتقالات", en: "Transfers", hi: "ट्रांसफ़र", zh: "转会", ku: "گواستنەوەکان"))
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
            }

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(transferTargets.indices, id: \.self) { idx in
                        transferCard(for: idx)
                    }
                }
            }
        }
    }

    private var tacticsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(t(ar: "الخطة الحالية", en: "Current Plan", hi: "वर्तमान योजना", zh: "当前阵型", ku: "پلانی ئێستا")): \(tacticalPlan.rawValue)")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(.white)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TacticalPlan.allCases, id: \.self) { plan in
                        Button {
                            tacticalPlan = plan
                        } label: {
                            VStack(spacing: 3) {
                                Text(plan.rawValue)
                                    .font(.system(size: 15, weight: .black))
                                Text(plan.localizedStyleName(in: language))
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundStyle(tacticalPlan == plan ? .black : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(tacticalPlan == plan ? FootballTheme.pitchGreen : FootballTheme.cardBase.opacity(0.72))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text("\(t(ar: "تأثير الخطة", en: "Plan Impact", hi: "योजना का प्रभाव", zh: "阵型影响", ku: "کاریگەری پلان")): \(t(ar: "هجوم", en: "Attack", hi: "आक्रमण", zh: "进攻", ku: "هێرش")) +\(tacticalPlan.attackBoost) | \(t(ar: "دفاع", en: "Defense", hi: "रक्षा", zh: "防守", ku: "بەرگری")) +\(tacticalPlan.defenseBoost)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.86))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(FootballTheme.cardBase.opacity(0.56))
        )
    }

    private var awardsSummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(t(ar: "الإنجازات والجوائز", en: "Achievements and Awards", hi: "उपलब्धियाँ और पुरस्कार", zh: "成就与奖项", ku: "دەستکەوت و خەڵاتەکان"))
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)

            Text("\(t(ar: "بطولات الدوري", en: "League Titles", hi: "लीग खिताब", zh: "联赛冠军", ku: "پاڵەوانییەکانی لیگ")): \(leagueTitlesWon)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(FootballTheme.pointsYellow)
            Text("\(t(ar: "مدرب الشهر", en: "Coach of the Month", hi: "महीने का कोच", zh: "月度最佳教练", ku: "ڕاهێنەری مانگ")): \(coachOfMonthAwards)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
            Text("\(t(ar: "الحذاء الذهبي", en: "Golden Boot", hi: "गोल्डन बूट", zh: "金靴奖", ku: "پێڵاوی زێڕین")): \(goldenBootAwards)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
            Text("\(t(ar: "هداف الفريق", en: "Top Scorer", hi: "शीर्ष स्कोरर", zh: "头号射手", ku: "باشترین گۆڵهێنەر")): \(localizedDisplayName(topScorerName, in: language)) (\(topScorerGoals))")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(FootballTheme.cardBase.opacity(0.62))
        )
    }

    private var contractBudgetCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(t(ar: "عقد المدرب", en: "Coach Contract", hi: "कोच का अनुबंध", zh: "教练合同", ku: "گرێبەستی ڕاهێنەر"))
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(.white)
                Text("\(t(ar: "متبقي", en: "Remaining", hi: "शेष", zh: "剩余", ku: "ماوە")) \(contractDaysRemaining()) \(t(ar: "يوم وينتهي العقد", en: "days until the contract ends", hi: "दिन, फिर अनुबंध समाप्त होगा", zh: "天后合同到期", ku: "ڕۆژ ماوە بۆ کۆتایی هاتنی گرێبەست"))")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))

                Divider().overlay(Color.white.opacity(0.3))

                Text("\(t(ar: "ميزانية الفريق", en: "Team Budget", hi: "टीम बजट", zh: "球队预算", ku: "بودجەی تیم")): $\(budgetM)M")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
            }
            Spacer()
            MoneyStickerView(amount: budgetM)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FootballTheme.cardBase.opacity(0.62))
        )
    }

    private func headerTitle(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(value)
                .font(.system(size: 18, weight: .bold))
            Spacer()
            Text(label)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
        }
        .foregroundStyle(.white)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(FootballTheme.cardBase.opacity(0.62))
        )
    }

    private func saveInfoPill(_ text: String, active: Bool) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .black))
            .foregroundStyle(active ? Color.black : .white.opacity(0.88))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(active ? Color.white.opacity(0.96) : Color.white.opacity(0.10))
            )
    }

    private func transferCard(for idx: Int) -> some View {
        let item = transferTargets[idx]

        return VStack(alignment: .leading, spacing: 9) {
            Text(localizedDisplayName(item.name, in: language))
                .font(.system(size: 19, weight: .black))
                .foregroundStyle(.white)

            HStack {
                Text("\(t(ar: "قوة", en: "Strength", hi: "ताकत", zh: "实力", ku: "هێز")) +\(item.boost)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.88))
                Spacer()

                Button {
                    signTransfer(at: idx)
                } label: {
                    Text(item.purchased
                         ? t(ar: "تم التوقيع", en: "Signed", hi: "साइन हो गया", zh: "已签约", ku: "واژۆ کرا")
                         : "\(t(ar: "توقيع", en: "Sign", hi: "साइन", zh: "签约", ku: "واژۆ")) $\(item.costM)M")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(item.purchased ? .black : .white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(item.purchased ? FootballTheme.pitchGreen.opacity(0.95) : FootballTheme.cardBase.opacity(0.74))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(item.purchased || budgetM < item.costM)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(FootballTheme.cardBase.opacity(0.62))
        )
    }

    private func playerSquare(_ player: TeamPlayer) -> some View {
        VStack(spacing: 8) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.95), Color.white.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 58, height: 58)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(FootballTheme.pitchGreen)
                )

            Text(localizedDisplayName(player.name, in: language))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text("#\(player.number) • \(player.role)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(FootballTheme.cardBase.opacity(0.62))
        )
    }

    private func goBackToMainMenu() {
        stopSimulation(manual: false)
        showCompetitions = false
        showTodayMatchesScreen = false
        showMatchCenter = false
        showTeamRecord = false
        showTeamManagementScreen = false
        showTeamCenterScreen = false
        showTransferCenterScreen = false
        showPlayerSearch = false
        showNegotiationSheet = false
        showMonthlyNews = false
        isSimulatingDays = false
        negotiationPlayerIndex = nil

        withAnimation(.easeInOut) {
            step = .welcome
        }
    }

    private func saveGame() {
        let payload = GameSaveData(
            stepRaw: stepRawValue(step),
            selectedLeagueName: selectedLeague?.name,
            selectedTeam: selectedTeam,
            currentTabRaw: currentTab.rawValue,
            seasonTable: seasonTable,
            matchWeek: matchWeek,
            totalWeeks: totalWeeks,
            previousResult: previousResult,
            managerNote: managerNote,
            budgetM: budgetM,
            fanSatisfaction: fanSatisfaction,
            squadStrength: squadStrength,
            injuries: injuries,
            seasonTarget: seasonTarget,
            transferTargets: transferTargets,
            marketPlayers: marketPlayers,
            seasonStartDate: seasonStartDate,
            currentDate: currentDate,
            calendarDisplayDate: calendarDisplayDate,
            contractEndDate: contractEndDate,
            lineup: lineup,
            bench: bench,
            selectedLiveLeagueRaw: selectedLiveLeague.rawValue,
            tacticalPlanRaw: tacticalPlan.rawValue,
            leagueTitlesWon: leagueTitlesWon,
            coachOfMonthAwards: coachOfMonthAwards,
            goldenBootAwards: goldenBootAwards,
            topScorerName: topScorerName,
            topScorerGoals: topScorerGoals,
            playerSeasonGoals: playerSeasonGoals,
            achievementLog: achievementLog,
            recentFormPoints: recentFormPoints,
            clubNewsFeed: clubNewsFeed,
            teamMatchHistory: teamMatchHistory
        )

        do {
            let encoded = try JSONEncoder().encode(payload)
            UserDefaults.standard.set(encoded, forKey: gameSaveKey)
            savedCareerSnapshot = payload
            managerNote = "تم حفظ اللعبة بنجاح"
        } catch {
            managerNote = "فشل الحفظ، حاول مرة ثانية"
        }
    }

    private func restoreSavedGameIfNeeded() {
        guard !hasAttemptedRestore else { return }
        hasAttemptedRestore = true

        guard let data = UserDefaults.standard.data(forKey: gameSaveKey) else { return }

        do {
            let saved = try JSONDecoder().decode(GameSaveData.self, from: data)
            if saved.selectedTeam != nil && saved.selectedLeagueName != nil {
                savedCareerSnapshot = saved
            }
        } catch {
            // Ignore corrupted save silently and keep current defaults.
        }
    }

    private func hasSavedCareer() -> Bool {
        savedCareerSnapshot?.selectedTeam != nil && savedCareerSnapshot?.selectedLeagueName != nil
    }

    private func continueSavedCareer() {
        if !hasAttemptedRestore {
            restoreSavedGameIfNeeded()
        }

        guard let saved = savedCareerSnapshot else { return }

        withAnimation(.easeInOut) {
            applySavedGame(saved)
        }
    }

    private func deleteSavedCareer() {
        UserDefaults.standard.removeObject(forKey: gameSaveKey)
        hasAttemptedRestore = true

        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            savedCareerSnapshot = nil
        }

        managerNote = t(
            ar: "تم حذف المهنة المحفوظة",
            en: "The saved career was deleted",
            hi: "सेव करियर हटा दिया गया",
            zh: "已删除保存的生涯",
            ku: "پیشەی هەڵگیراو سڕدرایەوە"
        )
    }

    private func applySavedGame(_ saved: GameSaveData) {
        stopSimulation(manual: false)
        selectedLeague = saved.selectedLeagueName.flatMap { leagueName in
            topLeagues.first(where: { $0.name == leagueName })
        }
        selectedTeam = saved.selectedTeam
        currentTab = DashboardTab(rawValue: saved.currentTabRaw) ?? .simulator

        seasonTable = saved.seasonTable
        matchWeek = max(1, saved.matchWeek)
        totalWeeks = max(1, saved.totalWeeks)
        previousResult = saved.previousResult
        managerNote = saved.managerNote

        budgetM = saved.budgetM
        fanSatisfaction = saved.fanSatisfaction
        squadStrength = saved.squadStrength
        injuries = saved.injuries
        seasonTarget = saved.seasonTarget
        transferTargets = saved.transferTargets
        marketPlayers = saved.marketPlayers

        seasonStartDate = saved.seasonStartDate
        currentDate = saved.currentDate
        calendarDisplayDate = saved.calendarDisplayDate
        contractEndDate = saved.contractEndDate
        simulationDateToken = 0
        simulationMatchFocus = false

        lineup = saved.lineup
        bench = saved.bench
        let restoredLiveLeague = LiveTopLeague(rawValue: saved.selectedLiveLeagueRaw) ?? .premierLeague
        selectedLiveLeague = LiveTopLeague.allCases.contains(restoredLiveLeague) ? restoredLiveLeague : .premierLeague
        tacticalPlan = TacticalPlan(rawValue: saved.tacticalPlanRaw ?? "") ?? .fourThreeThree

        leagueTitlesWon = saved.leagueTitlesWon ?? 0
        coachOfMonthAwards = saved.coachOfMonthAwards ?? 0
        goldenBootAwards = saved.goldenBootAwards ?? 0
        topScorerName = saved.topScorerName ?? "لا يوجد"
        topScorerGoals = saved.topScorerGoals ?? 0
        playerSeasonGoals = saved.playerSeasonGoals ?? [:]
        achievementLog = saved.achievementLog ?? []
        recentFormPoints = saved.recentFormPoints ?? []
        clubNewsFeed = saved.clubNewsFeed ?? []
        teamMatchHistory = saved.teamMatchHistory ?? [:]
        if let league = selectedLeague {
            for teamName in league.teams where teamMatchHistory[teamName] == nil {
                teamMatchHistory[teamName] = []
            }
        }

        let restoredStep = gameStep(from: saved.stepRaw)
        if restoredStep == .dashboard && (selectedLeague == nil || selectedTeam == nil) {
            step = .welcome
        } else {
            step = restoredStep
        }
    }

    private func stepRawValue(_ step: GameStep) -> String {
        switch step {
        case .welcome: return "welcome"
        case .leagueSelection: return "leagueSelection"
        case .teamSelection: return "teamSelection"
        case .dashboard: return "dashboard"
        }
    }

    private func gameStep(from raw: String) -> GameStep {
        switch raw {
        case "leagueSelection": return .leagueSelection
        case "teamSelection": return .teamSelection
        case "dashboard": return .dashboard
        default: return .welcome
        }
    }

    private func startCareer(with team: String) {
        guard let league = selectedLeague else { return }
        selectedTeam = team
        currentTab = .simulator
        configureNewSeason(for: league, team: team)

        withAnimation {
            step = .dashboard
        }
    }

    private func configureNewSeason(for league: League, team: String) {
        stopSimulation(manual: false)
        var table: [String: TeamStanding] = [:]
        league.teams.forEach { table[$0] = TeamStanding() }

        seasonTable = table
        totalWeeks = max(34, (league.teams.count - 1) * 2)
        matchWeek = 1
        previousResult = "لم تُلعب أي مباراة بعد"
        managerNote = "موسم جديد بدأ مع \(team)"

        seasonStartDate = Date()
        currentDate = seasonStartDate
        calendarDisplayDate = seasonStartDate
        contractEndDate = Calendar.current.date(byAdding: .day, value: 365, to: seasonStartDate) ?? seasonStartDate
        simulationDateToken = 0
        simulationMatchFocus = false

        budgetM = 120
        fanSatisfaction = 85
        squadStrength = 74
        tacticalPlan = .fourThreeThree
        injuries = 1
        seasonTarget = "إنهاء الموسم ضمن أول 4"
        negotiationPlayerIndex = nil
        showNegotiationSheet = false
        leagueTitlesWon = 0
        coachOfMonthAwards = 0
        goldenBootAwards = 0
        topScorerName = "لا يوجد"
        topScorerGoals = 0
        playerSeasonGoals = [:]
        achievementLog = []
        recentFormPoints = []
        clubNewsFeed = []
        teamMatchHistory = league.teams.reduce(into: [:]) { partial, teamName in
            partial[teamName] = []
        }
        showMonthlyNews = false
        isSimulatingDays = false
        transferTargets = [
            TransferOption(name: "مهاجم هداف", costM: 45, boost: 6),
            TransferOption(name: "صانع ألعاب", costM: 32, boost: 4),
            TransferOption(name: "مدافع صلب", costM: 27, boost: 3),
            TransferOption(name: "حارس مميز", costM: 24, boost: 2)
        ]
        marketPlayers = [
            MarketPlayer(name: "كيليان مبابي", costM: 95, boost: 11),
            MarketPlayer(name: "إيرلينغ هالاند", costM: 90, boost: 10),
            MarketPlayer(name: "جود بيلينغهام", costM: 82, boost: 9),
            MarketPlayer(name: "فينيسيوس جونيور", costM: 88, boost: 10),
            MarketPlayer(name: "جمال موسيالا", costM: 64, boost: 8),
            MarketPlayer(name: "رودري", costM: 59, boost: 7),
            MarketPlayer(name: "محمد صلاح", costM: 55, boost: 7),
            MarketPlayer(name: "لاعب شاب واعد", costM: 22, boost: 4),
            MarketPlayer(name: "مهاجم سريع", costM: 28, boost: 5),
            MarketPlayer(name: "قلب دفاع صلب", costM: 26, boost: 4)
        ]

        let squad = generateSquad(for: team)
        lineup = squad.starters
        bench = squad.bench
        appendNews(
            title: t(ar: "بداية موسم جديد", en: "A New Season Begins", hi: "नया सीज़न शुरू", zh: "新赛季开始", ku: "دەستپێکی وەرزی نوێ"),
            summary: t(
                ar: "النادي بدأ التحضيرات الرسمية للموسم الحالي تحت قيادة الجهاز الفني الجديد.",
                en: "The club has started official preparations for the current season under the coaching staff.",
                hi: "क्लब ने कोचिंग स्टाफ के साथ मौजूदा सीज़न की आधिकारिक तैयारियाँ शुरू कर दी हैं।",
                zh: "俱乐部已在教练组带领下启动本赛季官方备战。",
                ku: "یانەکە لەژێر سەرپەرشتی دەستەی ڕاهێنان ئامادەکارییە فەرمییەکانی وەرزەکە دەستی پێکرد."
            ),
            date: seasonStartDate,
            icon: "calendar.badge.clock"
        )
    }

    private func hubDateText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.dateFormat = "EEEE d MMM"
        return formatter.string(from: date)
    }

    private func hubTimeText(for date: Date) -> String? {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: date)
        let minute = cal.component(.minute, from: date)
        guard hour != 0 || minute != 0 else { return nil }

        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    private func runSimulateDays() {
        if isSimulatingDays {
            stopSimulation(manual: true)
            return
        }

        guard matchWeek <= totalWeeks else { return }
        guard !isTodayMatchDay() else {
            managerNote = t(
                ar: "اليوم يوم مباراة. استخدم زر ابدأ المباراة.",
                en: "Today is match day. Use the Play Match button.",
                hi: "आज मैच डे है। प्ले मैच बटन का उपयोग करें।",
                zh: "今天是比赛日，请使用“开始比赛”按钮。",
                ku: "ئەمڕۆ ڕۆژی یارییە. دوگمەی دەستپێکردنی یاری بەکاربهێنە."
            )
            return
        }
        startSimulationLoop()
    }

    private func openMatchCenterFromHub() {
        guard matchWeek <= totalWeeks else { return }
        guard isTodayMatchDay() else { return }
        stopSimulation(manual: false)
        withAnimation(.easeInOut(duration: 0.28)) {
            showMatchCenter = true
        }
    }

    private func startSimulationLoop() {
        guard !isSimulatingDays else { return }

        isSimulatingDays = true
        simulationMatchFocus = false
        managerNote = t(
            ar: "جاري تشغيل محاكاة الأيام...",
            en: "Simulation is running...",
            hi: "सिमुलेशन चल रहा है...",
            zh: "模拟正在运行...",
            ku: "شبیه‌کردن لە کاردایە..."
        )

        simulationTask?.cancel()
        simulationTask = Task { @MainActor in
            await simulateTimelineDayByDay()
        }
    }

    private func stopSimulation(manual: Bool) {
        simulationTask?.cancel()
        simulationTask = nil
        isSimulatingDays = false
        simulationMatchFocus = false

        if manual {
            managerNote = t(
                ar: "تم إيقاف المحاكاة",
                en: "Simulation stopped",
                hi: "सिमुलेशन रोका गया",
                zh: "模拟已停止",
                ku: "شبیه‌کردن وەستێنرا"
            )
        }
    }

    @MainActor
    private func simulateTimelineDayByDay() async {
        var pausedForMatchDay = false

        while isSimulatingDays && matchWeek <= totalWeeks {
            guard let fixture = nextFixture() else { break }

            let cal = Calendar.current
            let today = cal.startOfDay(for: currentDate)
            let matchDay = cal.startOfDay(for: fixture.date)

            if today < matchDay {
                let daysToMatch = max(0, cal.dateComponents([.day], from: today, to: matchDay).day ?? 0)
                await simulateRegularDay(daysToMatch: daysToMatch)
                continue
            }

            pausedForMatchDay = true
            withAnimation(.easeInOut(duration: 0.26)) {
                simulationMatchFocus = true
            }
            managerNote = t(
                ar: "يوم المباراة: \(localizedDisplayName(fixture.opponent, in: language))",
                en: "Match day: \(localizedDisplayName(fixture.opponent, in: language))",
                hi: "मैच डे: \(localizedDisplayName(fixture.opponent, in: language))",
                zh: "比赛日：\(localizedDisplayName(fixture.opponent, in: language))",
                ku: "ڕۆژی یاری: \(localizedDisplayName(fixture.opponent, in: language))"
            )
            isSimulatingDays = false
            simulationTask = nil
            break
        }

        if !pausedForMatchDay {
            simulationTask = nil
            isSimulatingDays = false
            withAnimation(.easeOut(duration: 0.22)) {
                simulationMatchFocus = false
            }
        }
    }

    @MainActor
    private func simulateRegularDay(daysToMatch: Int) async {
        let nearMatch = daysToMatch <= 2
        let delay: UInt64 = nearMatch ? 650_000_000 : 380_000_000

        withAnimation(.spring(response: 0.42, dampingFraction: 0.80)) {
            simulateOneDay()
        }

        if nearMatch && daysToMatch > 0 {
            managerNote = t(
                ar: "التحضير للمباراة خلال \(daysToMatch) يوم",
                en: "Preparing for the match in \(daysToMatch) day(s)",
                hi: "मैच की तैयारी: \(daysToMatch) दिन बाकी",
                zh: "距离比赛还有 \(daysToMatch) 天，正在备战",
                ku: "ئامادەکاری بۆ یاری، \(daysToMatch) ڕۆژ ماوە"
            )
        }

        maybeAppendSimulationSideNews(daysToMatch: daysToMatch)
        try? await Task.sleep(nanoseconds: delay)
    }

    private func maybeAppendSimulationSideNews(daysToMatch: Int) {
        guard isSimulatingDays else { return }
        guard daysToMatch > 0 else { return }

        let roll = Int.random(in: 1...100)

        if roll <= 4 {
            appendNews(
                title: t(ar: "خبر النادي", en: "Club Update", hi: "क्लब अपडेट", zh: "俱乐部动态", ku: "نوێکاری یانە"),
                summary: t(
                    ar: "الإدارة تؤكد استمرار الدعم الفني مع تركيز كامل على الاستقرار.",
                    en: "The board confirms continued technical support with full focus on stability.",
                    hi: "प्रबंधन ने स्थिरता पर पूरा ध्यान देते हुए तकनीकी समर्थन जारी रखने की पुष्टि की।",
                    zh: "管理层确认将继续技术支持，并专注于稳定性。",
                    ku: "بەڕێوەبەرایەتی پشتگیری فەنی بەردەوام دەکات و سەرنجی تەواوی لەسەر جێگیرییە."
                ),
                date: currentDate,
                icon: "building.2.fill"
            )
        } else if roll <= 7 {
            appendNews(
                title: t(ar: "مؤشر إصابة", en: "Fitness Alert", hi: "फिटनेस अलर्ट", zh: "体能提醒", ku: "ئاگاداری تەندروستی"),
                summary: t(
                    ar: "الجهاز الطبي يوصي بتخفيف الأحمال التدريبية لبعض اللاعبين.",
                    en: "The medical staff recommends reducing training loads for some players.",
                    hi: "मेडिकल स्टाफ ने कुछ खिलाड़ियों के लिए ट्रेनिंग लोड कम करने की सलाह दी है।",
                    zh: "医疗团队建议部分球员降低训练负荷。",
                    ku: "دەستەی پزیشکی پێشنیاری کەمکردنەوەی بارودۆخی ڕاهێنان بۆ هەندێک یاریزان دەکات."
                ),
                date: currentDate,
                icon: "waveform.path.ecg"
            )
        } else if roll <= 10 {
            appendNews(
                title: t(ar: "تحرك في سوق الانتقالات", en: "Transfer Market Movement", hi: "ट्रांसफ़र बाज़ार में हलचल", zh: "转会市场动态", ku: "هەوڵی بازاڕی گواستنەوە"),
                summary: t(
                    ar: "تقارير تربط النادي بخيارات جديدة قبل الفترة المقبلة.",
                    en: "Reports link the club with new options ahead of the next window.",
                    hi: "रिपोर्ट्स क्लब को अगली विंडो से पहले नए विकल्पों से जोड़ रही हैं।",
                    zh: "有报道称俱乐部在下个窗口前关注新的引援选择。",
                    ku: "ڕاپۆرتەکان یانەکە بە هەڵبژاردەی نوێ گرێدەدەن پێش ماوەی داهاتوو."
                ),
                date: currentDate,
                icon: "arrow.left.arrow.right.circle"
            )
        }
    }

    private func simulatedGoals(for strength: Int) -> Int {
        switch strength {
        case ..<55:
            return Int.random(in: 0...1)
        case 55..<70:
            return Int.random(in: 0...2)
        case 70..<84:
            return Int.random(in: 1...3)
        default:
            return Int.random(in: 1...4)
        }
    }

    private func appendNews(title: String, summary: String, date: Date, icon: String) {
        let item = ClubNewsItem(title: title, summary: summary, date: date, icon: icon)
        clubNewsFeed.append(item)
        clubNewsFeed.sort { $0.date > $1.date }
        if clubNewsFeed.count > 220 {
            clubNewsFeed.removeLast(clubNewsFeed.count - 220)
        }
    }

    private func currentMonthNewsItems() -> [ClubNewsItem] {
        let cal = Calendar.current
        let month = cal.component(.month, from: currentDate)
        let year = cal.component(.year, from: currentDate)

        return clubNewsFeed
            .filter {
                cal.component(.month, from: $0.date) == month &&
                    cal.component(.year, from: $0.date) == year
            }
            .sorted { $0.date > $1.date }
    }

    private func currentMonthTitle() -> String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: currentDate)
    }

    private func closeMonthlyNews() {
        withAnimation(.easeInOut(duration: 0.34)) {
            showMonthlyNews = false
        }
    }

    private func daysUntilNextMatch() -> Int? {
        guard let fixture = nextFixture() else { return nil }
        let cal = Calendar.current
        let today = cal.startOfDay(for: currentDate)
        let next = cal.startOfDay(for: fixture.date)
        return max(0, cal.dateComponents([.day], from: today, to: next).day ?? 0)
    }

    private func isTodayMatchDay() -> Bool {
        guard let fixture = nextFixture() else { return false }
        return Calendar.current.isDate(currentDate, inSameDayAs: fixture.date)
    }

    private func latestNewsAnimationKey() -> String {
        if let latest = currentMonthNewsItems().first {
            return latest.id.uuidString
        }
        let cal = Calendar.current
        let month = cal.component(.month, from: currentDate)
        let year = cal.component(.year, from: currentDate)
        return "empty-\(year)-\(month)"
    }

    private func hubNewsHeadline() -> String {
        if let latest = currentMonthNewsItems().first {
            return latest.title
        }

        if matchWeek > totalWeeks {
            return t(
                ar: "ختام الموسم وتقييم شامل",
                en: "Season wrap-up and full review",
                hi: "सीज़न समापन और पूर्ण समीक्षा",
                zh: "赛季收官与全面评估",
                ku: "کۆتایی وەرز و هەڵسەنگاندنی تەواو"
            )
        }

        if let fixture = nextFixture() {
            return t(
                ar: "استعدادات قبل مواجهة \(localizedDisplayName(fixture.opponent, in: language))",
                en: "Preparations ahead of \(localizedDisplayName(fixture.opponent, in: language))",
                hi: "\(localizedDisplayName(fixture.opponent, in: language)) के मुकाबले से पहले तैयारी",
                zh: "对阵 \(localizedDisplayName(fixture.opponent, in: language)) 前的备战",
                ku: "ئامادەکاری پێش یاری لەگەڵ \(localizedDisplayName(fixture.opponent, in: language))"
            )
        }

        return t(
            ar: "غرفة الملابس تنتظر البداية",
            en: "The locker room is waiting for kickoff",
            hi: "ड्रेसिंग रूम शुरुआत का इंतज़ार कर रहा है",
            zh: "更衣室正在等待开赛",
            ku: "ژووری جل گۆڕین چاوەڕێی دەستپێکە"
        )
    }

    private func hubNewsSummary() -> String {
        if let latest = currentMonthNewsItems().first {
            return latest.summary
        }

        if previousResult == "لم تُلعب أي مباراة بعد" {
            return t(
                ar: "الجهاز الفني يركز على الانسجام بين الخطوط قبل أول اختبار رسمي. لا توجد مباراة سابقة بعد.",
                en: "The coaching staff is focused on team cohesion before the first official test. No previous match has been played yet.",
                hi: "कोचिंग स्टाफ पहली आधिकारिक परीक्षा से पहले टीम तालमेल पर ध्यान दे रहा है। अभी तक कोई पिछला मैच नहीं खेला गया है।",
                zh: "教练组正专注于首场正式比赛前的团队磨合。目前尚未进行任何上一场比赛。",
                ku: "دەستەی ڕاهێنان سەرنجی لەسەر هاوسەنگی هێڵەکانە پێش یەکەم تاقیکردنەوەی فەرمی. هێشتا هیچ یارییەکی پێشوو نەکراوە."
            )
        }

        return localizedManagerNote(managerNote, in: language)
    }

    private func hubNewsTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: currentMonthNewsItems().first?.date ?? currentDate)
    }

    private func nextFixture() -> MatchFixture? {
        guard
            let league = selectedLeague,
            let team = selectedTeam,
            let index = league.teams.firstIndex(of: team),
            league.teams.count > 2,
            matchWeek <= totalWeeks
        else {
            return nil
        }

        let shift = ((matchWeek - 1) % (league.teams.count - 1)) + 1
        var opponent = league.teams[(index + shift) % league.teams.count]
        if opponent == team {
            opponent = league.teams[(index + shift + 1) % league.teams.count]
        }

        let date = fixtureDate(for: matchWeek)
        if matchWeek % 2 == 1 {
            return MatchFixture(home: team, away: opponent, opponent: opponent, date: date)
        }
        return MatchFixture(home: opponent, away: team, opponent: opponent, date: date)
    }

    private func fixtureDate(for week: Int) -> Date {
        let cal = Calendar.current
        let base = cal.startOfDay(for: seasonStartDate)
        let weekIndex = max(0, (week - 1) / 2)
        let slotInWeek = max(0, (week - 1) % 2)
        let offsetWithinWeek = slotInWeek == 0 ? 2 : 5
        let dayOffset = (weekIndex * 7) + offsetWithinWeek
        let matchDay = cal.date(byAdding: .day, value: dayOffset, to: base) ?? base
        let hour = slotInWeek == 0 ? 20 : 21
        return cal.date(bySettingHour: hour, minute: 0, second: 0, of: matchDay) ?? matchDay
    }

    private func applyMatchResult(myGoals: Int, oppGoals: Int, summary: String) {
        guard
            let league = selectedLeague,
            let team = selectedTeam,
            let fixture = nextFixture(),
            matchWeek <= totalWeeks
        else {
            return
        }

        let opponent = fixture.opponent
        let myClubGoalsAsHome = fixture.home == team ? myGoals : oppGoals
        let myClubGoalsAsAway = fixture.away == team ? myGoals : oppGoals
        applyFixtureResult(
            home: fixture.home,
            away: fixture.away,
            homeGoals: myClubGoalsAsHome,
            awayGoals: myClubGoalsAsAway,
            date: fixture.date
        )

        var others = league.teams.filter { $0 != team && $0 != opponent }.shuffled()
        while others.count >= 2 {
            let home = others.removeFirst()
            let away = others.removeFirst()
            let g1 = Int.random(in: 0...4)
            let g2 = Int.random(in: 0...4)
            applyFixtureResult(
                home: home,
                away: away,
                homeGoals: g1,
                awayGoals: g2,
                date: fixture.date
            )
        }

        previousResult = "\(fixture.home) \(fixture.home == team ? myGoals : oppGoals) - \(fixture.away == team ? myGoals : oppGoals) \(fixture.away)"
        registerGoalScorers(goals: myGoals)

        let playedWeek = matchWeek
        let pointsGained: Int

        if myGoals > oppGoals {
            budgetM += 4
            fanSatisfaction = min(100, fanSatisfaction + 3)
            pointsGained = 3
        } else if myGoals == oppGoals {
            budgetM += 1
            fanSatisfaction = min(100, fanSatisfaction + 1)
            pointsGained = 1
        } else {
            budgetM = max(0, budgetM - 2)
            fanSatisfaction = max(45, fanSatisfaction - 3)
            pointsGained = 0
        }

        updateAwardsAfterMatch(playedWeek: playedWeek, pointsGained: pointsGained)

        injuries = max(0, min(4, injuries + Int.random(in: -1...1)))
        currentDate = fixture.date
        calendarDisplayDate = fixture.date
        simulationDateToken += 1
        withAnimation(.easeInOut(duration: 0.24)) {
            simulationMatchFocus = false
        }
        managerNote = summary
        appendNews(
            title: t(
                ar: "نتيجة الجولة \(playedWeek)",
                en: "Round \(playedWeek) Result",
                hi: "राउंड \(playedWeek) का परिणाम",
                zh: "第 \(playedWeek) 轮赛果",
                ku: "ئەنجامی دەوری \(playedWeek)"
            ),
            summary: "\(localizedDisplayName(team, in: language)) \(myGoals)-\(oppGoals) \(localizedDisplayName(opponent, in: language))",
            date: fixture.date,
            icon: "soccerball.inverse"
        )

        if pointsGained == 3 && currentTeamRank() <= 4 {
            appendNews(
                title: t(ar: "تحسن واضح في المستوى", en: "Clear Performance Improvement", hi: "प्रदर्शन में स्पष्ट सुधार", zh: "表现明显提升", ku: "پێشکەوتنی دیار لە ئاست"),
                summary: t(
                    ar: "الفريق يواصل جمع النقاط ويقترب من المراكز المتقدمة في الجدول.",
                    en: "The team keeps collecting points and is moving closer to top positions.",
                    hi: "टीम लगातार अंक जुटा रही है और शीर्ष स्थानों के करीब पहुँच रही है।",
                    zh: "球队持续拿分，正在逼近积分榜前列。",
                    ku: "تیمەکە بەردەوام خاڵ کۆدەکاتەوە و نزیک دەبێتەوە لە پلە پێشەکان."
                ),
                date: fixture.date,
                icon: "chart.line.uptrend.xyaxis"
            )
        }

        if injuries >= 3 {
            appendNews(
                title: t(ar: "تحديث الإصابات", en: "Injury Update", hi: "चोट अपडेट", zh: "伤病更新", ku: "نوێکردنەوەی برینداری"),
                summary: t(
                    ar: "الجهاز الطبي يتابع أكثر من حالة، وقد يؤثر ذلك على التشكيلة القادمة.",
                    en: "The medical staff is monitoring multiple cases, which may impact the next lineup.",
                    hi: "मेडिकल स्टाफ कई मामलों की निगरानी कर रहा है, इसका अगली लाइनअप पर असर हो सकता है।",
                    zh: "医疗团队正在跟进多起伤病，可能影响下一场阵容。",
                    ku: "دەستەی پزیشکی چەند دۆخێکی برینداری چاودێری دەکات و لەوانەیە کاریگەری لەسەر پێکهاتەی داهاتوو هەبێت."
                ),
                date: fixture.date,
                icon: "cross.case.fill"
            )
        }

        matchWeek += 1

        if matchWeek > totalWeeks {
            finalizeSeasonAwards()
            managerNote = "انتهى الموسم - المركز النهائي #\(currentTeamRank()) | الإنجازات: \(achievementLog.count)"
            appendNews(
                title: t(ar: "نهاية الموسم", en: "Season Finished", hi: "सीज़न समाप्त", zh: "赛季结束", ku: "کۆتایی وەرز"),
                summary: t(
                    ar: "اختتم الفريق الموسم في المركز #\(currentTeamRank()) مع سجل إنجازات \(achievementLog.count).",
                    en: "The team finished the season in rank #\(currentTeamRank()) with \(achievementLog.count) achievements.",
                    hi: "टीम ने सीज़न #\(currentTeamRank()) रैंक पर और \(achievementLog.count) उपलब्धियों के साथ समाप्त किया।",
                    zh: "球队以第 #\(currentTeamRank()) 名结束赛季，共有 \(achievementLog.count) 项成就。",
                    ku: "تیمەکە وەرزەکەی بە پلەی #\(currentTeamRank()) کۆتایی هێنا و \(achievementLog.count) دەستکەوتی هەبوو."
                ),
                date: fixture.date,
                icon: "flag.checkered"
            )
        }
    }

    private func applyFixtureResult(home: String, away: String, homeGoals: Int, awayGoals: Int, date: Date) {
        updateStanding(team: home, goalsFor: homeGoals, goalsAgainst: awayGoals)
        updateStanding(team: away, goalsFor: awayGoals, goalsAgainst: homeGoals)

        appendMatchHistory(
            team: home,
            opponent: away,
            date: date,
            goalsFor: homeGoals,
            goalsAgainst: awayGoals
        )
        appendMatchHistory(
            team: away,
            opponent: home,
            date: date,
            goalsFor: awayGoals,
            goalsAgainst: homeGoals
        )
    }

    private func updateStanding(team: String, goalsFor: Int, goalsAgainst: Int) {
        guard var stats = seasonTable[team] else { return }
        stats.apply(goalsFor: goalsFor, goalsAgainst: goalsAgainst)
        seasonTable[team] = stats
    }

    private func currentTeamRank() -> Int {
        guard let team = selectedTeam else { return 1 }
        return rankForTeam(team)
    }

    private func rankForTeam(_ team: String) -> Int {
        let sorted = sortedStandings()
        guard let idx = sorted.firstIndex(where: { $0.name == team }) else { return 1 }
        return idx + 1
    }

    private func appendMatchHistory(
        team: String,
        opponent: String,
        date: Date,
        goalsFor: Int,
        goalsAgainst: Int
    ) {
        let result: TeamMatchResult
        if goalsFor > goalsAgainst {
            result = .win
        } else if goalsFor == goalsAgainst {
            result = .draw
        } else {
            result = .loss
        }

        var history = teamMatchHistory[team] ?? []
        history.append(
            TeamMatchHistoryEntry(
                opponent: opponent,
                date: date,
                result: result,
                goalsFor: goalsFor,
                goalsAgainst: goalsAgainst
            )
        )
        if history.count > 80 {
            history.removeFirst(history.count - 80)
        }
        teamMatchHistory[team] = history
    }

    private func recentHistoryForMatchView(team: String, limit: Int = 5) -> [TeamMatchHistoryEntry] {
        let history = teamMatchHistory[team] ?? []
        return Array(history.suffix(limit).reversed())
    }

    private func sortedStandings() -> [(name: String, stats: TeamStanding)] {
        seasonTable
            .map { (name: $0.key, stats: $0.value) }
            .sorted {
                if $0.stats.points != $1.stats.points { return $0.stats.points > $1.stats.points }
                if $0.stats.goalDifference != $1.stats.goalDifference { return $0.stats.goalDifference > $1.stats.goalDifference }
                return $0.stats.goalsFor > $1.stats.goalsFor
            }
    }

    private func seasonTargetStatus() -> String {
        let rank = currentTeamRank()
        if matchWeek > totalWeeks {
            return rank <= 4
                ? t(ar: "تم تحقيق الهدف", en: "Target achieved", hi: "लक्ष्य पूरा हुआ", zh: "目标已达成", ku: "ئامانجەکە جێبەجێ بوو")
                : t(ar: "لم يتحقق الهدف", en: "Target not achieved", hi: "लक्ष्य पूरा नहीं हुआ", zh: "目标未达成", ku: "ئامانجەکە جێبەجێ نەبوو")
        }
        return rank <= 4
            ? t(ar: "حاليًا ضمن الهدف", en: "Currently on target", hi: "अभी लक्ष्य के भीतर", zh: "当前达成目标", ku: "ئێستا لە ناو ئامانجدا")
            : t(ar: "خارج الهدف حاليًا", en: "Currently off target", hi: "अभी लक्ष्य से बाहर", zh: "当前未达目标", ku: "ئێستا دەرەوەی ئامانجە")
    }

    private func registerGoalScorers(goals: Int) {
        guard goals > 0 else { return }
        for _ in 0..<goals {
            guard let scorer = lineup.randomElement()?.name else { continue }
            playerSeasonGoals[scorer, default: 0] += 1
        }

        if let best = playerSeasonGoals.max(by: { $0.value < $1.value }) {
            topScorerName = best.key
            topScorerGoals = best.value
        }
    }

    private func updateAwardsAfterMatch(playedWeek: Int, pointsGained: Int) {
        recentFormPoints.append(pointsGained)
        if recentFormPoints.count > 12 {
            recentFormPoints.removeFirst(recentFormPoints.count - 12)
        }

        if playedWeek % 4 == 0 {
            let recent = recentFormPoints.suffix(4).reduce(0, +)
            if recent >= 9 && currentTeamRank() <= 4 {
                coachOfMonthAwards += 1
                addAchievement("جائزة مدرب الشهر - الجولة \(playedWeek)")
            }
        }
    }

    private func finalizeSeasonAwards() {
        let rank = currentTeamRank()

        if rank == 1 {
            leagueTitlesWon += 1
            budgetM += 25
            fanSatisfaction = min(100, fanSatisfaction + 8)
            addAchievement("بطل الدوري")
        }

        if topScorerGoals >= 15 {
            goldenBootAwards += 1
            addAchievement("الحذاء الذهبي: \(topScorerName) - \(topScorerGoals) هدف")
        }

        if leagueTitlesWon >= 1 && coachOfMonthAwards >= 2 {
            addAchievement("موسم تاريخي للمدرب")
        }
    }

    private func addAchievement(_ text: String) {
        if !achievementLog.contains(text) {
            achievementLog.append(text)
        }
    }

    private func signTransfer(at index: Int) {
        guard transferTargets.indices.contains(index) else { return }
        guard !transferTargets[index].purchased else { return }

        let option = transferTargets[index]
        guard budgetM >= option.costM else {
            managerNote = "الميزانية غير كافية لهذه الصفقة"
            return
        }

        budgetM -= option.costM
        squadStrength = min(99, squadStrength + option.boost)
        transferTargets[index].purchased = true
        managerNote = "تم التوقيع مع \(option.name)"
        appendNews(
            title: t(ar: "صفقة جديدة", en: "New Signing", hi: "नई साइनिंग", zh: "新援签约", ku: "واژۆکردنی نوێ"),
            summary: t(
                ar: "النادي أنهى صفقة \(localizedDisplayName(option.name, in: language)) لتعزيز جودة التشكيلة.",
                en: "The club completed the signing of \(localizedDisplayName(option.name, in: language)) to improve squad quality.",
                hi: "क्लब ने स्क्वाड क्वालिटी बढ़ाने के लिए \(localizedDisplayName(option.name, in: language)) को साइन किया।",
                zh: "俱乐部完成 \(localizedDisplayName(option.name, in: language)) 的签约，以提升阵容质量。",
                ku: "یانەکە واژۆکردنی \(localizedDisplayName(option.name, in: language)) تەواو کرد بۆ باشترکردنی کوالێتی کادری تیم."
            ),
            date: currentDate,
            icon: "arrow.left.arrow.right.circle.fill"
        )

        if !bench.isEmpty {
            bench[0] = TeamPlayer(name: option.name, role: "SUP", number: Int.random(in: 40...99))
        }
    }

    private func startNegotiation(for index: Int) {
        guard marketPlayers.indices.contains(index) else { return }
        guard !marketPlayers[index].signed else { return }
        negotiationPlayerIndex = index
        showNegotiationSheet = true
    }

    private func finalizeNegotiation(for index: Int, salaryM: Int, years: Int, bonusM: Int) {
        guard marketPlayers.indices.contains(index) else { return }
        guard !marketPlayers[index].signed else { return }

        let player = marketPlayers[index]
        let transferFee = player.costM
        let totalPackage = transferFee + (salaryM * years) + bonusM
        let desiredSalary = max(3, player.costM / 16)
        let desiredBonus = max(1, player.costM / 22)

        guard budgetM >= totalPackage else {
            managerNote = "الميزانية لا تكفي لعرض \(player.name)"
            return
        }

        let yearsImpact = max(-2, min(6, (years - 3) * 2))
        let salaryImpact = (salaryM - desiredSalary) * 8
        let bonusImpact = (bonusM - desiredBonus) * 6
        let squadPull = (squadStrength - 70) / 3
        let acceptance = max(20, min(94, 50 + yearsImpact + salaryImpact + bonusImpact + squadPull))

        if Int.random(in: 1...100) <= acceptance {
            budgetM -= totalPackage
            squadStrength = min(99, squadStrength + player.boost)
            marketPlayers[index].signed = true
            managerNote = "نجحت المفاوضات مع \(player.name) | عقد \(years) سنوات"
            addAchievement("صفقة ناجحة: \(player.name)")
            addSignedPlayerToSquad(name: player.name)
            appendNews(
                title: t(ar: "اتفاق انتقال مكتمل", en: "Transfer Deal Completed", hi: "ट्रांसफ़र डील पूरी", zh: "转会交易完成", ku: "ڕێککەوتنی گواستنەوە تەواو بوو"),
                summary: t(
                    ar: "تم التوصل لاتفاق نهائي مع \(localizedDisplayName(player.name, in: language)) بعقد \(years) سنوات.",
                    en: "A final agreement was reached with \(localizedDisplayName(player.name, in: language)) on a \(years)-year contract.",
                    hi: "\(localizedDisplayName(player.name, in: language)) के साथ \(years) साल का अंतिम समझौता हो गया।",
                    zh: "已与 \(localizedDisplayName(player.name, in: language)) 达成最终协议，合同 \(years) 年。",
                    ku: "گەیشتن بە ڕێککەوتنی کۆتایی لەگەڵ \(localizedDisplayName(player.name, in: language)) بە گرێبەستی \(years) ساڵ."
                ),
                date: currentDate,
                icon: "person.badge.plus"
            )
        } else {
            managerNote = "فشلت المفاوضات مع \(player.name)، اللاعب رفض العرض"
            fanSatisfaction = max(45, fanSatisfaction - 1)
            appendNews(
                title: t(ar: "تعثر مفاوضات", en: "Negotiations Stalled", hi: "बातचीत अटकी", zh: "谈判受阻", ku: "دانوستان وەستا"),
                summary: t(
                    ar: "المفاوضات مع \(localizedDisplayName(player.name, in: language)) لم تصل لاتفاق نهائي بعد.",
                    en: "Negotiations with \(localizedDisplayName(player.name, in: language)) did not reach a final agreement yet.",
                    hi: "\(localizedDisplayName(player.name, in: language)) के साथ बातचीत अभी अंतिम समझौते तक नहीं पहुँची।",
                    zh: "与 \(localizedDisplayName(player.name, in: language)) 的谈判尚未达成最终协议。",
                    ku: "دانوستان لەگەڵ \(localizedDisplayName(player.name, in: language)) هێشتا نەگەیشتووە بە ڕێککەوتنی کۆتایی."
                ),
                date: currentDate,
                icon: "exclamationmark.triangle.fill"
            )
        }
    }

    private func addSignedPlayerToSquad(name: String) {
        if bench.count >= 7 {
            bench[6] = TeamPlayer(name: name, role: "NEW", number: Int.random(in: 50...99))
        } else {
            bench.append(TeamPlayer(name: name, role: "NEW", number: Int.random(in: 50...99)))
        }
    }

    private func contractDaysRemaining() -> Int {
        let days = Calendar.current.dateComponents([.day], from: currentDate, to: contractEndDate).day ?? 0
        return max(0, days)
    }

    private func generateSquad(for team: String) -> (starters: [TeamPlayer], bench: [TeamPlayer]) {
        if team == "أتلتيكو مدريد" || team == "Atletico Madrid" {
            let starters: [TeamPlayer] = [
                TeamPlayer(name: "Jan Oblak", role: "GK", number: 13),
                TeamPlayer(name: "Nahuel Molina", role: "RB", number: 16),
                TeamPlayer(name: "Robin Le Normand", role: "CB", number: 24),
                TeamPlayer(name: "Jose Maria Gimenez", role: "CB", number: 2),
                TeamPlayer(name: "Matteo Ruggeri", role: "LB", number: 3),
                TeamPlayer(name: "Johnny Cardoso", role: "DM", number: 5),
                TeamPlayer(name: "Koke", role: "CM", number: 6),
                TeamPlayer(name: "Pablo Barrios", role: "CM", number: 8),
                TeamPlayer(name: "Antoine Griezmann", role: "SS", number: 7),
                TeamPlayer(name: "Julian Alvarez", role: "ST", number: 19),
                TeamPlayer(name: "Alex Baena", role: "LW", number: 10)
            ]

            let bench: [TeamPlayer] = [
                TeamPlayer(name: "Juan Musso", role: "GK", number: 1),
                TeamPlayer(name: "Clement Lenglet", role: "CB", number: 15),
                TeamPlayer(name: "Marcos Llorente", role: "RB", number: 14),
                TeamPlayer(name: "David Hancko", role: "CB", number: 17),
                TeamPlayer(name: "Marc Pubill", role: "RB", number: 18),
                TeamPlayer(name: "Rodrigo Mendoza", role: "CM", number: 27),
                TeamPlayer(name: "Obed Vargas", role: "CM", number: 28),
                TeamPlayer(name: "Thiago Almada", role: "AM", number: 11),
                TeamPlayer(name: "Ademola Lookman", role: "SS", number: 22),
                TeamPlayer(name: "Alexander Sorloth", role: "ST", number: 9),
                TeamPlayer(name: "Giuliano Simeone", role: "RW", number: 20),
                TeamPlayer(name: "Nico Gonzalez", role: "RW", number: 23)
            ]

            return (starters, bench)
        } else if team == "ريال مدريد" || team == "Real Madrid" {
            let starters: [TeamPlayer] = [
                TeamPlayer(name: "Thibaut Courtois", role: "GK", number: 1),
                TeamPlayer(name: "Dani Carvajal", role: "RB", number: 2),
                TeamPlayer(name: "Eder Militao", role: "CB", number: 3),
                TeamPlayer(name: "Antonio Rudiger", role: "CB", number: 22),
                TeamPlayer(name: "Ferland Mendy", role: "LB", number: 23),
                TeamPlayer(name: "Aurelien Tchouameni", role: "DM", number: 14),
                TeamPlayer(name: "Federico Valverde", role: "CM", number: 8),
                TeamPlayer(name: "Jude Bellingham", role: "AM", number: 5),
                TeamPlayer(name: "Rodrygo", role: "RW", number: 11),
                TeamPlayer(name: "Kylian Mbappe", role: "ST", number: 10),
                TeamPlayer(name: "Vinicius Junior", role: "LW", number: 7)
            ]

            let bench: [TeamPlayer] = [
                TeamPlayer(name: "Andriy Lunin", role: "GK", number: 13),
                TeamPlayer(name: "David Alaba", role: "CB", number: 4),
                TeamPlayer(name: "Trent Alexander-Arnold", role: "RB", number: 12),
                TeamPlayer(name: "Raul Asencio", role: "CB", number: 17),
                TeamPlayer(name: "Dean Huijsen", role: "CB", number: 24),
                TeamPlayer(name: "Alvaro Carreras", role: "LB", number: 18),
                TeamPlayer(name: "Fran Garcia", role: "LB", number: 20),
                TeamPlayer(name: "Eduardo Camavinga", role: "CM", number: 6),
                TeamPlayer(name: "Arda Guler", role: "AM", number: 15),
                TeamPlayer(name: "Dani Ceballos", role: "CM", number: 19),
                TeamPlayer(name: "Thiago Pitarch", role: "CM", number: 45),
                TeamPlayer(name: "Gonzalo Garcia", role: "ST", number: 16),
                TeamPlayer(name: "Brahim Diaz", role: "RW", number: 21),
                TeamPlayer(name: "Franco Mastantuono", role: "RW", number: 30)
            ]

            return (starters, bench)
        } else if team == "برشلونة" || team == "Barcelona" {
            let starters: [TeamPlayer] = [
                TeamPlayer(name: "Joan Garcia", role: "GK", number: 13),
                TeamPlayer(name: "Joao Cancelo", role: "RB", number: 2),
                TeamPlayer(name: "Ronald Araujo", role: "CB", number: 4),
                TeamPlayer(name: "Pau Cubarsi", role: "CB", number: 5),
                TeamPlayer(name: "Alejandro Balde", role: "LB", number: 3),
                TeamPlayer(name: "Marc Casado", role: "DM", number: 17),
                TeamPlayer(name: "Pedri", role: "CM", number: 8),
                TeamPlayer(name: "Gavi", role: "CM", number: 6),
                TeamPlayer(name: "Lamine Yamal", role: "RW", number: 10),
                TeamPlayer(name: "Robert Lewandowski", role: "ST", number: 9),
                TeamPlayer(name: "Raphinha", role: "LW", number: 11)
            ]

            let bench: [TeamPlayer] = [
                TeamPlayer(name: "Frenkie de Jong", role: "CM", number: 21),
                TeamPlayer(name: "Ferran Torres", role: "ST", number: 7),
                TeamPlayer(name: "Fermin Lopez", role: "AM", number: 16),
                TeamPlayer(name: "Dani Olmo", role: "AM", number: 20),
                TeamPlayer(name: "Marc Bernal", role: "DM", number: 22),
                TeamPlayer(name: "Marcus Rashford", role: "LW", number: 14),
                TeamPlayer(name: "Rooney Bardghji", role: "RW", number: 19),
                TeamPlayer(name: "Jules Kounde", role: "RB", number: 23),
                TeamPlayer(name: "Andreas Christensen", role: "CB", number: 15),
                TeamPlayer(name: "Eric Garcia", role: "CB", number: 24),
                TeamPlayer(name: "Gerard Martin", role: "LB", number: 18),
                TeamPlayer(name: "Xavi Espart", role: "RB", number: 42),
                TeamPlayer(name: "Wojciech Szczesny", role: "GK", number: 25)
            ]

            return (starters, bench)
        }

        let starters: [TeamPlayer] = [
            TeamPlayer(name: "حارس \(team)", role: "GK", number: 1),
            TeamPlayer(name: "ظهير أيمن", role: "RB", number: 2),
            TeamPlayer(name: "قلب دفاع 1", role: "CB", number: 4),
            TeamPlayer(name: "قلب دفاع 2", role: "CB", number: 5),
            TeamPlayer(name: "ظهير أيسر", role: "LB", number: 3),
            TeamPlayer(name: "محور", role: "DM", number: 6),
            TeamPlayer(name: "وسط 1", role: "CM", number: 8),
            TeamPlayer(name: "وسط 2", role: "CM", number: 10),
            TeamPlayer(name: "جناح أيمن", role: "RW", number: 7),
            TeamPlayer(name: "مهاجم", role: "ST", number: 9),
            TeamPlayer(name: "جناح أيسر", role: "LW", number: 11)
        ]

        let bench: [TeamPlayer] = [
            TeamPlayer(name: "حارس احتياط", role: "GK", number: 30),
            TeamPlayer(name: "دفاع احتياط", role: "CB", number: 14),
            TeamPlayer(name: "وسط احتياط 1", role: "CM", number: 16),
            TeamPlayer(name: "وسط احتياط 2", role: "CM", number: 17),
            TeamPlayer(name: "جناح احتياط", role: "RW", number: 18),
            TeamPlayer(name: "مهاجم احتياط", role: "ST", number: 19),
            TeamPlayer(name: "ورقة رابحة", role: "AM", number: 21)
        ]

        return (starters, bench)
    }

    private func teamShortCode() -> String {
        let words = (selectedTeam ?? "FC").split(separator: " ")
        if words.count >= 2 {
            return String(words.prefix(2).map { $0.prefix(1) }.joined())
        }
        return String((selectedTeam ?? "FC").prefix(2))
    }

    private func matchDays(in monthDate: Date) -> Set<Int> {
        var days: Set<Int> = []
        let cal = Calendar.current

        for week in 1...totalWeeks {
            let date = fixtureDate(for: week)
            if cal.component(.month, from: date) == cal.component(.month, from: monthDate) &&
                cal.component(.year, from: date) == cal.component(.year, from: monthDate) {
                days.insert(cal.component(.day, from: date))
            }
        }

        return days
    }

    private func fixturesInMonth(_ monthDate: Date) -> [String] {
        guard let team = selectedTeam else { return [] }
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.dateFormat = "d MMM"

        var rows: [String] = []

        for week in 1...totalWeeks {
            guard let fixture = fixtureFor(week: week, team: team) else { continue }
            let date = fixture.date
            if cal.component(.month, from: date) == cal.component(.month, from: monthDate) &&
                cal.component(.year, from: date) == cal.component(.year, from: monthDate) {
                rows.append("\(formatter.string(from: date)): \(localizedDisplayName(fixture.home, in: language)) × \(localizedDisplayName(fixture.away, in: language))")
            }
        }

        return rows
    }

    private func matchBadgesByDay(in monthDate: Date) -> [Int: [String]] {
        guard let team = selectedTeam else { return [:] }
        let cal = Calendar.current
        var rows: [Int: [String]] = [:]

        for week in 1...totalWeeks {
            guard let fixture = fixtureFor(week: week, team: team) else { continue }
            let date = fixture.date
            if cal.component(.month, from: date) == cal.component(.month, from: monthDate) &&
                cal.component(.year, from: date) == cal.component(.year, from: monthDate) {
                let day = cal.component(.day, from: date)
                rows[day, default: []].append(fixture.opponent)
            }
        }

        return rows
    }

    private func simulateOneDay() {
        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        calendarDisplayDate = currentDate
        simulationDateToken += 1
    }

    private func fixtureFor(week: Int, team: String) -> MatchFixture? {
        guard
            let league = selectedLeague,
            let index = league.teams.firstIndex(of: team),
            league.teams.count > 2
        else { return nil }

        let shift = ((week - 1) % (league.teams.count - 1)) + 1
        var opponent = league.teams[(index + shift) % league.teams.count]
        if opponent == team {
            opponent = league.teams[(index + shift + 1) % league.teams.count]
        }

        let date = fixtureDate(for: week)
        if week % 2 == 1 {
            return MatchFixture(home: team, away: opponent, opponent: opponent, date: date)
        }
        return MatchFixture(home: opponent, away: team, opponent: opponent, date: date)
    }

    private func teamTitlesCount() -> Int {
        leagueTitlesWon
    }
}

private struct TeamCalendarView: View {
    let language: AppLanguage
    let todayDate: Date
    @Binding var displayedMonth: Date
    let matchDays: Set<Int>
    let matchBadgesByDay: [Int: [String]]
    let fixtures: [String]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    private var weekDayNames: [String] {
        switch language {
        case .arabic:
            return ["أحد", "إثن", "ثلا", "أرب", "خم", "جمع", "سبت"]
        case .english:
            return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        case .hindi:
            return ["रवि", "सोम", "मंगल", "बुध", "गुरु", "शुक्र", "शनि"]
        case .chinese:
            return ["日", "一", "二", "三", "四", "五", "六"]
        case .kurdish:
            return ["یەکش", "دووش", "سێش", "چوار", "پێنج", "هەینی", "شەم"]
        }
    }

    var body: some View {
        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: displayedMonth) ?? (1..<31)
        let monthName = monthTitle(for: displayedMonth)
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth)) ?? displayedMonth
        let firstWeekdayOffset = max(0, cal.component(.weekday, from: monthStart) - 1)

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button {
                    displayedMonth = cal.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(FootballTheme.cardBase.opacity(0.72)))
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    displayedMonth = cal.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(FootballTheme.cardBase.opacity(0.72)))
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekDayNames, id: \.self) { dayName in
                    Text(dayName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                    Color.clear
                        .frame(height: 52)
                }

                ForEach(Array(range), id: \.self) { day in
                    let labels = matchBadgesByDay[day] ?? []
                    let isToday = isSameDay(day: day, calendar: cal)

                    VStack(alignment: .trailing, spacing: 3) {
                        Text("\(day)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(matchDays.contains(day) ? .black : .white)

                        if let first = labels.first {
                            HStack(spacing: 4) {
                                TeamLogoView(teamName: first, size: 12)
                                Text(compactLabel(first))
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(.black)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.white.opacity(0.88)))
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .topTrailing)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(matchDays.contains(day) ? FootballTheme.pitchGreen.opacity(0.95) : FootballTheme.cardBase.opacity(0.70))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isToday ? FootballTheme.pointsYellow : Color.clear, lineWidth: 1.5)
                            )
                    )
                }
            }

            if fixtures.isEmpty {
                Text(language.text(ar: "لا توجد مباريات متبقية هذا الشهر", en: "No matches remain this month", hi: "इस महीने कोई मैच बाकी नहीं है", zh: "本月没有剩余比赛", ku: "ئەم مانگە هیچ یارییەکی ماوە نییە"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.84))
            } else {
                ForEach(fixtures, id: \.self) { row in
                    Text("• \(row)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
    }

    private func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.localeIdentifier)
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func isSameDay(day: Int, calendar: Calendar) -> Bool {
        calendar.component(.day, from: todayDate) == day &&
            calendar.component(.month, from: todayDate) == calendar.component(.month, from: displayedMonth) &&
            calendar.component(.year, from: todayDate) == calendar.component(.year, from: displayedMonth)
    }

    private func compactLabel(_ name: String) -> String {
        let firstToken = localizedDisplayName(name, in: language).split(separator: " ").first.map(String.init) ?? localizedDisplayName(name, in: language)
        return String(firstToken.prefix(10))
    }
}

private struct HubHeader: View {
    let roundText: String
    let selectedTeam: String?
    let standingsLabel: String
    let mainMenuLabel: String
    let saveLabel: String
    let onMainMenu: () -> Void
    let onSave: () -> Void
    let onStandings: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                logoBadge

                Spacer(minLength: 8)

                HStack(alignment: .top, spacing: 8) {
                    Button(action: onSave) {
                        Label(saveLabel, systemImage: "square.and.arrow.down.fill")
                            .font(.system(size: 13, weight: .heavy))
                            .lineLimit(1)
                            .minimumScaleFactor(0.84)
                            .foregroundStyle(.black.opacity(0.92))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(FootballTheme.pitchGreen)
                            )
                    }
                    .buttonStyle(InteractivePressButtonStyle())

                    VStack(spacing: 7) {
                        Button(action: onMainMenu) {
                            Label(mainMenuLabel, systemImage: "house.fill")
                                .font(.system(size: 13, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                                .foregroundStyle(FootballTheme.textPrimary.opacity(0.92))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(minWidth: 128)
                                .background(
                                    Capsule()
                                        .fill(FootballTheme.backgroundPrimary.opacity(0.62))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(FootballTheme.textSecondary.opacity(0.28), lineWidth: 1)
                                )
                        }
                        .buttonStyle(InteractivePressButtonStyle())

                        Button(action: onStandings) {
                            HStack(spacing: 4) {
                                Image(systemName: "list.number")
                                    .font(.system(size: 12, weight: .black))

                                Text(standingsLabel)
                                    .font(.system(size: 12, weight: .black))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                            }
                            .foregroundStyle(.white.opacity(0.96))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(minWidth: 128)
                            .background(
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [FootballTheme.cardBase.opacity(0.9), FootballTheme.backgroundSecondary.opacity(0.72)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .stroke(FootballTheme.accentCyan.opacity(0.34), lineWidth: 1)
                            )
                        }
                        .buttonStyle(InteractivePressButtonStyle())
                    }
                }
            }

            Text(roundText)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.bottom, 2)
    }

    private var logoBadge: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.22), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 72, height: 72)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.28), lineWidth: 1.2)
                )

            if let selectedTeam {
                TeamLogoView(teamName: selectedTeam, size: 50)
            } else {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
            }
        }
    }
}

private extension ContentView {
    enum MainMenuTextKey {
        case screenTitle
        case screenSubtitle
        case profileGuestName
        case profileGuestRole
        case profileClubLabel
        case resourceBudget
        case resourceFans
        case resourceStrength
        case quickMatchTitle
        case quickMatchSubtitle
        case careerModeTitle
        case careerModeSubtitle
        case teamManagementTitle
        case teamManagementSubtitle
        case trainingTitle
        case trainingSubtitle
        case competitionsTitle
        case competitionsSubtitle
        case settingsTitle
        case settingsSubtitle
        case featuredTag
        case placeholderTeamManagementRequired
        case placeholderTrainingRequired
        case quickMatchFallbackNote
    }

    func mainMenuText(_ key: MainMenuTextKey) -> String {
        switch key {
        case .screenTitle:
            return t(ar: "القائمة الرئيسية", en: "Main Menu", hi: "Main Menu", zh: "Main Menu", ku: "لیستی سەرەکی")
        case .screenSubtitle:
            return t(ar: "وضع المهنة", en: "Career Hub", hi: "Career Hub", zh: "Career Hub", ku: "ناوەندی پیشە")
        case .profileGuestName:
            return t(ar: "مدرب ضيف", en: "Guest Coach", hi: "Guest Coach", zh: "Guest Coach", ku: "ڕاهێنەری میوان")
        case .profileGuestRole:
            return t(ar: "ابدأ مهنة جديدة", en: "Start a new career", hi: "Start a new career", zh: "Start a new career", ku: "پیشەیەکی نوێ دەستپێبکە")
        case .profileClubLabel:
            return t(ar: "النادي", en: "Club", hi: "Club", zh: "Club", ku: "یانە")
        case .resourceBudget:
            return t(ar: "الميزانية", en: "Budget", hi: "Budget", zh: "Budget", ku: "بودجە")
        case .resourceFans:
            return t(ar: "الجماهير", en: "Fans", hi: "Fans", zh: "Fans", ku: "هاندەران")
        case .resourceStrength:
            return t(ar: "القوة", en: "Strength", hi: "Strength", zh: "Strength", ku: "هێز")
        case .quickMatchTitle:
            return t(ar: "مباراة سريعة", en: "Quick Match", hi: "Quick Match", zh: "Quick Match", ku: "یاریی خێرا")
        case .quickMatchSubtitle:
            return t(ar: "ادخل مباشرة إلى أجواء المباراة.", en: "Jump straight into matchday action.", hi: "Jump straight into matchday action.", zh: "Jump straight into matchday action.", ku: "ڕاستەوخۆ بچۆ ناو کەشی یاری.")
        case .careerModeTitle:
            return t(ar: "وضع المهنة", en: "Career Mode", hi: "Career Mode", zh: "Career Mode", ku: "مۆدی پیشە")
        case .careerModeSubtitle:
            return t(ar: "ابدأ موسماً جديداً وابنِ مشروعك.", en: "Start a new season and build your project.", hi: "Start a new season and build your project.", zh: "Start a new season and build your project.", ku: "وەرزێکی نوێ دەستپێبکە و پڕۆژەکەت دروست بکە.")
        case .teamManagementTitle:
            return t(ar: "إدارة الفريق", en: "Team Management", hi: "Team Management", zh: "Team Management", ku: "بەڕێوەبردنی تیم")
        case .teamManagementSubtitle:
            return t(ar: "التشكيلة، الانتقالات، وتنظيم القائمة.", en: "Lineup, transfers, and squad control.", hi: "Lineup, transfers, and squad control.", zh: "Lineup, transfers, and squad control.", ku: "ڕیزبەندی، گواستنەوە و کۆنترۆڵی تیم.")
        case .trainingTitle:
            return t(ar: "التدريب والخطط", en: "Training & Tactics", hi: "Training & Tactics", zh: "Training & Tactics", ku: "ڕاهێنان و پلان")
        case .trainingSubtitle:
            return t(ar: "عدّل الخطة وارفع الجاهزية.", en: "Tune tactics and improve readiness.", hi: "Tune tactics and improve readiness.", zh: "Tune tactics and improve readiness.", ku: "پلان چاکبکە و ئامادەکاری بەرزبکە.")
        case .competitionsTitle:
            return t(ar: "البطولات والدوريات", en: "Competitions & Leagues", hi: "Competitions & Leagues", zh: "Competitions & Leagues", ku: "پاڵەوانی و لیگەکان")
        case .competitionsSubtitle:
            return t(ar: "استعرض البطولات المتاحة ومساراتها.", en: "Browse competitions and league paths.", hi: "Browse competitions and league paths.", zh: "Browse competitions and league paths.", ku: "پاڵەوانییە بەردەستەکان و ڕێگاکانی لیگ ببینە.")
        case .settingsTitle:
            return t(ar: "الإعدادات", en: "Settings", hi: "Settings", zh: "Settings", ku: "ڕێکخستن")
        case .settingsSubtitle:
            return t(ar: "اللغة، الدليل، وتخصيص التجربة.", en: "Language, guide, and experience options.", hi: "Language, guide, and experience options.", zh: "Language, guide, and experience options.", ku: "زمان، ڕێنمایی و هەڵبژاردەکانی ئەزموون.")
        case .featuredTag:
            return t(ar: "المحور الرئيسي", en: "Featured", hi: "Featured", zh: "Featured", ku: "سەرەکی")
        case .placeholderTeamManagementRequired:
            return t(ar: "لا توجد مهنة محفوظة لإدارة الفريق حالياً.", en: "No saved career is available for team management right now.", hi: "No saved career is available for team management right now.", zh: "No saved career is available for team management right now.", ku: "ئێستا هیچ پیشەیەکی هەڵگیراو بۆ بەڕێوەبردنی تیم نییە.")
        case .placeholderTrainingRequired:
            return t(ar: "التدريب والخطط يحتاجان مهنة محفوظة أولاً.", en: "Training and tactics need an active saved career first.", hi: "Training and tactics need an active saved career first.", zh: "Training and tactics need an active saved career first.", ku: "ڕاهێنان و پلان پێویستیان بە پیشەیەکی هەڵگیراوی چالاک هەیە.")
        case .quickMatchFallbackNote:
            return t(ar: "تم فتح مركز المحاكاة. حرّك الأيام حتى يوم المباراة.", en: "Simulation hub opened. Advance days until match day.", hi: "Simulation hub opened. Advance days until match day.", zh: "Simulation hub opened. Advance days until match day.", ku: "ناوەندی شبیه‌کردن کرایەوە. ڕۆژەکان بڕۆ تا ڕۆژی یاری.")
        }
    }
}

private struct LeagueStandingsSheetView: View {
    let language: AppLanguage
    let leagueDisplayName: String
    let selectedTeam: String?
    @Binding var seasonTable: [String: TeamStanding]
    let currentWeek: Int
    let totalWeeks: Int

    @Environment(\.dismiss) private var dismiss

    private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
    }

    private var sortedRows: [(name: String, stats: TeamStanding)] {
        seasonTable
            .map { (name: $0.key, stats: $0.value) }
            .sorted {
                if $0.stats.points != $1.stats.points { return $0.stats.points > $1.stats.points }
                if $0.stats.goalDifference != $1.stats.goalDifference { return $0.stats.goalDifference > $1.stats.goalDifference }
                return $0.stats.goalsFor > $1.stats.goalsFor
            }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [FootballTheme.backgroundPrimary, FootballTheme.cardBase, FootballTheme.backgroundSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 10) {
                header
                leagueMeta
                tableContent
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 8)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .black))
                    Text(t(ar: "إغلاق", en: "Close", hi: "बंद करें", zh: "关闭", ku: "داخستن"))
                        .font(.system(size: 12, weight: .black))
                }
                .foregroundStyle(.white.opacity(0.92))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
            }
            .buttonStyle(InteractivePressButtonStyle())

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "list.number")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(FootballTheme.accentCyan)

                Text(t(ar: "ترتيب الدوري", en: "League Table", hi: "लीग तालिका", zh: "联赛排名", ku: "ڕیزبەندی لیگ"))
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }

    private var leagueMeta: some View {
        HStack(spacing: 10) {
            metaPill(
                icon: "trophy.fill",
                text: leagueDisplayName.isEmpty
                    ? t(ar: "الدوري", en: "League", hi: "लीग", zh: "联赛", ku: "لیگ")
                    : leagueDisplayName
            )

            metaPill(
                icon: "flag.checkered",
                text: "\(t(ar: "الجولة", en: "Round", hi: "राउंड", zh: "轮次", ku: "دەور")) \(min(currentWeek, totalWeeks))/\(totalWeeks)"
            )
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func metaPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.system(size: 12, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.10))
        )
    }

    private var tableContent: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(t(ar: "يتحدث تلقائيًا بعد كل مباراة", en: "Auto updates after every match", hi: "हर मैच के बाद स्वतः अपडेट", zh: "每场比赛后自动更新", ku: "دوای هەر یارییەک خۆکار نوێ دەبێتەوە"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.76))
                .frame(maxWidth: .infinity, alignment: .trailing)

            if sortedRows.isEmpty {
                Text(t(ar: "لا توجد بيانات ترتيب حالياً", en: "No standings data right now", hi: "अभी कोई तालिका डेटा नहीं", zh: "当前暂无积分数据", ku: "ئێستا هیچ داتای ڕیزبەندییەک نییە"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.82))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 30)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(spacing: 7) {
                            standingsHeaderRow

                            ForEach(Array(sortedRows.enumerated()), id: \.element.name) { idx, row in
                                standingsRow(rank: idx + 1, name: row.name, stats: row.stats)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(FootballTheme.cardBase.opacity(0.54))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private var standingsHeaderRow: some View {
        HStack(spacing: 6) {
            headerCell(t(ar: "م", en: "#", hi: "#", zh: "名", ku: "پ"), width: 34)
            headerCell(t(ar: "الفريق", en: "Team", hi: "टीम", zh: "球队", ku: "تیم"), width: 170)
            headerCell(t(ar: "ل", en: "P", hi: "P", zh: "赛", ku: "ی"), width: 34)
            headerCell(t(ar: "ف", en: "W", hi: "W", zh: "胜", ku: "ب"), width: 34)
            headerCell(t(ar: "ت", en: "D", hi: "D", zh: "平", ku: "ی"), width: 34)
            headerCell(t(ar: "خ", en: "L", hi: "L", zh: "负", ku: "د"), width: 34)
            headerCell(t(ar: "له", en: "GF", hi: "GF", zh: "进", ku: "بۆ"), width: 40)
            headerCell(t(ar: "عليه", en: "GA", hi: "GA", zh: "失", ku: "لەسەر"), width: 44)
            headerCell("±", width: 34)
            headerCell(t(ar: "ن", en: "Pts", hi: "Pts", zh: "分", ku: "خال"), width: 40)
        }
        .frame(minWidth: 500, alignment: .leading)
    }

    private func standingsRow(rank: Int, name: String, stats: TeamStanding) -> some View {
        let isMyTeam = name == selectedTeam
        return HStack(spacing: 6) {
            valueCell("\(rank)", width: 34, bold: true, color: FootballTheme.pointsYellow)

            HStack(spacing: 6) {
                TeamLogoView(teamName: name, size: 20)

                Text(localizedDisplayName(name, in: language))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)

                Spacer(minLength: 0)
            }
            .frame(width: 170, alignment: .leading)

            valueCell("\(stats.played)", width: 34)
            valueCell("\(stats.wins)", width: 34)
            valueCell("\(stats.draws)", width: 34)
            valueCell("\(stats.losses)", width: 34)
            valueCell("\(stats.goalsFor)", width: 40)
            valueCell("\(stats.goalsAgainst)", width: 44)
            valueCell("\(stats.goalDifference)", width: 34)
            valueCell("\(stats.points)", width: 40, bold: true, color: .white)
        }
        .frame(minWidth: 500, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    isMyTeam
                        ? LinearGradient(
                            colors: [FootballTheme.pitchGreen.opacity(0.34), FootballTheme.accentGreen.opacity(0.22)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [Color.white.opacity(0.08), Color.white.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    isMyTeam ? FootballTheme.pitchGreen.opacity(0.70) : Color.white.opacity(0.08),
                    lineWidth: isMyTeam ? 1.2 : 0.8
                )
        )
        .shadow(color: isMyTeam ? FootballTheme.pitchGreen.opacity(0.26) : .clear, radius: 6, x: 0, y: 3)
    }

    private func headerCell(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .heavy))
            .foregroundStyle(.white.opacity(0.76))
            .frame(width: width, alignment: .center)
    }

    private func valueCell(_ text: String, width: CGFloat, bold: Bool = false, color: Color = .white.opacity(0.9)) -> some View {
        Text(text)
            .font(.system(size: 12, weight: bold ? .black : .semibold))
            .foregroundStyle(color)
            .frame(width: width, alignment: .center)
    }
}

private struct SimulationDateTickerCard: View {
    let date: Date
    let language: AppLanguage
    let isSimulating: Bool
    let isMatchDay: Bool
    let dateToken: Int

    private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
    }

    private var locale: Locale {
        Locale(identifier: language.localeIdentifier)
    }

    private var dayNumberText: String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var weekdayText: String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label(t(ar: "التاريخ", en: "Date", hi: "तारीख", zh: "日期", ku: "بەروار"), systemImage: "calendar.badge.clock")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.84))

                if isSimulating {
                    Text(t(ar: "الزمن يتحرك", en: "Time moving", hi: "समय चल रहा है", zh: "时间推进中", ku: "کات دەجوڵێت"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.black.opacity(0.88))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(FootballTheme.pitchGreen.opacity(0.92)))
                }

                Spacer(minLength: 0)

                if isMatchDay {
                    Text(t(ar: "يوم مباراة", en: "Match Day", hi: "मैच डे", zh: "比赛日", ku: "ڕۆژی یاری"))
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(FootballTheme.pitchGreen)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(dayNumberText)
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .id("day-\(dayNumberText)-\(dateToken)")

                VStack(alignment: .leading, spacing: 2) {
                    Text(weekdayText)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white.opacity(0.90))
                    Text(monthYearText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.74))
                }

                Spacer(minLength: 0)
            }
            .rotation3DEffect(.degrees(dateToken.isMultiple(of: 2) ? 0 : -8), axis: (x: 1, y: 0, z: 0))
            .animation(.spring(response: 0.42, dampingFraction: 0.78), value: dateToken)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(FootballTheme.cardBase.opacity(0.68))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(isSimulating ? FootballTheme.accentCyan.opacity(0.36) : Color.white.opacity(0.12), lineWidth: isSimulating ? 1.4 : 1)
                )
        )
        .shadow(color: isSimulating ? FootballTheme.accentCyan.opacity(0.24) : .black.opacity(0.18), radius: 10, x: 0, y: 5)
    }
}

private struct HubDateMatchCard: View {
    let date: Date
    let language: AppLanguage
    let isSimulating: Bool
    let isMatchDay: Bool
    let dateToken: Int
    let dateLabel: String
    let title: String
    let matchDayLabel: String
    let opponent: String?
    let matchDateText: String?
    let timeText: String?
    let previousMatchText: String
    let noUpcomingMatchText: String
    let previousMatchLabel: String
    let isHighlighted: Bool

    private var locale: Locale {
        Locale(identifier: language.localeIdentifier)
    }

    private var dayText: String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var weekdayText: String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private var monthText: String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }

    private var animationKey: String {
        "\(opponent ?? "none")-\(matchDateText ?? "na")-\(timeText ?? "na")-\(dateToken)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label(dateLabel, systemImage: "calendar")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.80))

                if isSimulating {
                    Text("جاري المحاكاة")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.black.opacity(0.88))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(FootballTheme.pitchGreen.opacity(0.92)))
                }

                Spacer(minLength: 0)

                if isMatchDay {
                    Text(matchDayLabel)
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(FootballTheme.pitchGreen)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(dayText)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                VStack(alignment: .leading, spacing: 1) {
                    Text(weekdayText)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.88))
                    Text(monthText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer(minLength: 0)
            }
            .rotation3DEffect(.degrees(dateToken.isMultiple(of: 2) ? 0 : -6), axis: (x: 1, y: 0, z: 0))
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: dateToken)

            Divider()
                .overlay(Color.white.opacity(0.18))

            HStack(spacing: 8) {
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(FootballTheme.pitchGreen.opacity(0.94))
                Text(title)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.84))
                Spacer(minLength: 0)
            }

            if let opponent, let matchDateText {
                Text(opponent)
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)
                    .contentTransition(.opacity)

                HStack(spacing: 8) {
                    matchPill(icon: "calendar", text: matchDateText)
                    if let timeText {
                        matchPill(icon: "clock.fill", text: timeText)
                    }
                }
            } else {
                Text(noUpcomingMatchText)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.84))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .contentTransition(.opacity)
            }

            Text("\(previousMatchLabel): \(previousMatchText)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.68))
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .contentTransition(.opacity)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(FootballTheme.cardBase.opacity(isHighlighted ? 0.82 : 0.73))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(isHighlighted ? FootballTheme.pitchGreen.opacity(0.62) : Color.white.opacity(0.14), lineWidth: isHighlighted ? 1.6 : 1)
                )
        )
        .shadow(color: isHighlighted ? FootballTheme.pitchGreen.opacity(0.34) : .black.opacity(0.2), radius: isHighlighted ? 13 : 8, x: 0, y: 4)
        .animation(.easeInOut(duration: 0.24), value: animationKey)
        .animation(.easeInOut(duration: 0.26), value: isHighlighted)
    }

    private func matchPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
                .lineLimit(1)
        }
        .font(.system(size: 11, weight: .bold))
        .foregroundStyle(.white.opacity(0.86))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
        )
    }
}

private struct NextMatchCard: View {
    let title: String
    let opponent: String?
    let dateText: String?
    let timeText: String?
    let previousMatchText: String
    let noUpcomingMatchText: String
    let previousMatchLabel: String
    let isHighlighted: Bool
    private var upcomingAnimationKey: String {
        "\(opponent ?? "none")-\(dateText ?? "na")-\(timeText ?? "na")"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(FootballTheme.pitchGreen)
                    .frame(width: 5, height: 26)
                Label(title, systemImage: "sportscourt.fill")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.86))
                Spacer(minLength: 0)
            }

            if let opponent, let dateText {
                Text(opponent)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .contentTransition(.opacity)

                HStack(spacing: 10) {
                    infoPill(icon: "calendar", text: dateText)
                    if let timeText {
                        infoPill(icon: "clock.fill", text: timeText)
                    }
                }
            } else {
                Text(noUpcomingMatchText)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white.opacity(0.88))
                    .contentTransition(.opacity)
            }

            Divider()
                .overlay(Color.white.opacity(0.2))

            Text("\(previousMatchLabel): \(previousMatchText)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.76))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .contentTransition(.opacity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(FootballTheme.cardBase.opacity(isHighlighted ? 0.82 : 0.74))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(isHighlighted ? FootballTheme.pitchGreen.opacity(0.70) : FootballTheme.textSecondary.opacity(0.22), lineWidth: isHighlighted ? 1.8 : 1)
                )
        )
        .shadow(color: isHighlighted ? FootballTheme.pitchGreen.opacity(0.40) : .black.opacity(0.22), radius: isHighlighted ? 16 : 10, x: 0, y: 6)
        .scaleEffect(isHighlighted ? 1.012 : 1.0)
        .animation(.easeInOut(duration: 0.24), value: upcomingAnimationKey)
        .animation(.easeInOut(duration: 0.24), value: previousMatchText)
        .animation(.easeInOut(duration: 0.30), value: isHighlighted)
    }

    private func infoPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
                .lineLimit(1)
        }
        .font(.system(size: 13, weight: .bold))
        .foregroundStyle(.white.opacity(0.88))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
        )
    }
}

private struct SimulateDaysButton: View {
    let title: String
    let disabled: Bool
    let isRunning: Bool
    let isMatchDay: Bool
    let onTap: () -> Void
    @State private var pulse = false
    @State private var glow = false
    @State private var shimmer = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                if isRunning {
                    RunningDotsView()
                    Text("جاري المحاكاة...")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.86)
                } else {
                    HStack(spacing: 1) {
                        Image(systemName: "forward.fill")
                        Image(systemName: "forward.fill")
                    }
                    .font(.system(size: 15, weight: .black))

                    Text(title)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)

                if isRunning {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(.black.opacity(0.8))
                        .opacity(pulse ? 1 : 0.36)
                }
            }
            .padding(.horizontal, 16)
            .foregroundStyle(.black.opacity((disabled && !isRunning) ? 0.58 : 0.96))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(backgroundFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                isRunning
                                    ? Color.white.opacity(0.45)
                                    : (disabled && isMatchDay ? Color.white.opacity(0.18) : Color.clear),
                                lineWidth: 1.2
                            )
                    )
            )
            .overlay {
                if isRunning {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(FootballTheme.pitchGreen.opacity(0.92), lineWidth: 2.4)
                        .blur(radius: glow ? 10 : 4)
                        .scaleEffect(glow ? 1.045 : 0.988)
                        .opacity(glow ? 1 : 0.40)
                        .animation(.easeInOut(duration: 0.42), value: glow)
                }
            }
        }
        .buttonStyle(InteractivePressButtonStyle())
        .disabled(disabled)
        .shadow(color: shadowColor, radius: isRunning ? 18 : 9, x: 0, y: 6)
        .onAppear {
            if isRunning {
                pulseAnimation()
                glowAnimation()
                shimmerAnimation()
            }
        }
        .onChange(of: isRunning) { _, running in
            if running {
                pulseAnimation()
                glowAnimation()
                shimmerAnimation()
            } else {
                pulse = false
                glow = false
                shimmer = false
            }
        }
    }

    private var backgroundFill: LinearGradient {
        if disabled && !isRunning {
            if isMatchDay {
                return LinearGradient(
                    colors: [Color(hex: 0x8C83D2), Color(hex: 0x796EB6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            return LinearGradient(
                colors: [FootballTheme.muted.opacity(0.68), FootballTheme.muted.opacity(0.68)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        if isRunning {
            return LinearGradient(
                colors: [
                    FootballTheme.pitchGreen.opacity(0.98),
                    FootballTheme.accentGreen.opacity(0.97),
                    FootballTheme.accentCyan.opacity(0.85)
                ],
                startPoint: shimmer ? .topLeading : .bottomTrailing,
                endPoint: shimmer ? .bottomTrailing : .topLeading
            )
        }
        return LinearGradient(
            colors: [FootballTheme.pitchGreen, FootballTheme.pitchGreen],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var shadowColor: Color {
        if disabled && !isRunning && !isMatchDay {
            return .clear
        }
        if disabled && isMatchDay {
            return Color(hex: 0xA89BFF).opacity(0.34)
        }
        return FootballTheme.pitchGreen.opacity(isRunning ? 0.70 : 0.34)
    }

    private func pulseAnimation() {
        withAnimation(.easeInOut(duration: 0.48).repeatForever(autoreverses: true)) {
            pulse.toggle()
        }
    }

    private func glowAnimation() {
        withAnimation(.easeInOut(duration: 0.56).repeatForever(autoreverses: true)) {
            glow.toggle()
        }
    }

    private func shimmerAnimation() {
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            shimmer.toggle()
        }
    }
}

private struct PlayMatchButton: View {
    let title: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "soccerball")
                    .font(.system(size: 16, weight: .black))
                Text(title)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)
            }
            .foregroundStyle(.black.opacity(0.92))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xFFD76A), Color(hex: 0xF2B20C)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.45), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(InteractivePressButtonStyle())
        .shadow(color: Color(hex: 0xFFD76A).opacity(0.40), radius: 10, x: 0, y: 5)
    }
}

private struct RunningDotsView: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { idx in
                Circle()
                    .fill(Color.black.opacity(0.82))
                    .frame(width: 6, height: 6)
                    .scaleEffect(animate ? 1.0 : 0.45)
                    .opacity(animate ? 1 : 0.35)
                    .animation(.easeInOut(duration: 0.36).repeatForever(autoreverses: true).delay(Double(idx) * 0.10), value: animate)
            }
        }
        .onAppear { animate = true }
    }
}

private struct InteractivePressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.90 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

private struct PremiumTilePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .brightness(configuration.isPressed ? 0.04 : 0)
            .saturation(configuration.isPressed ? 1.05 : 1)
            .animation(.spring(response: 0.30, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

private struct MainMenuTilePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .environment(\.mainMenuTilePressed, configuration.isPressed)
            .scaleEffect(configuration.isPressed ? 0.968 : 1)
            .brightness(configuration.isPressed ? 0.022 : 0)
            .saturation(configuration.isPressed ? 1.05 : 1)
            .overlay {
                Color.white
                    .opacity(configuration.isPressed ? 0.06 : 0)
            }
            .animation(.spring(response: 0.24, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

private struct MainMenuTilePressedKey: EnvironmentKey {
    static let defaultValue = false
}

private extension EnvironmentValues {
    var mainMenuTilePressed: Bool {
        get { self[MainMenuTilePressedKey.self] }
        set { self[MainMenuTilePressedKey.self] = newValue }
    }
}

private struct MainMenuTopBarView: View {
    let title: String
    let subtitle: String
    let resources: [MainMenuResourceItem]
    let profileName: String
    let profileSubtitle: String
    let onOpenPacks: () -> Void
    let onOpenSettings: () -> Void
    let language: AppLanguage

    @Environment(\.layoutDirection) private var layoutDirection

    private var isRTL: Bool {
        layoutDirection == .rightToLeft
    }

    private var topBarShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
    }

    var body: some View {
        HStack(spacing: 13) {
            if isRTL {
                profileSection
                if !resources.isEmpty { resourcesSection }
                titleSection
            } else {
                titleSection
                if !resources.isEmpty { resourcesSection }
                profileSection
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            topBarShape
                .fill(.ultraThinMaterial)
                .overlay(
                    topBarShape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: 0x0F1936).opacity(0.90),
                                    Color(hex: 0x1B2E61).opacity(0.78)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    topBarShape
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.20), Color.white.opacity(0.02), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                )
        )
        .overlay(
            topBarShape
                .stroke(Color.white.opacity(0.20), lineWidth: 1)
                .overlay(
                    topBarShape
                        .inset(by: 1.4)
                        .stroke(Color.black.opacity(0.30), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.34), radius: 18, x: 0, y: 10)
        .shadow(color: FootballTheme.accentCyan.opacity(0.10), radius: 16, x: 0, y: 0)
    }

    private var titleSection: some View {
        VStack(alignment: isRTL ? .trailing : .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .shadow(color: .black.opacity(0.30), radius: 3, x: 0, y: 1)

            Text(subtitle)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.74))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: isRTL ? .trailing : .leading)
    }

    private var resourcesSection: some View {
        HStack(spacing: 8) {
            ForEach(resources) { item in
                HStack(spacing: 6) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(hex: 0xFFE25C))
                    Text(item.value)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(item.label)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.65))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.10), Color.white.opacity(0.02)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                        )
                )
                .shadow(color: .black.opacity(0.16), radius: 4, x: 0, y: 2)
            }
        }
    }

    private var profileSection: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                actionButton(
                    symbol: "shippingbox.fill",
                    tint: Color(hex: 0xFFD76A),
                    accessibilityLabel: language.text(
                        ar: "مركز الحزم",
                        en: "Packs Center",
                        hi: "Packs Center",
                        zh: "Packs Center",
                        ku: "ناوەندی پەکیجەکان"
                    ),
                    action: onOpenPacks
                )
                actionButton(
                    symbol: "gearshape.fill",
                    tint: Color(hex: 0x8CA6DB),
                    accessibilityLabel: language.text(
                        ar: "الإعدادات",
                        en: "Settings",
                        hi: "Settings",
                        zh: "Settings",
                        ku: "ڕێکخستن"
                    ),
                    action: onOpenSettings
                )
            }

            VStack(alignment: isRTL ? .leading : .trailing, spacing: 1) {
                Text(profileName)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(profileSubtitle)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.70))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x32469A), Color(hex: 0x5A78DE)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Circle()
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)

                Image(systemName: "person.fill")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white.opacity(0.95))
            }
            .frame(width: 36, height: 36)
            .shadow(color: .black.opacity(0.24), radius: 6, x: 0, y: 3)
        }
    }

    private func actionButton(
        symbol: String,
        tint: Color,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white.opacity(0.96))
                .frame(width: 32, height: 32)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(.ultraThinMaterial)

                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [tint.opacity(0.46), tint.opacity(0.20)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(Color.white.opacity(0.24), lineWidth: 1)
                    )
                )
        }
        .buttonStyle(InteractivePressButtonStyle())
        .shadow(color: tint.opacity(0.20), radius: 8, x: 0, y: 3)
        .hoverEffect(.lift)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct MainMenuCardView: View {
    let title: String
    let subtitle: String
    let symbol: String
    let backgroundAsset: String
    let colors: [Color]
    let glow: Color
    let tag: String?
    let size: MainMenuCardSize
    let language: AppLanguage

    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.mainMenuTilePressed) private var isTilePressed
    @State private var hasAppeared = false

    private var isRTL: Bool {
        layoutDirection == .rightToLeft
    }

    private var isFeatured: Bool {
        size == .featured
    }

    private var isSmall: Bool {
        size == .small
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .featured: return 28
        case .medium: return 24
        case .small: return 20
        }
    }

    private var titleFontSize: CGFloat {
        switch size {
        case .featured: return 48
        case .medium: return 34
        case .small: return 21
        }
    }

    private var subtitleFontSize: CGFloat {
        switch size {
        case .featured: return 16
        case .medium: return 12
        case .small: return 10.5
        }
    }

    private var textStackSpacing: CGFloat {
        switch size {
        case .featured: return 9
        case .medium: return 6
        case .small: return 4
        }
    }

    private var symbolFontSize: CGFloat {
        switch size {
        case .featured: return 146
        case .medium: return 104
        case .small: return 72
        }
    }

    private var contentPadding: CGFloat {
        switch size {
        case .featured: return 20
        case .medium: return 14
        case .small: return 10
        }
    }

    private var chevronControlSize: CGFloat {
        switch size {
        case .featured: return 36
        case .medium: return 32
        case .small: return 28
        }
    }

    private var appearanceDelay: Double {
        switch size {
        case .featured: return 0.03
        case .medium: return 0.06
        case .small: return 0.09
        }
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    private var accentStart: UnitPoint {
        isRTL ? .trailing : .leading
    }

    private var accentEnd: UnitPoint {
        isRTL ? .leading : .trailing
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                cardShape.fill(Color.black.opacity(0.92))
                artworkLayer(in: size)
                cinematicColorLayer
                featuredSpotlightLayer(in: size)
                textureOverlayLayer(in: size)
                readabilityOverlayLayer(in: size)
                textContentLayer
            }
            .clipShape(cardShape)
            .overlay(borderLayer)
            .overlay(innerShadowLayer)
            .overlay(featuredHaloLayer)
            .overlay(topAccentLayer, alignment: .topLeading)
            .overlay(bottomSeparatorLayer, alignment: .bottom)
            .overlay(sideAccentLayer, alignment: isRTL ? .trailing : .leading)
            .scaleEffect(hasAppeared ? 1 : 0.985)
            .opacity(hasAppeared ? 1 : 0.02)
            .shadow(color: glow.opacity(isFeatured ? 0.30 : 0.16), radius: isFeatured ? 20 : 14, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.44), radius: 14, x: 0, y: 8)
            .onAppear {
                guard !hasAppeared else { return }
                withAnimation(.easeOut(duration: 0.32).delay(appearanceDelay)) {
                    hasAppeared = true
                }
            }
        }
    }

    private func artworkLayer(in size: CGSize) -> some View {
        backgroundArtwork(in: size)
            .clipShape(cardShape)
            .overlay(
                LinearGradient(
                    colors: [Color.black.opacity(0.12), Color.black.opacity(isFeatured ? 0.34 : 0.28)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                if isFeatured {
                    RadialGradient(
                        colors: [Color.white.opacity(0.12), .clear],
                        center: UnitPoint(x: isRTL ? 0.72 : 0.28, y: 0.20),
                        startRadius: 10,
                        endRadius: max(size.width, size.height) * 0.84
                    )
                    .blendMode(.screen)
                }
            }
    }

    private var cinematicColorLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black.opacity(isFeatured ? 0.05 : 0.08), Color.black.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [glow.opacity(isFeatured ? 0.28 : 0.16), .clear],
                startPoint: accentStart,
                endPoint: .center
            )
        }
    }

    @ViewBuilder
    private func featuredSpotlightLayer(in size: CGSize) -> some View {
        if isFeatured {
            ZStack {
                Ellipse()
                    .fill(Color.white.opacity(0.24))
                    .frame(width: size.width * 0.86, height: size.height * 0.38)
                    .blur(radius: 20)
                    .offset(
                        x: isRTL ? -size.width * 0.10 : size.width * 0.10,
                        y: -size.height * 0.24
                    )
                    .blendMode(.screen)

                RadialGradient(
                    colors: [glow.opacity(0.34), glow.opacity(0.08), .clear],
                    center: UnitPoint(x: isRTL ? 0.72 : 0.28, y: 0.22),
                    startRadius: 8,
                    endRadius: max(size.width, size.height) * 0.82
                )
            }
            .allowsHitTesting(false)
        }
    }

    private func textureOverlayLayer(in size: CGSize) -> some View {
        let lines = max(8, Int(size.height / 18))
        let spacing = max(5, size.height / CGFloat(lines + 5))

        return ZStack {
            VStack(spacing: spacing) {
                ForEach(0..<lines, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.020))
                        .frame(height: 1)
                }
            }
            .padding(.horizontal, 8)
            .rotationEffect(.degrees(-6))
            .blendMode(.softLight)
            .opacity(0.68)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.00), Color.white.opacity(0.20), Color.white.opacity(0.00)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size.width * 0.44)
                .rotationEffect(.degrees(isRTL ? 26 : -26))
                .offset(x: isRTL ? -size.width * 0.16 : size.width * 0.16, y: -size.height * 0.09)
                .blendMode(.screen)
                .opacity(isFeatured ? 0.50 : 0.34)
        }
    }

    private func readabilityOverlayLayer(in size: CGSize) -> some View {
        ZStack {
            cardShape
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.06), Color.black.opacity(isFeatured ? 0.84 : 0.80)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.97), Color.black.opacity(isFeatured ? 0.76 : 0.70), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(height: isFeatured ? size.height * 0.50 : size.height * 0.58)
                .frame(maxHeight: .infinity, alignment: .bottom)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(isFeatured ? 0.50 : 0.44), .clear],
                        startPoint: accentStart,
                        endPoint: accentEnd
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Rectangle()
                .fill(Color.black.opacity(isSmall ? 0.16 : 0.12))
                .frame(height: isSmall ? 12 : 16)
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private var textContentLayer: some View {
        VStack(alignment: isRTL ? .trailing : .leading, spacing: textStackSpacing) {
            if let tag, isFeatured {
                Text(tag)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.white.opacity(0.14))
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.26), lineWidth: 1)
                    )
            }

            Spacer(minLength: 0)

            Text(title)
                .font(.system(size: titleFontSize, weight: .black, design: .rounded))
                .foregroundStyle(isFeatured ? .white : .white.opacity(0.96))
                .lineLimit(1)
                .minimumScaleFactor(isFeatured ? 0.76 : 0.74)
                .kerning(isFeatured ? 0.42 : 0.18)
                .padding(.bottom, isSmall ? 1 : 3)
                .shadow(color: .black.opacity(0.74), radius: 5, x: 0, y: 2)
                .frame(maxWidth: .infinity, alignment: isRTL ? .trailing : .leading)

            Text(subtitle)
                .font(.system(size: subtitleFontSize, weight: .semibold))
                .foregroundStyle(Color.white.opacity(isFeatured ? 0.86 : 0.76))
                .lineLimit(isSmall ? 1 : 2)
                .minimumScaleFactor(0.75)
                .lineSpacing(1.4)
                .multilineTextAlignment(isRTL ? .trailing : .leading)
                .shadow(color: .black.opacity(0.52), radius: 2, x: 0, y: 1)
                .frame(maxWidth: .infinity, alignment: isRTL ? .trailing : .leading)

            HStack {
                if isRTL { nextChevron }
                Spacer()
                if !isRTL { nextChevron }
            }
        }
        .padding(contentPadding)
    }

    private var innerShadowLayer: some View {
        ZStack {
            cardShape
                .stroke(Color.black.opacity(0.48), lineWidth: isFeatured ? 8 : 6)
                .blur(radius: 4)
                .offset(y: 2.5)
                .mask(cardShape)

            cardShape
                .inset(by: 1)
                .stroke(Color.white.opacity(0.18), lineWidth: 1.4)
                .blur(radius: 1.6)
                .offset(y: -1)
                .mask(cardShape)
        }
    }

    @ViewBuilder
    private var featuredHaloLayer: some View {
        if isFeatured {
            cardShape
                .stroke(
                    LinearGradient(
                        colors: [glow.opacity(0.96), glow.opacity(0.36), Color.clear],
                        startPoint: accentStart,
                        endPoint: accentEnd
                    ),
                    lineWidth: 1.4
                )
                .shadow(color: glow.opacity(0.40), radius: 14, x: 0, y: 0)
        }
    }

    private var borderLayer: some View {
        ZStack {
            cardShape
                .stroke(Color.white.opacity(isFeatured ? 0.22 : 0.16), lineWidth: 1)

            cardShape
                .inset(by: 1.2)
                .stroke(glow.opacity(isFeatured ? 0.26 : 0.14), lineWidth: 0.8)
                .blendMode(.screen)

            cardShape
                .inset(by: 2.2)
                .stroke(Color.black.opacity(0.38), lineWidth: 0.9)
        }
    }

    private var topAccentLayer: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [glow.opacity(0.70), glow.opacity(0.16), .clear],
                    startPoint: accentStart,
                    endPoint: accentEnd
                )
            )
            .frame(height: isFeatured ? 3 : 2.5)
    }

    private var bottomSeparatorLayer: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(height: 1)
            .padding(.horizontal, 12)
    }

    private var sideAccentLayer: some View {
        Rectangle()
            .fill(glow.opacity(isFeatured ? 0.28 : 0.18))
            .frame(width: isFeatured ? 3 : 2.5)
    }

    @ViewBuilder
    private func backgroundArtwork(in size: CGSize) -> some View {
        if let image = UIImage(named: backgroundAsset) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
        } else {
            // Fallback backdrop when dedicated art assets are not in the catalog yet.
            ZStack {
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                AngularGradient(
                    colors: [Color.white.opacity(0.20), Color.clear, glow.opacity(0.26), Color.clear],
                    center: UnitPoint(x: isRTL ? 0.78 : 0.22, y: 0.28)
                )
                .blendMode(.screen)

                Ellipse()
                    .fill(Color.white.opacity(0.30))
                    .frame(width: size.width * 0.42, height: size.height * 0.56)
                    .blur(radius: 18)
                    .offset(
                        x: isRTL ? -size.width * 0.36 : size.width * 0.36,
                        y: -size.height * 0.36
                    )

                RadialGradient(
                    colors: [glow.opacity(0.52), glow.opacity(0.14), .clear],
                    center: UnitPoint(x: isRTL ? 0.78 : 0.22, y: 0.21),
                    startRadius: 12,
                    endRadius: max(size.width, size.height) * 0.82
                )

                Image(systemName: symbol)
                    .font(.system(size: symbolFontSize, weight: .black))
                    .foregroundStyle(
                        .white.opacity(
                            isFeatured ? 0.10 : (isSmall ? 0.12 : 0.16)
                        )
                    )
                    .offset(
                        x: isRTL ? -size.width * 0.20 : size.width * 0.20,
                        y: isFeatured ? -size.height * 0.04 : -size.height * 0.09
                    )
                    .blur(radius: isFeatured ? 0.7 : 0)

                VStack(spacing: size.height * 0.078) {
                    ForEach(0..<6, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.050))
                            .frame(height: 1)
                    }
                }
                .padding(.horizontal, 10)
            }
            .frame(width: size.width, height: size.height)
        }
    }

    private var nextChevron: some View {
        ZStack {
            RoundedRectangle(cornerRadius: isSmall ? 11.5 : 13, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: isSmall ? 11.5 : 13, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: isSmall ? 11.5 : 13, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.58), Color.white.opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            Image(systemName: isRTL ? "arrow.left" : "arrow.right")
                .font(.system(size: isSmall ? 11 : 12, weight: .black))
                .foregroundStyle(.white.opacity(0.94))
        }
        .frame(width: chevronControlSize, height: chevronControlSize)
        .scaleEffect(isTilePressed ? 0.90 : 1)
        .shadow(color: glow.opacity(isFeatured ? 0.34 : 0.20), radius: 8, x: 0, y: 3)
        .animation(.spring(response: 0.24, dampingFraction: 0.70), value: isTilePressed)
        .accessibilityHidden(true)
    }
}

private struct TeamHubPremiumCard: View {
    let card: TeamHubCard

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
            GeometryReader { proxy in
                let size = proxy.size
                let phaseTime = timeline.date.timeIntervalSinceReferenceDate + card.phase
                let gradientDrift = (sin(phaseTime * 0.55) + 1) / 2
                let pulse = (sin(phaseTime * 1.30) + 1) / 2
                let shimmerCycle = phaseTime.truncatingRemainder(dividingBy: 6.2) / 6.2
                let shimmerOffset = (CGFloat(shimmerCycle) * 2.4 - 0.8) * size.width
                let orbX = CGFloat(sin(phaseTime * 0.72)) * size.width * 0.22
                let orbY = CGFloat(cos(phaseTime * 0.64)) * size.height * 0.14
                let shape = RoundedRectangle(cornerRadius: 30, style: .continuous)
                let isTransferCenterTitle = card.title == "مركز الانتقالات"
                let titleSize: CGFloat = isTransferCenterTitle ? 32 : 40
                let titleTrailingInset: CGFloat = 92
                let titleLeadingInset: CGFloat = 26
                let titleScale: CGFloat = isTransferCenterTitle ? 0.76 : 0.68

                ZStack {
                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    card.colors[0].opacity(0.95),
                                    card.colors[1].opacity(0.94),
                                    card.colors[0].opacity(0.86)
                                ],
                                startPoint: UnitPoint(x: 0.10 + CGFloat(gradientDrift) * 0.48, y: 0.02),
                                endPoint: UnitPoint(x: 0.92 - CGFloat(gradientDrift) * 0.38, y: 1.02)
                            )
                        )

                    Circle()
                        .fill(card.glowColor.opacity(0.30))
                        .frame(width: size.height * 1.35, height: size.height * 1.35)
                        .blur(radius: 16)
                        .offset(x: orbX, y: -size.height * 0.28 + orbY)

                    shape
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.22), Color.white.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.screen)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.0),
                                    Color.white.opacity(0.0),
                                    Color.white.opacity(0.32),
                                    Color.white.opacity(0.0),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: size.width * 0.62)
                        .rotationEffect(.degrees(-17))
                        .offset(x: shimmerOffset)
                        .blur(radius: 0.6)
                        .blendMode(.screen)

                    shape
                        .stroke(Color.white.opacity(0.16), lineWidth: 0.9)

                    shape
                        .stroke(card.glowColor.opacity(0.60), lineWidth: 1.25)
                        .shadow(
                            color: card.glowColor.opacity(0.26 + 0.16 * pulse),
                            radius: 12 + 8 * pulse,
                            x: 0,
                            y: 0
                        )

                    Text(card.title)
                        .font(.system(size: titleSize, weight: .bold, design: .rounded))
                        .foregroundStyle(FootballTheme.textPrimary)
                        .lineLimit(isTransferCenterTitle ? 2 : 1)
                        .minimumScaleFactor(titleScale)
                        .allowsTightening(true)
                        .multilineTextAlignment(.trailing)
                        .padding(.leading, titleLeadingInset)
                        .padding(.trailing, titleTrailingInset)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

                    iconBadge(pulse: pulse)
                        .padding(.trailing, 22)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

                    shape
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.6)
                        .blur(radius: 0.8)
                        .offset(y: 0.4)
                }
                .clipShape(shape)
                .shadow(color: .black.opacity(0.28), radius: 14, x: 0, y: 9)
                .shadow(color: card.glowColor.opacity(0.30), radius: 22, x: 0, y: 10)
            }
        }
    }

    private func iconBadge(pulse: Double) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.24), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .stroke(Color.white.opacity(0.32), lineWidth: 1.0)

            Circle()
                .stroke(card.glowColor.opacity(0.35), lineWidth: 1.1)
                .blur(radius: 0.4)

            Image(systemName: card.icon)
                .font(.system(size: 27, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.96))
                .shadow(color: card.glowColor.opacity(0.45), radius: 8 + 4 * pulse, x: 0, y: 0)
        }
        .frame(width: 64, height: 64)
    }
}

private struct TeamManagementPortraitView: View {
    private enum TeamSectionTab: CaseIterable, Identifiable {
        case lineup
        case tactics
        case instructions
        case bench

        var id: String {
            switch self {
            case .lineup: return "lineup"
            case .tactics: return "tactics"
            case .instructions: return "instructions"
            case .bench: return "bench"
            }
        }
    }

    let language: AppLanguage
    @Binding var lineup: [TeamPlayer]
    @Binding var bench: [TeamPlayer]
    @Binding var tacticalPlan: TacticalPlan
    let onClose: () -> Void

    @State private var activeTab: TeamSectionTab = .lineup
    @State private var workingLineup: [TeamPlayer] = []
    @State private var workingBench: [TeamPlayer] = []
    @State private var baselineLineup: [TeamPlayer] = []
    @State private var baselineBench: [TeamPlayer] = []
    @State private var baselinePlan: TacticalPlan = .fourThreeThree

    @State private var selectedStarterID: UUID?
    @State private var selectedBenchID: UUID?

    @State private var pressingValue = 62.0
    @State private var compactnessValue = 56.0
    @State private var tempoValue = 58.0

    @State private var statusMessage = ""
    @State private var statusVisible = false

    @Namespace private var tabsNamespace

    private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
    }

    var body: some View {
        GeometryReader { proxy in
            let contentWidth = min(proxy.size.width - 24, 430)
            let pitchHeight = min(max(proxy.size.height * 0.44, 286), 396)

            ZStack {
                backgroundLayer

                VStack(spacing: 10) {
                    headerBar
                    tabsBar

                    if activeTab == .tactics {
                        tacticsStrip
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if activeTab == .instructions {
                        instructionsStrip
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    pitchSection(height: pitchHeight)
                    benchSection
                    selectionHint

                    if statusVisible {
                        statusPill
                    }
                }
                .frame(width: contentWidth)
                .padding(.top, 8)
                .padding(.bottom, 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            controlBar
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .animation(.easeInOut(duration: 0.22), value: activeTab)
        .animation(.spring(response: 0.30, dampingFraction: 0.80), value: selectedStarterID)
        .animation(.spring(response: 0.30, dampingFraction: 0.80), value: selectedBenchID)
        .onAppear {
            bootstrapState()
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x050815), Color(hex: 0x0B1F3F), Color(hex: 0x081A30)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(hex: 0x22C4FF, alpha: 0.24), Color.clear],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 280
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(hex: 0x7E95FF, alpha: 0.17), Color.clear],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 250
            )
            .ignoresSafeArea()
        }
    }

    private var headerBar: some View {
        ZStack {
            VStack(spacing: 3) {
                Text(t(ar: "إدارة الفريق", en: "Team Management", hi: "टीम प्रबंधन", zh: "球队管理", ku: "بەڕێوەبردنی تیم"))
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(t(ar: "الخطة", en: "Plan", hi: "योजना", zh: "阵型", ku: "پلان")): \(tacticalPlan.rawValue)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
            }

            HStack {
                Button {
                    onClose()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .black))
                        Text(t(ar: "رجوع", en: "Back", hi: "वापस", zh: "返回", ku: "گەڕانەوە"))
                            .font(.system(size: 13, weight: .black))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.10))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
                }
                .buttonStyle(InteractivePressButtonStyle())

                Spacer()
            }
        }
    }

    private var tabsBar: some View {
        HStack(spacing: 8) {
            ForEach(TeamSectionTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                        activeTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tabIcon(tab))
                            .font(.system(size: 14, weight: .black))
                        Text(tabTitle(tab))
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.80)
                    }
                    .foregroundStyle(activeTab == tab ? .black : .white.opacity(0.86))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        ZStack {
                            if activeTab == tab {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(FootballTheme.pitchGreen)
                                    .matchedGeometryEffect(id: "team-tab-active", in: tabsNamespace)
                            } else {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.07))
                            }
                        }
                    )
                }
                .buttonStyle(InteractivePressButtonStyle())
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.28))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var tacticsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TacticalPlan.allCases, id: \.self) { plan in
                    Button {
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                            tacticalPlan = plan
                        }
                    } label: {
                        VStack(spacing: 3) {
                            Text(plan.rawValue)
                                .font(.system(size: 14, weight: .black))
                            Text(plan.localizedStyleName(in: language))
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                        }
                        .foregroundStyle(tacticalPlan == plan ? .black : .white.opacity(0.88))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(tacticalPlan == plan ? FootballTheme.accentCyan : Color.white.opacity(0.09))
                        )
                    }
                    .buttonStyle(InteractivePressButtonStyle())
                }
            }
            .padding(.horizontal, 2)
        }
        .padding(.horizontal, 4)
    }

    private var instructionsStrip: some View {
        VStack(spacing: 8) {
            instructionRow(
                title: t(ar: "مستوى الضغط", en: "Pressing", hi: "प्रेसिंग", zh: "压迫", ku: "فشار"),
                icon: "bolt.fill",
                value: $pressingValue
            )
            instructionRow(
                title: t(ar: "تماسك الخطوط", en: "Compactness", hi: "सघनता", zh: "阵型紧凑", ku: "توندی هێڵەکان"),
                icon: "line.3.horizontal.decrease.circle.fill",
                value: $compactnessValue
            )
            instructionRow(
                title: t(ar: "سرعة التحول", en: "Transition Pace", hi: "ट्रांज़िशन गति", zh: "转换节奏", ku: "خێرایی گواستنەوە"),
                icon: "hare.fill",
                value: $tempoValue
            )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.13), lineWidth: 1)
                )
        )
    }

    private func instructionRow(title: String, icon: String, value: Binding<Double>) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(FootballTheme.accentCyan)
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.90))
                Spacer()
                Text("\(Int(value.wrappedValue))")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white.opacity(0.76))
            }

            Slider(value: value, in: 25...100, step: 1)
                .tint(FootballTheme.accentCyan)
        }
    }

    private func pitchSection(height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x144433, alpha: 0.84), Color(hex: 0x1D6A50, alpha: 0.80)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            GeometryReader { geo in
                let positions = pitchPositions(for: tacticalPlan)

                ZStack {
                    pitchMarkings(size: geo.size)
                    pitchZonesOverlay

                    ForEach(Array(workingLineup.enumerated()), id: \.element.id) { idx, player in
                        let point = positions[min(idx, positions.count - 1)]

                        starterCard(player)
                            .position(x: geo.size.width * point.x, y: geo.size.height * point.y)
                            .onTapGesture {
                                handleStarterTap(player.id)
                            }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.38), lineWidth: 1.2)
        }
        .frame(height: height)
        .shadow(color: Color.black.opacity(0.30), radius: 16, x: 0, y: 10)
        .shadow(color: FootballTheme.accentCyan.opacity(0.16), radius: 16, x: 0, y: 8)
    }

    private func pitchMarkings(size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.52), lineWidth: 1.2)
                .padding(14)

            Rectangle()
                .fill(Color.white.opacity(0.55))
                .frame(width: size.width - 36, height: 1.1)
                .position(x: size.width / 2, y: size.height / 2)

            Circle()
                .stroke(Color.white.opacity(0.62), lineWidth: 1.2)
                .frame(width: 74, height: 74)
                .position(x: size.width / 2, y: size.height / 2)

            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.white.opacity(0.62), lineWidth: 1.1)
                .frame(width: size.width * 0.46, height: size.height * 0.16)
                .position(x: size.width / 2, y: size.height * 0.08)

            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.white.opacity(0.62), lineWidth: 1.1)
                .frame(width: size.width * 0.46, height: size.height * 0.16)
                .position(x: size.width / 2, y: size.height * 0.92)
        }
    }

    private var pitchZonesOverlay: some View {
        VStack {
            zoneTag(t(ar: "هجوم", en: "Attack", hi: "आक्रमण", zh: "进攻", ku: "هێرش"))
            Spacer()
            zoneTag(t(ar: "وسط", en: "Midfield", hi: "मिडफ़ील्ड", zh: "中场", ku: "ناوەڕاست"))
            Spacer()
            zoneTag(t(ar: "دفاع", en: "Defense", hi: "रक्षा", zh: "防守", ku: "بەرگری"))
            Spacer()
            zoneTag(t(ar: "حارس", en: "Goalkeeper", hi: "गोलकीपर", zh: "门将", ku: "گۆڵپارێز"))
        }
        .padding(.vertical, 16)
        .padding(.trailing, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    }

    private func zoneTag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(.white.opacity(0.76))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.16))
            )
    }

    private func starterCard(_ player: TeamPlayer) -> some View {
        let isSelected = selectedStarterID == player.id
        let readiness = readinessPercent(for: player)
        let cardFill = isSelected ? FootballTheme.pointsYellow.opacity(0.94) : Color.white.opacity(0.14)
        let textColor: Color = isSelected ? .black : .white

        return VStack(spacing: 2) {
            Text(compactPlayerName(player))
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(textColor.opacity(0.94))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            HStack(spacing: 3) {
                Text(player.role)
                    .font(.system(size: 9, weight: .black))
                Text("•")
                    .font(.system(size: 8, weight: .black))
                Text("\(playerRating(for: player))")
                    .font(.system(size: 9, weight: .black))
            }
            .foregroundStyle(textColor.opacity(0.86))

            readinessBar(percent: readiness, isSelected: isSelected)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .frame(width: 88)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? Color.white.opacity(0.95) : Color.white.opacity(0.28), lineWidth: isSelected ? 1.8 : 0.9)
        )
        .shadow(color: isSelected ? FootballTheme.pointsYellow.opacity(0.56) : Color.black.opacity(0.20), radius: isSelected ? 12 : 4, x: 0, y: isSelected ? 6 : 2)
        .accessibilityLabel("\(compactPlayerName(player)) \(player.role)")
    }

    private func readinessBar(percent: Int, isSelected: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(readinessColor(percent))
                .frame(width: 6, height: 6)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill((isSelected ? Color.black : Color.white).opacity(0.16))
                    Capsule()
                        .fill(readinessColor(percent))
                        .frame(width: geo.size.width * CGFloat(percent) / 100.0)
                }
            }
            .frame(height: 5)
        }
        .frame(height: 7)
    }

    private var benchSection: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Text(t(ar: "البدلاء", en: "Bench", hi: "बेंच", zh: "替补", ku: "ئەندامانی یەدەک"))
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Text("\(workingBench.count) \(t(ar: "لاعب", en: "players", hi: "खिलाड़ी", zh: "球员", ku: "یاریزان"))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(workingBench) { player in
                        benchCard(player)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.28))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.13), lineWidth: 1)
                )
        )
    }

    private func benchCard(_ player: TeamPlayer) -> some View {
        let isSelected = selectedBenchID == player.id
        let readiness = readinessPercent(for: player)

        return Button {
            handleBenchTap(player.id)
        } label: {
            VStack(alignment: .trailing, spacing: 5) {
                Text(compactPlayerName(player))
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(isSelected ? .black : .white.opacity(0.94))
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                HStack(spacing: 6) {
                    Text("\(playerRating(for: player))")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(isSelected ? .black.opacity(0.88) : FootballTheme.pointsYellow)

                    Text(player.role)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isSelected ? .black.opacity(0.86) : .white.opacity(0.82))

                    Spacer(minLength: 0)
                }

                HStack(spacing: 4) {
                    Circle()
                        .fill(readinessColor(readiness))
                        .frame(width: 6, height: 6)
                    Text("\(readiness)%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isSelected ? .black.opacity(0.80) : .white.opacity(0.74))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(width: 132, height: 82)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(isSelected ? FootballTheme.accentCyan : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(isSelected ? Color.white.opacity(0.95) : Color.white.opacity(0.18), lineWidth: isSelected ? 1.7 : 1)
            )
            .shadow(color: isSelected ? FootballTheme.accentCyan.opacity(0.40) : Color.black.opacity(0.14), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var selectionHint: some View {
        Text(selectionHintText())
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.75))
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func selectionHintText() -> String {
        if selectedStarterID != nil {
            return t(
                ar: "تم تحديد لاعب أساسي. اضغط لاعبًا آخر للتبديل أو اختر بديلًا.",
                en: "Starter selected. Tap another starter or a bench player to swap.",
                hi: "स्टार्टर चुना गया। अदला-बदली के लिए दूसरा खिलाड़ी चुनें।",
                zh: "已选首发，点击其他球员或替补进行交换。",
                ku: "یاریزانی سەرەکی هەڵبژێردرا. یاریزانێکی تر یان یەدەک هەڵبژێرە بۆ گۆڕین."
            )
        }

        if selectedBenchID != nil {
            return t(
                ar: "تم تحديد لاعب احتياطي. اختر لاعبًا أساسيًا لإتمام التبديل.",
                en: "Bench player selected. Tap a starter to complete the swap.",
                hi: "बेंच खिलाड़ी चुना गया। अदला-बदली के लिए स्टार्टर चुनें।",
                zh: "已选替补，请点击首发完成交换。",
                ku: "یاریزانی یەدەک هەڵبژێردرا. یاریزانێکی سەرەکی هەڵبژێرە بۆ تەواوکردنی گۆڕین."
            )
        }

        return t(
            ar: "اضغط أي لاعب لتحديده.",
            en: "Tap any player to select.",
            hi: "चुनने के लिए किसी खिलाड़ी पर टैप करें।",
            zh: "点击任意球员进行选择。",
            ku: "بۆ هەڵبژاردن لەسەر هەر یاریزانێک بکە."
        )
    }

    private var statusPill: some View {
        Text(statusMessage)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.34))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
            )
            .transition(.opacity.combined(with: .scale(scale: 0.92)))
    }

    private var controlBar: some View {
        HStack(spacing: 8) {
            controlButton(
                title: t(ar: "حفظ", en: "Save", hi: "सेव", zh: "保存", ku: "هەڵگرتن"),
                icon: "checkmark.circle.fill",
                fill: FootballTheme.pitchGreen,
                foreground: .black
            ) {
                saveChanges()
            }

            controlButton(
                title: t(ar: "إعادة ضبط", en: "Reset", hi: "रीसेट", zh: "重置", ku: "نوێکردنەوە"),
                icon: "arrow.counterclockwise.circle.fill",
                fill: Color.white.opacity(0.14),
                foreground: .white
            ) {
                resetChanges()
            }

            controlButton(
                title: t(ar: "تبديل تلقائي", en: "Auto Swap", hi: "ऑटो स्वैप", zh: "自动轮换", ku: "گۆڕینی خۆکار"),
                icon: "shuffle.circle.fill",
                fill: FootballTheme.accentCyan,
                foreground: .black
            ) {
                autoSwap()
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.40))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.28), radius: 12, x: 0, y: 6)
    }

    private func controlButton(title: String, icon: String, fill: Color, foreground: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .black))
                Text(title)
                    .font(.system(size: 12, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(fill)
            )
        }
        .buttonStyle(InteractivePressButtonStyle())
    }

    private func tabTitle(_ tab: TeamSectionTab) -> String {
        switch tab {
        case .lineup:
            return t(ar: "التشكيلة", en: "Lineup", hi: "लाइनअप", zh: "阵容", ku: "پێکهاتە")
        case .tactics:
            return t(ar: "التكتيك", en: "Tactics", hi: "रणनीति", zh: "战术", ku: "تەکتیک")
        case .instructions:
            return t(ar: "التعليمات", en: "Instructions", hi: "निर्देश", zh: "指令", ku: "ڕێنمایی")
        case .bench:
            return t(ar: "البدلاء", en: "Bench", hi: "बेंच", zh: "替补", ku: "یەدەک")
        }
    }

    private func tabIcon(_ tab: TeamSectionTab) -> String {
        switch tab {
        case .lineup: return "sportscourt.fill"
        case .tactics: return "target"
        case .instructions: return "slider.horizontal.3"
        case .bench: return "person.3.sequence.fill"
        }
    }

    private func compactPlayerName(_ player: TeamPlayer) -> String {
        let localized = localizedDisplayName(player.name, in: language)
        let parts = localized.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0]) \(parts[1])"
        }
        return String(localized.prefix(14))
    }

    private func playerRating(for player: TeamPlayer) -> Int {
        let roleSeed = player.role.unicodeScalars.reduce(0) { partial, scalar in
            partial + Int(scalar.value)
        }
        let base = 68 + ((player.number * 11 + roleSeed) % 24)
        return min(max(base, 65), 95)
    }

    private func readinessPercent(for player: TeamPlayer) -> Int {
        let roleSeed = player.role.unicodeScalars.reduce(0) { partial, scalar in
            partial + Int(scalar.value)
        }
        return 60 + ((player.number * 17 + roleSeed) % 36)
    }

    private func readinessColor(_ percent: Int) -> Color {
        if percent >= 84 { return FootballTheme.accentGreen }
        if percent >= 72 { return FootballTheme.pointsYellow }
        return FootballTheme.dangerRed
    }

    private func bootstrapState() {
        workingLineup = lineup
        workingBench = bench
        baselineLineup = lineup
        baselineBench = bench
        baselinePlan = tacticalPlan
        selectedStarterID = nil
        selectedBenchID = nil
    }

    private func saveChanges() {
        lineup = workingLineup
        bench = workingBench
        baselineLineup = workingLineup
        baselineBench = workingBench
        baselinePlan = tacticalPlan
        showStatus(
            t(ar: "تم حفظ التعديلات", en: "Changes saved", hi: "बदलाव सेव हुए", zh: "已保存更改", ku: "گۆڕانکارییەکان هەڵگیران")
        )
    }

    private func resetChanges() {
        workingLineup = baselineLineup
        workingBench = baselineBench
        tacticalPlan = baselinePlan
        selectedStarterID = nil
        selectedBenchID = nil
        showStatus(
            t(ar: "تمت إعادة الضبط", en: "Reset completed", hi: "रीसेट पूरा हुआ", zh: "已重置", ku: "ڕێکخستنەکان نوێکرانەوە")
        )
    }

    private func autoSwap() {
        guard !workingLineup.isEmpty, !workingBench.isEmpty else { return }

        guard
            let weakestStarter = workingLineup.indices.min(by: { idxA, idxB in
                readinessPercent(for: workingLineup[idxA]) < readinessPercent(for: workingLineup[idxB])
            }),
            let strongestBench = workingBench.indices.max(by: { idxA, idxB in
                readinessPercent(for: workingBench[idxA]) < readinessPercent(for: workingBench[idxB])
            })
        else { return }

        let starterReadiness = readinessPercent(for: workingLineup[weakestStarter])
        let benchReadiness = readinessPercent(for: workingBench[strongestBench])

        guard benchReadiness > starterReadiness else {
            showStatus(
                t(ar: "التشكيلة الأساسية جاهزة حاليًا", en: "Starting lineup is already optimized", hi: "स्टार्टिंग लाइनअप पहले से बेहतर है", zh: "首发当前已较优", ku: "پێکهاتەی سەرەکی لە ئێستادا باشە")
            )
            return
        }

        swapStarterWithBench(starterIndex: weakestStarter, benchIndex: strongestBench)
        showStatus(
            t(ar: "تم تنفيذ تبديل تلقائي", en: "Auto swap completed", hi: "ऑटो स्वैप पूरा हुआ", zh: "已完成自动轮换", ku: "گۆڕینی خۆکار ئەنجامدرا")
        )
    }

    private func handleStarterTap(_ playerID: UUID) {
        if let selectedBenchID {
            swapSelectedStarterWithBench(starterID: playerID, benchID: selectedBenchID)
            return
        }

        if let currentStarterID = selectedStarterID, currentStarterID != playerID {
            swapStarterPositions(firstID: currentStarterID, secondID: playerID)
            selectedStarterID = nil
            showStatus(
                t(ar: "تم تبديل مراكز لاعبين أساسيين", en: "Starters swapped", hi: "स्टार्टर बदले गए", zh: "首发球员已互换", ku: "شوێنی دوو یاریزانی سەرەکی گۆڕدرا")
            )
            return
        }

        selectedStarterID = (selectedStarterID == playerID) ? nil : playerID
        selectedBenchID = nil
    }

    private func handleBenchTap(_ playerID: UUID) {
        if let starterID = selectedStarterID {
            swapSelectedStarterWithBench(starterID: starterID, benchID: playerID)
            return
        }

        selectedBenchID = (selectedBenchID == playerID) ? nil : playerID
        selectedStarterID = nil
    }

    private func swapSelectedStarterWithBench(starterID: UUID, benchID: UUID) {
        guard
            let starterIndex = workingLineup.firstIndex(where: { $0.id == starterID }),
            let benchIndex = workingBench.firstIndex(where: { $0.id == benchID })
        else { return }

        swapStarterWithBench(starterIndex: starterIndex, benchIndex: benchIndex)
        showStatus(
            t(ar: "تم تبديل لاعب أساسي مع بديل", en: "Starter swapped with bench player", hi: "स्टार्टर और बेंच खिलाड़ी बदले गए", zh: "首发与替补已互换", ku: "یاریزانی سەرەکی لەگەڵ یەدەک گۆڕدرا")
        )
    }

    private func swapStarterWithBench(starterIndex: Int, benchIndex: Int) {
        let starter = workingLineup[starterIndex]
        workingLineup[starterIndex] = workingBench[benchIndex]
        workingBench[benchIndex] = starter
        selectedStarterID = nil
        selectedBenchID = nil
    }

    private func swapStarterPositions(firstID: UUID, secondID: UUID) {
        guard
            let firstIndex = workingLineup.firstIndex(where: { $0.id == firstID }),
            let secondIndex = workingLineup.firstIndex(where: { $0.id == secondID })
        else { return }

        workingLineup.swapAt(firstIndex, secondIndex)
        selectedBenchID = nil
    }

    private func showStatus(_ message: String) {
        statusMessage = message
        withAnimation(.easeInOut(duration: 0.2)) {
            statusVisible = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeInOut(duration: 0.2)) {
                statusVisible = false
            }
        }
    }

    private func pitchPositions(for plan: TacticalPlan) -> [CGPoint] {
        switch plan {
        case .fourThreeThree:
            return [
                CGPoint(x: 0.5, y: 0.90),
                CGPoint(x: 0.82, y: 0.75),
                CGPoint(x: 0.62, y: 0.70),
                CGPoint(x: 0.38, y: 0.70),
                CGPoint(x: 0.18, y: 0.75),
                CGPoint(x: 0.50, y: 0.58),
                CGPoint(x: 0.65, y: 0.49),
                CGPoint(x: 0.35, y: 0.49),
                CGPoint(x: 0.78, y: 0.33),
                CGPoint(x: 0.50, y: 0.24),
                CGPoint(x: 0.22, y: 0.33)
            ]
        case .fourTwoThreeOne:
            return [
                CGPoint(x: 0.5, y: 0.90),
                CGPoint(x: 0.82, y: 0.77),
                CGPoint(x: 0.62, y: 0.73),
                CGPoint(x: 0.38, y: 0.73),
                CGPoint(x: 0.18, y: 0.77),
                CGPoint(x: 0.60, y: 0.60),
                CGPoint(x: 0.40, y: 0.60),
                CGPoint(x: 0.80, y: 0.45),
                CGPoint(x: 0.50, y: 0.42),
                CGPoint(x: 0.20, y: 0.45),
                CGPoint(x: 0.50, y: 0.24)
            ]
        case .threeFiveTwo:
            return [
                CGPoint(x: 0.5, y: 0.90),
                CGPoint(x: 0.72, y: 0.74),
                CGPoint(x: 0.50, y: 0.71),
                CGPoint(x: 0.28, y: 0.74),
                CGPoint(x: 0.85, y: 0.56),
                CGPoint(x: 0.65, y: 0.56),
                CGPoint(x: 0.50, y: 0.52),
                CGPoint(x: 0.35, y: 0.56),
                CGPoint(x: 0.15, y: 0.56),
                CGPoint(x: 0.62, y: 0.30),
                CGPoint(x: 0.38, y: 0.30)
            ]
        }
    }
}

private struct TeamCenterPlayersView: View {
    private enum SquadFilter: CaseIterable, Identifiable {
        case all
        case starters
        case bench

        var id: String {
            switch self {
            case .all: return "all"
            case .starters: return "starters"
            case .bench: return "bench"
            }
        }
    }

    private struct PlayerEntry: Identifiable, Hashable {
        let player: TeamPlayer
        let isStarter: Bool

        var id: UUID { player.id }

        static func == (lhs: PlayerEntry, rhs: PlayerEntry) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    private struct PlayerProfileData {
        let overall: Int
        let age: Int
        let nationality: String
        let heightCM: Int
        let weightKG: Int
        let birthDateText: String
        let preferredFoot: String
        let readiness: Int
        let fitnessStatus: String
        let marketValueM: Int
        let contractYears: Int
        let contractUntil: String
    }

    private struct InfoTile: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let tint: Color
    }

    private enum SquadUnit {
        case attack
        case midfield
        case defense
        case goalkeeper
    }

    let language: AppLanguage
    let lineup: [TeamPlayer]
    let bench: [TeamPlayer]
    let onClose: () -> Void

    @State private var activeFilter: SquadFilter = .all
    @State private var selectedPlayerForDetails: PlayerEntry?
    @State private var highlightedPlayerID: UUID?
    @State private var listAnimateIn = false

    @Namespace private var listNamespace

    private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
    }

    private var allPlayers: [PlayerEntry] {
        let starters = lineup.map { PlayerEntry(player: $0, isStarter: true) }
        let reserves = bench.map { PlayerEntry(player: $0, isStarter: false) }
        return starters + reserves
    }

    private var filteredPlayers: [PlayerEntry] {
        switch activeFilter {
        case .all:
            return allPlayers
        case .starters:
            return allPlayers.filter(\.isStarter)
        case .bench:
            return allPlayers.filter { !$0.isStarter }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                centerBackground

                VStack(spacing: 10) {
                    centerHeader
                    statsStrip
                    filterBar
                    playersList
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .navigationBarHidden(true)
            .environment(\.layoutDirection, .rightToLeft)
            .navigationDestination(item: $selectedPlayerForDetails) { entry in
                PlayerDetailsPremiumView(
                    language: language,
                    entry: entry,
                    profile: profile(for: entry),
                    onClose: {
                        selectedPlayerForDetails = nil
                    }
                )
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.35)) {
                    listAnimateIn = true
                }
            }
        }
    }

    private var centerBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x060B1A), Color(hex: 0x0C2448), Color(hex: 0x071A36)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(hex: 0x3EBBFF, alpha: 0.22), Color.clear],
                center: .top,
                startRadius: 40,
                endRadius: 250
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(hex: 0x6F78FF, alpha: 0.16), Color.clear],
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 220
            )
            .ignoresSafeArea()
        }
    }

    private var centerHeader: some View {
        ZStack {
            VStack(spacing: 3) {
                Text(t(ar: "مركز الفريق", en: "Team Center", hi: "टीम सेंटर", zh: "球队中心", ku: "ناوەندی تیم"))
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(t(ar: "قائمة اللاعبين", en: "Squad Players", hi: "स्क्वाड खिलाड़ी", zh: "球队球员", ku: "یاریزانانی تیم"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
            }

            HStack {
                Button {
                    onClose()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .black))
                        Text(t(ar: "رجوع", en: "Back", hi: "वापस", zh: "返回", ku: "گەڕانەوە"))
                            .font(.system(size: 13, weight: .black))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.11))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
                }
                .buttonStyle(InteractivePressButtonStyle())

                Spacer()
            }
        }
    }

    private var statsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                miniStat(
                    title: t(ar: "الإجمالي", en: "Total", hi: "कुल", zh: "总数", ku: "کۆی گشتی"),
                    value: "\(allPlayers.count)",
                    tint: FootballTheme.accentCyan
                )
                miniStat(
                    title: t(ar: "الهجوم", en: "Attack", hi: "आक्रमण", zh: "进攻", ku: "هێرش"),
                    value: "\(playersCount(for: .attack))",
                    tint: FootballTheme.pointsYellow
                )
                miniStat(
                    title: t(ar: "الوسط", en: "Midfield", hi: "मिडफ़ील्ड", zh: "中场", ku: "ناوەڕاست"),
                    value: "\(playersCount(for: .midfield))",
                    tint: FootballTheme.accentGreen
                )
                miniStat(
                    title: t(ar: "الدفاع", en: "Defense", hi: "रक्षा", zh: "防守", ku: "بەرگری"),
                    value: "\(playersCount(for: .defense))",
                    tint: FootballTheme.accentCyan
                )
                miniStat(
                    title: t(ar: "الحارس", en: "Goalkeeper", hi: "गोलकीपर", zh: "门将", ku: "گۆڵپارێز"),
                    value: "\(playersCount(for: .goalkeeper))",
                    tint: FootballTheme.pitchGreen
                )
            }
        }
    }

    private func miniStat(title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(tint)
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.74))
        }
        .frame(width: 90)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
    }

    private func playersCount(for unit: SquadUnit) -> Int {
        allPlayers.filter { roleUnit(for: $0.player.role) == unit }.count
    }

    private func roleUnit(for role: String) -> SquadUnit {
        let key = role.uppercased()
        switch key {
        case "GK":
            return .goalkeeper
        case "RB", "RWB", "CB", "LB", "LWB", "SW":
            return .defense
        case "DM", "CM", "AM", "RM", "LM", "MF":
            return .midfield
        case "RW", "LW", "ST", "CF", "SS", "FW":
            return .attack
        default:
            return .midfield
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(SquadFilter.allCases) { filter in
                Button {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                        activeFilter = filter
                    }
                } label: {
                    Text(filterTitle(filter))
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(activeFilter == filter ? .black : .white.opacity(0.86))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(activeFilter == filter ? FootballTheme.pitchGreen : Color.white.opacity(0.09))
                        )
                }
                .buttonStyle(InteractivePressButtonStyle())
            }
        }
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
    }

    private func filterTitle(_ filter: SquadFilter) -> String {
        switch filter {
        case .all:
            return t(ar: "الكل", en: "All", hi: "सभी", zh: "全部", ku: "هەموو")
        case .starters:
            return t(ar: "التشكيلة", en: "Lineup", hi: "लाइनअप", zh: "首发阵容", ku: "پێکهاتە")
        case .bench:
            return t(ar: "البدلاء", en: "Bench", hi: "बेंच", zh: "替补", ku: "یەدەک")
        }
    }

    private var playersList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(Array(filteredPlayers.enumerated()), id: \.element.id) { index, entry in
                    playerCard(entry)
                        .opacity(listAnimateIn ? 1 : 0)
                        .offset(y: listAnimateIn ? 0 : 14)
                        .animation(
                            .spring(response: 0.38, dampingFraction: 0.84).delay(Double(index) * 0.02),
                            value: listAnimateIn
                        )
                }
            }
            .padding(.top, 2)
            .padding(.bottom, 12)
        }
    }

    private func playerCard(_ entry: PlayerEntry) -> some View {
        let profileData = profile(for: entry)
        let selected = highlightedPlayerID == entry.id

        return Button {
            selectPlayer(entry)
        } label: {
            HStack(spacing: 10) {
                ZStack(alignment: .bottom) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: entry.isStarter
                                    ? [Color(hex: 0x2EEA99), Color(hex: 0x0CA36F)]
                                    : [Color(hex: 0x56AEFF), Color(hex: 0x3874D6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.42), lineWidth: 1)
                        )
                        .shadow(color: (entry.isStarter ? FootballTheme.pitchGreen : FootballTheme.accentCyan).opacity(0.34), radius: 8, x: 0, y: 4)

                    Image(systemName: "person.fill")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(Color.white.opacity(0.95))
                        .offset(y: -4)

                    Text("#\(entry.player.number)")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.black.opacity(0.84))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.88)))
                        .offset(y: 9)
                }

                VStack(alignment: .trailing, spacing: 5) {
                    Text(localizedDisplayName(entry.player.name, in: language))
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    HStack(spacing: 6) {
                        rolePill(entry.player.role)
                        rolePill(entry.isStarter
                                 ? t(ar: "أساسي", en: "Starter", hi: "स्टार्टर", zh: "首发", ku: "سەرەکی")
                                 : t(ar: "بديل", en: "Bench", hi: "बेंच", zh: "替补", ku: "یەدەک"))

                        Spacer(minLength: 0)

                        HStack(spacing: 4) {
                            Circle()
                                .fill(readinessColor(profileData.readiness))
                                .frame(width: 7, height: 7)
                            Text("\(profileData.readiness)%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white.opacity(0.78))
                        }
                    }
                }

                VStack(spacing: 3) {
                    Text("\(profileData.overall)")
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(FootballTheme.pointsYellow)
                    Text(t(ar: "تقييم", en: "OVR", hi: "रेटिंग", zh: "评分", ku: "هەڵسەنگاندن"))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .frame(width: 56)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: selected
                                ? [Color(hex: 0x1F4F9D), Color(hex: 0x2444A8)]
                                : [Color.white.opacity(0.11), Color.white.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? Color.white.opacity(0.86) : Color.white.opacity(0.18), lineWidth: selected ? 1.6 : 1)
            )
            .shadow(color: selected ? FootballTheme.accentCyan.opacity(0.35) : Color.black.opacity(0.18), radius: selected ? 14 : 6, x: 0, y: selected ? 9 : 4)
            .scaleEffect(selected ? 0.98 : 1)
            .matchedGeometryEffect(id: entry.id.uuidString, in: listNamespace, isSource: true)
        }
        .buttonStyle(.plain)
    }

    private func rolePill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(.white.opacity(0.86))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.24))
            )
    }

    private func selectPlayer(_ entry: PlayerEntry) {
        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
            highlightedPlayerID = entry.id
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            selectedPlayerForDetails = entry
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            withAnimation(.easeOut(duration: 0.2)) {
                highlightedPlayerID = nil
            }
        }
    }

    private func playerRating(for player: TeamPlayer, isStarter: Bool) -> Int {
        let roleSeed = player.role.unicodeScalars.reduce(0) { partial, scalar in
            partial + Int(scalar.value)
        }
        let base = 67 + ((player.number * 13 + roleSeed) % 22) + (isStarter ? 4 : 0)
        return min(max(base, 64), 95)
    }

    private func readinessPercent(for player: TeamPlayer) -> Int {
        let roleSeed = player.role.unicodeScalars.reduce(0) { partial, scalar in
            partial + Int(scalar.value)
        }
        return 58 + ((player.number * 19 + roleSeed) % 40)
    }

    private func readinessColor(_ percent: Int) -> Color {
        if percent >= 84 { return FootballTheme.accentGreen }
        if percent >= 72 { return FootballTheme.pointsYellow }
        return FootballTheme.dangerRed
    }

    private func profile(for entry: PlayerEntry) -> PlayerProfileData {
        let seed = entry.player.name.unicodeScalars.reduce(entry.player.number * 57) { partial, scalar in
            partial + Int(scalar.value)
        }
        let overall = playerRating(for: entry.player, isStarter: entry.isStarter)
        let age = 18 + (seed % 17)
        let heightCM = 168 + (seed % 26)
        let weightKG = 63 + (seed % 18)
        let readiness = readinessPercent(for: entry.player)
        let fitnessStatus: String
        if readiness >= 88 {
            fitnessStatus = t(ar: "جاهز بالكامل", en: "Fully fit", hi: "पूरी तरह फिट", zh: "状态极佳", ku: "تەواو ئامادەیە")
        } else if readiness >= 74 {
            fitnessStatus = t(ar: "جاهز", en: "Match ready", hi: "मैच फिट", zh: "可出场", ku: "ئامادەی یارییە")
        } else {
            fitnessStatus = t(ar: "يحتاج متابعة", en: "Needs monitoring", hi: "निगरानी ज़रूरी", zh: "需观察", ku: "پێویستی بە چاودێری هەیە")
        }

        let foot = preferredFoot(seed: seed)
        let nationality = nationalityName(seed: seed)
        let marketValueM = max(3, (overall * 2) + (entry.isStarter ? 10 : 2) - max(age - 28, 0))
        let contractYears = 1 + (seed % 5)
        let birthDateText = formattedBirthDate(seed: seed, age: age)
        let contractUntil = formattedContractEnd(years: contractYears)

        return PlayerProfileData(
            overall: overall,
            age: age,
            nationality: nationality,
            heightCM: heightCM,
            weightKG: weightKG,
            birthDateText: birthDateText,
            preferredFoot: foot,
            readiness: readiness,
            fitnessStatus: fitnessStatus,
            marketValueM: marketValueM,
            contractYears: contractYears,
            contractUntil: contractUntil
        )
    }

    private func preferredFoot(seed: Int) -> String {
        if seed % 7 == 0 {
            return t(ar: "كلتا القدمين", en: "Both", hi: "दोनों पैर", zh: "双足", ku: "هەردوو پێ")
        }
        if seed % 2 == 0 {
            return t(ar: "اليمنى", en: "Right", hi: "दायां", zh: "右脚", ku: "ڕاست")
        }
        return t(ar: "اليسرى", en: "Left", hi: "बायां", zh: "左脚", ku: "چەپ")
    }

    private func nationalityName(seed: Int) -> String {
        switch seed % 12 {
        case 0: return t(ar: "إسبانيا", en: "Spain", hi: "स्पेन", zh: "西班牙", ku: "ئیسپانیا")
        case 1: return t(ar: "فرنسا", en: "France", hi: "फ्रांस", zh: "法国", ku: "فەرەنسا")
        case 2: return t(ar: "البرازيل", en: "Brazil", hi: "ब्राज़ील", zh: "巴西", ku: "برازیل")
        case 3: return t(ar: "الأرجنتين", en: "Argentina", hi: "अर्जेंटीना", zh: "阿根廷", ku: "ئەرجەنتین")
        case 4: return t(ar: "إنجلترا", en: "England", hi: "इंग्लैंड", zh: "英格兰", ku: "ئینگلتەرا")
        case 5: return t(ar: "إيطاليا", en: "Italy", hi: "इटली", zh: "意大利", ku: "ئیتالیا")
        case 6: return t(ar: "البرتغال", en: "Portugal", hi: "पुर्तगाल", zh: "葡萄牙", ku: "پورتوگال")
        case 7: return t(ar: "ألمانيا", en: "Germany", hi: "जर्मनी", zh: "德国", ku: "ئەڵمانیا")
        case 8: return t(ar: "هولندا", en: "Netherlands", hi: "नीदरलैंड", zh: "荷兰", ku: "هۆڵەندا")
        case 9: return t(ar: "بلجيكا", en: "Belgium", hi: "बेल्जियम", zh: "比利时", ku: "بەلجیکا")
        case 10: return t(ar: "المغرب", en: "Morocco", hi: "मोरक्को", zh: "摩洛哥", ku: "مەغریب")
        default: return t(ar: "كرواتيا", en: "Croatia", hi: "क्रोएशिया", zh: "克罗地亚", ku: "کرۆاتیا")
        }
    }

    private func formattedBirthDate(seed: Int, age: Int) -> String {
        let month = (seed % 12) + 1
        let day = (seed % 27) + 1
        let year = Calendar.current.component(.year, from: Date()) - age
        var comp = DateComponents()
        comp.year = year
        comp.month = month
        comp.day = day
        let date = Calendar.current.date(from: comp) ?? Date()

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.localeIdentifier)
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formattedContractEnd(years: Int) -> String {
        let date = Calendar.current.date(byAdding: .year, value: years, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.localeIdentifier)
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private struct PlayerDetailsPremiumView: View {
        let language: AppLanguage
        let entry: PlayerEntry
        let profile: PlayerProfileData
        let onClose: () -> Void

        private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
            language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
        }

        var body: some View {
            ZStack {
                detailBackground

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        detailHeader
                        heroCard
                        infoSections
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 14)
                }
            }
            .navigationBarBackButtonHidden(true)
            .environment(\.layoutDirection, .rightToLeft)
        }

        private var detailBackground: some View {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0x050916), Color(hex: 0x111E45), Color(hex: 0x0A1531)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                RadialGradient(
                    colors: [Color(hex: 0x4BC9FF, alpha: 0.20), Color.clear],
                    center: .top,
                    startRadius: 20,
                    endRadius: 240
                )
                .ignoresSafeArea()
            }
        }

        private var detailHeader: some View {
            HStack {
                Button {
                    onClose()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .black))
                        Text(t(ar: "اللاعبون", en: "Players", hi: "खिलाड़ी", zh: "球员", ku: "یاریزانان"))
                            .font(.system(size: 13, weight: .black))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.10))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
                }
                .buttonStyle(InteractivePressButtonStyle())

                Spacer()

                Text(t(ar: "تفاصيل اللاعب", en: "Player Details", hi: "खिलाड़ी विवरण", zh: "球员详情", ku: "وردەکاری یاریزان"))
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
        }

        private var heroCard: some View {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0x2A4CA8), Color(hex: 0x2D77D7), Color(hex: 0x1E2E88)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RadialGradient(
                        colors: [Color.white.opacity(0.30), Color.clear],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: 150
                    )

                    VStack(spacing: 8) {
                        ZStack(alignment: .bottom) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.92), Color.white.opacity(0.64)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 118, height: 118)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.44), lineWidth: 1.1)
                                )

                            Image(systemName: "person.fill")
                                .font(.system(size: 54, weight: .black))
                                .foregroundStyle(Color(hex: 0x1A53A5))
                                .offset(y: -8)

                            Text("#\(entry.player.number)")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(.black.opacity(0.82))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.93))
                                )
                                .offset(y: 11)
                        }

                        Text(localizedDisplayName(entry.player.name, in: language))
                            .font(.system(size: 27, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        HStack(spacing: 8) {
                            heroPill(entry.player.role)
                            heroPill("\(t(ar: "تقييم", en: "OVR", hi: "रेटिंग", zh: "评分", ku: "هەڵسەنگاندن")) \(profile.overall)")
                            heroPill(profile.fitnessStatus)
                        }

                        readinessProgress
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 16)
                }
                .frame(height: 330)
                .shadow(color: FootballTheme.accentCyan.opacity(0.25), radius: 18, x: 0, y: 10)
            }
        }

        private var readinessProgress: some View {
            VStack(spacing: 5) {
                HStack {
                    Text("\(t(ar: "الجاهزية", en: "Readiness", hi: "तैयारी", zh: "状态", ku: "ئامادەیی")) \(profile.readiness)%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.90))
                    Spacer(minLength: 0)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                        Capsule()
                            .fill(readinessColor(profile.readiness))
                            .frame(width: geo.size.width * CGFloat(profile.readiness) / 100)
                    }
                }
                .frame(height: 8)
            }
            .padding(.top, 2)
        }

        private func heroPill(_ text: String) -> some View {
            Text(text)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.24))
                )
        }

        private var infoSections: some View {
            VStack(spacing: 10) {
                infoSection(
                    title: t(ar: "المعلومات الشخصية", en: "Personal Info", hi: "व्यक्तिगत जानकारी", zh: "个人信息", ku: "زانیاری کەسی"),
                    icon: "person.crop.circle.fill",
                    items: [
                        InfoTile(title: t(ar: "العمر", en: "Age", hi: "उम्र", zh: "年龄", ku: "تەمەن"), value: "\(profile.age)", tint: FootballTheme.accentCyan),
                        InfoTile(title: t(ar: "الجنسية", en: "Nationality", hi: "राष्ट्रीयता", zh: "国籍", ku: "نەتەوە"), value: profile.nationality, tint: FootballTheme.pointsYellow),
                        InfoTile(title: t(ar: "الطول", en: "Height", hi: "कद", zh: "身高", ku: "درێژی"), value: "\(profile.heightCM) cm", tint: FootballTheme.accentGreen),
                        InfoTile(title: t(ar: "الوزن", en: "Weight", hi: "वजन", zh: "体重", ku: "کێش"), value: "\(profile.weightKG) kg", tint: FootballTheme.pointsYellow),
                        InfoTile(title: t(ar: "تاريخ الميلاد", en: "Birth Date", hi: "जन्म तिथि", zh: "生日", ku: "بەرواری لەدایکبوون"), value: profile.birthDateText, tint: FootballTheme.accentCyan)
                    ]
                )

                infoSection(
                    title: t(ar: "المعلومات الفنية", en: "Technical Info", hi: "तकनीकी जानकारी", zh: "技术信息", ku: "زانیاری تەکنیکی"),
                    icon: "sportscourt.fill",
                    items: [
                        InfoTile(title: t(ar: "المركز", en: "Position", hi: "पोज़िशन", zh: "位置", ku: "پۆست"), value: entry.player.role, tint: FootballTheme.accentGreen),
                        InfoTile(title: t(ar: "التقييم العام", en: "Overall", hi: "ओवरऑल", zh: "总评", ku: "هەڵسەنگاندنی گشتی"), value: "\(profile.overall)", tint: FootballTheme.pointsYellow),
                        InfoTile(title: t(ar: "القدم المفضلة", en: "Preferred Foot", hi: "पसंदीदा पैर", zh: "惯用脚", ku: "پێی دڵخواز"), value: profile.preferredFoot, tint: FootballTheme.accentCyan),
                        InfoTile(title: t(ar: "رقم القميص", en: "Shirt Number", hi: "जर्सी नंबर", zh: "球衣号码", ku: "ژمارەی جل"), value: "#\(entry.player.number)", tint: FootballTheme.pointsYellow)
                    ]
                )

                infoSection(
                    title: t(ar: "الحالة البدنية", en: "Physical Status", hi: "शारीरिक स्थिति", zh: "身体状态", ku: "دۆخی جەستەیی"),
                    icon: "heart.circle.fill",
                    items: [
                        InfoTile(title: t(ar: "الجاهزية", en: "Readiness", hi: "तैयारी", zh: "状态", ku: "ئامادەیی"), value: "\(profile.readiness)%", tint: readinessColor(profile.readiness)),
                        InfoTile(title: t(ar: "الحالة", en: "Condition", hi: "स्थिति", zh: "状态", ku: "دۆخ"), value: profile.fitnessStatus, tint: FootballTheme.accentGreen)
                    ]
                )

                infoSection(
                    title: t(ar: "العقد / القيمة", en: "Contract / Value", hi: "अनुबंध / कीमत", zh: "合同 / 价值", ku: "گرێبەست / نرخ"),
                    icon: "briefcase.fill",
                    items: [
                        InfoTile(title: t(ar: "القيمة السوقية", en: "Market Value", hi: "मार्केट वैल्यू", zh: "市场价值", ku: "نرخی بازاڕ"), value: "$\(profile.marketValueM)M", tint: FootballTheme.pointsYellow),
                        InfoTile(title: t(ar: "مدة العقد", en: "Contract", hi: "अनुबंध अवधि", zh: "合同期限", ku: "ماوەی گرێبەست"), value: "\(profile.contractYears) \(t(ar: "سنوات", en: "years", hi: "साल", zh: "年", ku: "ساڵ"))", tint: FootballTheme.accentCyan),
                        InfoTile(title: t(ar: "ينتهي في", en: "Ends On", hi: "समाप्ति", zh: "到期日", ku: "کۆتایی لە"), value: profile.contractUntil, tint: FootballTheme.accentGreen)
                    ]
                )
            }
        }

        private func infoSection(title: String, icon: String, items: [InfoTile]) -> some View {
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 7) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(FootballTheme.accentCyan)
                    Text(title)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(items) { item in
                        infoTile(item)
                    }
                }
            }
            .padding(11)
            .background(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 17, style: .continuous)
                            .stroke(Color.white.opacity(0.13), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 5)
        }

        private func infoTile(_ item: InfoTile) -> some View {
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text(item.value)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(item.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.13), lineWidth: 1)
                    )
            )
        }

        private func readinessColor(_ percent: Int) -> Color {
            if percent >= 84 { return FootballTheme.accentGreen }
            if percent >= 72 { return FootballTheme.pointsYellow }
            return FootballTheme.dangerRed
        }
    }
}

private struct TransferCenterPremiumView: View {
    private enum PositionFilter: CaseIterable, Identifiable {
        case all
        case goalkeeper
        case defense
        case midfield
        case attack

        var id: String {
            switch self {
            case .all: return "all"
            case .goalkeeper: return "gk"
            case .defense: return "def"
            case .midfield: return "mid"
            case .attack: return "att"
            }
        }
    }

    private struct MarketPlayer: Identifiable, Hashable {
        let id: UUID
        var name: String
        var age: Int
        var position: String
        var overall: Int
        var club: String
        var league: String
        var nationality: String
        var marketValueM: Int
        var salaryK: Int
        var contractYears: Int
        var preferredFoot: String
        var heightCM: Int
        var potential: Int
        var birthDate: Date
        var isFeatured: Bool
    }

    private struct DetailRow: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let tint: Color
    }

    private let positionPattern = [
        "GK", "GK",
        "RB", "CB", "CB", "LB",
        "DM", "CM", "CM", "AM",
        "RW", "LW", "ST", "ST",
        "RM", "LM",
        "CB", "RB", "LB", "CM",
        "RW", "ST", "AM", "GK"
    ]

    let language: AppLanguage
    let selectedTeam: String?
    @Binding var budgetM: Int
    @Binding var lineup: [TeamPlayer]
    @Binding var bench: [TeamPlayer]
    let onClose: () -> Void

    @State private var marketPlayers: [MarketPlayer] = []
    @State private var searchText = ""
    @State private var selectedLeagueName = topLeagues.first?.name ?? ""
    @State private var selectedClubName = topLeagues.first?.teams.first ?? ""
    @State private var positionFilter: PositionFilter = .all
    @State private var leagueFilterName: String?
    @State private var maxAgeFilter = 40.0
    @State private var minRatingFilter = 60.0
    @State private var maxPriceFilter = 220.0
    @State private var shortlistIDs: Set<UUID> = []
    @State private var followIDs: Set<UUID> = []
    @State private var selectedPlayerForDetails: MarketPlayer?
    @State private var negotiationPlayer: MarketPlayer?
    @State private var highlightedID: UUID?
    @State private var toastMessage = ""
    @State private var showToast = false
    @State private var animateIn = false

    @Namespace private var cardNamespace

    private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
    }

    private var appLocale: Locale {
        Locale(identifier: language.localeIdentifier)
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var selectedLeague: League? {
        topLeagues.first(where: { $0.name == selectedLeagueName })
    }

    private var teamsForSelectedLeague: [String] {
        selectedLeague?.teams ?? []
    }

    private var shortlistedPlayers: [MarketPlayer] {
        marketPlayers.filter { shortlistIDs.contains($0.id) }
            .sorted { $0.overall > $1.overall }
    }

    private var visiblePlayers: [MarketPlayer] {
        let source: [MarketPlayer]
        if !trimmedSearchText.isEmpty {
            source = marketPlayers.filter { matchesSearch($0, query: trimmedSearchText) }
        } else if !selectedClubName.isEmpty {
            source = marketPlayers.filter { $0.club == selectedClubName }
        } else {
            source = marketPlayers
        }

        let filteredByLeague = source.filter { player in
            guard let leagueFilterName else { return true }
            return player.league == leagueFilterName
        }

        let filteredByPosition = filteredByLeague.filter { player in
            switch positionFilter {
            case .all:
                return true
            case .goalkeeper:
                return player.position == "GK"
            case .defense:
                return ["RB", "CB", "LB", "RWB", "LWB", "SW"].contains(player.position)
            case .midfield:
                return ["DM", "CM", "AM", "RM", "LM", "MF"].contains(player.position)
            case .attack:
                return ["RW", "LW", "ST", "CF", "SS", "FW"].contains(player.position)
            }
        }

        let filteredByAge = filteredByPosition.filter { Double($0.age) <= maxAgeFilter }
        let filteredByRating = filteredByAge.filter { Double($0.overall) >= minRatingFilter }
        let filteredByPrice = filteredByRating.filter { Double($0.marketValueM) <= maxPriceFilter }

        if trimmedSearchText.isEmpty {
            return filteredByPrice.sorted { $0.overall > $1.overall }
        }

        let normalizedQuery = normalize(trimmedSearchText)
        return filteredByPrice.sorted { lhs, rhs in
            searchScore(for: lhs, query: normalizedQuery) > searchScore(for: rhs, query: normalizedQuery)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                transferBackground

                VStack(spacing: 10) {
                    headerBar
                    searchBar
                    filtersPanel
                    leagueAndTeamSelection

                    if !shortlistedPlayers.isEmpty {
                        shortlistStrip
                    }

                    resultsHeader
                    playersList

                    if showToast {
                        toastPill
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .navigationBarHidden(true)
            .environment(\.layoutDirection, .rightToLeft)
            .navigationDestination(item: $selectedPlayerForDetails) { player in
                TransferPlayerDetailsView(
                    language: language,
                    player: player,
                    isShortlisted: shortlistIDs.contains(player.id),
                    onBack: {
                        selectedPlayerForDetails = nil
                    },
                    onNegotiate: {
                        negotiationPlayer = player
                    },
                    onToggleShortlist: {
                        toggleShortlist(player)
                    }
                )
            }
            .sheet(item: $negotiationPlayer) { player in
                TransferNegotiationSheetView(
                    language: language,
                    player: player,
                    budgetM: budgetM,
                    onSubmit: { offerM, salaryK, years, bonusM in
                        submitNegotiation(
                            player: player,
                            offerM: offerM,
                            salaryK: salaryK,
                            years: years,
                            bonusM: bonusM
                        )
                        negotiationPlayer = nil
                    },
                    onCancel: {
                        negotiationPlayer = nil
                    }
                )
            }
            .onAppear {
                if marketPlayers.isEmpty {
                    marketPlayers = buildInitialDatabase()
                }
                withAnimation(.easeOut(duration: 0.35)) {
                    animateIn = true
                }
            }
            .onChange(of: selectedLeagueName) { _, newValue in
                if let league = topLeagues.first(where: { $0.name == newValue }) {
                    selectedClubName = league.teams.first ?? ""
                }
            }
        }
    }

    private var transferBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x050918), Color(hex: 0x0D2041), Color(hex: 0x081A35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(hex: 0x47C4FF, alpha: 0.22), Color.clear],
                center: .top,
                startRadius: 14,
                endRadius: 250
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(hex: 0xAB78FF, alpha: 0.16), Color.clear],
                center: .bottomTrailing,
                startRadius: 14,
                endRadius: 230
            )
            .ignoresSafeArea()
        }
    }

    private var headerBar: some View {
        ZStack {
            VStack(spacing: 3) {
                Text("مركز الانتقالات")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(t(ar: "سوق انتقالات حي", en: "Live Transfer Market", hi: "लाइव ट्रांसफ़र मार्केट", zh: "实时转会市场", ku: "بازاڕی گواستنەوەی زیندوو"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
            }

            HStack {
                Button {
                    onClose()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .black))
                        Text(t(ar: "رجوع", en: "Back", hi: "वापस", zh: "返回", ku: "گەڕانەوە"))
                            .font(.system(size: 13, weight: .black))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.11))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
                }
                .buttonStyle(InteractivePressButtonStyle())

                Spacer()

                budgetPill
            }
        }
    }

    private var budgetPill: some View {
        HStack(spacing: 4) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 13, weight: .black))
            Text("$\(budgetM)M")
                .font(.system(size: 13, weight: .black))
        }
        .foregroundStyle(FootballTheme.pointsYellow)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.24))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(FootballTheme.accentCyan)

            TextField(
                t(
                    ar: "ابحث عن أي لاعب بالاسم...",
                    en: "Search any player by name...",
                    hi: "किसी खिलाड़ी को नाम से खोजें...",
                    zh: "按姓名搜索球员...",
                    ku: "بە ناو گەڕان بۆ هەر یاریزانێک..."
                ),
                text: $searchText
            )
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.white)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)

            if !searchText.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: FootballTheme.accentCyan.opacity(0.13), radius: 9, x: 0, y: 5)
    }

    private var filtersPanel: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Text(t(ar: "الفلاتر", en: "Filters", hi: "फ़िल्टर", zh: "筛选", ku: "فلتەر"))
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    filterChip(
                        title: t(ar: "الكل", en: "All", hi: "सभी", zh: "全部", ku: "هەموو"),
                        active: positionFilter == .all
                    ) { positionFilter = .all }
                    filterChip(
                        title: t(ar: "الحارس", en: "GK", hi: "गोलकीपर", zh: "门将", ku: "گۆڵپارێز"),
                        active: positionFilter == .goalkeeper
                    ) { positionFilter = .goalkeeper }
                    filterChip(
                        title: t(ar: "الدفاع", en: "DEF", hi: "डिफेंस", zh: "后卫", ku: "بەرگری"),
                        active: positionFilter == .defense
                    ) { positionFilter = .defense }
                    filterChip(
                        title: t(ar: "الوسط", en: "MID", hi: "मिडफ़ील्ड", zh: "中场", ku: "ناوەڕاست"),
                        active: positionFilter == .midfield
                    ) { positionFilter = .midfield }
                    filterChip(
                        title: t(ar: "الهجوم", en: "ATT", hi: "अटैक", zh: "前锋", ku: "هێرش"),
                        active: positionFilter == .attack
                    ) { positionFilter = .attack }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    filterChip(
                        title: t(ar: "كل الدوريات", en: "All Leagues", hi: "सभी लीग", zh: "所有联赛", ku: "هەموو لیگەکان"),
                        active: leagueFilterName == nil
                    ) { leagueFilterName = nil }

                    ForEach(topLeagues, id: \.name) { league in
                        filterChip(
                            title: localizedLeagueName(league.name, in: language),
                            active: leagueFilterName == league.name
                        ) {
                            leagueFilterName = league.name
                        }
                    }
                }
            }

            sliderRow(
                title: t(ar: "العمر حتى", en: "Age Up To", hi: "अधिकतम उम्र", zh: "年龄上限", ku: "تەمەنی زۆرترین"),
                valueText: "\(Int(maxAgeFilter))",
                value: $maxAgeFilter,
                range: 18...40
            )
            sliderRow(
                title: t(ar: "أدنى تقييم", en: "Min Rating", hi: "न्यूनतम रेटिंग", zh: "最低评分", ku: "کەمترین هەڵسەنگاندن"),
                valueText: "\(Int(minRatingFilter))",
                value: $minRatingFilter,
                range: 55...92
            )
            sliderRow(
                title: t(ar: "السعر حتى", en: "Price Up To", hi: "अधिकतम कीमत", zh: "价格上限", ku: "نرخ تا"),
                valueText: "$\(Int(maxPriceFilter))M",
                value: $maxPriceFilter,
                range: 5...260
            )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.13), lineWidth: 1)
                )
        )
    }

    private func filterChip(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(active ? .black : .white.opacity(0.88))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(active ? FootballTheme.pitchGreen : Color.white.opacity(0.10))
                )
        }
        .buttonStyle(InteractivePressButtonStyle())
    }

    private func sliderRow(title: String, valueText: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(valueText)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(FootballTheme.pointsYellow)
                Spacer()
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.76))
            }
            Slider(value: value, in: range, step: 1)
                .tint(FootballTheme.accentCyan)
        }
    }

    private var leagueAndTeamSelection: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Text(t(ar: "اختر الدوري", en: "Choose League", hi: "लीग चुनें", zh: "选择联赛", ku: "لیگ هەڵبژێرە"))
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(topLeagues, id: \.name) { league in
                        filterChip(
                            title: localizedLeagueName(league.name, in: language),
                            active: selectedLeagueName == league.name
                        ) {
                            withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                                selectedLeagueName = league.name
                            }
                        }
                    }
                }
            }

            HStack {
                Text(t(ar: "اختر الفريق", en: "Choose Team", hi: "टीम चुनें", zh: "选择球队", ku: "تیم هەڵبژێرە"))
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(teamsForSelectedLeague, id: \.self) { team in
                        filterChip(
                            title: localizedDisplayName(team, in: language),
                            active: selectedClubName == team
                        ) {
                            withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                                selectedClubName = team
                            }
                        }
                    }
                }
            }
        }
    }

    private var shortlistStrip: some View {
        VStack(alignment: .trailing, spacing: 7) {
            HStack {
                Text(t(ar: "القائمة المختصرة", en: "Shortlist", hi: "शॉर्टलिस्ट", zh: "候选名单", ku: "لیستی کورت"))
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(shortlistedPlayers.count)")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(FootballTheme.pointsYellow)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(shortlistedPlayers.prefix(20)) { player in
                        Button {
                            openPlayerDetails(player)
                        } label: {
                            VStack(alignment: .trailing, spacing: 3) {
                                Text(localizedDisplayName(player.name, in: language))
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text("\(player.position) • \(player.overall)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.72))
                                Text("$\(player.marketValueM)M")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(FootballTheme.pointsYellow)
                            }
                            .frame(width: 150, alignment: .trailing)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.20))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.13), lineWidth: 1)
                )
        )
    }

    private var resultsHeader: some View {
        HStack {
            Text("\(visiblePlayers.count) \(t(ar: "لاعب", en: "players", hi: "खिलाड़ी", zh: "名球员", ku: "یاریزان"))")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.white.opacity(0.74))
            Spacer()
            Text(trimmedSearchText.isEmpty
                 ? t(ar: "لاعبو الفريق المختار", en: "Selected Team Players", hi: "चुनी टीम के खिलाड़ी", zh: "所选球队球员", ku: "یاریزانانی تیمی هەڵبژێردراو")
                 : t(ar: "نتائج البحث المباشرة", en: "Live Search Results", hi: "लाइव सर्च परिणाम", zh: "实时搜索结果", ku: "ئەنجامەکانی گەڕانی ڕاستەوخۆ"))
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var playersList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(Array(visiblePlayers.enumerated()), id: \.element.id) { index, player in
                    playerCard(player)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 12)
                        .animation(
                            .spring(response: 0.36, dampingFraction: 0.84).delay(Double(index) * 0.015),
                            value: animateIn
                        )
                }
            }
            .padding(.bottom, 12)
        }
    }

    private func playerCard(_ player: MarketPlayer) -> some View {
        let isHighlighted = highlightedID == player.id

        return VStack(spacing: 8) {
            Button {
                openPlayerDetails(player)
            } label: {
                HStack(spacing: 10) {
                    ZStack(alignment: .bottom) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: player.isFeatured
                                        ? [Color(hex: 0xFFD35A), Color(hex: 0xFF9152)]
                                        : [Color(hex: 0x33D39A), Color(hex: 0x1A8F7D)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.40), lineWidth: 1)
                            )

                        Image(systemName: "person.fill")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(.white.opacity(0.95))
                            .offset(y: -3)
                    }
                    .frame(width: 58)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(localizedDisplayName(player.name, in: language))
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        HStack(spacing: 7) {
                            metaPill(player.position)
                            metaPill("\(player.age)")
                            metaPill(localizedDisplayName(player.nationality, in: language))
                            Spacer(minLength: 0)
                        }

                        HStack(spacing: 8) {
                            Text(localizedDisplayName(player.club, in: language))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white.opacity(0.78))
                                .lineLimit(1)

                            Spacer(minLength: 0)

                            Text("$\(player.marketValueM)M")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(FootballTheme.pointsYellow)
                        }
                    }

                    VStack(spacing: 2) {
                        Text("\(player.overall)")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(FootballTheme.pointsYellow)
                        Text(t(ar: "تقييم", en: "OVR", hi: "रेटिंग", zh: "评分", ku: "هەڵسەنگاندن"))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.64))
                    }
                    .frame(width: 52)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            HStack(spacing: 6) {
                actionButton(title: t(ar: "تفاوض", en: "Negotiate", hi: "बातचीत", zh: "谈判", ku: "دانوستان"), tint: FootballTheme.pitchGreen) {
                    negotiationPlayer = player
                }
                actionButton(title: t(ar: "عرض", en: "View", hi: "देखें", zh: "查看", ku: "بینین"), tint: FootballTheme.accentCyan) {
                    openPlayerDetails(player)
                }
                actionButton(
                    title: followIDs.contains(player.id)
                        ? t(ar: "متابَع", en: "Following", hi: "फॉलो", zh: "已关注", ku: "شوێنکەوت")
                        : t(ar: "متابعة", en: "Track", hi: "ट्रैक", zh: "关注", ku: "چاودێری"),
                    tint: FootballTheme.pointsYellow
                ) {
                    toggleFollow(player)
                }
                actionButton(
                    title: shortlistIDs.contains(player.id)
                        ? t(ar: "بالمختصرة", en: "Shortlisted", hi: "शॉर्टलिस्टेड", zh: "已入围", ku: "لە لیستی کورت")
                        : t(ar: "إضافة للمختصرة", en: "Shortlist", hi: "शॉर्टलिस्ट", zh: "加入候选", ku: "زیادکردن بۆ لیستی کورت"),
                    tint: Color(hex: 0xD67BFF)
                ) {
                    toggleShortlist(player)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isHighlighted
                            ? [Color(hex: 0x1D4E9A), Color(hex: 0x1A377B)]
                            : [Color.white.opacity(0.11), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(isHighlighted ? Color.white.opacity(0.88) : Color.white.opacity(0.18), lineWidth: isHighlighted ? 1.5 : 1)
        )
        .shadow(color: isHighlighted ? FootballTheme.accentCyan.opacity(0.34) : Color.black.opacity(0.17), radius: isHighlighted ? 12 : 6, x: 0, y: isHighlighted ? 9 : 4)
        .scaleEffect(isHighlighted ? 0.985 : 1)
        .matchedGeometryEffect(id: player.id.uuidString, in: cardNamespace, isSource: true)
    }

    private func metaPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(.white.opacity(0.84))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.22))
            )
    }

    private func actionButton(title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tint.opacity(0.24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(tint.opacity(0.70), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(InteractivePressButtonStyle())
    }

    private var toastPill: some View {
        Text(toastMessage)
            .font(.system(size: 12, weight: .black))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.38))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
            )
    }

    private func openPlayerDetails(_ player: MarketPlayer) {
        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
            highlightedID = player.id
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            selectedPlayerForDetails = player
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
            withAnimation(.easeOut(duration: 0.2)) {
                highlightedID = nil
            }
        }
    }

    private func toggleFollow(_ player: MarketPlayer) {
        if followIDs.contains(player.id) {
            followIDs.remove(player.id)
            presentToast(
                t(ar: "تم إلغاء متابعة اللاعب", en: "Player removed from tracking", hi: "खिलाड़ी ट्रैकिंग से हटाया गया", zh: "已取消关注球员", ku: "شوێنکەوتنی یاریزان هەڵوەشێنرایەوە")
            )
        } else {
            followIDs.insert(player.id)
            presentToast(
                t(ar: "تمت متابعة اللاعب", en: "Player added to tracking", hi: "खिलाड़ी ट्रैकिंग में जोड़ा गया", zh: "已关注该球员", ku: "یاریزانەکە شوێنکەوت کرا")
            )
        }
    }

    private func toggleShortlist(_ player: MarketPlayer) {
        if shortlistIDs.contains(player.id) {
            shortlistIDs.remove(player.id)
            presentToast(
                t(ar: "تمت إزالة اللاعب من المختصرة", en: "Removed from shortlist", hi: "शॉर्टलिस्ट से हटाया गया", zh: "已移出候选名单", ku: "لە لیستی کورت لابرا")
            )
        } else {
            shortlistIDs.insert(player.id)
            presentToast(
                t(ar: "تمت إضافة اللاعب للمختصرة", en: "Added to shortlist", hi: "शॉर्टलिस्ट में जोड़ा गया", zh: "已加入候选名单", ku: "زیادکرا بۆ لیستی کورت")
            )
        }
    }

    private func submitNegotiation(player: MarketPlayer, offerM: Int, salaryK: Int, years: Int, bonusM: Int) {
        let totalCost = offerM + bonusM
        guard totalCost <= budgetM else {
            presentToast(
                t(ar: "الميزانية لا تكفي لإرسال العرض", en: "Budget is not enough for this offer", hi: "इस ऑफर के लिए बजट पर्याप्त नहीं", zh: "预算不足，无法提交报价", ku: "بودجە بۆ ئەم پێشنیارە بەس نییە")
            )
            return
        }

        guard let index = marketPlayers.firstIndex(where: { $0.id == player.id }) else { return }

        budgetM -= totalCost

        let destinationClub = selectedTeam ?? t(ar: "فريقي", en: "My Club", hi: "मेरी टीम", zh: "我的球队", ku: "تیمی من")
        let destinationLeague = leagueName(for: destinationClub) ?? marketPlayers[index].league

        marketPlayers[index].club = destinationClub
        marketPlayers[index].league = destinationLeague
        marketPlayers[index].salaryK = salaryK
        marketPlayers[index].contractYears = years
        marketPlayers[index].marketValueM = max(marketPlayers[index].marketValueM, offerM)

        addSignedPlayerToMyTeam(marketPlayers[index])

        presentToast(
            t(ar: "تم التعاقد بنجاح مع \(marketPlayers[index].name)", en: "Successfully signed \(marketPlayers[index].name)", hi: "\(marketPlayers[index].name) के साथ सफलतापूर्वक अनुबंध", zh: "已成功签下\(marketPlayers[index].name)", ku: "بە سەرکەوتوویی واژۆ لەگەڵ \(marketPlayers[index].name)")
        )
    }

    private func addSignedPlayerToMyTeam(_ player: MarketPlayer) {
        if lineup.contains(where: { $0.name == player.name }) || bench.contains(where: { $0.name == player.name }) {
            return
        }

        let number = nextAvailableShirtNumber()
        let signed = TeamPlayer(name: player.name, role: player.position, number: number)

        if bench.count < 12 {
            bench.append(signed)
        } else if !bench.isEmpty {
            bench[bench.count - 1] = signed
        } else if lineup.count < 11 {
            lineup.append(signed)
        }
    }

    private func nextAvailableShirtNumber() -> Int {
        let used = Set((lineup + bench).map(\.number))
        for number in 1...99 where !used.contains(number) {
            return number
        }
        return Int.random(in: 1...99)
    }

    private func leagueName(for teamName: String) -> String? {
        topLeagues.first(where: { $0.teams.contains(teamName) })?.name
    }

    private func presentToast(_ message: String) {
        toastMessage = message
        withAnimation(.easeInOut(duration: 0.2)) {
            showToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showToast = false
            }
        }
    }

    private func normalize(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: appLocale)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func matchesSearch(_ player: MarketPlayer, query: String) -> Bool {
        let q = normalize(query)
        guard !q.isEmpty else { return true }
        let fullName = normalize(player.name)
        let clubName = normalize(player.club)
        let nationality = normalize(player.nationality)
        return fullName.contains(q) || clubName.contains(q) || nationality.contains(q)
    }

    private func searchScore(for player: MarketPlayer, query: String) -> Int {
        let name = normalize(player.name)
        let club = normalize(player.club)
        var score = player.overall

        if name == query { score += 300 }
        if name.hasPrefix(query) { score += 120 }
        if name.contains(query) { score += 70 }
        if club.contains(query) { score += 40 }
        if player.isFeatured { score += 24 }
        return score
    }

    private func buildInitialDatabase() -> [MarketPlayer] {
        let firstNames = [
            "آدم", "إياد", "سامي", "كريم", "يوسف", "نادر", "لؤي", "مالك", "خالد", "رامي",
            "ناصر", "وليد", "مروان", "فارس", "زياد", "حاتم", "عمر", "تيم", "سيف", "مازن",
            "هيثم", "علي", "محمود", "ياسر", "تميم", "معتز", "صالح", "باسل", "هاني", "نوح"
        ]
        let lastNames = [
            "الحربي", "الزهراني", "العمري", "السعيد", "الشمري", "المالكي", "الأنصاري", "الدوسري", "الزعبي", "الخطيب",
            "المنصوري", "القحطاني", "الغامدي", "الحسيني", "العبيدي", "الرفاعي", "النجار", "الجعفري", "البكري", "اليوسفي",
            "بن سالم", "الحداد", "الكعبي", "السامرائي", "النعيمي", "الطائي", "العتيبي", "المطيري", "الجبوري", "الخالدي"
        ]
        let nationalities = [
            "إسبانيا", "فرنسا", "الأرجنتين", "البرازيل", "البرتغال", "إنجلترا", "إيطاليا", "ألمانيا",
            "بلجيكا", "هولندا", "كرواتيا", "المغرب", "الجزائر", "مصر", "تونس", "السنغال", "النرويج", "أوروجواي"
        ]

        let featuredByTeam: [String: [(name: String, pos: String, ovr: Int, age: Int, nation: String, value: Int)]] = [
            "مانشستر سيتي": [("إيرلينغ هالاند", "ST", 91, 25, "النرويج", 185), ("رودري", "DM", 90, 29, "إسبانيا", 130), ("كيفين دي بروين", "CM", 89, 34, "بلجيكا", 75)],
            "ليفربول": [("محمد صلاح", "RW", 90, 34, "مصر", 100), ("فيرجيل فان دايك", "CB", 88, 35, "هولندا", 65)],
            "أرسنال": [("بوكايو ساكا", "RW", 88, 25, "إنجلترا", 125), ("مارتن أوديغارد", "AM", 88, 27, "النرويج", 110)],
            "أتلتيكو مدريد": [
                ("Jan Oblak", "GK", 88, 33, "سلوفينيا", 52),
                ("Juan Musso", "GK", 81, 32, "الأرجنتين", 22),
                ("Jose Maria Gimenez", "CB", 85, 31, "أوروغواي", 64),
                ("Robin Le Normand", "CB", 84, 30, "إسبانيا", 56),
                ("Clement Lenglet", "CB", 82, 31, "فرنسا", 30),
                ("Nahuel Molina", "RB", 83, 28, "الأرجنتين", 44),
                ("Matteo Ruggeri", "LB", 80, 24, "إيطاليا", 30),
                ("Marcos Llorente", "RB", 84, 31, "إسبانيا", 46),
                ("David Hancko", "CB", 82, 29, "سلوفاكيا", 34),
                ("Marc Pubill", "RB", 78, 23, "إسبانيا", 18),
                ("Johnny Cardoso", "DM", 83, 25, "الولايات المتحدة", 52),
                ("Koke", "CM", 83, 34, "إسبانيا", 20),
                ("Pablo Barrios", "CM", 82, 23, "إسبانيا", 44),
                ("Rodrigo Mendoza", "CM", 74, 20, "إسبانيا", 9),
                ("Obed Vargas", "CM", 78, 21, "المكسيك", 16),
                ("Ademola Lookman", "SS", 85, 29, "نيجيريا", 72),
                ("Antoine Griezmann", "SS", 87, 35, "فرنسا", 48),
                ("Alexander Sorloth", "ST", 83, 31, "النرويج", 34),
                ("Alex Baena", "LW", 84, 25, "إسبانيا", 50),
                ("Thiago Almada", "AM", 83, 25, "الأرجنتين", 46),
                ("Julian Alvarez", "ST", 88, 27, "الأرجنتين", 126),
                ("Giuliano Simeone", "RW", 80, 24, "الأرجنتين", 26),
                ("Nico Gonzalez", "RW", 82, 28, "الأرجنتين", 36)
            ],
            "ريال مدريد": [
                ("Thibaut Courtois", "GK", 89, 33, "بلجيكا", 45),
                ("Andriy Lunin", "GK", 82, 27, "أوكرانيا", 28),
                ("Dani Carvajal", "RB", 84, 33, "إسبانيا", 35),
                ("Eder Militao", "CB", 85, 28, "البرازيل", 72),
                ("David Alaba", "CB", 83, 34, "النمسا", 30),
                ("Trent Alexander-Arnold", "RB", 88, 28, "إنجلترا", 92),
                ("Raul Asencio", "CB", 78, 22, "إسبانيا", 20),
                ("Alvaro Carreras", "LB", 79, 23, "إسبانيا", 24),
                ("Fran Garcia", "LB", 81, 26, "إسبانيا", 32),
                ("Antonio Rudiger", "CB", 88, 33, "ألمانيا", 52),
                ("Ferland Mendy", "LB", 83, 31, "فرنسا", 38),
                ("Dean Huijsen", "CB", 83, 21, "إسبانيا", 58),
                ("Jude Bellingham", "AM", 90, 23, "إنجلترا", 175),
                ("Eduardo Camavinga", "CM", 86, 24, "فرنسا", 95),
                ("Federico Valverde", "CM", 89, 28, "أوروغواي", 130),
                ("Aurelien Tchouameni", "DM", 87, 26, "فرنسا", 110),
                ("Arda Guler", "AM", 84, 21, "تركيا", 66),
                ("Dani Ceballos", "CM", 81, 30, "إسبانيا", 30),
                ("Thiago Pitarch", "CM", 72, 20, "إسبانيا", 8),
                ("Vinicius Junior", "LW", 91, 26, "البرازيل", 180),
                ("Kylian Mbappe", "ST", 92, 27, "فرنسا", 210),
                ("Rodrygo", "RW", 87, 26, "البرازيل", 115),
                ("Gonzalo Garcia", "ST", 79, 22, "إسبانيا", 18),
                ("Brahim Diaz", "RW", 84, 27, "المغرب", 58),
                ("Franco Mastantuono", "RW", 82, 19, "الأرجنتين", 70)
            ],
            "برشلونة": [
                ("Robert Lewandowski", "ST", 89, 37, "بولندا", 52),
                ("Lamine Yamal", "RW", 88, 19, "إسبانيا", 132),
                ("Raphinha", "LW", 87, 30, "البرازيل", 92),
                ("Ferran Torres", "ST", 84, 27, "إسبانيا", 55),
                ("Marcus Rashford", "LW", 86, 29, "إنجلترا", 78),
                ("Rooney Bardghji", "RW", 79, 21, "السويد", 26),
                ("Pedri", "CM", 88, 23, "إسبانيا", 115),
                ("Gavi", "CM", 86, 22, "إسبانيا", 98),
                ("Frenkie de Jong", "CM", 87, 29, "هولندا", 88),
                ("Fermin Lopez", "AM", 83, 23, "إسبانيا", 52),
                ("Dani Olmo", "AM", 85, 28, "إسبانيا", 66),
                ("Marc Casado", "DM", 82, 23, "إسبانيا", 42),
                ("Marc Bernal", "DM", 78, 19, "إسبانيا", 22),
                ("Joao Cancelo", "RB", 85, 32, "البرتغال", 64),
                ("Alejandro Balde", "LB", 84, 23, "إسبانيا", 62),
                ("Ronald Araujo", "CB", 87, 28, "أوروغواي", 95),
                ("Pau Cubarsi", "CB", 84, 20, "إسبانيا", 70),
                ("Andreas Christensen", "CB", 84, 30, "الدنمارك", 52),
                ("Gerard Martin", "LB", 77, 24, "إسبانيا", 18),
                ("Jules Kounde", "RB", 86, 28, "فرنسا", 82),
                ("Eric Garcia", "CB", 81, 25, "إسبانيا", 35),
                ("Xavi Espart", "RB", 72, 20, "إسبانيا", 8),
                ("Joan Garcia", "GK", 82, 25, "إسبانيا", 30),
                ("Wojciech Szczesny", "GK", 84, 36, "بولندا", 22)
            ],
            "بايرن ميونخ": [("هاري كين", "ST", 90, 33, "إنجلترا", 110), ("جمال موسيالا", "AM", 88, 24, "ألمانيا", 130)],
            "باريس سان جيرمان": [("عثمان ديمبيلي", "RW", 87, 29, "فرنسا", 95), ("أشرف حكيمي", "RB", 86, 28, "المغرب", 90)],
            "إنتر ميلان": [("لاوتارو مارتينيز", "ST", 88, 29, "الأرجنتين", 115)],
            "يوفنتوس": [("دوشان فلاهوفيتش", "ST", 84, 27, "صربيا", 78)],
            "ميلان": [("رافاييل لياو", "LW", 86, 27, "البرتغال", 96)],
            "نابولي": [("فيكتور أوسيمين", "ST", 87, 28, "نيجيريا", 110)]
        ]

        var output: [MarketPlayer] = []

        for (leagueIndex, league) in topLeagues.enumerated() {
            for (teamIndex, teamName) in league.teams.enumerated() {
                var teamOutput: [MarketPlayer] = []
                var usedNames: Set<String> = []

                if let featured = featuredByTeam[teamName] {
                    for featuredPlayer in featured {
                        let month = (featuredPlayer.ovr % 12) + 1
                        let day = (featuredPlayer.ovr % 27) + 1
                        let year = Calendar.current.component(.year, from: Date()) - featuredPlayer.age
                        let birthDate = Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
                        let salaryK = max(2200, featuredPlayer.value * 32)
                        let contractYears = max(1, 5 - (featuredPlayer.age - 24) / 4)

                        teamOutput.append(
                            MarketPlayer(
                                id: UUID(),
                                name: featuredPlayer.name,
                                age: featuredPlayer.age,
                                position: featuredPlayer.pos,
                                overall: featuredPlayer.ovr,
                                club: teamName,
                                league: league.name,
                                nationality: featuredPlayer.nation,
                                marketValueM: featuredPlayer.value,
                                salaryK: salaryK,
                                contractYears: contractYears,
                                preferredFoot: featuredPlayer.pos == "RW" ? "اليسرى" : "اليمنى",
                                heightCM: featuredPlayer.pos == "GK" ? 191 : 178 + (featuredPlayer.ovr % 13),
                                potential: min(95, featuredPlayer.ovr + max(1, 7 - max(featuredPlayer.age - 21, 0) / 2)),
                                birthDate: birthDate,
                                isFeatured: true
                            )
                        )
                        usedNames.insert(featuredPlayer.name)
                    }
                }

                var idx = 0
                while teamOutput.count < 24 {
                    let seed = stableSeed(teamName: teamName, leagueIndex: leagueIndex, teamIndex: teamIndex, playerIndex: idx)
                    let position = positionPattern[idx % positionPattern.count]
                    let roleBase = baseRating(for: position)
                    let clubBoost = max(0, 10 - teamIndex / 2)
                    let rating = clamp(roleBase + clubBoost + (seed % 11) - 5, min: 60, max: 89)
                    let age = 17 + (seed % 17)
                    let potential = clamp(rating + 3 + (seed % 8), min: rating + 1, max: 94)
                    let nationality = nationalities[seed % nationalities.count]
                    let height = playerHeight(for: position, seed: seed)
                    let foot = preferredFoot(seed: seed)
                    let marketValue = clamp((rating - 52) * 3 + (potential - rating) + max(0, 28 - age), min: 2, max: 150)
                    let salaryK = clamp((marketValue * 25) + (rating * 11), min: 450, max: 12000)
                    let contractYears = 1 + (seed % 5)
                    let month = (seed % 12) + 1
                    let day = (seed % 27) + 1
                    let year = Calendar.current.component(.year, from: Date()) - age
                    let birthDate = Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()

                    var generatedName = "\(firstNames[seed % firstNames.count]) \(lastNames[(seed / 5) % lastNames.count])"
                    if usedNames.contains(generatedName) {
                        generatedName += " \(idx + 1)"
                    }
                    usedNames.insert(generatedName)

                    teamOutput.append(
                        MarketPlayer(
                            id: UUID(),
                            name: generatedName,
                            age: age,
                            position: position,
                            overall: rating,
                            club: teamName,
                            league: league.name,
                            nationality: nationality,
                            marketValueM: marketValue,
                            salaryK: salaryK,
                            contractYears: contractYears,
                            preferredFoot: foot,
                            heightCM: height,
                            potential: potential,
                            birthDate: birthDate,
                            isFeatured: false
                        )
                    )

                    idx += 1
                }

                output.append(contentsOf: teamOutput)
            }
        }

        return output
    }

    private func stableSeed(teamName: String, leagueIndex: Int, teamIndex: Int, playerIndex: Int) -> Int {
        let value = teamName.unicodeScalars.reduce(0) { partial, scalar in
            partial + Int(scalar.value)
        }
        return value + leagueIndex * 919 + teamIndex * 173 + playerIndex * 97
    }

    private func baseRating(for position: String) -> Int {
        switch position {
        case "GK": return 70
        case "CB": return 72
        case "RB", "LB": return 71
        case "DM": return 73
        case "CM": return 72
        case "AM": return 74
        case "RW", "LW": return 74
        case "ST": return 75
        case "RM", "LM": return 71
        default: return 70
        }
    }

    private func playerHeight(for position: String, seed: Int) -> Int {
        switch position {
        case "GK":
            return 186 + (seed % 11)
        case "CB", "ST":
            return 180 + (seed % 14)
        case "RB", "LB", "DM":
            return 173 + (seed % 13)
        default:
            return 169 + (seed % 12)
        }
    }

    private func preferredFoot(seed: Int) -> String {
        if seed % 8 == 0 {
            return "كلتا القدمين"
        }
        return seed % 2 == 0 ? "اليمنى" : "اليسرى"
    }

    private func clamp(_ value: Int, min: Int, max: Int) -> Int {
        Swift.max(min, Swift.min(max, value))
    }

    private struct TransferPlayerDetailsView: View {
        let language: AppLanguage
        let player: MarketPlayer
        let isShortlisted: Bool
        let onBack: () -> Void
        let onNegotiate: () -> Void
        let onToggleShortlist: () -> Void

        private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
            language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
        }

        private var appLocale: Locale {
            Locale(identifier: language.localeIdentifier)
        }

        var body: some View {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0x050916), Color(hex: 0x121E45), Color(hex: 0x081632)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        topBar
                        heroCard
                        infoSection(
                            title: t(ar: "المعلومات الشخصية", en: "Personal", hi: "व्यक्तिगत", zh: "个人信息", ku: "کەسی"),
                            icon: "person.crop.circle.fill",
                            rows: [
                                DetailRow(title: t(ar: "العمر", en: "Age", hi: "उम्र", zh: "年龄", ku: "تەمەن"), value: "\(player.age)", tint: FootballTheme.accentCyan),
                                DetailRow(title: t(ar: "الجنسية", en: "Nationality", hi: "राष्ट्रीयता", zh: "国籍", ku: "نەتەوە"), value: localizedDisplayName(player.nationality, in: language), tint: FootballTheme.pointsYellow),
                                DetailRow(title: t(ar: "تاريخ الميلاد", en: "Birth Date", hi: "जन्म तिथि", zh: "出生日期", ku: "بەرواری لەدایکبوون"), value: birthDateText, tint: FootballTheme.accentGreen),
                                DetailRow(title: t(ar: "الطول", en: "Height", hi: "कद", zh: "身高", ku: "درێژی"), value: "\(player.heightCM) cm", tint: FootballTheme.accentCyan)
                            ]
                        )
                        infoSection(
                            title: t(ar: "المعلومات الفنية", en: "Technical", hi: "तकनीकी", zh: "技术信息", ku: "تەکنیکی"),
                            icon: "sportscourt.fill",
                            rows: [
                                DetailRow(title: t(ar: "المركز", en: "Position", hi: "पोज़िशन", zh: "位置", ku: "پۆست"), value: player.position, tint: FootballTheme.accentGreen),
                                DetailRow(title: t(ar: "التقييم", en: "Overall", hi: "रेटिंग", zh: "评分", ku: "هەڵسەنگاندن"), value: "\(player.overall)", tint: FootballTheme.pointsYellow),
                                DetailRow(title: t(ar: "الإمكانيات", en: "Potential", hi: "पोटेंशियल", zh: "潜力", ku: "توانا"), value: "\(player.potential)", tint: FootballTheme.accentCyan),
                                DetailRow(title: t(ar: "القدم المفضلة", en: "Preferred Foot", hi: "पसंदीदा पैर", zh: "惯用脚", ku: "پێی دڵخواز"), value: player.preferredFoot, tint: FootballTheme.accentGreen)
                            ]
                        )
                        infoSection(
                            title: t(ar: "العقد / القيمة", en: "Contract / Value", hi: "अनुबंध / मूल्य", zh: "合同 / 价值", ku: "گرێبەست / نرخ"),
                            icon: "briefcase.fill",
                            rows: [
                                DetailRow(title: t(ar: "النادي الحالي", en: "Current Club", hi: "वर्तमान क्लब", zh: "当前俱乐部", ku: "تیمی ئێستا"), value: localizedDisplayName(player.club, in: language), tint: FootballTheme.accentCyan),
                                DetailRow(title: t(ar: "الراتب", en: "Salary", hi: "वेतन", zh: "薪资", ku: "مووچە"), value: "$\(player.salaryK)K", tint: FootballTheme.pointsYellow),
                                DetailRow(title: t(ar: "القيمة السوقية", en: "Market Value", hi: "मार्केट वैल्यू", zh: "市场价值", ku: "نرخی بازاڕ"), value: "$\(player.marketValueM)M", tint: FootballTheme.accentGreen),
                                DetailRow(title: t(ar: "مدة العقد", en: "Contract", hi: "अनुबंध", zh: "合同期限", ku: "ماوەی گرێبەست"), value: "\(player.contractYears) \(t(ar: "سنوات", en: "years", hi: "साल", zh: "年", ku: "ساڵ"))", tint: FootballTheme.pointsYellow)
                            ]
                        )

                        VStack(spacing: 8) {
                            Button(action: onNegotiate) {
                                HStack(spacing: 7) {
                                    Image(systemName: "signature")
                                        .font(.system(size: 14, weight: .black))
                                    Text(t(ar: "بدء التفاوض والتعاقد", en: "Start Negotiation", hi: "बातचीत शुरू करें", zh: "开始谈判", ku: "دەستپێکردنی دانوستان"))
                                        .font(.system(size: 15, weight: .black))
                                }
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(FootballTheme.pitchGreen)
                                )
                            }
                            .buttonStyle(InteractivePressButtonStyle())

                            Button(action: onToggleShortlist) {
                                Text(
                                    isShortlisted
                                        ? t(ar: "إزالة من القائمة المختصرة", en: "Remove from Shortlist", hi: "शॉर्टलिस्ट से हटाएँ", zh: "移出候选名单", ku: "لابردن لە لیستی کورت")
                                        : t(ar: "إضافة إلى القائمة المختصرة", en: "Add to Shortlist", hi: "शॉर्टलिस्ट में जोड़ें", zh: "加入候选名单", ku: "زیادکردن بۆ لیستی کورت")
                                )
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                                        .fill(Color.white.opacity(0.10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                                .stroke(Color.white.opacity(0.16), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(InteractivePressButtonStyle())
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 14)
                }
            }
            .navigationBarBackButtonHidden(true)
            .environment(\.layoutDirection, .rightToLeft)
        }

        private var topBar: some View {
            HStack {
                Button {
                    onBack()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .black))
                        Text(t(ar: "السوق", en: "Market", hi: "मार्केट", zh: "市场", ku: "بازاڕ"))
                            .font(.system(size: 13, weight: .black))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(Color.white.opacity(0.11))
                    )
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
                }
                .buttonStyle(InteractivePressButtonStyle())

                Spacer()

                Text(t(ar: "تفاصيل اللاعب", en: "Player Details", hi: "खिलाड़ी विवरण", zh: "球员详情", ku: "وردەکاری یاریزان"))
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
        }

        private var heroCard: some View {
            VStack(spacing: 9) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0x2647A1), Color(hex: 0x2E78D5), Color(hex: 0x1A2A76)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.20), lineWidth: 1)
                        )

                    HStack(spacing: 6) {
                        Text(player.position)
                        Text("OVR \(player.overall)")
                    }
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.black.opacity(0.24)))
                    .padding(12)

                    VStack(spacing: 8) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.94), Color.white.opacity(0.66)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 116, height: 116)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 52, weight: .black))
                                    .foregroundStyle(Color(hex: 0x1E4E97))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.42), lineWidth: 1)
                            )

                        Text(localizedDisplayName(player.name, in: language))
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Text("\(localizedDisplayName(player.club, in: language)) • \(localizedDisplayName(player.nationality, in: language))")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.76))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .padding(.vertical, 18)
                }
                .frame(height: 298)
                .shadow(color: FootballTheme.accentCyan.opacity(0.26), radius: 16, x: 0, y: 8)
            }
        }

        private var birthDateText: String {
            let formatter = DateFormatter()
            formatter.locale = appLocale
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: player.birthDate)
        }

        private func infoSection(title: String, icon: String, rows: [DetailRow]) -> some View {
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 7) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(FootballTheme.accentCyan)
                    Text(title)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(rows) { row in
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(row.title)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white.opacity(0.68))
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            Text(row.value)
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(row.tint)
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.black.opacity(0.20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.13), lineWidth: 1)
                                )
                        )
                    }
                }
            }
            .padding(11)
            .background(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 17, style: .continuous)
                            .stroke(Color.white.opacity(0.13), lineWidth: 1)
                    )
            )
        }
    }

    private struct TransferNegotiationSheetView: View {
        let language: AppLanguage
        let player: MarketPlayer
        let budgetM: Int
        let onSubmit: (_ offerM: Int, _ salaryK: Int, _ years: Int, _ bonusM: Int) -> Void
        let onCancel: () -> Void

        @State private var offerValueText: String
        @State private var salaryText: String
        @State private var yearsText: String
        @State private var bonusText: String

        init(
            language: AppLanguage,
            player: MarketPlayer,
            budgetM: Int,
            onSubmit: @escaping (_ offerM: Int, _ salaryK: Int, _ years: Int, _ bonusM: Int) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.language = language
            self.player = player
            self.budgetM = budgetM
            self.onSubmit = onSubmit
            self.onCancel = onCancel
            _offerValueText = State(initialValue: "\(max(player.marketValueM, 3))")
            _salaryText = State(initialValue: "\(max(player.salaryK, 400))")
            _yearsText = State(initialValue: "\(max(player.contractYears, 2))")
            _bonusText = State(initialValue: "\(max(player.marketValueM / 10, 1))")
        }

        private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
            language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
        }

        var body: some View {
            NavigationStack {
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: 0x08122B), Color(hex: 0x102246), Color(hex: 0x0A1733)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    VStack(alignment: .trailing, spacing: 12) {
                        HStack {
                            Button {
                                onCancel()
                            } label: {
                                Text(t(ar: "إلغاء", en: "Cancel", hi: "रद्द", zh: "取消", ku: "هەڵوەشاندنەوە"))
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundStyle(.white.opacity(0.84))
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Text(t(ar: "نافذة التفاوض", en: "Negotiation", hi: "बातचीत", zh: "谈判", ku: "دانوستان"))
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        Text(localizedDisplayName(player.name, in: language))
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        Text("\(t(ar: "الميزانية المتاحة", en: "Available Budget", hi: "उपलब्ध बजट", zh: "可用预算", ku: "بودجەی بەردەست")): $\(budgetM)M")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(FootballTheme.pointsYellow)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        inputRow(title: t(ar: "قيمة العرض (مليون)", en: "Offer Value (M)", hi: "ऑफ़र राशि (M)", zh: "报价（百万）", ku: "نرخی پێشنیار (م)") , text: $offerValueText)
                        inputRow(title: t(ar: "الراتب السنوي (ألف)", en: "Annual Salary (K)", hi: "वार्षिक वेतन (K)", zh: "年薪（千）", ku: "مووچەی ساڵانە (هەزار)") , text: $salaryText)
                        inputRow(title: t(ar: "مدة العقد (سنوات)", en: "Contract Years", hi: "अनुबंध वर्ष", zh: "合同年限", ku: "ماوەی گرێبەست (ساڵ)") , text: $yearsText)
                        inputRow(title: t(ar: "مكافأة التوقيع (مليون)", en: "Signing Bonus (M)", hi: "साइनिंग बोनस (M)", zh: "签字费（百万）", ku: "خەڵاتی واژۆ (م)") , text: $bonusText)

                        Button {
                            submitOffer()
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 13, weight: .black))
                                Text(t(ar: "إرسال العرض", en: "Send Offer", hi: "ऑफ़र भेजें", zh: "发送报价", ku: "ناردنی پێشنیار"))
                                    .font(.system(size: 15, weight: .black))
                            }
                            .foregroundStyle(.black.opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(FootballTheme.pitchGreen)
                            )
                        }
                        .buttonStyle(InteractivePressButtonStyle())

                        Spacer(minLength: 0)
                    }
                    .padding(16)
                }
                .environment(\.layoutDirection, .rightToLeft)
                .navigationBarHidden(true)
            }
        }

        private func inputRow(title: String, text: Binding<String>) -> some View {
            VStack(alignment: .trailing, spacing: 5) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(maxWidth: .infinity, alignment: .trailing)

                TextField("", text: text)
                    .font(.system(size: 15, weight: .black))
                    .keyboardType(.numberPad)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
                            )
                    )
                    .foregroundStyle(.white)
            }
        }

        private func submitOffer() {
            let offer = Int(offerValueText.filter(\.isNumber)) ?? max(player.marketValueM, 3)
            let salary = Int(salaryText.filter(\.isNumber)) ?? max(player.salaryK, 400)
            let years = max(1, Int(yearsText.filter(\.isNumber)) ?? 3)
            let bonus = Int(bonusText.filter(\.isNumber)) ?? max(player.marketValueM / 10, 1)
            onSubmit(offer, salary, years, bonus)
        }
    }
}

private struct NewsCard: View {
    let title: String
    let headline: String
    let summary: String
    let timeText: String
    let selectedTeam: String?
    let compact: Bool
    let onTap: () -> Void

    var body: some View {
        let titleFont: CGFloat = compact ? 20 : 23
        let imageHeight: CGFloat = compact ? 96 : 138
        let outerPadding: CGFloat = compact ? 12 : 16

        Button(action: onTap) {
            VStack(alignment: .leading, spacing: compact ? 9 : 12) {
                HStack {
                    Text(title)
                        .font(.system(size: titleFont, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.left")
                        .font(.system(size: compact ? 13 : 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0x214094), Color(hex: 0x171E5D)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    HStack {
                        VStack(alignment: .leading, spacing: compact ? 4 : 6) {
                            Image(systemName: "newspaper.fill")
                                .font(.system(size: compact ? 19 : 24, weight: .black))
                                .foregroundStyle(FootballTheme.pitchGreen.opacity(0.95))
                            Text(headline)
                                .font(.system(size: compact ? 16 : 18, weight: .heavy))
                                .foregroundStyle(.white)
                                .lineLimit(compact ? 1 : 2)
                                .minimumScaleFactor(0.82)
                        }
                        Spacer(minLength: 8)
                        if let selectedTeam {
                            TeamLogoView(teamName: selectedTeam, size: compact ? 44 : 54)
                                .frame(width: compact ? 54 : 66, height: compact ? 54 : 66)
                                .background(Circle().fill(Color.white.opacity(0.22)))
                        } else {
                            Image(systemName: "photo.fill")
                                .font(.system(size: compact ? 22 : 28, weight: .bold))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }
                    .padding(compact ? 11 : 14)
                }
                .frame(height: imageHeight)

                Text(summary)
                    .font(.system(size: compact ? 14 : 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.84))
                    .lineLimit(compact ? 1 : 3)
                    .minimumScaleFactor(0.86)

                if !compact {
                    Text(timeText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.64))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(outerPadding)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(FootballTheme.cardBase.opacity(0.76))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(FootballTheme.textSecondary.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.24), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(InteractivePressButtonStyle())
    }
}

private struct MonthlyNewsView: View {
    let language: AppLanguage
    let monthTitle: String
    let items: [ClubNewsItem]
    let onClose: () -> Void
    @State private var appeared = false

    private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [FootballTheme.backgroundPrimary, FootballTheme.cardBase, FootballTheme.backgroundSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("\(t(ar: "ملخص شهر", en: "Month Overview", hi: "महीने का सार", zh: "月度概览", ku: "پوختەی مانگ")): \(monthTitle)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.78))

                        if items.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(t(ar: "لا توجد أخبار كثيرة هذا الشهر حتى الآن", en: "There are not many news updates this month yet", hi: "इस महीने अभी ज्यादा समाचार अपडेट नहीं हैं", zh: "本月目前没有太多新闻更新", ku: "هێشتا ئەم مانگە هەواڵی زۆر نییە"))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white)
                                Text(t(ar: "تابع المحاكاة والمباريات لإضافة أخبار جديدة تلقائيًا.", en: "Keep simulating and playing matches to generate new updates.", hi: "नए अपडेट्स के लिए सिमुलेशन और मैच जारी रखें।", zh: "继续模拟与比赛将自动生成新动态。", ku: "بەردەوام بە لە شبیه‌کردن و یاری بۆ دروستبوونی نوێکارییە نوێکان."))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.74))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(FootballTheme.cardBase.opacity(0.72))
                            )
                        } else {
                            if items.count < 3 {
                                Text(t(ar: "لا توجد أخبار كثيرة هذا الشهر حتى الآن", en: "There are not many updates this month yet", hi: "इस महीने अभी अपडेट्स कम हैं", zh: "本月更新仍然较少", ku: "هێشتا ئەم مانگە نوێکارییەکان کەمە"))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.76))
                                    .padding(.horizontal, 2)
                            }
                            ForEach(items) { item in
                                MonthlyNewsRow(item: item, language: language)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 20)
                }
            }
            .offset(x: appeared ? 0 : 62)
            .opacity(appeared ? 1 : 0.98)
            .onAppear {
                withAnimation(.easeOut(duration: 0.24)) {
                    appeared = true
                }
            }
            .navigationTitle(t(ar: "أهم أخبار الشهر", en: "Top News of the Month", hi: "महीने की प्रमुख खबरें", zh: "本月重点新闻", ku: "گرنگترین هەواڵەکانی مانگ"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            appeared = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            onClose()
                        }
                    } label: {
                        Label(t(ar: "رجوع", en: "Back", hi: "वापस", zh: "返回", ku: "گەڕانەوە"), systemImage: "chevron.backward")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(InteractivePressButtonStyle())
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

private struct MonthlyNewsRow: View {
    let item: ClubNewsItem
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(FootballTheme.pitchGreen)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.11))
                    )

                Text(item.title)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }

            Text(item.summary)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.82))
                .lineLimit(3)

            Text(timestamp(for: item.date))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.63))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(FootballTheme.cardBase.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
    }

    private func timestamp(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.localeIdentifier)
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct BottomNavBar: View {
    let language: AppLanguage
    @Binding var currentTab: DashboardTab

    private let tabs: [DashboardTab] = [.simulator, .team, .management]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(tabs, id: \.self) { tab in
                let isActive = currentTab == tab
                Button {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
                        currentTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 19, weight: .bold))
                            .scaleEffect(isActive ? 1.18 : 1.0)
                        Text(tab.title(in: language))
                            .font(.system(size: 13, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Capsule()
                            .fill(FootballTheme.pitchGreen)
                            .frame(width: isActive ? 24 : 8, height: 4)
                            .opacity(isActive ? 1 : 0.0)
                    }
                    .foregroundStyle(isActive ? .black : .white.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                isActive
                                ? LinearGradient(colors: [FootballTheme.pitchGreen, FootballTheme.accentGreen], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [FootballTheme.backgroundPrimary.opacity(0.70), FootballTheme.backgroundPrimary.opacity(0.64)], startPoint: .top, endPoint: .bottom)
                            )
                    )
                    .shadow(color: isActive ? FootballTheme.pitchGreen.opacity(0.42) : .clear, radius: 10, x: 0, y: 4)
                }
                .buttonStyle(InteractivePressButtonStyle())
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.80), value: currentTab)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(FootballTheme.backgroundPrimary.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.30), radius: 10, x: 0, y: 6)
    }
}

private struct MoneyStickerView: View {
    let amount: Int
    @State private var glide = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 18, weight: .black))
            Text("$\(amount)M")
                .font(.system(size: 16, weight: .black))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [FootballTheme.pitchGreen, FootballTheme.accentGreen],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .shadow(color: FootballTheme.pitchGreen.opacity(0.6), radius: 10, x: 0, y: 5)
        .offset(x: glide ? 4 : -4)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                glide = true
            }
        }
    }
}

private struct FilesPanelView: View {
    @Environment(\.dismiss) private var dismiss

    let language: AppLanguage
    @Binding var downloadClubLogosEnabled: Bool

    private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [FootballTheme.backgroundPrimary, FootballTheme.backgroundSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Circle()
                    .fill(FootballTheme.accentCyan.opacity(0.14))
                    .frame(width: 250, height: 250)
                    .blur(radius: 10)
                    .offset(x: 130, y: -240)

                Circle()
                    .fill(FootballTheme.cardGlow.opacity(0.13))
                    .frame(width: 220, height: 220)
                    .blur(radius: 12)
                    .offset(x: -120, y: 250)

                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(t(ar: "الملفات", en: "Files", hi: "फ़ाइलें", zh: "文件", ku: "پەڕگەکان"))
                                .font(.system(size: 34, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                            Text(t(ar: "تحكم بشكل الشارات البديلة داخل اللعبة.", en: "Control the custom badge style inside the game.", hi: "गेम में कस्टम बैज शैली नियंत्रित करें।", zh: "控制游戏内自定义徽章样式。", ku: "کۆنترۆڵی شێوازی نیشانەی جێگرەوە لە یارییەکەدا بکە."))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.76))
                        }
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(FootballTheme.cardBase.opacity(0.74)))
                                .overlay(Circle().stroke(FootballTheme.cardGlow.opacity(0.30), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "paintpalette.fill")
                                .font(.system(size: 22, weight: .black))
                                .foregroundStyle(FootballTheme.accentCyan)
                            Text(t(ar: "وضع الشارات المميزة", en: "Enhanced Badge Mode", hi: "उन्नत बैज मोड", zh: "增强徽章模式", ku: "دۆخی نیشانەی پێشکەوتوو"))
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        Toggle(
                            t(ar: "تفعيل", en: "Enable", hi: "सक्रिय", zh: "启用", ku: "چالاککردن"),
                            isOn: $downloadClubLogosEnabled
                        )
                        .font(.system(size: 17, weight: .bold))
                        .tint(FootballTheme.accentGreen)
                        .foregroundStyle(.white)

                        Text(
                            downloadClubLogosEnabled
                            ? t(ar: "مفعّل: ستظهر شارات احترافية بلمعان وتفاصيل أعلى.", en: "Enabled: premium custom badges with glow and extra details are shown.", hi: "सक्रिय: चमक और अतिरिक्त विवरण वाले प्रीमियम कस्टम बैज दिखेंगे।", zh: "已启用：将显示带发光与更多细节的高级自定义徽章。", ku: "چالاککراوە: نیشانەی تایبەتی پڕۆفیشناڵ بە بریسکە و وردەکاری زیاتر پیشان دەدرێت.")
                            : t(ar: "متوقف: ستظهر شارات بسيطة ونظيفة.", en: "Disabled: clean and simple custom badges are shown.", hi: "बंद: साफ और सरल कस्टम बैज दिखेंगे।", zh: "已关闭：将显示简洁的自定义徽章。", ku: "وەستاوە: نیشانەی تایبەتی سادە و پاک پیشان دەدرێت.")
                        )
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.80))
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(FootballTheme.cardBase.opacity(0.65))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(FootballTheme.cardGlow.opacity(0.24), lineWidth: 1)
                    )

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Text(t(ar: "تم", en: "Done", hi: "पूर्ण", zh: "完成", ku: "تەواو"))
                            .font(.system(size: 19, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(FootballTheme.cardBase.opacity(0.68))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(FootballTheme.cardGlow.opacity(0.22), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 30)
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct SettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLanguage: AppLanguage
    let onOpenClubCenter: () -> Void

    private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        selectedLanguage.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
    }

    private var isRTL: Bool {
        selectedLanguage.layoutDirection == .rightToLeft
    }

    private var contentAlignment: Alignment {
        isRTL ? .trailing : .leading
    }

    var body: some View {
        NavigationStack {
            ZStack {
                settingsBackground

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        settingsHeader
                        customizationCard
                        clubCenterRow
                        languagePickerCard
                        guideButton
                        legalPrivacyFooterCard
                    }
                    .padding(.horizontal, 17)
                    .padding(.top, 18)
                    .padding(.bottom, 24)
                }
            }
        }
        .environment(\.layoutDirection, selectedLanguage.layoutDirection)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var clubCenterRow: some View {
        Button {
            dismiss()
            onOpenClubCenter()
        } label: {
            HStack(spacing: 12) {
                if isRTL {
                    clubCenterChevron
                    Spacer(minLength: 8)
                    clubCenterText(alignment: .trailing)
                    clubCenterIcon
                } else {
                    clubCenterIcon
                    clubCenterText(alignment: .leading)
                    Spacer(minLength: 8)
                    clubCenterChevron
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
            .frame(minHeight: 74)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x2E1C60).opacity(0.93), Color(hex: 0x203C7A).opacity(0.89)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color(hex: 0x9E7DE7).opacity(0.38), lineWidth: 1)
                    )
            )
            .shadow(color: Color(hex: 0x6A54B6).opacity(0.20), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    private func clubCenterText(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 3) {
            Text(t(ar: "مركز الأندية", en: "Clubs Center", hi: "क्लब सेंटर", zh: "俱乐部中心", ku: "ناوەندی یانەکان"))
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text(t(ar: "إدارة بيانات الأندية والمحتوى", en: "Manage clubs data and content", hi: "क्लब डेटा और सामग्री प्रबंधित करें", zh: "管理俱乐部数据与内容", ku: "بەڕێوەبردنی داتای یانەکان و ناوەڕۆک"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: isRTL ? .trailing : .leading)
    }

    private var clubCenterIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xFFE38A), Color(hex: 0xD99A1D)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Circle()
                .stroke(Color.white.opacity(0.40), lineWidth: 1)

            Image(systemName: "shippingbox.fill")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.black.opacity(0.82))
        }
        .frame(width: 36, height: 36)
    }

    private var clubCenterChevron: some View {
        Image(systemName: isRTL ? "chevron.left" : "chevron.right")
            .font(.system(size: 13, weight: .black))
            .foregroundStyle(.white.opacity(0.84))
            .frame(width: 20, height: 20)
    }

    private var settingsBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x11062D), Color(hex: 0x0C1A45), Color(hex: 0x083167)],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color(hex: 0x52D3FF).opacity(0.30))
                .frame(width: 360, height: 360)
                .blur(radius: 128)
                .offset(x: -172, y: -240)

            Circle()
                .fill(Color(hex: 0x4A91FF).opacity(0.22))
                .frame(width: 340, height: 340)
                .blur(radius: 126)
                .offset(x: 178, y: 320)

            Circle()
                .fill(Color(hex: 0x9D65FF).opacity(0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 120)
                .offset(x: isRTL ? -146 : 146, y: -10)

            LinearGradient(
                colors: [Color.white.opacity(0.06), .clear, Color.black.opacity(0.20)],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.softLight)
        }
        .ignoresSafeArea()
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            ZStack {
                Circle()
                    .fill(Color(hex: 0x2A174C).opacity(0.72))
                Circle()
                    .fill(.ultraThinMaterial.opacity(0.18))
                Circle()
                    .stroke(Color(hex: 0x8A73D4).opacity(0.52), lineWidth: 0.9)

                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .frame(width: 36, height: 36)
            .shadow(color: Color(hex: 0x6D5AB8).opacity(0.26), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var settingsHeader: some View {
        VStack(alignment: isRTL ? .trailing : .leading, spacing: 7) {
            Text(t(ar: "الإعدادات", en: "Settings", hi: "सेटिंग्स", zh: "设置", ku: "ڕێکخستن"))
                .font(.system(size: 41, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.74)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: contentAlignment)

            Text(
                t(
                    ar: "اختر اللغة وطالع الإرشادات من شاشة كاملة أنيقة.",
                    en: "Choose language and open instructions from a polished full-screen panel.",
                    hi: "भाषा चुनें और सुंदर पूर्ण-स्क्रीन पैनल से निर्देश खोलें।",
                    zh: "在精致的全屏面板中选择语言并打开说明。",
                    ku: "زمان هەڵبژێرە و ڕێنمایییەکان لە شاشەیەکی تەواو و جوان بکەرەوە."
                )
            )
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.76))
            .lineSpacing(1.2)
            .multilineTextAlignment(isRTL ? .trailing : .leading)
            .frame(maxWidth: .infinity, alignment: contentAlignment)
        }
        .padding(.top, 4)
        .padding(isRTL ? .leading : .trailing, 44)
        .overlay(alignment: isRTL ? .topLeading : .topTrailing) {
            closeButton
        }
    }

    private var customizationCard: some View {
        HStack(spacing: 12) {
            if isRTL {
                customizationTextBlock(isTrailing: true)
                customizationIcon
            } else {
                customizationIcon
                customizationTextBlock(isTrailing: false)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x2C1C5D).opacity(0.94), Color(hex: 0x1F326A).opacity(0.90)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.08), .clear, Color.black.opacity(0.14)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: 0xA985FF).opacity(0.52), Color.white.opacity(0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: Color(hex: 0x715DB6).opacity(0.24), radius: 12, x: 0, y: 6)
    }

    private func customizationTextBlock(isTrailing: Bool) -> some View {
        VStack(alignment: isTrailing ? .trailing : .leading, spacing: 4) {
            Text(t(ar: "تخصيص التجربة", en: "Customize Experience", hi: "अनुभव अनुकूलन", zh: "自定义体验", ku: "تایبەتمەندی ئەزموون"))
                .font(.system(size: 22, weight: .black, design: .rounded))
                .minimumScaleFactor(0.75)
                .lineLimit(1)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: isTrailing ? .trailing : .leading)

            Text(
                t(
                    ar: "كل تغيير ينعكس مباشرة على واجهة اللعبة.",
                    en: "Every change instantly affects the game interface.",
                    hi: "हर बदलाव सीधे गेम इंटरफेस पर लागू होता है।",
                    zh: "每个改动都会立即应用到游戏界面。",
                    ku: "هەموو گۆڕانکارییەک ڕاستەوخۆ لەسەر ڕووکارەکەی یاری دەردەکەوێت."
                )
            )
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.74))
            .lineLimit(2)
            .multilineTextAlignment(isTrailing ? .trailing : .leading)
            .frame(maxWidth: .infinity, alignment: isTrailing ? .trailing : .leading)
        }
    }

    private var customizationIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x77F2D0), Color(hex: 0x67E5FF), Color(hex: 0xC2F66C)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(Color.white.opacity(0.34), lineWidth: 0.9)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.18), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )

            Image(systemName: "gearshape.fill")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(Color.black.opacity(0.76))
        }
        .frame(width: 58, height: 58)
        .shadow(color: Color(hex: 0x7FF0D2).opacity(0.35), radius: 10, x: 0, y: 5)
    }

    private var languagePickerCard: some View {
        VStack(alignment: isRTL ? .trailing : .leading, spacing: 12) {
            Text(t(ar: "اختيار اللغة", en: "Language", hi: "भाषा चयन", zh: "语言选择", ku: "هەڵبژاردنی زمان"))
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.72)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: contentAlignment)

            ForEach(AppLanguage.userSelectableLanguages) { language in
                languageRow(for: language)
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x1A123F).opacity(0.93), Color(hex: 0x162A5A).opacity(0.90)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.07), .clear, Color.black.opacity(0.14)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: 0x8E73DC).opacity(0.44), Color.white.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: Color(hex: 0x4E3E86).opacity(0.22), radius: 12, x: 0, y: 6)
    }

    private func languageRow(for language: AppLanguage) -> some View {
        let isSelected = selectedLanguage == language

        return Button {
            selectedLanguage = language
        } label: {
            HStack(spacing: 10) {
                if isRTL {
                    languageSelectionIndicator(isSelected: isSelected)
                    Spacer(minLength: 8)
                    languageTextBlock(for: language, isSelected: isSelected, isTrailing: true)
                } else {
                    languageTextBlock(for: language, isSelected: isSelected, isTrailing: false)
                    Spacer(minLength: 8)
                    languageSelectionIndicator(isSelected: isSelected)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(minHeight: 74)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .fill(
                        isSelected
                        ? LinearGradient(
                            colors: [Color(hex: 0x7CF3D7), Color(hex: 0x68E4FF), Color(hex: 0xC6F56B)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color(hex: 0x342066).opacity(0.94), Color(hex: 0x244082).opacity(0.90)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 23, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.12), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .stroke(
                        isSelected ? Color.white.opacity(0.34) : Color.white.opacity(0.14),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? Color(hex: 0x74E6DA).opacity(0.34) : Color.black.opacity(0.12),
                radius: isSelected ? 12 : 5,
                x: 0,
                y: isSelected ? 7 : 3
            )
            .animation(.easeInOut(duration: 0.20), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private func languageTextBlock(for language: AppLanguage, isSelected: Bool, isTrailing: Bool) -> some View {
        VStack(alignment: isTrailing ? .trailing : .leading, spacing: 2) {
            Text(language.nativeName)
                .font(.system(size: 27, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.70)
                .foregroundStyle(isSelected ? Color(hex: 0x162742) : .white.opacity(0.98))
                .frame(maxWidth: .infinity, alignment: isTrailing ? .trailing : .leading)

            Text(interfaceSubtitle(for: language))
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.74)
                .foregroundStyle(isSelected ? Color(hex: 0x20375A).opacity(0.78) : .white.opacity(0.66))
                .frame(maxWidth: .infinity, alignment: isTrailing ? .trailing : .leading)
        }
    }

    private func languageSelectionIndicator(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.white.opacity(0.98) : Color.white.opacity(0.08))
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(isSelected ? 0.90 : 0.66), lineWidth: 1.8)
                )
                .frame(width: 24, height: 24)

            if isSelected {
                Circle()
                    .fill(Color.black.opacity(0.84))
                    .frame(width: 14, height: 14)

                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(.white)
            }
        }
    }

    private func interfaceSubtitle(for language: AppLanguage) -> String {
        language.text(
            ar: "تفعيل كامل للواجهة",
            en: "Apply to the full interface",
            hi: "पूरी इंटरफेस पर लागू करें",
            zh: "应用到整个界面",
            ku: "بۆ تەواوی ڕووکارەکە جێبەجێ بکە"
        )
    }

    private var guideButton: some View {
        NavigationLink {
            GuideView(language: selectedLanguage)
        } label: {
            HStack(spacing: 12) {
                if isRTL {
                    guideTrailingIcon

                    Spacer(minLength: 10)

                    Text(t(ar: "الإرشادات", en: "Instructions", hi: "निर्देश", zh: "说明", ku: "ڕێنمایی"))
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.82)
                        .lineLimit(1)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    Text(t(ar: "الإرشادات", en: "Instructions", hi: "निर्देश", zh: "说明", ku: "ڕێنمایی"))
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.82)
                        .lineLimit(1)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer(minLength: 10)

                    guideTrailingIcon
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x75F0D2), Color(hex: 0x68E4FF), Color(hex: 0xB9F563)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.22), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.white.opacity(0.30), lineWidth: 1)
            )
            .shadow(color: Color(hex: 0x73F1D3).opacity(0.34), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var guideTrailingIcon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0x273353).opacity(0.96))
            Circle()
                .stroke(Color.white.opacity(0.28), lineWidth: 0.9)

            Image(systemName: "book.fill")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(width: 40, height: 40)
        .shadow(color: .black.opacity(0.18), radius: 5, x: 0, y: 3)
    }

    private var legalPrivacyFooterCard: some View {
        NavigationLink {
            LegalCenterView(language: selectedLanguage)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isRTL ? "chevron.left" : "chevron.right")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.white.opacity(0.82))
                    .frame(width: 24, height: 24)

                VStack(alignment: isRTL ? .trailing : .leading, spacing: 4) {
                    Text(
                        t(
                            ar: "القانون والخصوصية",
                            en: "Legal & Privacy",
                            hi: "कानूनी और गोपनीयता",
                            zh: "法律与隐私",
                            ku: "یاسا و نهێنی"
                        )
                    )
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: isRTL ? .trailing : .leading)

                    Text(
                        t(
                            ar: "سياسة الخصوصية، الدعم، وإخلاء المسؤولية.",
                            en: "Privacy policy, support, and disclaimer.",
                            hi: "गोपनीयता नीति, सपोर्ट और अस्वीकरण।",
                            zh: "隐私政策、支持与免责声明。",
                            ku: "سیاسەتی نهێنی، پشتگیری و ڕەتکردنەوەی بەرپرسیارێتی."
                        )
                    )
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                    .foregroundStyle(.white.opacity(0.76))
                    .frame(maxWidth: .infinity, alignment: isRTL ? .trailing : .leading)
                }

                legalFooterShieldIcon
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .frame(minHeight: 92)
            .background(
                RoundedRectangle(cornerRadius: 29, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x2A1A5E), Color(hex: 0x214184), Color(hex: 0x2761AB)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 29, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.14), .clear, Color.black.opacity(0.16)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 29, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: 0xA584FF).opacity(0.52), Color.white.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color(hex: 0x6A56B8).opacity(0.24), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var legalFooterShieldIcon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0x2B1A52).opacity(0.96))
            Circle()
                .stroke(Color(hex: 0x9A82E7).opacity(0.42), lineWidth: 0.9)

            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(width: 42, height: 42)
        .shadow(color: .black.opacity(0.18), radius: 5, x: 0, y: 3)
    }
}

private struct TodayMatchesScreen: View {
    @Environment(\.dismiss) private var dismiss
    let language: AppLanguage
    @StateObject private var viewModel: MatchesViewModel

    init(language: AppLanguage) {
        self.language = language
        _viewModel = StateObject(wrappedValue: MatchesViewModel())
    }

    private var isRTL: Bool {
        language.layoutDirection == .rightToLeft
    }

    private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                matchesBackground

                VStack(spacing: 10) {
                    topBar
                    matchesContent
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Int.self) { matchId in
                MatchDetailsView(matchId: matchId, language: language)
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
        .task {
            await viewModel.loadMatches(forceRefresh: false)
        }
    }

    private var matchesBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x12052C), Color(hex: 0x0B1A48), Color(hex: 0x05336D)],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color(hex: 0x59D8FF).opacity(0.24))
                .frame(width: 360, height: 360)
                .blur(radius: 132)
                .offset(x: -170, y: -240)

            Circle()
                .fill(Color(hex: 0x4F8FFF).opacity(0.20))
                .frame(width: 330, height: 330)
                .blur(radius: 124)
                .offset(x: 180, y: 320)

            Circle()
                .fill(Color(hex: 0xA55FFF).opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 128)
                .offset(x: isRTL ? -130 : 130, y: -20)
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        VStack(alignment: isRTL ? .trailing : .leading, spacing: 4) {
            Text(t(ar: "مباريات اليوم", en: "Today Matches", hi: "आज के मैच", zh: "今日比赛", ku: "یارییەکانی ئەمڕۆ"))
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity, alignment: isRTL ? .trailing : .leading)

            Text(t(ar: "مباشر، اليوم، وأهم المواجهات", en: "Live, today, and top fixtures", hi: "लाइव, आज और मुख्य मुकाबले", zh: "直播、今日与焦点对决", ku: "ڕاستەوخۆ، ئەمڕۆ و گرنگترین پێکدادان"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.76))
                .lineLimit(1)
                .minimumScaleFactor(0.74)
                .frame(maxWidth: .infinity, alignment: isRTL ? .trailing : .leading)
        }
        .padding(.top, 2)
        .padding(isRTL ? .leading : .trailing, 48)
        .padding(isRTL ? .trailing : .leading, 48)
        .overlay(alignment: isRTL ? .topTrailing : .topLeading) {
            topIconButton(symbol: isRTL ? "chevron.right" : "chevron.left") {
                dismiss()
            }
        }
        .overlay(alignment: isRTL ? .topLeading : .topTrailing) {
            Button {
                viewModel.retry()
            } label: {
                if viewModel.isLoading {
                    ZStack {
                        Circle()
                            .fill(Color(hex: 0x2A1850).opacity(0.84))
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.78)
                    }
                    .frame(width: 34, height: 34)
                } else {
                    topIconButtonLabel(symbol: "arrow.clockwise")
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func topIconButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            topIconButtonLabel(symbol: symbol)
        }
        .buttonStyle(.plain)
    }

    private func topIconButtonLabel(symbol: String) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0x2A1850).opacity(0.84))
            Circle()
                .stroke(Color(hex: 0x8A73D4).opacity(0.44), lineWidth: 0.9)

            Image(systemName: symbol)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(width: 34, height: 34)
        .shadow(color: Color(hex: 0x6E58B8).opacity(0.24), radius: 8, x: 0, y: 4)
    }

    private func localizedLeagueName(_ leagueID: Int, fallback: String) -> String {
        switch leagueID {
        case 39:
            return t(ar: "الدوري الإنجليزي", en: "Premier League", hi: "प्रीमियर लीग", zh: "英超", ku: "پریمیەر لیگ")
        case 140:
            return t(ar: "الدوري الإسباني", en: "La Liga", hi: "ला लीगा", zh: "西甲", ku: "لا لیگا")
        case 135:
            return t(ar: "الدوري الإيطالي", en: "Serie A", hi: "सीरी ए", zh: "意甲", ku: "سێری ئا")
        case 78:
            return t(ar: "الدوري الألماني", en: "Bundesliga", hi: "बुंडेसलीगा", zh: "德甲", ku: "بوندسلیگا")
        case 61:
            return t(ar: "الدوري الفرنسي", en: "Ligue 1", hi: "लीग 1", zh: "法甲", ku: "لیگ ١")
        case 307:
            return t(ar: "الدوري السعودي", en: "Saudi Pro League", hi: "सऊदी प्रो लीग", zh: "沙特职业联赛", ku: "لیگی سعودی")
        default:
            return localizedDisplayName(fallback, in: language)
        }
    }

    private func localizedLeagueName(for match: MatchDisplayModel) -> String {
        guard let leagueID = match.leagueID else {
            return localizedDisplayName(match.leagueName, in: language)
        }
        return localizedLeagueName(leagueID, fallback: match.leagueName)
    }

    @ViewBuilder
    private var matchesContent: some View {
        if viewModel.isLoading && viewModel.liveMatches.isEmpty && viewModel.otherMatches.isEmpty {
            loadingState
        } else if let message = viewModel.errorMessage,
                  viewModel.liveMatches.isEmpty && viewModel.otherMatches.isEmpty {
            errorState(message: message)
        } else if viewModel.isEmpty {
            emptyState
        } else {
            matchesList
        }
    }

    private var loadingState: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.88)

                    Text(t(ar: "جاري تحميل مباريات البطولات المحددة...", en: "Loading selected league matches...", hi: "चयनित लीग मैच लोड हो रहे हैं...", zh: "正在加载指定联赛比赛...", ku: "یارییەکانی لیگە دیاریکراوەکان بار دەکرێن..."))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.78))
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 3)
                .padding(.top, 6)

                ForEach(0..<4, id: \.self) { _ in
                    loadingSkeletonCard
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 14)
        }
        .refreshable {
            await viewModel.loadMatches(forceRefresh: true)
        }
    }

    private func errorState(message: String) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                Spacer(minLength: 16)
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(Color(hex: 0xFF7E89))
                Text(t(ar: "تعذر تحميل المباريات", en: "Failed to load matches", hi: "मैच लोड नहीं हो सके", zh: "无法加载比赛", ku: "بارکردنی یارییەکان شکستی هێنا"))
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(message)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                Button {
                    viewModel.retry()
                } label: {
                    Text(t(ar: "إعادة المحاولة", en: "Try Again", hi: "फिर प्रयास करें", zh: "重试", ku: "دووبارە هەوڵبدە"))
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: 0x2E1E63), Color(hex: 0x224083)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                }
                .buttonStyle(.plain)
                Spacer(minLength: 16)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
        }
        .refreshable {
            await viewModel.loadMatches(forceRefresh: true)
        }
    }

    private var emptyState: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                Spacer(minLength: 18)
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(Color(hex: 0x7FB7FF))

                Text(t(
                    ar: "لا توجد مباريات اليوم في البطولات المحددة",
                    en: "No matches today in the selected leagues",
                    hi: "चयनित लीगों में आज कोई मैच नहीं",
                    zh: "指定联赛今天没有比赛",
                    ku: "ئەمڕۆ لە لیگە دیاریکراوەکان هیچ یارییەک نییە"
                ))
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

                Text(t(
                    ar: "اسحب للأسفل للتحديث",
                    en: "Pull down to refresh",
                    hi: "रीफ़्रेश करने के लिए नीचे खींचें",
                    zh: "下拉即可刷新",
                    ku: "بۆ نوێکردنەوە بەرەوخوار ڕابکێشە"
                ))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.70))

                Spacer(minLength: 18)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
        }
        .refreshable {
            await viewModel.loadMatches(forceRefresh: true)
        }
    }

    private var matchesList: some View {
        let orderedMatches = viewModel.liveMatches + viewModel.otherMatches

        return ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(orderedMatches) { match in
                    NavigationLink(value: match.id) {
                        matchCard(match)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 10)
        }
        .refreshable {
            await viewModel.loadMatches(forceRefresh: true)
        }
    }

    private var loadingSkeletonCard: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(0.10))
            .frame(height: 128)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .redacted(reason: .placeholder)
    }

    private func matchCard(_ match: MatchDisplayModel) -> some View {
        VStack(spacing: 10) {
            leagueRow(for: match)
            teamsRow(for: match)
            detailsRow(for: match)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x291A5D).opacity(0.94), Color(hex: 0x1E356F).opacity(0.90)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.10), .clear, Color.black.opacity(0.15)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 0.9)
                )
        )
        .shadow(color: .black.opacity(0.16), radius: 10, x: 0, y: 6)
    }

    private func leagueRow(for match: MatchDisplayModel) -> some View {
        HStack(spacing: 8) {
            statusChip(for: match)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Text(localizedLeagueName(for: match))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                leagueBadgeView(
                    url: match.leagueFlagURL ?? match.leagueLogoURL,
                    fallbackText: String(match.leagueName.prefix(1)).uppercased()
                )
            }
            .font(.system(size: 11, weight: .black))
            .foregroundStyle(.white.opacity(0.86))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.10))
            )
        }
    }

    private func teamsRow(for match: MatchDisplayModel) -> some View {
        let viewData = fixedCardViewData(for: match)

        return HStack(spacing: 8) {
            teamColumn(name: viewData.leadingTeam.name, logoURL: viewData.leadingTeam.logoURL)
            centerScoreColumn(for: match, leftScore: viewData.leadingScore, rightScore: viewData.trailingScore)
            teamColumn(name: viewData.trailingTeam.name, logoURL: viewData.trailingTeam.logoURL)
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private func teamColumn(name: String, logoURL: URL?) -> some View {
        VStack(spacing: 6) {
            teamLogoView(name: name, logoURL: logoURL)
            Text(name)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.70)
        }
        .frame(maxWidth: .infinity)
    }

    private func teamLogoView(name: String, logoURL: URL?) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x385395), Color(hex: 0x253767)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Circle()
                .stroke(Color.white.opacity(0.24), lineWidth: 0.9)

            if let logoURL {
                CachedRemoteImage(url: logoURL, contentMode: .fill) {
                    Text(teamInitials(name))
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white.opacity(0.92))
                }
                .frame(width: 34, height: 34)
                .clipShape(Circle())
            } else {
                Text(teamInitials(name))
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.92))
            }
        }
        .frame(width: 38, height: 38)
    }

    private func centerScoreColumn(for match: MatchDisplayModel, leftScore: String, rightScore: String) -> some View {
        VStack(spacing: 5) {
            if match.isLive || match.isFinished {
                HStack(spacing: 5) {
                    Text(leftScore)
                    Text("-")
                    Text(rightScore)
                }
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
                .environment(\.layoutDirection, .leftToRight)
            } else {
                Text(match.kickoffLocalText)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
            }

            if let minuteText = match.minuteText {
                Text(minuteText)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Color(hex: 0xFF9F7D))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(hex: 0x4A241E).opacity(0.88))
                    )
            }
        }
        .frame(minWidth: 82)
    }

    private func fixedCardViewData(for match: MatchDisplayModel) -> MatchCardViewData {
        let leadingHomeTeam = MatchTeamVisualSlot(
            name: match.homeTeamName,
            logoURL: match.homeTeamLogoURL,
            score: match.homeScore
        )
        let trailingAwayTeam = MatchTeamVisualSlot(
            name: match.awayTeamName,
            logoURL: match.awayTeamLogoURL,
            score: match.awayScore
        )

        #if DEBUG
        assert(
            leadingHomeTeam.name == match.homeTeamName && leadingHomeTeam.score == match.homeScore,
            "Home team must always stay in the first visual slot."
        )
        assert(
            trailingAwayTeam.name == match.awayTeamName && trailingAwayTeam.score == match.awayScore,
            "Away team must always stay in the second visual slot."
        )
        #endif

        return MatchCardViewData(
            leadingTeam: leadingHomeTeam,
            trailingTeam: trailingAwayTeam,
            leadingScore: leadingHomeTeam.score,
            trailingScore: trailingAwayTeam.score
        )
    }

    private func detailsRow(for match: MatchDisplayModel) -> some View {
        HStack(spacing: 8) {
            if !match.venueName.isEmpty, match.venueName != "--" {
                Label {
                    Text(match.venueName)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                } icon: {
                    Image(systemName: "mappin.and.ellipse")
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.64))
            }

            Spacer(minLength: 0)

            Label {
                Text(match.kickoffLocalText)
            } icon: {
                Image(systemName: "clock")
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Color(hex: 0x84CFFF))
        }
    }

    private func statusChip(for match: MatchDisplayModel) -> some View {
        let style = statusStyle(for: match)

        return Text(style.label)
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(style.tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(style.background.opacity(0.92))
            )
            .overlay(
                Capsule()
                    .stroke(style.tint.opacity(0.50), lineWidth: 0.9)
            )
    }

    private func statusStyle(for match: MatchDisplayModel) -> (label: String, tint: Color, background: Color) {
        if match.isLive {
            return (
                "LIVE",
                Color(hex: 0xFF5A57),
                Color(hex: 0x451616)
            )
        }

        if match.isFinished {
            return (
                t(ar: "انتهت", en: "Finished", hi: "समाप्त", zh: "已结束", ku: "تەواو بوو"),
                Color(hex: 0x9AA4FF),
                Color(hex: 0x232A56)
            )
        }

        return (
            t(ar: "لم تبدأ", en: "Not Started", hi: "शुरू नहीं", zh: "未开始", ku: "دەست پێ نەکردووە"),
            Color(hex: 0x82D0FF),
            Color(hex: 0x17355B)
        )
    }

    private func teamInitials(_ name: String) -> String {
        let words = name.split(separator: " ")
        if let first = words.first, let second = words.dropFirst().first {
            return "\(first.prefix(1))\(second.prefix(1))".uppercased()
        }
        return String(words.first?.prefix(2) ?? "TM").uppercased()
    }

    private func leagueBadgeView(url: URL?, fallbackText: String) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 16, height: 16)

            if let url {
                CachedRemoteImage(url: url, contentMode: .fill) {
                    Text(fallbackText)
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(width: 14, height: 14)
                .clipShape(Circle())
            } else {
                Text(fallbackText)
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }
}
private struct TeamDetailsView: View {
    @Environment(\.dismiss) private var dismiss

    let club: TopFiveClubItem
    let language: AppLanguage

    @StateObject private var viewModel: TeamDetailsViewModel

    init(club: TopFiveClubItem, language: AppLanguage) {
        self.club = club
        self.language = language
        _viewModel = StateObject(wrappedValue: TeamDetailsViewModel(club: club))
    }

    private var isRTL: Bool {
        language.layoutDirection == .rightToLeft
    }

    private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
    }

    private var hasCoreOverview: Bool {
        !viewModel.overview.teamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 12) {
                topBar
                contentState
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .toolbar(.hidden, for: .navigationBar)
        .environment(\.layoutDirection, language.layoutDirection)
        .task(id: club.id) {
            await viewModel.fetchDetails()
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x10042A), Color(hex: 0x0A204A), Color(hex: 0x083A75)],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color(hex: 0x58CCFF).opacity(0.23))
                .frame(width: 340, height: 340)
                .blur(radius: 124)
                .offset(x: -170, y: -240)

            Circle()
                .fill(Color(hex: 0x498BFF).opacity(0.20))
                .frame(width: 310, height: 310)
                .blur(radius: 122)
                .offset(x: 170, y: 280)

            Circle()
                .fill(Color(hex: 0xA869FF).opacity(0.12))
                .frame(width: 286, height: 286)
                .blur(radius: 118)
                .offset(x: isRTL ? -120 : 120, y: -24)
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        VStack(alignment: isRTL ? .trailing : .leading, spacing: 4) {
            Text(t(ar: "تفاصيل النادي", en: "Club Details", hi: "क्लब विवरण", zh: "俱乐部详情", ku: "وردەکاری تیم"))
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity, alignment: isRTL ? .trailing : .leading)

            Text(t(ar: "معلومات النادي الأساسية", en: "Basic club information", hi: "क्लब की बुनियादी जानकारी", zh: "俱乐部基础信息", ku: "زانیاریی بنەڕەتی تیم"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.76))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: isRTL ? .trailing : .leading)
        }
        .padding(.top, 2)
        .padding(isRTL ? .leading : .trailing, 48)
        .padding(isRTL ? .trailing : .leading, 48)
        .overlay(alignment: isRTL ? .topTrailing : .topLeading) {
            Button {
                dismiss()
            } label: {
                topIcon(symbol: isRTL ? "chevron.right" : "chevron.left")
            }
            .buttonStyle(.plain)
        }
        .overlay(alignment: isRTL ? .topLeading : .topTrailing) {
            Button {
                viewModel.retry()
            } label: {
                if viewModel.isLoading || viewModel.isRefreshing {
                    ZStack {
                        Circle()
                            .fill(Color(hex: 0x2A1850).opacity(0.84))
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.78)
                    }
                    .frame(width: 34, height: 34)
                } else {
                    topIcon(symbol: "arrow.clockwise")
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func topIcon(symbol: String) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0x2A1850).opacity(0.84))
            Circle()
                .stroke(Color(hex: 0x8A73D4).opacity(0.44), lineWidth: 0.9)

            Image(systemName: symbol)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(width: 34, height: 34)
        .shadow(color: Color(hex: 0x6E58B8).opacity(0.24), radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private var contentState: some View {
        if viewModel.isLoading && !hasCoreOverview {
            loadingState
        } else if let message = viewModel.errorMessage, !hasCoreOverview {
            errorState(message: message)
        } else {
            detailsContent
        }
    }

    private var loadingState: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                skeletonCard(height: 152)
                skeletonCard(height: 166)
            }
            .redacted(reason: .placeholder)
            .padding(.top, 4)
            .padding(.bottom, 10)
        }
    }

    private func skeletonCard(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.white.opacity(0.10))
            .frame(height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 10) {
            Spacer(minLength: 16)
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(Color(hex: 0xFF7E89))
            Text(t(ar: "تعذر تحميل بيانات النادي", en: "Failed to load club details", hi: "क्लब विवरण लोड नहीं हो सके", zh: "无法加载俱乐部详情", ku: "بارکردنی وردەکارییەکانی تیم شکستی هێنا"))
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(message)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Button {
                viewModel.retry()
            } label: {
                Text(t(ar: "إعادة المحاولة", en: "Try Again", hi: "फिर प्रयास करें", zh: "重试", ku: "دووبارە هەوڵبدە"))
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: 0x2E1E63), Color(hex: 0x224083)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
            .buttonStyle(.plain)
            Spacer(minLength: 16)
        }
        .frame(maxWidth: .infinity)
    }

    private var detailsContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                if let warning = viewModel.errorMessage {
                    teamDetailsWarningBanner(text: warning)
                }
                clubHeroCard
                overviewSection
                if let summary = overviewSummaryText {
                    summarySection(text: summary)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 10)
        }
    }

    private func teamDetailsWarningBanner(text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(Color(hex: 0xFFC47E))

            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
                .lineLimit(2)
                .multilineTextAlignment(isRTL ? .trailing : .leading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: 0x4A2A24).opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(hex: 0xFFC47E).opacity(0.34), lineWidth: 0.9)
                )
        )
    }

    private var clubHeroCard: some View {
        HStack(spacing: 12) {
            teamLogo(name: viewModel.overview.teamName, url: viewModel.overview.teamLogoURL, size: 74)

            VStack(alignment: isRTL ? .trailing : .leading, spacing: 4) {
                Text(localizedDisplayName(viewModel.overview.teamName, in: language))
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: isRTL ? .trailing : .leading)

                Text(localizedTopFiveLeagueName(viewModel.overview.leagueID, fallback: viewModel.overview.leagueName))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: isRTL ? .trailing : .leading)

                HStack(spacing: 8) {
                    if let country = viewModel.overview.country {
                        heroChip(country)
                    }
                    if let city = viewModel.overview.city {
                        heroChip(city)
                    }
                }
                .frame(maxWidth: .infinity, alignment: isRTL ? .trailing : .leading)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(sectionBackground)
    }

    private func heroChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(.white.opacity(0.84))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.10))
            )
    }

    private var overviewSection: some View {
        VStack(alignment: isRTL ? .trailing : .leading, spacing: 9) {
            sectionTitle(t(ar: "Overview", en: "Overview", hi: "ओवरव्यू", zh: "概览", ku: "پوختە"))

            infoRow(
                label: t(ar: "النادي", en: "Club", hi: "क्लब", zh: "俱乐部", ku: "تیم"),
                value: localizedDisplayName(viewModel.overview.teamName, in: language)
            )
            infoRow(
                label: t(ar: "الدوري", en: "League", hi: "लीग", zh: "联赛", ku: "لیگ"),
                value: localizedTopFiveLeagueName(viewModel.overview.leagueID, fallback: viewModel.overview.leagueName)
            )

            if let country = viewModel.overview.country {
                infoRow(label: t(ar: "الدولة", en: "Country", hi: "देश", zh: "国家", ku: "وڵات"), value: country)
            }
            if let city = viewModel.overview.city {
                infoRow(label: t(ar: "المدينة", en: "City", hi: "शहर", zh: "城市", ku: "شار"), value: city)
            }
            if let stadiumName = viewModel.overview.stadiumName {
                infoRow(label: t(ar: "الملعب", en: "Stadium", hi: "स्टेडियम", zh: "球场", ku: "یاریگا"), value: stadiumName)
            }
            if let founded = viewModel.overview.founded {
                infoRow(label: t(ar: "التأسيس", en: "Founded", hi: "स्थापना", zh: "成立", ku: "دامەزراندن"), value: "\(founded)")
            }
            if let coach = viewModel.overview.coachName {
                infoRow(label: t(ar: "المدرب", en: "Coach", hi: "कोच", zh: "教练", ku: "ڕاهێنەر"), value: coach)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(sectionBackground)
    }

    private var overviewSummaryText: String? {
        let localizedLeague = localizedTopFiveLeagueName(viewModel.overview.leagueID, fallback: viewModel.overview.leagueName)
        let teamName = localizedDisplayName(viewModel.overview.teamName, in: language)
        guard let country = viewModel.overview.country else { return nil }

        return t(
            ar: "\(teamName) نادي من \(country) ينافس في \(localizedLeague).",
            en: "\(teamName) is a club from \(country) competing in \(localizedLeague).",
            hi: "\(teamName) \(country) का क्लब है और \(localizedLeague) में प्रतिस्पर्धा करता है।",
            zh: "\(teamName) 来自 \(country)，参加 \(localizedLeague)。",
            ku: "\(teamName) یانەیەکە لە \(country) و لە \(localizedLeague) پێشبڕکێ دەکات."
        )
    }

    private func summarySection(text: String) -> some View {
        VStack(alignment: isRTL ? .trailing : .leading, spacing: 9) {
            sectionTitle(t(ar: "معلومات عامة", en: "General Info", hi: "सामान्य जानकारी", zh: "一般信息", ku: "زانیاریی گشتی"))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
                .frame(maxWidth: .infinity, alignment: isRTL ? .trailing : .leading)
                .multilineTextAlignment(isRTL ? .trailing : .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(sectionBackground)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(isRTL ? .trailing : .leading)

            Spacer(minLength: 0)

            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.66))
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Spacer(minLength: 0)
        }
    }

    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(hex: 0x291A5D).opacity(0.94), Color(hex: 0x1E356F).opacity(0.90)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.10), .clear, Color.black.opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 0.9)
            )
            .shadow(color: .black.opacity(0.16), radius: 10, x: 0, y: 6)
    }

    private func teamLogo(name: String, url: URL?, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x385395), Color(hex: 0x253767)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Circle()
                .stroke(Color.white.opacity(0.24), lineWidth: 0.9)

            if let url {
                CachedRemoteImage(url: url, contentMode: .fill) {
                    Text(teamInitials(name))
                        .font(.system(size: max(10, size * 0.25), weight: .black))
                        .foregroundStyle(.white.opacity(0.92))
                }
                .frame(width: size - 4, height: size - 4)
                .clipShape(Circle())
            } else {
                Text(teamInitials(name))
                    .font(.system(size: max(10, size * 0.25), weight: .black))
                    .foregroundStyle(.white.opacity(0.92))
            }
        }
        .frame(width: size, height: size)
    }

    private func teamInitials(_ name: String) -> String {
        let words = name.split(separator: " ")
        if let first = words.first, let second = words.dropFirst().first {
            return "\(first.prefix(1))\(second.prefix(1))".uppercased()
        }
        return String(words.first?.prefix(2) ?? "TM").uppercased()
    }

    private func localizedTopFiveLeagueName(_ leagueID: Int, fallback: String) -> String {
        switch leagueID {
        case 39:
            return t(ar: "الدوري الإنجليزي", en: "Premier League", hi: "प्रीमियर लीग", zh: "英超", ku: "پریمیەر لیگ")
        case 140:
            return t(ar: "الدوري الإسباني", en: "La Liga", hi: "ला लीगा", zh: "西甲", ku: "لا لیگا")
        case 135:
            return t(ar: "الدوري الإيطالي", en: "Serie A", hi: "सीरी ए", zh: "意甲", ku: "سێری ئا")
        case 78:
            return t(ar: "الدوري الألماني", en: "Bundesliga", hi: "बुंडेसलीगा", zh: "德甲", ku: "بوندسلیگا")
        case 61:
            return t(ar: "الدوري الفرنسي", en: "Ligue 1", hi: "लीग 1", zh: "法甲", ku: "لیگ ١")
        default:
            return localizedDisplayName(fallback, in: language)
        }
    }
}

private struct MatchDetailsView: View {
    @Environment(\.dismiss) private var dismiss

    let matchId: Int
    let language: AppLanguage

    @StateObject private var viewModel: MatchDetailsViewModel

    init(matchId: Int, language: AppLanguage) {
        self.matchId = matchId
        self.language = language
        _viewModel = StateObject(wrappedValue: MatchDetailsViewModel(matchId: matchId))
    }

    private var isRTL: Bool {
        language.layoutDirection == .rightToLeft
    }

    private func t(ar: String, en: String) -> String {
        language.text(ar: ar, en: en, hi: en, zh: en, ku: ar)
    }

    private var fixture: FixtureItem? {
        viewModel.fixture
    }

    private var awayLineup: FixtureLineup? {
        lineup(for: fixture?.teams?.away?.id)
    }

    private var homeLineup: FixtureLineup? {
        lineup(for: fixture?.teams?.home?.id)
    }

    private var awayTeamName: String {
        cleanedText(fixture?.teams?.away?.name) ?? "Away"
    }

    private var homeTeamName: String {
        cleanedText(fixture?.teams?.home?.name) ?? "Home"
    }

    private var awayTeamLogoURL: URL? {
        safeURL(fixture?.teams?.away?.logo)
    }

    private var homeTeamLogoURL: URL? {
        safeURL(fixture?.teams?.home?.logo)
    }

    private var awayScoreText: String {
        if let score = fixture?.goals?.away {
            return "\(score)"
        }
        return "-"
    }

    private var homeScoreText: String {
        if let score = fixture?.goals?.home {
            return "\(score)"
        }
        return "-"
    }

    private var currentStatusShort: String {
        cleanedText(fixture?.fixture?.status?.short)?.uppercased() ?? "--"
    }

    private var currentStatusText: String {
        cleanedText(fixture?.fixture?.status?.long)
            ?? cleanedText(fixture?.fixture?.status?.short)
            ?? "--"
    }

    private var competitionName: String {
        cleanedText(fixture?.league?.name) ?? "--"
    }

    private var kickoffDate: Date? {
        if let timestamp = fixture?.fixture?.timestamp, timestamp > 0 {
            return Date(timeIntervalSince1970: TimeInterval(timestamp))
        }

        guard let isoDate = cleanedText(fixture?.fixture?.date) else { return nil }
        if let parsed = MatchDetailsDateParsers.isoWithFractional.date(from: isoDate) {
            return parsed
        }
        return MatchDetailsDateParsers.isoStandard.date(from: isoDate)
    }

    private var kickoffTimeText: String {
        guard let kickoffDate else { return "--:--" }
        return MatchDetailsDateParsers.timeFormatter(localeIdentifier: language.localeIdentifier).string(from: kickoffDate)
    }

    private var kickoffDateText: String {
        guard let kickoffDate else { return "--" }
        return MatchDetailsDateParsers.dateFormatter(localeIdentifier: language.localeIdentifier).string(from: kickoffDate)
    }

    private var venueText: String {
        let venueName = cleanedText(fixture?.fixture?.venue?.name)
        let venueCity = cleanedText(fixture?.fixture?.venue?.city)

        switch (venueName, venueCity) {
        case let (name?, city?):
            return "\(name) • \(city)"
        case let (name?, nil):
            return name
        case let (nil, city?):
            return city
        default:
            return "--"
        }
    }

    private var shouldShowKickoffInCenter: Bool {
        let upcomingCodes: Set<String> = ["NS", "TBD"]
        return upcomingCodes.contains(currentStatusShort)
    }

    private var hasSubstitutes: Bool {
        viewModel.lineups.contains { !players(from: $0.substitutes).isEmpty }
    }

    private var coachRows: [MatchCoachRow] {
        var rows: [MatchCoachRow] = []
        for lineup in viewModel.lineups {
            guard let teamName = cleanedText(lineup.team?.name),
                  let coachName = cleanedText(lineup.coach?.name) else {
                continue
            }
            rows.append(MatchCoachRow(teamName: teamName, coachName: coachName, coachPhotoURL: safeURL(lineup.coach?.photo)))
        }
        return rows
    }

    private var statisticsRows: [MatchStatisticDisplayRow] {
        guard !viewModel.statistics.isEmpty else { return [] }

        let awayTeamID = fixture?.teams?.away?.id
        let homeTeamID = fixture?.teams?.home?.id

        let awayStats = statistics(for: awayTeamID) ?? viewModel.statistics.first
        let homeStats = statistics(for: homeTeamID) ?? (viewModel.statistics.count > 1 ? viewModel.statistics[1] : nil)

        guard let awayStats else { return [] }

        let awayPairs = awayStats.statistics.compactMap { stat -> (String, String)? in
            guard let type = cleanedText(stat.type) else { return nil }
            return (type, statisticValueText(stat.value))
        }
        let homePairs = (homeStats?.statistics ?? []).compactMap { stat -> (String, String)? in
            guard let type = cleanedText(stat.type) else { return nil }
            return (type, statisticValueText(stat.value))
        }

        let awayMap = Dictionary(uniqueKeysWithValues: awayPairs)
        let homeMap = Dictionary(uniqueKeysWithValues: homePairs)
        let orderedTypes = orderedUniqueTypes(from: awayPairs.map(\.0) + homePairs.map(\.0))

        return orderedTypes.map { type in
            MatchStatisticDisplayRow(
                type: type,
                awayValue: awayMap[type] ?? "--",
                homeValue: homeMap[type] ?? "--"
            )
        }
    }

    private var orderedEvents: [FixtureEventItem] {
        viewModel.events
    }

    var body: some View {
        ZStack {
            detailsBackground

            VStack(spacing: 12) {
                topBar
                contentState
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .toolbar(.hidden, for: .navigationBar)
        .environment(\.layoutDirection, language.layoutDirection)
        .task(id: matchId) {
            await viewModel.fetchDetails()
        }
    }

    private var detailsBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x10042A), Color(hex: 0x0A204A), Color(hex: 0x083A75)],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color(hex: 0x5BCBFF).opacity(0.24))
                .frame(width: 330, height: 330)
                .blur(radius: 128)
                .offset(x: -170, y: -250)

            Circle()
                .fill(Color(hex: 0x4A8EFF).opacity(0.20))
                .frame(width: 300, height: 300)
                .blur(radius: 118)
                .offset(x: 170, y: 270)

            Circle()
                .fill(Color(hex: 0xB36DFF).opacity(0.13))
                .frame(width: 280, height: 280)
                .blur(radius: 122)
                .offset(x: isRTL ? -120 : 120, y: -20)
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        VStack(alignment: isRTL ? .trailing : .leading, spacing: 4) {
            Text(t(ar: "تفاصيل المباراة", en: "Match Details"))
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity, alignment: isRTL ? .trailing : .leading)

            Text(t(ar: "التشكيلة، الإحصائيات، وأحداث المباراة", en: "Lineups, statistics, and match events"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.76))
                .lineLimit(1)
                .minimumScaleFactor(0.74)
                .frame(maxWidth: .infinity, alignment: isRTL ? .trailing : .leading)
        }
        .padding(.top, 2)
        .padding(isRTL ? .leading : .trailing, 48)
        .padding(isRTL ? .trailing : .leading, 48)
        .overlay(alignment: isRTL ? .topTrailing : .topLeading) {
            topIconButton(symbol: isRTL ? "chevron.right" : "chevron.left") {
                dismiss()
            }
        }
        .overlay(alignment: isRTL ? .topLeading : .topTrailing) {
            Button {
                viewModel.retry()
            } label: {
                if viewModel.isLoading {
                    ZStack {
                        Circle()
                            .fill(Color(hex: 0x2A1850).opacity(0.84))
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.78)
                    }
                    .frame(width: 34, height: 34)
                } else {
                    topIconButtonLabel(symbol: "arrow.clockwise")
                }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var contentState: some View {
        if viewModel.isLoading && fixture == nil {
            loadingState
        } else if let message = viewModel.errorMessage, fixture == nil {
            errorState(message: message)
        } else {
            detailsContent
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 18)
            ProgressView()
                .tint(.white)
                .scaleEffect(1.05)
            Text(t(ar: "جاري تحميل تفاصيل المباراة...", en: "Loading match details..."))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.78))
            Spacer(minLength: 18)
        }
        .frame(maxWidth: .infinity)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 10) {
            Spacer(minLength: 18)
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(Color(hex: 0xFF7E89))
            Text(t(ar: "تعذر تحميل تفاصيل المباراة", en: "Failed to load match details"))
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(message)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Button {
                viewModel.retry()
            } label: {
                Text(t(ar: "إعادة المحاولة", en: "Try Again"))
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: 0x2E1E63), Color(hex: 0x224083)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
            .buttonStyle(.plain)
            Spacer(minLength: 18)
        }
        .frame(maxWidth: .infinity)
    }

    private var detailsContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                if fixture != nil {
                    headerCard
                    lineupSection

                    if hasSubstitutes {
                        substitutesSection
                    }

                    if !coachRows.isEmpty {
                        coachesSection
                    }

                    if !statisticsRows.isEmpty {
                        statisticsSection
                    }

                    if !orderedEvents.isEmpty {
                        eventsSection
                    }
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 10)
        }
    }

    private var headerCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    leagueBadgeView(
                        url: safeURL(fixture?.league?.flag) ?? safeURL(fixture?.league?.logo),
                        fallbackText: String(competitionName.prefix(1)).uppercased()
                    )
                    Text(competitionName)
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white.opacity(0.90))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                )

                Spacer(minLength: 0)
                statusChip(label: currentStatusText)
            }

            HStack(spacing: 10) {
                teamColumn(name: awayTeamName, logoURL: awayTeamLogoURL)
                centerScoreColumn
                teamColumn(name: homeTeamName, logoURL: homeTeamLogoURL)
            }
            .environment(\.layoutDirection, .leftToRight)

            HStack(spacing: 8) {
                infoChip(symbol: "mappin.and.ellipse", text: venueText)
                infoChip(symbol: "clock.fill", text: kickoffTimeText)
                infoChip(symbol: "calendar", text: kickoffDateText)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(glassCardBackground(cornerRadius: 24))
        .shadow(color: .black.opacity(0.16), radius: 10, x: 0, y: 6)
    }

    private var centerScoreColumn: some View {
        VStack(spacing: 5) {
            if shouldShowKickoffInCenter {
                Text(kickoffTimeText)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
            } else {
                HStack(spacing: 5) {
                    Text(awayScoreText)
                    Text("-")
                    Text(homeScoreText)
                }
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
            }

            if let elapsed = fixture?.fixture?.status?.elapsed, elapsed > 0 {
                Text("\(elapsed)'")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Color(hex: 0xFF9F7D))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(hex: 0x4A241E).opacity(0.88))
                    )
            }
        }
        .frame(minWidth: 86)
    }

    private var lineupSection: some View {
        sectionCard(title: t(ar: "التشكيلة الأساسية", en: "Starting Lineups"), icon: "person.3.fill") {
            let awayPlayers = players(from: awayLineup?.startXI)
            let homePlayers = players(from: homeLineup?.startXI)

            if awayPlayers.isEmpty && homePlayers.isEmpty {
                Text(t(ar: "لا توجد تشكيلة متاحة حالياً", en: "No lineup available right now"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 12) {
                    if !awayPlayers.isEmpty {
                        lineupPitchTeamCard(
                            teamName: awayTeamName,
                            formation: cleanedText(awayLineup?.formation),
                            players: awayPlayers,
                            goalkeeperAtBottom: false
                        )
                    }

                    if !homePlayers.isEmpty {
                        lineupPitchTeamCard(
                            teamName: homeTeamName,
                            formation: cleanedText(homeLineup?.formation),
                            players: homePlayers,
                            goalkeeperAtBottom: true
                        )
                    }
                }
            }
        }
    }

    private var substitutesSection: some View {
        sectionCard(title: t(ar: "البدلاء", en: "Substitutes"), icon: "person.2.wave.2.fill") {
            VStack(spacing: 9) {
                lineupTeamCard(
                    teamName: awayTeamName,
                    formation: nil,
                    players: players(from: awayLineup?.substitutes),
                    emptyMessage: nil
                )
                lineupTeamCard(
                    teamName: homeTeamName,
                    formation: nil,
                    players: players(from: homeLineup?.substitutes),
                    emptyMessage: nil
                )
            }
        }
    }

    private var coachesSection: some View {
        sectionCard(title: t(ar: "المدربون", en: "Coaches"), icon: "person.crop.square.fill") {
            VStack(spacing: 8) {
                ForEach(Array(coachRows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 8) {
                        coachAvatar(name: row.coachName, photoURL: row.coachPhotoURL)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.coachName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text(row.teamName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.72))
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
                }
            }
        }
    }

    private var statisticsSection: some View {
        sectionCard(title: t(ar: "الإحصائيات", en: "Statistics"), icon: "chart.bar.xaxis") {
            VStack(spacing: 8) {
                HStack {
                    Text(awayTeamName)
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white.opacity(0.84))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Spacer(minLength: 0)
                    Text(homeTeamName)
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white.opacity(0.84))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .environment(\.layoutDirection, .leftToRight)

                ForEach(Array(statisticsRows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 6) {
                        Text(row.awayValue)
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(Color(hex: 0x8CD2FF))
                            .frame(minWidth: 44, alignment: .leading)

                        Text(row.type)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.86))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Text(row.homeValue)
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(Color(hex: 0x8CD2FF))
                            .frame(minWidth: 44, alignment: .trailing)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
                    .environment(\.layoutDirection, .leftToRight)
                }
            }
        }
    }

    private var eventsSection: some View {
        sectionCard(title: t(ar: "أحداث المباراة", en: "Match Events"), icon: "list.bullet.rectangle.portrait.fill") {
            VStack(spacing: 8) {
                ForEach(Array(orderedEvents.enumerated()), id: \.offset) { _, event in
                    eventRow(event)
                }
            }
        }
    }

    private func eventRow(_ event: FixtureEventItem) -> some View {
        HStack(spacing: 10) {
            Text(eventMinuteText(event))
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(eventTint(for: event))
                .frame(width: 48, alignment: .leading)

            Image(systemName: eventIcon(for: event))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(eventTint(for: event))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(eventPrimaryText(event))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if let secondary = eventSecondaryText(event) {
                    Text(secondary)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.70))
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .environment(\.layoutDirection, .leftToRight)
    }

    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: isRTL ? .trailing : .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(Color(hex: 0x9FD7FF))
                Text(title)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white.opacity(0.92))
                Spacer(minLength: 0)
            }
            .environment(\.layoutDirection, .leftToRight)

            content()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(glassCardBackground(cornerRadius: 22))
        .shadow(color: .black.opacity(0.14), radius: 9, x: 0, y: 5)
    }

    private func lineupPitchTeamCard(
        teamName: String,
        formation: String?,
        players: [FixtureLineupPlayer],
        goalkeeperAtBottom: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(teamName)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 0)

                Text(formation ?? "--")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(Color(hex: 0xA5E6FF))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color(hex: 0x163A5F).opacity(0.88))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.18), lineWidth: 0.9)
                    )
            }
            .environment(\.layoutDirection, .leftToRight)

            LineupPitchView(
                teamName: teamName,
                formation: formation,
                players: players,
                goalkeeperAtBottom: goalkeeperAtBottom
            )
            .frame(height: 332)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.8)
                )
        )
    }

    private func lineupTeamCard(teamName: String, formation: String?, players: [FixtureLineupPlayer], emptyMessage: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(teamName)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white.opacity(0.90))
                    .lineLimit(1)

                if let formation {
                    Text(formation)
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(Color(hex: 0x9FD7FF))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(hex: 0x17355B).opacity(0.86))
                        )
                }

                Spacer(minLength: 0)
            }
            .environment(\.layoutDirection, .leftToRight)

            if players.isEmpty {
                if let emptyMessage {
                    Text(emptyMessage)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.70))
                } else {
                    Text(t(ar: "لا توجد تشكيلة متاحة حالياً", en: "No lineup available right now"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.70))
                }
            } else {
                VStack(spacing: 4) {
                    ForEach(Array(players.enumerated()), id: \.offset) { _, player in
                        HStack(spacing: 6) {
                            if let number = player.number {
                                Text("#\(number)")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(Color(hex: 0x9FD7FF))
                                    .frame(width: 30, alignment: .leading)
                            }
                            Text(cleanedText(player.name) ?? "--")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.86))
                                .lineLimit(1)

                            Spacer(minLength: 0)

                            if let position = cleanedText(player.pos) {
                                Text(position)
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(.white.opacity(0.68))
                            }
                        }
                        .environment(\.layoutDirection, .leftToRight)
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }

    private func coachAvatar(name: String, photoURL: URL?) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x375193), Color(hex: 0x253B6E)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Circle()
                .stroke(Color.white.opacity(0.24), lineWidth: 0.9)

            if let photoURL {
                CachedRemoteImage(url: photoURL, contentMode: .fill) {
                    Text(teamInitials(name))
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white.opacity(0.92))
                }
                .frame(width: 30, height: 30)
                .clipShape(Circle())
            } else {
                Text(teamInitials(name))
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white.opacity(0.92))
            }
        }
        .frame(width: 34, height: 34)
    }

    private func teamColumn(name: String, logoURL: URL?) -> some View {
        VStack(spacing: 6) {
            teamLogoView(name: name, logoURL: logoURL)
            Text(name)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.70)
        }
        .frame(maxWidth: .infinity)
    }

    private func teamLogoView(name: String, logoURL: URL?) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x385395), Color(hex: 0x253767)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Circle()
                .stroke(Color.white.opacity(0.24), lineWidth: 0.9)

            if let logoURL {
                CachedRemoteImage(url: logoURL, contentMode: .fill) {
                    Text(teamInitials(name))
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white.opacity(0.92))
                }
                .frame(width: 34, height: 34)
                .clipShape(Circle())
            } else {
                Text(teamInitials(name))
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.92))
            }
        }
        .frame(width: 38, height: 38)
    }

    private func infoChip(symbol: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
            Text(text)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(.white.opacity(0.78))
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.10))
        )
    }

    private func statusChip(label: String) -> some View {
        let upperLabel = label.uppercased()
        let tint: Color
        let background: Color

        switch upperLabel {
        case "LIVE":
            tint = Color(hex: 0xFF5A57)
            background = Color(hex: 0x451616)
        case "HALF TIME", "HT":
            tint = Color(hex: 0xFFB347)
            background = Color(hex: 0x4A2E14)
        case "MATCH FINISHED", "FT":
            tint = Color(hex: 0x9AA4FF)
            background = Color(hex: 0x232A56)
        case "POSTPONED", "PST":
            tint = Color(hex: 0xC7CBE9)
            background = Color(hex: 0x2F3353)
        case "CANCELLED", "CANC":
            tint = Color(hex: 0xE1A9B8)
            background = Color(hex: 0x47232E)
        default:
            tint = Color(hex: 0x82D0FF)
            background = Color(hex: 0x17355B)
        }

        return Text(label)
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(background.opacity(0.92))
            )
            .overlay(
                Capsule()
                    .stroke(tint.opacity(0.50), lineWidth: 0.9)
            )
    }

    private func topIconButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            topIconButtonLabel(symbol: symbol)
        }
        .buttonStyle(.plain)
    }

    private func topIconButtonLabel(symbol: String) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0x2A1850).opacity(0.84))
            Circle()
                .stroke(Color(hex: 0x8A73D4).opacity(0.44), lineWidth: 0.9)

            Image(systemName: symbol)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(width: 34, height: 34)
        .shadow(color: Color(hex: 0x6E58B8).opacity(0.24), radius: 8, x: 0, y: 4)
    }

    private func glassCardBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(hex: 0x291A5D).opacity(0.94), Color(hex: 0x1E356F).opacity(0.90)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.10), .clear, Color.black.opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 0.9)
            )
    }

    private func leagueBadgeView(url: URL?, fallbackText: String) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 16, height: 16)

            if let url {
                CachedRemoteImage(url: url, contentMode: .fill) {
                    Text(fallbackText)
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(width: 14, height: 14)
                .clipShape(Circle())
            } else {
                Text(fallbackText)
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    private func eventMinuteText(_ event: FixtureEventItem) -> String {
        let elapsed = event.time?.elapsed ?? 0
        let extra = event.time?.extra ?? 0
        if elapsed <= 0 { return "--" }
        if extra > 0 {
            return "\(elapsed)+\(extra)'"
        }
        return "\(elapsed)'"
    }

    private func eventPrimaryText(_ event: FixtureEventItem) -> String {
        if let detail = cleanedText(event.detail) {
            return detail
        }
        if let type = cleanedText(event.type) {
            return type
        }
        return t(ar: "حدث", en: "Event")
    }

    private func eventSecondaryText(_ event: FixtureEventItem) -> String? {
        var fragments: [String] = []

        if let team = cleanedText(event.team?.name) {
            fragments.append(team)
        }
        if let player = cleanedText(event.player?.name) {
            fragments.append(player)
        }
        if let assist = cleanedText(event.assist?.name) {
            fragments.append("Assist: \(assist)")
        }
        if let comments = cleanedText(event.comments) {
            fragments.append(comments)
        }

        guard !fragments.isEmpty else { return nil }
        return fragments.joined(separator: " • ")
    }

    private func eventIcon(for event: FixtureEventItem) -> String {
        let key = "\(cleanedText(event.type) ?? "") \(cleanedText(event.detail) ?? "")".uppercased()
        if key.contains("GOAL") {
            return "soccerball"
        }
        if key.contains("YELLOW") {
            return "rectangle.fill"
        }
        if key.contains("RED") {
            return "rectangle.fill"
        }
        if key.contains("SUBST") {
            return "arrow.triangle.2.circlepath"
        }
        return "circle.fill"
    }

    private func eventTint(for event: FixtureEventItem) -> Color {
        let key = "\(cleanedText(event.type) ?? "") \(cleanedText(event.detail) ?? "")".uppercased()
        if key.contains("GOAL") {
            return Color(hex: 0x86FFB0)
        }
        if key.contains("YELLOW") {
            return Color(hex: 0xFFD166)
        }
        if key.contains("RED") {
            return Color(hex: 0xFF6B7A)
        }
        if key.contains("SUBST") {
            return Color(hex: 0x8DD5FF)
        }
        return Color(hex: 0xCFD7FF)
    }

    private func players(from source: [FixtureLineupMember]?) -> [FixtureLineupPlayer] {
        guard let source else { return [] }
        return source.compactMap(\.player)
    }

    private func lineup(for teamID: Int?) -> FixtureLineup? {
        guard let teamID else { return nil }
        return viewModel.lineups.first { $0.team?.id == teamID }
    }

    private func statistics(for teamID: Int?) -> FixtureTeamStatistics? {
        guard let teamID else { return nil }
        return viewModel.statistics.first { $0.team?.id == teamID }
    }

    private func orderedUniqueTypes(from source: [String]) -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []

        for item in source {
            if seen.insert(item).inserted {
                ordered.append(item)
            }
        }

        return ordered
    }

    private func statisticValueText(_ value: FixtureStatisticValue?) -> String {
        guard let value else { return "--" }
        let text = value.text.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? "--" : text
    }

    private func cleanedText(_ value: String?) -> String? {
        guard let value else { return nil }
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    private func safeURL(_ raw: String?) -> URL? {
        guard let cleaned = cleanedText(raw) else { return nil }
        return URL(string: cleaned)
    }

    private func teamInitials(_ name: String) -> String {
        let words = name.split(separator: " ")
        if let first = words.first, let second = words.dropFirst().first {
            return "\(first.prefix(1))\(second.prefix(1))".uppercased()
        }
        return String(words.first?.prefix(2) ?? "TM").uppercased()
    }
}

private struct MatchStatisticDisplayRow {
    let type: String
    let awayValue: String
    let homeValue: String
}

private struct MatchCoachRow {
    let teamName: String
    let coachName: String
    let coachPhotoURL: URL?
}

private enum MatchDetailsDateParsers {
    static let isoWithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let isoStandard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func timeFormatter(localeIdentifier: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    static func dateFormatter(localeIdentifier: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.timeZone = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

private struct LineupPitchView: View {
    let teamName: String
    let formation: String?
    let players: [FixtureLineupPlayer]
    let goalkeeperAtBottom: Bool
    let onPlayerTap: ((FixtureLineupPlayer) -> Void)?

    init(
        teamName: String,
        formation: String?,
        players: [FixtureLineupPlayer],
        goalkeeperAtBottom: Bool,
        onPlayerTap: ((FixtureLineupPlayer) -> Void)? = nil
    ) {
        self.teamName = teamName
        self.formation = formation
        self.players = players
        self.goalkeeperAtBottom = goalkeeperAtBottom
        self.onPlayerTap = onPlayerTap
    }

    private var plottedPlayers: [LineupPitchPlottedPlayer] {
        guard !players.isEmpty else { return [] }

        let indexedPlayers = Array(players.enumerated())
        let fallbackPoints = fallbackCoordinates(for: players, formation: formation, goalkeeperAtBottom: goalkeeperAtBottom)

        let allGridRows = indexedPlayers.compactMap { parseGrid($0.element.grid)?.row }
        let allGridColumns = indexedPlayers.compactMap { parseGrid($0.element.grid)?.column }
        let hasGridData = !allGridRows.isEmpty && !allGridColumns.isEmpty
        let maxGridRow = max(allGridRows.max() ?? 1, 1)
        let maxGridColumn = max(allGridColumns.max() ?? 1, 1)

        return indexedPlayers.map { index, player in
            let fallback = fallbackPoints[index] ?? LineupPitchPoint(x: 0.5, y: 0.5)

            let point: LineupPitchPoint
            if hasGridData, let parsedGrid = parseGrid(player.grid) {
                var y = Double(parsedGrid.row) / Double(maxGridRow + 1)
                if goalkeeperAtBottom {
                    y = 1 - y
                }
                point = LineupPitchPoint(
                    x: Double(parsedGrid.column) / Double(maxGridColumn + 1),
                    y: y
                )
            } else {
                point = fallback
            }

            return LineupPitchPlottedPlayer(
                id: "lineup-\(index)-\(player.id ?? -1)-\(player.number ?? -1)",
                player: player,
                x: clampX(point.x),
                y: clampY(point.y)
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                pitchBackground

                ForEach(plottedPlayers) { plotted in
                    playerNode(plotted)
                        .position(
                            x: plotted.x * geo.size.width,
                            y: plotted.y * geo.size.height
                        )
                }
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 0.9)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 5)
    }

    @ViewBuilder
    private func playerNode(_ plotted: LineupPitchPlottedPlayer) -> some View {
        if let onPlayerTap {
            Button {
                onPlayerTap(plotted.player)
            } label: {
                PlayerBubbleView(
                    playerName: cleanedText(plotted.player.name) ?? "--",
                    number: plotted.player.number,
                    photoURL: playerPhotoURL(for: plotted.player)
                )
            }
            .buttonStyle(.plain)
        } else {
            PlayerBubbleView(
                playerName: cleanedText(plotted.player.name) ?? "--",
                number: plotted.player.number,
                photoURL: playerPhotoURL(for: plotted.player)
            )
        }
    }

    private var pitchBackground: some View {
        GeometryReader { geo in
            let size = geo.size
            let horizontalInset = max(10, size.width * 0.03)
            let verticalInset = max(10, size.height * 0.03)
            let fieldRect = CGRect(
                x: horizontalInset,
                y: verticalInset,
                width: size.width - (horizontalInset * 2),
                height: size.height - (verticalInset * 2)
            )

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x0C7A3A), Color(hex: 0x0A5F2E), Color(hex: 0x0C7A3A)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Grass bands for better pitch depth.
                HStack(spacing: 0) {
                    ForEach(0..<10, id: \.self) { index in
                        Rectangle()
                            .fill(index.isMultiple(of: 2) ? Color.white.opacity(0.045) : Color.clear)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Path { path in
                    path.addRoundedRect(in: fieldRect, cornerSize: CGSize(width: 12, height: 12))

                    let middleY = fieldRect.midY
                    path.move(to: CGPoint(x: fieldRect.minX, y: middleY))
                    path.addLine(to: CGPoint(x: fieldRect.maxX, y: middleY))

                    let centerCircleDiameter = min(fieldRect.width * 0.26, fieldRect.height * 0.20)
                    let centerCircleRect = CGRect(
                        x: fieldRect.midX - centerCircleDiameter / 2,
                        y: middleY - centerCircleDiameter / 2,
                        width: centerCircleDiameter,
                        height: centerCircleDiameter
                    )
                    path.addEllipse(in: centerCircleRect)

                    let penaltyWidth = fieldRect.width * 0.56
                    let penaltyHeight = fieldRect.height * 0.16
                    let topPenaltyRect = CGRect(
                        x: fieldRect.midX - penaltyWidth / 2,
                        y: fieldRect.minY,
                        width: penaltyWidth,
                        height: penaltyHeight
                    )
                    let bottomPenaltyRect = CGRect(
                        x: fieldRect.midX - penaltyWidth / 2,
                        y: fieldRect.maxY - penaltyHeight,
                        width: penaltyWidth,
                        height: penaltyHeight
                    )
                    path.addRect(topPenaltyRect)
                    path.addRect(bottomPenaltyRect)

                    let goalBoxWidth = fieldRect.width * 0.28
                    let goalBoxHeight = fieldRect.height * 0.075
                    let topGoalBoxRect = CGRect(
                        x: fieldRect.midX - goalBoxWidth / 2,
                        y: fieldRect.minY,
                        width: goalBoxWidth,
                        height: goalBoxHeight
                    )
                    let bottomGoalBoxRect = CGRect(
                        x: fieldRect.midX - goalBoxWidth / 2,
                        y: fieldRect.maxY - goalBoxHeight,
                        width: goalBoxWidth,
                        height: goalBoxHeight
                    )
                    path.addRect(topGoalBoxRect)
                    path.addRect(bottomGoalBoxRect)
                }
                .stroke(Color.white.opacity(0.48), lineWidth: 1.2)

                Circle()
                    .fill(Color.white.opacity(0.70))
                    .frame(width: 4, height: 4)
                    .position(x: fieldRect.midX, y: fieldRect.midY)

                Circle()
                    .fill(Color.white.opacity(0.50))
                    .frame(width: 3.2, height: 3.2)
                    .position(x: fieldRect.midX, y: fieldRect.minY + fieldRect.height * 0.11)

                Circle()
                    .fill(Color.white.opacity(0.50))
                    .frame(width: 3.2, height: 3.2)
                    .position(x: fieldRect.midX, y: fieldRect.maxY - fieldRect.height * 0.11)
            }
        }
    }

    private func playerPhotoURL(for player: FixtureLineupPlayer) -> URL? {
        if let cleanedPhoto = cleanedText(player.photo), let url = URL(string: cleanedPhoto) {
            return url
        }

        if let id = player.id, id > 0 {
            return URL(string: "https://media.api-sports.io/football/players/\(id).png")
        }

        return nil
    }

    private func fallbackCoordinates(
        for players: [FixtureLineupPlayer],
        formation: String?,
        goalkeeperAtBottom: Bool
    ) -> [Int: LineupPitchPoint] {
        guard !players.isEmpty else { return [:] }

        let goalkeeperIndex = detectGoalkeeperIndex(in: players)
        let orderedIndices = [goalkeeperIndex] + players.indices.filter { $0 != goalkeeperIndex }

        var rowCounts = [1] + parsedFormationRows(from: formation)
        if rowCounts.count == 1 {
            rowCounts.append(contentsOf: [4, 4, 2])
        }

        var totalSlots = rowCounts.reduce(0, +)
        if totalSlots < players.count {
            rowCounts[rowCounts.count - 1] += (players.count - totalSlots)
            totalSlots = rowCounts.reduce(0, +)
        } else if totalSlots > players.count {
            var overflow = totalSlots - players.count
            for rowIndex in stride(from: rowCounts.count - 1, through: 1, by: -1) {
                guard overflow > 0 else { break }
                let reduction = min(overflow, max(0, rowCounts[rowIndex] - 1))
                rowCounts[rowIndex] -= reduction
                overflow -= reduction
            }
        }

        var result: [Int: LineupPitchPoint] = [:]
        var cursor = 0

        for (rowIndex, rowCount) in rowCounts.enumerated() {
            guard rowCount > 0 else { continue }
            let upperBound = min(cursor + rowCount, orderedIndices.count)
            guard cursor < upperBound else { break }

            let rowPlayers = Array(orderedIndices[cursor..<upperBound])
            let rawY = Double(rowIndex + 1) / Double(rowCounts.count + 1)
            let y = goalkeeperAtBottom ? (1 - rawY) : rawY

            for (slotIndex, originalIndex) in rowPlayers.enumerated() {
                let x = Double(slotIndex + 1) / Double(rowPlayers.count + 1)
                result[originalIndex] = LineupPitchPoint(x: x, y: y)
            }
            cursor = upperBound
        }

        return result
    }

    private func parsedFormationRows(from formation: String?) -> [Int] {
        guard let formation = cleanedText(formation) else {
            return [4, 4, 2]
        }

        let numbers = formation
            .split(whereSeparator: { !$0.isNumber })
            .compactMap { Int($0) }
            .filter { $0 > 0 }

        return numbers.isEmpty ? [4, 4, 2] : numbers
    }

    private func detectGoalkeeperIndex(in players: [FixtureLineupPlayer]) -> Int {
        if let idx = players.firstIndex(where: { player in
            let normalizedPos = cleanedText(player.pos)?.uppercased() ?? ""
            return normalizedPos == "G" || normalizedPos == "GK"
        }) {
            return idx
        }

        if let idx = players.firstIndex(where: { player in
            guard let grid = parseGrid(player.grid) else { return false }
            return grid.row == 1
        }) {
            return idx
        }

        if let idx = players.firstIndex(where: { $0.number == 1 }) {
            return idx
        }

        return 0
    }

    private func parseGrid(_ value: String?) -> (row: Int, column: Int)? {
        guard let cleaned = cleanedText(value) else { return nil }
        let parts = cleaned.split(separator: ":")
        guard parts.count == 2,
              let row = Int(parts[0]),
              let column = Int(parts[1]),
              row > 0,
              column > 0 else {
            return nil
        }
        return (row, column)
    }

    private func clampX(_ value: Double) -> CGFloat {
        CGFloat(min(max(value, 0.10), 0.90))
    }

    private func clampY(_ value: Double) -> CGFloat {
        CGFloat(min(max(value, 0.13), 0.87))
    }

    private func cleanedText(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct PlayerBubbleView: View {
    let playerName: String
    let number: Int?
    let photoURL: URL?

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0x344B7D), Color(hex: 0x1E2C56)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Circle()
                        .stroke(Color.white.opacity(0.28), lineWidth: 0.9)

                    if let photoURL {
                        CachedRemoteImage(url: photoURL, contentMode: .fill) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(.white.opacity(0.88))
                        }
                        .frame(width: 38, height: 38)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(.white.opacity(0.88))
                    }
                }
                .frame(width: 42, height: 42)
                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)

                if let number {
                    Text("\(number)")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.black.opacity(0.88))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(hex: 0xD9FF66))
                        )
                        .offset(x: 8, y: -7)
                }
            }

            Text(playerName)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .frame(width: 78)
        }
        .frame(width: 80)
        .environment(\.layoutDirection, .leftToRight)
    }
}

private struct LineupPitchPlottedPlayer: Identifiable {
    let id: String
    let player: FixtureLineupPlayer
    let x: CGFloat
    let y: CGFloat
}

private struct LineupPitchPoint {
    let x: Double
    let y: Double
}

private struct MatchTeamVisualSlot {
    let name: String
    let logoURL: URL?
    let score: String
}

private struct MatchCardViewData {
    let leadingTeam: MatchTeamVisualSlot
    let trailingTeam: MatchTeamVisualSlot
    let leadingScore: String
    let trailingScore: String
}

private struct GuideView: View {
    @Environment(\.dismiss) private var dismiss
    let language: AppLanguage

    private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.10, blue: 0.22), Color(red: 0.02, green: 0.20, blue: 0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.backward")
                                Text(t(ar: "رجوع", en: "Back", hi: "वापस", zh: "返回", ku: "گەڕانەوە"))
                            }
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.14))
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }

                    Text(t(ar: "عن اللعبة", en: "About the Game", hi: "खेल के बारे में", zh: "关于这款游戏", ku: "دەربارەی یارییەکە"))
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    guideCard(
                        t(
                            ar: "هذه اللعبة تأخذك إلى عالم التدريب خطوة بخطوة. تختار فريقك، تدير الموسم، تراقب النتائج، وتعيش تفاصيل القرار مثل مدرب حقيقي يبحث عن المجد مباراة بعد مباراة.",
                            en: "This game puts you inside the life of a football coach. You choose your team, manage the season, follow results, and live every decision like a real manager chasing glory match after match.",
                            hi: "यह खेल आपको फुटबॉल कोच की दुनिया के भीतर ले जाता है। आप अपनी टीम चुनते हैं, पूरे सीज़न को संभालते हैं, नतीजों पर नज़र रखते हैं और हर फैसले को असली मैनेजर की तरह जीते हैं।",
                            zh: "这款游戏带你进入足球教练的真实节奏。你要选择球队、管理赛季、跟进结果，并像真正的主教练一样在每场比赛里追逐荣耀。",
                            ku: "ئەم یارییە تۆ دەباتە ناو ژیانی ڕاهێنەری تۆپی پێ. تیمەکەت هەڵدەبژێریت، وەرزەکە بەڕێوەدەبەیت، ئەنجامەکان چاودێری دەکەیت و وەک ڕاهێنەرێکی ڕاستەقینە بڕیار دەدەیت."
                        )
                    )

                    guideCard(
                        t(
                            ar: "فائدة اللعبة أنها تقوّي عندك حس التخطيط، الصبر، وقراءة الموقف. كل مباراة تعلّمك متى تهاجم، متى تغيّر الخطة، وكيف تبني فريقاً متوازناً يستطيع الاستمرار والنجاح.",
                            en: "The value of the game is in training your planning, patience, and game reading. Every match teaches you when to attack, when to adjust your plan, and how to build a balanced team that can keep winning.",
                            hi: "इस खेल की सबसे बड़ी फायदेमंद बात यह है कि यह योजना, धैर्य और मैच पढ़ने की समझ को मजबूत करता है। हर मैच सिखाता है कि कब आक्रमण करना है, कब रणनीति बदलनी है और कैसे संतुलित टीम बनानी है।",
                            zh: "这款游戏的意义在于锻炼你的规划能力、耐心和比赛阅读能力。每一场比赛都会让你学习何时进攻、何时调整战术，以及如何打造一支平衡且持续取胜的球队。",
                            ku: "سوودی یارییەکە لەوەدایە هەستی پلاندانان، ئارامی و تێگەیشتن لە یاری پەروەردە دەکات. هەر یارییەکت فێردەکات کەی هێرش بکەیت، کەی پلان بگۆڕیت و چۆن تیمێکی هاوسەنگ دروست بکەیت."
                        )
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text(t(ar: "صانع اللعبة", en: "Game Creator", hi: "गेम निर्माता", zh: "游戏制作者", ku: "دروستکەری یاری"))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white.opacity(0.75))
                        Text("Mustafa Raad")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                }
                .padding(22)
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }

    private func guideCard(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white.opacity(0.94))
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(FootballTheme.cardBase.opacity(0.58))
            )
    }
}

private struct LegalCenterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let language: AppLanguage

    private let privacyPolicyURL = URL(string: "https://www.termsfeed.com/live/e3bca448-7ab9-4826-b699-d0ffb2696881")
    private let supportPageURL = URL(string: "https://www.instagram.com/92weo?igsh=Nm5mbnlqcmcxaHht&utm_source=qr")
    private let supportEmailURL = URL(string: "mailto:mraad7723@gmail.com?subject=STACOACH%20Support")

    private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [FootballTheme.backgroundPrimary, FootballTheme.backgroundSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(FootballTheme.cardGlow.opacity(0.15))
                .frame(width: 260, height: 260)
                .blur(radius: 14)
                .offset(x: 120, y: -240)

            Circle()
                .fill(FootballTheme.accentCyan.opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 10)
                .offset(x: -120, y: 260)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.backward")
                                Text(t(ar: "رجوع", en: "Back", hi: "वापस", zh: "返回", ku: "گەڕانەوە"))
                            }
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.14))
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }

                    Text(t(ar: "القانون والخصوصية", en: "Legal & Privacy", hi: "कानूनी और गोपनीयता", zh: "法律与隐私", ku: "یاسا و نهێنی"))
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(t(ar: "قبل النشر على App Store، تأكد أن الروابط أدناه تستبدل بروابطك الحقيقية.", en: "Before App Store submission, replace the links below with your real links.", hi: "App Store पर भेजने से पहले नीचे दिए गए लिंक को अपने असली लिंक से बदलें।", zh: "提交 App Store 前，请将下方链接替换为你的真实链接。", ku: "پێش ناردن بۆ App Store، بەستەرەکانی خوارەوە بە بەستەری ڕاستەقینەی خۆت بگۆڕە."))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.78))

                    legalCard(
                        title: t(ar: "سياسة الخصوصية", en: "Privacy Policy", hi: "गोपनीयता नीति", zh: "隐私政策", ku: "سیاسەتی نهێنی"),
                        subtitle: t(ar: "شرح كامل للبيانات التي تُجمع وكيفية استخدامها.", en: "Full details about collected data and how it is used.", hi: "एकत्रित डेटा और उसके उपयोग का पूरा विवरण।", zh: "完整说明收集哪些数据以及如何使用。", ku: "ڕوونکردنەوەی تەواو لەسەر داتای کۆکراوە و چۆنیەتی بەکارهێنانی.")
                    ) {
                        legalActionButton(
                            title: t(ar: "فتح سياسة الخصوصية", en: "Open Privacy Policy", hi: "गोपनीयता नीति खोलें", zh: "打开隐私政策", ku: "سیاسەتی نهێنی بکەرەوە"),
                            icon: "lock.shield.fill",
                            url: privacyPolicyURL
                        )
                    }

                    legalCard(
                        title: t(ar: "الدعم", en: "Support", hi: "सपोर्ट", zh: "支持", ku: "پشتگیری"),
                        subtitle: t(ar: "قناة رسمية للاستفسارات والمشاكل الفنية.", en: "Official channel for questions and technical issues.", hi: "सवालों और तकनीकी समस्याओं के लिए आधिकारिक चैनल।", zh: "用于咨询与技术问题的官方渠道。", ku: "کەناڵی فەرمی بۆ پرسیار و کێشە تەکنیکییەکان.")
                    ) {
                        VStack(spacing: 10) {
                            legalActionButton(
                                title: t(ar: "فتح صفحة الدعم", en: "Open Support Page", hi: "सपोर्ट पेज खोलें", zh: "打开支持页面", ku: "پەڕەی پشتگیری بکەرەوە"),
                                icon: "questionmark.circle.fill",
                                url: supportPageURL
                            )
                            legalActionButton(
                                title: t(ar: "مراسلة الدعم بالبريد", en: "Email Support", hi: "ईमेल सपोर्ट", zh: "邮件联系支持", ku: "پۆستی ئەلیکترۆنی پشتگیری"),
                                icon: "envelope.fill",
                                url: supportEmailURL
                            )
                        }
                    }

                    legalCard(
                        title: t(ar: "إخلاء المسؤولية", en: "Disclaimer", hi: "अस्वीकरण", zh: "免责声明", ku: "ڕەتکردنەوەی بەرپرسیارێتی"),
                        subtitle: t(ar: "هذا النص يساعدك على تجنب ملاحظات حقوق الملكية أثناء المراجعة.", en: "This text helps reduce intellectual-property review issues.", hi: "यह पाठ बौद्धिक संपदा समीक्षा समस्याओं को कम करने में मदद करता है।", zh: "该说明可帮助降低知识产权审核问题。", ku: "ئەم دەقە یارمەتیدەرە بۆ کەمکردنەوەی کێشەکانی مافەکانی هزری لە پشکنینەوە.")
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• \(t(ar: "اللعبة غير تابعة رسميًا لأي نادي أو دوري.", en: "This game is not officially affiliated with any club or league.", hi: "यह गेम किसी क्लब या लीग से आधिकारिक रूप से संबद्ध नहीं है।", zh: "本游戏并非任何俱乐部或联赛的官方产品。", ku: "ئەم یارییە بە فەرمی سەر بە هیچ تیم یان لیگێک نییە."))")
                            Text("• \(t(ar: "الأسماء والعلامات التجارية تخصّ أصحابها الشرعيين.", en: "Names and trademarks belong to their legal owners.", hi: "नाम और ट्रेडमार्क उनके वैध मालिकों के हैं।", zh: "名称与商标归其合法权利人所有。", ku: "ناو و نیشانە بازرگانییەکان هی خاوەن مافە یاسایییەکانیانن."))")
                            Text("• \(t(ar: "بيانات المباريات مقدّمة من مزود طرف ثالث وقد تتأخر أو تختلف.", en: "Match data is provided by a third-party source and may be delayed or vary.", hi: "मैच डेटा तृतीय-पक्ष स्रोत से आता है और देर या भिन्न हो सकता है।", zh: "比赛数据来自第三方，可能存在延迟或差异。", ku: "داتای یارییەکان لەلایەن دابینکەری لایەنی سێیەمەوە دێت و لەوانەیە دواکەوتوو یان جیاواز بێت."))")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                    }
                }
                .padding(20)
                .padding(.bottom, 24)
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }

    private func legalCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 21, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.78))
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(FootballTheme.cardBase.opacity(0.64))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(FootballTheme.cardGlow.opacity(0.20), lineWidth: 1)
        )
    }

    private func legalActionButton(title: String, icon: String, url: URL?) -> some View {
        Button {
            guard let url else { return }
            openURL(url)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                Spacer()
                Image(systemName: "arrow.up.right.square.fill")
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [FootballTheme.backgroundSecondary.opacity(0.88), FootballTheme.cardBase.opacity(0.94)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(url == nil)
    }
}

private struct PlayerSearchView: View {
    @Environment(\.dismiss) private var dismiss

    let language: AppLanguage
    @Binding var players: [MarketPlayer]
    let budgetM: Int
    let onNegotiatePlayer: (Int) -> Void

    @State private var query = ""

    private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextField(t(ar: "اكتب اسم اللاعب", en: "Type the player name", hi: "खिलाड़ी का नाम लिखें", zh: "输入球员名字", ku: "ناوی یاریزان بنووسە"), text: $query)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 4)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(filteredIndices(), id: \.self) { idx in
                            let player = players[idx]
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(localizedDisplayName(player.name, in: language))
                                        .font(.system(size: 18, weight: .black))
                                    Text("\(t(ar: "القيمة", en: "Value", hi: "मूल्य", zh: "身价", ku: "نرخ")): $\(player.costM)M | \(t(ar: "قوة", en: "Strength", hi: "ताकत", zh: "实力", ku: "هێز")) +\(player.boost)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button(player.signed
                                       ? t(ar: "تم", en: "Done", hi: "हो गया", zh: "完成", ku: "تەواو")
                                       : t(ar: "تفاوض", en: "Negotiate", hi: "बातचीत", zh: "谈判", ku: "دانوستان")) {
                                    onNegotiatePlayer(idx)
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(player.signed ? FootballTheme.muted : (budgetM >= player.costM ? FootballTheme.pitchGreen : FootballTheme.dangerRed))
                                .clipShape(Capsule())
                                .disabled(player.signed || budgetM < player.costM)
                            }
                            .padding()
                            .background(FootballTheme.cardBase.opacity(0.30))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            .padding()
            .navigationTitle(t(ar: "بحث لاعب", en: "Player Search", hi: "खिलाड़ी खोज", zh: "球员搜索", ku: "گەڕانی یاریزان"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(t(ar: "إغلاق", en: "Close", hi: "बंद करें", zh: "关闭", ku: "داخستن")) { dismiss() }
                }
            }
        }
    }

    private func filteredIndices() -> [Int] {
        let cleaned = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return players.indices.filter { idx in
            let name = localizedDisplayName(players[idx].name, in: language)
            return cleaned.isEmpty || name.localizedCaseInsensitiveContains(cleaned) || players[idx].name.localizedCaseInsensitiveContains(cleaned)
        }
    }
}

private struct ContractNegotiationView: View {
    let language: AppLanguage
    let player: MarketPlayer
    let budgetM: Int
    let onSubmit: (Int, Int, Int) -> Void
    let onCancel: () -> Void

    @State private var salaryM: Int
    @State private var years: Int
    @State private var bonusM: Int

    init(
        language: AppLanguage,
        player: MarketPlayer,
        budgetM: Int,
        onSubmit: @escaping (Int, Int, Int) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.language = language
        self.player = player
        self.budgetM = budgetM
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        _salaryM = State(initialValue: max(3, player.costM / 16))
        _years = State(initialValue: 3)
        _bonusM = State(initialValue: max(1, player.costM / 22))
    }

    private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
    }

    private var totalPackage: Int {
        player.costM + (salaryM * years) + bonusM
    }

    private var acceptancePercent: Int {
        let desiredSalary = max(3, player.costM / 16)
        let desiredBonus = max(1, player.costM / 22)
        let yearsImpact = max(-2, min(6, (years - 3) * 2))
        let salaryImpact = (salaryM - desiredSalary) * 8
        let bonusImpact = (bonusM - desiredBonus) * 6
        return max(20, min(94, 50 + yearsImpact + salaryImpact + bonusImpact))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Text("\(t(ar: "مفاوضات عقد", en: "Contract Negotiation", hi: "अनुबंध बातचीत", zh: "合同谈判", ku: "دانوستانی گرێبەست")): \(localizedDisplayName(player.name, in: language))")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 10) {
                    negotiationRow(t(ar: "رسوم الصفقة", en: "Transfer Fee", hi: "ट्रांसफ़र शुल्क", zh: "转会费", ku: "پارەی گواستنەوە"), "$\(player.costM)M")
                    negotiationRow(t(ar: "راتب سنوي", en: "Annual Salary", hi: "वार्षिक वेतन", zh: "年薪", ku: "مووچەی ساڵانە"), "$\(salaryM)M")
                    negotiationRow(t(ar: "مدة العقد", en: "Contract Length", hi: "अनुबंध अवधि", zh: "合同期限", ku: "ماوەی گرێبەست"), "\(years) \(t(ar: "سنوات", en: "years", hi: "साल", zh: "年", ku: "ساڵ"))")
                    negotiationRow(t(ar: "مكافأة توقيع", en: "Signing Bonus", hi: "साइनिंग बोनस", zh: "签字费", ku: "بۆنسی واژۆ"), "$\(bonusM)M")
                    negotiationRow(t(ar: "قيمة العقد الكلية", en: "Total Package", hi: "कुल पैकेज", zh: "合同总额", ku: "کۆی گرێبەست"), "$\(totalPackage)M")
                    negotiationRow(t(ar: "نسبة القبول", en: "Acceptance Rate", hi: "स्वीकृति दर", zh: "接受概率", ku: "ڕێژەی قبووڵکردن"), "\(acceptancePercent)%")
                }

                VStack(spacing: 10) {
                    HStack {
                        Text(t(ar: "الراتب السنوي", en: "Annual Salary", hi: "वार्षिक वेतन", zh: "年薪", ku: "مووچەی ساڵانە"))
                        Spacer()
                        Stepper("", value: $salaryM, in: 1...25)
                    }

                    HStack {
                        Text(t(ar: "سنوات العقد", en: "Contract Years", hi: "अनुबंध के साल", zh: "合同年限", ku: "ساڵانی گرێبەست"))
                        Spacer()
                        Stepper("", value: $years, in: 1...5)
                    }

                    HStack {
                        Text(t(ar: "مكافأة التوقيع", en: "Signing Bonus", hi: "साइनिंग बोनस", zh: "签字费", ku: "بۆنسی واژۆ"))
                        Spacer()
                        Stepper("", value: $bonusM, in: 0...20)
                    }
                }
                .font(.system(size: 16, weight: .bold))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(FootballTheme.cardBase.opacity(0.30))
                )

                Button {
                    onSubmit(salaryM, years, bonusM)
                } label: {
                    Text(totalPackage <= budgetM
                         ? t(ar: "إرسال العرض", en: "Send Offer", hi: "ऑफ़र भेजें", zh: "提交报价", ku: "پێشنیار بنێرە")
                         : t(ar: "الميزانية لا تكفي", en: "Budget Too Low", hi: "बजट पर्याप्त नहीं", zh: "预算不足", ku: "بودجە بەس نییە"))
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(totalPackage <= budgetM ? FootballTheme.pitchGreen : FootballTheme.muted)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(totalPackage > budgetM)

                Button(t(ar: "إلغاء", en: "Cancel", hi: "रद्द करें", zh: "取消", ku: "هەڵوەشاندنەوە")) {
                    onCancel()
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(FootballTheme.dangerRed)

                Spacer()
            }
            .padding()
        }
    }

    private func negotiationRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(value)
                .font(.system(size: 16, weight: .black))
            Spacer()
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}

private struct TeamRecordView: View {
    @Environment(\.dismiss) private var dismiss

    let language: AppLanguage
    let teamName: String
    let wins: Int
    let losses: Int
    let draws: Int
    let titles: Int
    let goalsFor: Int
    let goalsAgainst: Int
    let coachAwards: Int
    let goldenBoots: Int
    let topScorerName: String
    let topScorerGoals: Int
    let achievements: [String]

    private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.10, blue: 0.22), Color(red: 0.02, green: 0.18, blue: 0.32)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Button(t(ar: "إغلاق", en: "Close", hi: "बंद करें", zh: "关闭", ku: "داخستن")) { dismiss() }
                        .font(.system(size: 15, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())

                    Spacer()

                    Text("\(t(ar: "سجل", en: "Record", hi: "रिकॉर्ड", zh: "战绩", ku: "تۆمار")) \(localizedDisplayName(teamName, in: language))")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    recordCard(t(ar: "عدد الفوز", en: "Wins", hi: "जीत", zh: "胜场", ku: "برد"), "\(wins)", color: .green)
                    recordCard(t(ar: "عدد الخسارة", en: "Losses", hi: "हार", zh: "负场", ku: "دۆڕان"), "\(losses)", color: .red)
                    recordCard(t(ar: "عدد التعادل", en: "Draws", hi: "ड्रॉ", zh: "平局", ku: "یەکسان"), "\(draws)", color: .orange)
                    recordCard(t(ar: "عدد البطولات", en: "Titles", hi: "खिताब", zh: "冠军数", ku: "پاڵەوانی"), "\(titles)", color: FootballTheme.pointsYellow)
                    recordCard(t(ar: "عدد الأهداف", en: "Goals For", hi: "किए गए गोल", zh: "进球数", ku: "گۆڵ بۆ"), "\(goalsFor)", color: .blue)
                    recordCard(t(ar: "استقبال الأهداف", en: "Goals Against", hi: "खाए गए गोल", zh: "失球数", ku: "گۆڵ لەسەر"), "\(goalsAgainst)", color: .pink)
                    recordCard(t(ar: "مدرب الشهر", en: "Coach Awards", hi: "कोच पुरस्कार", zh: "教练奖项", ku: "خەڵاتی ڕاهێنەر"), "\(coachAwards)", color: .mint)
                    recordCard(t(ar: "الحذاء الذهبي", en: "Golden Boots", hi: "गोल्डन बूट", zh: "金靴奖", ku: "پێڵاوی زێڕین"), "\(goldenBoots)", color: .purple)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("\(t(ar: "هداف الفريق", en: "Top Scorer", hi: "शीर्ष स्कोरर", zh: "头号射手", ku: "باشترین گۆڵهێنەر")): \(localizedDisplayName(topScorerName, in: language)) (\(topScorerGoals) \(t(ar: "هدف", en: "goals", hi: "गोल", zh: "球", ku: "گۆڵ")))")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white)

                    if achievements.isEmpty {
                        Text(t(ar: "لا توجد إنجازات بعد", en: "No achievements yet", hi: "अभी तक कोई उपलब्धि नहीं", zh: "暂无成就", ku: "هێشتا هیچ دەستکەوتێک نییە"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                    } else {
                        ForEach(achievements.suffix(5), id: \.self) { item in
                            Text("• \(localizedAchievement(item, in: language))")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.92))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.10))
                )

                Spacer()
            }
            .padding(18)
        }
    }

    private func recordCard(_ title: String, _ value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 33, weight: .black))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
    }
}

private struct MatchCenterView: View {
    private struct RecentHistorySelection: Identifiable {
        let id = UUID()
        let team: String
        let entry: TeamMatchHistoryEntry
    }

    private enum MatchCenterTab: Int, CaseIterable, Identifiable {
        case match
        case lineup
        case settings

        var id: Int { rawValue }
    }

    private enum MatchApproach: Int, CaseIterable, Hashable {
        case direct
        case balanced
        case possession
    }

    private enum MatchPressingStyle: Int, CaseIterable, Hashable {
        case high
        case balanced
        case defensive
    }

    private enum MatchTempo: Int, CaseIterable, Hashable {
        case slow
        case normal
        case fast
    }

    private enum MatchKickoffTime: Int, CaseIterable, Hashable {
        case early
        case afternoon
        case evening
        case night
    }

    private enum MatchWeather: Int, CaseIterable, Hashable {
        case clear
        case cloudy
        case rainy
        case stormy
    }

    private enum OpponentDifficulty: Int, CaseIterable, Hashable {
        case easy
        case balanced
        case hard
        case legendary
    }

    let language: AppLanguage
    let teamName: String
    let opponentName: String
    let matchDate: Date
    let teamRank: Int
    let opponentRank: Int
    let teamRecentHistory: [TeamMatchHistoryEntry]
    let opponentRecentHistory: [TeamMatchHistoryEntry]

    @Binding var lineup: [TeamPlayer]
    @Binding var bench: [TeamPlayer]
    let tacticalPlan: TacticalPlan
    let squadStrength: Int
    let fanSatisfaction: Int

    let onClose: () -> Void
    let onFinish: (Int, Int, String) -> Void

    @State private var minute = 0
    @State private var isRunning = false
    @State private var myGoals = 0
    @State private var oppGoals = 0
    @State private var events: [MatchEvent] = []

    @State private var selectedTab: MatchCenterTab = .match
    @State private var showLiveMatch = false
    @State private var matchApproach: MatchApproach = .balanced
    @State private var pressingStyle: MatchPressingStyle = .balanced
    @State private var matchTempo: MatchTempo = .normal
    @State private var kickoffTime: MatchKickoffTime = .evening
    @State private var matchWeather: MatchWeather = .clear
    @State private var opponentDifficulty: OpponentDifficulty = .balanced
    @State private var commentaryEnabled = true
    @State private var showRecentFormDots = false
    @State private var selectedHistorySelection: RecentHistorySelection?

    @Namespace private var tabsNamespace
    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
    }

    private var appLocale: Locale {
        Locale(identifier: language.localeIdentifier)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [FootballTheme.backgroundPrimary, FootballTheme.backgroundSecondary],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if showLiveMatch {
                liveMatchView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                preMatchView
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            if let selection = selectedHistorySelection {
                recentHistoryOverlay(selection: selection)
                    .zIndex(10)
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onReceive(timer) { _ in
            guard showLiveMatch, isRunning else { return }
            tickMatch()
        }
        .animation(.easeInOut(duration: 0.34), value: selectedTab)
        .animation(.spring(response: 0.42, dampingFraction: 0.88), value: showLiveMatch)
        .animation(.easeInOut(duration: 0.22), value: selectedHistorySelection != nil)
    }

    private var preMatchView: some View {
        VStack(spacing: 14) {
            topHeader
            tabContent
            Spacer(minLength: 0)
        }
        .padding(.top, 12)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .safeAreaInset(edge: .bottom) {
            tabsBar
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
        }
    }

    private var topHeader: some View {
        ZStack {
            Text(headerTitle)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            HStack {
                Button {
                    onClose()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .black))
                        Text(t(ar: "رجوع", en: "Back", hi: "वापस", zh: "返回", ku: "گەڕانەوە"))
                            .font(.system(size: 14, weight: .black))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(FootballTheme.cardBase.opacity(0.76))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
                }
                .buttonStyle(InteractivePressButtonStyle())

                Spacer()
            }
        }
    }

    private var headerTitle: String {
        switch selectedTab {
        case .match:
            return t(ar: "يوم المباراة", en: "Match Day", hi: "मैच डे", zh: "比赛日", ku: "ڕۆژی یاری")
        case .lineup:
            return t(ar: "التشكيلة", en: "Lineup", hi: "लाइनअप", zh: "阵容", ku: "پێکهاتە")
        case .settings:
            return t(ar: "الإعدادات", en: "Settings", hi: "सेटिंग्स", zh: "设置", ku: "ڕێکخستن")
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        ZStack {
            if selectedTab == .match {
                matchTab
                    .transition(tabTransition)
            }
            if selectedTab == .lineup {
                lineupTab
                    .transition(tabTransition)
            }
            if selectedTab == .settings {
                settingsTab
                    .transition(tabTransition)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var tabTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    private var matchTab: some View {
        VStack(spacing: 14) {
            matchOverviewCard
            startMatchButton
            recentFiveMatchesCard
            Spacer(minLength: 0)
        }
    }

    private var matchOverviewCard: some View {
        VStack(spacing: 12) {
            Text(matchDateText)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.84))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            HStack(alignment: .top, spacing: 10) {
                teamColumn(name: teamName, rank: teamRank)

                VStack(spacing: 7) {
                    Text("VS")
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(FootballTheme.pointsYellow)

                    Text(matchTimeText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.76))
                }
                .frame(width: 58)

                teamColumn(name: opponentName, rank: opponentRank)
            }

            Rectangle()
                .fill(Color.white.opacity(0.16))
                .frame(height: 1)

            Text(t(ar: "الترتيب قبل انطلاق المباراة", en: "League ranks before kickoff", hi: "किकऑफ से पहले लीग रैंक", zh: "开赛前联赛排名", ku: "پلەبەندی پێش دەستپێکی یاری"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.68))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [FootballTheme.cardBase.opacity(0.92), FootballTheme.backgroundSecondary.opacity(0.56)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
        .shadow(color: FootballTheme.cardGlow.opacity(0.16), radius: 12, x: 0, y: 6)
    }

    private func teamColumn(name: String, rank: Int) -> some View {
        VStack(spacing: 8) {
            TeamLogoView(teamName: name, size: 60)
                .padding(6)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.08))
                )
                .overlay(
                    Circle()
                        .stroke(FootballTheme.pointsYellow.opacity(0.45), lineWidth: 1)
                )
                .shadow(color: FootballTheme.pointsYellow.opacity(0.26), radius: 8, x: 0, y: 4)

            Text(localizedDisplayName(name, in: language))
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .multilineTextAlignment(.center)

            Text("\(t(ar: "المركز", en: "Rank", hi: "रैंक", zh: "排名", ku: "پلە")) \(rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(FootballTheme.textSecondary.opacity(0.92))
        }
        .frame(maxWidth: .infinity)
    }

    private var startMatchButton: some View {
        Button {
            beginMatchExperience()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 17, weight: .black))
                Text(t(ar: "بدء المباراة", en: "Start Match", hi: "मैच शुरू करें", zh: "开始比赛", ku: "یاری دەستپێبکە"))
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Image(systemName: "soccerball")
                    .font(.system(size: 17, weight: .black))
            }
            .foregroundStyle(.black.opacity(0.92))
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [FootballTheme.pitchGreen, FootballTheme.accentGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.50), lineWidth: 1)
                    )
            )
            .shadow(color: FootballTheme.pitchGreen.opacity(0.32), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(InteractivePressButtonStyle())
    }

    private var recentFiveMatchesCard: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text(t(ar: "آخر 5 مباريات", en: "Last 5 Matches", hi: "पिछले 5 मैच", zh: "最近5场", ku: "دوا 5 یاری"))
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text(t(ar: "الأحدث أولاً", en: "Newest first", hi: "सबसे नया पहले", zh: "最新在前", ku: "نوێترین سەرەتا"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.58))
                .frame(maxWidth: .infinity, alignment: .trailing)

            HStack(alignment: .top, spacing: 10) {
                recentFormColumn(team: teamName, history: teamRecentHistory)
                recentFormColumn(team: opponentName, history: opponentRecentHistory)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(FootballTheme.cardBase.opacity(0.58))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
        .shadow(color: FootballTheme.cardGlow.opacity(0.14), radius: 8, x: 0, y: 4)
        .onAppear {
            showRecentFormDots = false
            DispatchQueue.main.async {
                showRecentFormDots = true
            }
        }
    }

    private func recentFormColumn(team: String, history: [TeamMatchHistoryEntry]) -> some View {
        VStack(alignment: .trailing, spacing: 7) {
            Text(localizedDisplayName(team, in: language))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity, alignment: .trailing)

            if history.isEmpty {
                Text(t(ar: "لا توجد مباريات سابقة بعد", en: "No previous matches yet", hi: "अभी कोई पिछला मैच नहीं", zh: "暂无历史比赛", ku: "هێشتا هیچ یارییەکی پێشوو نییە"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.64))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                HStack(spacing: 6) {
                    ForEach(Array(history.enumerated()), id: \.element.id) { idx, entry in
                        resultDot(entry: entry, team: team, index: idx)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                if history.count < 5 {
                    Text("\(t(ar: "متاح", en: "Available", hi: "उपलब्ध", zh: "可用", ku: "بەردەست")) \(history.count)/5")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.58))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private func resultDot(entry: TeamMatchHistoryEntry, team: String, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                selectedHistorySelection = RecentHistorySelection(team: team, entry: entry)
            }
        } label: {
            Circle()
                .fill(resultColor(for: entry.result))
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.34), lineWidth: 0.8)
                )
                .scaleEffect(showRecentFormDots ? 1 : 0.25)
                .opacity(showRecentFormDots ? 1 : 0.1)
                .animation(
                    .spring(response: 0.34, dampingFraction: 0.78)
                        .delay(Double(index) * 0.06),
                    value: showRecentFormDots
                )
        }
        .buttonStyle(.plain)
    }

    private func resultColor(for result: TeamMatchResult) -> Color {
        switch result {
        case .win:
            return FootballTheme.accentGreen
        case .draw:
            return FootballTheme.pointsYellow
        case .loss:
            return FootballTheme.dangerRed
        }
    }

    private func recentHistoryOverlay(selection: RecentHistorySelection) -> some View {
        ZStack {
            Color.black.opacity(0.44)
                .ignoresSafeArea()
                .onTapGesture {
                    closeRecentHistoryOverlay()
                }

            VStack(alignment: .trailing, spacing: 10) {
                HStack {
                    Button {
                        closeRecentHistoryOverlay()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.white.opacity(0.14)))
                    }
                    .buttonStyle(InteractivePressButtonStyle())

                    Spacer()

                    Text(t(ar: "تفاصيل المباراة", en: "Match Details", hi: "मैच विवरण", zh: "比赛详情", ku: "وردەکاری یاری"))
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                Text("\(localizedDisplayName(selection.team, in: language)) vs \(localizedDisplayName(selection.entry.opponent, in: language))")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                detailRow(
                    label: t(ar: "النتيجة", en: "Score", hi: "स्कोर", zh: "比分", ku: "ئەنجام"),
                    value: "\(selection.entry.goalsFor) - \(selection.entry.goalsAgainst)"
                )
                detailRow(
                    label: t(ar: "الحالة", en: "Status", hi: "स्थिति", zh: "状态", ku: "دۆخ"),
                    value: localizedResultLabel(selection.entry.result),
                    valueColor: resultColor(for: selection.entry.result)
                )
                detailRow(
                    label: t(ar: "التاريخ", en: "Date", hi: "तारीख", zh: "日期", ku: "بەروار"),
                    value: formatHistoryDate(selection.entry.date)
                )
            }
            .padding(14)
            .frame(maxWidth: 330)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [FootballTheme.cardBase.opacity(0.96), FootballTheme.backgroundSecondary.opacity(0.82)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.20), lineWidth: 1)
                    )
            )
            .shadow(color: FootballTheme.cardGlow.opacity(0.24), radius: 14, x: 0, y: 8)
            .padding(.horizontal, 24)
        }
    }

    private func detailRow(label: String, value: String, valueColor: Color = .white) -> some View {
        HStack(spacing: 8) {
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Spacer(minLength: 0)
            Text("\(label):")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.76))
        }
    }

    private func localizedResultLabel(_ result: TeamMatchResult) -> String {
        switch result {
        case .win:
            return t(ar: "فوز", en: "Win", hi: "जीत", zh: "胜", ku: "بردنەوە")
        case .draw:
            return t(ar: "تعادل", en: "Draw", hi: "ड्रॉ", zh: "平", ku: "یەکسان")
        case .loss:
            return t(ar: "خسارة", en: "Loss", hi: "हार", zh: "负", ku: "دۆڕان")
        }
    }

    private func formatHistoryDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func closeRecentHistoryOverlay() {
        withAnimation(.easeInOut(duration: 0.18)) {
            selectedHistorySelection = nil
        }
    }

    private var lineupTab: some View {
        VStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 6) {
                Text(t(ar: "الخطة الحالية", en: "Current Formation", hi: "वर्तमान फॉर्मेशन", zh: "当前阵型", ku: "پلانی ئێستا"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(FootballTheme.textSecondary.opacity(0.92))

                Text(tacticalPlan.rawValue)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )

            VStack(spacing: 10) {
                ForEach(Array(lineupRows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 7) {
                        ForEach(row) { player in
                            lineupPlayerChip(player)
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(FootballTheme.cardBase.opacity(0.58))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            )

            Text(t(ar: "عرض مبسّط للتشكيلة الأساسية قبل المباراة.", en: "A simple preview of your starting lineup before kickoff.", hi: "किकऑफ़ से पहले आपकी शुरुआती लाइनअप का सरल दृश्य।", zh: "开赛前首发阵容的简洁预览。", ku: "پێشاندانی سادەی پێکهاتەی سەرەکی پێش دەستپێکی یاری."))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))
                .frame(maxWidth: .infinity, alignment: .trailing)

            Spacer(minLength: 0)
        }
    }

    private var settingsTab: some View {
        VStack(alignment: .trailing, spacing: 12) {
            settingBlock(
                title: t(ar: "وقت المباراة", en: "Match Time", hi: "मैच समय", zh: "比赛时间", ku: "کاتی یاری")
            ) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MatchKickoffTime.allCases, id: \.self) { item in
                            compactOptionChip(
                                title: kickoffTimeLabel(item),
                                isActive: kickoffTime == item
                            ) {
                                withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                                    kickoffTime = item
                                }
                            }
                        }
                    }
                }
            }

            settingBlock(
                title: t(ar: "الطقس", en: "Weather", hi: "मौसम", zh: "天气", ku: "کەشوهەوا")
            ) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MatchWeather.allCases, id: \.self) { item in
                            compactOptionChip(
                                title: weatherLabel(item),
                                isActive: matchWeather == item
                            ) {
                                withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                                    matchWeather = item
                                }
                            }
                        }
                    }
                }
            }

            settingBlock(
                title: t(ar: "صعوبة الخصم", en: "Opponent Difficulty", hi: "प्रतिद्वंद्वी कठिनाई", zh: "对手难度", ku: "سەختیی نەیار")
            ) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(OpponentDifficulty.allCases, id: \.self) { item in
                            compactOptionChip(
                                title: opponentDifficultyLabel(item),
                                isActive: opponentDifficulty == item
                            ) {
                                withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                                    opponentDifficulty = item
                                }
                            }
                        }
                    }
                }
            }

            settingBlock(
                title: t(ar: "أسلوب اللعب", en: "Play Style", hi: "खेल शैली", zh: "比赛风格", ku: "شێوازی یاری")
            ) {
                HStack(spacing: 8) {
                    ForEach(MatchApproach.allCases, id: \.self) { item in
                        optionChip(
                            title: approachLabel(item),
                            isActive: matchApproach == item
                        ) {
                            withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                                matchApproach = item
                            }
                        }
                    }
                }
            }

            settingBlock(
                title: t(ar: "الضغط", en: "Pressing", hi: "प्रेसिंग", zh: "压迫", ku: "فشار")
            ) {
                HStack(spacing: 8) {
                    ForEach(MatchPressingStyle.allCases, id: \.self) { item in
                        optionChip(
                            title: pressingLabel(item),
                            isActive: pressingStyle == item
                        ) {
                            withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                                pressingStyle = item
                            }
                        }
                    }
                }
            }

            settingBlock(
                title: t(ar: "سرعة اللعب", en: "Game Speed", hi: "गेम गति", zh: "比赛速度", ku: "خێرایی یاری")
            ) {
                HStack(spacing: 8) {
                    ForEach(MatchTempo.allCases, id: \.self) { item in
                        optionChip(
                            title: tempoLabel(item),
                            isActive: matchTempo == item
                        ) {
                            withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                                matchTempo = item
                            }
                        }
                    }
                }
            }

            HStack {
                Toggle(
                    t(ar: "تشغيل التعليق", en: "Commentary", hi: "कमेंट्री", zh: "解说", ku: "ڕاڤەکردن"),
                    isOn: $commentaryEnabled
                )
                .toggleStyle(.switch)
                .tint(FootballTheme.pitchGreen)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )

            Spacer(minLength: 0)
        }
    }

    private func settingBlock<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white.opacity(0.86))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }

    private func optionChip(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isActive ? .black : .white.opacity(0.88))
                .lineLimit(1)
                .minimumScaleFactor(0.86)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isActive ? FootballTheme.pitchGreen : Color.white.opacity(0.08))
                )
        }
        .buttonStyle(InteractivePressButtonStyle())
    }

    private func compactOptionChip(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(isActive ? .black : .white.opacity(0.88))
                .lineLimit(1)
                .minimumScaleFactor(0.80)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isActive ? FootballTheme.pitchGreen : Color.white.opacity(0.08))
                )
        }
        .buttonStyle(InteractivePressButtonStyle())
    }

    private var tabsBar: some View {
        HStack(spacing: 8) {
            ForEach(MatchCenterTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tabIcon(tab))
                            .font(.system(size: 16, weight: .black))
                        Text(tabTitle(tab))
                            .font(.system(size: 12, weight: .black))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }
                    .foregroundStyle(selectedTab == tab ? Color.black : Color.white.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        ZStack {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(FootballTheme.pitchGreen)
                                    .matchedGeometryEffect(id: "activeMatchTab", in: tabsNamespace)
                            } else {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.07))
                            }
                        }
                    )
                    .scaleEffect(selectedTab == tab ? 1.08 : 1.0)
                }
                .buttonStyle(InteractivePressButtonStyle())
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(FootballTheme.cardBase.opacity(0.86))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.28), radius: 10, x: 0, y: 6)
    }

    private func tabIcon(_ tab: MatchCenterTab) -> String {
        switch tab {
        case .match: return "soccerball.inverse"
        case .lineup: return "person.3.sequence.fill"
        case .settings: return "slider.horizontal.3"
        }
    }

    private func tabTitle(_ tab: MatchCenterTab) -> String {
        switch tab {
        case .match:
            return t(ar: "المباراة", en: "Match", hi: "मैच", zh: "比赛", ku: "یاری")
        case .lineup:
            return t(ar: "التشكيلة", en: "Lineup", hi: "लाइनअप", zh: "阵容", ku: "پێکهاتە")
        case .settings:
            return t(ar: "الإعدادات", en: "Settings", hi: "सेटिंग्स", zh: "设置", ku: "ڕێکخستن")
        }
    }

    private func approachLabel(_ value: MatchApproach) -> String {
        switch value {
        case .direct:
            return t(ar: "مباشر", en: "Direct", hi: "सीधा", zh: "直接", ku: "ڕاستەوخۆ")
        case .balanced:
            return t(ar: "متوازن", en: "Balanced", hi: "संतुलित", zh: "均衡", ku: "هاوسەنگ")
        case .possession:
            return t(ar: "استحواذ", en: "Possession", hi: "पजेशन", zh: "控球", ku: "دەسەڵات")
        }
    }

    private func pressingLabel(_ value: MatchPressingStyle) -> String {
        switch value {
        case .high:
            return t(ar: "عالي", en: "High", hi: "हाई", zh: "高压", ku: "بەرز")
        case .balanced:
            return t(ar: "متوازن", en: "Balanced", hi: "संतुलित", zh: "均衡", ku: "هاوسەنگ")
        case .defensive:
            return t(ar: "دفاعي", en: "Defensive", hi: "रक्षात्मक", zh: "防守", ku: "بەرگری")
        }
    }

    private func tempoLabel(_ value: MatchTempo) -> String {
        switch value {
        case .slow:
            return t(ar: "بطيء", en: "Slow", hi: "धीमा", zh: "慢速", ku: "هێواش")
        case .normal:
            return t(ar: "عادي", en: "Normal", hi: "सामान्य", zh: "普通", ku: "ئاسایی")
        case .fast:
            return t(ar: "سريع", en: "Fast", hi: "तेज़", zh: "快速", ku: "خێرا")
        }
    }

    private func kickoffTimeLabel(_ value: MatchKickoffTime) -> String {
        switch value {
        case .early:
            return t(ar: "ظهرًا", en: "Noon", hi: "दोपहर", zh: "中午", ku: "نیوەڕۆ")
        case .afternoon:
            return t(ar: "عصرًا", en: "Afternoon", hi: "दोपहर बाद", zh: "下午", ku: "ئێوارە")
        case .evening:
            return t(ar: "مساءً", en: "Evening", hi: "शाम", zh: "傍晚", ku: "ئێوارە")
        case .night:
            return t(ar: "ليلًا", en: "Night", hi: "रात", zh: "夜间", ku: "شەو")
        }
    }

    private func weatherLabel(_ value: MatchWeather) -> String {
        switch value {
        case .clear:
            return t(ar: "مشمس", en: "Clear", hi: "साफ़", zh: "晴朗", ku: "ڕووناک")
        case .cloudy:
            return t(ar: "غائم", en: "Cloudy", hi: "बादल", zh: "多云", ku: "هەور")
        case .rainy:
            return t(ar: "ممطر", en: "Rainy", hi: "बारिश", zh: "下雨", ku: "باراناوی")
        case .stormy:
            return t(ar: "عاصف", en: "Stormy", hi: "तूफ़اني", zh: "暴风", ku: "با")
        }
    }

    private func opponentDifficultyLabel(_ value: OpponentDifficulty) -> String {
        switch value {
        case .easy:
            return t(ar: "سهل", en: "Easy", hi: "आसान", zh: "简单", ku: "ئاسان")
        case .balanced:
            return t(ar: "متوازن", en: "Balanced", hi: "संतुलित", zh: "均衡", ku: "هاوسەنگ")
        case .hard:
            return t(ar: "صعب", en: "Hard", hi: "कठिन", zh: "困难", ku: "سەخت")
        case .legendary:
            return t(ar: "أسطوري", en: "Legendary", hi: "लीजेंडरी", zh: "传奇", ku: "ئەفسانەیی")
        }
    }

    private var lineupRows: [[TeamPlayer]] {
        switch tacticalPlan {
        case .fourThreeThree:
            return [
                players(at: [0]),
                players(at: [1, 2, 3, 4]),
                players(at: [5, 6, 7]),
                players(at: [8, 9, 10])
            ]
        case .fourTwoThreeOne:
            return [
                players(at: [0]),
                players(at: [1, 2, 3, 4]),
                players(at: [5, 6]),
                players(at: [7, 8, 9]),
                players(at: [10])
            ]
        case .threeFiveTwo:
            return [
                players(at: [0]),
                players(at: [1, 2, 3]),
                players(at: [4, 5, 6, 7, 8]),
                players(at: [9, 10])
            ]
        }
    }

    private func players(at indices: [Int]) -> [TeamPlayer] {
        indices.compactMap { idx in
            lineup.indices.contains(idx) ? lineup[idx] : nil
        }
    }

    private func lineupPlayerChip(_ player: TeamPlayer) -> some View {
        VStack(spacing: 3) {
            Text(player.role)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(FootballTheme.pointsYellow)
                .lineLimit(1)
            Text(localizedDisplayName(player.name, in: language))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.09))
        )
    }

    private var configuredMatchDate: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: matchDate)
        switch kickoffTime {
        case .early:
            components.hour = 13
            components.minute = 30
        case .afternoon:
            components.hour = 16
            components.minute = 30
        case .evening:
            components.hour = 19
            components.minute = 45
        case .night:
            components.hour = 22
            components.minute = 0
        }
        return Calendar.current.date(from: components) ?? matchDate
    }

    private var matchDateText: String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMMM")
        return formatter.string(from: configuredMatchDate)
    }

    private var matchTimeText: String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: configuredMatchDate)
    }

    private func beginMatchExperience() {
        selectedHistorySelection = nil
        minute = 0
        myGoals = 0
        oppGoals = 0
        let kickoffInfo = "\(kickoffTimeLabel(kickoffTime)) • \(weatherLabel(matchWeather)) • \(opponentDifficultyLabel(opponentDifficulty))"
        events = [
            MatchEvent(
                minute: 0,
                text: "\(t(ar: "صافرة البداية!", en: "Kickoff whistle!", hi: "किकऑफ़ सीटी!", zh: "开场哨响！", ku: "سڕوتی دەستپێک!")) • \(kickoffInfo)"
            )
        ]
        isRunning = true
        withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
            showLiveMatch = true
        }
    }

    private var liveMatchView: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    isRunning = false
                    withAnimation(.easeInOut(duration: 0.28)) {
                        showLiveMatch = false
                        selectedTab = .match
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.right")
                        Text(t(ar: "العودة", en: "Back", hi: "वापस", zh: "返回", ku: "گەڕانەوە"))
                    }
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(FootballTheme.cardBase.opacity(0.74))
                    )
                }
                .buttonStyle(InteractivePressButtonStyle())

                Spacer()

                Text(t(ar: "المباراة جارية", en: "Live Match", hi: "लाइव मैच", zh: "比赛进行中", ku: "یاری بەردەوامە"))
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.white.opacity(0.15)))
                }
                .buttonStyle(InteractivePressButtonStyle())
            }

            HStack {
                HStack(spacing: 6) {
                    TeamLogoView(teamName: teamName, size: 24)
                    Text(localizedDisplayName(teamName, in: language))
                }
                Spacer()
                Text("\(myGoals) - \(oppGoals)")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 6) {
                    Text(localizedDisplayName(opponentName, in: language))
                    TeamLogoView(teamName: opponentName, size: 24)
                }
            }
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 4)

            Text("\(t(ar: "الدقيقة", en: "Minute", hi: "मिनट", zh: "分钟", ku: "خولەک")): \(minute) / 90")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(FootballTheme.pointsYellow)

            Text("\(t(ar: "الخطة", en: "Plan", hi: "योजना", zh: "阵型", ku: "پلان")): \(tacticalPlan.rawValue) • \(approachLabel(matchApproach))")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.86))

            Text("\(t(ar: "الوقت", en: "Time", hi: "समय", zh: "时间", ku: "کات")): \(kickoffTimeLabel(kickoffTime)) • \(t(ar: "الطقس", en: "Weather", hi: "मौसम", zh: "天气", ku: "کەشوهەوا")): \(weatherLabel(matchWeather)) • \(t(ar: "الصعوبة", en: "Difficulty", hi: "कठिनाई", zh: "难度", ku: "سەختی")): \(opponentDifficultyLabel(opponentDifficulty))")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            pitchView
                .frame(height: 350)

            if minute >= 90 {
                Button {
                    finishMatch()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 17, weight: .black))
                        Text(t(ar: "إنهاء المباراة", en: "Finish Match", hi: "मैच समाप्त करें", zh: "结束比赛", ku: "یارییەکە کۆتایی پێبهێنە"))
                            .font(.system(size: 20, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.black.opacity(0.92))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(FootballTheme.pitchGreen)
                    )
                }
                .buttonStyle(InteractivePressButtonStyle())
            }

            ScrollView {
                VStack(alignment: .trailing, spacing: 6) {
                    Text(t(ar: "أحداث المباراة", en: "Match Events", hi: "मैच घटनाएँ", zh: "比赛事件", ku: "ڕووداوەکانی یاری"))
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    ForEach(events.suffix(8)) { item in
                        Text("\(item.minute)' - \(item.text)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .frame(height: 120)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private func finishMatch() {
        let summary = "\(t(ar: "انتهت", en: "Finished", hi: "समाप्त", zh: "结束", ku: "کۆتایی هات")) \(myGoals)-\(oppGoals) | \(events.prefix(2).map { $0.text }.joined(separator: " | "))"
        onFinish(myGoals, oppGoals, summary)
    }

    private var pitchView: some View {
        GeometryReader { geo in
            let positions = positionsForPlan()

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(FootballTheme.pitchGreen.opacity(0.72))
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.8), lineWidth: 2)
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: geo.size.width * 0.80, height: geo.size.height * 0.98)
                    .overlay(Rectangle().stroke(Color.white.opacity(0.7), lineWidth: 1.5))
                Circle()
                    .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                    .frame(width: 70, height: 70)

                ForEach(Array(lineup.enumerated()), id: \.element.id) { idx, player in
                    let point = positions[min(idx, positions.count - 1)]
                    playerChip(player: player)
                        .position(x: geo.size.width * point.x, y: geo.size.height * point.y)
                }
            }
        }
    }

    private func playerChip(player: TeamPlayer) -> some View {
        VStack(spacing: 2) {
            Circle()
                .fill(Color.white)
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundStyle(FootballTheme.pitchGreen)
                )
            Text("\(player.number)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private func positionsForPlan() -> [CGPoint] {
        switch tacticalPlan {
        case .fourThreeThree:
            return [
                CGPoint(x: 0.5, y: 0.92),
                CGPoint(x: 0.82, y: 0.76),
                CGPoint(x: 0.62, y: 0.72),
                CGPoint(x: 0.38, y: 0.72),
                CGPoint(x: 0.18, y: 0.76),
                CGPoint(x: 0.50, y: 0.60),
                CGPoint(x: 0.65, y: 0.50),
                CGPoint(x: 0.35, y: 0.50),
                CGPoint(x: 0.78, y: 0.34),
                CGPoint(x: 0.50, y: 0.24),
                CGPoint(x: 0.22, y: 0.34)
            ]
        case .fourTwoThreeOne:
            return [
                CGPoint(x: 0.5, y: 0.92),
                CGPoint(x: 0.82, y: 0.78),
                CGPoint(x: 0.62, y: 0.74),
                CGPoint(x: 0.38, y: 0.74),
                CGPoint(x: 0.18, y: 0.78),
                CGPoint(x: 0.60, y: 0.60),
                CGPoint(x: 0.40, y: 0.60),
                CGPoint(x: 0.80, y: 0.45),
                CGPoint(x: 0.50, y: 0.42),
                CGPoint(x: 0.20, y: 0.45),
                CGPoint(x: 0.50, y: 0.24)
            ]
        case .threeFiveTwo:
            return [
                CGPoint(x: 0.5, y: 0.92),
                CGPoint(x: 0.72, y: 0.74),
                CGPoint(x: 0.50, y: 0.72),
                CGPoint(x: 0.28, y: 0.74),
                CGPoint(x: 0.85, y: 0.56),
                CGPoint(x: 0.65, y: 0.56),
                CGPoint(x: 0.50, y: 0.52),
                CGPoint(x: 0.35, y: 0.56),
                CGPoint(x: 0.15, y: 0.56),
                CGPoint(x: 0.62, y: 0.30),
                CGPoint(x: 0.38, y: 0.30)
            ]
        }
    }

    private func tickMatch() {
        let paceRange: ClosedRange<Int>
        switch matchTempo {
        case .slow:
            paceRange = 1...2
        case .normal:
            paceRange = 1...3
        case .fast:
            paceRange = 2...4
        }

        minute = min(90, minute + Int.random(in: paceRange))

        let approachBoost: Int
        switch matchApproach {
        case .direct: approachBoost = 4
        case .balanced: approachBoost = 2
        case .possession: approachBoost = 1
        }

        let pressingAttackBoost: Int
        switch pressingStyle {
        case .high:
            pressingAttackBoost = 3
        case .balanced:
            pressingAttackBoost = 1
        case .defensive:
            pressingAttackBoost = -3
        }

        let weatherEventModifier: Int
        let weatherChanceModifier: Int
        switch matchWeather {
        case .clear:
            weatherEventModifier = 1
            weatherChanceModifier = 1
        case .cloudy:
            weatherEventModifier = 0
            weatherChanceModifier = 0
        case .rainy:
            weatherEventModifier = -3
            weatherChanceModifier = -5
        case .stormy:
            weatherEventModifier = -6
            weatherChanceModifier = -9
        }

        let difficultyEventModifier: Int
        let difficultyChanceModifier: Int
        switch opponentDifficulty {
        case .easy:
            difficultyEventModifier = 1
            difficultyChanceModifier = 8
        case .balanced:
            difficultyEventModifier = 0
            difficultyChanceModifier = 0
        case .hard:
            difficultyEventModifier = 2
            difficultyChanceModifier = -8
        case .legendary:
            difficultyEventModifier = 3
            difficultyChanceModifier = -14
        }

        let eventChance = max(
            10,
            min(
                52,
                24
                + ((squadStrength - 70) / 2)
                + tacticalPlan.attackBoost
                + approachBoost
                + weatherEventModifier
                + difficultyEventModifier
            )
        )
        let baseChance = 52
            + ((squadStrength - 72) / 2)
            + ((fanSatisfaction - 70) / 5)
            + tacticalPlan.attackBoost
            + pressingAttackBoost
            - (tacticalPlan.defenseBoost / 2)
            + weatherChanceModifier
            + difficultyChanceModifier
        let myChancePercent = max(20, min(84, baseChance))

        if Bool.random() && Int.random(in: 0...100) < eventChance {
            let myChance = Int.random(in: 0...100) < myChancePercent
            let rawScorer = lineup.randomElement()?.name ?? t(ar: "لاعب", en: "Player", hi: "खिलाड़ी", zh: "球员", ku: "یاریزان")
            let rawAssist = lineup.filter { $0.name != rawScorer }.randomElement()?.name ?? rawScorer
            let scorer = localizedDisplayName(rawScorer, in: language)
            let localizedAssist = localizedDisplayName(rawAssist, in: language)
            let opponentScorer = [
                t(ar: "المهاجم", en: "Striker", hi: "स्ट्राइकर", zh: "前锋", ku: "هێرشبەر"),
                t(ar: "الجناح", en: "Winger", hi: "विंगर", zh: "边锋", ku: "باڵ"),
                t(ar: "صانع اللعب", en: "Playmaker", hi: "प्लेमेकर", zh: "组织者", ku: "یاریساز"),
                t(ar: "البديل", en: "Substitute", hi: "सब्स्टिट्यूट", zh: "替补", ku: "یاریزانی پشتی")
            ].randomElement() ?? t(ar: "المهاجم", en: "Striker", hi: "स्ट्राइकर", zh: "前锋", ku: "هێرشبەر")
            let opponentAssist = [
                t(ar: "الظهير", en: "Full Back", hi: "फुल बैक", zh: "边后卫", ku: "بەرگری لا"),
                t(ar: "الوسط", en: "Midfielder", hi: "मिडफ़ील्डर", zh: "中场", ku: "ناوەڕاست"),
                t(ar: "المهاجم", en: "Striker", hi: "स्ट्राइकर", zh: "前锋", ku: "هێرشبەر"),
                t(ar: "الجناح", en: "Winger", hi: "विंगर", zh: "边锋", ku: "باڵ")
            ].randomElement() ?? t(ar: "الوسط", en: "Midfielder", hi: "मिडफ़ील्डर", zh: "中场", ku: "ناوەڕاست")

            let goalLabel = commentaryEnabled
                ? t(ar: "هدف لـ", en: "Goal for", hi: "गोल", zh: "进球", ku: "گۆڵ بۆ")
                : t(ar: "تسجيل", en: "Scored", hi: "स्कोर", zh: "得分", ku: "تۆمارکردن")

            if myChance {
                myGoals += 1
                events.append(MatchEvent(minute: minute, text: "\(goalLabel) \(localizedDisplayName(teamName, in: language)) - \(t(ar: "سجّل", en: "Scored", hi: "गोल किया", zh: "进球队员", ku: "تۆماری کرد")): \(scorer) | \(t(ar: "صنع", en: "Assist", hi: "असिस्ट", zh: "助攻", ku: "یارمەتیدا")): \(localizedAssist)"))
            } else {
                oppGoals += 1
                events.append(MatchEvent(minute: minute, text: "\(goalLabel) \(localizedDisplayName(opponentName, in: language)) - \(t(ar: "سجّل", en: "Scored", hi: "गोल किया", zh: "进球队员", ku: "تۆماری کرد")): \(opponentScorer) | \(t(ar: "صنع", en: "Assist", hi: "असिस्ट", zh: "助攻", ku: "یارمەتیدا")): \(opponentAssist)"))
            }
        }

        if minute >= 90 {
            isRunning = false
            if events.isEmpty {
                events.append(MatchEvent(minute: 90, text: t(ar: "مباراة تكتيكية بدون أهداف خطيرة", en: "A tactical match with no major chances", hi: "बिना बड़े मौकों वाला सामरिक मैच", zh: "一场没有明显机会的战术比赛", ku: "یارییەکی تاکتیکی بەبێ هەلێکی گەورەی گۆڵ")))
            }
        }
    }
}

private struct CompetitionsView: View {
    @Environment(\.dismiss) private var dismiss
    let language: AppLanguage
    @State private var championsTable: [LiveStandingRow] = []
    @State private var nextFixtures: [UCLFixtureRow] = []
    @State private var recentFixtures: [UCLFixtureRow] = []
    @State private var loading = false
    @State private var errorMessage = ""
    @State private var lastUpdated: Date?

    private let refreshTimer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
    private let championsLeagueID = "4480"

    private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        language.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.08, blue: 0.20), Color(red: 0.02, green: 0.18, blue: 0.29)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Button(t(ar: "إغلاق", en: "Close", hi: "Close", zh: "关闭", ku: "داخستن")) {
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())

                        Spacer()

                        Button {
                            Task { await loadChampionsLeagueData(force: true) }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                Text(t(ar: "تحديث", en: "Refresh", hi: "रीफ़्रेश", zh: "刷新", ku: "نوێکردنەوە"))
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(loading)

                        Text(t(ar: "البطولات", en: "Competitions", hi: "प्रतियोगिताएँ", zh: "赛事", ku: "پاڵەوانییەکان"))
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    competitionBar(
                        title: t(ar: "دوري الأبطال (مباشر)", en: "Champions League (Live)", hi: "चैंपियंस लीग (लाइव)", zh: "欧冠（实时）", ku: "لیگی پاڵەوانان (ڕاستەوخۆ)"),
                        subtitle: t(ar: "مرتبط بنتائج الواقع", en: "Connected to real results", hi: "वास्तविक परिणामों से जुड़ा", zh: "与真实结果同步", ku: "بە ئەنجامە ڕاستەقینەکانەوە پەیوەستە"),
                        gradient: [Color(red: 0.02, green: 0.28, blue: 0.95), Color(red: 0.17, green: 0.52, blue: 1.0)],
                        glow: .blue
                    )

                    if loading && championsTable.isEmpty {
                        loadingCard(t(ar: "جاري تحميل بيانات دوري الأبطال الحقيقية...", en: "Loading live Champions League data...", hi: "लाइव चैंपियंस लीग डेटा लोड हो रहा है...", zh: "正在加载欧冠实时数据...", ku: "داتای ڕاستەوخۆی لیگی پاڵەوانان بار دەکرێت..."))
                    } else if !errorMessage.isEmpty && championsTable.isEmpty {
                        infoCard(
                            errorMessage == "تعذر جلب بيانات دوري الأبطال حالياً"
                            ? t(ar: "تعذر جلب بيانات دوري الأبطال حالياً", en: "Unable to fetch Champions League data right now", hi: "इस समय चैंपियंस लीग डेटा नहीं लाया जा सका", zh: "当前无法获取欧冠数据", ku: "لە ئێستادا ناتوانرێت داتای لیگی پاڵەوانان بهێنرێت")
                            : errorMessage,
                            color: .red.opacity(0.92)
                        )
                    } else {
                        championsStandingsCard
                        fixturesCard(title: t(ar: "المباريات القادمة", en: "Upcoming Matches", hi: "आगामी मैच", zh: "即将到来的比赛", ku: "یارییەکانی داهاتوو"), rows: nextFixtures)
                        fixturesCard(title: t(ar: "آخر النتائج", en: "Recent Results", hi: "हाल के परिणाम", zh: "近期结果", ku: "دوایین ئەنجامەکان"), rows: recentFixtures)
                    }

                    if let lastUpdated {
                        infoCard("\(t(ar: "آخر تحديث", en: "Last update", hi: "आख़िरी अपडेट", zh: "最后更新", ku: "دوایین نوێکردنەوە")): \(formatUpdateDate(lastUpdated))", color: .white.opacity(0.82))
                    }

                    if !errorMessage.isEmpty && !championsTable.isEmpty {
                        infoCard(
                            errorMessage == "تعذر جلب بيانات دوري الأبطال حالياً"
                            ? t(ar: "تعذر جلب بيانات دوري الأبطال حالياً", en: "Unable to fetch Champions League data right now", hi: "इस समय चैंपियंस लीग डेटा नहीं लाया जा सका", zh: "当前无法获取欧冠数据", ku: "لە ئێستادا ناتوانرێت داتای لیگی پاڵەوانان بهێنرێت")
                            : errorMessage,
                            color: .orange.opacity(0.9)
                        )
                    }

                    competitionBar(
                        title: t(ar: "الدوري الأوروبي", en: "Europa League", hi: "यूरोपा लीग", zh: "欧联杯", ku: "یورۆپا لیگ"),
                        subtitle: t(ar: "فرصة مجد قاري جديدة", en: "A new chance for continental glory", hi: "महाद्वीपीय गौरव का नया मौका", zh: "新的洲际荣耀机会", ku: "هەلێکی نوێ بۆ شانازیی کیشوەری"),
                        gradient: [Color(red: 0.98, green: 0.42, blue: 0.04), Color(red: 1.0, green: 0.63, blue: 0.16)],
                        glow: .orange
                    )

                    competitionBar(
                        title: t(ar: "كأس العالم (منتخبات)", en: "World Cup (National Teams)", hi: "विश्व कप (राष्ट्रीय टीमें)", zh: "世界杯（国家队）", ku: "جامی جیهان (نیشتیمانی)"),
                        subtitle: t(ar: "البطولة الذهبية الأكبر", en: "The biggest golden tournament", hi: "सबसे बड़ा सुनहरा टूर्नामेंट", zh: "最耀眼的黄金赛事", ku: "گەورەترین پاڵەوانی زێڕین"),
                        gradient: [Color(red: 0.74, green: 0.56, blue: 0.05), Color(red: 1.0, green: 0.86, blue: 0.32)],
                        glow: .yellow
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.65), lineWidth: 2)
                    )
                }
                .padding(20)
            }
        }
        .task {
            await loadChampionsLeagueData(force: true)
        }
        .onReceive(refreshTimer) { _ in
            Task { await loadChampionsLeagueData(force: true) }
        }
    }

    private var championsStandingsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(t(ar: "جدول دوري الأبطال", en: "Champions League Table", hi: "चैंपियंस लीग तालिका", zh: "欧冠积分榜", ku: "خشتەی لیگی پاڵەوانان"))
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        headerCell(t(ar: "م", en: "#", hi: "#", zh: "名", ku: "پ"), width: 28)
                        headerCell(t(ar: "الفريق", en: "Team", hi: "टीम", zh: "球队", ku: "تیم"), width: 165)
                        headerCell(t(ar: "ل", en: "P", hi: "P", zh: "赛", ku: "ی"), width: 32)
                        headerCell(t(ar: "ف", en: "W", hi: "W", zh: "胜", ku: "ب"), width: 32)
                        headerCell(t(ar: "ت", en: "D", hi: "D", zh: "平", ku: "ی"), width: 32)
                        headerCell(t(ar: "خ", en: "L", hi: "L", zh: "负", ku: "د"), width: 32)
                        headerCell(t(ar: "له", en: "GF", hi: "GF", zh: "进", ku: "بۆ"), width: 38)
                        headerCell(t(ar: "عليه", en: "GA", hi: "GA", zh: "失", ku: "لەسەر"), width: 44)
                        headerCell("±", width: 34)
                        headerCell(t(ar: "ن", en: "Pts", hi: "Pts", zh: "分", ku: "خال"), width: 34)
                        headerCell(t(ar: "آخر 5", en: "Last 5", hi: "पिछले 5", zh: "近5场", ku: "دوا 5"), width: 120)
                    }

                    ForEach(Array(championsTable.prefix(16))) { row in
                        HStack(spacing: 6) {
                            valueCell("\(row.rank)", width: 28, bold: true, color: FootballTheme.pointsYellow)
                            HStack(spacing: 6) {
                                TeamLogoView(teamName: row.teamName, size: 20)

                                Text(localizedDisplayName(row.teamName, in: language))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                            }
                            .frame(width: 165, alignment: .leading)

                            valueCell("\(row.played)", width: 32)
                            valueCell("\(row.wins)", width: 32)
                            valueCell("\(row.draws)", width: 32)
                            valueCell("\(row.losses)", width: 32)
                            valueCell("\(row.goalsFor)", width: 38)
                            valueCell("\(row.goalsAgainst)", width: 44)
                            valueCell("\(row.goalDiff)", width: 34)
                            valueCell("\(row.points)", width: 34, bold: true)

                            HStack(spacing: 4) {
                                ForEach(Array(row.form.prefix(5).enumerated()), id: \.offset) { _, item in
                                    formCircle(item)
                                }
                            }
                            .frame(width: 120, alignment: .leading)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(Color.white.opacity(0.07))
                        )
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.1))
        )
    }

    private func fixturesCard(title: String, rows: [UCLFixtureRow]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)

            if rows.isEmpty {
                Text(t(ar: "لا توجد بيانات حالياً", en: "No data available right now", hi: "फिलहाल कोई डेटा उपलब्ध नहीं है", zh: "当前没有可用数据", ku: "لە ئێستادا هیچ داتایەک بەردەست نییە"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.82))
            } else {
                ForEach(rows.prefix(6)) { row in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(localizedDisplayName(row.home, in: language)) × \(localizedDisplayName(row.away, in: language))")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text("\(row.dateText) \(row.timeText)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.82))
                        }

                        Spacer()

                        if let homeScore = row.homeScore, let awayScore = row.awayScore {
                            Text("\(homeScore)-\(awayScore)")
                                .font(.system(size: 15, weight: .black))
                                .foregroundStyle(FootballTheme.pointsYellow)
                        } else {
                            Text(row.status)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.cyan.opacity(0.9))
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.08))
                    )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.1))
        )
    }

    private func loadingCard(_ message: String) -> some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(.white)
            Text(message)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }

    private func infoCard(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.08))
            )
    }

    private func headerCell(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .black))
            .foregroundStyle(.white.opacity(0.84))
            .frame(width: width)
    }

    private func valueCell(_ value: String, width: CGFloat, bold: Bool = false, color: Color = .white) -> some View {
        Text(value)
            .font(.system(size: 13, weight: bold ? .black : .semibold))
            .foregroundStyle(color)
            .frame(width: width)
    }

    private func formCircle(_ result: Character) -> some View {
        let symbol: String
        let color: Color

        switch result {
        case "W":
            symbol = "checkmark"
            color = .green
        case "D":
            symbol = "minus"
            color = .gray
        case "L":
            symbol = "xmark"
            color = .red
        default:
            symbol = "minus"
            color = .gray
        }

        return Circle()
            .fill(color.opacity(0.95))
            .frame(width: 18, height: 18)
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.white)
            )
    }

    private func formatUpdateDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.localeIdentifier)
        formatter.dateFormat = "d MMM - HH:mm"
        return formatter.string(from: date)
    }

    private func formatEventDate(_ item: SportsDBEvent) -> (date: String, time: String) {
        if let stamp = item.strTimestamp, let date = ISO8601DateFormatter().date(from: stamp) {
            let dayFormatter = DateFormatter()
            dayFormatter.locale = Locale(identifier: language.localeIdentifier)
            dayFormatter.dateFormat = "d MMM"

            let timeFormatter = DateFormatter()
            timeFormatter.locale = Locale(identifier: language.localeIdentifier)
            timeFormatter.dateFormat = "HH:mm"
            return (dayFormatter.string(from: date), timeFormatter.string(from: date))
        }

        return (item.dateEvent ?? "-", item.strTime?.prefix(5).description ?? "")
    }

    private func mapStandings(_ rows: [SportsDBStanding]) -> [LiveStandingRow] {
        rows.compactMap { row in
            guard
                let rankText = row.intRank,
                let rank = Int(rankText),
                let teamName = row.strTeam
            else { return nil }

            let played = Int(row.intPlayed ?? "") ?? 0
            let wins = Int(row.intWin ?? "") ?? 0
            let draws = Int(row.intDraw ?? "") ?? 0
            let losses = Int(row.intLoss ?? "") ?? 0
            let goalsFor = Int(row.intGoalsFor ?? "") ?? 0
            let goalsAgainst = Int(row.intGoalsAgainst ?? "") ?? 0
            let goalDiff = Int(row.intGoalDifference ?? "") ?? (goalsFor - goalsAgainst)
            let points = Int(row.intPoints ?? "") ?? 0
            let formChars = Array((row.strForm ?? "").prefix(5))
            let badge = row.strTeamBadge ?? row.strBadge

            return LiveStandingRow(
                id: row.idStanding ?? row.idTeam ?? "\(rank)-\(teamName)",
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
                form: formChars,
                badgeURL: badge.flatMap(URL.init(string:))
            )
        }
        .sorted { $0.rank < $1.rank }
    }

    private func mapFixtures(_ rows: [SportsDBEvent]) -> [UCLFixtureRow] {
        rows.compactMap { item in
            guard
                let home = item.strHomeTeam,
                let away = item.strAwayTeam
            else { return nil }

            let dateTime = formatEventDate(item)
            let statusText = (item.strStatus?.isEmpty == false ? item.strStatus ?? "NS" : "NS")

            return UCLFixtureRow(
                id: item.idEvent ?? "\(home)-\(away)-\(dateTime.date)",
                home: home,
                away: away,
                homeScore: item.intHomeScore,
                awayScore: item.intAwayScore,
                dateText: dateTime.date,
                timeText: dateTime.time,
                status: statusText
            )
        }
    }

    private func fetchStandingsRows() async -> [SportsDBStanding] {
        guard let key = configuredSportsDBAPIKey() else { return [] }
        var components = URLComponents(string: "https://www.thesportsdb.com/api/v1/json/\(key)/lookuptable.php")
        components?.queryItems = [URLQueryItem(name: "l", value: championsLeagueID)]
        guard let url = components?.url else { return [] }

        guard
            let (data, _) = try? await URLSession.shared.data(from: url),
            let decoded = try? JSONDecoder().decode(SportsDBStandingsResponse.self, from: data)
        else { return [] }
        let rows = decoded.table ?? []
        if !rows.isEmpty { return rows }

        return []
    }

    private func fetchEventsRows(endpoint: String) async -> [SportsDBEvent] {
        guard let key = configuredSportsDBAPIKey() else { return [] }
        guard let url = URL(string: "https://www.thesportsdb.com/api/v1/json/\(key)/\(endpoint)?id=\(championsLeagueID)") else {
            return []
        }

        guard
            let (data, _) = try? await URLSession.shared.data(from: url),
            let decoded = try? JSONDecoder().decode(SportsDBEventsResponse.self, from: data)
        else { return [] }
        let rows = decoded.events ?? []
        if !rows.isEmpty { return rows }

        return []
    }

    private func loadChampionsLeagueData(force: Bool) async {
        if loading { return }
        if !force && !championsTable.isEmpty { return }

        await MainActor.run {
            loading = true
            errorMessage = ""
        }

        async let standingsTask = fetchStandingsRows()
        async let nextTask = fetchEventsRows(endpoint: "eventsnextleague.php")
        async let pastTask = fetchEventsRows(endpoint: "eventspastleague.php")

        let standings = await standingsTask
        let next = await nextTask
        let past = await pastTask

        let mappedStandings = mapStandings(standings)
        let mappedNext = mapFixtures(next)
        let mappedPast = mapFixtures(past)

        await MainActor.run {
            championsTable = mappedStandings
            nextFixtures = mappedNext
            recentFixtures = mappedPast
            lastUpdated = Date()
            loading = false

            if mappedStandings.isEmpty && mappedNext.isEmpty && mappedPast.isEmpty {
                errorMessage = t(
                    ar: "تعذر جلب البيانات حالياً",
                    en: "Unable to fetch data right now",
                    hi: "अभी डेटा लाना संभव नहीं",
                    zh: "当前无法获取数据",
                    ku: "لە ئێستادا ناتوانرێت داتا بهێنرێت"
                )
            }
        }
    }

    private func competitionBar(title: String, subtitle: String, gradient: [Color], glow: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.system(size: 23, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.93))
            }
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: glow.opacity(0.7), radius: 12, x: 0, y: 6)
        )
    }
}

#Preview {
    ContentView()
}
