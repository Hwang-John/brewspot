# BrewSpot TODO

이 파일 하나만 작업 기준으로 사용합니다.  
진행 상황은 "로컬 코드/문서에 반영된 것"과 "외부 환경에서 실제 확인이 필요한 것"을 구분해서 적습니다.

표시 규칙:
- `v` 로컬 작업 완료
- `[ ]` 아직 해야 할 일 / 외부 확인 필요

## 1. 지금까지 로컬에 반영 완료
- v SwiftUI iOS 앱 기본 골격 구성
- v `ios/project.yml` 기반 XcodeGen 프로젝트 구성
- v `ios/BrewSpot.xcodeproj` 생성
- v Supabase Swift 패키지 연결
- v Supabase URL / Publishable Key 연결
- v 이메일 로그인 / 회원가입 / 세션 확인 / 로그아웃 구현
- v 로그인 화면을 이메일 전용으로 정리
- v 로그인 후 홈 진입 흐름 구현
- v 지도 기반 카페 탐색 화면 구현
- v 카페 상세 화면 구현
- v 리뷰 작성 시트와 리뷰 목록 반영 구현
- v 카페 저장(북마크) 기능 구현
- v 홈 검색 / 카테고리 필터 구현
- v 마이페이지 탭 추가
- v 저장한 카페 / 취향 태그 / 활동 요약 UI 구현
- v 내 리뷰 목록을 마이페이지에 연결
- v 최근 활동 기록 섹션 추가
- v 비어 있는 상태 화면 문구/디자인 다듬기
- v 카페 목록 조회 Service / ViewModel 분리
- v 더미 UI 데이터를 Supabase 조회 구조로 교체
- v 리뷰 / 북마크를 Supabase 기반 Service와 연결
- v 사용자 프로필 보장 로직(`UserProfileService`) 추가
- v 로그인/회원가입 에러 메시지 세분화
- v 브라우저용 UI 목업 파일 추가
- v 로그인/운영/시드/Supabase 검증 문서 정리
- v 개인정보처리방침 / 이용약관 / 위치정보 처리 기준안 정리
- v GitHub Pages 지원/정책 페이지 공개
- v ONE_PAGER / LOGIN_FLOW / ERD / README / API_SPEC / 백엔드 / Supabase 문서 기준선 정리
- v GitHub `main` 브랜치 반영 완료

## 2. 지금 바로 확인해야 할 것
- v Xcode 시뮬레이터에서 앱 전체 실행 확인
- v 이메일 로그인 후 홈 진입, 카페 조회, 리뷰 작성, 북마크 동작 검증
- v 리뷰 작성 후 상세 / 마이페이지 / 최근 활동 반영 흐름 검증
- v 기본 앱 흐름 기준 빈 상태 문구와 화면 전환 정상 동작 확인
- [ ] 네트워크 실패, 권한 문제, 강제 빈 데이터 상태에서 에러 문구/로딩 상태 점검

## 3. 데이터 / 백엔드 상태

