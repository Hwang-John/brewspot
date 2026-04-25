# BrewSpot 실행 순서

최종 기준일: 2026-04-25

## 1. 1순위: Supabase 실반영

사용자 작업:
1. Supabase Dashboard 접속
2. `SUPABASE_MINI_SCHEMA.sql` 실행
3. 필요 시 `SUPABASE_RESET_CONTENT.sql` 실행
4. `SUPABASE_AUTH_TRIGGER_FIX.sql` 실행 여부 확인
5. `SUPABASE_CAFE_SEED.sql` 실행
6. 테스트 계정 15개 생성
7. `SUPABASE_REVIEW_SEED.sql` 실행
8. `SUPABASE_VERIFY.sql` 실행

Codex 작업:
1. 실행 순서 문서 정리
2. 스키마/시드/검증 SQL 준비 유지
3. TODO 상태 반영
4. 시뮬레이터 QA 전 로컬 빌드 준비

정상 기준:
1. `cafe_count = 24`
2. `review_count = 36`
3. 테스트 계정 15개 조회
4. legacy review 정리 확인

관련 문서:
1. `SUPABASE_APPLY_CHECKLIST.md`
2. `TEST_ACCOUNT_SETUP_CHECKLIST.md`

## 2. 2순위: Provider 활성화

사용자 작업:
1. Supabase `Authentication > Providers > Google` 활성화
2. Supabase `Authentication > Providers > Apple` 활성화
3. Google Cloud Console / Apple Developer 설정값 입력
4. Redirect URL / Bundle ID / URL Scheme 일치 확인

Codex 작업:
1. 앱 고정값 문서 유지
2. 실패 시 점검 포인트 정리
3. 시뮬레이터에서 버튼 동작 확인 준비

정상 기준:
1. `google=true`
2. `apple=true`
3. OAuth 완료 후 앱 복귀 가능

관련 문서:
1. `AUTH_PROVIDER_SETUP_CHECKLIST.md`

## 3. 3순위: 시뮬레이터 QA

사용자 작업:
1. 준비된 테스트 계정으로 로그인
2. Google / Apple 실제 인증 진행
3. 필요 시 Supabase 콘솔에서 결과 확인

Codex 작업:
1. 앱 빌드
2. 시뮬레이터 실행
3. QA 체크리스트 기준으로 점검 순서 제공
4. 실패 로그와 원인 후보 정리

정상 기준:
1. 이메일 로그인 후 홈 진입
2. 카페 조회 / 상세 / 리뷰 / 북마크 동작
3. 마이페이지 / 최근 활동 반영
4. 실패 문구와 빈 상태 문구 확인

관련 문서:
1. `MANUAL_QA_CHECKLIST.md`

## 4. 지금 바로 할 일

1. 사용자: Supabase 실반영부터 시작
2. Codex: 시뮬레이터 빌드/실행 준비
3. 사용자: Provider 활성화
4. Codex: 이메일 / Google / Apple QA 순서로 검증 지원
