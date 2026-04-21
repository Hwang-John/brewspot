import Foundation

extension Cafe {
    static let sampleCafes: [Cafe] = [
        Cafe(
            name: "성수커피",
            address: "서울 성동구 성수동",
            category: "스페셜티",
            city: "성수",
            latitude: 37.5445,
            longitude: 127.0561,
            rating: 4.8,
            reviewCount: 128,
            priceNote: "1인 7천원대",
            signatureMenu: "플랫화이트",
            shortDescription: "균형 잡힌 원두와 차분한 좌석감이 강점인 스페셜티 카페",
            vibeTags: ["조용한", "작업하기 좋은", "원두 맛집"],
            features: ["에스프레소 베이스 음료 만족도가 높아요.", "혼자 방문하기 좋은 좌석 배치예요.", "짧게 머물며 커피를 즐기기 좋아요."],
            openHours: "매일 10:00 - 21:00"
        ),
        Cafe(
            name: "연남카페",
            address: "서울 마포구 연남동",
            category: "로스팅",
            city: "연남",
            latitude: 37.5651,
            longitude: 126.9234,
            rating: 4.6,
            reviewCount: 94,
            priceNote: "1인 8천원대",
            signatureMenu: "시그니처 라떼",
            shortDescription: "직접 로스팅한 원두 풍미와 밝은 무드가 살아 있는 로스터리",
            vibeTags: ["대화하기 좋은", "향이 좋은", "데이트 추천"],
            features: ["향 중심 원두를 좋아하면 만족도가 높아요.", "매장 분위기가 밝고 사진이 잘 나와요.", "주말에는 다소 붐빌 수 있어요."],
            openHours: "매일 11:00 - 22:00"
        ),
        Cafe(
            name: "망원카페",
            address: "서울 마포구 망원동",
            category: "브런치",
            city: "망원",
            latitude: 37.5565,
            longitude: 126.9018,
            rating: 4.5,
            reviewCount: 73,
            priceNote: "1인 1만원대",
            signatureMenu: "브런치 플레이트",
            shortDescription: "브런치와 커피를 함께 즐기기 좋은 여유로운 동네 카페",
            vibeTags: ["브런치", "주말 방문", "친구와 가기 좋은"],
            features: ["식사와 커피를 한 번에 해결하기 편해요.", "테이블 간격이 적당해 모임에 좋아요.", "오전 시간대 방문 만족도가 높아요."],
            openHours: "화-일 09:00 - 20:00"
        )
    ]
}
