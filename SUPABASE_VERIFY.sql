-- BrewSpot Supabase verification queries
-- Run this after executing SUPABASE_MINI_SCHEMA.sql

-- 1. Required tables
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in ('users', 'user_identities', 'cafes', 'reviews', 'bookmarks')
order by table_name;

-- 2. cafes columns expected by the app
select column_name, data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'cafes'
  and column_name in (
    'id',
    'name',
    'address',
    'category',
    'city',
    'latitude',
    'longitude',
    'signature_menu_name',
    'signature_menu_price',
    'price_note',
    'short_description',
    'vibe_tags',
    'features',
    'open_hours',
    'avg_rating',
    'review_count'
  )
order by column_name;

-- 3. reviews columns expected by the app
select column_name, data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'reviews'
  and column_name in (
    'id',
    'user_id',
    'cafe_id',
    'author_nickname',
    'overall_rating',
    'recommended_menu_name',
    'content',
    'created_at',
    'updated_at'
  )
order by column_name;

-- 4. bookmarks columns expected by the app
select column_name, data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'bookmarks'
  and column_name in ('id', 'user_id', 'cafe_id', 'created_at')
order by column_name;

-- 5. RLS policies
select schemaname, tablename, policyname, permissive, roles, cmd
from pg_policies
where schemaname = 'public'
  and tablename in ('users', 'user_identities', 'cafes', 'reviews', 'bookmarks')
order by tablename, policyname;

-- 6. Cafe seed count
select count(*) as cafe_count
from public.cafes;

-- 7. Cafe count by city
select city, count(*) as cafe_count
from public.cafes
group by city
order by city;

-- 8. Review seed count
select count(*) as review_count
from public.reviews;

-- 9. Review count by cafe
select c.city, c.name, count(r.id) as review_count
from public.cafes c
left join public.reviews r on r.cafe_id = c.id
group by c.city, c.name
order by c.city, c.name;

-- 10. Rows that still look like legacy review data
select id, user_id, cafe_id, author_nickname, recommended_menu_name, content, created_at
from public.reviews
where author_nickname is null
   or recommended_menu_name is null
order by created_at desc;

-- 11. Test account count in public.users
select count(*) as public_user_count
from public.users
where email in (
  'test1@brewspot.app',
  'test2@brewspot.app',
  'test3@brewspot.app',
  'test4@brewspot.app',
  'test6@brewspot.app',
  'test8@brewspot.app',
  'test9@brewspot.app',
  'test10@brewspot.app',
  'test12@brewspot.app',
  'test13@brewspot.app',
  'test14@brewspot.app',
  'test15@brewspot.app',
  'test16@brewspot.app',
  'test17@brewspot.app',
  'test18@brewspot.app'
);

-- 12. Test account existence check
select email, nickname
from public.users
where email in (
  'test1@brewspot.app',
  'test2@brewspot.app',
  'test3@brewspot.app',
  'test4@brewspot.app',
  'test6@brewspot.app',
  'test8@brewspot.app',
  'test9@brewspot.app',
  'test10@brewspot.app',
  'test12@brewspot.app',
  'test13@brewspot.app',
  'test14@brewspot.app',
  'test15@brewspot.app',
  'test16@brewspot.app',
  'test17@brewspot.app',
  'test18@brewspot.app'
)
order by email;

-- 13. Auth users missing public.users profile rows
select au.email, au.id
from auth.users au
left join public.users pu
  on pu.id = au.id
where au.email in (
  'test1@brewspot.app',
  'test2@brewspot.app',
  'test3@brewspot.app',
  'test4@brewspot.app',
  'test6@brewspot.app',
  'test8@brewspot.app',
  'test9@brewspot.app',
  'test10@brewspot.app',
  'test12@brewspot.app',
  'test13@brewspot.app',
  'test14@brewspot.app',
  'test15@brewspot.app',
  'test16@brewspot.app',
  'test17@brewspot.app',
  'test18@brewspot.app'
)
  and pu.id is null
order by au.email;

-- 14. Seed preview
select id, name, category, city, price_note
from public.cafes
order by created_at desc
limit 10;
