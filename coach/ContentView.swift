import SwiftUI
import Combine

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
}

private let topLeagues: [League] = [
    League(name: "الدوري الإنجليزي", teams: ["مانشستر سيتي", "أرسنال", "ليفربول", "تشيلسي", "مانشستر يونايتد", "توتنهام", "نيوكاسل", "أستون فيلا", "برايتون", "وست هام", "ولفرهامبتون", "فولهام", "كريستال بالاس", "برينتفورد", "إيفرتون", "نوتنغهام فورست", "بورنموث", "بيرنلي", "شيفيلد يونايتد", "لوتون تاون"]),
    League(name: "الدوري الإسباني", teams: ["ريال مدريد", "برشلونة", "أتلتيكو مدريد", "إشبيلية", "ريال سوسيداد", "ريال بيتيس", "فياريال", "فالنسيا", "أتلتيك بلباو", "خيتافي", "أوساسونا", "جيرونا", "سيلتا فيغو", "ريال مايوركا", "غرناطة", "ألافيس", "قادش", "رايو فاليكانو", "لاس بالماس", "ألميريا"]),
    League(name: "الدوري الإيطالي", teams: ["إنتر ميلان", "يوفنتوس", "ميلان", "نابولي", "روما", "لاتسيو", "أتلانتا", "فيورنتينا", "بولونيا", "تورينو", "ساسولو", "أودينيزي", "جنوى", "مونزا", "إمبولي", "ليتشي", "فروزينوني", "هيلاس فيرونا", "كالياري", "ساليرنيتانا"]),
    League(name: "الدوري الألماني", teams: ["بايرن ميونخ", "بوروسيا دورتموند", "لايبزيغ", "باير ليفركوزن", "شتوتغارت", "فولفسبورغ", "آينتراخت فرانكفورت", "هوفنهايم", "فرايبورغ", "ماينز", "أوغسبورغ", "بوروسيا مونشنغلادباخ", "فيردر بريمن", "يونيون برلين", "كولن", "بوخوم", "دارمشتات", "هايدنهايم", "سانت باولي", "هامبورغ"]),
    League(name: "الدوري الفرنسي", teams: ["باريس سان جيرمان", "مارسيليا", "ليون", "موناكو", "ليل", "رين", "نيس", "لانس", "ستاد ريمس", "مونبلييه", "ستراسبورغ", "نانت", "بريست", "تولوز", "لوهافر", "ميتز", "أنجيه", "لوريان", "كليرمون", "أوكسير"])
]

private let laligaLogoAssetByTeam: [String: String] = [
    "ريال مدريد": "Real Madrid",
    "Real Madrid": "Real Madrid",
    "Real Madrid CF": "Real Madrid",
    "برشلونة": "FC Barcelona",
    "Barcelona": "FC Barcelona",
    "FC Barcelona": "FC Barcelona",
    "Barça": "FC Barcelona",
    "FCB": "FC Barcelona",
    "أتلتيكو مدريد": "Atletico Madrid",
    "اتلتيكو مدريد": "Atletico Madrid",
    "Atletico Madrid": "Atletico Madrid",
    "Atletico de Madrid": "Atletico Madrid",
    "Atlético Madrid": "Atletico Madrid",
    "Atlético de Madrid": "Atletico Madrid",
    "Atl Madrid": "Atletico Madrid",
    "إشبيلية": "Sevilla",
    "Sevilla": "Sevilla",
    "Sevilla FC": "Sevilla",
    "ريال سوسيداد": "Real Sociedad",
    "Real Sociedad": "Real Sociedad",
    "Real Sociedad de Futbol": "Real Sociedad",
    "ريال بيتيس": "Real Betis",
    "Real Betis": "Real Betis",
    "Real Betis Balompie": "Real Betis",
    "فياريال": "Villarreal",
    "Villarreal": "Villarreal",
    "Villarreal CF": "Villarreal",
    "فالنسيا": "Valencia",
    "Valencia": "Valencia",
    "Valencia CF": "Valencia",
    "أتلتيك بلباو": "Athletic Bilbao",
    "اثلتيك بلباو": "Athletic Bilbao",
    "Athletic Bilbao": "Athletic Bilbao",
    "Athletic Club": "Athletic Bilbao",
    "خيتافي": "Getafe",
    "Getafe": "Getafe",
    "Getafe CF": "Getafe",
    "أوساسونا": "Osasuna",
    "Osasuna": "Osasuna",
    "CA Osasuna": "Osasuna",
    "جيرونا": "Girona",
    "Girona": "Girona",
    "Girona FC": "Girona",
    "سيلتا فيغو": "Celta Vigo",
    "Celta Vigo": "Celta Vigo",
    "Celta de Vigo": "Celta Vigo",
    "ريال مايوركا": "Mallorca",
    "مايوركا": "Mallorca",
    "Mallorca": "Mallorca",
    "RCD Mallorca": "Mallorca",
    "ألافيس": "Alaves",
    "Alaves": "Alaves",
    "Deportivo Alaves": "Alaves",
    "رايو فاليكانو": "Rayo Vallecano",
    "Rayo Vallecano": "Rayo Vallecano",
    "Rayo": "Rayo Vallecano",
    "إسبانيول": "Espanyol",
    "Espanyol": "Espanyol",
    "RCD Espanyol": "Espanyol",
    "إلتشي": "Elche",
    "إلشي": "Elche",
    "Elche": "Elche",
    "Elche CF": "Elche",
    "ليفانتي": "Levante",
    "Levante": "Levante",
    "Levante UD": "Levante",
    "ريال أوفييدو": "Real Oviedo",
    "ريال اوفييدو": "Real Oviedo",
    "Real Oviedo": "Real Oviedo"
]

