import Foundation

@MainActor
final class BookmarkStore: ObservableObject {
    enum ToggleResult {
        case added
        case removed
    }

    @Published private(set) var bookmarkedCafeIDs: Set<UUID> = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let bookmarkService = BookmarkService()
    private var bookmarkTimestamps: [UUID: Date] = [:]

    func isBookmarked(_ cafe: Cafe) -> Bool {
        bookmarkedCafeIDs.contains(cafe.id)
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let bookmarks = try await bookmarkService.fetchBookmarks()
            bookmarkedCafeIDs = Set(bookmarks.map(\.cafeID))
            bookmarkTimestamps = Dictionary(uniqueKeysWithValues: bookmarks.map { ($0.cafeID, $0.createdAt) })
        } catch {
            bookmarkedCafeIDs = []
            bookmarkTimestamps = [:]
            errorMessage = "저장한 카페를 불러오지 못했어요."
        }
    }

    func toggle(_ cafe: Cafe) async -> ToggleResult? {
        errorMessage = nil

        do {
            if isBookmarked(cafe) {
                try await bookmarkService.removeBookmark(cafeID: cafe.id)
                bookmarkedCafeIDs.remove(cafe.id)
                bookmarkTimestamps.removeValue(forKey: cafe.id)
                return .removed
            } else {
                let bookmark = try await bookmarkService.addBookmark(cafeID: cafe.id)
                bookmarkedCafeIDs.insert(cafe.id)
                bookmarkTimestamps[cafe.id] = bookmark.createdAt
                return .added
            }
        } catch {
            errorMessage = "카페 저장 상태를 업데이트하지 못했어요."
            return nil
        }
    }

    func bookmarkedAt(_ cafe: Cafe) -> Date? {
        bookmarkTimestamps[cafe.id]
    }
}
