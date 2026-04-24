import Foundation
import Supabase

struct BookmarkService {
    private let client = SupabaseClientProvider.client

    func fetchBookmarks() async throws -> [BookmarkRecord] {
        let userID = try await currentUserID()

        return try await client
            .from("bookmarks")
            .select()
            .eq("user_id", value: userID)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func addBookmark(cafeID: UUID) async throws -> BookmarkRecord {
        let userID = try await currentUserID()

        return try await client
            .from("bookmarks")
            .upsert(NewBookmarkRecord(userID: userID, cafeID: cafeID), onConflict: "user_id,cafe_id")
            .select()
            .single()
            .execute()
            .value
    }

    func removeBookmark(cafeID: UUID) async throws {
        let userID = try await currentUserID()

        try await client
            .from("bookmarks")
            .delete()
            .eq("user_id", value: userID)
            .eq("cafe_id", value: cafeID)
            .execute()
    }

    private func currentUserID() async throws -> UUID {
        let session = try await client.auth.session
        return session.user.id
    }
}

struct BookmarkRecord: Codable {
    let id: UUID
    let userID: UUID
    let cafeID: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case cafeID = "cafe_id"
        case createdAt = "created_at"
    }
}

private struct NewBookmarkRecord: Encodable {
    let userID: UUID
    let cafeID: UUID

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case cafeID = "cafe_id"
    }
}
