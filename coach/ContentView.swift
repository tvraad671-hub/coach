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

private enum LiveTopLeague: String, CaseIterable, Identifiable {
    case championsLeague
    case premierLeague
    case laliga
    case serieA
    case bundesliga
    case ligue1

    var id: String { rawValue }

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

    func localizedTitle(in language: AppLanguage) -> String {
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
}

private struct LiveStandingRow: Identifiable {
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
    League(name: "الدوري الإسباني", teams: ["ريال مدريد", "برشلونة", "أتلتيكو مدريد", "إشبيلية", "ريال سوسيداد", "ريال بيتيس", "فياريال", "فالنسيا", "أتلتيك بلباو", "خيتافي", "أوساسونا", "جيرونا", "سيلتا فيغو", "ريال مايوركا", "غرناطة", "ألافيس", "قادش", "رايو فاليكانو", "لاس بالماس", "ألميريا"]),
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
    "ريال مايوركا": "Mallorca",
    "غرناطة": "Granada",
    "ألافيس": "Alaves",
    "قادش": "Cadiz",
    "رايو فاليكانو": "Rayo Vallecano",
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
        let data: Data
        do {
            let (responseData, response) = try await URLSession.shared.data(from: manifestURL)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw ImportError.downloadFailed
            }
            data = responseData
        } catch let importError as ImportError {
            throw importError
        } catch {
            throw ImportError.downloadFailed
        }

        let manifest: RemoteLogosManifest
        do {
            manifest = try JSONDecoder().decode(RemoteLogosManifest.self, from: data)
        } catch {
            throw ImportError.invalidManifest
        }

        var items: [RemoteLogoDownloadItem] = []
        for (clubName, urlString) in manifest.clubs {
            guard let remoteURL = URL(string: urlString) else { continue }
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

            let urlExtension = item.remoteURL.pathExtension.lowercased()
            let fileNameExtension = URL(fileURLWithPath: item.fileName).pathExtension.lowercased()
            let finalExtension = supportedImageExtensions.contains(urlExtension)
                ? urlExtension
                : (supportedImageExtensions.contains(fileNameExtension) ? fileNameExtension : "png")

            let cacheEntry = cache[normalizedBaseName]
            var request = URLRequest(url: item.remoteURL)
            request.cachePolicy = .reloadIgnoringLocalCacheData

            if cacheEntry?.sourceURL == item.remoteURL.absoluteString {
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
                    throw ImportError.downloadFailed
                }
                statusCode = http.statusCode
                responseData = data
                responseHeaders = http.allHeaderFields
            } catch let importError as ImportError {
                throw importError
            } catch {
                throw ImportError.downloadFailed
            }

            if statusCode == 304 {
                if logoURL(forKey: normalizedBaseName) != nil {
                    importedCount += 1
                    continue
                }
                throw ImportError.downloadFailed
            }

            guard (200...299).contains(statusCode) else {
                throw ImportError.downloadFailed
            }

