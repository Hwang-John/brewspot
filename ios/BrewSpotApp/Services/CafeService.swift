import Foundation
import Supabase

struct CafeService {
    private let client = SupabaseClientProvider.client

    func fetchCafes() async throws -> [Cafe] {
        let records: [CafeRecord] = try await client
            .from("cafes")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value

        return records.map(\.asCafe)
    }
}

private struct CafeRecord: Codable {
    let id: UUID
    let name: String
    let address: String
    let category: String?
    let city: String?
    let latitude: Double?
    let longitude: Double?
    let signatureMenuName: String?
    let priceNote: String?
    let avgRating: Double?
    let reviewCount: Int?
    let shortDescription: String?
    let vibeTags: [String]?
    let features: [String]?
    let openHours: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case category
        case city
        case latitude
        case longitude
        case signatureMenuName = "signature_menu_name"
        case priceNote = "price_note"
        case avgRating = "avg_rating"
        case reviewCount = "review_count"
        case shortDescription = "short_description"
        case vibeTags = "vibe_tags"
        case features
        case openHours = "open_hours"
    }

    var asCafe: Cafe {
        Cafe(
            id: id,
            name: name,
            address: address,
            category: category ?? "카페",
            city: city ?? Self.inferCity(from: address),
            latitude: latitude ?? 37.5665,
            longitude: longitude ?? 126.9780,
            rating: avgRating ?? 0,
            reviewCount: reviewCount ?? 0,
            priceNote: priceNote ?? "현장 확인 필요",
            signatureMenu: signatureMenuName ?? "대표 메뉴 준비 중",
            shortDescription: shortDescription ?? "카페 소개를 준비 중이에요.",
            vibeTags: vibeTags ?? [],
            features: features ?? [],
            openHours: openHours ?? "운영 시간 정보 준비 중"
        )
    }

    private static func inferCity(from address: String) -> String {
        let components = address.split(separator: " ")
        guard components.count > 1 else { return "지역 정보" }
        return String(components[1])
    }
}
