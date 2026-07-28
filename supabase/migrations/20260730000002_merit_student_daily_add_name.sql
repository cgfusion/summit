-- Add full_name to merit_student_daily so the daily roster screen doesn't
-- need a second round trip per row. CREATE OR REPLACE VIEW only allows
-- appending columns at the end, not reordering -- kept additive.
create or replace view public.merit_student_daily
with (security_invoker = true) as
select
  ad.student_id,
  ad.school_date,
  s.class_id,
  ad.status as attendance_status,
  case when ad.status in ('hadir', 'lewat') then 1 else 0 end as point_hadir,
  case when ad.status = 'hadir' then 1 else 0 end as point_tepat_masa,
  case
    when ad.status not in ('hadir', 'lewat') then 0
    when coalesce(e.missed_recess_return, false) then 0
    else 1
  end as point_kembali_rehat,
  case
    when ad.status not in ('hadir', 'lewat') then 0
    when coalesce(e.left_early, false) then 0
    else 1
  end as point_kekal_sesi,
  coalesce(b.bonus_total, 0) as bonus,
  (case when ad.status in ('hadir', 'lewat') then 1 else 0 end)
    + (case when ad.status = 'hadir' then 1 else 0 end)
    + (case
        when ad.status not in ('hadir', 'lewat') then 0
        when coalesce(e.missed_recess_return, false) then 0
        else 1
      end)
    + (case
        when ad.status not in ('hadir', 'lewat') then 0
        when coalesce(e.left_early, false) then 0
        else 1
      end)
    + coalesce(b.bonus_total, 0) as total_points,
  s.full_name
from public.attendance_days ad
join public.students s on s.id = ad.student_id
left join public.attendance_day_exceptions e
  on e.student_id = ad.student_id and e.school_date = ad.school_date
left join (
  select student_id, school_date, sum(points) as bonus_total
  from public.merit_bonus_points
  group by student_id, school_date
) b on b.student_id = ad.student_id and b.school_date = ad.school_date;

grant select on public.merit_student_daily to authenticated;
