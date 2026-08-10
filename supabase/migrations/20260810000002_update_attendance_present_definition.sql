-- Update attendance calculations across all SQL functions so that
-- Cuti Sakit and Urusan Rasmi count as Present ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')
-- while only unexplained absence ('tidak_hadir') counts against attendance rate.

-- 1. fn_weekly_kpi_trend
create or replace function public.fn_weekly_kpi_trend(
  p_from date,
  p_to date,
  p_session text default null
)
returns table (
  week_start date,
  total_records bigint,
  present_count bigint,
  late_count bigint,
  attendance_rate numeric,
  missed_recess_count bigint,
  repeat_absent_students bigint
)
language sql
stable
security definer
set search_path = public
as $$
  with base as (
    select
      ad.student_id,
      ad.school_date,
      ad.status,
      date_trunc('week', ad.school_date)::date as week_start
    from public.attendance_days ad
    join public.students s on s.id = ad.student_id
    join public.classes c on c.id = s.class_id
    where ad.school_date between p_from and p_to
      and (p_session is null or lower(c.session) = lower(p_session))
  ),
  weekly_base as (
    select
      week_start,
      count(*) as total_records,
      count(*) filter (where status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')) as present_count,
      count(*) filter (where status = 'lewat') as late_count
    from base
    group by week_start
  ),
  repeat_absent as (
    select week_start, count(*) as repeat_absent_students
    from (
      select student_id, week_start
      from base
      where status = 'tidak_hadir'
      group by student_id, week_start
      having count(*) >= 2
    ) x
    group by week_start
  ),
  recess_missed as (
    select
      date_trunc('week', e.school_date)::date as week_start,
      count(*) as missed_recess_count
    from public.attendance_day_exceptions e
    join public.students s on s.id = e.student_id
    join public.classes c on c.id = s.class_id
    where e.school_date between p_from and p_to
      and e.missed_recess_return = true
      and (p_session is null or lower(c.session) = lower(p_session))
    group by 1
  )
  select
    wb.week_start,
    wb.total_records,
    wb.present_count,
    wb.late_count,
    case
      when wb.total_records = 0 then 0
      else round(wb.present_count::numeric / wb.total_records * 100, 1)
    end as attendance_rate,
    coalesce(rm.missed_recess_count, 0) as missed_recess_count,
    coalesce(ra.repeat_absent_students, 0) as repeat_absent_students
  from weekly_base wb
  left join repeat_absent ra on ra.week_start = wb.week_start
  left join recess_missed rm on rm.week_start = wb.week_start
  order by wb.week_start;
$$;

grant execute on function public.fn_weekly_kpi_trend(date, date, text) to authenticated, anon;

-- 2. fn_student_period_summary
create or replace function public.fn_student_period_summary(
  p_from date,
  p_to date,
  p_class_id uuid default null
)
returns table (
  student_id uuid,
  full_name text,
  class_id uuid,
  total_points bigint,
  max_points bigint,
  pct numeric,
  full_attendance boolean,
  days_present bigint,
  days_absent bigint
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
    coalesce(sum(msd.total_points), 0) as total_points,
    coalesce(count(msd.school_date), 0) * (select merit_max_points from public.attendance_settings where id = 1) as max_points,
    case
      when count(msd.school_date) = 0 then 0
      else round(
        coalesce(sum(msd.total_points), 0)::numeric
        / (count(msd.school_date) * (select merit_max_points from public.attendance_settings where id = 1)) * 100,
        1
      )
    end as pct,
    (count(msd.school_date) > 0 and count(*) filter (where msd.attendance_status = 'tidak_hadir') = 0) as full_attendance,
    count(*) filter (where msd.attendance_status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')) as days_present,
    count(*) filter (where msd.attendance_status = 'tidak_hadir') as days_absent
  from public.students s
  left join public.merit_student_daily msd
    on msd.student_id = s.id and msd.school_date between p_from and p_to
  where (p_class_id is null or s.class_id = p_class_id) and s.enrollment_status = 'active'
  group by s.id, s.full_name, s.class_id;
$$;

grant execute on function public.fn_student_period_summary(date, date, uuid) to authenticated, anon;

-- 3. fn_repeat_absent_students
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
    count(*) filter (where ad.status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')) as present_count,
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

-- 4. fn_class_attendance_rates
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
    count(ad.id) filter (where ad.status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')) as present_count,
    count(ad.id) filter (where ad.status = 'tidak_hadir') as absent_count,
    case
      when count(ad.id) = 0 then 0
      else round(count(ad.id) filter (where ad.status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi'))::numeric / count(ad.id) * 100, 1)
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

-- 5. fn_class_attendance_summary
create or replace function public.fn_class_attendance_summary(
  p_from date,
  p_to date
)
returns table (
  class_id uuid,
  class_name text,
  form_level int,
  session text,
  recorded_count bigint,
  present_count bigint,
  late_count bigint,
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
    count(ad.id) as recorded_count,
    count(ad.id) filter (where ad.status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')) as present_count,
    count(ad.id) filter (where ad.status = 'lewat') as late_count,
    count(ad.id) filter (where ad.status = 'tidak_hadir') as absent_count,
    case
      when count(ad.id) = 0 then 0
      else round(count(ad.id) filter (where ad.status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi'))::numeric / count(ad.id) * 100, 1)
    end as attendance_rate
  from public.classes c
  left join public.students s on s.class_id = c.id and s.enrollment_status = 'active'
  left join public.attendance_days ad on ad.student_id = s.id and ad.school_date between p_from and p_to
  group by c.id, c.name, c.form_level, c.session
  order by c.form_level, c.name;
$$;

grant execute on function public.fn_class_attendance_summary(date, date) to authenticated, anon;
