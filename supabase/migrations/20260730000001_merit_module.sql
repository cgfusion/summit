-- Merit module (D2C program): daily 4-point scoring derived from attendance,
-- plus exceptions, bonus points, and a reward/recognition log.
--
-- Per KK D2C.docx: 1 point each for (1) hadir ke sekolah, (2) masuk kelas
-- tepat masa, (3) kembali selepas rehat, (4) kekal hingga tamat sesi.
-- Points 1-2 are fully derivable from attendance_days.status. Points 3-4
-- are NOT observable from a single morning scan; per the document's own
-- workflow (duty teacher/PRS report students who don't return, not confirm
-- those who do), they default to earned and staff record exceptions.
--
-- Attendance stays the single source of truth -- this file only adds a
-- read-side view/functions plus small exception/bonus/award tables. No
-- merit logic is written into the attendance_* tables themselves.

-- ---------------------------------------------------------------------------
-- attendance_settings: add the D2C program period
-- ---------------------------------------------------------------------------
alter table public.attendance_settings
  add column program_start_date date not null default '2026-08-01',
  add column program_end_date date not null default '2026-10-31';

comment on column public.attendance_settings.program_start_date is 'D2C program period per KK D2C.docx (1 Ogos - 31 Oktober 2026).';

-- ---------------------------------------------------------------------------
-- attendance_day_exceptions: staff-recorded exceptions to the default
-- "earned" points 3-4. No row for a student/day = both points earned.
-- ---------------------------------------------------------------------------
create table public.attendance_day_exceptions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students (id) on delete cascade,
  school_date date not null,
  missed_recess_return boolean not null default false,
  left_early boolean not null default false,
  noted_by uuid references public.profiles (id) on delete set null,
  noted_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (student_id, school_date)
);

comment on table public.attendance_day_exceptions is 'Exception-only records for merit points 3 (kembali selepas rehat) and 4 (kekal hingga tamat sesi). Default is earned; a row here flags that it was not.';

create index attendance_day_exceptions_school_date_idx on public.attendance_day_exceptions (school_date);

create trigger attendance_day_exceptions_touch_updated_at
  before update on public.attendance_day_exceptions
  for each row execute function public.touch_updated_at();

alter table public.attendance_day_exceptions enable row level security;

create policy attendance_day_exceptions_select_staff on public.attendance_day_exceptions
  for select using (public.is_staff());

create policy attendance_day_exceptions_staff_insert on public.attendance_day_exceptions
  for insert with check (public.is_staff());

create policy attendance_day_exceptions_staff_update on public.attendance_day_exceptions
  for update using (public.is_staff()) with check (public.is_staff());

create policy attendance_day_exceptions_admin_delete on public.attendance_day_exceptions
  for delete using (public.is_admin());

-- ---------------------------------------------------------------------------
-- merit_bonus_points: optional ad hoc bonus (per KK D2C.docx "Bonus" column)
-- ---------------------------------------------------------------------------
create table public.merit_bonus_points (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students (id) on delete cascade,
  school_date date not null,
  points smallint not null check (points > 0),
  reason text,
  awarded_by uuid references public.profiles (id) on delete set null,
  awarded_at timestamptz not null default now()
);

create index merit_bonus_points_student_date_idx on public.merit_bonus_points (student_id, school_date);

alter table public.merit_bonus_points enable row level security;

create policy merit_bonus_points_select_staff on public.merit_bonus_points
  for select using (public.is_staff());

create policy merit_bonus_points_staff_insert on public.merit_bonus_points
  for insert with check (public.is_staff());

create policy merit_bonus_points_admin_write on public.merit_bonus_points
  for update using (public.is_admin()) with check (public.is_admin());

create policy merit_bonus_points_admin_delete on public.merit_bonus_points
  for delete using (public.is_admin());

-- ---------------------------------------------------------------------------
-- merit_awards: log of recognition actually handed out (section 10.0).
-- A manual "log it" action, never auto-awarded -- recognition stays a
-- deliberate staff decision per the document's own ethics section.
-- ---------------------------------------------------------------------------
create table public.merit_awards (
  id uuid primary key default gen_random_uuid(),
  category text not null check (category in (
    'full_weekly_attendance',
    'full_monthly_attendance',
    'individual_improvement',
    'most_improved_class',
    'best_transition',
    'highest_merit_class'
  )),
  scope_type text not null check (scope_type in ('student', 'class')),
  student_id uuid references public.students (id) on delete cascade,
  class_id uuid references public.classes (id) on delete cascade,
  period_start date not null,
  period_end date not null,
  awarded_by uuid references public.profiles (id) on delete set null,
  awarded_at timestamptz not null default now(),
  note text,
  check (
    (scope_type = 'student' and student_id is not null and class_id is null)
    or (scope_type = 'class' and class_id is not null and student_id is null)
  )
);

