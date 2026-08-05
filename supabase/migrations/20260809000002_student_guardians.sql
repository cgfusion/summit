-- Parent/guardian contact info per student. Direct-table staff RLS (same
-- pattern as qr_tokens) rather than an RPC -- this is routine contact
-- upkeep any staff member should be able to do, not a disciplinary action.

create table public.student_guardians (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students (id) on delete cascade,
  full_name text not null,
  relationship text,
  phone text,
  email text,
  is_primary boolean not null default false,
  is_emergency_contact boolean not null default false,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.student_guardians.relationship is 'Free text, e.g. Bapa / Ibu / Penjaga / Datuk.';

create index student_guardians_student_id_idx on public.student_guardians (student_id);

create trigger student_guardians_touch_updated_at
  before update on public.student_guardians
  for each row execute function public.touch_updated_at();

alter table public.student_guardians enable row level security;

create policy student_guardians_select_staff on public.student_guardians
  for select
  using (public.is_staff());

create policy student_guardians_write_staff on public.student_guardians
  for all
  using (public.is_staff())
  with check (public.is_staff());
