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

-- 7. Seed preview
select id, name, category, city, price_note
from public.cafes
order by created_at desc
limit 10;
