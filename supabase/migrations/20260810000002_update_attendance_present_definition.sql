-- Update attendance calculations across all SQL functions so that
-- Cuti Sakit and Urusan Rasmi count as Present ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')
-- while only unexplained absence ('tidak_hadir') counts against attendance rate.

-- 1. fn_weekly_kpi_trend
drop function if exists public.fn_weekly_kpi_trend(date, date, text);
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
drop function if exists public.fn_student_period_summary(date, date, uuid);
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
drop function if exists public.fn_repeat_absent_students(date, date, text, int);
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
drop function if exists public.fn_class_attendance_rates(date, date, text);
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
drop function if exists public.fn_class_attendance_summary(date, date);
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

-- 6. fn_attendance_period_summary (used by WhatsApp Report & Period Summaries)
drop function if exists public.fn_attendance_period_summary(date);
create or replace function public.fn_attendance_period_summary(p_reference_date date)
returns table (
  scope_type text,
  scope_id uuid,
  scope_name text,
  student_count bigint,
  day_present bigint,
  day_total bigint,
  day_rate numeric,
  week_present bigint,
  week_total bigint,
  week_rate numeric,
  month_present bigint,
  month_total bigint,
  month_rate numeric,
  year_present bigint,
  year_total bigint,
  year_rate numeric
)
language sql
stable
security definer
set search_path = public
as $$
  with bounds as (
    select
      p_reference_date as day_from,
      p_reference_date as day_to,
      (p_reference_date - (extract(isodow from p_reference_date)::int - 1))::date as week_from,
      (p_reference_date - (extract(isodow from p_reference_date)::int - 1))::date + 4 as week_to,
      date_trunc('month', p_reference_date)::date as month_from,
      (date_trunc('month', p_reference_date) + interval '1 month - 1 day')::date as month_to,
      date_trunc('year', p_reference_date)::date as year_from,
      (date_trunc('year', p_reference_date) + interval '1 year - 1 day')::date as year_to
  ),
  weekdays as (
    select
      public.fn_weekday_count(b.week_from, b.week_to) as week_days,
      public.fn_weekday_count(b.month_from, b.month_to) as month_days,
      public.fn_weekday_count(b.year_from, b.year_to) as year_days
    from bounds b
  ),
  raw as (
    -- Whole school
    select
      'school'::text as scope_type,
      null::uuid as scope_id,
      'Whole School'::text as scope_name,
      count(distinct s.id) as student_count,
      count(*) filter (
        where ad.school_date = (select day_from from bounds) and ad.status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')
      ) as day_present,
      count(*) filter (
        where ad.school_date between (select week_from from bounds) and (select week_to from bounds)
          and ad.status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')
      ) as week_present,
      count(*) filter (
        where ad.school_date between (select month_from from bounds) and (select month_to from bounds)
          and ad.status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')
      ) as month_present,
      count(*) filter (
        where ad.school_date between (select year_from from bounds) and (select year_to from bounds)
          and ad.status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')
      ) as year_present
    from public.students s
    left join public.attendance_days ad on ad.student_id = s.id
    where s.enrollment_status = 'active'

    union all

    -- Tingkatan (form level 1-5)
    select
      'form'::text,
      null::uuid,
      ('Tingkatan ' || c.form_level)::text,
      count(distinct s.id),
      count(*) filter (
        where ad.school_date = (select day_from from bounds) and ad.status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')
      ),
      count(*) filter (
        where ad.school_date between (select week_from from bounds) and (select week_to from bounds)
          and ad.status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')
      ),
      count(*) filter (
        where ad.school_date between (select month_from from bounds) and (select month_to from bounds)
          and ad.status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')
      ),
      count(*) filter (
        where ad.school_date between (select year_from from bounds) and (select year_to from bounds)
          and ad.status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')
      )
    from public.classes c
    join public.students s on s.class_id = c.id and s.enrollment_status = 'active'
    left join public.attendance_days ad on ad.student_id = s.id
    group by c.form_level

    union all

    -- Per class
    select
      'class'::text,
      c.id,
      c.name,
      count(distinct s.id),
      count(*) filter (
        where ad.school_date = (select day_from from bounds) and ad.status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')
      ),
      count(*) filter (
        where ad.school_date between (select week_from from bounds) and (select week_to from bounds)
          and ad.status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')
      ),
      count(*) filter (
        where ad.school_date between (select month_from from bounds) and (select month_to from bounds)
          and ad.status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')
      ),
      count(*) filter (
        where ad.school_date between (select year_from from bounds) and (select year_to from bounds)
          and ad.status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')
      )
    from public.classes c
    join public.students s on s.class_id = c.id and s.enrollment_status = 'active'
    left join public.attendance_days ad on ad.student_id = s.id
    group by c.id, c.name
  )
  select
    r.scope_type,
    r.scope_id,
    r.scope_name,
    r.student_count,
    r.day_present,
    r.student_count as day_total,
    case when r.student_count = 0 then 0 else round(r.day_present::numeric / r.student_count * 100, 1) end as day_rate,
    r.week_present,
    r.student_count * w.week_days as week_total,
    case when r.student_count = 0 or w.week_days = 0 then 0
      else round(r.week_present::numeric / (r.student_count * w.week_days) * 100, 1)
    end as week_rate,
    r.month_present,
    r.student_count * w.month_days as month_total,
    case when r.student_count = 0 or w.month_days = 0 then 0
      else round(r.month_present::numeric / (r.student_count * w.month_days) * 100, 1)
    end as month_rate,
    r.year_present,
    r.student_count * w.year_days as year_total,
    case when r.student_count = 0 or w.year_days = 0 then 0
      else round(r.year_present::numeric / (r.student_count * w.year_days) * 100, 1)
    end as year_rate
  from raw r
  cross join weekdays w
  order by
    case r.scope_type when 'school' then 0 when 'form' then 1 else 2 end,
    r.scope_name;
