import Foundation
import Combine

@MainActor
final class TeamDetailsViewModel: ObservableObject {
    @Published private(set) var overview: TeamDetailsOverview

    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?

    let club: TopFiveClubItem

    private let repository: TeamDetailsRepositoryProtocol

    init(
        club: TopFiveClubItem,
        repository: TeamDetailsRepositoryProtocol? = nil
    ) {
        self.club = club
        self.overview = TeamDetailsOverview.fallback(from: club)
        self.repository = repository ?? TeamDetailsRepository()
    }

    func fetchDetails() async {
        if overview.country == nil
            && overview.city == nil
            && overview.stadiumName == nil
            && overview.coachName == nil
            && overview.founded == nil {
            isLoading = true
        } else {
            isRefreshing = true
        }

        defer {
            isLoading = false
            isRefreshing = false
        }

        let overviewResult = await loadOverviewResult()
        switch overviewResult {
        case .success(let fetchedOverview):
            overview = fetchedOverview
            errorMessage = nil
        case .failure:
            // Keep fallback basic data from selected club if live API details are not available.
            if overview.teamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = "Unable to load team details right now."
            } else {
                errorMessage = "بعض البيانات المباشرة غير متوفرة الآن."
            }
        }
    }

    func retry() {
        Task {
            await fetchDetails()
        }
    }

    private func loadOverviewResult() async -> Result<TeamDetailsOverview, Error> {
        do {
            let payload = try await repository.fetchOverview(for: club)
            return .success(payload)
        } catch {
            return .failure(error)
        }
    }
}
