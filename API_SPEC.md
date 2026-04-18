# BrewSpot API 명세 초안

## 1. 목적

이 문서는 BrewSpot MVP 기준 API 초안이다.  
실제 구현 시 REST 기준으로 시작하며, 인증은 Bearer Token 기반을 가정한다.

Base URL 예시:

```text
https://api.brewspot.app/v1
```

---

## 2. 인증

### `POST /auth/login/sso`

소셜 로그인 토큰으로 로그인 또는 회원가입 처리

Request

```json
{
  "provider": "google",
  "idToken": "token_value",
  "accessToken": "optional_access_token",
  "nonce": "optional_nonce"
}
```

Response

```json
{
  "user": {
    "id": "uuid",
    "nickname": "brew_jane",
    "email": "relay@example.com",
    "profileImageUrl": null
  },
  "tokens": {
    "accessToken": "jwt",
    "refreshToken": "refresh_jwt"
  },
  "isNewUser": true
}
```

### `POST /auth/login/email`

이메일 로그인

### `POST /auth/signup/email`

이메일 회원가입

### `POST /auth/refresh`

리프레시 토큰 재발급

### `POST /auth/logout`

로그아웃 처리

### `POST /auth/link-identity`

기존 계정에 Apple/Google/Kakao 추가 연결

### `DELETE /auth/unlink-identity/{provider}`

로그인 연동 해제

---

## 3. 사용자

### `GET /users/me`

내 정보 조회

### `PATCH /users/me`

내 프로필 수정

### `GET /users/me/preferences`

취향 정보 조회

### `PUT /users/me/preferences`

취향 정보 수정

### `GET /users/me/bookmarks`

저장한 카페 목록 조회

### `GET /users/me/visit-logs`

내 커피 기록 조회

### `POST /users/me/visit-logs`

내 커피 기록 등록

### `DELETE /users/me`

회원 탈퇴

---

## 4. 카페

### `GET /cafes`

카페 목록 조회

Query 예시:

- `lat`
- `lng`
- `radius`
- `region`
- `keyword`
- `filters`
- `sort`

Response

```json
{
  "items": [
    {
      "id": "uuid",
      "name": "브루스팟 성수",
      "address": "서울 성동구 ...",
      "latitude": 37.0,
      "longitude": 127.0,
      "avgRating": 4.5,
      "reviewCount": 128,
      "tags": ["스페셜티", "작업하기좋은곳"]
    }
  ],
  "page": 1,
  "size": 20,
  "total": 312
}
```

### `GET /cafes/{cafeId}`

카페 상세 조회

### `GET /cafes/{cafeId}/menus`

카페 메뉴 조회

### `POST /cafes/{cafeId}/bookmark`

카페 저장

### `DELETE /cafes/{cafeId}/bookmark`

카페 저장 취소

---

## 5. 리뷰

### `GET /cafes/{cafeId}/reviews`

카페 리뷰 목록 조회

### `POST /cafes/{cafeId}/reviews`

리뷰 작성

Request

```json
{
  "overallRating": 5,
  "tasteRating": 5,
  "moodRating": 4,
  "priceRating": 4,
  "workFriendlyRating": 5,
  "visitPurpose": "work",
  "content": "조용하고 라떼 맛이 좋았어요.",
  "imageUrls": [
    "https://cdn.example.com/review/1.jpg"
  ]
}
```

### `PATCH /reviews/{reviewId}`

리뷰 수정

### `DELETE /reviews/{reviewId}`

리뷰 삭제

### `POST /reviews/{reviewId}/report`

리뷰 신고

---

## 6. 추천 및 랭킹

### `GET /recommendations/nearby`

근처 카페 추천

### `GET /recommendations/trending`

요즘 뜨는 카페

### `GET /rankings`

랭킹 조회

Query 예시:

- `type=regional`
- `type=trending`
- `type=signature-latte`
- `region=seoul-seongsu`

---

## 7. 커뮤니티

### `GET /community/posts`

게시글 목록 조회

### `POST /community/posts`

게시글 작성

### `GET /community/posts/{postId}`

게시글 상세 조회

### `PATCH /community/posts/{postId}`

게시글 수정

### `DELETE /community/posts/{postId}`

게시글 삭제

### `POST /community/posts/{postId}/comments`

댓글 작성

### `POST /community/posts/{postId}/report`

게시글 신고

---

## 8. 홈바리스타

### `GET /homebarista/posts`

홈바리스타 피드 조회

### `POST /homebarista/posts`

홈바리스타 게시글 작성

### `GET /homebarista/posts/{postId}`

홈바리스타 게시글 상세

### `POST /homebarista/posts/{postId}/report`

신고

---

## 9. 파일 업로드

### `POST /files/presign`

리뷰 이미지/프로필 이미지 업로드용 presigned URL 발급

Request

```json
{
  "type": "review-image",
  "fileName": "latte.jpg",
  "contentType": "image/jpeg"
}
```

Response

```json
{
  "uploadUrl": "https://storage.example.com/...",
  "fileUrl": "https://cdn.example.com/..."
}
```

---

## 10. 관리자 API

### `GET /admin/reports`

신고 목록 조회

### `PATCH /admin/reports/{reportId}`

신고 처리 상태 변경

### `POST /admin/cafes`

카페 등록

### `PATCH /admin/cafes/{cafeId}`

카페 수정

### `DELETE /admin/cafes/{cafeId}`

카페 비활성화

### `GET /admin/users`

사용자 목록 조회

### `PATCH /admin/users/{userId}/status`

사용자 제재

---

## 11. 에러 응답 형식

```json
{
  "code": "INVALID_TOKEN",
  "message": "유효하지 않은 로그인 토큰입니다.",
  "traceId": "req-1234"
}
```

---

## 12. 보안 체크

1. 모든 소셜 토큰은 서버 검증
2. presigned URL 업로드는 파일 타입 검증 필요
3. 관리자 API는 별도 role 체크
4. 리뷰/게시글 작성 API에 rate limit 필요
5. 탈퇴 API는 재인증 요구 권장
