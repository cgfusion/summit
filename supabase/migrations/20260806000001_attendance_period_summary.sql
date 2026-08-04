-- Per-class (+ whole-school) attendance % across 4 fixed timeframes: day,
-- week, month, year, all anchored to one reference date. Per the requesting
-- teacher: the denominator for week/month/year is the FULL period's school
-- day count (Mon-Fri only), not "days elapsed so far" -- so mid-period the
-- percentage reads as running progress toward 100%, only reaching its final
-- value once the period ends. E.g. present both Mon and Tue of a week in
-- progress reads as 2/5 = 40%, not 2/2 = 100%.

create or replace function public.fn_weekday_count(p_from date, p_to date)
returns int
language sql
stable
as $$
  select count(*)::int
  from generate_series(p_from, p_to, interval '1 day') d
  where extract(isodow from d) between 1 and 5;
$$;

grant execute on function public.fn_weekday_count(date, date) to authenticated;

create or replace function public.fn_attendance_period_summary(p_reference_date date)
returns table (
  class_id uuid,
  class_name text,
  day_rate numeric,
  week_rate numeric,
  month_rate numeric,
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
  per_class as (
    select
      c.id as class_id,
      c.name as class_name,
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
    from public.classes c
    join public.students s on s.class_id = c.id
    left join public.attendance_days ad on ad.student_id = s.id
    group by c.id, c.name

    union all

    -- Whole-school row: class_id null, aggregated across every student.
    select
      null::uuid as class_id,
      'Whole School' as class_name,
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
  )
  select
    pc.class_id,
    pc.class_name,
    case when pc.student_count = 0 then 0
      else round(pc.day_present::numeric / pc.student_count * 100, 1)
    end as day_rate,
    case when pc.student_count = 0 or w.week_days = 0 then 0
      else round(pc.week_present::numeric / (pc.student_count * w.week_days) * 100, 1)
    end as week_rate,
    case when pc.student_count = 0 or w.month_days = 0 then 0
      else round(pc.month_present::numeric / (pc.student_count * w.month_days) * 100, 1)
    end as month_rate,
    case when pc.student_count = 0 or w.year_days = 0 then 0
      else round(pc.year_present::numeric / (pc.student_count * w.year_days) * 100, 1)
    end as year_rate
  from per_class pc
  cross join weekdays w
  order by (pc.class_id is null) desc, pc.class_name;
$$;

grant execute on function public.fn_attendance_period_summary(date) to authenticated;
