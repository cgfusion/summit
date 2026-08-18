-- ---------------------------------------------------------------------------
-- Migration: 20260818000001_add_image_url_to_sudut_info.sql
-- Description: Adds image_url column to public.sudut_info_posts for poster/banner graphics.
-- ---------------------------------------------------------------------------

alter table public.sudut_info_posts
  add column if not exists image_url text;

-- Storage bucket for Sudut Info Banners (if not exists)
insert into storage.buckets (id, name, public)
values ('sudut-info-banners', 'sudut-info-banners', true)
on conflict (id) do nothing;

drop policy if exists "Public access to sudut-info-banners" on storage.objects;
create policy "Public access to sudut-info-banners"
  on storage.objects for select
  to public
  using (bucket_id = 'sudut-info-banners');

drop policy if exists "Authenticated insert to sudut-info-banners" on storage.objects;
create policy "Authenticated insert to sudut-info-banners"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'sudut-info-banners');

-- Update RPC function fn_active_sudut_info_posts to return image_url
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
