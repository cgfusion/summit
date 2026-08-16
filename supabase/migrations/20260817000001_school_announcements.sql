-- ---------------------------------------------------------------------------
-- Migration: 20260817000001_school_announcements.sql
-- Description: Creates school_announcements table and updates fn_student_portal_data_by_qr
-- to return live Discipline and Counseling (UBK) announcements for students.
-- ---------------------------------------------------------------------------

-- 1. School Announcements Table
create table if not exists public.school_announcements (
  id uuid primary key default gen_random_uuid(),
  author_id uuid references public.profiles(id) on delete set null,
  category text not null, -- 'disiplin' or 'kaunseling'
  title text not null,
  content text not null,
  target_student_id uuid references public.students(id) on delete set null,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Indices
create index if not exists idx_school_announcements_category on public.school_announcements(category);
create index if not exists idx_school_announcements_published on public.school_announcements(is_published);
create index if not exists idx_school_announcements_date on public.school_announcements(created_at desc);

-- RLS
alter table public.school_announcements enable row level security;

drop policy if exists "public_read_published_announcements" on public.school_announcements;
create policy "public_read_published_announcements"
  on public.school_announcements for select
  to authenticated, anon using (is_published = true);

drop policy if exists "authenticated_manage_announcements" on public.school_announcements;
create policy "authenticated_manage_announcements"
  on public.school_announcements for all
  to authenticated using (true) with check (true);

-- 2. Update fn_student_portal_data_by_qr to return announcements
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
  v_total_days bigint;
  v_days_present bigint;
  v_days_absent bigint;
  v_attendance_rate numeric;
  v_total_merit bigint;
  v_recent_attendance jsonb;
  v_submissions jsonb;
  v_announcements jsonb;
begin
  if p_qr_token is null or trim(p_qr_token) = '' then
    return null;
  end if;

  -- 1. Resolve student by QR token in qr_tokens or students table
  select s.id, s.full_name, s.class_id, s.ic_number, s.enrollment_status
  into v_student
  from public.students s
  left join public.qr_tokens qt on qt.student_id = s.id
  where qt.token = trim(p_qr_token)
     or qt.id::text = trim(p_qr_token)
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

  -- 6. Live School Announcements (Discipline & Counseling)
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', a.id,
      'category', a.category,
      'title', a.title,
      'content', a.content,
      'author_name', coalesce(p.full_name, 'Pengurusan Sekolah'),
      'target_student_name', st.full_name,
      'created_at', a.created_at
    ) order by a.created_at desc
  ), '[]'::jsonb)
  into v_announcements
  from public.school_announcements a
  left join public.profiles p on p.id = a.author_id
  left join public.students st on st.id = a.target_student_id
  where a.is_published = true
    and (a.target_student_id is null or a.target_student_id = v_student_id);

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
    'submissions', v_submissions,
    'announcements', v_announcements
  );
end;
$$;

grant execute on function public.fn_student_portal_data_by_qr(text) to authenticated, anon;
