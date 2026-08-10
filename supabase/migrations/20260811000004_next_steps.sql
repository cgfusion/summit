-- Next steps migration: T-031 (primary guardian unique constraint),
-- T-030 (parent portal hardening: access log & rate limiting),
-- T-027 (absence cron helper).

-- ---------------------------------------------------------------------------
-- T-031: Enforce at most one primary guardian per student
-- ---------------------------------------------------------------------------
with ranked as (
  select id, row_number() over (partition by student_id order by created_at asc, id asc) as rn
  from public.student_guardians
  where is_primary = true
)
update public.student_guardians
set is_primary = false
where id in (select id from ranked where rn > 1);

create unique index if not exists student_guardians_one_primary_per_student
  on public.student_guardians (student_id)
  where is_primary = true;

-- ---------------------------------------------------------------------------
-- T-030: Parent Portal Hardening -- access log & rate limiting
-- ---------------------------------------------------------------------------
create table if not exists public.parent_portal_access_logs (
  id uuid primary key default gen_random_uuid(),
  token uuid not null,
  student_id uuid null references public.students(id) on delete cascade,
  accessed_at timestamptz not null default now()
);

create index if not exists parent_portal_access_logs_token_idx
  on public.parent_portal_access_logs (token, accessed_at desc);

alter table public.parent_portal_access_logs enable row level security;

drop policy if exists parent_portal_access_logs_select_staff on public.parent_portal_access_logs;
create policy parent_portal_access_logs_select_staff
  on public.parent_portal_access_logs
  for select using (public.is_staff());

create or replace function public.fn_parent_portal_data(p_token uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_student_id uuid;
  v_max_points int;
  v_recent_count int;
  v_month_start date := date_trunc('month', current_date)::date;
  v_month_end date := (date_trunc('month', current_date) + interval '1 month - 1 day')::date;
  v_week_start date := (current_date - (extract(isodow from current_date)::int - 1))::date;
  v_week_end date := v_week_start + 4;
  v_result jsonb;
begin
  -- Rate limiting: max 20 requests per minute per token
  select count(*) into v_recent_count
  from public.parent_portal_access_logs
  where token = p_token and accessed_at > (now() - interval '1 minute');

  if v_recent_count >= 20 then
    raise exception 'rate limit exceeded (too many requests for this link)';
  end if;

  select student_id into v_student_id from public.student_guardians where access_token = p_token;

  -- Log access attempt
  insert into public.parent_portal_access_logs (token, student_id)
  values (p_token, v_student_id);

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

-- ---------------------------------------------------------------------------
-- T-027: Absence Cron -- populate missing attendance_days rows for active students
-- ---------------------------------------------------------------------------
create or replace function public.fn_populate_absence_cron(p_school_date date default current_date)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inserted_count int;
begin
  if not public.is_staff() then
    raise exception 'not authorized';
  end if;

  insert into public.attendance_days (student_id, school_date, status, source)
  select s.id, p_school_date, 'tidak_hadir', 'system_cron'
  from public.students s
  where s.enrollment_status = 'active'
  on conflict (student_id, school_date) do nothing;

  get diagnostics v_inserted_count = row_count;
  return v_inserted_count;
end;
$$;

grant execute on function public.fn_populate_absence_cron(date) to authenticated;
