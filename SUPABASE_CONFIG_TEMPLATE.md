# BrewSpot Supabase 연결 설정 초안

## 목적

이 문서는 BrewSpot 앱에서 Supabase를 연결할 때 필요한 최소 설정값을 정리한 문서다.

---

## 1. 현재 확보한 값

- `Project URL`: `https://ahlstavrnnwydzxwwnbq.supabase.co`
- `Publishable key`: `sb_publishable_UUFOiprjYpty5Jaa74xAzw_eRmZh5Tt`

주의:

- `service_role key`는 앱에 넣으면 안 된다.
- 앱/프론트엔드에는 `Publishable key`만 사용한다.

---

## 2. 앱에서 필요한 환경값

```env
SUPABASE_URL=https://ahlstavrnnwydzxwwnbq.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_UUFOiprjYpty5Jaa74xAzw_eRmZh5Tt
```

---

## 3. Swift 기준 예시 구조

```swift
struct AppConfig {
    static let supabaseURL = URL(string: "https://ahlstavrnnwydzxwwnbq.supabase.co")!
    static let supabaseKey = "sb_publishable_UUFOiprjYpty5Jaa74xAzw_eRmZh5Tt"
}
```

---

## 4. JavaScript/TypeScript 기준 예시 구조

```ts
export const appConfig = {
  supabaseUrl: "https://ahlstavrnnwydzxwwnbq.supabase.co",
  supabaseKey: "sb_publishable_UUFOiprjYpty5Jaa74xAzw_eRmZh5Tt",
};
```

---

## 5. Supabase 클라이언트 예시

```ts
import { createClient } from "@supabase/supabase-js";

export const supabase = createClient(
  "https://ahlstavrnnwydzxwwnbq.supabase.co",
  "sb_publishable_UUFOiprjYpty5Jaa74xAzw_eRmZh5Tt"
);
```

---

## 6. 지금 바로 확인할 것

- [ ] `SUPABASE_MINI_SCHEMA.sql` 실행 완료 여부
- [ ] `cafes` 테이블 생성 여부
- [ ] Email 로그인 활성화 여부
- [ ] Google 로그인 활성화 여부

---

## 7. 보안 메모

1. Publishable key는 앱에 들어가도 된다.
2. 민감한 서버 작업은 별도 서버 또는 Supabase 함수에서 처리한다.
3. RLS 정책 없이 바로 운영하면 위험하다.
4. MVP라도 최소한 테이블 접근 정책은 설계해야 한다.

> [AI 추가 제안]
> 지금 단계에서는 연결부터 하되, 실제 사용자 테스트 전에 반드시 RLS와 인증 정책을 정리해야 한다. 그렇지 않으면 누구나 데이터에 접근하거나 수정할 수 있는 상태가 될 수 있다.
