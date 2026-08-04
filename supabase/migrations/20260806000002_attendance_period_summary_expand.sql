-- Extends fn_attendance_period_summary: adds a Tingkatan (form-level) tier
-- between "Whole School" and per-class rows, and exposes the raw
-- present/total counts behind each percentage (per the requesting
-- teacher's follow-up: they want a second table showing real counts, not
-- just %, and a per-Tingkatan breakdown alongside per-class).

drop function if exists public.fn_attendance_period_summary(date);

create function public.fn_attendance_period_summary(p_reference_date date)
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
    join public.students s on s.class_id = c.id
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
    join public.students s on s.class_id = c.id
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

grant execute on function public.fn_attendance_period_summary(date) to authenticated;
