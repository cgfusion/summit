-- Parent portal IC lookup: allow parents to enter their IC number (and optionally a child's IC)
-- to view scoped status for all students under their care.

create or replace function public.fn_parent_portal_data_by_ic(
  p_parent_ic text,
  p_child_ic text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_norm_parent_ic text;
  v_norm_child_ic text;
  v_recent_count int;
  v_student_ids uuid[];
  v_verified_student_ids uuid[];
  v_max_points int;
  v_month_start date := date_trunc('month', current_date)::date;
  v_month_end date := (date_trunc('month', current_date) + interval '1 month - 1 day')::date;
  v_week_start date := (current_date - (extract(isodow from current_date)::int - 1))::date;
  v_week_end date := v_week_start + 4;
  v_results jsonb;
begin
  -- 1. Normalize IC inputs by stripping all non-digit characters
  v_norm_parent_ic := regexp_replace(coalesce(p_parent_ic, ''), '\D', '', 'g');
  if v_norm_parent_ic = '' then
    return '[]'::jsonb;
  end if;

  if p_child_ic is not null and trim(p_child_ic) <> '' then
    v_norm_child_ic := regexp_replace(p_child_ic, '\D', '', 'g');
  end if;

  -- 2. Rate limiting: max 5 IC lookup calls in a 5-minute window
  select count(*) into v_recent_count
  from public.parent_portal_access_logs
  where accessed_at > (now() - interval '5 minutes');

  if v_recent_count >= 15 then
    raise exception 'rate limit exceeded (too many lookup requests)';
  end if;

  -- 3. Log access attempt
  insert into public.parent_portal_access_logs (token, student_id)
  values (gen_random_uuid(), null);

  -- 4. Find all student_ids linked to this parent IC
  select array_agg(distinct sg.student_id)
  into v_student_ids
  from public.student_guardians sg
  where regexp_replace(coalesce(sg.ic_number, ''), '\D', '', 'g') = v_norm_parent_ic;

  if v_student_ids is null or array_length(v_student_ids, 1) is null then
    return '[]'::jsonb;
  end if;

  -- 5. If child IC verification is supplied, ensure at least one student matches
  if v_norm_child_ic is not null and v_norm_child_ic <> '' then
    select array_agg(s.id)
    into v_verified_student_ids
    from public.students s
    where s.id = any(v_student_ids)
      and (
        regexp_replace(coalesce(s.ic_number, ''), '\D', '', 'g') = v_norm_child_ic
        or s.student_id::text = v_norm_child_ic
      );

    if v_verified_student_ids is null or array_length(v_verified_student_ids, 1) is null then
      return '[]'::jsonb;
    end if;
  end if;

  -- 6. Fetch merit max points setting
  select merit_max_points into v_max_points from public.attendance_settings where id = 1;

  -- 7. Build array of student portal records for all linked students
  select jsonb_agg(
    jsonb_build_object(
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
          where student_id = s.id
          order by school_date desc
          limit 30
        ) recent
      ), '[]'::jsonb),
      'attendance_week', jsonb_build_object(
        'present', (
          select count(*) filter (where status in ('hadir', 'lewat'))
          from public.attendance_days
          where student_id = s.id and school_date between v_week_start and v_week_end
        ),
        'total_days', public.fn_weekday_count(v_week_start, v_week_end)
      ),
      'attendance_month', jsonb_build_object(
        'present', (
          select count(*) filter (where status in ('hadir', 'lewat'))
          from public.attendance_days
          where student_id = s.id and school_date between v_month_start and v_month_end
        ),
        'total_days', public.fn_weekday_count(v_month_start, v_month_end)
      ),
      'merit_month', jsonb_build_object(
        'total_points', (
          select coalesce(sum(total_points), 0) from public.merit_student_daily
          where student_id = s.id and school_date between v_month_start and v_month_end
        ),
        'days_recorded', (
          select count(*) from public.merit_student_daily
          where student_id = s.id and school_date between v_month_start and v_month_end
        ),
        'max_points_per_day', v_max_points
      )
    )
    order by c.name, s.full_name
  )
  into v_results
  from public.students s
  left join public.classes c on c.id = s.class_id
  where s.id = any(v_student_ids);

  return coalesce(v_results, '[]'::jsonb);
end;
$$;

grant execute on function public.fn_parent_portal_data_by_ic(text, text) to anon, authenticated;