private func laligaLogoAssetName(for teamName: String) -> String? {
    laligaLogoAssetByTeam[teamName]
}

private struct SyntheticBadgeStyle {
    let label: String
    let miniLabel: String
    let start: Color
    let end: Color
}

private func normalizedTeamKey(_ name: String) -> String {
    name
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
}

private func syntheticBadgeStyle(for teamName: String) -> SyntheticBadgeStyle? {
    let key = normalizedTeamKey(teamName)
    switch key {
    case "غرناطة", "غرناطه", "granada", "granada cf":
        return SyntheticBadgeStyle(
            label: "GRA",
            miniLabel: "G",
            start: Color(red: 0.75, green: 0.10, blue: 0.18),
            end: Color(red: 0.52, green: 0.05, blue: 0.12)
        )
    case "قادش", "cadiz", "cadiz cf":
        return SyntheticBadgeStyle(
            label: "CAD",
            miniLabel: "C",
            start: Color(red: 1.0, green: 0.83, blue: 0.08),
            end: Color(red: 0.07, green: 0.23, blue: 0.67)
        )
    case "لاس بالماس", "las palmas", "ud las palmas":
        return SyntheticBadgeStyle(
            label: "LPA",
            miniLabel: "L",
            start: Color(red: 1.0, green: 0.79, blue: 0.10),
            end: Color(red: 0.05, green: 0.33, blue: 0.70)
        )
    case "ألميريا", "الميريا", "almeria", "ud almeria":
        return SyntheticBadgeStyle(
            label: "ALM",
            miniLabel: "A",
            start: Color(red: 0.92, green: 0.16, blue: 0.16),
            end: Color(red: 0.75, green: 0.08, blue: 0.12)
        )
    default:
        return nil
    }
}

private struct TeamLogoView: View {
    let teamName: String
    let size: CGFloat

    var body: some View {
        if let asset = laligaLogoAssetName(for: teamName) {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else if let customBadge = syntheticBadgeStyle(for: teamName) {
            let badgeText = size < 18 ? customBadge.miniLabel : customBadge.label
            Circle()
                .fill(
                    LinearGradient(
                        colors: [customBadge.start, customBadge.end],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.82), lineWidth: max(1, size * 0.06))
                )
                .overlay(
                    Text(badgeText)
                        .font(.system(size: max(6, size * 0.30), weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                )
        } else {
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "shield.fill")
                        .font(.system(size: max(10, size * 0.4), weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                )
        }
    }
}

struct ContentView: View {
    @State private var step: GameStep = .welcome
    @State private var selectedLeague: League?
    @State private var selectedTeam: String?
    @State private var currentTab: DashboardTab = .simulator

    @State private var showCompetitions = false
    @State private var showMatchCenter = false
    @State private var showTeamRecord = false
    @State private var showPlayerSearch = false

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
    private let liveAutoRefreshTimer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
    private let gameSaveKey = "coach.saved.game.v1"

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.10, blue: 0.22), Color(red: 0.02, green: 0.25, blue: 0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            content
                .padding(.horizontal, 18)
                .padding(.top, 24)
                .padding(.bottom, 8)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .sheet(isPresented: $showCompetitions) {
            CompetitionsView()
        }
        .sheet(isPresented: $showTeamRecord) {
            TeamRecordView(
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
                    teamName: team,
                    opponentName: fixture.opponent,
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
        .onAppear {
            restoreSavedGameIfNeeded()
        }
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
                Button {
                    withAnimation(.spring) {
                        step = .leagueSelection
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.08, green: 0.61, blue: 0.80), Color(red: 0.02, green: 0.80, blue: 0.66)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.white.opacity(0.35), lineWidth: 2)
                            )
                            .shadow(color: Color.cyan.opacity(0.45), radius: 15, x: 0, y: 10)

                        VStack(spacing: 8) {
                            Text("مهنة مدرب")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("اضغط للدخول")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.92))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("ترتيب الفرق (مباشر)")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(.white)

                        Spacer()

                        Button {
                            Task { await loadLiveStandings(force: true) }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                Text("تحديث")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.16))
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
                                    Text(league.title)
                                        .font(.system(size: 14, weight: .heavy))
                                        .foregroundStyle(selectedLiveLeague == league ? .black : .white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(selectedLiveLeague == league ? Color.green : Color.white.opacity(0.13))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if liveLoading && liveStandings.isEmpty {
                        HStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text("جاري تحميل الجدول الحقيقي...")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(.vertical, 16)
                    } else if !liveErrorMessage.isEmpty && liveStandings.isEmpty {
                        Text(liveErrorMessage)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.red.opacity(0.95))
                    } else {
                        ScrollView(.horizontal, showsIndicators: true) {
                            VStack(spacing: 8) {
                                HStack(spacing: 6) {
                                    liveHeaderCell("م", width: 32)
                                    liveHeaderCell("الفريق", width: 170)
                                    liveHeaderCell("ل", width: 34)
                                    liveHeaderCell("ف", width: 34)
                                    liveHeaderCell("ت", width: 34)
                                    liveHeaderCell("خ", width: 34)
                                    liveHeaderCell("له", width: 40)
                                    liveHeaderCell("عليه", width: 44)
                                    liveHeaderCell("±", width: 36)
                                    liveHeaderCell("ن", width: 36)
                                    liveHeaderCell("آخر 5", width: 130)
                                }

                                ForEach(liveStandings) { row in
                                    HStack(spacing: 6) {
                                        liveValueCell("\(row.rank)", width: 32, bold: true, color: .yellow)

                                        HStack(spacing: 6) {
                                            if let localAsset = laligaLogoAssetName(for: row.teamName) {
                                                Image(localAsset)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 21, height: 21)
                                            } else {
                                                AsyncImage(url: row.badgeURL) { image in
                                                    image.resizable().scaledToFit()
                                                } placeholder: {
                                                    Circle()
                                                        .fill(Color.white.opacity(0.2))
                                                        .overlay(
                                                            Image(systemName: "shield.fill")
                                                                .font(.system(size: 10, weight: .bold))
                                                                .foregroundStyle(.white.opacity(0.75))
                                                        )
                                                }
                                                .frame(width: 21, height: 21)
                                            }

                                            Text(row.teamName)
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
                                            .fill(Color.white.opacity(0.08))
                                    )
                                }
                            }
                        }
                    }

                    if let last = liveLastUpdated {
                        Text("آخر تحديث: \(liveUpdatedText(from: last))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.72))
                    }

                    if !liveErrorMessage.isEmpty && !liveStandings.isEmpty {
                        Text(liveErrorMessage)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.orange.opacity(0.9))
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.08))
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

