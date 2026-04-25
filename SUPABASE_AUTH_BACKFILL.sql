-- BrewSpot auth -> public profile backfill
-- Use this when auth.users exists but public.users / public.user_identities is missing rows
-- Safe to re-run because it only inserts missing profiles and identities,
-- and fills null profile fields from auth.users where possible.

do $$
declare
  auth_user_record record;
  derived_nickname text;
begin
  for auth_user_record in
    select
      au.id,
      au.email,
      au.raw_user_meta_data,
      au.raw_app_meta_data
    from auth.users au
    left join public.users pu
      on pu.id = au.id
    where pu.id is null
    order by au.created_at asc, au.id asc
  loop
    derived_nickname :=
      coalesce(
        auth_user_record.raw_user_meta_data ->> 'nickname',
        nullif(split_part(coalesce(auth_user_record.email, ''), '@', 1), ''),
        'brewspot_user'
      );

    if exists (
      select 1
      from public.users
      where nickname = left(derived_nickname, 30)
        and id <> auth_user_record.id
    ) then
      derived_nickname := left(
        left(derived_nickname, 23) || '_' || left(replace(auth_user_record.id::text, '-', ''), 6),
        30
      );
    else
      derived_nickname := left(derived_nickname, 30);
    end if;

    insert into public.users (
      id,
      nickname,
      email,
      profile_image_url
    )
    values (
      auth_user_record.id,
      derived_nickname,
      auth_user_record.email,
      auth_user_record.raw_user_meta_data ->> 'avatar_url'
    )
    on conflict (id) do nothing;
  end loop;
end;
$$;

update public.users pu
set
  email = coalesce(pu.email, au.email),
  profile_image_url = coalesce(pu.profile_image_url, au.raw_user_meta_data ->> 'avatar_url'),
  updated_at = now()
from auth.users au
where pu.id = au.id
  and (
    pu.email is null
    or (pu.profile_image_url is null and au.raw_user_meta_data ->> 'avatar_url' is not null)
  );

insert into public.user_identities (
  user_id,
  provider,
  provider_user_id,
  provider_email
)
select
  au.id,
  coalesce(au.raw_app_meta_data ->> 'provider', 'email'),
  au.id::text,
  au.email
from auth.users au
join public.users pu
  on pu.id = au.id
on conflict (provider, provider_user_id) do nothing;
