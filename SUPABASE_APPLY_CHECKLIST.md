# BrewSpot Supabase 적용 체크리스트

최종 기준일: 2026-05-25

## 목적

이 문서는 Supabase 콘솔에서 BrewSpot MVP 데이터를 실제 반영할 때 바로 따라갈 수 있는 실행 순서를 정리한다.
현재 기준으로 핵심 카페 데이터 외에 `community_posts`, `homebarista_posts` 확장 테이블도 함께 확인한다.

## 준비 파일

1. `SUPABASE_MINI_SCHEMA.sql`
2. `SUPABASE_CAFE_SEED.sql`
3. `SUPABASE_REVIEW_SEED.sql`
4. `SUPABASE_COMMUNITY_SEED.sql`
5. `SUPABASE_HOMEBARISTA_SEED.sql`
6. `SUPABASE_VERIFY.sql`
7. `SUPABASE_RLS_SMOKE_TEST.sql`
8. `TEST_ACCOUNTS_TEMPLATE.csv`
9. `SUPABASE_RESET_CONTENT.sql`
10. `SUPABASE_AUTH_TRIGGER_FIX.sql`
11. `SUPABASE_AUTH_BACKFILL.sql`
12. `TEST_ACCOUNT_SETUP_CHECKLIST.md`

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
2. 이 파일은 테이블/정책/트리거만 만들고 카페 데이터는 넣지 않음

정상 기준:

1. `users`
2. `user_identities`
3. `cafes`
4. `reviews`
5. `bookmarks`
6. `community_posts`
7. `homebarista_posts`

위 7개 테이블이 존재해야 한다.

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

1. 테이블 7개가 조회되는지
2. `cafes`, `reviews`, `bookmarks`, `community_posts`, `homebarista_posts` 컬럼이 기대값과 맞는지
3. RLS 정책이 생성됐는지

## 6. 카페 시드 반영

위치:
`SQL Editor`

할 일:

1. `SUPABASE_CAFE_SEED.sql` 실행
2. 카페 데이터는 반드시 이 파일로만 넣기

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
3. `auth.users`에만 있고 `public.users`에 없는 테스트 계정이 없거나, 있으면 `SUPABASE_AUTH_BACKFILL.sql` 실행 후 다시 확인

관련 체크:

1. `TEST_ACCOUNT_SETUP_CHECKLIST.md`

## 8. 리뷰 시드 반영

위치:
`SQL Editor`

할 일:

1. `SUPABASE_REVIEW_SEED.sql` 실행

정상 기준:

1. 총 리뷰 수가 `36`
2. 리뷰 분배가 `3개 6곳 / 2개 6곳 / 1개 6곳 / 0개 6곳`
3. 실행 전 `public.users` 테스트 계정 수가 `15`가 아니면 `SUPABASE_AUTH_BACKFILL.sql`부터 실행

## 8-1. 커뮤니티 테스트 글 반영

위치:
`SQL Editor`

할 일:

1. `SUPABASE_COMMUNITY_SEED.sql` 실행

정상 기준:

1. `community_post_count >= 3`
2. `board_type`, `title`, `city`, `author_nickname` 값이 조회됨
3. 앱/웹 커뮤니티 탭에서 샘플 fallback이 아닌 실데이터 확인이 가능해짐

## 8-2. 홈바리스타 테스트 글 반영

위치:
`SQL Editor`

할 일:

1. `SUPABASE_HOMEBARISTA_SEED.sql` 실행

정상 기준:

1. `homebarista_post_count >= 3`
2. `brew_method`, `title`, `bean_name`, `author_nickname` 값이 조회됨
3. 앱/웹 홈바리스타 탭에서 샘플 fallback이 아닌 실데이터 확인이 가능해짐

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
6. `auth.users`에만 있고 `public.users`에 없는 테스트 계정이 남아 있지 않은지
7. `community_posts` 테이블이 조회되고 글 생성용 컬럼과 정책이 존재하는지
8. `homebarista_posts` 테이블이 조회되고 레시피 생성용 컬럼과 정책이 존재하는지

추가 메모:

1. 현재 확장 기능은 앱/웹에서 fallback 데이터로도 동작하므로, 실운영 반영의 1차 완료 기준은 `테이블/정책 생성 확인`이다.
2. 별도 시드 SQL이 아직 없으면 `community_posts`, `homebarista_posts`는 0건이어도 괜찮다.
3. 이후 실제 운영 전에 샘플 글을 넣고 싶다면 Dashboard 또는 SQL Editor에서 수동 1~3건 테스트 입력 후 앱/웹 반영을 확인한다.

## 9-1. RLS 스모크 테스트

위치:
`SQL Editor`

할 일:

1. `SUPABASE_RLS_SMOKE_TEST.sql` 실행
2. 결과 표에서 `passed = true`인지 확인
3. NOTICE 로그에 `PASS:` 문구만 보이는지 확인
4. 마지막 `rollback`으로 테스트 데이터가 남지 않는지 확인

정상 기준:

1. anon은 `cafes`, `reviews`, `community_posts`, `homebarista_posts`를 읽을 수 있음
2. anon은 `bookmarks`를 읽지 못하고 커뮤니티 글을 쓰지 못함
3. authenticated는 본인 `reviews`, `bookmarks`, `community_posts`, `homebarista_posts` 쓰기가 가능함
4. authenticated는 다른 사용자 `community_posts`, `homebarista_posts`에 쓰기/수정하지 못함

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
4. 커뮤니티 탭이 fallback이 아니라 Supabase 데이터 기준으로도 열릴 준비가 되어 있음
5. 홈바리스타 탭이 fallback이 아니라 Supabase 데이터 기준으로도 열릴 준비가 되어 있음

## 11. 실패 시 우선 점검

1. `cafe_count`가 24가 아니면 기존 더미 카페가 섞였는지 확인
2. `review_count`가 36이 아니면 테스트 계정 누락 여부 확인
3. `auth.users`에는 있는데 `public.users`에는 없다면 `SUPABASE_AUTH_BACKFILL.sql` 실행
4. legacy review가 남아 있으면 기존 `reviews` 데이터 정리 필요
5. Google / Apple 로그인 실패 시 Provider 활성화 여부 확인
6. 이메일 회원가입에서 DB 오류가 나면 `SUPABASE_AUTH_TRIGGER_FIX.sql` 먼저 적용
7. 커뮤니티/홈바리스타 탭이 계속 샘플 모드라면 `community_posts`, `homebarista_posts` 테이블과 RLS 정책부터 다시 확인
