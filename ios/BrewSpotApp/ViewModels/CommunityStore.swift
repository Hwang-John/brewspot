import Foundation

@MainActor
final class CommunityStore: ObservableObject {
    enum CreateResult {
        case synced(CommunityPost)
        case localFallback(CommunityPost)
    }

    @Published private(set) var posts: [CommunityPost] = []
    @Published private(set) var isLoading = false
    @Published private(set) var sourceDescription = "커뮤니티 준비 중"
    @Published var errorMessage: String?

    private let service = CommunityService()
    private var hasLoaded = false
    private var localFallbackPosts: [CommunityPost] = []

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
            sourceDescription = localFallbackPosts.isEmpty ? "Supabase 커뮤니티" : "Supabase + 임시 로컬 글"
        } catch {
            posts = merge(localFallbackPosts, with: CommunityPost.samplePosts)
            sourceDescription = localFallbackPosts.isEmpty ? "샘플 커뮤니티" : "오프라인 임시 게시판"
            errorMessage = "커뮤니티 테이블이 아직 준비되지 않아 샘플 글을 보여주고 있어요."
        }
    }

    func createPost(
        title: String,
        content: String,
        category: String,
        city: String,
        authorNickname: String
    ) async -> CreateResult {
        errorMessage = nil

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let syncedPost = try await service.addPost(
                title: trimmedTitle,
                content: trimmedContent,
                category: category,
                city: trimmedCity.isEmpty ? "동네 미정" : trimmedCity,
                authorNickname: authorNickname
            )

            posts.insert(syncedPost, at: 0)
            sourceDescription = localFallbackPosts.isEmpty ? "Supabase 커뮤니티" : "Supabase + 임시 로컬 글"
            return .synced(syncedPost)
        } catch {
            let fallbackPost = CommunityPost(
                id: UUID(),
                authorID: nil,
                authorName: authorNickname,
                category: category,
                title: trimmedTitle,
                content: trimmedContent,
                city: trimmedCity.isEmpty ? "동네 미정" : trimmedCity,
                likeCount: 0,
                commentCount: 0,
                createdAt: Date(),
                source: .localFallback
            )

            localFallbackPosts.insert(fallbackPost, at: 0)
            posts = merge(localFallbackPosts, with: posts.filter { $0.source != .localFallback })
            sourceDescription = "오프라인 임시 게시판"
            errorMessage = "커뮤니티 서버가 아직 준비되지 않아 이 기기에만 임시 저장했어요."
            return .localFallback(fallbackPost)
        }
    }

    private func merge(_ localPosts: [CommunityPost], with basePosts: [CommunityPost]) -> [CommunityPost] {
        let dedupedBase = basePosts.filter { post in
            !localPosts.contains(where: { $0.id == post.id })
        }

        return (localPosts + dedupedBase)
            .sorted { $0.createdAt > $1.createdAt }
    }
}
