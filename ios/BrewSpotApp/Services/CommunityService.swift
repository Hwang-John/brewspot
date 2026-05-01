import Foundation
import Supabase

struct CommunityService {
    private let client = SupabaseClientProvider.client

    func fetchPosts() async throws -> [CommunityPost] {
        let records: [CommunityPostRecord] = try await client
            .from("community_posts")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value

        return records.map(\.asCommunityPost)
    }

    func addPost(
        title: String,
        content: String,
        category: String,
        city: String,
        authorNickname: String
    ) async throws -> CommunityPost {
        let userID = try await currentUserID()

        let record: CommunityPostRecord = try await client
            .from("community_posts")
            .insert(
                NewCommunityPostRecord(
                    userID: userID,
                    authorNickname: authorNickname,
                    boardType: category,
                    title: title,
                    content: content,
                    city: city
                )
            )
            .select()
            .single()
            .execute()
            .value

        return record.asCommunityPost
    }

    private func currentUserID() async throws -> UUID {
        let session = try await client.auth.session
        return session.user.id
    }
}

private struct CommunityPostRecord: Codable {
    let id: UUID
    let userID: UUID
    let authorNickname: String
    let boardType: String
    let title: String
    let content: String
    let city: String?
    let likeCount: Int?
    let commentCount: Int?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case authorNickname = "author_nickname"
        case boardType = "board_type"
        case title
        case content
        case city
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case createdAt = "created_at"
    }

    var asCommunityPost: CommunityPost {
        CommunityPost(
            id: id,
            authorID: userID,
            authorName: authorNickname,
            category: boardType,
            title: title,
            content: content,
            city: city ?? "동네 미정",
            likeCount: likeCount ?? 0,
            commentCount: commentCount ?? 0,
            createdAt: createdAt,
            source: .remote
        )
    }
}

private struct NewCommunityPostRecord: Encodable {
    let userID: UUID
    let authorNickname: String
    let boardType: String
    let title: String
    let content: String
    let city: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case authorNickname = "author_nickname"
        case boardType = "board_type"
        case title
        case content
        case city
    }
}
