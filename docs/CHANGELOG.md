# CHANGELOG.md — Dare to Change (D2C)

> Chronological, oldest first — this reads as the build story, which matters here because later design decisions (e.g. the enrollment-status ripple, the two different denominator conventions) only make sense in light of what came before. Dates are the migration-file timestamps, the most reliable dating source in this repo (no separate release-tagging scheme exists — every push to `main` auto-deploys).

## 2026-07-28 — Foundation
- Initialized Supabase project config, core schema: `profiles` (staff accounts), `classes`, `students`, `qr_tokens`. `is_admin()`/`is_staff()` RLS helper functions established as the pattern for every future policy.
- Attendance pipeline: `attendance_settings` (singleton config), `attendance_logs` (append-only scans), `attendance_days` (canonical daily status), `audit_log`. The scan → trigger → derived-status pipeline (`handle_attendance_scan()`) established as the core mechanism the whole app builds on.
- Python seed script (`generate_seed_sql.py`) written against the school's XEA4402 SIS export + QR card recovery export; initial data imported (614 students, class rosters).
- Flutter scaffold: Student, Class, QR-scan/Attendance features (domain/data/presentation layers), `go_router` wired, initial theme.
- Register QR Card screen + unrecognised-scan-to-register flow.

## 2026-07-29 — QR access widened
- QR card registration/reissue opened to any staff member (was admin-only) — recognized as a routine teacher task, not a disciplinary action.

## 2026-07-30 to 2026-07-31 — Merit module
- Full merit scoring module: `attendance_day_exceptions`, `merit_bonus_points`, `merit_awards`, the `merit_student_daily` **view** (the single computed source of all merit data — no stored ledger). `fn_student_period_summary`/`fn_class_period_summary` for reporting.
- Merit daily roster screen, class summary screen, rewards/recognition screen with 6 award categories, all wired into the router and dashboard tiles.
- Fixed a double-award-logging bug via a `coalesce()`-based unique index (`merit_awards_dedupe_idx`) — a plain multi-column unique constraint doesn't work when exactly one of two nullable scope columns is always null.
- Corrected the "masuk kelas tepat masa" (on-time-to-class) merit point: it is **not** the morning arrival scan, but lateness to any of ~5-6 individual subject periods — added a dedicated `late_to_class` exception flag, decoupled from `attendance_days.status`.

## 2026-08-01 to 2026-08-02 — Session-aware cutoffs, Reports, Settings
- Replaced the single global cutoff time with `session_cutoff_times` (per `pagi`/`petang` session, per ISO weekday) — Forms 1-2 (afternoon session) and Forms 3-5 (morning session) have genuinely different on-time thresholds. The scan trigger was rewritten to look up class session + weekday.
- Reports feature: `fn_weekly_kpi_trend` (attendance rate, repeat-absence count, late/missed-recess trend), explicitly scoped to the 3 of 5 official program KPIs buildable from existing data (mentor coverage and follow-up timeliness deferred — no mentor/case data model exists).
- Settings feature: program period, merit toggles, cutoff-time editing, staff account management (`fn_upsert_staff_by_email` — requires the person to have signed in at least once already; no invite-email flow).

## 2026-08-03 to 2026-08-04 — Manual entry, configurable merit
- Manual attendance entry (`fn_manual_attendance_set`) — single-entry and bulk-migrate UI, for students who didn't scan or for backfilling paper records. Defaults `hadir`/`lewat` time to the class's cutoff when no explicit time is given.
- Per-component merit configurability — each of the 4 components (hadir, tepat masa, kembali rehat, kekal sesi) plus bonus can be individually enabled/disabled per school preference; `merit_max_points` made configurable rather than hardcoded to 4.

## 2026-08-05 — Dashboard v1, responsive shell
- Responsive `AppShell`: persistent sidebar ≥720px width, mobile tile-grid Home below it, with a manual override toggle (`LayoutMode`). Bold/vibrant theme overhaul from stock Material defaults.
- Full Dashboard analytics screen: 6 stat cards with vs-yesterday deltas, attendance trend/status/time-of-day charts, streak leaderboard, class attendance ranking (with a Worst-5 toggle), merit trend/distribution charts, an attendance heatmap, a recent-activity feed, and KPI gauges — 7 backing SQL functions (`fn_attendance_day_summary` through `fn_kpi_overview`), all reading strictly from existing tables/views, no new source-of-truth data.
- Iterated dark mode to match a reference design: gradient page background, glow-accented stat cards, greeting header with date filter, avatar-menu account footer.

