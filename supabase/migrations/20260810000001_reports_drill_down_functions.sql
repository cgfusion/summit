-- Reports drill-down RPC functions to handle full dataset aggregation without
-- hitting PostgREST client-side pagination limits.

-- 1. Repeat absent students drill-down
create or replace function public.fn_repeat_absent_students(
  p_from date,
  p_to date,
  p_session text default null,
  p_min_absent int default 2
)
returns table (
  student_id uuid,
  full_name text,
  class_id uuid,
  class_name text,
  session text,
  absent_count bigint,
  present_count bigint,
  total_days bigint,
  ic_number text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    s.id as student_id,
    s.full_name,
    s.class_id,
    c.name as class_name,
    c.session,
    count(*) filter (where ad.status = 'tidak_hadir') as absent_count,
    count(*) filter (where ad.status in ('hadir', 'lewat')) as present_count,
    count(*) as total_days,
    s.ic_number
  from public.attendance_days ad
  join public.students s on s.id = ad.student_id
  join public.classes c on c.id = s.class_id
  where ad.school_date between p_from and p_to
    and s.enrollment_status = 'active'
    and (p_session is null or lower(c.session) = lower(p_session))
  group by s.id, s.full_name, s.class_id, c.name, c.session, s.ic_number
  having count(*) filter (where ad.status = 'tidak_hadir') >= p_min_absent
  order by absent_count desc, s.full_name asc;
$$;

grant execute on function public.fn_repeat_absent_students(date, date, text, int) to authenticated, anon;

-- 2. Class attendance rates drill-down
create or replace function public.fn_class_attendance_rates(
  p_from date,
  p_to date,
  p_session text default null
)
returns table (
  class_id uuid,
  class_name text,
  form_level int,
  session text,
  homeroom_teacher_name text,
  total_records bigint,
  present_count bigint,
  absent_count bigint,
  attendance_rate numeric
)
language sql
stable
security definer
set search_path = public
as $$
  select
    c.id as class_id,
    c.name as class_name,
    c.form_level,
    c.session,
    p.full_name as homeroom_teacher_name,
    count(ad.id) as total_records,
    count(ad.id) filter (where ad.status in ('hadir', 'lewat')) as present_count,
    count(ad.id) filter (where ad.status = 'tidak_hadir') as absent_count,
    case
      when count(ad.id) = 0 then 0
      else round(count(ad.id) filter (where ad.status in ('hadir', 'lewat'))::numeric / count(ad.id) * 100, 1)
    end as attendance_rate
  from public.classes c
  left join public.profiles p on p.id = c.homeroom_teacher_id
  left join public.students s on s.class_id = c.id and s.enrollment_status = 'active'
  left join public.attendance_days ad on ad.student_id = s.id and ad.school_date between p_from and p_to
  where (p_session is null or lower(c.session) = lower(p_session))
  group by c.id, c.name, c.form_level, c.session, p.full_name
  order by attendance_rate asc, c.form_level asc, c.name asc;
$$;

grant execute on function public.fn_class_attendance_rates(date, date, text) to authenticated, anon;

-- 3. Late and missed recess students drill-down
create or replace function public.fn_late_and_recess_students(
  p_from date,
  p_to date,
  p_session text default null
)
returns table (
  student_id uuid,
  full_name text,
  class_id uuid,
  class_name text,
  session text,
  late_count bigint,
  missed_recess_count bigint
)
language sql
stable
security definer
set search_path = public
as $$
  with late_summary as (
    select
      ad.student_id,
      count(*) as late_count
    from public.attendance_days ad
    where ad.school_date between p_from and p_to
      and ad.status = 'lewat'
    group by ad.student_id
  ),
  recess_summary as (
    select
      e.student_id,
      count(*) as missed_recess_count
    from public.attendance_day_exceptions e
    where e.school_date between p_from and p_to
      and e.missed_recess_return = true
    group by e.student_id
  )
  select
    s.id as student_id,
    s.full_name,
    s.class_id,
    c.name as class_name,
    c.session,
    coalesce(ls.late_count, 0) as late_count,
    coalesce(rs.missed_recess_count, 0) as missed_recess_count
  from public.students s
  join public.classes c on c.id = s.class_id
  left join late_summary ls on ls.student_id = s.id
  left join recess_summary rs on rs.student_id = s.id
  where s.enrollment_status = 'active'
    and (p_session is null or lower(c.session) = lower(p_session))
    and (coalesce(ls.late_count, 0) > 0 or coalesce(rs.missed_recess_count, 0) > 0)
  order by (coalesce(ls.late_count, 0) + coalesce(rs.missed_recess_count, 0)) desc, s.full_name asc;
$$;

grant execute on function public.fn_late_and_recess_students(date, date, text) to authenticated, anon;

-- 4. Leave type records drill-down
create or replace function public.fn_leave_type_records(
  p_from date,
  p_to date,
  p_session text default null,
  p_status text default null
)
returns table (
  id uuid,
  student_id uuid,
  full_name text,
  class_id uuid,
  class_name text,
  session text,
  school_date date,
  status text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    ad.id,
    s.id as student_id,
    s.full_name,
    s.class_id,
    c.name as class_name,
    c.session,
    ad.school_date,
    ad.status
  from public.attendance_days ad
  join public.students s on s.id = ad.student_id
  join public.classes c on c.id = s.class_id
  where ad.school_date between p_from and p_to
    and s.enrollment_status = 'active'
    and (p_session is null or lower(c.session) = lower(p_session))
    and ad.status in ('tidak_hadir', 'cuti_sakit', 'urusan_rasmi')
    and (p_status is null or ad.status = p_status)
  order by ad.school_date desc, c.name asc, s.full_name asc;
$$;

grant execute on function public.fn_leave_type_records(date, date, text, text) to authenticated, anon;
