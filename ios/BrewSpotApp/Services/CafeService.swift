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
    let name: String
    let address: String
    let latitude: Double?
    let longitude: Double?
    let signatureMenuName: String?
    let avgRating: Double?
    let reviewCount: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case address
        case latitude
        case longitude
        case signatureMenuName = "signature_menu_name"
        case avgRating = "avg_rating"
        case reviewCount = "review_count"
    }

    var asCafe: Cafe {
        Cafe(
            name: name,
            address: address,
            category: "카페",
            city: Self.inferCity(from: address),
            latitude: latitude ?? 37.5665,
            longitude: longitude ?? 126.9780,
            rating: avgRating ?? 0,
            reviewCount: reviewCount ?? 0,
            priceNote: "현장 확인 필요",
            signatureMenu: signatureMenuName ?? "대표 메뉴 준비 중",
            shortDescription: "Supabase에서 불러온 카페 데이터입니다. 상세 정보는 이후 단계에서 더 풍부하게 연결할 예정이에요.",
            vibeTags: ["신규 데이터", "정보 보강 예정"],
            features: ["기본 위치와 대표 메뉴 중심으로 먼저 연결된 상태예요.", "리뷰와 저장 기능은 다음 단계에서 실제 DB와 연결할 예정이에요."],
            openHours: "운영 시간 정보 준비 중"
        )
    }

    private static func inferCity(from address: String) -> String {
        let components = address.split(separator: " ")
        guard components.count > 1 else { return "지역 정보" }
        return String(components[1])
    }
}