## 2026-08-06 — Period summaries, principal-facing reports
- `fn_attendance_period_summary`: day/week/month/year attendance rates at whole-school, Tingkatan, and per-class scope, anchored to a reference date — using a **deliberately fixed, full-period denominator** (not elapsed-days), per an explicit teacher request that the rate read as "progress toward 100%" mid-period. Expanded to add the Tingkatan tier and expose raw present/total counts alongside the percentages (a second table, not just %).
- At-Risk Students report added to Reports — reusing `fn_student_period_summary`, whose denominator convention is deliberately **elapsed/actual-recorded-days**, distinct from the period-summary convention above. This distinction was reasoned through explicitly and is the most important "don't unify these" note in the whole codebase (see `PROJECT.md` §7 #3).
- Home Back Button fix — every non-Dashboard/non-Home screen now has an explicit `HomeBackButton` in its AppBar, because Flutter's default back-arrow silently disappears whenever there's nothing to pop (deep link, page reload), which is exactly the mobile navigation state most users are in.

## 2026-08-07 — More principal-facing signals, Dashboard rearrange
- Added: "Classes with no attendance recorded today" compliance banner (reusing `fn_class_attendance_summary` with `from=to=today`, filtering `recorded_count=0` client-side), Chronic Latecomers (`fn_chronic_latecomers`, trailing-window `lewat` count), Leave-Type Breakdown (`fn_leave_type_breakdown`).
- Dashboard card layout made user-customizable and persisted server-side (`profiles.dashboard_layout jsonb`, via `fn_update_dashboard_layout` since direct `profiles` writes are otherwise admin-only). Shipped with drag-and-drop reordering.
- **Bug found and fixed same day**: the drag handle silently doesn't render/work on iPad Safari (`ReorderableListView`'s `buildDefaultDragHandles` platform-detection quirk, combined with a gesture-arena loss against the sheet's own scrollable). Fixed by forcing the handle on for desktop/Android **and** adding explicit up/down `IconButton`s as a guaranteed-everywhere fallback — both are kept, not just the fix.

## 2026-08-09 to 2026-08-10 — Student enrollment status, guardian contacts
- Student enrollment status: `active/suspended/expelled/transferred_out/withdrawn/deceased/graduated`, bilingual labels (English/Malay, matching MOE terminology), admin-only change via `fn_update_student_status` with a recorded audit trail (who/when/why). Six existing roster/summary SQL functions updated to exclude non-active students from *current* views while leaving all historical data untouched; the manual-attendance RPC and the QR-scan flow both gained guards rejecting writes for inactive students (server-side and client-side respectively).
- Parent/guardian contact management added to a new Student Detail sheet (enrollment status change + guardian list in one place), staff-writable (not admin-only — routine contact upkeep).
- Bulk-imported 1078 real guardian records (598 students) from the school's XEA4402 export's PENJAGA 1/2 blocks — name, IC number, relationship, phone — via a new idempotent seed-generation script, mirroring the original student-import script's conventions.

## 2026-08-11 — Parent Portal
- Built an unauthenticated, per-guardian magic-link Parent Portal (`/parent/:token`) — chosen specifically because the guardian data has phone/IC but no verified email, and there was no SMS-provider budget for OTP login. `fn_parent_portal_data`, a `security definer` function granted to `anon`, is the one function in the entire schema callable without a session; it is scoped so tightly (one token → one student, nothing else reachable) that this was treated as a deliberate, carefully-reviewed exception, not a default.
- Staff can copy or regenerate a guardian's link from the Student Detail sheet; regenerating immediately invalidates the old one.
- Explicitly accepted trade-off, not a bug: no rate limiting, no link expiry, no access audit log on the portal — flagged for future hardening (see `TASKS.md` T-030).

## 2026-08-11 (later) — AI Development Kit
- This `docs/` folder (`PROJECT.md` through `NEXT_SESSION.md`) written as a complete handoff kit so a new engineer (human or AI) can become productive without re-deriving context from the build history.

## 2026-08-11 (even later) — WhatsApp PIBG report generator
- Added a "WhatsApp PIBG Reports" section to Reports: reproduces, byte-for-byte in structure, the daily attendance message a teacher previously typed by hand for the parent WhatsApp group (per-class present/total counts, a "Semua Murid Hadir Tahniah" congratulations line for a zero-absence class, per-Tingkatan subtotals with percentages, a dashed separator between Tingkatan blocks). One card per session (Sesi Petang = Tingkatan 1-2, Sesi Pagi = Tingkatan 3-5, derived from `classes.session` rather than hardcoded), each with a one-tap Copy button — the teacher still pastes it into WhatsApp themselves; no WhatsApp Business API integration was built (a separate infra/cost decision, deliberately not assumed).
- No new SQL — reuses `fn_attendance_period_summary`, which already returns per-class and per-Tingkatan day present/total counts. Added `classes.session` to the `SchoolClass` Flutter entity (the column already existed in the DB; it just wasn't exposed to the client yet).
- Also added a free-text "Special Announcement (Discipline)" composer in the same section, for the discipline teacher's ad hoc PIBG-group posts — an optional "Attach Student" search prefills a Nama/Kelas header, then copy-to-clipboard. Stateless, nothing persisted.
- Verified live against real 5 Aug 2026 data: exact per-class counts, correct Malay date/day names ("05 Ogos 2026/ Rabu"), and the zero-absence special case all confirmed matching the teacher's original manual format.

## 2026-08-12 — Recommended Next Steps (T-027, T-028, T-030, T-031, T-032)
- **T-028 (Shared `dateOnly` utility)**: Extracted `dateOnly` and `formatDateOnly` into `core/utils/date_utils.dart` and refactored 8 call sites across repositories and presentation screens.
- **T-031 (Primary Guardian Constraint)**: Added `student_guardians_one_primary_per_student` partial unique index on `student_guardians(student_id) WHERE is_primary = true`, after deduplicating existing primary records.
- **T-030 (Parent Portal Hardening)**: Created `parent_portal_access_logs` access-logging table and added a 20 request/minute rate limit in `fn_parent_portal_data`.
- **T-027 (Absence Cron)**: Added `fn_populate_absence_cron(p_school_date)` RPC function to populate `'tidak_hadir'` with `source = 'system_cron'` for unscanned active students.
- **T-032 (Automated Unit Tests)**: Created unit test suite in `app/test/unit/` covering `date_utils`, `EnrollmentStatus`, and `AttendanceStatus` enums.
- **T-038 (Parent IC Lookup Option)**: Built a dedicated `/parent` route allowing parents/guardians to enter their IC number (with optional child IC verification). Uses `fn_parent_portal_data_by_ic` to normalize IC input, enforce rate limits, and display a multi-student tabbed dashboard when a parent has multiple children at the school.

