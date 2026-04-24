-- BrewSpot review seed template
-- 1. Make sure users with the emails in REVIEW_SEED_TEMPLATE.csv exist in auth/users.
-- 2. Update rows below or import from the CSV manually.
-- 3. This template inserts reviews by matching cafe (name, address) and user email.

with seed_reviews as (
  select *
  from (
    values
      ('대니스수퍼마켓', '서울 성동구 연무장15길 11', 'test4@brewspot.app', '디저트러버', 5, '대니스츄 플레인', '츄러스가 눅눅하지 않고 커피랑 같이 먹기 좋아서 첫 방문 만족도가 높았어요.', '2026-04-24T12:10:00+09:00'::timestamptz),
      ('커피 리브레 연남점', '서울 마포구 성미산로32길 20-5', 'test10@brewspot.app', '드립메모', 5, '플랫화이트', '우유 음료 밸런스가 안정적이고 짧게 들러도 커피 만족감이 높았어요.', '2026-04-24T11:10:00+09:00'::timestamptz),
      ('카페 공명 망원책빵', '서울 마포구 월드컵로13길 22-3', 'test8@brewspot.app', '브런치러버', 5, '드립커피', '층별 공간이 넓어서 오래 머물기 좋고 책이 있어 혼자 가도 심심하지 않았어요.', '2026-04-24T10:40:00+09:00'::timestamptz)
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
