-- ---------------------------------------------------------------------------
-- Migration: 20260817000002_sudut_info_posts.sql
-- Description: Creates public.sudut_info_posts table for scheduled Sudut Info announcements.
-- ---------------------------------------------------------------------------

create table if not exists public.sudut_info_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid references public.profiles(id) on delete set null,
  category text not null default 'umum', -- 'disiplin', 'kaunseling', 'sahsiah', 'sekolah', 'umum'
  title text not null,
  content text not null,
  managed_by text not null default 'Unit Disiplin & Kaunseling',
  is_published boolean not null default true,
  valid_from timestamptz not null default now(),
  valid_until timestamptz, -- null means valid indefinitely
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Indices
create index if not exists idx_sudut_info_category on public.sudut_info_posts(category);
create index if not exists idx_sudut_info_published on public.sudut_info_posts(is_published);
create index if not exists idx_sudut_info_validity on public.sudut_info_posts(valid_from, valid_until);
create index if not exists idx_sudut_info_created on public.sudut_info_posts(created_at desc);

-- RLS
alter table public.sudut_info_posts enable row level security;

drop policy if exists "public_read_active_sudut_info" on public.sudut_info_posts;
create policy "public_read_active_sudut_info"
  on public.sudut_info_posts for select
  to authenticated, anon
  using (
    is_published = true
    and valid_from <= now()
    and (valid_until is null or valid_until >= now())
  );

drop policy if exists "authenticated_manage_sudut_info" on public.sudut_info_posts;
create policy "authenticated_manage_sudut_info"
  on public.sudut_info_posts for all
  to authenticated
  using (true)
  with check (true);

-- RPC to get active Sudut Info posts
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
