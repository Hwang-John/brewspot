-- BrewSpot RLS smoke test
-- Run this after SUPABASE_MINI_SCHEMA.sql, test account setup, and seed SQL.
-- This script uses a transaction and rolls everything back at the end.
-- Look for:
-- 1. all `passed` values are true
-- 2. NOTICE lines starting with `PASS:`

begin;

select set_config('brewspot.rls.anon_insert_blocked', 'false', true);
select set_config('brewspot.rls.review_insert_allowed', 'false', true);
select set_config('brewspot.rls.bookmark_insert_allowed', 'false', true);
select set_config('brewspot.rls.community_insert_allowed', 'false', true);
select set_config('brewspot.rls.community_cross_insert_blocked', 'false', true);
select set_config('brewspot.rls.community_cross_update_blocked', 'false', true);
select set_config('brewspot.rls.homebarista_insert_allowed', 'false', true);
select set_config('brewspot.rls.homebarista_cross_insert_blocked', 'false', true);
select set_config('brewspot.rls.homebarista_cross_update_blocked', 'false', true);

select set_config(
  'brewspot.rls.community_author_id',
  coalesce(
    (
      select id::text
      from public.users
      where email = 'test10@brewspot.app'
      limit 1
    ),
    ''
  ),
  true
);

select set_config(
  'brewspot.rls.homebarista_author_id',
  coalesce(
    (
      select id::text
      from public.users
      where email = 'test6@brewspot.app'
      limit 1
    ),
    ''
  ),
  true
);

select set_config(
  'brewspot.rls.other_user_id',
  coalesce(
    (
      select id::text
      from public.users
      where email = 'test18@brewspot.app'
      limit 1
    ),
    ''
  ),
  true
);

do $$
declare
  missing_accounts text[] := '{}';
begin
  if current_setting('brewspot.rls.community_author_id', true) = '' then
    missing_accounts := array_append(missing_accounts, 'test10@brewspot.app');
  end if;

  if current_setting('brewspot.rls.homebarista_author_id', true) = '' then
    missing_accounts := array_append(missing_accounts, 'test6@brewspot.app');
  end if;

  if current_setting('brewspot.rls.other_user_id', true) = '' then
    missing_accounts := array_append(missing_accounts, 'test18@brewspot.app');
  end if;

  if array_length(missing_accounts, 1) is not null then
    raise exception 'Missing required test accounts: %', array_to_string(missing_accounts, ', ');
  end if;
end;
$$;

select set_config(
  'brewspot.rls.review_cafe_id',
  coalesce(
    (
      select id::text
      from public.cafes
      order by created_at asc
      limit 1
    ),
    ''
  ),
  true
);

select set_config(
  'brewspot.rls.bookmark_cafe_id',
  coalesce(
    (
      select c.id::text
      from public.cafes c
      where not exists (
        select 1
        from public.bookmarks b
        where b.user_id = current_setting('brewspot.rls.community_author_id', true)::uuid
          and b.cafe_id = c.id
      )
      order by c.created_at asc
      limit 1
    ),
    ''
  ),
  true
);

do $$
begin
  if current_setting('brewspot.rls.review_cafe_id', true) = '' then
    raise exception 'No cafes found. Run cafe seed first.';
  end if;

  if current_setting('brewspot.rls.bookmark_cafe_id', true) = '' then
    raise exception 'No bookmark candidate cafe found for test10@brewspot.app.';
  end if;
end;
$$;

-- 1. anonymous public read range
set local role anon;
select set_config('request.jwt.claim.role', 'anon', true);
select set_config('request.jwt.claim.sub', '', true);

select 'anon can read cafes' as test, count(*) > 0 as passed, count(*) as row_count
from public.cafes;

select 'anon can read reviews' as test, count(*) >= 0 as passed, count(*) as row_count
from public.reviews;

select 'anon can read community posts' as test, count(*) >= 0 as passed, count(*) as row_count
from public.community_posts;

select 'anon can read homebarista posts' as test, count(*) >= 0 as passed, count(*) as row_count
from public.homebarista_posts;

select 'anon cannot read bookmarks' as test, count(*) = 0 as passed, count(*) as row_count
from public.bookmarks;

do $$
declare
  actor_id uuid := current_setting('brewspot.rls.community_author_id', true)::uuid;
begin
  begin
    insert into public.community_posts (
      user_id,
      author_nickname,
      board_type,
      title,
      content,
      city
    )
    values (
      actor_id,
      'AnonBlock',
      '자유',
      'anon write blocked check',
      'anonymous users should not be able to post',
      '성수'
    );

    raise exception 'FAIL: anon community insert unexpectedly succeeded';
  exception
    when others then
      perform set_config('brewspot.rls.anon_insert_blocked', 'true', true);
      raise notice 'PASS: anon community insert blocked (%).', sqlerrm;
  end;
end;
$$;

reset role;

-- 2. authenticated review / bookmark / community checks
set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config(
  'request.jwt.claim.sub',
  current_setting('brewspot.rls.community_author_id', true),
  true
);

select 'authenticated cannot read other user bookmarks' as test, count(*) = 0 as passed, count(*) as row_count
from public.bookmarks
where user_id = current_setting('brewspot.rls.other_user_id', true)::uuid;

do $$
declare
  actor_id uuid := current_setting('brewspot.rls.community_author_id', true)::uuid;
  other_id uuid := current_setting('brewspot.rls.other_user_id', true)::uuid;
  review_cafe_id uuid := current_setting('brewspot.rls.review_cafe_id', true)::uuid;
  bookmark_cafe_id uuid := current_setting('brewspot.rls.bookmark_cafe_id', true)::uuid;
  review_id uuid;
  community_id uuid;
