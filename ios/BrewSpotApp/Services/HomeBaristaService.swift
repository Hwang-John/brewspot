import Foundation
import Supabase

struct HomeBaristaService {
    private let client = SupabaseClientProvider.client

    func fetchPosts() async throws -> [HomeBaristaPost] {
        let records: [HomeBaristaPostRecord] = try await client
            .from("homebarista_posts")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value

        return records.map(\.asHomeBaristaPost)
    }

    func addPost(
        brewMethod: String,
        title: String,
        beanName: String,
        ratioNote: String,
        tastingNote: String,
        brewNote: String,
        authorNickname: String
    ) async throws -> HomeBaristaPost {
        let userID = try await currentUserID()

        let record: HomeBaristaPostRecord = try await client
            .from("homebarista_posts")
            .insert(
                NewHomeBaristaPostRecord(
                    userID: userID,
                    authorNickname: authorNickname,
                    brewMethod: brewMethod,
                    title: title,
                    beanName: beanName,
                    ratioNote: ratioNote,
                    tastingNote: tastingNote,
                    brewNote: brewNote
                )
            )
            .select()
            .single()
            .execute()
            .value

        return record.asHomeBaristaPost
    }

    private func currentUserID() async throws -> UUID {
        let session = try await client.auth.session
        return session.user.id
    }
}

private struct HomeBaristaPostRecord: Codable {
    let id: UUID
    let userID: UUID
    let authorNickname: String
    let brewMethod: String
    let title: String
    let beanName: String
    let ratioNote: String
    let tastingNote: String
    let brewNote: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case authorNickname = "author_nickname"
        case brewMethod = "brew_method"
        case title
        case beanName = "bean_name"
        case ratioNote = "ratio_note"
        case tastingNote = "tasting_note"
        case brewNote = "brew_note"
        case createdAt = "created_at"
    }

    var asHomeBaristaPost: HomeBaristaPost {
        HomeBaristaPost(
            id: id,
            authorID: userID,
            authorName: authorNickname,
            brewMethod: brewMethod,
            title: title,
            beanName: beanName,
            ratioNote: ratioNote,
            tastingNote: tastingNote,
            brewNote: brewNote,
            createdAt: createdAt,
            source: .remote
        )
    }
}

private struct NewHomeBaristaPostRecord: Encodable {
    let userID: UUID
    let authorNickname: String
    let brewMethod: String
    let title: String
    let beanName: String
    let ratioNote: String
    let tastingNote: String
    let brewNote: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case authorNickname = "author_nickname"
        case brewMethod = "brew_method"
        case title
        case beanName = "bean_name"
        case ratioNote = "ratio_note"
        case tastingNote = "tasting_note"
        case brewNote = "brew_note"
    }
}
