-- Correction: "masuk kelas tepat masa" (point 2) is NOT the morning arrival
-- scan -- it's whether the student was on time to their ~5-6 individual
-- subject periods across the day, which a single QR scan can't capture at
-- all. Per the school: always defaults to earned regardless of morning
-- arrival time (a "lewat" scan does not auto-flag it), any staff member can
-- flag an exception if the student was late to a class period, teacher's
-- judgment call. Same one-flag-per-day pattern as the other two exceptions.

alter table public.attendance_day_exceptions
  add column late_to_class boolean not null default false;

comment on column public.attendance_day_exceptions.late_to_class is 'Point 2 (masuk kelas tepat masa): late to at least one subject period that day. Independent of morning arrival time (attendance_days.status) by design.';

create or replace view public.merit_student_daily
with (security_invoker = true) as
select
  ad.student_id,
  ad.school_date,
  s.class_id,
  ad.status as attendance_status,
  case when ad.status in ('hadir', 'lewat') then 1 else 0 end as point_hadir,
  case
    when ad.status not in ('hadir', 'lewat') then 0
    when coalesce(e.late_to_class, false) then 0
    else 1
  end as point_tepat_masa,
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
    + (case
        when ad.status not in ('hadir', 'lewat') then 0
        when coalesce(e.late_to_class, false) then 0
        else 1
      end)
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
