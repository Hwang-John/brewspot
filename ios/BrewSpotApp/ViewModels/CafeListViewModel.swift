import Foundation

@MainActor
final class CafeListViewModel: ObservableObject {
    @Published private(set) var cafes: [Cafe] = []
    @Published private(set) var isLoading = false
    @Published private(set) var sourceDescription = "Supabase 연결 대기"
    @Published private(set) var errorMessage: String?

    private let cafeService = CafeService()
    private var hasLoaded = false

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await refresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetchedCafes = try await cafeService.fetchCafes()
            if fetchedCafes.isEmpty {
                cafes = []
                sourceDescription = "Supabase 데이터 없음"
            } else {
                cafes = fetchedCafes
                sourceDescription = "Supabase 데이터"
            }
        } catch {
            cafes = Cafe.sampleCafes
            sourceDescription = "Supabase 연결 실패, 샘플 데이터"
            errorMessage = "Supabase에서 카페 데이터를 불러오지 못해 샘플 데이터를 표시하고 있어요."
        }
    }
}
