-- BrewSpot community post seed
-- Run this after SUPABASE_MINI_SCHEMA.sql
-- Make sure test accounts already exist in public.users
-- Safe to re-run because matching seeded posts are deleted before insert

with seed_posts as (
  select *
  from (
    values
      (
        'test10@brewspot.app',
        '드립메모',
        '추천',
        '성수에서 오래 머물기 좋은 카페 추천해요',
        '콘센트 자리 넉넉하고 음악이 너무 시끄럽지 않은 곳 위주로 골라봤어요. 평일 오후 기준으로는 창가보다 안쪽 긴 테이블 쪽이 훨씬 편했어요.',
        '성수',
        18,
        4,
        '2026-05-20T10:30:00+09:00'::timestamptz
      ),
      (
        'test14@brewspot.app',
        '카페산책',
        '자유',
        '연남 카페 투어 동선 이렇게 잡아도 괜찮을까요?',
        '오후 2시쯤 시작해서 3곳 정도만 천천히 돌고 싶어요. 디저트보다는 커피 맛 중심으로 보고 있고, 이동은 도보 기준이에요.',
        '연남',
        9,
        7,
        '2026-05-19T14:10:00+09:00'::timestamptz
      ),
      (
        'test18@brewspot.app',
        '동네기록',
        '질문',
        '망원에서 디카페인 괜찮은 곳 있나요?',
        '저녁에도 부담 없이 마시고 싶어서 디카페인 원두 퀄리티 괜찮은 곳 찾고 있어요. 산미가 너무 강하지 않으면 더 좋겠습니다.',
        '망원',
        6,
        2,
        '2026-05-18T19:20:00+09:00'::timestamptz
      )
  ) as t(
    user_email,
    author_nickname,
    board_type,
    title,
    content,
    city,
    like_count,
    comment_count,
    created_at
  )
),
deleted_seeded_posts as (
  delete from public.community_posts p
  using seed_posts s
  join public.users u
    on u.email = s.user_email
  where p.user_id = u.id
    and p.title = s.title
    and p.created_at = s.created_at
  returning p.id
)
insert into public.community_posts (
  user_id,
  author_nickname,
  board_type,
  title,
  content,
  city,
  like_count,
  comment_count,
  created_at,
  updated_at
)
select
  u.id,
  s.author_nickname,
  s.board_type,
  s.title,
  s.content,
  s.city,
  s.like_count,
  s.comment_count,
  s.created_at,
  s.created_at
from seed_posts s
join public.users u
  on u.email = s.user_email;
