import type { AppUser, Cafe, CafeReview } from "../types";

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
