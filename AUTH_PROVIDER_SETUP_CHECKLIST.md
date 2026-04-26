# BrewSpot Email Auth 설정 체크리스트

최종 기준일: 2026-04-26

## 목적

이 문서는 BrewSpot iOS 앱을 이메일 로그인 전용으로 운영할 때, Supabase 콘솔과 앱 코드에서 확인해야 할 항목을 정리한다.

## 현재 앱 고정값

코드 기준:

1. Supabase URL: `https://ahlstavrnnwydzxwwnbq.supabase.co`
2. Supabase Project Ref: `ahlstavrnnwydzxwwnbq`
3. iOS Bundle ID: `com.hwangjohn.brewspot`

관련 파일:

1. `ios/BrewSpotApp/Config/AppConfig.swift`
2. `ios/project.yml`

## 1. Email Provider

위치:
Supabase `Authentication > Providers > Email`

할 일:

1. Email Provider 활성화 확인
2. 회원가입 허용 여부 확인
3. 테스트 단계에서는 메일 인증 절차를 어떻게 처리할지 결정

현재 확인 메모:

1. `email=true`
2. `disable_signup=false`
3. `mailer_autoconfirm=false`
4. 2026-04-26 `GET /auth/v1/settings` 응답으로 재확인

의미:

1. 이메일 회원가입은 열려 있음
2. 메일 자동 인증은 꺼져 있을 가능성이 높음
3. 테스트 계정은 가입 후 인증 완료 상태를 맞추는 것이 안전함

현재 추가 확인:

1. 공개 Auth API 회원가입 테스트에서 `Database error saving new user` 응답 확인
2. 따라서 Provider 설정 전 `SUPABASE_AUTH_TRIGGER_FIX.sql` 적용 여부도 같이 봐야 함
3. 2026-04-26 회원가입 API 재확인 시 `429 over_email_send_rate_limit` 응답이 확인됨
4. 테스트 중 반복 회원가입 시 인증 메일 발송 제한에 걸릴 수 있으므로 기존 테스트 계정 로그인이나 Dashboard 수동 계정 생성도 같이 준비하는 것이 안전함

## 2. 현재 버전에서 제외한 Provider

현재 MVP에서는 아래 Provider를 앱에서 노출하지 않는다.

1. Enabled
2. Google
3. Apple

권장 상태:

1. Supabase Console에서 Google / Apple Provider를 비활성화 상태로 유지
2. 앱 로그인 화면에서 Email 외 버튼이 노출되지 않음
3. App Review 메모와 제출 문서도 Email 기준으로만 작성

## 3. 공통 점검

1. 로그인 화면에 이메일 입력, 비밀번호 입력, 로그인 버튼, 회원가입 진입만 보이는지
2. 로그인 직후 `public.users`가 기대대로 채워지는지
3. 실패 시 사용자에게 에러 문구가 표시되는지
4. 이메일 인증이 필요한 경우 안내 문구가 표시되는지

## 4. 실패 시 먼저 볼 것

1. Email Provider가 실제로 Enabled인지
2. 회원가입 허용이 켜져 있는지
3. `SUPABASE_AUTH_TRIGGER_FIX.sql`이 반영되어 있는지
4. Supabase 프로젝트가 앱이 바라보는 프로젝트와 같은지
5. 이메일 인증 정책이 현재 QA 방식과 맞는지
6. `over_email_send_rate_limit`로 인증 메일 발송 제한에 걸린 상태가 아닌지

## 5. 실제 확인 순서

1. Email Provider 상태 확인
2. Xcode 시뮬레이터에서 이메일 로그인 확인
3. 이메일 회원가입 확인
4. `SUPABASE_VERIFY.sql`과 `public.users`로 로그인 결과 확인
