import Foundation
import Supabase

struct ReviewService {
    private let client = SupabaseClientProvider.client

    func fetchReviews(for cafeID: UUID) async throws -> [CafeReview] {
        do {
            let records: [ReviewRecord] = try await client
                .from("reviews")
                .select()
                .eq("cafe_id", value: cafeID)
                .order("created_at", ascending: false)
                .execute()
                .value

            return records.map(\.asCafeReview)
        } catch {
            let legacyRecords: [LegacyReviewRecord] = try await client
                .from("reviews")
                .select("id, user_id, cafe_id, overall_rating, content, created_at, users(nickname)")
                .eq("cafe_id", value: cafeID)
                .order("created_at", ascending: false)
                .execute()
                .value

            return legacyRecords.map(\.asCafeReview)
        }
    }

    func fetchMyReviewRecords() async throws -> [ReviewRecord] {
        let userID = try await currentUserID()

        do {
            return try await client
                .from("reviews")
                .select()
                .eq("user_id", value: userID)
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {
            let legacyRecords: [LegacyReviewRecord] = try await client
                .from("reviews")
                .select("id, user_id, cafe_id, overall_rating, content, created_at, users(nickname)")
                .eq("user_id", value: userID)
                .order("created_at", ascending: false)
                .execute()
                .value

            return legacyRecords.map(\.asReviewRecord)
        }
    }

    func addReview(
        cafeID: UUID,
        authorNickname: String,
        rating: Int,
        visitNote: String,
        recommendedMenu: String
    ) async throws -> CafeReview {
        let userID = try await currentUserID()

        do {
            let record: ReviewRecord = try await client
                .from("reviews")
                .insert(
                    NewReviewRecord(
                        userID: userID,
                        cafeID: cafeID,
                        authorNickname: authorNickname,
                        overallRating: rating,
                        content: visitNote,
                        recommendedMenuName: recommendedMenu
                    )
                )
                .select()
                .single()
                .execute()
                .value

            return record.asCafeReview
        } catch {
            let record: LegacyInsertedReviewRecord = try await client
                .from("reviews")
                .insert(
                    LegacyNewReviewRecord(
                        userID: userID,
                        cafeID: cafeID,
                        overallRating: rating,
                        content: LegacyReviewContentSerializer.serialize(
                            recommendedMenu: recommendedMenu,
                            visitNote: visitNote
                        )
                    )
                )
                .select()
                .single()
                .execute()
                .value

            return CafeReview(
                id: record.id,
                authorName: authorNickname,
                rating: record.overallRating,
                visitNote: LegacyReviewContentSerializer.visitNote(from: record.content),
                recommendedMenu: LegacyReviewContentSerializer.recommendedMenu(from: record.content),
                createdAt: record.createdAt
            )
        }
    }

    private func currentUserID() async throws -> UUID {
        let session = try await client.auth.session
        return session.user.id
    }
}

struct ReviewRecord: Codable {
    let id: UUID
    let userID: UUID
    let cafeID: UUID
    let authorNickname: String
    let overallRating: Int
    let content: String?
    let recommendedMenuName: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case cafeID = "cafe_id"
        case authorNickname = "author_nickname"
        case overallRating = "overall_rating"
        case content
        case recommendedMenuName = "recommended_menu_name"
        case createdAt = "created_at"
    }

    var asCafeReview: CafeReview {
        CafeReview(
            id: id,
            authorName: authorNickname,
            rating: overallRating,
            visitNote: content ?? "",
            recommendedMenu: recommendedMenuName ?? "",
            createdAt: createdAt
        )
    }
}

private struct NewReviewRecord: Encodable {
    let userID: UUID
    let cafeID: UUID
    let authorNickname: String
    let overallRating: Int
    let content: String
    let recommendedMenuName: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case cafeID = "cafe_id"
        case authorNickname = "author_nickname"
        case overallRating = "overall_rating"
        case content
        case recommendedMenuName = "recommended_menu_name"
    }
}

private struct LegacyReviewRecord: Codable {
    let id: UUID
    let userID: UUID
    let cafeID: UUID
    let overallRating: Int
    let content: String?
    let createdAt: Date
    let users: LegacyReviewAuthor?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case cafeID = "cafe_id"
        case overallRating = "overall_rating"
        case content
        case createdAt = "created_at"
        case users
    }

    var asCafeReview: CafeReview {
        CafeReview(
            id: id,
            authorName: users?.nickname ?? "브루스팟 사용자",
            rating: overallRating,
            visitNote: LegacyReviewContentSerializer.visitNote(from: content),
            recommendedMenu: LegacyReviewContentSerializer.recommendedMenu(from: content),
            createdAt: createdAt
        )
    }

    var asReviewRecord: ReviewRecord {
        ReviewRecord(
            id: id,
            userID: userID,
            cafeID: cafeID,
            authorNickname: users?.nickname ?? "브루스팟 사용자",
            overallRating: overallRating,
            content: LegacyReviewContentSerializer.visitNote(from: content),
            recommendedMenuName: LegacyReviewContentSerializer.recommendedMenu(from: content),
            createdAt: createdAt
        )
    }
}

private struct LegacyReviewAuthor: Codable {
    let nickname: String?
}

private struct LegacyInsertedReviewRecord: Codable {
    let id: UUID
    let overallRating: Int
    let content: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case overallRating = "overall_rating"
        case content
        case createdAt = "created_at"
    }
}

private struct LegacyNewReviewRecord: Encodable {
    let userID: UUID
    let cafeID: UUID
    let overallRating: Int
    let content: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case cafeID = "cafe_id"
        case overallRating = "overall_rating"
        case content
    }
}

private enum LegacyReviewContentSerializer {
    private static let prefix = "[추천메뉴]"

    static func serialize(recommendedMenu: String, visitNote: String) -> String {
        "\(prefix) \(recommendedMenu)\n\(visitNote)"
    }

    static func recommendedMenu(from content: String?) -> String {
        guard let content else { return "" }
        let lines = content.components(separatedBy: .newlines)
        guard let firstLine = lines.first, firstLine.hasPrefix(prefix) else { return "" }
        return firstLine.replacingOccurrences(of: "\(prefix) ", with: "")
    }

    static func visitNote(from content: String?) -> String {
        guard let content else { return "" }
        let lines = content.components(separatedBy: .newlines)
        guard let firstLine = lines.first, firstLine.hasPrefix(prefix) else { return content }
        return lines.dropFirst().joined(separator: "\n")
    }
}
