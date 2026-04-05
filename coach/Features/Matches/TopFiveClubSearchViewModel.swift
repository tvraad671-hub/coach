import Foundation
import Combine

@MainActor
final class TopFiveClubSearchViewModel: ObservableObject {
    @Published var query = ""

    @Published private(set) var results: [TopFiveClubItem] = []
    @Published private(set) var isSearching = false
    @Published private(set) var isLoadingClubIndex = false
    @Published private(set) var errorMessage: String?

    var hasActiveQuery: Bool {
        !trimmedQuery.isEmpty
    }

    var hasNoResults: Bool {
        hasActiveQuery
            && !isSearching
            && !isLoadingClubIndex
            && results.isEmpty
            && errorMessage == nil
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private let repository: TopFiveClubRepositoryProtocol
    private let season: Int
    private let debounceMilliseconds: Int
    private let aliasProvider: (String, String?) -> [String]

    private var allClubs: [TopFiveClubItem] = []
    private var normalizedAliasesByClubID: [Int: [String]] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var currentSearchToken = UUID()
    private var searchTask: Task<Void, Never>?
    private var clubIndexLoadTask: Task<[TopFiveClubItem], Error>?
    private var remoteRefreshTask: Task<Void, Never>?
    private var hasAttemptedRemoteRefresh = false

    init(
        repository: TopFiveClubRepositoryProtocol? = nil,
        season: Int = FootballSeasonResolver.currentSeason(),
        debounceMilliseconds: Int = 320,
        aliasProvider: @escaping (String, String?) -> [String]
    ) {
        self.repository = repository ?? TopFiveClubRepository()
        self.season = season
        self.debounceMilliseconds = max(150, debounceMilliseconds)
        self.aliasProvider = aliasProvider

        updateClubIndex(with: TopFiveClubItem.fallbackTopFiveClubs)
        setupSearchPipeline()
        triggerRemoteRefreshIfNeeded()
    }

    func clearQuery() {
        searchTask?.cancel()
        query = ""
        resetSearchState()
    }

    private func setupSearchPipeline() {
        $query
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: .milliseconds(debounceMilliseconds), scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self else { return }
                self.searchTask?.cancel()
                self.searchTask = Task {
                    await self.performSearch(for: value)
                }
            }
            .store(in: &cancellables)
    }

    private func performSearch(for rawQuery: String) async {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = UUID()
        currentSearchToken = token

        guard !query.isEmpty else {
            resetSearchState()
            return
        }

        guard query.count >= 2 else {
            isSearching = false
            errorMessage = nil
            results = []
            return
        }

        isSearching = true
        errorMessage = nil

        do {
            try await ensureClubIndexLoaded()
            guard token == currentSearchToken else { return }

            let ranked = rankClubs(matching: query)
            results = Array(ranked.prefix(16))

            guard token == currentSearchToken else { return }
            isSearching = false
        } catch {
            guard token == currentSearchToken else { return }
            isSearching = false
            if !allClubs.isEmpty {
                results = Array(rankClubs(matching: query).prefix(16))
                errorMessage = nil
            } else {
                errorMessage = error.localizedDescription
                results = []
            }
        }
    }

    private func ensureClubIndexLoaded() async throws {
        if !allClubs.isEmpty {
            triggerRemoteRefreshIfNeeded()
            return
        }

        if let existingTask = clubIndexLoadTask {
            let clubs = try await existingTask.value
            updateClubIndex(with: clubs)
            return
        }

        isLoadingClubIndex = true
        let task = Task { try await repository.fetchTopFiveClubs(season: season) }
        clubIndexLoadTask = task

        defer {
            isLoadingClubIndex = false
            clubIndexLoadTask = nil
        }

        let clubs = try await task.value
        updateClubIndex(with: clubs)
    }

    private func updateClubIndex(with clubs: [TopFiveClubItem]) {
        guard !clubs.isEmpty else { return }
        let merged = mergeClubs(allClubs + clubs)
        allClubs = merged
        normalizedAliasesByClubID = Dictionary(uniqueKeysWithValues: merged.map { club in
            (club.id, normalizedAliases(for: club))
        })
    }

