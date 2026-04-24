-- BrewSpot MVP schema for Supabase
-- Email auth + cafe list + reviews + bookmarks

create extension if not exists "pgcrypto";

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  nickname varchar(30) not null unique,
  email varchar(255),
  profile_image_url text,
  status varchar(20) not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_identities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  provider varchar(20) not null,
  provider_user_id varchar(255) not null,
  provider_email varchar(255),
  linked_at timestamptz not null default now(),
  unique (provider, provider_user_id)
);

create table if not exists public.cafes (
  id uuid primary key default gen_random_uuid(),
  name varchar(150) not null,
  address text not null,
  category varchar(50) not null default '카페',
  city varchar(50) not null default '지역 정보',
  latitude numeric(10, 7),
  longitude numeric(10, 7),
  signature_menu_name varchar(150),
  signature_menu_price integer,
  price_note varchar(100) not null default '현장 확인 필요',
  short_description text not null default '카페 소개를 준비 중이에요.',
  vibe_tags text[] not null default '{}',
  features text[] not null default '{}',
  open_hours varchar(100) not null default '운영 시간 정보 준비 중',
  avg_rating numeric(2, 1) not null default 0.0,
  review_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.cafes add column if not exists category varchar(50) not null default '카페';
alter table public.cafes add column if not exists city varchar(50) not null default '지역 정보';
alter table public.cafes add column if not exists signature_menu_name varchar(150);
alter table public.cafes add column if not exists signature_menu_price integer;
alter table public.cafes add column if not exists price_note varchar(100) not null default '현장 확인 필요';
alter table public.cafes add column if not exists short_description text not null default '카페 소개를 준비 중이에요.';
alter table public.cafes add column if not exists vibe_tags text[] not null default '{}';
alter table public.cafes add column if not exists features text[] not null default '{}';
alter table public.cafes add column if not exists open_hours varchar(100) not null default '운영 시간 정보 준비 중';
alter table public.cafes add column if not exists avg_rating numeric(2, 1) not null default 0.0;
alter table public.cafes add column if not exists review_count integer not null default 0;
alter table public.cafes add column if not exists created_at timestamptz not null default now();
alter table public.cafes add column if not exists updated_at timestamptz not null default now();

drop table if exists temp_cafe_dedup_map;
create temporary table temp_cafe_dedup_map as
with ranked_cafes as (
  select
    id,
    name,
    address,
    created_at,
    first_value(id) over (
      partition by name, address
      order by created_at asc, id asc
    ) as canonical_id,
    row_number() over (
      partition by name, address
      order by created_at asc, id asc
    ) as row_num
  from public.cafes
)
select
  id as duplicate_id,
  canonical_id
from ranked_cafes
where row_num > 1;

do $$
begin
  if exists (select 1 from temp_cafe_dedup_map) then
    if to_regclass('public.reviews') is not null then
      update public.reviews r
      set cafe_id = m.canonical_id
      from temp_cafe_dedup_map m
      where r.cafe_id = m.duplicate_id;
    end if;

    if to_regclass('public.bookmarks') is not null then
      delete from public.bookmarks b
      using temp_cafe_dedup_map m
      where b.cafe_id = m.duplicate_id
        and exists (
          select 1
          from public.bookmarks existing
          where existing.user_id = b.user_id
            and existing.cafe_id = m.canonical_id
        );

      update public.bookmarks b
      set cafe_id = m.canonical_id
      from temp_cafe_dedup_map m
      where b.cafe_id = m.duplicate_id;
    end if;

    delete from public.cafes c
    using temp_cafe_dedup_map m
    where c.id = m.duplicate_id;
  end if;
end;
$$;

create unique index if not exists idx_cafes_name_address_unique
  on public.cafes(name, address);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  cafe_id uuid not null references public.cafes(id) on delete cascade,
  author_nickname varchar(30) not null,
  overall_rating integer not null check (overall_rating between 1 and 5),
  recommended_menu_name varchar(150),
  content text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.reviews add column if not exists author_nickname varchar(30);
alter table public.reviews add column if not exists recommended_menu_name varchar(150);
alter table public.reviews add column if not exists created_at timestamptz not null default now();
alter table public.reviews add column if not exists updated_at timestamptz not null default now();

update public.reviews
set author_nickname = coalesce(author_nickname, '브루스팟 사용자')
where author_nickname is null;

alter table public.reviews alter column author_nickname set not null;

create table if not exists public.bookmarks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  cafe_id uuid not null references public.cafes(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, cafe_id)
);

alter table public.bookmarks add column if not exists created_at timestamptz not null default now();

create index if not exists idx_user_identities_user_id on public.user_identities(user_id);
create index if not exists idx_reviews_cafe_id on public.reviews(cafe_id);
create index if not exists idx_reviews_user_id on public.reviews(user_id);
create index if not exists idx_bookmarks_user_id on public.bookmarks(user_id);
create index if not exists idx_bookmarks_cafe_id on public.bookmarks(cafe_id);