    private func liveHeaderCell(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .black))
            .foregroundStyle(.white.opacity(0.82))
            .frame(width: width)
    }

    private func liveValueCell(_ text: String, width: CGFloat, bold: Bool = false, color: Color = .white) -> some View {
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
            bgColor = .green
        case "D":
            symbol = "minus"
            bgColor = .gray
        case "L":
            symbol = "xmark"
            bgColor = .red
        default:
            symbol = "minus"
            bgColor = .gray
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
        formatter.locale = Locale(identifier: "ar")
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
        let keys = ["3", "123"]
        let seasons = seasonCandidates()

        for key in keys {
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

        return []
    }

    private func fetchPastEvents(league: LiveTopLeague) async -> [SportsDBEvent] {
        let keys = ["3", "123"]
        let seasons = seasonCandidates()

        for key in keys {
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
                continue
            }
            guard
                let (data, _) = try? await URLSession.shared.data(from: url),
                let decoded = try? JSONDecoder().decode(SportsDBEventsResponse.self, from: data)
            else { continue }
            let rows = decoded.events ?? []
            if !rows.isEmpty { return rows }
        }

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
                liveErrorMessage = "عرض مؤقت - سيتم التحديث تلقائيًا عند توفر البيانات المباشرة"
            }
        }
    }

    private var leagueSelectionView: some View {
        VStack(spacing: 16) {
            headerTitle("اختر أحد الدوريات الخمسة الكبرى")

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
                                Text(league.name)
                                    .font(.system(size: 21, weight: .bold))
                                Spacer()
                            }
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.white.opacity(0.15))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
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
            headerTitle("فرق \(selectedLeague?.name ?? "")")

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(selectedLeague?.teams ?? [], id: \.self) { team in
                        Button {
                            startCareer(with: team)
                        } label: {
                            HStack {
                                TeamLogoView(teamName: team, size: 28)
                                Text(team)
                                    .font(.system(size: 19, weight: .semibold))
                                Spacer()
                            }
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.12))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var dashboardView: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Button {
                    goBackToMainMenu()
                } label: {
                    Label("القائمة الرئيسية", systemImage: "house.fill")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)

                Button {
                    saveGame()
                } label: {
                    Label("حفظ", systemImage: "square.and.arrow.down.fill")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.92))
                        )
                }
                .buttonStyle(.plain)

                Spacer()
            }

            HStack {
                teamBadge
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedTeam ?? "")
                        .font(.system(size: 27, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("الجولة \(min(matchWeek, totalWeeks))/\(totalWeeks)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
            }

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
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomBar
        }
    }

    private var simulatorView: some View {
        let rank = currentTeamRank()
        let myStats = seasonTable[selectedTeam ?? ""] ?? TeamStanding()

        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("المباراة القادمة: \(nextMatchDescription())")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)

                Text("المباراة السابقة: \(previousResult)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))

                Text("ترتيب فريقي: #\(rank) | \(myStats.points) نقطة")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.yellow)

                tacticsCard

                TeamCalendarView(
                    todayDate: currentDate,
                    displayedMonth: $calendarDisplayDate,
                    matchDays: matchDays(in: calendarDisplayDate),
                    matchBadgesByDay: matchBadgesByDay(in: calendarDisplayDate),
                    fixtures: fixturesInMonth(calendarDisplayDate)
                )

                Button {
                    simulateOneDay()
                } label: {
                    Text("محاكي الأيام")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.cyan.opacity(0.95), Color.blue.opacity(0.95)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                }
                .buttonStyle(.plain)

                ZStack(alignment: .leading) {
                    Button {
                        if matchWeek <= totalWeeks {
                            showMatchCenter = true
                        }
                    } label: {
                        Text(matchWeek > totalWeeks ? "انتهى الموسم" : "لعب المباراة")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(matchWeek > totalWeeks ? Color.gray : Color.green)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(matchWeek > totalWeeks)

                    Button {
                        showCompetitions = true
                    } label: {
                        Text("بطولات")
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(colors: [.pink, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                            )
                            .shadow(color: .red.opacity(0.6), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 10)
                }

                Text(managerNote)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.88))
            }
        }
    }

    private var teamView: some View {
        let myStats = seasonTable[selectedTeam ?? ""] ?? TeamStanding()
        let squad = lineup + bench

        return VStack(spacing: 12) {
            HStack {
                Button {
                    showTeamRecord = true
                } label: {
                    Text("سجل الفريق")
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.95))
                        )
                }
                .buttonStyle(.plain)

                Spacer()
            }

            headerTitle("لاعبين الفريق")

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(squad) { player in
                        playerSquare(player)
                    }
                }
            }

            infoRow("سجل الموسم", "ف\(myStats.wins) - ت\(myStats.draws) - خ\(myStats.losses)")
            infoRow("الأهداف", "له \(myStats.goalsFor) / عليه \(myStats.goalsAgainst)")
            awardsSummaryCard
        }
    }

    private var managementView: some View {
        VStack(spacing: 14) {
            headerTitle("الإدارة")

            contractBudgetCard

            infoRow("الميزانية", "$\(budgetM)M")
            infoRow("رضا الجماهير", "\(fanSatisfaction)%")
            infoRow("هدف الموسم", seasonTarget)
            infoRow("حالة الهدف", seasonTargetStatus())

            Button {
                showPlayerSearch = true
            } label: {
                Text("بحث وتفاوض على عقد لاعب")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.green.opacity(0.92))
                    )
            }
            .buttonStyle(.plain)

            HStack {
                Text("الانتقالات")
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
                Text("الخطة الحالية: \(tacticalPlan.rawValue)")
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
                                Text(plan.styleName)
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundStyle(tacticalPlan == plan ? .black : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(tacticalPlan == plan ? Color.green.opacity(0.95) : Color.white.opacity(0.14))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text("تأثير الخطة: هجوم +\(tacticalPlan.attackBoost) | دفاع +\(tacticalPlan.defenseBoost)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.86))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.10))
        )
    }

    private var awardsSummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("الإنجازات والجوائز")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)

            Text("بطولات الدوري: \(leagueTitlesWon)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.yellow)
            Text("مدرب الشهر: \(coachOfMonthAwards)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
            Text("الحذاء الذهبي: \(goldenBootAwards)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
            Text("هداف الفريق: \(topScorerName) (\(topScorerGoals))")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.12))
        )
    }

    private var contractBudgetCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("عقد المدرب")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(.white)
                Text("متبقي \(contractDaysRemaining()) يوم وينتهي العقد")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))

                Divider().overlay(Color.white.opacity(0.3))

                Text("ميزانية الفريق: $\(budgetM)M")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
            }
            Spacer()
            MoneyStickerView(amount: budgetM)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.12))
        )
    }

    private var teamBadge: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
            if let team = selectedTeam, laligaLogoAssetName(for: team) != nil {
                TeamLogoView(teamName: team, size: 42)
            } else {
                Text(teamShortCode())
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.white)
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 10) {
            ForEach(DashboardTab.allCases, id: \.self) { tab in
                Button {
                    currentTab = tab
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .bold))
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(currentTab == tab ? Color.black : Color.white)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(currentTab == tab ? Color.white : Color.white.opacity(0.16))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.20))
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
                .fill(Color.white.opacity(0.12))
        )
    }

    private func transferCard(for idx: Int) -> some View {
        let item = transferTargets[idx]

        return VStack(alignment: .leading, spacing: 9) {
            Text(item.name)
                .font(.system(size: 19, weight: .black))
                .foregroundStyle(.white)

            HStack {
                Text("قوة +\(item.boost)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.88))
                Spacer()

                Button {
                    signTransfer(at: idx)
                } label: {
                    Text(item.purchased ? "تم التوقيع" : "توقيع $\(item.costM)M")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(item.purchased ? .black : .white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(item.purchased ? Color.green.opacity(0.9) : Color.white.opacity(0.18))
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
                .fill(Color.white.opacity(0.12))
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
                        .foregroundStyle(.green)
                )

            Text(player.name)
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
                .fill(Color.white.opacity(0.12))
        )
    }

    private func goBackToMainMenu() {
        showCompetitions = false
        showMatchCenter = false
        showTeamRecord = false
        showPlayerSearch = false
        showNegotiationSheet = false
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
            recentFormPoints: recentFormPoints
        )

        do {
            let encoded = try JSONEncoder().encode(payload)
            UserDefaults.standard.set(encoded, forKey: gameSaveKey)
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
            applySavedGame(saved)
        } catch {
            // Ignore corrupted save silently and keep current defaults.
        }
    }

    private func applySavedGame(_ saved: GameSaveData) {
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
    }

    private func nextMatchDescription() -> String {
        guard matchWeek <= totalWeeks else { return "لا توجد مباريات متبقية" }
        guard let fixture = nextFixture() else { return "غير متاح" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.dateFormat = "d MMM"
        return "\(fixture.home) ضد \(fixture.away) - \(formatter.string(from: fixture.date))"
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
        Calendar.current.date(byAdding: .day, value: week - 1, to: seasonStartDate) ?? seasonStartDate
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

        updateStanding(team: team, goalsFor: myGoals, goalsAgainst: oppGoals)
        updateStanding(team: opponent, goalsFor: oppGoals, goalsAgainst: myGoals)

        var others = league.teams.filter { $0 != team && $0 != opponent }.shuffled()
        while others.count >= 2 {
            let home = others.removeFirst()
            let away = others.removeFirst()
            let g1 = Int.random(in: 0...4)
            let g2 = Int.random(in: 0...4)
            updateStanding(team: home, goalsFor: g1, goalsAgainst: g2)
            updateStanding(team: away, goalsFor: g2, goalsAgainst: g1)
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
        managerNote = summary
        simulateOneDay()
        matchWeek += 1

        if matchWeek > totalWeeks {
            finalizeSeasonAwards()
            managerNote = "انتهى الموسم - المركز النهائي #\(currentTeamRank()) | الإنجازات: \(achievementLog.count)"
        }
    }

    private func updateStanding(team: String, goalsFor: Int, goalsAgainst: Int) {
        guard var stats = seasonTable[team] else { return }
        stats.apply(goalsFor: goalsFor, goalsAgainst: goalsAgainst)
        seasonTable[team] = stats
    }

    private func currentTeamRank() -> Int {
        guard let team = selectedTeam else { return 1 }
        let sorted = sortedStandings()
        guard let idx = sorted.firstIndex(where: { $0.name == team }) else { return 1 }
        return idx + 1
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
            return rank <= 4 ? "تم تحقيق الهدف" : "لم يتحقق الهدف"
        }
        return rank <= 4 ? "حاليًا ضمن الهدف" : "خارج الهدف حاليًا"
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
        } else {
            managerNote = "فشلت المفاوضات مع \(player.name)، اللاعب رفض العرض"
            fanSatisfaction = max(45, fanSatisfaction - 1)
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
        formatter.locale = Locale(identifier: "ar")
        formatter.dateFormat = "d MMM"

        var rows: [String] = []

        for week in 1...totalWeeks {
            guard let fixture = fixtureFor(week: week, team: team) else { continue }
            let date = fixture.date
            if cal.component(.month, from: date) == cal.component(.month, from: monthDate) &&
                cal.component(.year, from: date) == cal.component(.year, from: monthDate) {
                rows.append("\(formatter.string(from: date)): \(fixture.home) × \(fixture.away)")
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
    let todayDate: Date
    @Binding var displayedMonth: Date
    let matchDays: Set<Int>
    let matchBadgesByDay: [Int: [String]]
    let fixtures: [String]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let weekDayNames = ["أحد", "إثن", "ثلا", "أرب", "خم", "جمع", "سبت"]

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
                        .background(Circle().fill(Color.white.opacity(0.15)))
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
                        .background(Circle().fill(Color.white.opacity(0.15)))
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
                            .fill(matchDays.contains(day) ? Color.green.opacity(0.95) : Color.white.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isToday ? Color.yellow : Color.clear, lineWidth: 1.5)
                            )
                    )
                }
            }

            if fixtures.isEmpty {
                Text("لا توجد مباريات متبقية هذا الشهر")
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
        formatter.locale = Locale(identifier: "ar")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func isSameDay(day: Int, calendar: Calendar) -> Bool {
        calendar.component(.day, from: todayDate) == day &&
            calendar.component(.month, from: todayDate) == calendar.component(.month, from: displayedMonth) &&
            calendar.component(.year, from: todayDate) == calendar.component(.year, from: displayedMonth)
    }

    private func compactLabel(_ name: String) -> String {
        let firstToken = name.split(separator: " ").first.map(String.init) ?? name
        return String(firstToken.prefix(10))
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
                        colors: [Color.green, Color(red: 0.08, green: 0.74, blue: 0.42)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .shadow(color: .green.opacity(0.6), radius: 10, x: 0, y: 5)
        .offset(x: glide ? 4 : -4)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                glide = true
            }
        }
    }
}

private struct PlayerSearchView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var players: [MarketPlayer]
    let budgetM: Int
    let onNegotiatePlayer: (Int) -> Void

    @State private var query = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextField("اكتب اسم اللاعب", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 4)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(filteredIndices(), id: \.self) { idx in
                            let player = players[idx]
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(player.name)
                                        .font(.system(size: 18, weight: .black))
                                    Text("القيمة: $\(player.costM)M | قوة +\(player.boost)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button(player.signed ? "تم" : "تفاوض") {
                                    onNegotiatePlayer(idx)
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(player.signed ? Color.gray : (budgetM >= player.costM ? Color.green : Color.red))
                                .clipShape(Capsule())
                                .disabled(player.signed || budgetM < player.costM)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("بحث لاعب")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("إغلاق") { dismiss() }
                }
            }
        }
    }

    private func filteredIndices() -> [Int] {
        let cleaned = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return players.indices.filter { idx in
            let name = players[idx].name
            return cleaned.isEmpty || name.localizedCaseInsensitiveContains(cleaned)
        }
    }
}