$$;

grant execute on function public.fn_attendance_period_summary(date) to authenticated, anon;

-- 7. fn_attendance_day_summary: updated present_count to include cuti_sakit & urusan_rasmi, plus detailed counts
drop function if exists public.fn_attendance_day_summary(date);
create or replace function public.fn_attendance_day_summary(p_date date)
returns table (
  present_count bigint,
  hadir_count bigint,
  late_count bigint,
  absent_count bigint,
  mc_count bigint,
  rasmi_count bigint,
  recorded_count bigint,
  merit_points bigint,
  rewards_issued bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    count(*) filter (where ad.status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi')) as present_count,
    count(*) filter (where ad.status = 'hadir') as hadir_count,
    count(*) filter (where ad.status = 'lewat') as late_count,
    count(*) filter (where ad.status = 'tidak_hadir') as absent_count,
    count(*) filter (where ad.status = 'cuti_sakit') as mc_count,
    count(*) filter (where ad.status = 'urusan_rasmi') as rasmi_count,
    count(*) as recorded_count,
    coalesce((select sum(msd.total_points) from public.merit_student_daily msd where msd.school_date = p_date), 0) as merit_points,
    coalesce((select count(*) from public.merit_awards ma where ma.awarded_at::date = p_date), 0) as rewards_issued
  from public.attendance_days ad
  where ad.school_date = p_date;
$$;

grant execute on function public.fn_attendance_day_summary(date) to authenticated, anon;

-- 8. Parent Portal lookup functions
drop function if exists public.fn_parent_portal_data_by_ic(text);
create or replace function public.fn_parent_portal_data_by_ic(p_ic_number text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_normalized_ic text;
  v_week_start date;
  v_week_end date;
  v_month_start date;
  v_month_end date;
  v_max_points int;
  v_today date := current_date;
  v_result jsonb;
begin
  v_normalized_ic := regexp_replace(p_ic_number, '\D', '', 'g');
  if v_normalized_ic = '' then
    return '[]'::jsonb;
  end if;

  v_week_start := (v_today - (extract(isodow from v_today)::int - 1))::date;
  v_week_end := v_week_start + 4;
  v_month_start := date_trunc('month', v_today)::date;
  v_month_end := (date_trunc('month', v_today) + interval '1 month - 1 day')::date;

  select merit_max_points into v_max_points
  from public.attendance_settings where id = 1;
  v_max_points := coalesce(v_max_points, 1);

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'student', jsonb_build_object(
        'full_name', s.full_name,
        'class_name', c.name,
        'enrollment_status', s.enrollment_status,
        'enrollment_status_reason', s.enrollment_status_reason,
        'enrollment_status_date', s.enrollment_status_date
      ),
      'attendance_recent', coalesce((
        select jsonb_agg(jsonb_build_object('date', recent.school_date, 'status', recent.status) order by recent.school_date desc)
        from (
          select school_date, status from public.attendance_days
          where student_id = s.id
          order by school_date desc
          limit 30
        ) recent
      ), '[]'::jsonb),
      'attendance_week', jsonb_build_object(
        'present', (
          select count(*) filter (where status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi'))
          from public.attendance_days
          where student_id = s.id and school_date between v_week_start and v_week_end
        ),
        'total_days', public.fn_weekday_count(v_week_start, v_week_end)
      ),
      'attendance_month', jsonb_build_object(
        'present', (
          select count(*) filter (where status in ('hadir', 'lewat', 'cuti_sakit', 'urusan_rasmi'))
          from public.attendance_days
          where student_id = s.id and school_date between v_month_start and v_month_end
        ),
        'total_days', public.fn_weekday_count(v_month_start, v_month_end)
      ),
      'merit_month', jsonb_build_object(
        'total_points', (
          select coalesce(sum(total_points), 0) from public.merit_student_daily
          where student_id = s.id and school_date between v_month_start and v_month_end
        ),
        'days_recorded', (
          select count(*) from public.merit_student_daily
          where student_id = s.id and school_date between v_month_start and v_month_end
        ),
        'max_points_per_day', v_max_points
      )
    )
    order by c.name, s.full_name
  ), '[]'::jsonb)
  into v_result
  from public.students s
  join public.classes c on c.id = s.class_id
  join public.student_guardians sg on sg.student_id = s.id
  where regexp_replace(sg.ic_number, '\D', '', 'g') = v_normalized_ic
    and s.enrollment_status = 'active';

  return v_result;
end;
$$;

grant execute on function public.fn_parent_portal_data_by_ic(text) to authenticated, anon;
