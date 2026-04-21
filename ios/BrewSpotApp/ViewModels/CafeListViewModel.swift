import Foundation

@MainActor
final class CafeListViewModel: ObservableObject {
    @Published private(set) var cafes: [Cafe] = Cafe.sampleCafes
    @Published private(set) var isLoading = false
    @Published private(set) var sourceDescription = "샘플 데이터"

    private let cafeService = CafeService()
    private var hasLoaded = false

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await refresh()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedCafes = try await cafeService.fetchCafes()
            if fetchedCafes.isEmpty {
                cafes = Cafe.sampleCafes
                sourceDescription = "샘플 데이터"
            } else {
                cafes = fetchedCafes
                sourceDescription = "Supabase 데이터"
            }
        } catch {
            cafes = Cafe.sampleCafes
            sourceDescription = "샘플 데이터"
        }
    }
}
