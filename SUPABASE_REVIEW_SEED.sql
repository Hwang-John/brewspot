-- BrewSpot full review seed
-- Run this after SUPABASE_MINI_SCHEMA.sql and SUPABASE_CAFE_SEED.sql
-- If test accounts exist in auth.users but not public.users, run SUPABASE_AUTH_BACKFILL.sql first
-- Make sure users with the emails below already exist in auth.users/public.users
-- Safe to re-run because matching seeded reviews are deleted before insert

with seed_reviews as (
  select *
  from (
    values
      ('대니스수퍼마켓', '서울 성동구 연무장15길 11', 'test4@brewspot.app', '디저트러버', 5, '대니스츄 플레인', '츄러스가 눅눅하지 않고 커피랑 같이 먹기 좋아서 첫 방문 만족도가 높았어요.', '2026-04-24T12:10:00+09:00'::timestamptz),
      ('대니스수퍼마켓', '서울 성동구 연무장15길 11', 'test15@brewspot.app', '빵먼저', 4, '아메리카노', '간식처럼 들르기 좋고 성수 메인 골목에서 접근성이 좋아 재방문하기 편했어요.', '2026-04-23T16:40:00+09:00'::timestamptz),
      ('대니스수퍼마켓', '서울 성동구 연무장15길 11', 'test1@brewspot.app', '라떼헌터', 5, '대니스츄 플레인', '달달한 메뉴가 강하지만 커피 맛도 무겁지 않아서 균형이 좋았어요.', '2026-04-21T14:10:00+09:00'::timestamptz),
      ('아이안', '서울 성동구 왕십리로4가길 3', 'test13@brewspot.app', '크림매니아', 5, '꿀고구마타르트', '타르트 식감이 좋고 늦게까지 열어서 저녁 디저트 코스로 가기 좋았어요.', '2026-04-24T20:20:00+09:00'::timestamptz),
      ('아이안', '서울 성동구 왕십리로4가길 3', 'test8@brewspot.app', '브런치러버', 4, '밤크림라떼', '분위기가 차분해서 대화하기 좋았고 시즌 음료가 디저트랑 잘 맞았어요.', '2026-04-22T19:00:00+09:00'::timestamptz),
      ('아이안', '서울 성동구 왕십리로4가길 3', 'test16@brewspot.app', '티타임러', 5, '꿀고구마타르트', '진한 디저트 좋아하면 만족도가 높을 것 같고 야간 방문 동선이 편했어요.', '2026-04-20T18:30:00+09:00'::timestamptz),
      ('커피 리브레 연남점', '서울 마포구 성미산로32길 20-5', 'test10@brewspot.app', '드립메모', 5, '플랫화이트', '우유 음료 밸런스가 안정적이고 짧게 들러도 커피 만족감이 높았어요.', '2026-04-24T11:10:00+09:00'::timestamptz),
      ('커피 리브레 연남점', '서울 마포구 성미산로32길 20-5', 'test2@brewspot.app', '원두메모', 5, '아메리카노', '원두 개성이 깔끔하게 느껴져서 커피 중심으로 방문하기 좋은 곳이었어요.', '2026-04-23T13:00:00+09:00'::timestamptz),
      ('커피 리브레 연남점', '서울 마포구 성미산로32길 20-5', 'test14@brewspot.app', '카페산책', 4, '플랫화이트', '작은 규모지만 회전이 빠르고 연남에서 커피 맛으로 추천하기 좋아요.', '2026-04-19T12:20:00+09:00'::timestamptz),
      ('레인리포트 브리티시', '서울 마포구 동교로51안길 17', 'test9@brewspot.app', '햇살기록', 5, '디저트샘플러', '공간 콘셉트가 분명해서 데이트 코스로 기억에 남았고 디저트도 보는 재미가 있었어요.', '2026-04-24T17:40:00+09:00'::timestamptz),
      ('레인리포트 브리티시', '서울 마포구 동교로51안길 17', 'test4@brewspot.app', '디저트러버', 4, '런던 포그', '룸처럼 나뉜 좌석이 독특해서 오래 머물기 좋았고 테마가 확실했어요.', '2026-04-22T18:10:00+09:00'::timestamptz),
      ('레인리포트 브리티시', '서울 마포구 동교로51안길 17', 'test16@brewspot.app', '티타임러', 5, '디저트샘플러', '연남에서 분위기 좋은 카페 찾을 때 추천하기 좋고 사진도 잘 나왔어요.', '2026-04-20T15:50:00+09:00'::timestamptz),
      ('으믐', '서울 마포구 성미산로 29', 'test15@brewspot.app', '빵먼저', 5, '스윗 카푸치노', '케이크와 커피 조합이 좋고 조용한 감성 덕분에 편하게 쉬다 왔어요.', '2026-04-24T14:30:00+09:00'::timestamptz),
      ('으믐', '서울 마포구 성미산로 29', 'test13@brewspot.app', '크림매니아', 4, '바닐라빈 라떼', '디저트 라인업이 매력적이고 소규모로 머물기 좋은 분위기였어요.', '2026-04-22T14:50:00+09:00'::timestamptz),
      ('으믐', '서울 마포구 성미산로 29', 'test3@brewspot.app', '모닝브루', 5, '아메리카노', '시즌 디저트 구성이 자주 바뀌는 느낌이라 재방문 이유가 분명한 곳이었어요.', '2026-04-18T13:20:00+09:00'::timestamptz),
      ('카페 공명 망원책빵', '서울 마포구 월드컵로13길 22-3', 'test8@brewspot.app', '브런치러버', 5, '드립커피', '층별 공간이 넓어서 오래 머물기 좋고 책이 있어 혼자 가도 심심하지 않았어요.', '2026-04-24T10:40:00+09:00'::timestamptz),
      ('카페 공명 망원책빵', '서울 마포구 월드컵로13길 22-3', 'test6@brewspot.app', '집중모드', 4, '오리지널 크림빵', '노트북 들고 가기 괜찮고 대형 매장이라 자리 찾기가 비교적 쉬웠어요.', '2026-04-23T15:10:00+09:00'::timestamptz),
      ('카페 공명 망원책빵', '서울 마포구 월드컵로13길 22-3', 'test18@brewspot.app', '동네기록', 5, '드립커피', '망원에서 모임하기 좋은 규모고 빵까지 같이 고를 수 있어 만족스러웠어요.', '2026-04-21T11:40:00+09:00'::timestamptz),
      ('베통 성수', '서울 성동구 연무장7가길 8', 'test15@brewspot.app', '빵먼저', 5, '소금빵', '소금빵 결이 좋고 매장이 작아도 동선이 빨라서 테이크아웃하기 편했어요.', '2026-04-24T09:50:00+09:00'::timestamptz),
      ('베통 성수', '서울 성동구 연무장7가길 8', 'test12@brewspot.app', '가성비픽', 4, '아메리카노', '성수에서 가볍게 빵이랑 커피 한 잔 하기 좋고 가격 부담도 크지 않았어요.', '2026-04-20T10:10:00+09:00'::timestamptz),
      ('하우스오브바이닐 성수점', '서울 성동구 아차산로7길 29', 'test13@brewspot.app', '크림매니아', 5, '딸기 파블로바', '디저트 비주얼이 강해서 사진 찍기 좋고 데이트 코스로 만족도가 높았어요.', '2026-04-24T18:20:00+09:00'::timestamptz),
      ('하우스오브바이닐 성수점', '서울 성동구 아차산로7길 29', 'test9@brewspot.app', '햇살기록', 4, '말차라떼', '좌석 분위기가 차분해서 생각보다 편하게 머물렀고 음료도 무난했어요.', '2026-04-22T17:00:00+09:00'::timestamptz),
      ('커피로드뷰 연남점', '서울 마포구 월드컵북로6길 52', 'test12@brewspot.app', '가성비픽', 5, '아메리카노', '연남에서 가격이 부담 없어서 자주 들르기 좋고 디저트 선택지도 괜찮았어요.', '2026-04-24T08:40:00+09:00'::timestamptz),
      ('커피로드뷰 연남점', '서울 마포구 월드컵북로6길 52', 'test4@brewspot.app', '디저트러버', 4, '티라미수', '티라미수가 무난하게 맛있고 전체적으로 편하게 이용하기 좋은 동네 카페 느낌이었어요.', '2026-04-19T16:20:00+09:00'::timestamptz),
      ('티브커피하우스', '서울 마포구 동교로51안길 11', 'test16@brewspot.app', '티타임러', 5, '티브 넘버 원', '주택 개조 공간이 예쁘고 시그니처 음료가 확실해서 목적 방문하기 좋았어요.', '2026-04-24T16:00:00+09:00'::timestamptz),
      ('티브커피하우스', '서울 마포구 동교로51안길 11', 'test14@brewspot.app', '카페산책', 4, '티브 아이스크림', '분위기 덕분에 천천히 쉬다 오기 좋았고 디저트류도 같이 보게 되는 곳이었어요.', '2026-04-21T17:30:00+09:00'::timestamptz),
      ('라뚜셩트 망원점', '서울 마포구 포은로8길 20', 'test15@brewspot.app', '빵먼저', 5, '소금빵', '망원시장 들렀다가 가볍게 들르기 좋고 빵 종류가 많아서 고르는 재미가 있었어요.', '2026-04-24T11:20:00+09:00'::timestamptz),
      ('라뚜셩트 망원점', '서울 마포구 포은로8길 20', 'test8@brewspot.app', '브런치러버', 4, '바닐라빈라떼', '층별로 자리가 나뉘어 있어 생각보다 여유롭게 머물 수 있었어요.', '2026-04-22T12:40:00+09:00'::timestamptz),
      ('포트레이트커피바', '서울 마포구 포은로8길 32', 'test10@brewspot.app', '드립메모', 5, '플랫화이트', '브루잉 쪽이 강하고 좌석 간격이 넓어서 혼자 커피 마시기 좋았어요.', '2026-04-24T13:30:00+09:00'::timestamptz),
      ('포트레이트커피바', '서울 마포구 포은로8길 32', 'test17@brewspot.app', '워케이션러', 4, '프렌치토스트', '조용한 편이라 작업과 대화 둘 다 무난했고 프렌치토스트가 기억에 남았어요.', '2026-04-20T14:00:00+09:00'::timestamptz),
      ('레이더 성수', '서울 성동구 연무장길 39-29', 'test1@brewspot.app', '라떼헌터', 5, '바닐라크림커피', '공간감이 좋아서 2인 방문 만족도가 높았고 시그니처 메뉴가 확실했어요.', '2026-04-23T19:10:00+09:00'::timestamptz),
      ('플로렌틴 성수', '서울 성동구 성수이로14길 14', 'test4@brewspot.app', '디저트러버', 4, '두바이쫀득쿠키', '쿠키류가 확실히 강하고 달달한 디저트 생각날 때 다시 갈 것 같아요.', '2026-04-21T15:30:00+09:00'::timestamptz),
      ('에프이에이티 연남', '서울 마포구 성미산로17길 86', 'test14@brewspot.app', '카페산책', 4, '바닐라라떼', '연남에서 친구랑 가볍게 만나기 좋고 좌석이 답답하지 않아 편했어요.', '2026-04-19T13:40:00+09:00'::timestamptz),
      ('맥코이 커피 연남', '서울 마포구 성미산로 147', 'test13@brewspot.app', '크림매니아', 5, '아메리카노', '빈티지한 무드가 좋아서 오래 기억에 남고 디저트까지 같이 즐기기 좋았어요.', '2026-04-18T17:10:00+09:00'::timestamptz),
      ('고슴도치 티라미수', '서울 마포구 희우정로5길 29', 'test4@brewspot.app', '디저트러버', 5, '클래식 티라미수', '티라미수 종류가 다양해서 디저트 좋아하면 한번쯤 꼭 들러볼 만했어요.', '2026-04-17T16:30:00+09:00'::timestamptz),
      ('루아르커피바 망원', '서울 마포구 월드컵로11길 7', 'test6@brewspot.app', '집중모드', 4, '커피', '2층 좌석과 콘센트 덕분에 노트북 작업하기 편했고 채광도 좋았어요.', '2026-04-16T14:20:00+09:00'::timestamptz)
  ) as t(
    cafe_name,
    cafe_address,
    user_email,
    author_nickname,
    overall_rating,
    recommended_menu_name,
    content,
    created_at
  )
),
deleted_seeded_reviews as (
  delete from public.reviews r
  using seed_reviews s
  join public.users u
    on u.email = s.user_email
  join public.cafes c
    on c.name = s.cafe_name
   and c.address = s.cafe_address
  where r.user_id = u.id
    and r.cafe_id = c.id
    and r.created_at = s.created_at
  returning r.id
)
insert into public.reviews (
  user_id,
  cafe_id,
  author_nickname,
  overall_rating,
  recommended_menu_name,
  content,
  created_at,
  updated_at
)
select
  u.id as user_id,
  c.id as cafe_id,
  s.author_nickname,
  s.overall_rating,
  s.recommended_menu_name,
  s.content,
  s.created_at,
  s.created_at
from seed_reviews s
join public.users u
  on u.email = s.user_email
join public.cafes c
  on c.name = s.cafe_name
 and c.address = s.cafe_address;
