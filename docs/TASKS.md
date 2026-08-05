# TASKS.md — Dare to Change (D2C)

> Project backlog. IDs are stable — reference them in commit messages/CHANGELOG entries where useful. "Complexity" is rough T-shirt sizing (S = one file/migration, M = a few files across layers, L = new feature spanning migration+repo+UI+route, XL = new subsystem).

## Completed

| ID | Title | Priority | Dependencies | Complexity |
|---|---|---|---|---|
| T-001 | Core schema: `profiles`, `classes`, `students`, `qr_tokens` + `is_admin()`/`is_staff()` helpers | P0 | none | L |
| T-002 | Attendance pipeline: `attendance_logs` → trigger → `attendance_days`, `audit_log` | P0 | T-001 | L |
| T-003 | QR card registration opened to all staff (was admin-only) | P1 | T-001 | S |
| T-004 | Merit module: exceptions, bonus points, awards, `merit_student_daily` view, period-summary functions | P0 | T-002 | XL |
| T-005 | Award dedupe (unique index fix for double-logging) | P1 | T-004 | S |
| T-006 | "Masuk kelas tepat masa" correction — `late_to_class` exception, decoupled from morning scan time | P1 | T-004 | M |
| T-007 | Session cutoff times: `pagi`/`petang` per-weekday cutoffs replacing single global cutoff | P0 | T-002 | M |
| T-008 | Reports (weekly KPI trend) + Settings (staff account management via `fn_upsert_staff_by_email`) | P1 | T-004, T-007 | L |
| T-009 | Manual attendance entry (`fn_manual_attendance_set`) + UI (single entry + bulk migrate) | P0 | T-002, T-007 | L |
| T-010 | Merit component toggles — per-component enable/disable + configurable max points | P1 | T-004 | M |
| T-011 | Responsive `AppShell` (sidebar ≥720px / mobile tile-grid below), theme overhaul, `HomeBackButton` fix | P1 | none | L |
| T-012 | Dashboard analytics screen v1 — stat cards, trend/status/time charts, streak leaderboard, class ranking, merit charts, heatmap, recent activity, KPI gauges | P0 | T-002, T-004 | XL |
| T-013 | Dashboard dark-mode redesign to match reference design (gradient bg, glow cards, greeting header, avatar menu) | P2 | T-012 | M |
| T-014 | Attendance period summary — day/week/month/year rates at school/Tingkatan/class scope, fixed-period denominator, real-count table alongside % table | P1 | T-012 | L |
| T-015 | At-Risk Students report (elapsed-days denominator, distinct from T-014's convention) | P1 | T-004 | M |
| T-016 | Classes-with-no-attendance-today banner, Chronic Latecomers, Leave-Type Breakdown | P1 | T-012 | M |
| T-017 | Dashboard drag-to-reorder card layout, persisted per-user (`profiles.dashboard_layout`) | P2 | T-012 | L |
| T-018 | Dashboard reorder: up/down button fallback (iPad Safari drag-handle bug fix) | P0 | T-017 | S |
| T-019 | Student enrollment status (active/suspended/expelled/transferred_out/withdrawn/deceased/graduated), bilingual, admin-gated change, 6-function roster-exclusion ripple, manual/QR-scan write guards | P0 | T-002, T-009 | XL |
| T-020 | Parent/guardian contact management UI (Student Detail sheet: add/edit/remove) | P1 | T-019 | M |
| T-021 | Bulk guardian import from XEA4402 (1078 rows, 598 students) via `scripts/generate_guardian_seed_sql.py` | P1 | T-020 | M |
| T-022 | Parent Portal — unauthenticated, token-gated read-only student status view (`fn_parent_portal_data`, `/parent/:token` route) | P1 | T-019, T-021 | L |
| T-023 | Staff UI: copy/regenerate parent-portal link (`fn_regenerate_guardian_token`) | P1 | T-022 | S |
| T-024 | AI Development Kit documentation (this `docs/` folder) | P1 | all of the above | L |

## In Progress

*(none at time of writing — T-024 is being finalized in this session; treat it as complete once all 12 files in `docs/` exist and this line is removed)*

## Blocked

| ID | Title | Priority | Blocked on | Complexity |
|---|---|---|---|---|
| T-025 | Real parent/student login (replace magic-link Parent Portal) | P3 | **Product decision + budget**: needs either an SMS provider account (Twilio/similar, has per-message cost) for phone OTP, or a parent-email data-collection step (XEA4402 has no email field) for email/password. Do not start without the user choosing one — see `PROJECT.md` §7 design decision #7 for why this was deliberately deferred | XL |
| T-026 | Mentor/PRS assignment + case-tracking module (2 of 5 official program KPIs) | P3 | **Requires new domain modeling** — no existing table models "mentor," "case," or "escalation." Needs a scoping conversation before any migration is written; do not infer a schema from `attendance_day_exceptions`, it's the wrong shape | XL |

## Next (near-term, natural continuations of shipped work)

| ID | Title | Priority | Dependencies | Complexity |
|---|---|---|---|---|
| T-027 | Absence cron: populate `attendance_days` with `source='system_cron'` for students with no scan by end of day | P1 | T-002 | M — needs a scheduled-execution mechanism (Supabase Edge Function + `pg_cron`, or an external scheduler); none exists in this project yet |
| T-028 | Extract a single shared `dateOnly(DateTime)` helper — currently duplicated across ~8 files | P2 | none | S |
| T-029 | Persist `themeModeProvider` selection (currently resets to `system` on every reload) | P2 | none | S — likely `shared_preferences`, not currently a dependency |
| T-030 | Parent Portal: basic abuse mitigation — rate limit or at least a per-token access log | P2 | T-022 | M — see `DATABASE.md` Future Migration Notes for a proposed `parent_portal_links`/access-log schema shape |
| T-031 | Enforce "at most one primary guardian per student" (partial unique index, mirroring `qr_tokens`' active-token pattern) | P2 | T-020 | S |
| T-032 | Widget/unit test coverage for at least the enrollment-status ripple (T-019) and the attendance scan pipeline (T-002) — the two highest-risk-of-silent-regression areas | P2 | none | L — no test infrastructure beyond the one smoke test exists yet; this is establishing a pattern, not just adding tests |

## Future (larger, deliberately deferred)

| ID | Title | Priority | Dependencies | Complexity |
|---|---|---|---|---|
| T-033 | Decide the fate of the unused `isar`/`isar_flutter_libs`/`path_provider` dependencies — either build the offline-cache feature they imply, or remove them | P3 | none | S to remove, XL to actually build offline support |
| T-034 | Multi-tenancy (supporting more than one school) | P4 | **explicit product decision — do not build speculatively**, see `PROJECT.md` §9 constraint | XL |
| T-035 | Storage bucket + file upload (e.g. legacy certificate attachments, student photos) | P3 | none yet requested; no existing bucket/RLS pattern to copy — would be genuinely new territory | L |
| T-036 | Design-system extraction (`AppButton`/`AppCard`/shared loading-state widget) | P4 | Only worth doing once 3+ screens show real duplication pain — see `COMPONENTS.md` "What Does Not Exist" | M |