            guard !responseData.isEmpty else {
                throw ImportError.invalidImageData
            }

#if canImport(UIKit)
            guard UIImage(data: responseData) != nil else {
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
                sourceURL: item.remoteURL.absoluteString,
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

                Text(t(ar: "مركز الشعارات", en: "Logos Center", hi: "लोगो सेंटर", zh: "队徽中心", ku: "ناوەندی شعارەکان"))
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

                        Text(t(ar: "تفعيل الشعارات المخصصة", en: "Activate custom logos", hi: "कस्टम लोगो सक्रिय करें", zh: "启用自定义队徽", ku: "چالاککردنی شعارە تایبەتیەکان"))
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
    @AppStorage("coach.selectedLanguage") private var selectedLanguageRaw = AppLanguage.arabic.rawValue
    @AppStorage("coach.downloadClubLogosEnabled") private var downloadClubLogosEnabled = false
    @ObservedObject private var logoStore = ClubLogoStore.shared
    @State private var step: GameStep = .welcome
    @State private var selectedLeague: League?
    @State private var selectedTeam: String?
    @State private var currentTab: DashboardTab = .simulator

    @State private var showSettings = false
    @State private var showCompetitions = false
    @State private var showMatchCenter = false
    @State private var showTeamRecord = false
    @State private var showPlayerSearch = false
    @State private var showMonthlyNews = false

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
        AppLanguage(rawValue: selectedLanguageRaw) ?? .arabic
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
            LinearGradient(
                colors: [FootballTheme.backgroundPrimary, FootballTheme.cardBase, FootballTheme.backgroundSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            content
                .padding(.horizontal, 18)
                .padding(.top, step == .welcome ? 82 : 24)
                .padding(.bottom, 8)
        }
        .overlay(alignment: .topTrailing) {
            if step == .welcome {
                settingsButton
                    .padding(.top, 18)
                    .padding(.trailing, 18)
            }
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
        .fullScreenCover(isPresented: $showSettings) {
            SettingsSheetView(selectedLanguage: selectedLanguageBinding)
        }
        .onAppear {
            restoreSavedGameIfNeeded()
        }
    }

    private var settingsButton: some View {
        Button {
            showSettings = true
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
        }
        .buttonStyle(.plain)
        .accessibilityLabel(t(ar: "الإعدادات", en: "Settings", hi: "सेटिंग्स", zh: "设置", ku: "ڕێکخستن"))
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
            VStack(spacing: 14) {
                welcomeEntryCard

                continueCareerCard
                importLogosCard

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(t(ar: "ترتيب الفرق (مباشر)", en: "Live Team Standings", hi: "लाइव टीम तालिका", zh: "实时球队排名", ku: "ڕیزبەندی تیمەکان (ڕاستەوخۆ)"))
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(FootballTheme.textPrimary)

                        Spacer()

                        Button {
                            Task { await loadLiveStandings(force: true) }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                Text(t(ar: "تحديث", en: "Refresh", hi: "रीफ़्रेश", zh: "刷新", ku: "نوێکردنەوە"))
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [FootballTheme.accentCyan, FootballTheme.cardGlow.opacity(0.92)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(liveLoading)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(LiveTopLeague.allCases) { league in
                                Button {
                                    selectedLiveLeague = league
                                } label: {
                                    Text(league.localizedTitle(in: language))
                                        .font(.system(size: 14, weight: .heavy))
                                        .foregroundStyle(selectedLiveLeague == league ? .black : FootballTheme.textPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(
                                                    selectedLiveLeague == league
                                                    ? LinearGradient(
                                                        colors: [FootballTheme.pitchGreen, FootballTheme.accentGreen],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                    : LinearGradient(
                                                        colors: [FootballTheme.cardBase.opacity(0.92), FootballTheme.backgroundSecondary.opacity(0.82)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if liveLoading && liveStandings.isEmpty {
                        HStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text(t(ar: "جاري تحميل الجدول الحقيقي...", en: "Loading the live standings...", hi: "लाइव तालिका लोड हो रही है...", zh: "正在加载实时积分榜...", ku: "خشتەی ڕاستەوخۆ بار دەکرێت..."))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(.vertical, 16)
                    } else if !liveErrorMessage.isEmpty && liveStandings.isEmpty {
                        Text(
                            liveErrorMessage == "عرض مؤقت - سيتم التحديث تلقائيًا عند توفر البيانات المباشرة"
                            ? t(ar: "عرض مؤقت - سيتم التحديث تلقائيًا عند توفر البيانات المباشرة", en: "Temporary view - it will refresh automatically when live data is available", hi: "अस्थायी दृश्य - लाइव डेटा उपलब्ध होते ही यह अपने आप अपडेट होगा", zh: "当前为临时显示，实时数据可用后将自动刷新", ku: "پیشاندانی کاتییە - کاتێک داتای ڕاستەوخۆ بەردەست بێت خۆکار نوێ دەبێتەوە")
                            : liveErrorMessage
                        )
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(FootballTheme.dangerRed.opacity(0.95))
                    } else {
                        ScrollView(.horizontal, showsIndicators: true) {
                            VStack(spacing: 8) {
                                HStack(spacing: 6) {
                                    liveHeaderCell(t(ar: "م", en: "#", hi: "#", zh: "名", ku: "پ"), width: 32)
                                    liveHeaderCell(t(ar: "الفريق", en: "Team", hi: "टीम", zh: "球队", ku: "تیم"), width: 170)
                                    liveHeaderCell(t(ar: "ل", en: "P", hi: "P", zh: "赛", ku: "ی"), width: 34)
                                    liveHeaderCell(t(ar: "ف", en: "W", hi: "W", zh: "胜", ku: "ب"), width: 34)
                                    liveHeaderCell(t(ar: "ت", en: "D", hi: "D", zh: "平", ku: "ی"), width: 34)
                                    liveHeaderCell(t(ar: "خ", en: "L", hi: "L", zh: "负", ku: "د"), width: 34)
                                    liveHeaderCell(t(ar: "له", en: "GF", hi: "GF", zh: "进", ku: "بۆ"), width: 40)
                                    liveHeaderCell(t(ar: "عليه", en: "GA", hi: "GA", zh: "失", ku: "لەسەر"), width: 44)
                                    liveHeaderCell("±", width: 36)
                                    liveHeaderCell(t(ar: "ن", en: "Pts", hi: "Pts", zh: "分", ku: "خال"), width: 36)
                                    liveHeaderCell(t(ar: "آخر 5", en: "Last 5", hi: "पिछले 5", zh: "近5场", ku: "دوا 5"), width: 130)
                                }

                                ForEach(liveStandings) { row in
                                    HStack(spacing: 6) {
                                        liveValueCell("\(row.rank)", width: 32, bold: true, color: FootballTheme.pointsYellow)

                                        HStack(spacing: 6) {
                                            TeamLogoView(teamName: row.teamName, size: 21)

                                            Text(localizedDisplayName(row.teamName, in: language))
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(.white)
                                                .lineLimit(1)

                                            Spacer(minLength: 0)
                                        }
                                        .frame(width: 170, alignment: .leading)

                                        liveValueCell("\(row.played)", width: 34)
                                        liveValueCell("\(row.wins)", width: 34)
                                        liveValueCell("\(row.draws)", width: 34)
                                        liveValueCell("\(row.losses)", width: 34)
                                        liveValueCell("\(row.goalsFor)", width: 40)
                                        liveValueCell("\(row.goalsAgainst)", width: 44)
                                        liveValueCell("\(row.goalDiff)", width: 36)
                                        liveValueCell("\(row.points)", width: 36, bold: true, color: .white)

                                        HStack(spacing: 4) {
                                            ForEach(Array(row.form.prefix(5).enumerated()), id: \.offset) { _, result in
                                                formBadge(result)
                                            }
                                        }
                                        .frame(width: 130, alignment: .leading)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(FootballTheme.cardBase.opacity(0.76))
                                    )
                                }
                            }
                        }
                    }

                    if let last = liveLastUpdated {
                        Text("\(t(ar: "آخر تحديث", en: "Last update", hi: "आख़िरी अपडेट", zh: "最后更新", ku: "دوایین نوێکردنەوە")): \(liveUpdatedText(from: last))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(FootballTheme.textSecondary)
                    }

                    if !liveErrorMessage.isEmpty && !liveStandings.isEmpty {
                        Text(
                            liveErrorMessage == "عرض مؤقت - سيتم التحديث تلقائيًا عند توفر البيانات المباشرة"
                            ? t(ar: "عرض مؤقت - سيتم التحديث تلقائيًا عند توفر البيانات المباشرة", en: "Temporary view - it will refresh automatically when live data is available", hi: "अस्थायी दृश्य - लाइव डेटा उपलब्ध होते ही यह अपने आप अपडेट होगा", zh: "当前为临时显示，实时数据可用后将自动刷新", ku: "پیشاندانی کاتییە - کاتێک داتای ڕاستەوخۆ بەردەست بێت خۆکار نوێ دەبێتەوە")
                            : liveErrorMessage
                        )
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(FootballTheme.accentCyan.opacity(0.9))
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(FootballTheme.cardBase.opacity(0.80))
                )
            }
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .task(id: selectedLiveLeague) {
            await loadLiveStandings(force: false)
        }
        .onReceive(liveAutoRefreshTimer) { _ in
            Task { await loadLiveStandings(force: true) }
        }
    }

    private var welcomeEntryCard: some View {
        let supportedLeagues = topLeagues.count

        return Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.84)) {
                step = .leagueSelection
            }
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
            .frame(height: 214)
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
                logoImporterStatusIsSuccess = false
                logoImporterStatusText = localizedLogoImportError(importError)
            } catch {
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
                logoImporterStatusIsSuccess = false
                logoImporterStatusText = localizedLogoImportError(importError)
            } catch {
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
            return t(ar: "فشل تحميل الشعارات من روابط GitHub.", en: "Failed to download logos from GitHub links.", hi: "GitHub लिंक से लोगो डाउनलोड नहीं हुए।", zh: "从 GitHub 链接下载队徽失败。", ku: "داگرتنی شعارەکان لە لینکەکانی GitHub سەرکەوتوو نەبوو.")
        case .invalidImageData:
            return t(ar: "الملف المحمّل ليس صورة صالحة.", en: "Downloaded file is not a valid image.", hi: "डाउनलोड की गई फ़ाइल मान्य इमेज नहीं है।", zh: "下载的文件不是有效图片。", ku: "پەڕگەی داگیراو وێنەیەکی دروست نییە.")
        case .invalidManifest:
            return t(ar: "ملف logos.json غير صالح أو لا يحتوي روابط شعارات.", en: "logos.json is invalid or has no logo links.", hi: "logos.json अमान्य है या इसमें लोगो लिंक नहीं हैं।", zh: "logos.json 无效或不包含队徽链接。", ku: "پەڕگەی logos.json دروست نییە یان لینکەکانی شعار لەخۆناگرێت.")
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

    private func seasonCandidates() -> [String] {
        let year = Calendar.current.component(.year, from: Date())
        let current = "\(year - 1)-\(year)"
        let previous = "\(year - 2)-\(year - 1)"
        let next = "\(year)-\(year + 1)"
        return [current, previous, next]
    }

    private func parsedEventDate(_ event: SportsDBEvent) -> Date {
        if let ts = event.strTimestamp, let parsed = ISO8601DateFormatter().date(from: ts) {
            return parsed
        }
        if let dateText = event.dateEvent {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd"
            if let parsed = formatter.date(from: dateText) {
                return parsed
            }
        }
        return .distantPast
    }

    private func fetchLiveStandingsRows(league: LiveTopLeague) async -> [SportsDBStanding] {
        guard let key = configuredSportsDBAPIKey() else { return [] }
        let seasons = seasonCandidates()

        for season in seasons {
            var components = URLComponents(string: "https://www.thesportsdb.com/api/v1/json/\(key)/lookuptable.php")
            components?.queryItems = [
                URLQueryItem(name: "l", value: league.sportsDBLeagueId),
                URLQueryItem(name: "s", value: season)
            ]

            guard let url = components?.url else { continue }

            guard
                let (data, _) = try? await URLSession.shared.data(from: url),
                let decoded = try? JSONDecoder().decode(SportsDBStandingsResponse.self, from: data)
            else { continue }
            let rows = decoded.table ?? []
            if !rows.isEmpty {
                return rows
            }
        }

        var components = URLComponents(string: "https://www.thesportsdb.com/api/v1/json/\(key)/lookuptable.php")
        components?.queryItems = [URLQueryItem(name: "l", value: league.sportsDBLeagueId)]
        guard let url = components?.url else { return [] }

        guard
            let (data, _) = try? await URLSession.shared.data(from: url),
            let decoded = try? JSONDecoder().decode(SportsDBStandingsResponse.self, from: data)
        else { return [] }
        let rows = decoded.table ?? []
        if !rows.isEmpty {
            return rows
        }

        return []
    }

    private func fetchPastEvents(league: LiveTopLeague) async -> [SportsDBEvent] {
        guard let key = configuredSportsDBAPIKey() else { return [] }
        let seasons = seasonCandidates()

        for season in seasons {
            var components = URLComponents(string: "https://www.thesportsdb.com/api/v1/json/\(key)/eventspastleague.php")
            components?.queryItems = [
                URLQueryItem(name: "id", value: league.sportsDBLeagueId),
                URLQueryItem(name: "s", value: season)
            ]
            guard let url = components?.url else { continue }

            guard
                let (data, _) = try? await URLSession.shared.data(from: url),
                let decoded = try? JSONDecoder().decode(SportsDBEventsResponse.self, from: data)
            else { continue }
            let rows = decoded.events ?? []
            if !rows.isEmpty { return rows }
        }

        guard let url = URL(string: "https://www.thesportsdb.com/api/v1/json/\(key)/eventspastleague.php?id=\(league.sportsDBLeagueId)") else {
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

    private func fallbackStandingsFromEvents(_ events: [SportsDBEvent]) -> [LiveStandingRow] {
        struct Agg {
            var played = 0
            var wins = 0
            var draws = 0
            var losses = 0
            var gf = 0
            var ga = 0
            var points = 0
            var form: [Character] = []
        }

        let sortedEvents = events
            .filter { Int($0.intHomeScore ?? "") != nil && Int($0.intAwayScore ?? "") != nil }
            .sorted { parsedEventDate($0) < parsedEventDate($1) }

        var table: [String: Agg] = [:]

        for event in sortedEvents {
            guard
                let home = event.strHomeTeam,
                let away = event.strAwayTeam,
                let homeScore = Int(event.intHomeScore ?? ""),
                let awayScore = Int(event.intAwayScore ?? "")
            else { continue }

            var homeAgg = table[home, default: Agg()]
            var awayAgg = table[away, default: Agg()]

            homeAgg.played += 1
            awayAgg.played += 1
            homeAgg.gf += homeScore
            homeAgg.ga += awayScore
            awayAgg.gf += awayScore
            awayAgg.ga += homeScore

            if homeScore > awayScore {
                homeAgg.wins += 1
                homeAgg.points += 3
                awayAgg.losses += 1
                homeAgg.form.append("W")
                awayAgg.form.append("L")
            } else if homeScore < awayScore {
                awayAgg.wins += 1
                awayAgg.points += 3
                homeAgg.losses += 1
                homeAgg.form.append("L")
                awayAgg.form.append("W")
            } else {
                homeAgg.draws += 1
                awayAgg.draws += 1
                homeAgg.points += 1
                awayAgg.points += 1
                homeAgg.form.append("D")
                awayAgg.form.append("D")
            }

            table[home] = homeAgg
            table[away] = awayAgg
        }

        let sortedTeams = table.map { (name: $0.key, stats: $0.value) }.sorted {
            if $0.stats.points != $1.stats.points { return $0.stats.points > $1.stats.points }
            let gd0 = $0.stats.gf - $0.stats.ga
            let gd1 = $1.stats.gf - $1.stats.ga
            if gd0 != gd1 { return gd0 > gd1 }
            return $0.stats.gf > $1.stats.gf
        }

        return sortedTeams.enumerated().map { index, item in
            LiveStandingRow(
                id: "fallback-\(item.name)",
                rank: index + 1,
                teamName: item.name,
                played: item.stats.played,
                wins: item.stats.wins,
                draws: item.stats.draws,
                losses: item.stats.losses,
                goalsFor: item.stats.gf,
                goalsAgainst: item.stats.ga,
                goalDiff: item.stats.gf - item.stats.ga,
                points: item.stats.points,
                form: Array(item.stats.form.suffix(5)),
                badgeURL: nil
            )
        }
    }

    private func fallbackLocalStandings(for league: LiveTopLeague) -> [LiveStandingRow] {
        let teams: [String]
        switch league {
        case .championsLeague:
            teams = ["ريال مدريد", "مانشستر سيتي", "بايرن ميونخ", "برشلونة", "باريس سان جيرمان", "إنتر ميلان", "أرسنال", "دورتموند"]
        case .premierLeague:
            teams = ["ليفربول", "مانشستر سيتي", "أرسنال", "توتنهام", "أستون فيلا", "تشيلسي", "نيوكاسل", "مانشستر يونايتد"]
        case .laliga:
            teams = ["ريال مدريد", "برشلونة", "أتلتيكو مدريد", "أتلتيك بلباو", "ريال سوسيداد", "ريال بيتيس", "فياريال", "فالنسيا"]
        case .serieA:
            teams = ["إنتر ميلان", "يوفنتوس", "ميلان", "نابولي", "روما", "لاتسيو", "أتلانتا", "فيورنتينا"]
        case .bundesliga:
            teams = ["بايرن ميونخ", "ليفركوزن", "دورتموند", "لايبزيغ", "شتوتغارت", "فرانكفورت", "فرايبورغ", "هوفنهايم"]
        case .ligue1:
            teams = ["باريس سان جيرمان", "موناكو", "ليل", "مارسيليا", "نيس", "رين", "ليون", "لانس"]
        }

        return teams.enumerated().map { index, name in
            let played = 24
            let wins = max(3, 15 - index)
            let draws = min(8, index / 2 + 2)
            let losses = max(0, played - wins - draws)
            let goalsFor = max(18, 45 - index * 2)
            let goalsAgainst = 20 + index
            let points = wins * 3 + draws

            return LiveStandingRow(
                id: "local-\(league.rawValue)-\(index)",
                rank: index + 1,
                teamName: name,
                played: played,
                wins: wins,
                draws: draws,
                losses: losses,
                goalsFor: goalsFor,
                goalsAgainst: goalsAgainst,
                goalDiff: goalsFor - goalsAgainst,
                points: points,
                form: ["W", "W", "D", "L", "W"],
                badgeURL: nil
            )
        }
    }

    private func loadLiveStandings(force: Bool) async {
        if liveLoading { return }
        if !force && !liveStandings.isEmpty && liveLoadedLeague == selectedLiveLeague { return }

        let league = selectedLiveLeague
        let hasSportsDBKey = configuredSportsDBAPIKey() != nil

        await MainActor.run {
            liveLoading = true
            liveErrorMessage = ""
            if liveLoadedLeague != league {
                liveStandings = []
            }
        }

        let apiRows = await fetchLiveStandingsRows(league: league)

        let mapped = apiRows.compactMap { row -> LiveStandingRow? in
            guard
                let rankText = row.intRank,
                let rank = Int(rankText),
                let teamName = row.strTeam
            else {
                return nil
            }

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

        var finalRows = mapped
        if finalRows.isEmpty && league == .championsLeague {
            let pastEvents = await fetchPastEvents(league: league)
            finalRows = fallbackStandingsFromEvents(pastEvents)
        }

        await MainActor.run {
            liveStandings = finalRows
            liveLastUpdated = Date()
            liveLoadedLeague = league
            liveLoading = false
            if finalRows.isEmpty {
                liveStandings = fallbackLocalStandings(for: league)
                liveErrorMessage = hasSportsDBKey
                    ? "عرض مؤقت - سيتم التحديث تلقائيًا عند توفر البيانات المباشرة"
                    : t(
                        ar: "أضف مفتاح API مدفوع لمصدر البيانات لعرض النتائج المباشرة.",
                        en: "Add a paid API key for the data provider to show live results.",
                        hi: "लाइव परिणाम दिखाने के लिए डेटा प्रदाता की पेड API key जोड़ें।",
                        zh: "请添加数据提供方的付费 API key 以显示实时结果。",
                        ku: "بۆ پیشاندانی ئەنجامی ڕاستەوخۆ، کلیلی APIی پارەدانەوەی سەرچاوەی داتا زیاد بکە."
                    )
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

            VStack(spacing: 9) {
                HubHeader(
                    teamName: localizedDisplayName(selectedTeam ?? "", in: language),
                    roundText: roundText,
                    selectedTeam: selectedTeam,
                    mainMenuLabel: t(ar: "القائمة الرئيسية", en: "Main Menu", hi: "मुख्य मेन्यू", zh: "主菜单", ku: "لیستی سەرەکی"),
                    saveLabel: t(ar: "حفظ", en: "Save", hi: "सेव", zh: "保存", ku: "هەڵگرتن"),
                    onMainMenu: goBackToMainMenu,
                    onSave: saveGame
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

                SimulateDaysButton(
                    title: t(ar: "محاكاة الأيام", en: "Simulate Days", hi: "दिनों का सिमुलेशन", zh: "模拟天数", ku: "شبیه‌کردنی ڕۆژەکان"),
                    disabled: matchWeek > totalWeeks || (isCurrentMatchDay && !isSimulatingDays),
                    isRunning: isSimulatingDays,
                    onTap: runSimulateDays
                )

                if isCurrentMatchDay && matchWeek <= totalWeeks {
                    PlayMatchButton(
                        title: t(ar: "ابدأ المباراة", en: "Play Match", hi: "मैच शुरू करें", zh: "开始比赛", ku: "یاری دەستپێبکە"),
                        onTap: openMatchCenterFromHub
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

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
                .id(newsAnimationKey)
                .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.95)))
                .animation(.spring(response: 0.42, dampingFraction: 0.80), value: newsAnimationKey)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var teamView: some View {
        let myStats = seasonTable[selectedTeam ?? ""] ?? TeamStanding()
        let squad = lineup + bench

        return VStack(spacing: 12) {
            HStack {
                Button {
                    showTeamRecord = true
                } label: {
                    Text(t(ar: "سجل الفريق", en: "Team Record", hi: "टीम रिकॉर्ड", zh: "球队战绩", ku: "تۆماری تیم"))
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(FootballTheme.pitchGreen)
                        )
                }
                .buttonStyle(.plain)

                Spacer()
            }

            headerTitle(t(ar: "لاعبين الفريق", en: "Team Players", hi: "टीम खिलाड़ी", zh: "球队球员", ku: "یاریزانانی تیم"))

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(squad) { player in
                        playerSquare(player)
                    }
                }
            }

            infoRow(
                t(ar: "سجل الموسم", en: "Season Record", hi: "सीज़न रिकॉर्ड", zh: "赛季战绩", ku: "تۆماری وەرز"),
                "\(t(ar: "ف", en: "W", hi: "W", zh: "胜", ku: "ب"))\(myStats.wins) - \(t(ar: "ت", en: "D", hi: "D", zh: "平", ku: "ی"))\(myStats.draws) - \(t(ar: "خ", en: "L", hi: "L", zh: "负", ku: "د"))\(myStats.losses)"
            )
            infoRow(
                t(ar: "الأهداف", en: "Goals", hi: "गोल", zh: "进球", ku: "گۆڵەکان"),
                "\(t(ar: "له", en: "GF", hi: "GF", zh: "进", ku: "بۆ")) \(myStats.goalsFor) / \(t(ar: "عليه", en: "GA", hi: "GA", zh: "失", ku: "لەسەر")) \(myStats.goalsAgainst)"
            )
            awardsSummaryCard
        }
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
        showMatchCenter = false
        showTeamRecord = false
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
        selectedLiveLeague = LiveTopLeague(rawValue: saved.selectedLiveLeagueRaw) ?? .premierLeague
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
    let teamName: String
    let roundText: String
    let selectedTeam: String?
    let mainMenuLabel: String
    let saveLabel: String
    let onMainMenu: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                logoBadge

                Spacer(minLength: 8)

                HStack(spacing: 8) {
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

                    Button(action: onMainMenu) {
                        Label(mainMenuLabel, systemImage: "house.fill")
                            .font(.system(size: 13, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .foregroundStyle(FootballTheme.textPrimary.opacity(0.92))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
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
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(teamName.isEmpty ? "—" : teamName)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text(roundText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
                .frame(width: 66, height: 66)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.28), lineWidth: 1.2)
                )

            if let selectedTeam {
                TeamLogoView(teamName: selectedTeam, size: 46)
            } else {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
            }
        }
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
                    Image(systemName: "forward.fill")
                        .font(.system(size: 18, weight: .black))
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
                            .stroke(isRunning ? Color.white.opacity(0.45) : Color.clear, lineWidth: 1.2)
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
        if disabled && !isRunning {
            return .clear
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
                                .lineLimit(2)
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
                    .lineLimit(compact ? 2 : 3)
                    .minimumScaleFactor(0.86)

                Text(timeText)
                    .font(.system(size: compact ? 12 : 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.64))
                    .lineLimit(1)
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

    private func t(ar: String, en: String, hi: String, zh: String, ku: String) -> String {
        selectedLanguage.text(ar: ar, en: en, hi: hi, zh: zh, ku: ku)
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
                    .fill(FootballTheme.accentCyan.opacity(0.16))
                    .frame(width: 240, height: 240)
                    .blur(radius: 8)
                    .offset(x: 120, y: -250)

                Circle()
                    .fill(FootballTheme.pitchGreen.opacity(0.12))
                    .frame(width: 220, height: 220)
                    .blur(radius: 12)
                    .offset(x: -140, y: 260)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(t(ar: "الإعدادات", en: "Settings", hi: "सेटिंग्स", zh: "设置", ku: "ڕێکخستن"))
                                    .font(.system(size: 34, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(t(ar: "اختَر اللغة وطالع الإرشادات من شاشة كاملة أنيقة.", en: "Choose the language and open the guide from a polished full-screen panel.", hi: "भाषा चुनें और एक सुंदर पूर्ण-स्क्रीन पैनल से निर्देश खोलें।", zh: "在一个完整且精致的全屏界面中选择语言并打开说明。", ku: "زمان هەڵبژێرە و ڕێنمایییەکان لە شاشەیەکی تەواو و جوان بکەرەوە."))
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
                                    .background(
                                        Circle()
                                            .fill(FootballTheme.cardBase.opacity(0.74))
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(FootballTheme.cardGlow.opacity(0.30), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [FootballTheme.accentCyan, FootballTheme.pitchGreen],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 72, height: 72)
                                    Image(systemName: "gearshape.2.fill")
                                        .font(.system(size: 28, weight: .black))
                                        .foregroundStyle(.white)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(t(ar: "تخصيص التجربة", en: "Customize the Experience", hi: "अनुभव को अनुकूलित करें", zh: "自定义体验", ku: "ئەزموونەکە تایبەت بکە"))
                                        .font(.system(size: 23, weight: .black, design: .rounded))
                                        .foregroundStyle(.white)
                                    Text(t(ar: "كل تغيير ينعكس مباشرة على واجهة اللعبة.", en: "Every change is applied directly to the game interface.", hi: "हर बदलाव सीधे खेल की स्क्रीन पर लागू होगा।", zh: "每个改动都会立即应用到游戏界面。", ku: "هەموو گۆڕانکارییەک ڕاستەوخۆ لەسەر ڕووکارەکەی یاری دەردەکەوێت."))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.78))
                                }
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(FootballTheme.cardBase.opacity(0.62))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(FootballTheme.cardGlow.opacity(0.24), lineWidth: 1)
                        )

                        VStack(alignment: .leading, spacing: 12) {
                            Text(t(ar: "اختيار اللغة", en: "Choose Language", hi: "भाषा चुनें", zh: "选择语言", ku: "زمان هەڵبژێرە"))
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundStyle(.white)

                            ForEach(AppLanguage.allCases) { language in
                                Button {
                                    selectedLanguage = language
                                } label: {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(language.nativeName)
                                                .font(.system(size: 19, weight: .bold))
                                                .foregroundStyle(selectedLanguage == language ? .black : .white)
                                            Text(
                                                language.text(
                                                    ar: "تفعيل كامل للواجهة",
                                                    en: "Apply to the full interface",
                                                    hi: "पूरी इंटरफ़ेस पर लागू करें",
                                                    zh: "应用到整个界面",
                                                    ku: "بۆ تەواوی ڕووکارەکە جێبەجێ بکە"
                                                )
                                            )
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(selectedLanguage == language ? Color.black.opacity(0.65) : .white.opacity(0.68))
                                        }

                                        Spacer()

                                        Image(systemName: selectedLanguage == language ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(selectedLanguage == language ? Color.black : .white.opacity(0.75))
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(
                                                selectedLanguage == language
                                                ? LinearGradient(
                                                    colors: [FootballTheme.accentGreen, FootballTheme.accentCyan],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                                : LinearGradient(
                                                    colors: [FootballTheme.cardBase.opacity(0.72), FootballTheme.backgroundSecondary.opacity(0.56)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(selectedLanguage == language ? Color.white.opacity(0.35) : Color.white.opacity(0.10), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(FootballTheme.backgroundPrimary.opacity(0.42))
                        )

                        NavigationLink {
                            GuideView(language: selectedLanguage)
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(FootballTheme.cardBase.opacity(0.74))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "book.fill")
                                        .font(.system(size: 20, weight: .black))
                                        .foregroundStyle(.white)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(t(ar: "الإرشادات", en: "Instructions", hi: "निर्देश", zh: "说明", ku: "ڕێنمایی"))
                                        .font(.system(size: 19, weight: .black))
                                        .foregroundStyle(.white)
                                    Text(t(ar: "افتح شاشة التعريف باللعبة وفائدتها.", en: "Open the game guide and value overview.", hi: "खेल की जानकारी और उसके लाभ देखें।", zh: "打开游戏介绍与价值说明。", ku: "شاشەی ناساندنی یاری و سوودەکانی بکەرەوە."))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.78))
                                }

                                Spacer()

                                Image(systemName: "chevron.forward")
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            .padding(18)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [FootballTheme.accentCyan, FootballTheme.pitchGreen],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: FootballTheme.accentCyan.opacity(0.22), radius: 16, x: 0, y: 10)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            LegalCenterView(language: selectedLanguage)
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(FootballTheme.cardBase.opacity(0.74))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.system(size: 20, weight: .black))
                                        .foregroundStyle(.white)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(t(ar: "القانون والخصوصية", en: "Legal & Privacy", hi: "कानूनी और गोपनीयता", zh: "法律与隐私", ku: "یاسا و نهێنی"))
                                        .font(.system(size: 19, weight: .black))
                                        .foregroundStyle(.white)
                                    Text(t(ar: "سياسة الخصوصية، الدعم، وإخلاء المسؤولية.", en: "Privacy policy, support, and disclaimer.", hi: "गोपनीयता नीति, सपोर्ट और अस्वीकरण।", zh: "隐私政策、支持与免责声明。", ku: "سیاسەتی نهێنی، پشتگیری و ڕەتکردنەوەی بەرپرسیارێتی."))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.78))
                                }

                                Spacer()

                                Image(systemName: "chevron.forward")
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            .padding(18)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [FootballTheme.cardBase.opacity(0.86), FootballTheme.backgroundSecondary.opacity(0.78)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(FootballTheme.cardGlow.opacity(0.22), lineWidth: 1)
                            )
                            .shadow(color: FootballTheme.cardGlow.opacity(0.14), radius: 14, x: 0, y: 9)
                        }
                        .buttonStyle(.plain)

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
        }
        .environment(\.layoutDirection, selectedLanguage.layoutDirection)
        .toolbar(.hidden, for: .navigationBar)
    }
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

    private var matchDateText: String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMMM")
        return formatter.string(from: matchDate)
    }

    private var matchTimeText: String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: matchDate)
    }

    private func beginMatchExperience() {
        selectedHistorySelection = nil
        minute = 0
        myGoals = 0
        oppGoals = 0
        events = [
            MatchEvent(
                minute: 0,
                text: t(ar: "صافرة البداية!", en: "Kickoff whistle!", hi: "किकऑफ़ सीटी!", zh: "开场哨响！", ku: "سڕوتی دەستپێک!")
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

        let eventChance = max(12, min(50, 24 + ((squadStrength - 70) / 2) + tacticalPlan.attackBoost + approachBoost))
        let baseChance = 52
            + ((squadStrength - 72) / 2)
            + ((fanSatisfaction - 70) / 5)
            + tacticalPlan.attackBoost
            + pressingAttackBoost
            - (tacticalPlan.defenseBoost / 2)
        let myChancePercent = max(28, min(82, baseChance))

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
        let hasSportsDBKey = configuredSportsDBAPIKey() != nil

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
                errorMessage = hasSportsDBKey
                    ? "تعذر جلب بيانات دوري الأبطال حالياً"
                    : t(
                        ar: "أضف مفتاح API مدفوع لمصدر البيانات لعرض بيانات دوري الأبطال.",
                        en: "Add a paid API key for the data provider to show Champions League data.",
                        hi: "चैंपियंस लीग डेटा दिखाने के लिए डेटा प्रदाता की पेड API key जोड़ें।",
                        zh: "请添加数据提供方的付费 API key 以显示欧冠数据。",
                        ku: "بۆ پیشاندانی داتای لیگی پاڵەوانان، کلیلی APIی پارەدانەوەی سەرچاوەی داتا زیاد بکە."
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
