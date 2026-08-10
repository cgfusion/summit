-- ---------------------------------------------------------------------------
-- Migration: 20260811000002_discipline_and_counseling.sql
-- Description: Creates discipline_records and counseling_records tables and RPCs
-- for Guru Disiplin, Guru Kaunselor (UBK), and Admin staff roles.
-- ---------------------------------------------------------------------------

-- 1. Disciplinary Records Table (SSDOP)
create table if not exists public.discipline_records (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id),
  incident_date date not null default current_date,
  category text not null, -- e.g. 'Ponteng Sekolah/Kelas', 'Tingkah Laku Kurang Sopan', 'Kekemasan Diri', 'Buli', 'Lain-lain'
  severity text not null default 'ringan', -- 'ringan', 'sederhana', 'berat'
  action_taken text, -- e.g. 'Nasihat', 'Amaran Lisan', 'Surat Amaran 1', 'Surat Amaran 2', 'Surat Amaran 3', 'Rujukan UBK'
  status text not null default 'dalam_siasatan', -- 'dalam_siasatan', 'dirujuk_ubk', 'selesai'
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. Counseling Records Table (UBK)
create table if not exists public.counseling_records (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  counselor_id uuid not null references public.profiles(id),
  discipline_record_id uuid references public.discipline_records(id) on delete set null,
  session_date date not null default current_date,
  session_type text not null default 'individu', -- 'individu', 'kelompok', 'ibu_bapa'
  focus_area text not null default 'sahsiah_disiplin', -- 'sahsiah_disiplin', 'akademik', 'kerjaya', 'psikososial'
  outcome_notes text,
  follow_up_status text not null default 'memerlukan_susulan', -- 'memerlukan_susulan', 'selesai'
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Indices for quick lookup
create index if not exists idx_discipline_records_student on public.discipline_records(student_id);
create index if not exists idx_discipline_records_date on public.discipline_records(incident_date desc);
create index if not exists idx_counseling_records_student on public.counseling_records(student_id);
create index if not exists idx_counseling_records_date on public.counseling_records(session_date desc);

-- RLS
alter table public.discipline_records enable row level security;
alter table public.counseling_records enable row level security;

create policy "authenticated_read_discipline"
  on public.discipline_records for select
  to authenticated using (true);

create policy "authenticated_manage_discipline"
  on public.discipline_records for all
  to authenticated using (true) with check (true);

create policy "authenticated_read_counseling"
  on public.counseling_records for select
  to authenticated using (true);

create policy "authenticated_manage_counseling"
  on public.counseling_records for all
  to authenticated using (true) with check (true);

-- 3. RPC: Student Discipline & Counseling Summary for Student Detail Sheet
create or replace function public.fn_student_discipline_summary(p_student_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_discipline_count int;
  v_counseling_count int;
  v_latest_action text;
  v_active_warning text;
begin
  select count(*), coalesce(max(action_taken), 'Tiada Tindakan')
  into v_discipline_count, v_latest_action
  from public.discipline_records
  where student_id = p_student_id;

  select count(*)
  into v_counseling_count
  from public.counseling_records
  where student_id = p_student_id;

  select action_taken
  into v_active_warning
  from public.discipline_records
  where student_id = p_student_id
    and action_taken like 'Surat Amaran%'
  order by created_at desc
  limit 1;

  return jsonb_build_object(
    'discipline_count', coalesce(v_discipline_count, 0),
    'counseling_count', coalesce(v_counseling_count, 0),
    'latest_action', coalesce(v_latest_action, '-'),
    'active_warning', coalesce(v_active_warning, 'Tiada Kes Tertunggak')
  );
end;
$$;

grant execute on function public.fn_student_discipline_summary(uuid) to authenticated, anon;
