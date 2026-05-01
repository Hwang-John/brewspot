import Foundation

struct HomeBaristaPost: Identifiable, Equatable {
    enum Source: String {
        case remote
        case localFallback
        case sample
    }

    let id: UUID
    let authorID: UUID?
    let authorName: String
    let brewMethod: String
    let title: String
    let beanName: String
    let ratioNote: String
    let tastingNote: String
    let brewNote: String
    let createdAt: Date
    let source: Source

    var previewText: String {
        let trimmed = tastingNote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 84 else { return trimmed }
        return String(trimmed.prefix(84)) + "..."
    }

    var relativeDateText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

extension HomeBaristaPost {
    static let samplePosts: [HomeBaristaPost] = [
        HomeBaristaPost(
            id: UUID(uuidString: "B4AB0744-5AE7-40D3-8697-148481868B67") ?? UUID(),
            authorID: nil,
            authorName: "브루노트",
            brewMethod: "V60",
            title: "성수 블렌드로 가볍게 내리는 아침 레시피",
            beanName: "BrewSpot House Blend",
            ratioNote: "15g : 240ml / 2분 30초",
            tastingNote: "첫 모금은 견과류 느낌이 부드럽고, 식으면서 은은한 초콜릿 뉘앙스가 올라와요.",
            brewNote: "40ml bloom 30초 후 100ml, 180ml, 240ml 순서로 나눠 부었어요. 물줄기는 중앙보다 살짝 바깥쪽이 더 안정적이었어요.",
            createdAt: Date().addingTimeInterval(-60 * 50),
            source: .sample
        ),
        HomeBaristaPost(
            id: UUID(uuidString: "80C08846-D6B3-4CB1-B554-72C9F85A4A12") ?? UUID(),
            authorID: nil,
            authorName: "홈카페준",
            brewMethod: "에어로프레스",
            title: "산미 줄이고 단맛 살린 에어로프레스",
            beanName: "Ethiopia Guji",
            ratioNote: "17g : 220ml / 1분 50초",
            tastingNote: "산미가 너무 튀지 않고 복숭아 같은 단맛이 뒤에 남아요. 점심 이후에도 부담이 적었어요.",
            brewNote: "역방향으로 1분 침출 후 천천히 20초 프레스했어요. 물 온도는 88도 쪽이 훨씬 편안했어요.",
            createdAt: Date().addingTimeInterval(-60 * 60 * 3),
            source: .sample
        ),
        HomeBaristaPost(
            id: UUID(uuidString: "4ED47807-E047-4B52-8D4B-A04AEE9BC4B7") ?? UUID(),
            authorID: nil,
            authorName: "드립메모",
            brewMethod: "콜드브루",
            title: "주말용 콜드브루 베이스 비율 공유",
            beanName: "Brazil Cerrado",
            ratioNote: "80g : 800ml / 14시간",
            tastingNote: "우유와 섞어도 맛이 흐려지지 않고, 단맛이 둥글게 남아요.",
            brewNote: "굵은 분쇄로 냉장 침출했고, 원액 기준이라 마실 때는 얼음이나 물로 1:1 정도 희석했어요.",
            createdAt: Date().addingTimeInterval(-60 * 60 * 8),
            source: .sample
        )
    ]
}
