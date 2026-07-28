-- Attendance pipeline: raw scan events -> canonical daily status.
-- Deliberately contains no merit/points logic (merit_rules/merit_ledger are a
-- separate module, pending the full merit rulebook from the school).

-- ---------------------------------------------------------------------------
-- attendance_settings: single-row config (cutoff time used for hadir/lewat)
-- ---------------------------------------------------------------------------
create table public.attendance_settings (
  id smallint primary key default 1 check (id = 1),
  cutoff_time time not null default '07:30:00',
  school_timezone text not null default 'Asia/Kuala_Lumpur',
  updated_at timestamptz not null default now()
);

comment on table public.attendance_settings is 'Singleton config row. cutoff_time is the last on-time arrival time of day; a scan after this is Lewat.';

insert into public.attendance_settings (id) values (1);

create trigger attendance_settings_touch_updated_at
  before update on public.attendance_settings
  for each row execute function public.touch_updated_at();

alter table public.attendance_settings enable row level security;

create policy attendance_settings_select_staff on public.attendance_settings
  for select
  using (public.is_staff());

create policy attendance_settings_admin_write on public.attendance_settings
  for all
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- attendance_logs: append-only raw scan events (source of truth for scans)
-- ---------------------------------------------------------------------------
create table public.attendance_logs (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students (id) on delete cascade,
  scanned_at timestamptz not null default now(),
  scanned_by uuid references public.profiles (id) on delete set null,
  device_label text,
  created_at timestamptz not null default now()
);

comment on table public.attendance_logs is 'Append-only raw QR scan events. Never updated or deleted by the app; attendance_days is the derived canonical record.';

create index attendance_logs_student_id_idx on public.attendance_logs (student_id);
create index attendance_logs_scanned_at_idx on public.attendance_logs (scanned_at);

alter table public.attendance_logs enable row level security;

-- Any staff member (teacher operating a scanner) may log a scan; nobody may
-- update/delete (no policies granted for those actions -> denied by default).
create policy attendance_logs_select_staff on public.attendance_logs
  for select
  using (public.is_staff());

create policy attendance_logs_insert_staff on public.attendance_logs
  for insert
  with check (public.is_staff());

-- ---------------------------------------------------------------------------
-- attendance_days: canonical one-row-per-student-per-school-day status
-- ---------------------------------------------------------------------------
create table public.attendance_days (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students (id) on delete cascade,
  school_date date not null,
  status text not null check (status in ('hadir', 'lewat', 'tidak_hadir', 'cuti_sakit', 'urusan_rasmi')),
  source text not null default 'qr_scan' check (source in ('qr_scan', 'system_cron', 'manual_override')),
  first_scan_id uuid references public.attendance_logs (id) on delete set null,
  first_scan_at timestamptz,
  overridden_by uuid references public.profiles (id) on delete set null,
  override_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (student_id, school_date)
);

comment on table public.attendance_days is 'Canonical daily attendance status. Created either by the first qr_scan of the day, or by the absence cron for students with no scan. Admins may override via manual_override.';

create index attendance_days_school_date_idx on public.attendance_days (school_date);
create index attendance_days_student_id_idx on public.attendance_days (student_id);

create trigger attendance_days_touch_updated_at
  before update on public.attendance_days
  for each row execute function public.touch_updated_at();

alter table public.attendance_days enable row level security;

create policy attendance_days_select_staff on public.attendance_days
  for select
  using (public.is_staff());

-- Only admins may directly write attendance_days (manual overrides / cron
-- uses the service role, which bypasses RLS). The qr-scan path never writes
-- here directly -- it always goes through attendance_logs + the trigger below.
create policy attendance_days_admin_write on public.attendance_days
  for all
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- audit_log: generic append-only audit trail
-- ---------------------------------------------------------------------------
create table public.audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles (id) on delete set null,
  action text not null,
  table_name text not null,
  record_id uuid not null,
  before jsonb,
  after jsonb,
  created_at timestamptz not null default now()
);

comment on table public.audit_log is 'Append-only audit trail. Populated by triggers (e.g. attendance_days status changes), not written directly by the app.';

create index audit_log_table_record_idx on public.audit_log (table_name, record_id);

alter table public.audit_log enable row level security;

create policy audit_log_select_admin on public.audit_log
  for select
  using (public.is_admin());

-- ---------------------------------------------------------------------------
-- Trigger: attendance_days status change -> audit_log
-- ---------------------------------------------------------------------------
create function public.audit_attendance_days_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (tg_op = 'UPDATE' and new.status is distinct from old.status) then
    insert into public.audit_log (actor_id, action, table_name, record_id, before, after)
    values (
      new.overridden_by,
      'attendance_status_change',
      'attendance_days',
      new.id,
      to_jsonb(old),
      to_jsonb(new)
    );
  end if;
  return new;
end;
$$;

create trigger attendance_days_audit
  after update on public.attendance_days
  for each row execute function public.audit_attendance_days_change();

-- ---------------------------------------------------------------------------
-- Trigger: attendance_logs insert -> derive/refresh attendance_days
-- ---------------------------------------------------------------------------
create function public.handle_attendance_scan()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_settings record;
  v_local_ts timestamp;
  v_school_date date;
  v_status text;
begin
  select cutoff_time, school_timezone into v_settings
  from public.attendance_settings where id = 1;

  v_local_ts := new.scanned_at at time zone v_settings.school_timezone;
  v_school_date := v_local_ts::date;
  v_status := case
    when v_local_ts::time <= v_settings.cutoff_time then 'hadir'
    else 'lewat'
  end;

  insert into public.attendance_days (
    student_id, school_date, status, source, first_scan_id, first_scan_at
  ) values (
    new.student_id, v_school_date, v_status, 'qr_scan', new.id, new.scanned_at
  )
  on conflict (student_id, school_date) do update
    set status = excluded.status,
        source = 'qr_scan',
        first_scan_id = excluded.first_scan_id,
        first_scan_at = excluded.first_scan_at,
        overridden_by = null,
        override_reason = null,
        updated_at = now()
    -- Only replace a cron-generated "absent" placeholder for that day.
    -- A row from an earlier scan, or a manual override, is left untouched.
    where public.attendance_days.source = 'system_cron';

  return new;
end;
$$;

create trigger attendance_logs_after_insert
  after insert on public.attendance_logs
  for each row execute function public.handle_attendance_scan();
