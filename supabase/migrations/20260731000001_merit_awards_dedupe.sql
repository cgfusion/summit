-- Prevent the same award being logged twice for the same category/scope/period.
-- A plain UNIQUE(student_id, class_id, ...) would NOT catch this: standard SQL
-- treats each NULL as distinct, and exactly one of student_id/class_id is
-- always NULL here (per the existing scope_type check constraint) -- so two
-- class-scoped rows would both have student_id = NULL and never collide.
-- coalesce() collapses both columns into a single "scope key" so the index
-- actually enforces one-per-period.
create unique index merit_awards_dedupe_idx
  on public.merit_awards (category, scope_type, coalesce(student_id, class_id), period_start, period_end);