    private func mergeClubs(_ clubs: [TopFiveClubItem]) -> [TopFiveClubItem] {
        var unique: [Int: TopFiveClubItem] = [:]
        for club in clubs {
            if let existing = unique[club.id] {
                if existing.logoURL == nil, club.logoURL != nil {
                    unique[club.id] = club
                }
            } else {
                unique[club.id] = club
            }
        }
        return unique.values.sorted { lhs, rhs in
            if lhs.leagueID != rhs.leagueID {
                return leaguePriority(lhs.leagueID) < leaguePriority(rhs.leagueID)
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private func triggerRemoteRefreshIfNeeded() {
        guard !hasAttemptedRemoteRefresh else { return }
        hasAttemptedRemoteRefresh = true
        remoteRefreshTask?.cancel()

        remoteRefreshTask = Task { [weak self] in
            guard let self else { return }
            do {
                let clubs = try await self.repository.fetchTopFiveClubs(season: self.season)
                guard !Task.isCancelled else { return }
                self.updateClubIndex(with: clubs)
                self.errorMessage = nil
            } catch {
                guard !Task.isCancelled else { return }
                if self.allClubs.isEmpty {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.errorMessage = nil
                }
            }
        }
    }

    private func normalizedAliases(for club: TopFiveClubItem) -> [String] {
        var aliases: [String] = []
        aliases.append(club.name)
        if let shortCode = club.shortCode {
            aliases.append(shortCode)
        }
        aliases.append(club.leagueName)
        aliases.append(contentsOf: aliasProvider(club.name, club.shortCode))

        let compactName = club.name
            .replacingOccurrences(of: " FC", with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: " CF", with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: " AC", with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: " SC", with: "", options: [.caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !compactName.isEmpty {
            aliases.append(compactName)
        }

        var deduplicated: [String] = []
        var seen = Set<String>()

        for alias in aliases {
            let normalized = normalizedSearchKey(alias)
            guard !normalized.isEmpty else { continue }
            if seen.insert(normalized).inserted {
                deduplicated.append(normalized)
            }
        }

        return deduplicated
    }

    private func rankClubs(matching query: String) -> [TopFiveClubItem] {
        let normalizedQuery = normalizedSearchKey(query)
        guard !normalizedQuery.isEmpty else { return [] }

        let scored: [(club: TopFiveClubItem, score: Int)] = allClubs.compactMap { club in
            let aliases = normalizedAliasesByClubID[club.id] ?? []
            let score = score(for: aliases, query: normalizedQuery, club: club)
            guard score > 0 else { return nil }
            return (club, score)
        }

        let sorted = scored.sorted { lhs, rhs in
            if lhs.score != rhs.score {
                return lhs.score > rhs.score
            }

            let leftLeague = leaguePriority(lhs.club.leagueID)
            let rightLeague = leaguePriority(rhs.club.leagueID)
            if leftLeague != rightLeague {
                return leftLeague < rightLeague
            }

            return lhs.club.name.localizedCaseInsensitiveCompare(rhs.club.name) == .orderedAscending
        }

        return sorted.map(\.club)
    }

    private func score(for aliases: [String], query: String, club: TopFiveClubItem) -> Int {
        var best = 0

        for alias in aliases {
            if alias == query {
                best = max(best, 900)
                continue
            }

            if alias.hasPrefix(query) {
                best = max(best, 620)
                continue
            }

            if alias.contains(query) {
                best = max(best, 430)
                continue
            }

            if query.hasPrefix(alias), alias.count >= 2 {
                best = max(best, 280)
            }
        }

        if let shortCode = club.shortCode {
            let code = normalizedSearchKey(shortCode)
            if code == query {
                best = max(best, 880)
            } else if code.hasPrefix(query) || query.hasPrefix(code) {
                best = max(best, 560)
            }
        }

        best += max(0, 20 - leaguePriority(club.leagueID))
        return best
    }

    private func resetSearchState() {
        currentSearchToken = UUID()
        results = []
        isSearching = false
        errorMessage = nil
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
}

private func normalizedSearchKey(_ raw: String) -> String {
    let folded = raw
        .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

    let sanitized = folded.unicodeScalars.map { scalar -> String in
        CharacterSet.alphanumerics.contains(scalar) ? String(scalar) : " "
    }.joined()

    return sanitized
        .split(whereSeparator: \.isWhitespace)
        .joined(separator: " ")
}
