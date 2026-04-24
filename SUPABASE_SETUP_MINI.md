# BrewSpot Supabase 최소 구축 가이드

최종 기준일: 2026-04-24

## 목적

이 문서는 현재 BrewSpot MVP를 실제 Supabase 프로젝트에 반영할 때 필요한 가장 짧은 순서를 정리한다.

실제 콘솔 작업 순서를 한 번에 보려면 `SUPABASE_APPLY_CHECKLIST.md`를 함께 본다.
Auth Provider 설정만 먼저 보려면 `AUTH_PROVIDER_SETUP_CHECKLIST.md`를 함께 본다.

## 1. 현재 로컬에서 준비 완료된 것

1. `SUPABASE_MINI_SCHEMA.sql`
2. `SUPABASE_VERIFY.sql`
3. `SUPABASE_CAFE_SEED.sql`
4. `SUPABASE_REVIEW_SEED.sql`
5. `CAFE_SEED_TEMPLATE.csv`
6. `REVIEW_SEED_TEMPLATE.csv`
7. `TEST_ACCOUNTS_TEMPLATE.csv`
8. `SUPABASE_RESET_CONTENT.sql`
9. `SUPABASE_AUTH_TRIGGER_FIX.sql`

## 2. 지금 Supabase에서 해야 할 일

1. Supabase 프로젝트 생성 또는 기존 프로젝트 확인
2. `SUPABASE_MINI_SCHEMA.sql` 실행
3. 필요 시 `SUPABASE_RESET_CONTENT.sql` 실행
4. 필요 시 `SUPABASE_AUTH_TRIGGER_FIX.sql` 실행
5. `SUPABASE_VERIFY.sql` 실행
6. `SUPABASE_CAFE_SEED.sql`로 카페 24개 입력
7. `TEST_ACCOUNTS_TEMPLATE.csv` 기준 테스트 계정 15개 준비
8. 테스트 계정 준비 후 리뷰 36개 입력
9. Email / Google / Apple Auth Provider 설정 확인

## 3. Auth 기준

### 1차 지원

1. Email
2. Google
3. Apple

### 2차 이후

1. Kakao
2. Naver 보류

## 4. 카페 시드 기준

현재 기준:

1. 지역 3곳: 성수 / 연남 / 망원
2. 총 24개 카페
3. 카페 정보 필수 필드 전부 채움

적용 파일:

1. `CAFE_SEED_TEMPLATE.csv`
2. `SUPABASE_CAFE_SEED.sql`

## 5. 리뷰 시드 기준

현재 기준:

1. 총 36개 리뷰
2. 3개 리뷰 카페 6곳
3. 2개 리뷰 카페 6곳
4. 1개 리뷰 카페 6곳
5. 리뷰 0개 유지 카페 6곳

적용 파일:

1. `REVIEW_SEED_TEMPLATE.csv`
2. `SUPABASE_REVIEW_SEED.sql`
3. `SUPABASE_REVIEW_SEED_TEMPLATE.sql`
4. `TEST_ACCOUNTS_TEMPLATE.csv`
5. `SUPABASE_RESET_CONTENT.sql`
6. `SUPABASE_AUTH_TRIGGER_FIX.sql`

## 6. 실제 적용 순서

1. Supabase `SQL Editor`에서 `SUPABASE_MINI_SCHEMA.sql` 실행
2. 기존 더미/legacy 데이터가 있으면 `SUPABASE_RESET_CONTENT.sql` 실행
3. 이메일 회원가입에서 `Database error saving new user`가 보이면 `SUPABASE_AUTH_TRIGGER_FIX.sql` 실행
4. `SUPABASE_VERIFY.sql` 실행해서 테이블 / 컬럼 / 정책 확인
5. `SUPABASE_CAFE_SEED.sql` 실행
6. `TEST_ACCOUNTS_TEMPLATE.csv` 기준 테스트 계정 준비
7. `SUPABASE_REVIEW_SEED.sql` 또는 `REVIEW_SEED_TEMPLATE.csv`로 리뷰 입력
8. `SUPABASE_VERIFY.sql`로 카페 24개 / 리뷰 36개 / legacy review 여부 확인
9. iOS 앱에서 카페 조회 / 리뷰 / 북마크 흐름 확인

## 7. 지금 남은 검증 항목

1. RLS 정책이 앱 요청과 충돌 없는지 확인
2. Google Provider 콘솔 설정 확인
3. Apple Provider 콘솔 설정 확인
4. 시드 입력 후 지도와 상세 화면 데이터가 기대대로 보이는지 확인