drop trigger if exists users_set_updated_at on public.users;
create trigger users_set_updated_at
before update on public.users
for each row execute function public.set_updated_at();

drop trigger if exists cafes_set_updated_at on public.cafes;
create trigger cafes_set_updated_at
before update on public.cafes
for each row execute function public.set_updated_at();

drop trigger if exists reviews_set_updated_at on public.reviews;
create trigger reviews_set_updated_at
before update on public.reviews
for each row execute function public.set_updated_at();

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  derived_nickname text;
begin
  derived_nickname :=
    coalesce(
      new.raw_user_meta_data ->> 'nickname',
      split_part(coalesce(new.email, ''), '@', 1),
      'brewspot_user'
    );

  if exists (
    select 1
    from public.users
    where nickname = left(derived_nickname, 30)
      and id <> new.id
  ) then
    derived_nickname := left(left(derived_nickname, 23) || '_' || left(replace(new.id::text, '-', ''), 6), 30);
  end if;

  insert into public.users (id, nickname, email, profile_image_url)
  values (
    new.id,
    left(derived_nickname, 30),
    new.email,
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do update
    set nickname = excluded.nickname,
        email = excluded.email,
        profile_image_url = coalesce(excluded.profile_image_url, public.users.profile_image_url),
        updated_at = now();

  insert into public.user_identities (user_id, provider, provider_user_id, provider_email)
  select
    new.id,
    coalesce(identity.value ->> 'provider', 'email'),
    coalesce(identity.value ->> 'id', new.id::text),
    coalesce(identity.value ->> 'email', new.email)
  from jsonb_array_elements(coalesce(new.identities, '[]'::jsonb)) as identity(value)
  on conflict (provider, provider_user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

create or replace function public.refresh_cafe_review_stats()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_cafe_id uuid;
begin
  target_cafe_id := coalesce(new.cafe_id, old.cafe_id);

  update public.cafes
  set
    avg_rating = coalesce((
      select round(avg(overall_rating)::numeric, 1)
      from public.reviews
      where cafe_id = target_cafe_id
    ), 0.0),
    review_count = (
      select count(*)
      from public.reviews
      where cafe_id = target_cafe_id
    ),
    updated_at = now()
  where id = target_cafe_id;

  return coalesce(new, old);
end;
$$;

drop trigger if exists reviews_refresh_cafe_stats on public.reviews;
create trigger reviews_refresh_cafe_stats
after insert or update or delete on public.reviews
for each row execute function public.refresh_cafe_review_stats();

alter table public.users enable row level security;
alter table public.user_identities enable row level security;
alter table public.cafes enable row level security;
alter table public.reviews enable row level security;
alter table public.bookmarks enable row level security;

drop policy if exists "Users can read their own profile" on public.users;
create policy "Users can read their own profile"
on public.users
for select
to authenticated
using (auth.uid() = id);

drop policy if exists "Users can insert their own profile" on public.users;
create policy "Users can insert their own profile"
on public.users
for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "Users can update their own profile" on public.users;
create policy "Users can update their own profile"
on public.users
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "Users can read their identities" on public.user_identities;
create policy "Users can read their identities"
on public.user_identities
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert their identities" on public.user_identities;
create policy "Users can insert their identities"
on public.user_identities
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Public can read cafes" on public.cafes;
create policy "Public can read cafes"
on public.cafes
for select
to anon, authenticated
using (true);

drop policy if exists "Public can read reviews" on public.reviews;
create policy "Public can read reviews"
on public.reviews
for select
to anon, authenticated
using (true);

drop policy if exists "Users can insert their own reviews" on public.reviews;
create policy "Users can insert their own reviews"
on public.reviews
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update their own reviews" on public.reviews;
create policy "Users can update their own reviews"
on public.reviews
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own reviews" on public.reviews;
create policy "Users can delete their own reviews"
on public.reviews
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can read their bookmarks" on public.bookmarks;
create policy "Users can read their bookmarks"
on public.bookmarks
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert their bookmarks" on public.bookmarks;
create policy "Users can insert their bookmarks"
on public.bookmarks
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can delete their bookmarks" on public.bookmarks;
create policy "Users can delete their bookmarks"
on public.bookmarks
for delete
to authenticated
using (auth.uid() = user_id);

insert into public.cafes (
  id,
  name,
  address,
  category,
  city,
  latitude,
  longitude,
  signature_menu_name,
  signature_menu_price,
  price_note,
  short_description,
  vibe_tags,
  features,
  open_hours
) values
  (
    'c31f7050-5677-49d1-a3e0-df0c3b0fb001',
    '성수커피',
    '서울 성동구 성수동',
    '스페셜티',
    '성수',
    37.5445000,
    127.0561000,
    '플랫화이트',
    6500,
    '1인 7천원대',
    '균형 잡힌 원두와 차분한 좌석감이 강점인 스페셜티 카페',
    array['조용한', '작업하기 좋은', '원두 맛집'],
    array['에스프레소 베이스 음료 만족도가 높아요.', '혼자 방문하기 좋은 좌석 배치예요.', '짧게 머물며 커피를 즐기기 좋아요.'],
    '매일 10:00 - 21:00'
  ),
  (
    'c31f7050-5677-49d1-a3e0-df0c3b0fb002',
    '레이어드빈 성수',
    '서울 성동구 연무장길 23',
    '디저트',
    '성수',
    37.5458000,
    127.0552000,
    '바닐라빈 라떼',
    7000,
    '1인 9천원대',
    '층고 높은 공간감과 디저트 조합이 강점인 성수 감성 카페',
    array['디저트 맛집', '사진이 잘 나오는', '대화하기 좋은'],
    array['좌석이 넉넉해 2~3인 방문 만족도가 높아요.', '디저트와 커피 조합이 좋아 첫 방문 만족감이 커요.', '주말 오후에는 대기가 있을 수 있어요.'],
    '매일 11:00 - 22:00'
  ),
  (
    'c31f7050-5677-49d1-a3e0-df0c3b0fb003',
    '연남카페',
    '서울 마포구 연남동',
    '로스팅',
    '연남',
    37.5651000,
    126.9234000,
    '시그니처 라떼',
    6800,
    '1인 8천원대',
    '직접 로스팅한 원두 풍미와 밝은 무드가 살아 있는 로스터리',
    array['대화하기 좋은', '향이 좋은', '데이트 추천'],
    array['향 중심 원두를 좋아하면 만족도가 높아요.', '매장 분위기가 밝고 사진이 잘 나와요.', '주말에는 다소 붐빌 수 있어요.'],
    '매일 11:00 - 22:00'
  ),
  (
    'c31f7050-5677-49d1-a3e0-df0c3b0fb004',
    '골목필터 연남',
    '서울 마포구 동교로38길 18',
    '필터커피',
    '연남',
    37.5638000,
    126.9261000,
    '에티오피아 핸드드립',
    7500,
    '1인 8천원대',
    '필터 커피 선택 폭이 넓고 조용히 머물기 좋은 연남 골목 카페',
    array['조용한', '핸드드립', '혼자 가기 좋은'],
    array['원두 설명이 친절해서 취향 탐색에 좋아요.', '혼자 앉기 좋은 바 좌석이 있어요.', '대화보다는 커피 맛에 집중하기 좋은 분위기예요.'],
    '월-토 12:00 - 20:30'
  ),
  (
    'c31f7050-5677-49d1-a3e0-df0c3b0fb005',
    '망원카페',
    '서울 마포구 망원동',
    '브런치',
    '망원',
    37.5565000,
    126.9018000,
    '브런치 플레이트',
    12000,
    '1인 1만원대',
    '브런치와 커피를 함께 즐기기 좋은 여유로운 동네 카페',
    array['브런치', '주말 방문', '친구와 가기 좋은'],
    array['식사와 커피를 한 번에 해결하기 편해요.', '테이블 간격이 적당해 모임에 좋아요.', '오전 시간대 방문 만족도가 높아요.'],
    '화-일 09:00 - 20:00'
  ),
  (
    'c31f7050-5677-49d1-a3e0-df0c3b0fb006',
    '포인트오브뷰 망원',
    '서울 마포구 포은로 91',
    '작업형',
    '망원',
    37.5552000,
    126.9031000,
    '오트 라떼',
    6500,
    '1인 7천원대',
    '넓은 테이블과 차분한 소음도로 작업 수요가 높은 망원 카페',
    array['작업하기 좋은', '노트북 친화', '오래 머물기 좋은'],
    array['콘센트 좌석이 있어 작업 목적 방문이 많아요.', '오트 라떼와 디카페인 옵션 만족도가 좋아요.', '피크타임엔 노트북 좌석 경쟁이 있을 수 있어요.'],
    '매일 10:30 - 21:30'
  )
on conflict (name, address) do update
set
  category = excluded.category,
  city = excluded.city,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  signature_menu_name = excluded.signature_menu_name,
  signature_menu_price = excluded.signature_menu_price,
  price_note = excluded.price_note,
  short_description = excluded.short_description,
  vibe_tags = excluded.vibe_tags,
  features = excluded.features,
  open_hours = excluded.open_hours,
  updated_at = now();

comment on table public.users is '서비스 사용자 기본 정보';
comment on table public.user_identities is '이메일, Google 등 로그인 연결 정보';
comment on table public.cafes is '카페 기본 정보';
comment on table public.reviews is '카페 리뷰';
comment on table public.bookmarks is '사용자 저장 카페';
