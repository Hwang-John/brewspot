import type { AppUser, Cafe, CafeReview, CommunityPost, HomeBaristaPost } from "../types";

export const demoUser: AppUser = {
  id: "demo-user",
  nickname: "게스트 브루어",
  email: "guest@brewspot.local",
  profileImageUrl: null,
  status: "active"
};

export const demoCafes: Cafe[] = [
  {
    id: "cafe-seongsu-denny",
    name: "대니스수퍼마켓",
    address: "서울 성동구 연무장15길 11",
    category: "디저트",
    city: "성수",
    latitude: 37.5428,
    longitude: 127.0589,
    rating: 4.7,
    reviewCount: 3,
    priceNote: "1인 1만원대",
    signatureMenu: "대니스츄 플레인",
    shortDescription: "성수 골목 감성과 디저트 무드가 살아 있는 츄러스 카페",
    vibeTags: ["디저트 맛집", "사진이 잘 나오는", "친구와 가기 좋은"],
    features: ["성수 메인 골목 접근성", "디저트 메뉴 반응 좋음"],
    openHours: "매일 11:00 - 22:00"
  },
  {
    id: "cafe-yeonnam-layer",
    name: "레이어드 연남",
    address: "서울 마포구 성미산로 161-4",
    category: "브런치",
    city: "연남",
    latitude: 37.5623,
    longitude: 126.9251,
    rating: 4.5,
    reviewCount: 4,
    priceNote: "1인 1만5천원대",
    signatureMenu: "스콘 플레이트",
    shortDescription: "오래 머물기 좋고 디저트 선택지가 풍부한 연남 대표 무드 카페",
    vibeTags: ["브런치", "대화하기 좋은", "오래 머물기 좋은"],
    features: ["넓은 좌석", "디저트 선택지 다양"],
    openHours: "매일 10:30 - 21:30"
  },
  {
    id: "cafe-mangwon-tailor",
    name: "테일러커피 망원",
    address: "서울 마포구 포은로 87",
    category: "스페셜티",
    city: "망원",
    latitude: 37.5557,
    longitude: 126.9056,
    rating: 4.8,
    reviewCount: 5,
    priceNote: "1인 8천원대",
    signatureMenu: "플랫화이트",
    shortDescription: "커피 밸런스를 중심으로 다시 찾게 되는 망원 스페셜티 스팟",
    vibeTags: ["커피 맛집", "혼자 가기 좋은", "조용한"],
    features: ["원두 선택 가능", "짧게 들르기 좋은 동선"],
    openHours: "매일 09:00 - 20:00"
  },
  {
    id: "cafe-seongsu-mill",
    name: "밀도 성수",
    address: "서울 성동구 성수이로7길 41-1",
    category: "베이커리",
    city: "성수",
    latitude: 37.5396,
    longitude: 127.0553,
    rating: 4.4,
    reviewCount: 2,
    priceNote: "1인 1만원대",
    signatureMenu: "우유식빵 토스트",
    shortDescription: "빵과 커피를 함께 즐기기 좋은 따뜻한 결의 베이커리 카페",
    vibeTags: ["베이커리", "아침 방문", "포근한"],
    features: ["포장 수요 높음", "빵 회전 빠름"],
    openHours: "매일 08:30 - 20:30"
  }
];

export const demoReviews: CafeReview[] = [
  {
    id: "review-1",
    userId: "demo-user",
    cafeId: "cafe-seongsu-denny",
    authorNickname: "게스트 브루어",
    overallRating: 5,
    recommendedMenuName: "대니스츄 플레인",
    content: "디저트 비주얼이 좋아서 사진 찍기 좋고 좌석 회전도 생각보다 괜찮았어요.",
    createdAt: "2026-05-08T12:00:00+09:00"
  },
  {
    id: "review-2",
    userId: "friend-1",
    cafeId: "cafe-seongsu-denny",
    authorNickname: "라떼헌터",
    overallRating: 4,
    recommendedMenuName: "아인슈페너",
    content: "주말엔 조금 붐비지만 성수 감성 카페로 데려가기 좋아요.",
    createdAt: "2026-05-07T16:30:00+09:00"
  },
  {
    id: "review-3",
    userId: "friend-2",
    cafeId: "cafe-yeonnam-layer",
    authorNickname: "브런치러버",
    overallRating: 5,
    recommendedMenuName: "스콘 플레이트",
    content: "대화하기 좋고 디저트가 많아서 오래 머물기 편했어요.",
    createdAt: "2026-05-06T10:15:00+09:00"
  },
  {
    id: "review-4",
    userId: "friend-3",
    cafeId: "cafe-mangwon-tailor",
    authorNickname: "원두메모",
    overallRating: 5,
    recommendedMenuName: "플랫화이트",
    content: "커피 밸런스가 정말 좋고 혼자 들러서 집중하기 좋았습니다.",
    createdAt: "2026-05-05T09:40:00+09:00"
  },
  {
    id: "review-5",
    userId: "friend-4",
    cafeId: "cafe-seongsu-mill",
    authorNickname: "빵순이",
    overallRating: 4,
    recommendedMenuName: "우유식빵 토스트",
    content: "빵 향이 좋아서 아침에 가기 좋고 커피도 무난하게 잘 어울려요.",
    createdAt: "2026-05-03T08:50:00+09:00"
  }
];