create index merit_awards_category_period_idx on public.merit_awards (category, period_start, period_end);

alter table public.merit_awards enable row level security;

create policy merit_awards_select_staff on public.merit_awards
  for select using (public.is_staff());

create policy merit_awards_staff_insert on public.merit_awards
  for insert with check (public.is_staff());

create policy merit_awards_admin_delete on public.merit_awards
  for delete using (public.is_admin());

-- ---------------------------------------------------------------------------
-- merit_student_daily: per-student per-day breakdown.
-- security_invoker is required so this runs under the QUERYING user's RLS,
-- not the view owner's -- without it every staff member would see every
-- student's data regardless of the underlying table policies.
-- ---------------------------------------------------------------------------
create view public.merit_student_daily
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
    + coalesce(b.bonus_total, 0) as total_points
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

-- ---------------------------------------------------------------------------
-- fn_student_period_summary: per-student totals over a date range.
-- Excused absences (cuti_sakit/urusan_rasmi) earn 0 points that day but do
-- NOT break full_attendance -- only tidak_hadir (unexcused) does.
-- ---------------------------------------------------------------------------
create function public.fn_student_period_summary(
  p_from date,
  p_to date,
  p_class_id uuid default null
)
returns table (
  student_id uuid,
  full_name text,
  class_id uuid,
  total_points bigint,
  max_points bigint,
  pct numeric,
  full_attendance boolean,
  days_present bigint,
  days_absent bigint
)
language sql
stable
as $$
  select
    s.id as student_id,
    s.full_name,
    s.class_id,
    coalesce(sum(msd.total_points), 0) as total_points,
    coalesce(count(msd.school_date), 0) * 4 as max_points,
    case
      when count(msd.school_date) = 0 then 0
      else round(coalesce(sum(msd.total_points), 0)::numeric / (count(msd.school_date) * 4) * 100, 1)
    end as pct,
    (count(msd.school_date) > 0 and count(*) filter (where msd.attendance_status = 'tidak_hadir') = 0) as full_attendance,
    count(*) filter (where msd.attendance_status in ('hadir', 'lewat')) as days_present,
    count(*) filter (where msd.attendance_status = 'tidak_hadir') as days_absent
  from public.students s
  left join public.merit_student_daily msd
    on msd.student_id = s.id and msd.school_date between p_from and p_to
  where (p_class_id is null or s.class_id = p_class_id)
  group by s.id, s.full_name, s.class_id;
$$;

grant execute on function public.fn_student_period_summary(date, date, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- fn_class_period_summary: per-class totals over a date range, including
-- the "best transition" metric (share of present-days with a missed
-- recess-return exception).
-- ---------------------------------------------------------------------------
create function public.fn_class_period_summary(
  p_from date,
  p_to date
)
returns table (
  class_id uuid,
  class_name text,
  total_points bigint,
  max_points bigint,
  pct numeric,
  missed_recess_return_count bigint,
  missed_recess_return_rate numeric
)
language sql
stable
as $$
  select
    c.id as class_id,
    c.name as class_name,
    coalesce(sum(msd.total_points), 0) as total_points,
    coalesce(count(msd.school_date), 0) * 4 as max_points,
    case
      when count(msd.school_date) = 0 then 0
      else round(coalesce(sum(msd.total_points), 0)::numeric / (count(msd.school_date) * 4) * 100, 1)
    end as pct,
    count(*) filter (
      where msd.point_kembali_rehat = 0 and msd.attendance_status in ('hadir', 'lewat')
    ) as missed_recess_return_count,
    case
      when count(msd.school_date) filter (where msd.attendance_status in ('hadir', 'lewat')) = 0 then 0
      else round(
        count(*) filter (
          where msd.point_kembali_rehat = 0 and msd.attendance_status in ('hadir', 'lewat')
        )::numeric
        / count(msd.school_date) filter (where msd.attendance_status in ('hadir', 'lewat')) * 100,
        1
      )
    end as missed_recess_return_rate
  from public.classes c
  left join public.students s on s.class_id = c.id
  left join public.merit_student_daily msd
    on msd.student_id = s.id and msd.school_date between p_from and p_to
  group by c.id, c.name;
$$;

grant execute on function public.fn_class_period_summary(date, date) to authenticated;
