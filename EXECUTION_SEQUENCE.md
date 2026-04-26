# BrewSpot 실행 순서

최종 기준일: 2026-04-26

현재 앱 범위:
1. 로그인 수단은 이메일만 사용한다.
2. 현재 위치, 사진 업로드, 소셜 로그인, 결제는 이번 MVP 범위에 없다.
3. QA와 문서 기준도 위 범위에 맞춰 해석한다.

## 1. 1순위: Supabase 실반영

사용자 작업:
1. Supabase Dashboard 접속
2. `SUPABASE_MINI_SCHEMA.sql` 실행
3. 필요 시 `SUPABASE_RESET_CONTENT.sql` 실행
4. `SUPABASE_AUTH_TRIGGER_FIX.sql` 실행 여부 확인
5. `SUPABASE_CAFE_SEED.sql` 실행
6. 테스트 계정 15개 생성
7. `SUPABASE_VERIFY.sql`로 `public.users` 15개 / 누락 계정 여부 확인
8. 필요 시 `SUPABASE_AUTH_BACKFILL.sql` 실행
9. `SUPABASE_REVIEW_SEED.sql` 실행
10. `SUPABASE_VERIFY.sql` 실행

Codex 작업:
1. 실행 순서 문서 정리
2. 스키마/시드/검증 SQL 준비 유지
3. TODO 상태 반영
4. 시뮬레이터 QA 전 로컬 빌드 준비

정상 기준:
1. `cafe_count = 24`
2. `review_count = 36`
3. 테스트 계정 15개 조회
4. `auth.users`에만 있고 `public.users`에 없는 테스트 계정 없음
5. legacy review 정리 확인

관련 문서:
1. `SUPABASE_APPLY_CHECKLIST.md`
2. `TEST_ACCOUNT_SETUP_CHECKLIST.md`

## 2. 2순위: Email Auth 점검

사용자 작업:
1. Supabase `Authentication > Providers > Email` 상태 확인
2. 회원가입 허용 여부 확인
3. 필요 시 `SUPABASE_AUTH_TRIGGER_FIX.sql` 적용
4. 테스트 계정 로그인 가능 상태 확인

Codex 작업:
1. 앱 로그인 UI를 이메일 전용 기준으로 유지
2. 실패 시 점검 포인트 정리
3. 시뮬레이터에서 이메일 로그인 동작 확인 준비

정상 기준:
1. `email=true`
2. 이메일 로그인과 회원가입이 모두 동작
3. 사용자 프로필 생성 흐름이 깨지지 않음

관련 문서:
1. `AUTH_PROVIDER_SETUP_CHECKLIST.md`

## 3. 3순위: 시뮬레이터 QA

사용자 작업:
1. 준비된 테스트 계정으로 로그인
2. 신규 이메일 회원가입 진행
3. 필요 시 Supabase 콘솔에서 결과 확인

Codex 작업:
1. 앱 빌드
2. 시뮬레이터 실행
3. QA 체크리스트 기준으로 점검 순서 제공
4. 실패 로그와 원인 후보 정리

정상 기준:
1. 이메일 로그인 후 홈 진입
2. 홈 탐색 / 지도 / 카페 상세 / 리뷰 / 북마크 동작
3. 마이페이지 / 최근 기록 / 정책 링크 반영
4. 실패 카드와 빈 상태 문구 확인

관련 문서:
1. `MANUAL_QA_CHECKLIST.md`

## 4. 현재 우선순위

1. 사용자: 이메일 로그인 기준 핵심 플로우 QA
2. Codex: 빌드 / 시뮬레이터 / UI 개선 계속 지원
3. 사용자: 문구와 디자인 피드백 정리
4. Codex: 현재 MVP 범위에 맞춰 문서와 화면을 같이 유지
