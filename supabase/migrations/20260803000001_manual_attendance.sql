-- Manual attendance keyin, for the students who didn't scan their QR card
-- (and for backfilling historical attendance from before this system).
-- Reuses attendance_days.source = 'manual_override', already modelled in
-- the original attendance migration but never given a write path.

create or replace function public.fn_manual_attendance_set(
  p_student_id uuid,
  p_school_date date,
  p_status text,
  p_time time default null,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_timezone text;
  v_session text;
  v_dow smallint;
  v_cutoff time;
  v_at timestamptz;
  v_actor uuid := auth.uid();
begin
  if not public.is_staff() then
    raise exception 'not authorized';
  end if;

  if p_status not in ('hadir', 'lewat', 'tidak_hadir', 'cuti_sakit', 'urusan_rasmi') then
    raise exception 'invalid status: %', p_status;
  end if;

  select school_timezone into v_timezone from public.attendance_settings where id = 1;

  if p_status in ('hadir', 'lewat') then
    if p_time is not null then
      v_at := (p_school_date::text || ' ' || p_time::text)::timestamp at time zone v_timezone;
    else
      -- No time given (e.g. bulk backfill) -- default to that student's
      -- class/weekday cutoff, so a plain "hadir" reads as on-time rather
      -- than an arbitrary clock value.
      v_dow := extract(isodow from p_school_date);
      select c.session into v_session
      from public.students s
      join public.classes c on c.id = s.class_id
      where s.id = p_student_id;

      select cutoff_time into v_cutoff
      from public.session_cutoff_times
      where session = v_session and day_of_week = v_dow;

      v_at := (p_school_date::text || ' ' || coalesce(v_cutoff, '07:00:00')::text)::timestamp at time zone v_timezone;
    end if;
  else
    v_at := null;
  end if;

  insert into public.attendance_days (
    student_id, school_date, status, source, first_scan_id, first_scan_at, overridden_by, override_reason
  ) values (
    p_student_id, p_school_date, p_status, 'manual_override', null, v_at, v_actor, p_note
  )
  on conflict (student_id, school_date) do update
    set status = excluded.status,
        source = 'manual_override',
        first_scan_id = null,
        first_scan_at = excluded.first_scan_at,
        overridden_by = excluded.overridden_by,
        override_reason = excluded.override_reason,
        updated_at = now();
end;
$$;

grant execute on function public.fn_manual_attendance_set(uuid, date, text, time, text) to authenticated;
