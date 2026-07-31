-- Reports (KPI dashboard, KK D2C.docx section 18.0) + Settings (program
-- period/cutoff times, staff account management) support.
--
-- Only 3 of the document's 5 KPIs are buildable from current data (afternoon
-- attendance %, repeat-absence count, late/missed-recess trend). The other
-- 2 (mentor coverage, follow-up timeliness) depend on the mentor/PRS and
-- absence-escalation tables that were explicitly deferred when the merit
-- module was built -- not faked here.

-- ---------------------------------------------------------------------------
-- fn_weekly_kpi_trend: one function backing all 3 buildable KPIs, grouped
-- by ISO week (Monday-start, matching period_picker.dart's convention).
-- ---------------------------------------------------------------------------
create function public.fn_weekly_kpi_trend(
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
      and (p_session is null or c.session = p_session)
  ),
  weekly_base as (
    select
      week_start,
      count(*) as total_records,
      count(*) filter (where status in ('hadir', 'lewat')) as present_count,
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
      and (p_session is null or c.session = p_session)
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

grant execute on function public.fn_weekly_kpi_trend(date, date, text) to authenticated;

-- ---------------------------------------------------------------------------
-- fn_upsert_staff_by_email: admin-only, looks up auth.users by email
-- server-side (never exposed to the client directly) and upserts profiles.
-- Replaces the manual SQL pattern used by hand up to now.
-- ---------------------------------------------------------------------------
create function public.fn_upsert_staff_by_email(
  p_email text,
  p_full_name text,
  p_role text
)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_profile public.profiles;
begin
  if not public.is_admin() then
    raise exception 'Only admins can manage staff accounts.';
  end if;

  if p_role not in ('admin', 'teacher', 'staff') then
    raise exception 'Invalid role: %', p_role;
  end if;

  select id into v_user_id from auth.users where email = p_email;
  if v_user_id is null then
    raise exception 'No account found for email %. They must sign up first.', p_email;
  end if;

  insert into public.profiles (id, full_name, role)
  values (v_user_id, p_full_name, p_role)
  on conflict (id) do update set full_name = excluded.full_name, role = excluded.role
  returning * into v_profile;

  return v_profile;
end;
$$;

grant execute on function public.fn_upsert_staff_by_email(text, text, text) to authenticated;
