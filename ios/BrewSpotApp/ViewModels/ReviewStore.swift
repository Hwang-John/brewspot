import Foundation

@MainActor
final class ReviewStore: ObservableObject {
    struct SavedReviewItem: Identifiable {
        let cafeID: UUID
        let cafeName: String
        let review: CafeReview

        var id: UUID { review.id }
    }

    @Published private var reviewsByCafeID: [UUID: [CafeReview]] = [:]
    @Published private(set) var myReviews: [SavedReviewItem] = []
    @Published private(set) var loadingCafeIDs: Set<UUID> = []
    @Published private(set) var isRefreshingMyReviews = false
    @Published var errorMessage: String?

    private let reviewService = ReviewService()

    func reviews(for cafe: Cafe) -> [CafeReview] {
        reviewsByCafeID[cafe.id] ?? []
    }

    func isLoadingReviews(for cafe: Cafe) -> Bool {
        loadingCafeIDs.contains(cafe.id)
    }

    func loadReviews(for cafe: Cafe) async {
        guard !loadingCafeIDs.contains(cafe.id) else { return }

        errorMessage = nil
        loadingCafeIDs.insert(cafe.id)
        defer { loadingCafeIDs.remove(cafe.id) }

        do {
            reviewsByCafeID[cafe.id] = try await reviewService.fetchReviews(for: cafe.id)
        } catch {
            reviewsByCafeID[cafe.id] = []
            errorMessage = "리뷰를 불러오지 못했어요."
        }
    }

    func refreshMyReviews(using cafes: [Cafe]) async {
        isRefreshingMyReviews = true
        errorMessage = nil
        defer { isRefreshingMyReviews = false }

        let cafeNameByID = Dictionary(uniqueKeysWithValues: cafes.map { ($0.id, $0.name) })

        do {
            let records = try await reviewService.fetchMyReviewRecords()
            myReviews = records.map { record in
                SavedReviewItem(
                    cafeID: record.cafeID,
                    cafeName: cafeNameByID[record.cafeID] ?? "알 수 없는 카페",
                    review: record.asCafeReview
                )
            }
            .sorted { $0.review.createdAt > $1.review.createdAt }
        } catch {
            myReviews = []
            errorMessage = "내 리뷰를 불러오지 못했어요."
        }
    }

    func addReview(
        cafe: Cafe,
        authorNickname: String,
        rating: Int,
        visitNote: String,
        recommendedMenu: String
    ) async throws {
        let review = try await reviewService.addReview(
            cafeID: cafe.id,
            authorNickname: authorNickname,
            rating: rating,
            visitNote: visitNote,
            recommendedMenu: recommendedMenu
        )

        var currentReviews = reviewsByCafeID[cafe.id] ?? []
        currentReviews.insert(review, at: 0)
        reviewsByCafeID[cafe.id] = currentReviews

        myReviews.insert(
            SavedReviewItem(cafeID: cafe.id, cafeName: cafe.name, review: review),
            at: 0
        )
    }
}
