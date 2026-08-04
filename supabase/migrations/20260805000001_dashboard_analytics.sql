-- Analytics for the new Dashboard screen (separate from the Home tile
-- grid). Every function here is read-only and derives strictly from
-- attendance_days / merit_student_daily / merit_awards -- no new
-- source-of-truth tables.

-- ---------------------------------------------------------------------------
-- fn_attendance_day_summary: present/late/absent/mc counts + merit points +
-- rewards issued for one calendar day. Called twice by the client (today,
-- yesterday) to compute "vs yesterday" deltas without a bespoke function.
-- ---------------------------------------------------------------------------
create function public.fn_attendance_day_summary(p_date date)
returns table (
  present_count bigint,
  late_count bigint,
  absent_count bigint,
  mc_count bigint,
  recorded_count bigint,
  merit_points bigint,
  rewards_issued bigint
)
language sql
stable
as $$
  select
    count(*) filter (where ad.status = 'hadir') as present_count,
    count(*) filter (where ad.status = 'lewat') as late_count,
    count(*) filter (where ad.status = 'tidak_hadir') as absent_count,
    count(*) filter (where ad.status in ('cuti_sakit', 'urusan_rasmi')) as mc_count,
    count(*) as recorded_count,
    coalesce((select sum(msd.total_points) from public.merit_student_daily msd where msd.school_date = p_date), 0) as merit_points,
    coalesce((select count(*) from public.merit_awards ma where ma.awarded_at::date = p_date), 0) as rewards_issued
  from public.attendance_days ad
  where ad.school_date = p_date;
$$;

grant execute on function public.fn_attendance_day_summary(date) to authenticated;

-- ---------------------------------------------------------------------------
-- fn_daily_attendance_trend: one row per school day with a recorded
-- attendance day in [p_from, p_to] -- powers the weekly trend line and the
-- monthly heatmap (both just group these rows differently client-side).
-- ---------------------------------------------------------------------------
create function public.fn_daily_attendance_trend(p_from date, p_to date)
returns table (
  school_date date,
  present_count bigint,
  late_count bigint,
  absent_count bigint,
  mc_count bigint,
  recorded_count bigint,
  attendance_rate numeric
)
language sql
stable
as $$
  select
    ad.school_date,
    count(*) filter (where ad.status = 'hadir') as present_count,
    count(*) filter (where ad.status = 'lewat') as late_count,
    count(*) filter (where ad.status = 'tidak_hadir') as absent_count,
    count(*) filter (where ad.status in ('cuti_sakit', 'urusan_rasmi')) as mc_count,
    count(*) as recorded_count,
    round(count(*) filter (where ad.status in ('hadir', 'lewat'))::numeric / count(*) * 100, 1) as attendance_rate
  from public.attendance_days ad
  where ad.school_date between p_from and p_to
  group by ad.school_date
  order by ad.school_date;
$$;

grant execute on function public.fn_daily_attendance_trend(date, date) to authenticated;

-- ---------------------------------------------------------------------------
-- fn_daily_merit_trend: total merit points per school day in a range --
-- powers the weekly merit points chart.
-- ---------------------------------------------------------------------------
create function public.fn_daily_merit_trend(p_from date, p_to date)
returns table (
  school_date date,
  total_points bigint
)
language sql
stable
as $$
  select msd.school_date, sum(msd.total_points) as total_points
  from public.merit_student_daily msd
  where msd.school_date between p_from and p_to
  group by msd.school_date
  order by msd.school_date;
$$;

grant execute on function public.fn_daily_merit_trend(date, date) to authenticated;

-- ---------------------------------------------------------------------------
-- fn_class_attendance_summary: per-class attendance rate over a range --
-- powers the Top 5 / Worst 5 classes leaderboards.
-- ---------------------------------------------------------------------------
create function public.fn_class_attendance_summary(p_from date, p_to date)
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
  left join public.students s on s.class_id = c.id
  left join public.attendance_days ad on ad.student_id = s.id and ad.school_date between p_from and p_to
  group by c.id, c.name;
