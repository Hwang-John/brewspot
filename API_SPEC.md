# BrewSpot 데이터/API 기준안

최종 기준일: 2026-04-24

## 1. 목적

현재 BrewSpot MVP는 iOS 앱이 Supabase를 직접 사용하는 구조다.  
이 문서는 별도 REST 서버가 있다고 가정한 장기 명세가 아니라, 현재 앱이 실제로 다루는 리소스와 동등한 데이터 계약을 정리한다.

## 2. 현재 인증 계약

### 이메일 로그인

입력:

```json
{
  "email": "user@example.com",
  "password": "password"
}
```

처리:

1. Supabase Auth 로그인
2. 사용자 프로필 보장 로직 실행
3. 세션 저장

### 이메일 회원가입

입력:

```json
{
  "nickname": "brew_jane",
  "email": "user@example.com",
  "password": "password"
}
```

### Google / Apple 로그인

1. 앱에서 OAuth 시작
2. Supabase Auth OAuth 완료
3. 사용자 프로필 보장 로직 실행

## 3. 현재 사용자 리소스

### `users`

```json
{
  "id": "uuid",
  "nickname": "brew_jane",
  "email": "user@example.com",
  "profileImageUrl": null,
  "status": "active"
}
```

### `user_identities`

```json
{
  "provider": "google",
  "providerUserId": "provider_user_id",
  "providerEmail": "user@example.com"
}
```

## 4. 현재 카페 리소스

### 카페 목록 / 상세

```json
{
  "id": "uuid",
  "name": "대니스수퍼마켓",
  "address": "서울 성동구 연무장15길 11",
  "category": "디저트",
  "city": "성수",
  "latitude": 37.5428358,
  "longitude": 127.0589363,
  "signatureMenuName": "대니스츄 플레인",
  "signatureMenuPrice": 4500,
  "priceNote": "1인 1만원대",
  "shortDescription": "츄러스와 디저트를 중심으로 성수 골목 감성이 살아 있는 카페",
  "vibeTags": ["디저트 맛집", "사진이 잘 나오는", "친구와 가기 좋은"],
  "features": ["츄러스류 메뉴 반응이 좋음", "성수 메인 골목 접근성이 좋음"],
  "openHours": "매일 11:00 - 22:00",
  "avgRating": 4.7,
  "reviewCount": 3
}
```

현재 지원 조회 기준:

1. 카페 목록
2. 카페 상세
3. 홈 검색
4. 카테고리 필터

현재 미지원:

1. 현재 위치 기반 nearby API
2. 랭킹 API
3. 메뉴 전용 API

## 5. 현재 리뷰 리소스

### 리뷰 작성 입력

```json
{
  "authorNickname": "브루러버",
  "overallRating": 5,
  "recommendedMenuName": "플랫화이트",
  "content": "조용하고 커피 밸런스가 좋았어요."
}
```

### 리뷰 조회 응답 예시

```json
{
  "id": "uuid",
  "userId": "uuid",
  "cafeId": "uuid",
  "authorNickname": "브루러버",
  "overallRating": 5,
  "recommendedMenuName": "플랫화이트",
  "content": "조용하고 커피 밸런스가 좋았어요.",
  "createdAt": "2026-04-24T09:00:00+09:00"
}
```

현재 미지원:

1. 구조화 세부 평점
2. 리뷰 이미지 업로드
3. 리뷰 수정 / 삭제 UI
4. 리뷰 신고 API

## 6. 현재 북마크 리소스

입력:

```json
{
  "userId": "uuid",
  "cafeId": "uuid"
}
```

동작:

1. 북마크 저장
2. 북마크 해제
3. 마이페이지 저장 목록 조회

## 7. 2차 이후 확장 API 후보

1. 근처 추천
2. 랭킹
3. 커뮤니티 게시판
4. 홈바리스타 피드
5. 리뷰 신고 / 운영 신고
6. 계정 연결 / 해제 API

## 8. 현재 결론

현재는 `직접 Supabase 연동 구조`를 기준으로 보고, 별도 백엔드 API 명세는 2차 확장 시점에 다시 구체화한다.
