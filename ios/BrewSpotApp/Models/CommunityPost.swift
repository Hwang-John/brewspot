import Foundation

struct CommunityPost: Identifiable, Equatable {
    enum Source: String {
        case remote
        case localFallback
        case sample
    }

    let id: UUID
    let authorID: UUID?
    let authorName: String
    let category: String
    let title: String
    let content: String
    let city: String
    let likeCount: Int
    let commentCount: Int
    let createdAt: Date
    let source: Source

    var previewText: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 90 else { return trimmed }
        return String(trimmed.prefix(90)) + "..."
    }

    var relativeDateText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

extension CommunityPost {
    static let samplePosts: [CommunityPost] = [
        CommunityPost(
            id: UUID(uuidString: "4B0CCCF7-DBF9-4B6A-BDF3-8AC0CB1E1CA1") ?? UUID(),
            authorID: nil,
            authorName: "브루가이드",
            category: "추천",
            title: "성수에서 오래 머물기 좋은 카페 추천해요",
            content: "콘센트 자리 넉넉하고 음악이 너무 시끄럽지 않은 곳 위주로 골라봤어요. 평일 오후 기준으로는 창가보다 안쪽 긴 테이블 쪽이 훨씬 편했어요.",
            city: "성수",
            likeCount: 18,
            commentCount: 4,
            createdAt: Date().addingTimeInterval(-60 * 35),
            source: .sample
        ),
        CommunityPost(
            id: UUID(uuidString: "0AAB2A27-A0AE-4F5F-96A8-BA8B2D2E7069") ?? UUID(),
            authorID: nil,
            authorName: "연남러버",
            category: "자유",
            title: "연남 카페 투어 동선 이렇게 잡아도 괜찮을까요?",
            content: "오후 2시쯤 시작해서 3곳 정도만 천천히 돌고 싶어요. 디저트보다는 커피 맛 중심으로 보고 있고, 이동은 도보 기준이에요.",
            city: "연남",
            likeCount: 9,
            commentCount: 7,
            createdAt: Date().addingTimeInterval(-60 * 90),
            source: .sample
        ),
        CommunityPost(
            id: UUID(uuidString: "C26C9BE8-94B4-4A46-8E55-2211F6A84E7B") ?? UUID(),
            authorID: nil,
            authorName: "망원필터",
            category: "질문",
            title: "망원에서 디카페인 괜찮은 곳 있나요?",
            content: "저녁에도 부담 없이 마시고 싶어서 디카페인 원두 퀄리티 괜찮은 곳 찾고 있어요. 산미가 너무 강하지 않으면 더 좋겠습니다.",
            city: "망원",
            likeCount: 6,
            commentCount: 2,
            createdAt: Date().addingTimeInterval(-60 * 60 * 4),
            source: .sample
        )
    ]
}
