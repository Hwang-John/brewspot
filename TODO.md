# BrewSpot TODO

이 파일 하나만 작업 기준으로 사용합니다.  
진행 상황은 "로컬 코드/문서에 반영된 것"과 "외부 환경에서 실제 확인이 필요한 것"을 구분해서 적습니다.

표시 규칙:
- `=` 로컬 작업 완료
- `[ ]` 아직 해야 할 일 / 외부 확인 필요

## 1. 지금까지 로컬에 반영 완료
- = SwiftUI iOS 앱 기본 골격 구성
- = `ios/project.yml` 기반 XcodeGen 프로젝트 구성
- = `ios/BrewSpot.xcodeproj` 생성
- = Supabase Swift 패키지 연결
- = Supabase URL / Publishable Key 연결
- = 이메일 로그인 / 회원가입 / 세션 확인 / 로그아웃 구현
- = Google 로그인 버튼 및 OAuth 호출 연결
- = Apple 로그인 버튼 및 OAuth 호출 연결
- = 로그인 후 홈 진입 흐름 구현
- = 지도 기반 카페 탐색 화면 구현
- = 카페 상세 화면 구현
- = 리뷰 작성 시트와 리뷰 목록 반영 구현
- = 카페 저장(북마크) 기능 구현
- = 홈 검색 / 카테고리 필터 구현
- = 마이페이지 탭 추가
- = 저장한 카페 / 취향 태그 / 활동 요약 UI 구현
- = 내 리뷰 목록을 마이페이지에 연결
- = 최근 활동 기록 섹션 추가
- = 비어 있는 상태 화면 문구/디자인 다듬기
- = 카페 목록 조회 Service / ViewModel 분리
- = 더미 UI 데이터를 Supabase 조회 구조로 교체
- = 리뷰 / 북마크를 Supabase 기반 Service와 연결
- = 사용자 프로필 보장 로직(`UserProfileService`) 추가
- = 브라우저용 UI 목업 파일 추가
- = 로그인/운영/시드/Supabase 검증 문서 정리
- = 개인정보처리방침 / 이용약관 / 위치정보 처리 기준안 정리
- = 로컬 Git 커밋 완료 (`7b07bb0`)

## 2. 지금 바로 확인해야 할 것
- = Xcode 시뮬레이터에서 앱 전체 실행 확인
- [ ] GitHub 인증 후 `origin/main` push
- [ ] 이메일 로그인 후 홈 진입, 카페 조회, 리뷰 작성, 북마크 동작 검증
- [ ] Google 로그인 redirect / URL scheme / Supabase Provider 설정 실검증
- [ ] Apple 로그인 redirect / Bundle 설정 / Supabase Provider 설정 실검증
- [ ] 리뷰 작성 후 상세 / 마이페이지 / 최근 활동 반영 흐름 검증
- [ ] 네트워크 실패, 권한 문제, 빈 데이터 상태에서 에러 문구/로딩 상태 점검

## 3. 데이터 / 백엔드 상태

로컬 반영 완료:
- = `SUPABASE_MINI_SCHEMA.sql` 확장
- = `users`, `user_identities`, `cafes`, `reviews`, `bookmarks` 스키마 정의
- = 리뷰 수 집계용 트리거 / 함수 추가
- = RLS 정책 초안 추가
- = `SUPABASE_VERIFY.sql` 검증 쿼리 추가
- = `SUPABASE_CAFE_SEED.sql` 카페 시드 SQL 추가
- = `CAFE_SEED_TEMPLATE.csv` 카페 시드 템플릿 보강
- = `REVIEW_SEED_TEMPLATE.csv` 리뷰 시드 템플릿 추가
- = `OPERATIONS_SEED_PLAN.md` 운영/시드 기준 문서 추가

외부 확인 필요:
- [ ] Supabase 프로젝트에 최신 `SUPABASE_MINI_SCHEMA.sql` 실제 반영
- [ ] `SUPABASE_VERIFY.sql` 실행으로 컬럼 / 정책 / 시드 상태 점검
- [ ] 카페 시드 24개 이상 실제 입력
- [ ] 테스트 리뷰 36개 이상 실제 입력
- [ ] RLS 정책이 iOS 앱 요청 흐름과 충돌 없는지 검증

## 4. 로그인 확장 상태

로컬 반영 완료:
- = Email 로그인 기본 흐름
- = Google 로그인 UI 및 AuthService 연결
- = Apple 로그인 UI 및 AuthService 연결
- = 계정 연결 정책 문서화
- = Apple / Google / Kakao / Naver 우선순위 결정 정리

현재 결정:
- = Apple 로그인은 iOS 앱에서 Google 같은 서드파티 로그인을 제공할 때 App Store 제출 전 대응 항목으로 본다.
- = Kakao 로그인은 2차 우선순위로 추가한다.
- = Naver 로그인은 이번 버전에서는 보류한다.

남은 일:
- [ ] Google Provider 콘솔 설정값 최종 확정
- [ ] Apple Provider 콘솔 설정값 최종 확정
- [ ] 실제 로그인 성공/실패 케이스별 메시지 점검
- [ ] Kakao 로그인 추가 여부를 MVP 이후 작업으로 분리

## 5. 운영 준비

로컬 반영 완료:
- = 초기 지역 3곳 확정
- = 운영/시드 기준 문서화
- = 테스트용 카페 시드 템플릿 작성
- = 테스트용 리뷰 시드 템플릿 작성

현재 작업 기준:
- = 초기 지역 3곳은 `성수`, `연남`, `망원`
- = 운영 기준 문서는 `OPERATIONS_SEED_PLAN.md`
- = 카페 입력 초안은 `CAFE_SEED_TEMPLATE.csv`
- = 카페 입력 SQL은 `SUPABASE_CAFE_SEED.sql`
- = 리뷰 입력 초안은 `REVIEW_SEED_TEMPLATE.csv`

남은 일:
- = 지역별 카페 데이터 실제 수집 및 검수
- = 카페 24개 기준으로 필수 필드 누락 없는지 확인
- = 리뷰 분배 기준에 맞춰 테스트 리뷰 작성
- = 신고/관리 최소 운영 정책 최종 정리

## 6. 출시 전 문서
- [ ] 개인정보처리방침 최종본 정리
- [ ] 이용약관 최종본 정리
- = 현재 MVP는 개인위치정보 미수집으로 별도 위치기반서비스 약관 비공개 유지
- [ ] 앱스토어 제출용 설명/스크린샷 준비
- [ ] 테스트 계정 준비

## 7. 이번 버전에서 미루기
- [ ] Kakao 로그인 구현
- [ ] Naver 로그인 구현
- [ ] 커뮤니티 게시판
- [ ] 랭킹 고도화
- [ ] 홈바리스타 기능
- [ ] 커머스 / 중고장터
- [ ] 고급 추천 엔진

## 추천 작업 순서
1. Xcode에서 이메일 / Google / Apple 로그인 실제 동작 확인
2. 카페 조회 / 북마크 / 리뷰 작성 end-to-end 검증
3. Supabase 최신 스키마 반영 및 `SUPABASE_VERIFY.sql` 실행
4. 카페 24개 / 리뷰 36개 시드 실제 입력
5. 운영 정책 및 출시 문서 마무리