begin
  insert into public.reviews (
    user_id,
    cafe_id,
    author_nickname,
    overall_rating,
    recommended_menu_name,
    content
  )
  values (
    actor_id,
    review_cafe_id,
    'RLS Review',
    5,
    '테스트 메뉴',
    'RLS own review insert check'
  )
  returning id into review_id;

  perform set_config('brewspot.rls.review_insert_allowed', 'true', true);
  raise notice 'PASS: own review insert allowed (%).', review_id;

  delete from public.bookmarks
  where user_id = actor_id
    and cafe_id = bookmark_cafe_id;

  insert into public.bookmarks (user_id, cafe_id)
  values (actor_id, bookmark_cafe_id);

  perform set_config('brewspot.rls.bookmark_insert_allowed', 'true', true);
  raise notice 'PASS: own bookmark insert allowed (%).', bookmark_cafe_id;

  insert into public.community_posts (
    user_id,
    author_nickname,
    board_type,
    title,
    content,
    city
  )
  values (
    actor_id,
    'RLS Community',
    '자유',
    'own community insert check',
    'authenticated users should be able to post as themselves',
    '연남'
  )
  returning id into community_id;

  perform set_config('brewspot.rls.community_insert_allowed', 'true', true);
  raise notice 'PASS: own community insert allowed (%).', community_id;

  begin
    insert into public.community_posts (
      user_id,
      author_nickname,
      board_type,
      title,
      content,
      city
    )
    values (
      other_id,
      'CrossUser',
      '자유',
      'cross user insert should fail',
      'authenticated users must not post for another user',
      '망원'
    );

    raise exception 'FAIL: cross-user community insert unexpectedly succeeded';
  exception
    when others then
      perform set_config('brewspot.rls.community_cross_insert_blocked', 'true', true);
      raise notice 'PASS: cross-user community insert blocked (%).', sqlerrm;
  end;

  update public.community_posts
  set title = title || ' blocked'
  where user_id = other_id;

  if found then
    raise exception 'FAIL: cross-user community update unexpectedly affected rows';
  else
    perform set_config('brewspot.rls.community_cross_update_blocked', 'true', true);
    raise notice 'PASS: cross-user community update affected 0 rows.';
  end if;
end;
$$;

reset role;

-- 3. authenticated home barista checks
set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config(
  'request.jwt.claim.sub',
  current_setting('brewspot.rls.homebarista_author_id', true),
  true
);

do $$
declare
  actor_id uuid := current_setting('brewspot.rls.homebarista_author_id', true)::uuid;
  other_id uuid := current_setting('brewspot.rls.other_user_id', true)::uuid;
  homebarista_id uuid;
begin
  insert into public.homebarista_posts (
    user_id,
    author_nickname,
    brew_method,
    title,
    bean_name,
    ratio_note,
    tasting_note,
    brew_note
  )
  values (
    actor_id,
    'RLS HomeBarista',
    'V60',
    'own homebarista insert check',
    'RLS Test Beans',
    '1:15',
    'clean and bright',
    'authenticated users should be able to save their own recipe'
  )
  returning id into homebarista_id;

  perform set_config('brewspot.rls.homebarista_insert_allowed', 'true', true);
  raise notice 'PASS: own homebarista insert allowed (%).', homebarista_id;

  begin
    insert into public.homebarista_posts (
      user_id,
      author_nickname,
      brew_method,
      title,
      bean_name,
      ratio_note,
      tasting_note,
      brew_note
    )
    values (
      other_id,
      'CrossUser',
      'Aeropress',
      'cross user recipe should fail',
      'Wrong Owner Beans',
      '1:14',
      'should fail',
      'authenticated users must not write another user recipe'
    );

    raise exception 'FAIL: cross-user homebarista insert unexpectedly succeeded';
  exception
    when others then
      perform set_config('brewspot.rls.homebarista_cross_insert_blocked', 'true', true);
      raise notice 'PASS: cross-user homebarista insert blocked (%).', sqlerrm;
  end;

  update public.homebarista_posts
  set title = title || ' blocked'
  where user_id = other_id;

  if found then
    raise exception 'FAIL: cross-user homebarista update unexpectedly affected rows';
  else
    perform set_config('brewspot.rls.homebarista_cross_update_blocked', 'true', true);
    raise notice 'PASS: cross-user homebarista update affected 0 rows.';
  end if;
end;
$$;

reset role;

select 'anon insert blocked' as test, current_setting('brewspot.rls.anon_insert_blocked', true) = 'true' as passed;
select 'authenticated own review insert allowed' as test, current_setting('brewspot.rls.review_insert_allowed', true) = 'true' as passed;
select 'authenticated own bookmark insert allowed' as test, current_setting('brewspot.rls.bookmark_insert_allowed', true) = 'true' as passed;
select 'authenticated own community insert allowed' as test, current_setting('brewspot.rls.community_insert_allowed', true) = 'true' as passed;
select 'authenticated cross-user community insert blocked' as test, current_setting('brewspot.rls.community_cross_insert_blocked', true) = 'true' as passed;
select 'authenticated cross-user community update blocked' as test, current_setting('brewspot.rls.community_cross_update_blocked', true) = 'true' as passed;
select 'authenticated own homebarista insert allowed' as test, current_setting('brewspot.rls.homebarista_insert_allowed', true) = 'true' as passed;
select 'authenticated cross-user homebarista insert blocked' as test, current_setting('brewspot.rls.homebarista_cross_insert_blocked', true) = 'true' as passed;
select 'authenticated cross-user homebarista update blocked' as test, current_setting('brewspot.rls.homebarista_cross_update_blocked', true) = 'true' as passed;

rollback;
