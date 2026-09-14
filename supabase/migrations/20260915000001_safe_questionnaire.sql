-- ---------------------------------------------------------------------------
-- Migration: 20260915000001_safe_questionnaire.sql
-- Description: SAFE (School Anti-Bullying Framework for Empowerment) student
-- questionnaire -- 12 Likert-scale items (1-5) across 3 sections:
--   A. Pengetahuan & Kesedaran Antibuli   (items 1-4)
--   B. Amalan Sekolah Penyayang (6S)      (items 5-8)
--   C. Peranan Pembimbing Rakan Sebaya    (items 9-12)
--
-- Source doc: docs/SOAL_SELIDIK_PENILAIAN_PROGRAM_SCHOOL_ANTIBULLIYING_FRAMEWORK.docx
-- gave the formula "Peratus Skor Individu = (Jumlah Skor / 40) x 100", but
-- 12 items x 5 points = 60 max, not 40 -- confirmed with Raizal this is a
-- documentation error in the source; the correct denominator is 60. The
-- level table (10-19/20-29/30-40 out of 40) doesn't tile cleanly onto any
-- subset of the 12 items either, so levels are computed from the resulting
-- PERCENTAGE (the one number the source document is internally consistent
-- about: ">=75% = Memahami") rather than from rescaled raw-score bands:
--   < 50%        -> Rendah
--   50% to <75%  -> Sederhana
--   >= 75%       -> Tinggi (also the "Memahami" / target-met threshold)
-- ---------------------------------------------------------------------------

