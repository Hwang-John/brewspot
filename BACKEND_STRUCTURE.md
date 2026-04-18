# BrewSpot 백엔드 폴더 구조 초안

## 1. 목적

이 문서는 비개발자도 백엔드가 어떤 구조로 만들어지는지 이해할 수 있도록  
권장 폴더 구조와 각 영역의 역할을 설명한다.

---

## 2. 권장 아키텍처

권장 방식:

1. `iOS App`
2. `Backend API`
3. `Admin Web`
4. `PostgreSQL`
5. `Storage`

백엔드는 `API 서버 하나`로 시작하고, 이후 규모가 커지면 추천/검색/알림을 분리하는 구조가 적합하다.

---

## 3. 폴더 구조 예시

```text
backend/
  src/
    main.ts
    app.module.ts

    common/
      config/
      constants/
      decorators/
      dto/
      exceptions/
      filters/
      guards/
      interceptors/
      logger/
      utils/

    modules/
      auth/
        auth.controller.ts
        auth.service.ts
        auth.repository.ts
        dto/
        providers/

      users/
        users.controller.ts
        users.service.ts
        users.repository.ts
        dto/

      cafes/
        cafes.controller.ts
        cafes.service.ts
        cafes.repository.ts
        dto/

      reviews/
        reviews.controller.ts
        reviews.service.ts
        reviews.repository.ts
        dto/

      bookmarks/
        bookmarks.controller.ts
        bookmarks.service.ts

      recommendations/
        recommendations.controller.ts
        recommendations.service.ts

      rankings/
        rankings.controller.ts
        rankings.service.ts

      community/
        posts.controller.ts
        comments.controller.ts
        community.service.ts

      homebarista/
        homebarista.controller.ts
        homebarista.service.ts

      visit-logs/
        visit-logs.controller.ts
        visit-logs.service.ts

      files/
        files.controller.ts
        files.service.ts

      reports/
        reports.controller.ts
        reports.service.ts

      admin/
        admin.controller.ts
        admin.service.ts

    database/
      migrations/
      seeds/
      schema/

    jobs/
      ranking.job.ts
      trending.job.ts
      cleanup.job.ts

    integrations/
      apple/
      google/
      kakao/
      maps/
      storage/
      push/

  test/
  docs/
  .env.example
  package.json
  README.md
```

---

## 4. 폴더별 역할 설명

### common

- 공통 모듈
- 에러 처리
- 인증 가드
- 설정 관리
- 로깅

### modules/auth

- 로그인/회원가입/토큰 재발급
- Apple/Google/Kakao 토큰 검증
- 계정 연결/해제

### modules/users

- 내 정보 조회/수정
- 프로필 관리
- 취향 태그 관리

### modules/cafes

- 카페 목록/상세
- 카페 검색
- 메뉴 정보

### modules/reviews

- 리뷰 작성/수정/삭제
- 평점 계산

### modules/recommendations

- 근처 추천
- 취향 기반 추천
- 요즘 뜨는 카페 계산

### modules/rankings

- 지역별/카테고리별 랭킹 제공

### modules/community

- 게시글/댓글
- 좋아요/신고

### modules/homebarista

- 홈바리스타 피드
- 레시피/장비 콘텐츠

### modules/admin

- 신고 처리
- 사용자 제재
- 카페 정보 관리

### database

- DB 마이그레이션
- 샘플 데이터
- 스키마 관리

### jobs

- 랭킹 계산
- 급상승 카페 계산
- 오래된 로그 정리

### integrations

- Apple 로그인
- Google 로그인
- Kakao 로그인
- 지도 API
- 이미지 저장소
- 푸시 알림

---

## 5. 비개발자용 이해 포인트

1. `modules`는 기능 단위 묶음이다.
2. 로그인, 카페, 리뷰, 커뮤니티를 각각 따로 관리한다고 보면 된다.
3. `integrations`는 외부 서비스 연결 영역이다.
4. `jobs`는 새벽 자동 작업 같은 배치 처리 영역이다.
5. 처음엔 하나의 API 서버로 시작하고, 나중에 커지면 분리하면 된다.

---

## 6. 바이브코딩 기준 추천

비개발자 기준이면 아래 순서가 가장 현실적이다.

1. Supabase 또는 Firebase 대체 BaaS로 인증/DB 먼저 구축
2. 백엔드는 필요한 부분만 Edge Functions 또는 간단한 API 서버로 시작
3. 복잡한 추천/랭킹은 2차에서 서버 고도화

> [AI 추가 제안]
> 완전 커스텀 백엔드를 처음부터 만드는 것보다 `Supabase Auth + Postgres + Storage + Server Functions` 조합이 비개발자 바이브코딩 환경에서는 훨씬 빠르다.