로컬 반영 완료:
- v `SUPABASE_MINI_SCHEMA.sql` 확장
- v `users`, `user_identities`, `cafes`, `reviews`, `bookmarks` 스키마 정의
- v 리뷰 수 집계용 트리거 / 함수 추가
- v RLS 정책 초안 추가
- v `SUPABASE_VERIFY.sql` 검증 쿼리 추가
- v `SUPABASE_CAFE_SEED.sql` 카페 시드 SQL 추가
- v `CAFE_SEED_TEMPLATE.csv` 카페 시드 템플릿 보강
- v `REVIEW_SEED_TEMPLATE.csv` 리뷰 시드 템플릿 추가
- v `SUPABASE_REVIEW_SEED.sql` 전체 리뷰 시드 SQL 추가
- v `TEST_ACCOUNTS_TEMPLATE.csv` 테스트 계정 템플릿 추가
- v `SUPABASE_RESET_CONTENT.sql` 기존 더미 데이터 초기화 SQL 추가
- v `SUPABASE_AUTH_TRIGGER_FIX.sql` 회원가입 트리거 수정 SQL 추가
- v `SUPABASE_AUTH_BACKFILL.sql` 테스트 계정 프로필 백필 SQL 추가
- v `OPERATIONS_SEED_PLAN.md` 운영/시드 기준 문서 추가
- v Supabase 퍼블릭 조회 연결 확인 (`cafes`, `reviews`, `bookmarks` 응답 확인)
- v `SUPABASE_VERIFY.sql`에 카페/리뷰 수량과 legacy 데이터 점검 쿼리 보강
- v `SUPABASE_APPLY_CHECKLIST.md` 실제 반영 체크리스트 추가
- v `AUTH_PROVIDER_SETUP_CHECKLIST.md` 이메일 로그인 설정 체크리스트로 정리
- v `APP_STORE_METADATA_DRAFT.md` 앱스토어 메타데이터 초안 추가
- v `APP_STORE_SCREENSHOT_PLAN.md` 앱스토어 스크린샷 구성안 추가
- v `LAUNCH_VALUES_CHECKLIST.md` 출시 고정값 체크리스트 추가
- v `APP_PRIVACY_LABEL_DRAFT.md` App Privacy 초안 추가
- v `MANUAL_QA_CHECKLIST.md` 수동 검증 체크리스트 추가
- v `APP_REVIEW_NOTES_DRAFT.md` App Review 메모 초안 추가
- v `TEST_ACCOUNT_SETUP_CHECKLIST.md` 테스트 계정 준비 체크리스트 추가
- v `ERD.md`에 `auth.users` 연결과 트리거 기준 반영
- v `EXECUTION_SEQUENCE.md`에 Supabase → Provider → QA 실행 순서 정리
- v `SUPABASE_MINI_SCHEMA.sql`에서 legacy 샘플 카페 시드 제거

외부 확인 필요:
- v Supabase 프로젝트에 최신 `SUPABASE_MINI_SCHEMA.sql` 실제 반영
- v `SUPABASE_VERIFY.sql` 실행으로 컬럼 / 정책 / 시드 상태 점검
- v 카페 시드 24개 이상 실제 입력
- v 테스트 리뷰 36개 실제 입력 확인
- [ ] RLS 정책이 iOS 앱 요청 흐름과 충돌 없는지 검증
- v 현재 Supabase `cafes` 응답은 9개로 확인되어 목표 24개와 불일치
- v 현재 Supabase 리뷰 데이터에 legacy / 최신 형식이 혼재하는지 정리 필요
- v `SUPABASE_AUTH_BACKFILL.sql` 실행 포함 기준으로 `public.users` 테스트 계정 누락 정리 후 리뷰 36개 반영 확인

## 4. 로그인 확장 상태

로컬 반영 완료:
- v Email 로그인 기본 흐름
- v 로그인 화면과 인증 로직을 이메일 전용 기준으로 정리
- v 계정 연결 정책 문서화
- v Google / Apple / Kakao / Naver를 후순위 확장 대상으로 정리

현재 결정:
- v 현재 MVP 로그인 수단은 이메일만 유지한다.
- v Google 로그인은 MVP 이후 작업으로 분리한다.
- v Apple 로그인은 MVP 이후 작업으로 분리한다.
- v Kakao 로그인은 2차 우선순위로 추가한다.
- v Naver 로그인은 이번 버전에서는 보류한다.
- v Supabase Auth 설정 확인 결과 `email=true`, `disable_signup=false`, `mailer_autoconfirm=false`

남은 일:
- v 이메일 회원가입 시 `Database error saving new user`가 나면 `SUPABASE_AUTH_TRIGGER_FIX.sql` 실제 반영
- v 실제 로그인 성공/실패 케이스별 메시지 점검
- v Kakao 로그인 추가 여부를 MVP 이후 작업으로 분리

## 5. 운영 준비

로컬 반영 완료:
- v 초기 지역 3곳 확정
- v 운영/시드 기준 문서화
- v 테스트용 카페 시드 템플릿 작성
- v 테스트용 리뷰 시드 템플릿 작성

현재 작업 기준:
- v 초기 지역 3곳은 `성수`, `연남`, `망원`
- v 운영 기준 문서는 `OPERATIONS_SEED_PLAN.md`
- v 카페 입력 초안은 `CAFE_SEED_TEMPLATE.csv`
- v 카페 입력 SQL은 `SUPABASE_CAFE_SEED.sql`
- v 리뷰 입력 초안은 `REVIEW_SEED_TEMPLATE.csv`

