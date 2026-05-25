-- BrewSpot home barista post seed
-- Run this after SUPABASE_MINI_SCHEMA.sql
-- Make sure test accounts already exist in public.users
-- Safe to re-run because matching seeded posts are deleted before insert

with seed_posts as (
  select *
  from (
    values
      (
        'test3@brewspot.app',
        '모닝브루',
        'V60',
        '성수 블렌드로 가볍게 내리는 아침 레시피',
        'BrewSpot House Blend',
        '15g : 240ml / 2분 30초',
        '첫 모금은 견과류 느낌이 부드럽고, 식으면서 은은한 초콜릿 뉘앙스가 올라와요.',
        '40ml bloom 30초 후 100ml, 180ml, 240ml 순서로 나눠 부었어요. 물줄기는 중앙보다 살짝 바깥쪽이 더 안정적이었어요.',
        '2026-05-20T08:20:00+09:00'::timestamptz
      ),
      (
        'test2@brewspot.app',
        '원두메모',
        '에어로프레스',
        '산미 줄이고 단맛 살린 에어로프레스',
        'Ethiopia Guji',
        '17g : 220ml / 1분 50초',
        '산미가 너무 튀지 않고 복숭아 같은 단맛이 뒤에 남아요. 점심 이후에도 부담이 적었어요.',
        '역방향으로 1분 침출 후 천천히 20초 프레스했어요. 물 온도는 88도 쪽이 훨씬 편안했어요.',
        '2026-05-19T09:40:00+09:00'::timestamptz
      ),
      (
        'test6@brewspot.app',
        '집중모드',
        '콜드브루',
        '주말용 콜드브루 베이스 비율 공유',
        'Brazil Cerrado',
        '80g : 800ml / 14시간',
        '우유와 섞어도 맛이 흐려지지 않고, 단맛이 둥글게 남아요.',
        '굵은 분쇄로 냉장 침출했고, 원액 기준이라 마실 때는 얼음이나 물로 1:1 정도 희석했어요.',
        '2026-05-18T21:10:00+09:00'::timestamptz
      )
  ) as t(
    user_email,
    author_nickname,
    brew_method,
    title,
    bean_name,
    ratio_note,
    tasting_note,
    brew_note,
    created_at
  )
),
deleted_seeded_posts as (
  delete from public.homebarista_posts p
  using seed_posts s
  join public.users u
    on u.email = s.user_email
  where p.user_id = u.id
    and p.title = s.title
    and p.created_at = s.created_at
  returning p.id
)
insert into public.homebarista_posts (
  user_id,
  author_nickname,
  brew_method,
  title,
  bean_name,
  ratio_note,
  tasting_note,
  brew_note,
  created_at,
  updated_at
)
select
  u.id,
  s.author_nickname,
  s.brew_method,
  s.title,
  s.bean_name,
  s.ratio_note,
  s.tasting_note,
  s.brew_note,
  s.created_at,
  s.created_at
from seed_posts s
join public.users u
  on u.email = s.user_email;
