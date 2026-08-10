-- ---------------------------------------------------------------------------
-- Migration: 20260811000003_student_voice.sql
-- Description: Creates student_voice_submissions table and fn_student_portal_data_by_qr
-- RPC for QR-authenticated student portal & Suara Murid feedback.
-- ---------------------------------------------------------------------------

-- 1. Student Voice Submissions Table (Suara Murid / Aduan & Cadangan)
create table if not exists public.student_voice_submissions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid references public.students(id) on delete set null,
  category text not null, -- 'cadangan_sekolah', 'maklum_balas_pembelajaran', 'aduan_buli_keselamatan', 'permohonan_kaunseling'
  is_anonymous boolean not null default false,
  subject text not null,
  message text not null,
  status text not null default 'baru', -- 'baru', 'dalam_tindakan', 'selesai'
  response_notes text,
  responded_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Indices
create index if not exists idx_student_voice_student on public.student_voice_submissions(student_id);
create index if not exists idx_student_voice_status on public.student_voice_submissions(status);
create index if not exists idx_student_voice_date on public.student_voice_submissions(created_at desc);

-- RLS
alter table public.student_voice_submissions enable row level security;

drop policy if exists "public_read_voice" on public.student_voice_submissions;
create policy "public_read_voice"
  on public.student_voice_submissions for select
  to authenticated, anon using (true);

drop policy if exists "public_insert_voice" on public.student_voice_submissions;
create policy "public_insert_voice"
  on public.student_voice_submissions for insert
  to authenticated, anon with check (true);

drop policy if exists "authenticated_update_voice" on public.student_voice_submissions;
create policy "authenticated_update_voice"
  on public.student_voice_submissions for update
  to authenticated using (true) with check (true);

-- 2. RPC: Resolve Student Portal Data by QR Code Token
create or replace function public.fn_student_portal_data_by_qr(p_qr_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_student_id uuid;
  v_student record;
  v_class_name text;
  v_today date := current_date;
  v_month_start date := date_trunc('month', current_date)::date;
  v_month_end date := (date_trunc('month', current_date) + interval '1 month - 1 day')::date;
  v_total_days bigint;
  v_days_present bigint;
  v_days_absent bigint;
  v_attendance_rate numeric;
  v_total_merit bigint;
  v_recent_attendance jsonb;
  v_submissions jsonb;
begin
  if p_qr_token is null or trim(p_qr_token) = '' then
    return null;
  end if;

  -- 1. Resolve student by QR token in student_qr_cards or students table
  select s.id, s.full_name, s.class_id, s.ic_number, s.enrollment_status
  into v_student
  from public.students s
  left join public.student_qr_cards sqc on sqc.student_id = s.id
  where sqc.token = trim(p_qr_token)
     or sqc.card_number = trim(p_qr_token)
     or s.id::text = trim(p_qr_token)
     or (s.ic_number is not null and regexp_replace(s.ic_number, '\D', '', 'g') = regexp_replace(p_qr_token, '\D', '', 'g'))
  limit 1;

  if v_student.id is null then
    return null;
  end if;

  v_student_id := v_student.id;

  select name into v_class_name
  from public.classes where id = v_student.class_id;

  -- 2. Attendance Summary
  select
    count(*),
    count(*) filter (where status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')),
    count(*) filter (where status = 'tidak_hadir')
  into v_total_days, v_days_present, v_days_absent
  from public.attendance_days
  where student_id = v_student_id;

  if v_total_days = 0 then
    v_attendance_rate := 100.0;
  else
    v_attendance_rate := round(v_days_present::numeric / v_total_days * 100, 1);
  end if;

  -- 3. Merit points
  select coalesce(sum(total_points), 0)
  into v_total_merit
  from public.merit_student_daily
  where student_id = v_student_id;

  -- 4. Recent attendance history (last 30 days)
  select coalesce(jsonb_agg(
    jsonb_build_object('date', school_date, 'status', status) order by school_date desc
  ), '[]'::jsonb)
  into v_recent_attendance
  from (
    select school_date, status from public.attendance_days
    where student_id = v_student_id
    order by school_date desc
    limit 30
  ) x;

  -- 5. Student Voice Submissions history
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', id,
      'category', category,
      'is_anonymous', is_anonymous,
      'subject', subject,
      'message', message,
      'status', status,
      'response_notes', response_notes,
      'created_at', created_at
    ) order by created_at desc
  ), '[]'::jsonb)
  into v_submissions
  from public.student_voice_submissions
  where student_id = v_student_id;

  return jsonb_build_object(
    'student', jsonb_build_object(
      'id', v_student_id,
      'full_name', v_student.full_name,
      'class_name', coalesce(v_class_name, 'Tiada Kelas'),
      'enrollment_status', v_student.enrollment_status
    ),
    'attendance', jsonb_build_object(
      'total_days', v_total_days,
      'days_present', v_days_present,
      'days_absent', v_days_absent,
      'attendance_rate', v_attendance_rate
    ),
    'merit', jsonb_build_object(
      'total_points', v_total_merit
    ),
    'recent_attendance', v_recent_attendance,
    'submissions', v_submissions
  );
end;
$$;

grant execute on function public.fn_student_portal_data_by_qr(text) to authenticated, anon;
