import Foundation

struct CafeReview: Identifiable, Codable {
    let id: UUID
    let authorName: String
    let rating: Int
    let visitNote: String
    let recommendedMenu: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        authorName: String,
        rating: Int,
        visitNote: String,
        recommendedMenu: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.authorName = authorName
        self.rating = rating
        self.visitNote = visitNote
        self.recommendedMenu = recommendedMenu
        self.createdAt = createdAt
    }

    var relativeCreatedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    static func samples(for cafe: Cafe) -> [CafeReview] {
        switch cafe.name {
        case "성수커피":
            return [
                CafeReview(authorName: "라떼헌터", rating: 5, visitNote: "플랫화이트 밸런스가 정말 좋고 좌석 간격이 넉넉해서 혼자 머물기 편했어요.", recommendedMenu: "플랫화이트", createdAt: Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date()),
                CafeReview(authorName: "원두메모", rating: 4, visitNote: "산미가 튀지 않고 편하게 마시기 좋아요. 오후 시간대에도 매장이 비교적 차분했어요.", recommendedMenu: "아메리카노", createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date())
            ]
        case "연남카페":
            return [
                CafeReview(authorName: "모닝브루", rating: 5, visitNote: "직접 로스팅한 향이 살아 있고 대화하기 좋은 분위기라 재방문 의사가 높아요.", recommendedMenu: "시그니처 라떼", createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()),
                CafeReview(authorName: "카페산책", rating: 4, visitNote: "주말엔 조금 붐볐지만 사진 찍기 좋고 디저트 조합도 만족스러웠어요.", recommendedMenu: "드립커피", createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date())
            ]
        default:
            return [
                CafeReview(authorName: "브런치러버", rating: 5, visitNote: "브런치 양이 넉넉하고 커피랑 잘 어울려서 주말 낮 방문에 잘 맞았어요.", recommendedMenu: "브런치 플레이트", createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()),
                CafeReview(authorName: "동네탐방", rating: 4, visitNote: "테이블 간격이 적당해서 친구와 오래 이야기하기 좋았고 오전 햇살이 예뻤어요.", recommendedMenu: "라떼", createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date())
            ]
        }
    }
}
