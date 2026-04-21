import Foundation

@MainActor
final class BookmarkStore: ObservableObject {
    private let storageKey = "bookmark_store.cafe_names"
    private let timestampStorageKey = "bookmark_store.timestamps"
    @Published private(set) var bookmarkedCafeNames: Set<String> = []
    private var bookmarkTimestamps: [String: TimeInterval] = [:]

    init() {
        loadBookmarks()
    }

    func isBookmarked(_ cafe: Cafe) -> Bool {
        bookmarkedCafeNames.contains(cafe.name)
    }

    func toggle(_ cafe: Cafe) {
        if isBookmarked(cafe) {
            bookmarkedCafeNames.remove(cafe.name)
            bookmarkTimestamps.removeValue(forKey: cafe.name)
        } else {
            bookmarkedCafeNames.insert(cafe.name)
            bookmarkTimestamps[cafe.name] = Date().timeIntervalSince1970
        }

        persistBookmarks()
    }

    func bookmarkedAt(_ cafe: Cafe) -> Date? {
        guard let timestamp = bookmarkTimestamps[cafe.name] else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    private func loadBookmarks() {
        guard let savedNames = UserDefaults.standard.array(forKey: storageKey) as? [String] else {
            return
        }

        bookmarkedCafeNames = Set(savedNames)
        bookmarkTimestamps = UserDefaults.standard.dictionary(forKey: timestampStorageKey) as? [String: TimeInterval] ?? [:]
    }

    private func persistBookmarks() {
        UserDefaults.standard.set(Array(bookmarkedCafeNames).sorted(), forKey: storageKey)
        UserDefaults.standard.set(bookmarkTimestamps, forKey: timestampStorageKey)
    }
}