export const demoCommunityPosts: CommunityPost[] = [
  {
    id: "community-1",
    authorId: null,
    authorName: "브루가이드",
    category: "추천",
    title: "성수에서 오래 머물기 좋은 카페 추천해요",
    content:
      "콘센트 자리 넉넉하고 음악이 너무 시끄럽지 않은 곳 위주로 골라봤어요. 평일 오후 기준으로는 창가보다 안쪽 긴 테이블 쪽이 훨씬 편했어요.",
    city: "성수",
    likeCount: 18,
    commentCount: 4,
    createdAt: new Date(Date.now() - 1000 * 60 * 35).toISOString(),
    source: "sample"
  },
  {
    id: "community-2",
    authorId: null,
    authorName: "연남러버",
    category: "자유",
    title: "연남 카페 투어 동선 이렇게 잡아도 괜찮을까요?",
    content:
      "오후 2시쯤 시작해서 3곳 정도만 천천히 돌고 싶어요. 디저트보다는 커피 맛 중심으로 보고 있고, 이동은 도보 기준이에요.",
    city: "연남",
    likeCount: 9,
    commentCount: 7,
    createdAt: new Date(Date.now() - 1000 * 60 * 90).toISOString(),
    source: "sample"
  },
  {
    id: "community-3",
    authorId: null,
    authorName: "망원필터",
    category: "질문",
    title: "망원에서 디카페인 괜찮은 곳 있나요?",
    content:
      "저녁에도 부담 없이 마시고 싶어서 디카페인 원두 퀄리티 괜찮은 곳 찾고 있어요. 산미가 너무 강하지 않으면 더 좋겠습니다.",
    city: "망원",
    likeCount: 6,
    commentCount: 2,
    createdAt: new Date(Date.now() - 1000 * 60 * 60 * 4).toISOString(),
    source: "sample"
  }
];

export const demoHomeBaristaPosts: HomeBaristaPost[] = [
  {
    id: "barista-1",
    authorId: null,
    authorName: "브루노트",
    brewMethod: "V60",
    title: "성수 블렌드로 가볍게 내리는 아침 레시피",
    beanName: "BrewSpot House Blend",
    ratioNote: "15g : 240ml / 2분 30초",
    tastingNote: "첫 모금은 견과류 느낌이 부드럽고, 식으면서 은은한 초콜릿 뉘앙스가 올라와요.",
    brewNote:
      "40ml bloom 30초 후 100ml, 180ml, 240ml 순서로 나눠 부었어요. 물줄기는 중앙보다 살짝 바깥쪽이 더 안정적이었어요.",
    createdAt: new Date(Date.now() - 1000 * 60 * 50).toISOString(),
    source: "sample"
  },
  {
    id: "barista-2",
    authorId: null,
    authorName: "홈카페준",
    brewMethod: "에어로프레스",
    title: "산미 줄이고 단맛 살린 에어로프레스",
    beanName: "Ethiopia Guji",
    ratioNote: "17g : 220ml / 1분 50초",
    tastingNote: "산미가 너무 튀지 않고 복숭아 같은 단맛이 뒤에 남아요. 점심 이후에도 부담이 적었어요.",
    brewNote:
      "역방향으로 1분 침출 후 천천히 20초 프레스했어요. 물 온도는 88도 쪽이 훨씬 편안했어요.",
    createdAt: new Date(Date.now() - 1000 * 60 * 60 * 3).toISOString(),
    source: "sample"
  },
  {
    id: "barista-3",
    authorId: null,
    authorName: "드립메모",
    brewMethod: "콜드브루",
    title: "주말용 콜드브루 베이스 비율 공유",
    beanName: "Brazil Cerrado",
    ratioNote: "80g : 800ml / 14시간",
    tastingNote: "우유와 섞어도 맛이 흐려지지 않고, 단맛이 둥글게 남아요.",
    brewNote:
      "굵은 분쇄로 냉장 침출했고, 원액 기준이라 마실 때는 얼음이나 물로 1:1 정도 희석했어요.",
    createdAt: new Date(Date.now() - 1000 * 60 * 60 * 8).toISOString(),
    source: "sample"
  }
];
