-- Per-school configurability of the 4 merit components (+ bonus) and the
-- daily max. "Kembali selepas rehat" is hard to enforce reliably in
-- practice, so schools can turn it (and any other component) off entirely
-- rather than have it silently misrepresent students. A disabled component
-- no longer counts toward merit points at all.

alter table public.attendance_settings
  add column merit_enable_hadir boolean not null default true,
  add column merit_enable_tepat_masa boolean not null default true,
  add column merit_enable_kembali_rehat boolean not null default false,
  add column merit_enable_kekal_sesi boolean not null default true,
  add column merit_enable_bonus boolean not null default false,
  add column merit_max_points smallint not null default 4;

comment on column public.attendance_settings.merit_enable_kembali_rehat is 'Defaults off -- hard to verify reliably in practice, per school request.';
comment on column public.attendance_settings.merit_enable_bonus is 'Defaults off -- ad hoc bonus points, opt-in.';
comment on column public.attendance_settings.merit_max_points is 'Max merit points achievable per day. Independent of which components are enabled -- admin sets this to match manually.';

-- ---------------------------------------------------------------------------
-- merit_student_daily: each point column (and total_points) now reads 0 for
-- a disabled component, regardless of the underlying exception/bonus data.
-- ---------------------------------------------------------------------------
create or replace view public.merit_student_daily
with (security_invoker = true) as
select
  ad.student_id,
  ad.school_date,
  s.class_id,
  ad.status as attendance_status,
  case when cfg.merit_enable_hadir and ad.status in ('hadir', 'lewat') then 1 else 0 end as point_hadir,
  case
    when not cfg.merit_enable_tepat_masa then 0
    when ad.status not in ('hadir', 'lewat') then 0
    when coalesce(e.late_to_class, false) then 0
    else 1
  end as point_tepat_masa,
  case
    when not cfg.merit_enable_kembali_rehat then 0
    when ad.status not in ('hadir', 'lewat') then 0
    when coalesce(e.missed_recess_return, false) then 0
    else 1
  end as point_kembali_rehat,
  case
    when not cfg.merit_enable_kekal_sesi then 0
    when ad.status not in ('hadir', 'lewat') then 0
    when coalesce(e.left_early, false) then 0
    else 1
  end as point_kekal_sesi,
  case when cfg.merit_enable_bonus then coalesce(b.bonus_total, 0) else 0 end as bonus,
  (case when cfg.merit_enable_hadir and ad.status in ('hadir', 'lewat') then 1 else 0 end)
    + (case
        when not cfg.merit_enable_tepat_masa then 0
        when ad.status not in ('hadir', 'lewat') then 0
        when coalesce(e.late_to_class, false) then 0
        else 1
      end)
    + (case
        when not cfg.merit_enable_kembali_rehat then 0
        when ad.status not in ('hadir', 'lewat') then 0
        when coalesce(e.missed_recess_return, false) then 0
        else 1
      end)
    + (case
        when not cfg.merit_enable_kekal_sesi then 0
        when ad.status not in ('hadir', 'lewat') then 0
        when coalesce(e.left_early, false) then 0
        else 1
      end)
    + (case when cfg.merit_enable_bonus then coalesce(b.bonus_total, 0) else 0 end) as total_points,
  s.full_name
from public.attendance_days ad
join public.students s on s.id = ad.student_id
cross join public.attendance_settings cfg
left join public.attendance_day_exceptions e
  on e.student_id = ad.student_id and e.school_date = ad.school_date
left join (
  select student_id, school_date, sum(points) as bonus_total
  from public.merit_bonus_points
  group by student_id, school_date
) b on b.student_id = ad.student_id and b.school_date = ad.school_date;

grant select on public.merit_student_daily to authenticated;

-- ---------------------------------------------------------------------------
-- fn_student_period_summary: max_points now reads the configurable setting
-- instead of a hardcoded 4.
-- ---------------------------------------------------------------------------
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
  where (p_class_id is null or s.class_id = p_class_id)
  group by s.id, s.full_name, s.class_id;
$$;

grant execute on function public.fn_student_period_summary(date, date, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- fn_class_period_summary: max_points now configurable; missed-recess-return
-- rate is decoupled from the merit toggle and reads the exception flag
-- directly, so it stays a meaningful reporting metric even while the
-- "kembali selepas rehat" component isn't counted toward merit points
-- (which is the default).
-- ---------------------------------------------------------------------------
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
  left join public.students s on s.class_id = c.id
  left join public.merit_student_daily msd
    on msd.student_id = s.id and msd.school_date between p_from and p_to
  left join public.attendance_day_exceptions e
    on e.student_id = msd.student_id and e.school_date = msd.school_date
  group by c.id, c.name;
$$;

grant execute on function public.fn_class_period_summary(date, date) to authenticated;
