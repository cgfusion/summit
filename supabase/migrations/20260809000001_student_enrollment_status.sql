-- Student enrollment status: active/suspended/expelled/transferred/withdrawn/
-- deceased/graduated, distinct from the existing study_status column (which
-- is the raw MOE "STATUS PENGAJIAN" import field and left unconstrained).
-- Non-active students are excluded from every "current roster" query
-- (attendance-taking, merit rosters, leaderboards, period summaries) below,
-- while their historical attendance_days/merit rows are left untouched.

alter table public.students
  add column enrollment_status text not null default 'active'
    check (enrollment_status in (
      'active', 'suspended', 'expelled', 'transferred_out', 'withdrawn', 'deceased', 'graduated'
    )),
  add column enrollment_status_reason text,
  add column enrollment_status_date date,
  add column enrollment_status_changed_by uuid references public.profiles (id) on delete set null,
  add column enrollment_status_changed_at timestamptz;

create index students_enrollment_status_idx on public.students (enrollment_status);

-- ---------------------------------------------------------------------------
-- fn_update_student_status: admin-only, records who/when alongside the
-- status change for audit purposes.
-- ---------------------------------------------------------------------------
create function public.fn_update_student_status(
  p_student_id uuid,
  p_status text,
  p_reason text default null,
  p_date date default current_date
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  if p_status not in (
    'active', 'suspended', 'expelled', 'transferred_out', 'withdrawn', 'deceased', 'graduated'
  ) then
    raise exception 'invalid status: %', p_status;
  end if;

  update public.students
  set enrollment_status = p_status,
      enrollment_status_reason = p_reason,
      enrollment_status_date = p_date,
      enrollment_status_changed_by = auth.uid(),
      enrollment_status_changed_at = now()
  where id = p_student_id;
end;
$$;

grant execute on function public.fn_update_student_status(uuid, text, text, date) to authenticated;

-- ---------------------------------------------------------------------------
-- fn_manual_attendance_set: reject writes for a student who isn't active,
-- so staff can't keyin attendance for someone who's been expelled/
-- transferred/etc. (Server-side guard -- the client also filters inactive
-- students out of roster/search results, but this is the real enforcement.)
-- ---------------------------------------------------------------------------
create or replace function public.fn_manual_attendance_set(
  p_student_id uuid,
  p_school_date date,
  p_status text,
  p_time time default null,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_timezone text;
  v_session text;
  v_dow smallint;
  v_cutoff time;
  v_at timestamptz;
  v_actor uuid := auth.uid();
  v_enrollment_status text;
begin
  if not public.is_staff() then
    raise exception 'not authorized';
  end if;

  if p_status not in ('hadir', 'lewat', 'tidak_hadir', 'cuti_sakit', 'urusan_rasmi') then
    raise exception 'invalid status: %', p_status;
  end if;

  select enrollment_status into v_enrollment_status from public.students where id = p_student_id;
  if v_enrollment_status is null then
    raise exception 'student not found';
  elsif v_enrollment_status <> 'active' then
    raise exception 'student is not active (enrollment_status: %)', v_enrollment_status;
  end if;

  select school_timezone into v_timezone from public.attendance_settings where id = 1;

  if p_status in ('hadir', 'lewat') then
    if p_time is not null then
      v_at := (p_school_date::text || ' ' || p_time::text)::timestamp at time zone v_timezone;
    else
      -- No time given (e.g. bulk backfill) -- default to that student's
      -- class/weekday cutoff, so a plain "hadir" reads as on-time rather
      -- than an arbitrary clock value.
      v_dow := extract(isodow from p_school_date);
      select c.session into v_session
      from public.students s
      join public.classes c on c.id = s.class_id
      where s.id = p_student_id;

      select cutoff_time into v_cutoff
      from public.session_cutoff_times
      where session = v_session and day_of_week = v_dow;

      v_at := (p_school_date::text || ' ' || coalesce(v_cutoff, '07:00:00')::text)::timestamp at time zone v_timezone;
    end if;
  else
    v_at := null;
  end if;

  insert into public.attendance_days (
    student_id, school_date, status, source, first_scan_id, first_scan_at, overridden_by, override_reason
  ) values (
    p_student_id, p_school_date, p_status, 'manual_override', null, v_at, v_actor, p_note
  )
  on conflict (student_id, school_date) do update
    set status = excluded.status,
        source = 'manual_override',
        first_scan_id = null,
        first_scan_at = excluded.first_scan_at,
        overridden_by = excluded.overridden_by,
        override_reason = excluded.override_reason,
        updated_at = now();
end;
$$;

-- ---------------------------------------------------------------------------
-- Exclude non-active students from every "current roster" query below.
-- Historical attendance_days/merit_student_daily rows are untouched -- this
-- only changes who counts as part of a class/school roster going forward.
-- ---------------------------------------------------------------------------

create or replace function public.fn_class_attendance_summary(p_from date, p_to date)
returns table (
  class_id uuid,
  class_name text,
  recorded_count bigint,
  attendance_rate numeric
)
language sql
stable
as $$
  select
    c.id as class_id,
    c.name as class_name,
    count(ad.id) as recorded_count,
    case
      when count(ad.id) = 0 then 0
      else round(count(*) filter (where ad.status in ('hadir', 'lewat'))::numeric / count(ad.id) * 100, 1)
    end as attendance_rate
  from public.classes c
  left join public.students s on s.class_id = c.id and s.enrollment_status = 'active'
  left join public.attendance_days ad on ad.student_id = s.id and ad.school_date between p_from and p_to
  group by c.id, c.name;
$$;

create or replace function public.fn_attendance_streaks(p_limit int default 10)
returns table (
  student_id uuid,
  full_name text,
  class_id uuid,
  streak_days bigint
)
language sql
stable
as $$
  with school_days as (
    select distinct school_date from public.attendance_days
  ),
  ranked_days as (
    select school_date, row_number() over (order by school_date desc) as rn from school_days
  ),
  student_status as (
    select
      s.id as student_id,
      s.full_name,
      s.class_id,
      rd.rn,
      coalesce(ad.status in ('hadir', 'lewat'), false) as present
    from public.students s
    cross join ranked_days rd
    left join public.attendance_days ad on ad.student_id = s.id and ad.school_date = rd.school_date
    where s.enrollment_status = 'active'
  ),
  first_break as (
    select student_id, min(rn) filter (where not present) as break_rn, count(*) as total_days
    from student_status
    group by student_id
  )
  select
    ss.student_id,
    ss.full_name,
    ss.class_id,
    coalesce(fb.break_rn, fb.total_days + 1) - 1 as streak_days
  from student_status ss
  join first_break fb using (student_id)
  group by ss.student_id, ss.full_name, ss.class_id, fb.break_rn, fb.total_days
  having coalesce(fb.break_rn, fb.total_days + 1) - 1 > 0
  order by streak_days desc, ss.full_name
  limit p_limit;
$$;

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
        where ad.school_date = (select day_from from bounds) and ad.status in ('hadir', 'lewat')
      ) as day_present,
      count(*) filter (
        where ad.school_date between (select week_from from bounds) and (select week_to from bounds)
          and ad.status in ('hadir', 'lewat')
      ) as week_present,
      count(*) filter (
        where ad.school_date between (select month_from from bounds) and (select month_to from bounds)
          and ad.status in ('hadir', 'lewat')
      ) as month_present,
      count(*) filter (
        where ad.school_date between (select year_from from bounds) and (select year_to from bounds)
          and ad.status in ('hadir', 'lewat')
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
        where ad.school_date = (select day_from from bounds) and ad.status in ('hadir', 'lewat')
      ),
      count(*) filter (
        where ad.school_date between (select week_from from bounds) and (select week_to from bounds)
          and ad.status in ('hadir', 'lewat')
      ),
      count(*) filter (
        where ad.school_date between (select month_from from bounds) and (select month_to from bounds)
          and ad.status in ('hadir', 'lewat')
      ),
      count(*) filter (
        where ad.school_date between (select year_from from bounds) and (select year_to from bounds)
          and ad.status in ('hadir', 'lewat')
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
        where ad.school_date = (select day_from from bounds) and ad.status in ('hadir', 'lewat')
      ),
      count(*) filter (
        where ad.school_date between (select week_from from bounds) and (select week_to from bounds)
          and ad.status in ('hadir', 'lewat')
      ),
      count(*) filter (
        where ad.school_date between (select month_from from bounds) and (select month_to from bounds)
          and ad.status in ('hadir', 'lewat')
      ),
      count(*) filter (
        where ad.school_date between (select year_from from bounds) and (select year_to from bounds)
          and ad.status in ('hadir', 'lewat')
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

create or replace function public.fn_chronic_latecomers(
  p_reference_date date,
  p_window_days int default 7,
  p_min_late int default 3
)
returns table (
  student_id uuid,
  full_name text,
  class_id uuid,
  class_name text,
  late_count bigint
)
language sql
stable
as $$
  select
    s.id as student_id,
    s.full_name,
    s.class_id,
    c.name as class_name,
    count(*) filter (where ad.status = 'lewat') as late_count
  from public.students s
  join public.classes c on c.id = s.class_id
  join public.attendance_days ad
    on ad.student_id = s.id
    and ad.school_date between p_reference_date - (p_window_days - 1) and p_reference_date
  where s.enrollment_status = 'active'
  group by s.id, s.full_name, s.class_id, c.name
  having count(*) filter (where ad.status = 'lewat') >= p_min_late
  order by count(*) filter (where ad.status = 'lewat') desc, s.full_name;
$$;

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
    count(*) filter (where msd.attendance_status in ('hadir', 'lewat')) as days_present,
    count(*) filter (where msd.attendance_status = 'tidak_hadir') as days_absent
  from public.students s
  left join public.merit_student_daily msd
    on msd.student_id = s.id and msd.school_date between p_from and p_to
  where (p_class_id is null or s.class_id = p_class_id) and s.enrollment_status = 'active'
  group by s.id, s.full_name, s.class_id;
$$;

create or replace function public.fn_class_period_summary(
  p_from date,
  p_to date
)
returns table (
  class_id uuid,
  class_name text,
  total_points bigint,
  max_points bigint,
  pct numeric,
  missed_recess_return_count bigint,
  missed_recess_return_rate numeric
)
language sql
stable
as $$
  select
    c.id as class_id,
    c.name as class_name,
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
    count(*) filter (
      where coalesce(e.missed_recess_return, false) and msd.attendance_status in ('hadir', 'lewat')
    ) as missed_recess_return_count,
    case
      when count(msd.school_date) filter (where msd.attendance_status in ('hadir', 'lewat')) = 0 then 0
      else round(
        count(*) filter (
          where coalesce(e.missed_recess_return, false) and msd.attendance_status in ('hadir', 'lewat')
        )::numeric
        / count(msd.school_date) filter (where msd.attendance_status in ('hadir', 'lewat')) * 100,
        1
      )
    end as missed_recess_return_rate
  from public.classes c
  left join public.students s on s.class_id = c.id and s.enrollment_status = 'active'
  left join public.merit_student_daily msd
    on msd.student_id = s.id and msd.school_date between p_from and p_to
  left join public.attendance_day_exceptions e
    on e.student_id = msd.student_id and e.school_date = msd.school_date
  group by c.id, c.name;
$$;
