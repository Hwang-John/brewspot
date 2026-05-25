# BrewSpot 실행 순서

최종 기준일: 2026-05-25

현재 앱 범위:
1. 로그인 수단은 이메일만 사용한다.
2. 현재 위치는 `내 위치 중심 이동`, `거리 표시`, `가장 가까운 카페 안내`까지만 포함한다.
3. 사진 업로드, 소셜 로그인, 결제는 이번 MVP 범위에 없다.
4. 커뮤니티 / 랭킹 / 홈바리스타 1차 MVP 화면은 로컬 코드에 반영되어 있다.
5. QA와 문서 기준도 위 범위에 맞춰 해석한다.

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
11. `community_posts`, `homebarista_posts` 테이블과 정책 존재 여부 확인
12. `SUPABASE_RLS_SMOKE_TEST.sql` 실행으로 공개 읽기 / 본인 쓰기 / 타인 수정 차단 확인
13. 필요 시 테스트용 글 1~3건 수동 입력 후 앱/웹 반영 확인

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
6. `community_posts`, `homebarista_posts` 테이블 존재 확인
7. `SUPABASE_RLS_SMOKE_TEST.sql` 결과가 모두 정상

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
3. 현재 위치 허용 시 `내 위치` 이동과 거리 표시 동작
4. 마이페이지 / 최근 기록 / 정책 링크 / 프로필 편집 반영
5. 커뮤니티 / 랭킹 / 홈바리스타 탭 노출과 기본 흐름 확인
6. 실패 카드와 빈 상태 문구 확인

관련 문서:
1. `MANUAL_QA_CHECKLIST.md`

## 4. 현재 우선순위

1. 사용자: Supabase에 확장 테이블 실반영 여부 확인
2. 사용자: 이메일 로그인 기준 핵심 플로우 QA
3. Codex: 빌드 / 시뮬레이터 / UI 개선 계속 지원
4. 사용자: 위치 권한 허용 / 거부 흐름 QA
5. 사용자: 문구와 디자인 피드백 정리
6. Codex: 현재 MVP 범위에 맞춰 문서와 화면을 같이 유지
