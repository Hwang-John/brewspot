import Foundation

@MainActor
final class HomeBaristaStore: ObservableObject {
    enum CreateResult {
        case synced(HomeBaristaPost)
        case localFallback(HomeBaristaPost)
    }

    @Published private(set) var posts: [HomeBaristaPost] = []
    @Published private(set) var isLoading = false
    @Published private(set) var sourceDescription = "홈바리스타 준비 중"
    @Published var errorMessage: String?

    private let service = HomeBaristaService()
    private var hasLoaded = false
    private var localFallbackPosts: [HomeBaristaPost] = []

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
            let fetchedPosts = try await service.fetchPosts()
            posts = merge(localFallbackPosts, with: fetchedPosts)
            sourceDescription = localFallbackPosts.isEmpty ? "Supabase 레시피" : "Supabase + 임시 로컬 레시피"
        } catch {
            posts = merge(localFallbackPosts, with: HomeBaristaPost.samplePosts)
            sourceDescription = localFallbackPosts.isEmpty ? "샘플 레시피" : "오프라인 임시 레시피"
            errorMessage = "홈바리스타 테이블이 아직 준비되지 않아 샘플 레시피를 보여주고 있어요."
        }
    }

    func createPost(
        brewMethod: String,
        title: String,
        beanName: String,
        ratioNote: String,
        tastingNote: String,
        brewNote: String,
        authorNickname: String
    ) async -> CreateResult {
        errorMessage = nil

        do {
            let syncedPost = try await service.addPost(
                brewMethod: brewMethod,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                beanName: beanName.trimmingCharacters(in: .whitespacesAndNewlines),
                ratioNote: ratioNote.trimmingCharacters(in: .whitespacesAndNewlines),
                tastingNote: tastingNote.trimmingCharacters(in: .whitespacesAndNewlines),
                brewNote: brewNote.trimmingCharacters(in: .whitespacesAndNewlines),
                authorNickname: authorNickname
            )

            posts.insert(syncedPost, at: 0)
            sourceDescription = localFallbackPosts.isEmpty ? "Supabase 레시피" : "Supabase + 임시 로컬 레시피"
            return .synced(syncedPost)
        } catch {
            let fallbackPost = HomeBaristaPost(
                id: UUID(),
                authorID: nil,
                authorName: authorNickname,
                brewMethod: brewMethod,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                beanName: beanName.trimmingCharacters(in: .whitespacesAndNewlines),
                ratioNote: ratioNote.trimmingCharacters(in: .whitespacesAndNewlines),
                tastingNote: tastingNote.trimmingCharacters(in: .whitespacesAndNewlines),
                brewNote: brewNote.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: Date(),
                source: .localFallback
            )

            localFallbackPosts.insert(fallbackPost, at: 0)
            posts = merge(localFallbackPosts, with: posts.filter { $0.source != .localFallback })
            sourceDescription = "오프라인 임시 레시피"
            errorMessage = "홈바리스타 서버가 아직 준비되지 않아 이 기기에만 임시 저장했어요."
            return .localFallback(fallbackPost)
        }
    }

    private func merge(_ localPosts: [HomeBaristaPost], with basePosts: [HomeBaristaPost]) -> [HomeBaristaPost] {
        let dedupedBase = basePosts.filter { post in
            !localPosts.contains(where: { $0.id == post.id })
        }

        return (localPosts + dedupedBase)
            .sorted { $0.createdAt > $1.createdAt }
    }
}
