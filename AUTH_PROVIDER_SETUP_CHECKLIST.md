# BrewSpot Auth Provider 설정 체크리스트

최종 기준일: 2026-04-24

## 목적

이 문서는 BrewSpot iOS 앱의 Email / Google / Apple 로그인 설정 시, 앱 코드와 Supabase 콘솔에서 맞춰야 하는 값을 한 번에 정리한다.

## 현재 앱 고정값

코드 기준:

1. Supabase URL: `https://ahlstavrnnwydzxwwnbq.supabase.co`
2. Supabase Project Ref: `ahlstavrnnwydzxwwnbq`
3. iOS Bundle ID: `com.hwangjohn.brewspot`
4. URL Scheme: `com.hwangjohn.brewspot`
5. Redirect URL: `com.hwangjohn.brewspot://login-callback`

관련 파일:

1. `ios/BrewSpotApp/Config/AppConfig.swift`
2. `ios/BrewSpotApp/Info.plist`
3. `ios/project.yml`

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

의미:

1. 이메일 회원가입은 열려 있음
2. 메일 자동 인증은 꺼져 있을 가능성이 높음
3. 테스트 계정은 가입 후 인증 완료 상태를 맞추는 것이 안전함

현재 추가 확인:

1. 공개 Auth API 회원가입 테스트에서 `Database error saving new user` 응답 확인
2. 따라서 Provider 설정 전 `SUPABASE_AUTH_TRIGGER_FIX.sql` 적용 여부도 같이 봐야 함

## 2. Google Provider

위치:
Supabase `Authentication > Providers > Google`

필수 확인값:

1. Enabled
2. Client ID
3. Client Secret
4. Redirect URL

앱 기준 체크:

1. 앱은 Google OAuth 버튼을 이미 호출함
2. Redirect URL은 `com.hwangjohn.brewspot://login-callback`
3. URL Scheme은 `com.hwangjohn.brewspot`

현재 확인 메모:

1. `google=false` 상태로 확인됨
2. 즉, 앱 코드가 있어도 지금은 실제 로그인 성공 불가

정상 기준:

1. Supabase Google Provider 활성화
2. Google Cloud Console에 Supabase / 앱 redirect 설정 반영
3. 앱에서 Google 로그인 후 BrewSpot으로 복귀

## 3. Apple Provider

위치:
Supabase `Authentication > Providers > Apple`

필수 확인값:

1. Enabled
2. Services ID
3. Team ID
4. Key ID
5. Private Key
6. Redirect URL

앱 기준 체크:

1. Bundle ID는 `com.hwangjohn.brewspot`
2. Redirect URL은 `com.hwangjohn.brewspot://login-callback`
3. URL Scheme은 `com.hwangjohn.brewspot`

현재 확인 메모:

1. `apple=false` 상태로 확인됨
2. 즉, 앱 코드가 있어도 지금은 실제 로그인 성공 불가

정상 기준:

1. Supabase Apple Provider 활성화
2. Apple Developer 설정과 Supabase 값 일치
3. 앱에서 Apple 로그인 후 BrewSpot으로 복귀

## 4. 공통 점검

1. 앱에서 로그인 버튼 탭 시 웹 인증 또는 시스템 인증이 시작되는지
2. 인증 후 BrewSpot 앱으로 다시 돌아오는지
3. 로그인 직후 `public.users`와 `public.user_identities`가 기대대로 채워지는지
4. 실패 시 사용자에게 에러 문구가 표시되는지

## 5. 실패 시 먼저 볼 것

1. Provider가 실제로 Enabled인지
2. Redirect URL이 `com.hwangjohn.brewspot://login-callback`와 정확히 같은지
3. iOS URL Scheme가 `com.hwangjohn.brewspot`인지
4. Bundle ID가 `com.hwangjohn.brewspot`인지
5. Supabase 프로젝트가 앱이 바라보는 프로젝트와 같은지

## 6. 실제 확인 순서

1. Email Provider 상태 확인
2. Google Provider 활성화
3. Apple Provider 활성화
4. Xcode 시뮬레이터에서 Google 로그인 확인
5. Xcode 시뮬레이터에서 Apple 로그인 확인
6. `SUPABASE_VERIFY.sql`과 `public.user_identities`로 로그인 결과 확인