$$;

grant execute on function public.fn_class_attendance_summary(date, date) to authenticated;

-- ---------------------------------------------------------------------------
-- fn_attendance_streaks: current consecutive-present-day streak per student,
-- counting back from the most recent recorded school day. A student with no
-- gap since the first ever recorded day gets the full history length.
-- ---------------------------------------------------------------------------
create function public.fn_attendance_streaks(p_limit int default 10)
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

grant execute on function public.fn_attendance_streaks(int) to authenticated;

-- ---------------------------------------------------------------------------
-- fn_recent_activity: a merged, real-events timeline -- QR scans, manual
-- attendance entries, and merit awards -- for the dashboard's activity feed.
-- ---------------------------------------------------------------------------
create function public.fn_recent_activity(p_limit int default 15)
returns table (
  kind text,
  occurred_at timestamptz,
  student_name text,
  class_name text,
  detail text
)
language sql
stable
as $$
  (
    select
      'scan' as kind,
      al.scanned_at as occurred_at,
      s.full_name as student_name,
      c.name as class_name,
      'Scanned in' as detail
    from public.attendance_logs al
    join public.students s on s.id = al.student_id
    left join public.classes c on c.id = s.class_id
    order by al.scanned_at desc
    limit p_limit
  )
  union all
  (
    select
      'manual_attendance' as kind,
      ad.updated_at as occurred_at,
      s.full_name as student_name,
      c.name as class_name,
      'Marked ' || ad.status || ' manually' as detail
    from public.attendance_days ad
    join public.students s on s.id = ad.student_id
    left join public.classes c on c.id = s.class_id
    where ad.source = 'manual_override'
    order by ad.updated_at desc
    limit p_limit
  )
  union all
  (
    select
      'merit_award' as kind,
      ma.awarded_at as occurred_at,
      coalesce(s.full_name, c2.name) as student_name,
      c2.name as class_name,
      ma.category as detail
    from public.merit_awards ma
    left join public.students s on s.id = ma.student_id
    left join public.classes c2 on c2.id = coalesce(ma.class_id, s.class_id)
    order by ma.awarded_at desc
    limit p_limit
  )
  order by occurred_at desc
  limit p_limit;
$$;

grant execute on function public.fn_recent_activity(int) to authenticated;

-- ---------------------------------------------------------------------------
-- fn_kpi_overview: 3 headline rates for a period -- attendance, average
-- merit %, and "discipline" (share of present-days with no exception
-- flagged at all, i.e. on time, returned from recess, stayed till the end).
-- ---------------------------------------------------------------------------
create function public.fn_kpi_overview(p_from date, p_to date)
returns table (
  attendance_rate numeric,
  merit_avg_pct numeric,
  discipline_rate numeric
)
language sql
stable
as $$
  select
    (
      select case when count(*) = 0 then 0
        else round(count(*) filter (where status in ('hadir', 'lewat'))::numeric / count(*) * 100, 1)
        end
      from public.attendance_days where school_date between p_from and p_to
    ) as attendance_rate,
    (
      select case when count(*) = 0 then 0 else round(avg(pct), 1) end
      from public.fn_student_period_summary(p_from, p_to, null)
      where max_points > 0
    ) as merit_avg_pct,
    (
      select case when count(*) = 0 then 0
        else round(
          count(*) filter (
            where not coalesce(e.late_to_class, false)
              and not coalesce(e.missed_recess_return, false)
              and not coalesce(e.left_early, false)
          )::numeric / count(*) * 100, 1
        )
        end
      from public.attendance_days ad
      left join public.attendance_day_exceptions e
        on e.student_id = ad.student_id and e.school_date = ad.school_date
      where ad.school_date between p_from and p_to and ad.status in ('hadir', 'lewat')
    ) as discipline_rate;
$$;

grant execute on function public.fn_kpi_overview(date, date) to authenticated;
