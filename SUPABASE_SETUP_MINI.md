# BrewSpot Supabase 최소 구축 가이드

최종 기준일: 2026-04-24

## 목적

이 문서는 현재 BrewSpot MVP를 실제 Supabase 프로젝트에 반영할 때 필요한 가장 짧은 순서를 정리한다.

## 1. 현재 로컬에서 준비 완료된 것

1. `SUPABASE_MINI_SCHEMA.sql`
2. `SUPABASE_VERIFY.sql`
3. `SUPABASE_CAFE_SEED.sql`
4. `SUPABASE_REVIEW_SEED.sql`
5. `CAFE_SEED_TEMPLATE.csv`
6. `REVIEW_SEED_TEMPLATE.csv`

## 2. 지금 Supabase에서 해야 할 일

1. Supabase 프로젝트 생성 또는 기존 프로젝트 확인
2. `SUPABASE_MINI_SCHEMA.sql` 실행
3. `SUPABASE_VERIFY.sql` 실행
4. `SUPABASE_CAFE_SEED.sql`로 카페 24개 입력
5. 테스트 계정 준비 후 리뷰 36개 입력
6. Email / Google / Apple Auth Provider 설정 확인

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

## 6. 실제 적용 순서

1. Supabase `SQL Editor`에서 `SUPABASE_MINI_SCHEMA.sql` 실행
2. `SUPABASE_VERIFY.sql` 실행해서 테이블 / 컬럼 / 정책 확인
3. `SUPABASE_CAFE_SEED.sql` 실행
4. 테스트 계정 준비
5. `SUPABASE_REVIEW_SEED.sql` 또는 `REVIEW_SEED_TEMPLATE.csv`로 리뷰 입력
6. iOS 앱에서 카페 조회 / 리뷰 / 북마크 흐름 확인

## 7. 지금 남은 검증 항목

1. RLS 정책이 앱 요청과 충돌 없는지 확인
2. Google Provider 콘솔 설정 확인
3. Apple Provider 콘솔 설정 확인
4. 시드 입력 후 지도와 상세 화면 데이터가 기대대로 보이는지 확인
