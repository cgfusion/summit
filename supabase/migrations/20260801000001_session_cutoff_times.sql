-- Correction: cutoff time is not one value for the whole school. Forms 1-2
-- are Sidang Petang (afternoon session, must arrive before 12:05pm Mon-Thu,
-- 1:30pm Fri); Forms 3-5 are Sidang Pagi (morning session, before 7:00am
-- every day). Replaces the single attendance_settings.cutoff_time.

alter table public.classes
  add column session text not null default 'pagi' check (session in ('pagi', 'petang'));

comment on column public.classes.session is 'pagi (morning, forms 3-5) or petang (afternoon, forms 1-2) -- determines which cutoff_time schedule applies.';

update public.classes set session = 'petang' where form_level in (1, 2);
update public.classes set session = 'pagi' where form_level in (3, 4, 5);

create table public.session_cutoff_times (
  session text not null check (session in ('pagi', 'petang')),
  day_of_week smallint not null check (day_of_week between 1 and 7),
  cutoff_time time not null,
  primary key (session, day_of_week)
);

comment on table public.session_cutoff_times is 'Last on-time arrival time per session per ISO weekday (1=Monday..7=Sunday). A scan after this is Lewat.';

insert into public.session_cutoff_times (session, day_of_week, cutoff_time) values
  ('petang', 1, '12:05:00'),
  ('petang', 2, '12:05:00'),
  ('petang', 3, '12:05:00'),
  ('petang', 4, '12:05:00'),
  ('petang', 5, '13:30:00'),
  ('pagi', 1, '07:00:00'),
  ('pagi', 2, '07:00:00'),
  ('pagi', 3, '07:00:00'),
  ('pagi', 4, '07:00:00'),
  ('pagi', 5, '07:00:00');

alter table public.session_cutoff_times enable row level security;

create policy session_cutoff_times_select_staff on public.session_cutoff_times
  for select using (public.is_staff());

create policy session_cutoff_times_admin_write on public.session_cutoff_times
  for all using (public.is_admin()) with check (public.is_admin());

-- Superseded by session_cutoff_times.
alter table public.attendance_settings drop column cutoff_time;

create or replace function public.handle_attendance_scan()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_timezone text;
  v_local_ts timestamp;
  v_school_date date;
  v_dow smallint;
  v_session text;
  v_cutoff time;
  v_status text;
begin
  select school_timezone into v_timezone from public.attendance_settings where id = 1;

  v_local_ts := new.scanned_at at time zone v_timezone;
  v_school_date := v_local_ts::date;
  v_dow := extract(isodow from v_school_date);

  select c.session into v_session
  from public.students s
  join public.classes c on c.id = s.class_id
  where s.id = new.student_id;

  select cutoff_time into v_cutoff
  from public.session_cutoff_times
  where session = v_session and day_of_week = v_dow;

  -- No session/weekday match (e.g. student has no class assigned, or a
  -- weekend scan) -> v_cutoff is null, the comparison below is unknown, so
  -- it falls through to 'lewat' rather than silently guessing on-time.
  v_status := case
    when v_cutoff is not null and v_local_ts::time <= v_cutoff then 'hadir'
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
    where public.attendance_days.source = 'system_cron';

  return new;
end;
$$;
