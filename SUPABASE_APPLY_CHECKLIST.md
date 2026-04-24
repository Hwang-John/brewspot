# BrewSpot Supabase 적용 체크리스트

최종 기준일: 2026-04-24

## 목적

이 문서는 Supabase 콘솔에서 BrewSpot MVP 데이터를 실제 반영할 때 바로 따라갈 수 있는 실행 순서를 정리한다.

## 준비 파일

1. `SUPABASE_MINI_SCHEMA.sql`
2. `SUPABASE_CAFE_SEED.sql`
3. `SUPABASE_REVIEW_SEED.sql`
4. `SUPABASE_VERIFY.sql`
5. `TEST_ACCOUNTS_TEMPLATE.csv`
6. `SUPABASE_RESET_CONTENT.sql`
7. `SUPABASE_AUTH_TRIGGER_FIX.sql`

## 1. 프로젝트와 Auth 상태 확인

위치:
Supabase Dashboard

할 일:

1. 대상 프로젝트가 `brewspot` 운영용 프로젝트인지 확인
2. `Authentication > Providers` 이동
3. 현재 상태 확인
4. `Email` 활성화 여부 확인
5. `Google`, `Apple` 활성화 여부 확인

정상 기준:

1. Email은 사용 가능
2. Google / Apple은 이번 테스트 범위에 맞게 켜거나, 아직 꺼져 있으면 TODO에 그대로 유지

## 2. 최신 스키마 적용

위치:
`SQL Editor`

할 일:

1. `SUPABASE_MINI_SCHEMA.sql` 전체 실행

정상 기준:

1. `users`
2. `user_identities`
3. `cafes`
4. `reviews`
5. `bookmarks`

위 5개 테이블이 존재해야 한다.

## 3. 기존 데이터 초기화 여부 판단

위치:
`SQL Editor`

할 일:

1. 현재 프로젝트가 비어 있는지 먼저 확인
2. 기존 더미 카페나 legacy 리뷰가 섞여 있으면 `SUPABASE_RESET_CONTENT.sql` 실행

리셋이 필요한 경우:

1. 카페 수가 24가 아닌데 기존 샘플 데이터가 섞여 있음
2. 리뷰 수가 36과 크게 다름
3. legacy review가 많이 남아 있음

주의:

1. 이 SQL은 `bookmarks`, `reviews`, `cafes`를 비운다
2. `auth.users`는 지우지 않는다

## 4. Auth 트리거 오류 여부 확인

위치:
`Authentication > Users` 또는 앱 회원가입 테스트

할 일:

1. 이메일 회원가입을 한 번 시도
2. `Database error saving new user`가 나오면 `SUPABASE_AUTH_TRIGGER_FIX.sql` 실행

현재 확인 메모:

1. 공개 Auth API 기준 회원가입 시 `Database error saving new user` 응답 확인
2. 원인은 현재 `handle_new_auth_user()` 트리거의 identity 처리 로직일 가능성이 높음

## 5. 스키마 1차 검증

위치:
`SQL Editor`

할 일:

1. `SUPABASE_VERIFY.sql` 실행

우선 확인할 결과:

1. 테이블 5개가 조회되는지
2. `cafes`, `reviews`, `bookmarks` 컬럼이 기대값과 맞는지
3. RLS 정책이 생성됐는지

## 6. 카페 시드 반영

위치:
`SQL Editor`

할 일:

1. `SUPABASE_CAFE_SEED.sql` 실행

정상 기준:

1. 총 카페 수가 `24`
2. 도시별로 `성수 8`, `연남 8`, `망원 8`

## 7. 테스트 계정 생성

위치:
`Authentication > Users`

할 일:

1. `TEST_ACCOUNTS_TEMPLATE.csv` 기준으로 15개 계정 생성
2. 이메일 / 비밀번호는 템플릿 기준 사용
3. 필요하면 이메일 확인 완료 상태로 맞춤

정상 기준:

1. `public.users`에서 테스트 계정 이메일 15개가 조회됨
2. 닉네임이 템플릿과 크게 어긋나지 않음

## 8. 리뷰 시드 반영

위치:
`SQL Editor`

할 일:

1. `SUPABASE_REVIEW_SEED.sql` 실행

정상 기준:

1. 총 리뷰 수가 `36`
2. 리뷰 분배가 `3개 6곳 / 2개 6곳 / 1개 6곳 / 0개 6곳`

## 9. 최종 검증

위치:
`SQL Editor`

할 일:

1. `SUPABASE_VERIFY.sql` 다시 실행

반드시 볼 항목:

1. `cafe_count = 24`
2. `review_count = 36`
3. 도시별 카페 수가 `8 / 8 / 8`
4. `author_nickname is null` 또는 `recommended_menu_name is null`인 legacy review가 남아 있는지
5. 테스트 계정 15개가 모두 조회되는지

## 10. 앱 확인

위치:
Xcode 시뮬레이터

할 일:

1. 이메일 로그인
2. 홈 진입
3. 카페 목록 조회
4. 카페 상세 진입
5. 리뷰 목록 확인
6. 북마크 저장 / 해제
7. 마이페이지 최근 활동 확인

정상 기준:

1. 카페가 샘플 데이터가 아니라 Supabase 데이터로 보임
2. 리뷰 수와 평점이 상세 화면에 반영됨
3. 북마크가 마이페이지 저장 목록에 반영됨

## 11. 실패 시 우선 점검

1. `cafe_count`가 24가 아니면 기존 더미 카페가 섞였는지 확인
2. `review_count`가 36이 아니면 테스트 계정 누락 여부 확인
3. legacy review가 남아 있으면 기존 `reviews` 데이터 정리 필요
4. Google / Apple 로그인 실패 시 Provider 활성화 여부 확인
5. 이메일 회원가입에서 DB 오류가 나면 `SUPABASE_AUTH_TRIGGER_FIX.sql` 먼저 적용