private struct ContractNegotiationView: View {
    let player: MarketPlayer
    let budgetM: Int
    let onSubmit: (Int, Int, Int) -> Void
    let onCancel: () -> Void

    @State private var salaryM: Int
    @State private var years: Int
    @State private var bonusM: Int

    init(
        player: MarketPlayer,
        budgetM: Int,
        onSubmit: @escaping (Int, Int, Int) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.player = player
        self.budgetM = budgetM
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        _salaryM = State(initialValue: max(3, player.costM / 16))
        _years = State(initialValue: 3)
        _bonusM = State(initialValue: max(1, player.costM / 22))
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
                Text("مفاوضات عقد: \(player.name)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 10) {
                    negotiationRow("رسوم الصفقة", "$\(player.costM)M")
                    negotiationRow("راتب سنوي", "$\(salaryM)M")
                    negotiationRow("مدة العقد", "\(years) سنوات")
                    negotiationRow("مكافأة توقيع", "$\(bonusM)M")
                    negotiationRow("قيمة العقد الكلية", "$\(totalPackage)M")
                    negotiationRow("نسبة القبول", "\(acceptancePercent)%")
                }

                VStack(spacing: 10) {
                    HStack {
                        Text("الراتب السنوي")
                        Spacer()
                        Stepper("", value: $salaryM, in: 1...25)
                    }

                    HStack {
                        Text("سنوات العقد")
                        Spacer()
                        Stepper("", value: $years, in: 1...5)
                    }

                    HStack {
                        Text("مكافأة التوقيع")
                        Spacer()
                        Stepper("", value: $bonusM, in: 0...20)
                    }
                }
                .font(.system(size: 16, weight: .bold))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.blue.opacity(0.08))
                )

                Button {
                    onSubmit(salaryM, years, bonusM)
                } label: {
                    Text(totalPackage <= budgetM ? "إرسال العرض" : "الميزانية لا تكفي")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(totalPackage <= budgetM ? Color.green : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(totalPackage > budgetM)

                Button("إلغاء") {
                    onCancel()
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.red)

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
                    Button("إغلاق") { dismiss() }
                        .font(.system(size: 15, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())

                    Spacer()

                    Text("سجل \(teamName)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    recordCard("عدد الفوز", "\(wins)", color: .green)
                    recordCard("عدد الخسارة", "\(losses)", color: .red)
                    recordCard("عدد التعادل", "\(draws)", color: .orange)
                    recordCard("عدد البطولات", "\(titles)", color: .yellow)
                    recordCard("عدد الأهداف", "\(goalsFor)", color: .blue)
                    recordCard("استقبال الأهداف", "\(goalsAgainst)", color: .pink)
                    recordCard("مدرب الشهر", "\(coachAwards)", color: .mint)
                    recordCard("الحذاء الذهبي", "\(goldenBoots)", color: .purple)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("هداف الفريق: \(topScorerName) (\(topScorerGoals) هدف)")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white)

                    if achievements.isEmpty {
                        Text("لا توجد إنجازات بعد")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                    } else {
                        ForEach(achievements.suffix(5), id: \.self) { item in
                            Text("• \(item)")
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
    let teamName: String
    let opponentName: String

    @Binding var lineup: [TeamPlayer]
    @Binding var bench: [TeamPlayer]
    let tacticalPlan: TacticalPlan
    let squadStrength: Int
    let fanSatisfaction: Int

    let onClose: () -> Void
    let onFinish: (Int, Int, String) -> Void

    @State private var minute = 0
    @State private var isRunning = true
    @State private var myGoals = 0
    @State private var oppGoals = 0
    @State private var events: [MatchEvent] = []

    @State private var selectedStarter: UUID?
    @State private var selectedBench: UUID?
    @State private var showLineupSheet = false

    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.01, green: 0.25, blue: 0.14), Color(red: 0.00, green: 0.16, blue: 0.09)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 10) {
                HStack {
                    Button("إغلاق") {
                        onClose()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())

                    Spacer()

                    Button("تشكيلة الفريق") {
                        showLineupSheet.toggle()
                    }
                    .font(.system(size: 15, weight: .black))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
                }

                HStack {
                    HStack(spacing: 6) {
                        TeamLogoView(teamName: teamName, size: 24)
                        Text(teamName)
                    }
                    Spacer()
                    Text("\(myGoals) - \(oppGoals)")
                        .font(.system(size: 25, weight: .black))
                    Spacer()
                    HStack(spacing: 6) {
                        Text(opponentName)
                        TeamLogoView(teamName: opponentName, size: 24)
                    }
                }
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

                Text("الدقيقة: \(minute) / 90")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.yellow)

                Text("الخطة: \(tacticalPlan.rawValue) - \(tacticalPlan.styleName)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.88))

                pitchView
                    .frame(height: 420)

                if minute >= 90 {
                    Button("إنهاء المباراة") {
                        let summary = "انتهت \(myGoals)-\(oppGoals) | \(events.prefix(2).map { $0.text }.joined(separator: " | "))"
                        onFinish(myGoals, oppGoals, summary)
                    }
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("أحداث المباراة")
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(.white)

                        ForEach(events.suffix(8)) { item in
                            Text("\(item.minute)' - \(item.text)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.92))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 120)
            }
            .padding(14)
        }
        .onReceive(timer) { _ in
            guard isRunning else { return }
            tickMatch()
        }
        .sheet(isPresented: $showLineupSheet) {
            lineupSheet
                .presentationDetents([.medium, .large])
        }
    }

    private var pitchView: some View {
        GeometryReader { geo in
            let positions = positionsForPlan()

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.10, green: 0.55, blue: 0.24))
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
                    playerChip(player: player, selected: selectedStarter == player.id)
                        .position(x: geo.size.width * point.x, y: geo.size.height * point.y)
                        .onTapGesture {
                            selectedStarter = player.id
                        }
                }
            }
        }
    }

    private func playerChip(player: TeamPlayer, selected: Bool) -> some View {
        VStack(spacing: 2) {
            Circle()
                .fill(selected ? Color.yellow : Color.white)
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundStyle(selected ? .black : .green)
                )
            Text("\(player.number)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private var lineupSheet: some View {
        VStack(spacing: 10) {
            Text("الاحتياط والتبديلات")
                .font(.system(size: 24, weight: .black))

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("الأساسي")
                        .font(.system(size: 18, weight: .bold))
                    ForEach(lineup) { p in
                        swapRow(player: p, isStarter: true)
                    }

                    Text("الاحتياط")
                        .font(.system(size: 18, weight: .bold))
                        .padding(.top, 8)
                    ForEach(bench) { p in
                        swapRow(player: p, isStarter: false)
                    }
                }
            }

            Button("تنفيذ التبديل") {
                performSwap()
            }
            .font(.system(size: 18, weight: .black))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }

    private func swapRow(player: TeamPlayer, isStarter: Bool) -> some View {
        let selected = isStarter ? selectedStarter == player.id : selectedBench == player.id

        return HStack {
            Text("#\(player.number) \(player.name) (\(player.role))")
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture {
            if isStarter {
                selectedStarter = player.id
            } else {
                selectedBench = player.id
            }
        }
    }

    private func performSwap() {
        guard let starterID = selectedStarter, let benchID = selectedBench else { return }
        guard let sIdx = lineup.firstIndex(where: { $0.id == starterID }) else { return }
        guard let bIdx = bench.firstIndex(where: { $0.id == benchID }) else { return }

        let temp = lineup[sIdx]
        lineup[sIdx] = bench[bIdx]
        bench[bIdx] = temp

        selectedStarter = nil
        selectedBench = nil
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
        minute = min(90, minute + Int.random(in: 1...3))

        let eventChance = max(12, min(46, 24 + ((squadStrength - 70) / 2) + tacticalPlan.attackBoost - 2))
        let baseChance = 52
            + ((squadStrength - 72) / 2)
            + ((fanSatisfaction - 70) / 5)
            + tacticalPlan.attackBoost
            - (tacticalPlan.defenseBoost / 2)
        let myChancePercent = max(28, min(82, baseChance))

        if Bool.random() && Int.random(in: 0...100) < eventChance {
            let myChance = Int.random(in: 0...100) < myChancePercent
            let scorer = lineup.randomElement()?.name ?? "لاعب"
            let assist = lineup.filter { $0.name != scorer }.randomElement()?.name ?? scorer
            let opponentScorer = ["المهاجم", "الجناح", "صانع اللعب", "البديل"].randomElement() ?? "المهاجم"
            let opponentAssist = ["الظهير", "الوسط", "المهاجم", "الجناح"].randomElement() ?? "الوسط"

            if myChance {
                myGoals += 1
                events.append(MatchEvent(minute: minute, text: "هدف لـ \(teamName) - سجّل: \(scorer) | صنع: \(assist)"))
            } else {
                oppGoals += 1
                events.append(MatchEvent(minute: minute, text: "هدف لـ \(opponentName) - سجّل: \(opponentScorer) | صنع: \(opponentAssist)"))
            }
        }

        if minute >= 90 {
            isRunning = false
            if events.isEmpty {
                events.append(MatchEvent(minute: 90, text: "مباراة تكتيكية بدون أهداف خطيرة"))
            }
        }
    }
}

