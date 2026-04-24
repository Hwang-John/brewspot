# BrewSpot App Privacy 초안

최종 기준일: 2026-04-24

이 문서는 App Store Connect의 App Privacy 입력을 준비하기 위한 초안이다.  
최종 제출 전에는 Supabase 운영 설정, 에러 로그 수집 범위, 외부 SDK 추가 여부를 다시 확인해야 한다.

## 1. Tracking

- 현재 기준: `No`
- 광고 SDK, 제3자 추적, IDFA 사용 코드 없음

## 2. Collected Data 초안

### Contact Info

- `Email Address`
- 수집 목적: 계정 생성, 로그인, 고객 문의 대응
- 연결 여부: 계정에 연결됨

### User Content

- `Reviews`
- 수집 목적: 리뷰 작성/조회, 마이페이지 활동 표시, 운영 정책 집행
- 연결 여부: 계정에 연결됨

### Identifiers

- `User ID`
- 수집 목적: 계정 식별, 세션 유지, 데이터 연결
- 연결 여부: 계정에 연결됨

## 3. 조건부 재확인 항목

아래는 최종 제출 전 운영 방식에 따라 답변이 달라질 수 있다.

- `Product Interaction`
  현재 앱은 별도 분석 SDK를 쓰지 않지만, 서버 운영 로그를 제품 분석 용도로 활용한다면 재검토 필요
- `Diagnostics`
  현재 앱 코드에는 크래시 리포팅 SDK가 없지만, 운영 중 에러 로그를 별도 수집한다면 재검토 필요

## 4. Not Collected 초안

현재 코드/설정 기준으로 아래 항목은 수집하지 않는 쪽으로 본다.

- 정확한 위치
- 대략적 위치
- 사진 또는 동영상
- 연락처
- 검색 기록
- 구매 내역
- 건강 정보
- 금융 정보
- 광고 데이터

## 5. 근거 메모

- `Info.plist`에 위치, 사진, 카메라, 알림 권한 설명 키 없음
- 현재 로그인 수단은 `email`, `google`, `apple`
- 지도는 카페 좌표 표시용이며 사용자 현재 위치 권한 요청 없음
- 앱 내 광고/추적 SDK 연결 없음

## 6. 제출 전 최종 확인

- [ ] Supabase 외 외부 SDK 추가 여부 재확인
- [ ] 에러 로그/운영 로그를 App Privacy의 Diagnostics로 볼지 결정
- [ ] App Store Connect 답변과 `PRIVACY_POLICY_DRAFT.md` 문구 일치 확인
- [ ] 향후 위치 기반 기능 추가 시 답변 수정
