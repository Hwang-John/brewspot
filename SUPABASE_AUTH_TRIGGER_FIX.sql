-- BrewSpot auth trigger fix
-- Use this when email signup returns "Database error saving new user"
-- This updates the auth -> public profile trigger to avoid relying on auth.users.identities

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
  values (
    new.id,
    coalesce(new.raw_app_meta_data ->> 'provider', 'email'),
    new.id::text,
    new.email
  )
  on conflict (provider, provider_user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();
