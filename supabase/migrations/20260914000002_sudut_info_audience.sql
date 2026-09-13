-- ---------------------------------------------------------------------------
-- Migration: 20260914000002_sudut_info_audience.sql
-- Description: Adds an audience field to sudut_info_posts so staff can target
-- a post at students, parents/guardians, or both. Requested after Sudut Info
-- moved off the public Landing Page and into the Student Portal and Parent
-- Portal specifically -- those two audiences should not necessarily see the
-- same posts.
-- ---------------------------------------------------------------------------

alter table public.sudut_info_posts
  add column if not exists audience text not null default 'kedua_dua';

alter table public.sudut_info_posts
  drop constraint if exists sudut_info_posts_audience_check;
alter table public.sudut_info_posts
  add constraint sudut_info_posts_audience_check
  check (audience in ('murid', 'ibu_bapa', 'kedua_dua'));

create index if not exists idx_sudut_info_audience on public.sudut_info_posts(audience);

-- Keep the RPC in sync (not currently called by the Flutter app for this
-- table -- getSudutInfoPosts reads the table directly -- but kept accurate
-- for any future/external caller).
create or replace function public.fn_active_sudut_info_posts()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_result jsonb;
begin
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', p.id,
        'category', p.category,
        'audience', p.audience,
        'title', p.title,
        'content', p.content,
        'image_url', p.image_url,
        'managed_by', p.managed_by,
        'is_published', p.is_published,
        'valid_from', p.valid_from,
        'valid_until', p.valid_until,
        'created_at', p.created_at,
        'author_name', prof.full_name
      )
      order by p.created_at desc
    ),
    '[]'::jsonb
  )
  into v_result
  from public.sudut_info_posts p
  left join public.profiles prof on prof.id = p.author_id
  where p.is_published = true
    and p.valid_from <= now()
    and (p.valid_until is null or p.valid_until >= now());

  return v_result;
end;
$$;
