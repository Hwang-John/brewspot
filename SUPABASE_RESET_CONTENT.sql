-- BrewSpot content reset for reseeding
-- Use this only when you want to replace existing cafe/review/bookmark content
-- This does not delete auth users. Remove test auth users manually in Supabase Dashboard if needed.

begin;

delete from public.bookmarks;
delete from public.reviews;
delete from public.cafes;

commit;

-- Optional follow-up checks
select count(*) as cafe_count from public.cafes;
select count(*) as review_count from public.reviews;
select count(*) as bookmark_count from public.bookmarks;