남은 일:
- v 지역별 카페 데이터 실제 수집 및 검수
- v 카페 24개 기준으로 필수 필드 누락 없는지 확인
- v 리뷰 분배 기준에 맞춰 테스트 리뷰 작성
- v 신고/관리 최소 운영 정책 최종 정리

## 6. 출시 전 문서
- v 개인정보처리방침 공개본 정리 및 GitHub Pages 반영
- v 이용약관 공개본 정리 및 GitHub Pages 반영
- v 현재 MVP는 개인위치정보 미수집으로 별도 위치기반서비스 약관 비공개 유지
- [ ] 앱스토어 제출용 설명/스크린샷 준비
- [ ] 테스트 계정 준비
현재 상태: Auth 계정 / `public.users` 정합성 / 카페 24개 / 리뷰 36개 반영과 앱 내 end-to-end QA는 확인 완료했고, 현재 MVP는 이메일 로그인 기준으로 정리했다. 지원/개인정보처리방침/이용약관 페이지는 GitHub Pages에 공개했다.

공개 URL:
- 메인: `https://hwang-john.github.io/brewspot/`
- 지원: `https://hwang-john.github.io/brewspot/support.html`
- 개인정보처리방침: `https://hwang-john.github.io/brewspot/privacy-policy.html`
- 이용약관: `https://hwang-john.github.io/brewspot/terms.html`

## 7. 이번 버전에서 미루기
- [ ] Google 로그인 구현
- [ ] Apple 로그인 구현
- [ ] Kakao 로그인 구현
- [ ] Naver 로그인 구현
- [ ] 커뮤니티 게시판
- [ ] 랭킹 고도화
- [ ] 홈바리스타 기능
- [ ] 커머스 / 중고장터
- [ ] 고급 추천 엔진

## 8. 지금 구현 우선순위 재정리

필수:
- v 홈 / 북마크 / 내 리뷰에서 네트워크 실패와 권한 실패를 실제 UI로 노출
- v 공통 에러 상태 컴포넌트 추가 (`에러 문구`, `다시 시도` 버튼, `로딩/빈 상태` 구분)
- v 마이페이지에 `문의하기`, `개인정보처리방침`, `이용약관`, `앱 버전` 섹션 추가
- v 계정 관리 동선 보강 (`계정 삭제 문의 방법` 또는 `탈퇴/삭제 요청 안내` 제공)
- v 지도 첫 진입 경험 개선 (고정 좌표 대신 카페 데이터 기준 중심 이동 또는 선택 카페 중심 이동)

있으면 좋은 것:
- v 빈 상태 화면 디자인 보강 (`문구만`이 아니라 아이콘/설명/다음 행동 포함)
- v 홈 화면 정보 구조 재정리 (검색/필터 상태 강조, 카드 정보 우선순위 조정)
- v 리뷰 작성 UX 보강 (저장 성공/실패 피드백, 이탈 방지, 입력 흐름 단순화)
- v 지원/정책 페이지와 앱 내부 동선 연결 강화

나중에 미뤄도 되는 것:
- [ ] 현재 위치 권한 기반 기능 추가
- [ ] 소셜 로그인 재도입
- [ ] 프로필 편집 / 취향 입력 고도화
- [ ] 운영 문서와 ERD를 확장 범위 기준으로 다시 정리

현재 판단:
- v 지금은 `출시 마감`보다 `에러 처리`, `마이페이지 구조`, `지도 UX`, `빈 상태 디자인`을 먼저 보강하는 편이 맞다.

## 추천 작업 순서
1. 마이페이지 프로필 / 최근 활동 / 리뷰 카드 톤을 한 단계 더 정교화
2. 카페 상세 리뷰 리스트와 정보 카드의 시각 계층을 더 통일
3. v `CafeMapView`의 iOS 17 deprecated API를 최신 `Map` 방식으로 교체
4. v 카페 상세 / 마이페이지를 기준으로 브랜드 카피와 마이크로카피 정리
5. v 제품 범위 정리 후 출시 문서와 체크리스트 다시 맞추기

## 9. 다음 추천 작업
1. v 리뷰 저장 / 북마크 저장 완료 시 짧은 성공 피드백 추가
2. v 카페 상세 상단과 홈 카드에 실제 이미지 또는 비주얼 에셋 전략 정리
3. 앱스토어 스크린샷용 더미 카피와 촬영 계정 상태 최종 정리
