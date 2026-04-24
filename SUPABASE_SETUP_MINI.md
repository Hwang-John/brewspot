# BrewSpot Supabase 최소 구축 가이드

## 목적

이 문서는 BrewSpot 최소 MVP를 Supabase로 바로 시작하기 위한 가장 짧은 구축 가이드다.

---

## 1. 먼저 만들 것

- [ ] Supabase 프로젝트 생성
- [ ] `SUPABASE_MINI_SCHEMA.sql` 실행
- [ ] Auth 로그인 방식 정리
- [ ] 카페 더미 데이터 입력
- [ ] Storage 필요 여부 결정

---

## 2. 프로젝트 생성

1. Supabase 로그인
2. `New project`
3. 프로젝트 이름: `brewspot`
4. Database password 설정
5. Region 선택
6. 생성 완료까지 대기

---

## 3. SQL 실행

1. Supabase 왼쪽 메뉴 `SQL Editor`
2. `New query`
3. `SUPABASE_MINI_SCHEMA.sql` 전체 붙여넣기
4. `Run`

실행 후 확인:

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;
```

정상이라면 최소 아래 테이블이 보여야 함:

1. `users`
2. `user_identities`
3. `cafes`
4. `reviews`
5. `bookmarks`

---

## 4. Auth 설정

### 1차 추천

- [ ] Email
- [ ] Google
- [ ] Apple

### 2차 추천

- [ ] Kakao
- [ ] Naver 보류

설명:

- Gmail 로그인은 실제로는 Google 로그인으로 처리하면 된다.
- iOS 앱에서 Google 같은 서드파티 로그인을 제공하면 App Store 제출 전 Apple 로그인도 함께 준비하는 편이 안전하다.
- Kakao는 2차 확장으로 두고, Naver는 Custom OAuth/OIDC 설정 부담 때문에 이번 버전에서는 보류한다.

> [AI 추가 제안]
> 기획상 `메일 + Kakao + Gmail + Naver`를 유지하더라도, 실제 첫 구현은 `이메일 + Google`부터 시작하는 것이 훨씬 쉽다. Kakao/Naver는 한국 사용자 친화적이지만 초기 연동 난이도는 더 높다.

---

## 5. 카페 더미 데이터 넣기

초기에는 수동 입력 또는 CSV 업로드가 가장 현실적이다.

권장 방식:

1. `CAFE_SEED_TEMPLATE.csv` 작성
2. Supabase `Table Editor` 또는 SQL로 입력

예시 SQL:

```sql
insert into cafes (
  name,
  address,
  latitude,
  longitude,
  signature_menu_name,
  signature_menu_price
) values
  ('카페 A', '서울 성동구 ...', 37.0, 127.0, '플랫화이트', 5500),
  ('카페 B', '서울 마포구 ...', 37.1, 126.9, '바닐라라떼', 6000);
```

---

## 6. 지금 당장 해야 할 최소 순서

1. Supabase 프로젝트 생성
2. `SUPABASE_MINI_SCHEMA.sql` 실행
3. `cafes` 테이블에 카페 10개 입력
4. Email 로그인 켜기
5. Google 로그인 가능 여부 검토

---

## 7. 다음 단계

- [ ] 카페 30개 채우기
- [ ] 리뷰 더미 데이터 10개 만들기
- [ ] 로그인 화면 구현
- [ ] 지도 화면 구현
- [ ] 카페 상세 화면 구현
