-- BrewSpot MVP DB Schema Draft
-- PostgreSQL 기준

create extension if not exists "pgcrypto";

create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  nickname varchar(30) not null unique,
  email varchar(255),
  profile_image_url text,
  status varchar(20) not null default 'active',
  marketing_opt_in boolean not null default false,
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

create table if not exists user_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  roast_preference varchar(50),
  flavor_preference varchar(50),
  visit_purpose varchar(50),
  preferred_region varchar(100),
  updated_at timestamptz not null default now(),
  unique (user_id)
);

create table if not exists cafes (
  id uuid primary key default gen_random_uuid(),
  name varchar(150) not null,
  address text not null,
  latitude numeric(10, 7),
  longitude numeric(10, 7),
  phone varchar(50),
  opening_hours text,
  status varchar(20) not null default 'active',
  avg_rating numeric(2, 1) not null default 0.0,
  review_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists cafe_menus (
  id uuid primary key default gen_random_uuid(),
  cafe_id uuid not null references cafes(id) on delete cascade,
  name varchar(150) not null,
  price integer not null,
  signature_yn boolean not null default false,
  category varchar(50),
  created_at timestamptz not null default now()
);

create table if not exists reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  cafe_id uuid not null references cafes(id) on delete cascade,
  overall_rating integer not null check (overall_rating between 1 and 5),
  taste_rating integer check (taste_rating between 1 and 5),
  mood_rating integer check (mood_rating between 1 and 5),
  price_rating integer check (price_rating between 1 and 5),
  work_friendly_rating integer check (work_friendly_rating between 1 and 5),
  content text,
  visit_purpose varchar(50),
  status varchar(20) not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists review_images (
  id uuid primary key default gen_random_uuid(),
  review_id uuid not null references reviews(id) on delete cascade,
  image_url text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists bookmarks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  cafe_id uuid not null references cafes(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, cafe_id)
);

create table if not exists visit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  cafe_id uuid references cafes(id) on delete set null,
  drink_name varchar(150),
  price integer,
  visited_at timestamptz not null,
  memo text,
  created_at timestamptz not null default now()
);

create table if not exists community_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  category varchar(50) not null,
  title varchar(200) not null,
  content text not null,
  status varchar(20) not null default 'active',
  like_count integer not null default 0,
  comment_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists community_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references community_posts(id) on delete cascade,
  user_id uuid not null references users(id) on delete cascade,
  content text not null,
  status varchar(20) not null default 'active',
  created_at timestamptz not null default now()
);

create table if not exists homebarista_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  title varchar(200) not null,
  content text,
  bean_name varchar(150),
  recipe text,
  brew_tool varchar(100),
  image_url text,
  status varchar(20) not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists reports (
  id uuid primary key default gen_random_uuid(),
  reporter_user_id uuid not null references users(id) on delete cascade,
  target_type varchar(50) not null,
  target_id uuid not null,
  reason varchar(100) not null,
  status varchar(20) not null default 'pending',
  created_at timestamptz not null default now(),
  processed_at timestamptz
);

create table if not exists rank_snapshots (
  id uuid primary key default gen_random_uuid(),
  cafe_id uuid not null references cafes(id) on delete cascade,
  ranking_type varchar(50) not null,
  region_code varchar(100),
  rank integer not null,
  score numeric(10, 2) not null,
  snapshot_date date not null
);

create table if not exists audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references users(id) on delete set null,
  action varchar(100) not null,
  target_type varchar(50),
  target_id uuid,
  payload jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_user_identities_user_id on user_identities(user_id);
create index if not exists idx_cafes_name on cafes(name);
create index if not exists idx_reviews_cafe_id on reviews(cafe_id);
create index if not exists idx_reviews_user_id on reviews(user_id);
create index if not exists idx_bookmarks_user_id on bookmarks(user_id);
create index if not exists idx_visit_logs_user_id on visit_logs(user_id);
create index if not exists idx_community_posts_category on community_posts(category);
create index if not exists idx_reports_status on reports(status);
create index if not exists idx_rank_snapshots_region on rank_snapshots(region_code, ranking_type, snapshot_date, rank);
