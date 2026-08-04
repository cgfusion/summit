-- Two more principal-facing reports:
-- 1. Chronic latecomers: students with several 'lewat' days in a trailing
--    window, so a teacher can intervene on a pattern instead of one-off
--    lateness.
-- 2. Leave-type breakdown: how much of a period's absences were
--    unexplained (tidak_hadir) vs excused (cuti_sakit / urusan_rasmi), to
--    check the exception workflow is actually being used.
-- ("Classes with no attendance recorded today" needs no new SQL -- it
-- reuses fn_class_attendance_summary with from=to=today and reads
-- recorded_count = 0.)

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
  group by s.id, s.full_name, s.class_id, c.name
  having count(*) filter (where ad.status = 'lewat') >= p_min_late
  order by count(*) filter (where ad.status = 'lewat') desc, s.full_name;
$$;

grant execute on function public.fn_chronic_latecomers(date, int, int) to authenticated;

create or replace function public.fn_leave_type_breakdown(p_from date, p_to date)
returns table (
  tidak_hadir_count bigint,
  cuti_sakit_count bigint,
  urusan_rasmi_count bigint
)
language sql
stable
as $$
  select
    count(*) filter (where status = 'tidak_hadir') as tidak_hadir_count,
    count(*) filter (where status = 'cuti_sakit') as cuti_sakit_count,
    count(*) filter (where status = 'urusan_rasmi') as urusan_rasmi_count
  from public.attendance_days
  where school_date between p_from and p_to;
$$;

grant execute on function public.fn_leave_type_breakdown(date, date) to authenticated;
