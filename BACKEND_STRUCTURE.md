# BrewSpot 백엔드 구조 기준안

최종 기준일: 2026-04-24

## 1. 목적

이 문서는 BrewSpot의 현재 MVP 백엔드 운영 방식과, 이후 커스텀 백엔드로 확장할 때의 구조를 구분해서 설명한다.

## 2. 현재 MVP 구조

현재 버전은 `커스텀 API 서버`보다 `Supabase 중심 구조`를 기준으로 한다.

현재 사용 기준:

1. `iOS App`
2. `Supabase Auth`
3. `Supabase Postgres`
4. `Supabase RLS 정책`
5. 필요 시 향후 `Storage`

즉, 현재는 별도 `backend/` 서버를 먼저 만드는 단계가 아니라 `Supabase 스키마 + iOS 서비스 레이어`로 빠르게 운영 검증하는 단계다.

## 3. 현재 책임 분리

### iOS 앱

1. 로그인 시작
2. 카페 목록 / 상세 조회
3. 리뷰 작성
4. 북마크 저장
5. 마이페이지 표시

### Supabase

1. 인증 처리
2. 사용자 프로필 생성 / 보장
3. 카페 / 리뷰 / 북마크 데이터 저장
4. RLS 정책 적용
5. 리뷰 집계 트리거 실행

## 4. 현재 코드 기준 서비스 영역

현재 iOS 코드에서 실제로 분리된 서비스는 아래와 같다.

1. `AuthService`
2. `CafeService`
3. `ReviewService`
4. `BookmarkService`
5. `UserProfileService`

즉, 현재 MVP 기준 기능 단위는 `auth / cafes / reviews / bookmarks / users` 정도로 보면 된다.

## 5. 지금 백엔드에서 실제 남은 일

1. Supabase 프로젝트에 최신 `SUPABASE_MINI_SCHEMA.sql` 적용
2. `SUPABASE_VERIFY.sql` 실행
3. 카페 24개 / 리뷰 36개 시드 실제 반영
4. Google / Apple Provider 설정 검증
5. RLS 정책이 앱 흐름과 충돌 없는지 확인

## 6. 2차 이후 커스텀 백엔드 확장안

트래픽이나 기능이 커지면 아래 구조로 확장할 수 있다.

```text
backend/
  src/
    modules/
      auth/
      users/
      cafes/
      reviews/
      bookmarks/
      recommendations/
      rankings/
      community/
      homebarista/
      reports/
      admin/
    jobs/
    integrations/
```

이 구조는 아래 기능이 실제로 필요해질 때 의미가 커진다.

1. 근처 추천 / 취향 추천
2. 랭킹 계산 배치
3. 커뮤니티 게시판
4. 홈바리스타 피드
5. 신고 처리와 운영 어드민
6. Kakao / Naver 추가 인증

## 7. 현재 결론

현재 단계에서 중요한 것은 `백엔드 폴더를 크게 설계하는 것`보다 아래 3가지다.

1. Supabase 실반영
2. 앱과 DB 흐름 검증
3. 운영 데이터와 정책 정합성 확인