create table if not exists public.safe_questionnaire_responses (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null unique references public.students(id) on delete cascade,
  -- Bahagian A: Pengetahuan & Kesedaran Antibuli
  item_01 smallint not null check (item_01 between 1 and 5),
  item_02 smallint not null check (item_02 between 1 and 5),
  item_03 smallint not null check (item_03 between 1 and 5),
  item_04 smallint not null check (item_04 between 1 and 5),
  -- Bahagian B: Amalan Sekolah Penyayang (6S)
  item_05 smallint not null check (item_05 between 1 and 5),
  item_06 smallint not null check (item_06 between 1 and 5),
  item_07 smallint not null check (item_07 between 1 and 5),
  item_08 smallint not null check (item_08 between 1 and 5),
  -- Bahagian C: Peranan Pembimbing Rakan Sebaya
  item_09 smallint not null check (item_09 between 1 and 5),
  item_10 smallint not null check (item_10 between 1 and 5),
  item_11 smallint not null check (item_11 between 1 and 5),
  item_12 smallint not null check (item_12 between 1 and 5),
  submitted_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_safe_questionnaire_student on public.safe_questionnaire_responses(student_id);

alter table public.safe_questionnaire_responses enable row level security;

-- Staff-wide read (same pattern as discipline_records/counseling_records/
-- school_announcements/sudut_info_posts -- not role-gated to a specific
-- disiplin/kaunselor role, see KNOWN_ISSUES.md KI-015).
drop policy if exists "staff_read_safe_questionnaire" on public.safe_questionnaire_responses;
create policy "staff_read_safe_questionnaire"
  on public.safe_questionnaire_responses for select
  to authenticated using (true);

-- Deliberately NO insert/update/delete policy for anon or authenticated.
-- All writes go through fn_submit_safe_questionnaire (security definer),
-- which resolves and validates the student via QR token server-side before
-- writing -- this is what KI-014 should have looked like from the start:
-- identified writes from an unauthenticated client go through a function
-- that proves identity itself, never a raw table policy trying to fake it.

create or replace function public.fn_submit_safe_questionnaire(
  p_qr_token text,
  p_item_01 int, p_item_02 int, p_item_03 int, p_item_04 int,
  p_item_05 int, p_item_06 int, p_item_07 int, p_item_08 int,
  p_item_09 int, p_item_10 int, p_item_11 int, p_item_12 int
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_student_id uuid;
begin
  if p_qr_token is null or trim(p_qr_token) = '' then
    raise exception 'Token QR diperlukan';
  end if;

  if p_item_01 not between 1 and 5 or p_item_02 not between 1 and 5 or p_item_03 not between 1 and 5 or p_item_04 not between 1 and 5
     or p_item_05 not between 1 and 5 or p_item_06 not between 1 and 5 or p_item_07 not between 1 and 5 or p_item_08 not between 1 and 5
     or p_item_09 not between 1 and 5 or p_item_10 not between 1 and 5 or p_item_11 not between 1 and 5 or p_item_12 not between 1 and 5 then
    raise exception 'Setiap jawapan mestilah antara 1 hingga 5';
  end if;

  select s.id into v_student_id
  from public.students s
  left join public.qr_tokens qt on qt.student_id = s.id
  where qt.token = trim(p_qr_token)
     or qt.id::text = trim(p_qr_token)
     or s.id::text = trim(p_qr_token)
     or (s.ic_number is not null and regexp_replace(s.ic_number, '\D', '', 'g') = regexp_replace(p_qr_token, '\D', '', 'g'))
  limit 1;

  if v_student_id is null then
    raise exception 'Token QR tidak sah';
  end if;

  insert into public.safe_questionnaire_responses (
    student_id, item_01, item_02, item_03, item_04, item_05, item_06,
    item_07, item_08, item_09, item_10, item_11, item_12
  ) values (
    v_student_id, p_item_01, p_item_02, p_item_03, p_item_04, p_item_05, p_item_06,
    p_item_07, p_item_08, p_item_09, p_item_10, p_item_11, p_item_12
  )
  on conflict (student_id) do update set
    item_01 = excluded.item_01, item_02 = excluded.item_02, item_03 = excluded.item_03, item_04 = excluded.item_04,
    item_05 = excluded.item_05, item_06 = excluded.item_06, item_07 = excluded.item_07, item_08 = excluded.item_08,
    item_09 = excluded.item_09, item_10 = excluded.item_10, item_11 = excluded.item_11, item_12 = excluded.item_12,
    updated_at = now();

  return jsonb_build_object('success', true);
end;
$$;

grant execute on function public.fn_submit_safe_questionnaire(text,int,int,int,int,int,int,int,int,int,int,int,int) to anon, authenticated;

-- Returns the calling student's own response (scored), or null if they
-- haven't submitted yet. Anon-reachable by design -- same QR-token model as
-- fn_student_portal_data_by_qr.
create or replace function public.fn_get_my_safe_questionnaire(p_qr_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_student_id uuid;
  v_row public.safe_questionnaire_responses%rowtype;
  v_total int;
  v_section_a int;
  v_section_b int;
  v_section_c int;
  v_percent numeric;
begin
  if p_qr_token is null or trim(p_qr_token) = '' then
    return null;
  end if;

  select s.id into v_student_id
  from public.students s
  left join public.qr_tokens qt on qt.student_id = s.id
  where qt.token = trim(p_qr_token)
     or qt.id::text = trim(p_qr_token)
     or s.id::text = trim(p_qr_token)
     or (s.ic_number is not null and regexp_replace(s.ic_number, '\D', '', 'g') = regexp_replace(p_qr_token, '\D', '', 'g'))
  limit 1;

  if v_student_id is null then
    return null;
  end if;

  select * into v_row from public.safe_questionnaire_responses where student_id = v_student_id;
  if v_row.id is null then
    return null;
  end if;

  v_section_a := v_row.item_01 + v_row.item_02 + v_row.item_03 + v_row.item_04;
  v_section_b := v_row.item_05 + v_row.item_06 + v_row.item_07 + v_row.item_08;
  v_section_c := v_row.item_09 + v_row.item_10 + v_row.item_11 + v_row.item_12;
  v_total := v_section_a + v_section_b + v_section_c;
  v_percent := round(v_total::numeric / 60 * 100, 1);

  return jsonb_build_object(
    'total_score', v_total,
    'max_score', 60,
    'percent', v_percent,
    'level', case when v_percent >= 75 then 'tinggi' when v_percent >= 50 then 'sederhana' else 'rendah' end,
    'memahami', v_percent >= 75,
    'section_a_score', v_section_a,
    'section_b_score', v_section_b,
    'section_c_score', v_section_c,
    'items', jsonb_build_array(
      v_row.item_01, v_row.item_02, v_row.item_03, v_row.item_04,
      v_row.item_05, v_row.item_06, v_row.item_07, v_row.item_08,
      v_row.item_09, v_row.item_10, v_row.item_11, v_row.item_12
    ),
    'submitted_at', v_row.submitted_at,
    'updated_at', v_row.updated_at
  );
end;
$$;

grant execute on function public.fn_get_my_safe_questionnaire(text) to anon, authenticated;

-- Staff-facing aggregate summary. Plain SQL/invoker -- relies on the
-- staff_read_safe_questionnaire RLS policy above, same pattern as
-- fn_student_period_summary etc.
create or replace function public.fn_safe_questionnaire_summary()
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'total_responses', count(*),
    'avg_percent', coalesce(round(avg(
      (item_01+item_02+item_03+item_04+item_05+item_06+item_07+item_08+item_09+item_10+item_11+item_12)::numeric / 60 * 100
    ), 1), 0),
    'memahami_count', count(*) filter (
      where (item_01+item_02+item_03+item_04+item_05+item_06+item_07+item_08+item_09+item_10+item_11+item_12)::numeric / 60 * 100 >= 75
    ),
    'belum_memahami_count', count(*) filter (
      where (item_01+item_02+item_03+item_04+item_05+item_06+item_07+item_08+item_09+item_10+item_11+item_12)::numeric / 60 * 100 < 75
    ),
    'level_rendah', count(*) filter (
      where (item_01+item_02+item_03+item_04+item_05+item_06+item_07+item_08+item_09+item_10+item_11+item_12)::numeric / 60 * 100 < 50
    ),
    'level_sederhana', count(*) filter (
      where (item_01+item_02+item_03+item_04+item_05+item_06+item_07+item_08+item_09+item_10+item_11+item_12)::numeric / 60 * 100 >= 50
        and (item_01+item_02+item_03+item_04+item_05+item_06+item_07+item_08+item_09+item_10+item_11+item_12)::numeric / 60 * 100 < 75
    ),
    'level_tinggi', count(*) filter (
      where (item_01+item_02+item_03+item_04+item_05+item_06+item_07+item_08+item_09+item_10+item_11+item_12)::numeric / 60 * 100 >= 75
    ),
    'avg_section_a', coalesce(round(avg(item_01+item_02+item_03+item_04), 2), 0),
    'avg_section_b', coalesce(round(avg(item_05+item_06+item_07+item_08), 2), 0),
    'avg_section_c', coalesce(round(avg(item_09+item_10+item_11+item_12), 2), 0)
  )
  from public.safe_questionnaire_responses;
$$;

grant execute on function public.fn_safe_questionnaire_summary() to authenticated;
