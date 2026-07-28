-- Core reference schema: profiles (staff), classes, students, qr_tokens.
-- Merit-related tables intentionally excluded until the full merit rulebook is provided.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- profiles: one row per staff member (admin/teacher), linked 1:1 to auth.users
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  role text not null default 'teacher' check (role in ('admin', 'teacher', 'staff')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is 'Staff accounts. One row per Supabase auth user.';

-- SECURITY DEFINER helpers so RLS policies can check role without recursive
-- self-selects on profiles (same pattern used in the SAB Youth Portal project).
create function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

create function public.is_staff()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid()
  );
$$;

create function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.touch_updated_at();

alter table public.profiles enable row level security;

create policy profiles_select_self_or_admin on public.profiles
  for select
  using (id = auth.uid() or public.is_admin());

create policy profiles_admin_write on public.profiles
  for all
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- classes
-- ---------------------------------------------------------------------------
create table public.classes (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  form_level smallint not null check (form_level between 1 and 6),
  homeroom_teacher_name text,
  homeroom_teacher_id uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.classes is 'e.g. name=''1 Citra'', form_level=1. Sourced from XEA4402 "NAMA KELAS"/"TAHUN / TINGKATAN".';
comment on column public.classes.homeroom_teacher_name is 'Raw teacher name from the XEA4402 import ("NAMA GURU KELAS"), kept even before that teacher has a login. homeroom_teacher_id can be linked once they have a profiles row.';

create trigger classes_touch_updated_at
  before update on public.classes
  for each row execute function public.touch_updated_at();

alter table public.classes enable row level security;

create policy classes_select_staff on public.classes
  for select
  using (public.is_staff());

create policy classes_admin_write on public.classes
  for all
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- students
-- ---------------------------------------------------------------------------
create table public.students (
  id uuid primary key default gen_random_uuid(),
  student_id bigint not null unique,
  full_name text not null,
  ic_number text,
  ic_type text,
  date_of_birth date,
  gender text check (gender in ('LELAKI', 'PEREMPUAN')),
  study_status text not null default 'BERSEKOLAH',
  enrolled_at date,
  class_joined_at date,
  class_id uuid references public.classes (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.students is 'Sourced from XEA4402 master export. student_id = "ID MURID" (authoritative external id).';
comment on column public.students.gender is 'Source: JANTINA (LELAKI/PEREMPUAN, as stored in the MOE master export)';
comment on column public.students.study_status is 'Source: STATUS PENGAJIAN, e.g. BERSEKOLAH. Left unconstrained (free text) since the full MOE APDM value set is not confirmed from the sample data -- do not hardcode a check constraint without verifying against the school''s actual status list.';

create index students_class_id_idx on public.students (class_id);
create index students_full_name_idx on public.students (full_name);

create trigger students_touch_updated_at
  before update on public.students
  for each row execute function public.touch_updated_at();

alter table public.students enable row level security;

create policy students_select_staff on public.students
  for select
  using (public.is_staff());

create policy students_admin_write on public.students
  for all
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- qr_tokens: at most one ACTIVE token per student at a time
-- ---------------------------------------------------------------------------
create table public.qr_tokens (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students (id) on delete cascade,
  token text not null unique,
  status text not null default 'active' check (status in ('active', 'revoked', 'reissued')),
  printed_class_snapshot text,
  issued_at timestamptz not null default now(),
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

comment on table public.qr_tokens is 'Physical QR card tokens. printed_class_snapshot records the class printed on the card at issue time, for reconciling against later class reassignments.';

create unique index qr_tokens_one_active_per_student
  on public.qr_tokens (student_id)
  where (status = 'active');

create index qr_tokens_token_idx on public.qr_tokens (token);

alter table public.qr_tokens enable row level security;

-- Staff may look up a token to resolve a scan; only admins issue/revoke cards.
create policy qr_tokens_select_staff on public.qr_tokens
  for select
  using (public.is_staff());

create policy qr_tokens_admin_write on public.qr_tokens
  for all
  using (public.is_admin())
  with check (public.is_admin());
