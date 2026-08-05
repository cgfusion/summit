-- Adds the guardian's IC number (from XEA4402's NO. PENGENALAN PENJAGA 1/2)
-- and a natural key so the bulk import from that source can be re-run
-- safely (on conflict do update) rather than accumulating duplicates.

alter table public.student_guardians add column ic_number text;

alter table public.student_guardians
  add constraint student_guardians_student_name_key unique (student_id, full_name);
