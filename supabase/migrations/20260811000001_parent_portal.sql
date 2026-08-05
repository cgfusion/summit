-- Parent portal: a read-only, no-login view of one student's attendance,
-- merit, and enrollment status, reached via a private unguessable link
-- (https://.../#/parent/<access_token>) rather than a real account -- the
-- guardian data imported from XEA4402 has no email/phone verified for
-- login, so a magic-link token is the pragmatic option. The ONLY gate is
-- guessing a random uuid (122 bits), same trust model as any "share link".

alter table public.student_guardians
  add column access_token uuid not null default gen_random_uuid() unique;

-- ---------------------------------------------------------------------------
-- fn_regenerate_guardian_token: staff-only, for when a link needs revoking
-- (e.g. shared with the wrong person) without deleting the guardian record.
-- ---------------------------------------------------------------------------
create function public.fn_regenerate_guardian_token(p_guardian_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_new_token uuid := gen_random_uuid();
begin
  if not public.is_staff() then
    raise exception 'not authorized';
  end if;

  update public.student_guardians set access_token = v_new_token where id = p_guardian_id;
  return v_new_token;
end;
$$;

grant execute on function public.fn_regenerate_guardian_token(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- fn_parent_portal_data: the only thing an unauthenticated caller can read
-- through this path. Scoped strictly to the one student matched by the
-- token -- no other table or student is ever reachable from here. Returns
-- null for an unknown/invalid token (no distinction made between "bad
-- token" and "token valid, no data" to avoid a validity oracle).
-- ---------------------------------------------------------------------------
create function public.fn_parent_portal_data(p_token uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_student_id uuid;
  v_max_points int;
  v_month_start date := date_trunc('month', current_date)::date;
  v_month_end date := (date_trunc('month', current_date) + interval '1 month - 1 day')::date;
  v_week_start date := (current_date - (extract(isodow from current_date)::int - 1))::date;
  v_week_end date := v_week_start + 4;
  v_result jsonb;
begin
  select student_id into v_student_id from public.student_guardians where access_token = p_token;
  if v_student_id is null then
    return null;
  end if;

  select merit_max_points into v_max_points from public.attendance_settings where id = 1;

  select jsonb_build_object(
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
        where student_id = v_student_id
        order by school_date desc
        limit 30
      ) recent
    ), '[]'::jsonb),
    'attendance_week', jsonb_build_object(
      'present', (
        select count(*) filter (where status in ('hadir', 'lewat'))
        from public.attendance_days
        where student_id = v_student_id and school_date between v_week_start and v_week_end
      ),
      'total_days', public.fn_weekday_count(v_week_start, v_week_end)
    ),
    'attendance_month', jsonb_build_object(
      'present', (
        select count(*) filter (where status in ('hadir', 'lewat'))
        from public.attendance_days
        where student_id = v_student_id and school_date between v_month_start and v_month_end
      ),
      'total_days', public.fn_weekday_count(v_month_start, v_month_end)
    ),
    'merit_month', jsonb_build_object(
      'total_points', (
        select coalesce(sum(total_points), 0) from public.merit_student_daily
        where student_id = v_student_id and school_date between v_month_start and v_month_end
      ),
      'days_recorded', (
        select count(*) from public.merit_student_daily
        where student_id = v_student_id and school_date between v_month_start and v_month_end
      ),
      'max_points_per_day', v_max_points
    )
  )
  into v_result
  from public.students s
  left join public.classes c on c.id = s.class_id
  where s.id = v_student_id;

  return v_result;
end;
$$;

grant execute on function public.fn_parent_portal_data(uuid) to anon, authenticated;
