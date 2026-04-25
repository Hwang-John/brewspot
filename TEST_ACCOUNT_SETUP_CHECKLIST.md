# BrewSpot 테스트 계정 준비 체크리스트

최종 기준일: 2026-04-25

이 문서는 `TEST_ACCOUNTS_TEMPLATE.csv`에 정의된 15개 테스트 계정을 실제 Supabase 프로젝트에 생성하고, 앱 검증에 바로 쓸 수 있게 맞추기 위한 체크리스트다.

## 1. 준비 파일

1. `TEST_ACCOUNTS_TEMPLATE.csv`
2. `SUPABASE_APPLY_CHECKLIST.md`
3. `SUPABASE_VERIFY.sql`
4. `SUPABASE_AUTH_TRIGGER_FIX.sql`
5. `SUPABASE_AUTH_BACKFILL.sql`

## 2. 현재 기준 계정 정보

공통 비밀번호:
`BrewSpot123!`

대상 계정 수:
`15`

대표 계정 예시:
1. `test1@brewspot.app`
2. `test2@brewspot.app`
3. `test3@brewspot.app`

## 3. 생성 전 확인

위치:
Supabase `Authentication > Providers > Email`

할 일:

1. Email Provider 활성화 확인
2. 회원가입 허용 상태 확인
3. 이메일 자동 인증 여부 확인
4. 회원가입 시 `Database error saving new user`가 나는지 확인

정상 기준:

1. `email=true`
2. `disable_signup=false`
3. DB 오류가 있으면 계정 생성 전에 `SUPABASE_AUTH_TRIGGER_FIX.sql` 적용

## 4. 생성 방법 A: Dashboard에서 수동 생성

위치:
Supabase `Authentication > Users`

할 일:

1. `Add user`로 계정 생성
2. 이메일은 `TEST_ACCOUNTS_TEMPLATE.csv` 기준 사용
3. 비밀번호는 `BrewSpot123!` 사용
4. 가능하면 이메일 확인 완료 상태로 맞춤
5. 15개 모두 반복

장점:

1. 가장 안전함
2. 인증 상태를 눈으로 확인하기 쉬움

## 5. 생성 후 필수 확인

위치:
Supabase `Authentication > Users`

할 일:

1. 15개 계정이 모두 보이는지 확인
2. 이메일 오타가 없는지 확인
3. `Email confirmed` 상태를 테스트 전략에 맞게 확인

정상 기준:

1. `test1@brewspot.app`부터 `test18@brewspot.app` 중 템플릿에 있는 15개 계정이 존재
2. 로그인에 쓸 대표 계정 1개 이상이 실제 로그인 가능한 상태

## 6. public.users 동기화 확인

위치:
Supabase `SQL Editor`

할 일:

1. `SUPABASE_VERIFY.sql` 실행
2. 테스트 계정 존재 여부 쿼리 결과 확인

정상 기준:

1. `public.users`에서 테스트 계정 15개가 조회됨
2. 닉네임과 이메일이 크게 어긋나지 않음
3. `auth.users`에만 있고 `public.users`에 없는 테스트 계정이 없음

## 7. 앱 검증용 추천 계정

아래처럼 역할을 정해두면 QA가 쉬워진다.

1. `test1@brewspot.app`
   기본 로그인 / 홈 진입 확인
2. `test2@brewspot.app`
   리뷰 작성 / 마이페이지 반영 확인
3. `test3@brewspot.app`
   북마크 저장 / 해제 확인

## 8. 실패 시 먼저 볼 것

1. Email Provider가 실제로 켜져 있는지
2. `SUPABASE_AUTH_TRIGGER_FIX.sql`이 반영됐는지
3. `public.users` 트리거가 정상 작동하는지
4. 계정이 `auth.users`에만 있고 `public.users`에는 없는지
5. 위 상태면 `SUPABASE_AUTH_BACKFILL.sql` 실행
6. 이미 같은 이메일 계정이 존재하는지
7. 메일 인증이 꺼져 있지 않아 로그인만 막히는 상태인지

## 9. 완료 기준

- [ ] Authentication에 테스트 계정 15개 생성
- [ ] `public.users`에 15개 반영 확인
- [ ] `auth.users`와 `public.users` 간 누락 계정 없음 확인
- [ ] 대표 테스트 계정 1개 이상 실제 로그인 성공
- [ ] 리뷰 / 북마크 검증용 계정 역할 정리
