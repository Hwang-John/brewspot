import Foundation

@MainActor
final class BookmarkStore: ObservableObject {
    @Published private(set) var bookmarkedCafeNames: Set<String> = []

    func isBookmarked(_ cafe: Cafe) -> Bool {
        bookmarkedCafeNames.contains(cafe.name)
    }

    func toggle(_ cafe: Cafe) {
        if isBookmarked(cafe) {
            bookmarkedCafeNames.remove(cafe.name)
        } else {
            bookmarkedCafeNames.insert(cafe.name)
        }
    }
}
