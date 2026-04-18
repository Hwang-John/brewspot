-- BrewSpot MVP Mini Schema
-- 최소 5개 테이블 버전
-- 로그인: email / google(gmail) / kakao / naver

create extension if not exists "pgcrypto";

create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  nickname varchar(30) not null unique,
  email varchar(255),
  profile_image_url text,
  status varchar(20) not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists user_identities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  provider varchar(20) not null,
  provider_user_id varchar(255) not null,
  provider_email varchar(255),
  linked_at timestamptz not null default now(),
  unique (provider, provider_user_id)
);

create table if not exists cafes (
  id uuid primary key default gen_random_uuid(),
  name varchar(150) not null,
  address text not null,
  latitude numeric(10, 7),
  longitude numeric(10, 7),
  signature_menu_name varchar(150),
  signature_menu_price integer,
  avg_rating numeric(2, 1) not null default 0.0,
  review_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  cafe_id uuid not null references cafes(id) on delete cascade,
  overall_rating integer not null check (overall_rating between 1 and 5),
  content text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists bookmarks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  cafe_id uuid not null references cafes(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, cafe_id)
);

create index if not exists idx_user_identities_user_id on user_identities(user_id);
create index if not exists idx_reviews_cafe_id on reviews(cafe_id);
create index if not exists idx_reviews_user_id on reviews(user_id);
create index if not exists idx_bookmarks_user_id on bookmarks(user_id);

comment on table users is '서비스 사용자 기본 정보';
comment on table user_identities is '이메일, Gmail, Kakao, Naver 로그인 연결 정보';
comment on table cafes is '카페 기본 정보';
comment on table reviews is '카페 리뷰';
comment on table bookmarks is '사용자 저장 카페';
