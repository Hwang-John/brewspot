import Foundation

@MainActor
final class ReviewStore: ObservableObject {
    struct SavedReviewItem: Identifiable {
        let cafeName: String
        let review: CafeReview

        var id: UUID { review.id }
    }

    private let storageKey = "review_store.saved_reviews"
    @Published private var storedReviews: [String: [CafeReview]] = [:]

    init() {
        loadReviews()
    }

    func reviews(for cafe: Cafe) -> [CafeReview] {
        let savedReviews = storedReviews[cafe.name] ?? []
        return savedReviews + CafeReview.samples(for: cafe)
    }

    func addReview(_ review: CafeReview, for cafe: Cafe) {
        var currentReviews = storedReviews[cafe.name] ?? []
        currentReviews.insert(review, at: 0)
        storedReviews[cafe.name] = currentReviews
        persistReviews()
    }

    func savedReviews(for cafe: Cafe) -> [CafeReview] {
        storedReviews[cafe.name] ?? []
    }

    func allSavedReviews() -> [SavedReviewItem] {
        storedReviews
            .flatMap { cafeName, reviews in
                reviews.map { SavedReviewItem(cafeName: cafeName, review: $0) }
            }
            .sorted { $0.review.createdAt > $1.review.createdAt }
    }

    private func loadReviews() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([String: [CafeReview]].self, from: data)
        else {
            return
        }

        storedReviews = decoded
    }

    private func persistReviews() {
        guard let encoded = try? JSONEncoder().encode(storedReviews) else {
            return
        }

        UserDefaults.standard.set(encoded, forKey: storageKey)
    }
}