private struct CompetitionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var championsTable: [LiveStandingRow] = []
    @State private var nextFixtures: [UCLFixtureRow] = []
    @State private var recentFixtures: [UCLFixtureRow] = []
    @State private var loading = false
    @State private var errorMessage = ""
    @State private var lastUpdated: Date?

    private let refreshTimer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
    private let championsLeagueID = "4480"

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
                        Button("إغلاق") {
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
                                Text("تحديث")
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

                        Text("البطولات")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    competitionBar(
                        title: "دوري الأبطال (مباشر)",
                        subtitle: "مرتبط بنتائج الواقع",
                        gradient: [Color(red: 0.02, green: 0.28, blue: 0.95), Color(red: 0.17, green: 0.52, blue: 1.0)],
                        glow: .blue
                    )

                    if loading && championsTable.isEmpty {
                        loadingCard("جاري تحميل بيانات دوري الأبطال الحقيقية...")
                    } else if !errorMessage.isEmpty && championsTable.isEmpty {
                        infoCard(errorMessage, color: .red.opacity(0.92))
                    } else {
                        championsStandingsCard
                        fixturesCard(title: "المباريات القادمة", rows: nextFixtures)
                        fixturesCard(title: "آخر النتائج", rows: recentFixtures)
                    }

                    if let lastUpdated {
                        infoCard("آخر تحديث: \(formatUpdateDate(lastUpdated))", color: .white.opacity(0.82))
                    }

                    if !errorMessage.isEmpty && !championsTable.isEmpty {
                        infoCard(errorMessage, color: .orange.opacity(0.9))
                    }

                    competitionBar(
                        title: "الدوري الأوروبي",
                        subtitle: "فرصة مجد قاري جديدة",
                        gradient: [Color(red: 0.98, green: 0.42, blue: 0.04), Color(red: 1.0, green: 0.63, blue: 0.16)],
                        glow: .orange
                    )

                    competitionBar(
                        title: "كأس العالم (منتخبات)",
                        subtitle: "البطولة الذهبية الأكبر",
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
            Text("جدول دوري الأبطال")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        headerCell("م", width: 28)
                        headerCell("الفريق", width: 165)
                        headerCell("ل", width: 32)
                        headerCell("ف", width: 32)
                        headerCell("ت", width: 32)
                        headerCell("خ", width: 32)
                        headerCell("له", width: 38)
                        headerCell("عليه", width: 44)
                        headerCell("±", width: 34)
                        headerCell("ن", width: 34)
                        headerCell("آخر 5", width: 120)
                    }

                    ForEach(Array(championsTable.prefix(16))) { row in
                        HStack(spacing: 6) {
                            valueCell("\(row.rank)", width: 28, bold: true, color: .yellow)
                            HStack(spacing: 6) {
                                if let localAsset = laligaLogoAssetName(for: row.teamName) {
                                    Image(localAsset)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                } else {
                                    AsyncImage(url: row.badgeURL) { image in
                                        image.resizable().scaledToFit()
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .overlay(
                                                Image(systemName: "shield.fill")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundStyle(.white.opacity(0.8))
                                            )
                                    }
                                    .frame(width: 20, height: 20)
                                }

                                Text(row.teamName)
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
                Text("لا توجد بيانات حالياً")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.82))
            } else {
                ForEach(rows.prefix(6)) { row in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(row.home) × \(row.away)")
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
                                .foregroundStyle(.yellow)
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
        formatter.locale = Locale(identifier: "ar")
        formatter.dateFormat = "d MMM - HH:mm"
        return formatter.string(from: date)
    }

    private func formatEventDate(_ item: SportsDBEvent) -> (date: String, time: String) {
        if let stamp = item.strTimestamp, let date = ISO8601DateFormatter().date(from: stamp) {
            let dayFormatter = DateFormatter()
            dayFormatter.locale = Locale(identifier: "ar")
            dayFormatter.dateFormat = "d MMM"

            let timeFormatter = DateFormatter()
            timeFormatter.locale = Locale(identifier: "ar")
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
        let keys = ["3", "123"]

        for key in keys {
            var components = URLComponents(string: "https://www.thesportsdb.com/api/v1/json/\(key)/lookuptable.php")
            components?.queryItems = [URLQueryItem(name: "l", value: championsLeagueID)]
            guard let url = components?.url else { continue }

            guard
                let (data, _) = try? await URLSession.shared.data(from: url),
                let decoded = try? JSONDecoder().decode(SportsDBStandingsResponse.self, from: data)
            else { continue }
            let rows = decoded.table ?? []
            if !rows.isEmpty { return rows }
        }

        return []
    }

    private func fetchEventsRows(endpoint: String) async -> [SportsDBEvent] {
        let keys = ["3", "123"]

        for key in keys {
            guard let url = URL(string: "https://www.thesportsdb.com/api/v1/json/\(key)/\(endpoint)?id=\(championsLeagueID)") else {
                continue
            }

            guard
                let (data, _) = try? await URLSession.shared.data(from: url),
                let decoded = try? JSONDecoder().decode(SportsDBEventsResponse.self, from: data)
            else { continue }
            let rows = decoded.events ?? []
            if !rows.isEmpty { return rows }
        }

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
                errorMessage = "تعذر جلب بيانات دوري الأبطال حالياً"
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
