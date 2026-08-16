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
- Chronic Latecomers report added to Reports — backing function `fn_chronic_latecomers` returning students with 3+ late scans in a given period.
- Leave Breakdown report added to Reports — backing function `fn_leave_type_breakdown` giving a per-class summary of `cuti_sakit` and `urusan_rasmi`.
- Dashboard layout rearranged per principal preference: Present card first, Absent second, Late third, Leave fourth. Stat cards click through directly to the corresponding filtered drill-down modal or report page.

## 2026-08-08 — Enrollment status & parent contact overhaul
- Student enrollment status tracking (`EnrollmentStatus`: `active`, `suspended`, `expelled`, `transferred`, `graduated`) added across database schema, RPC functions, Flutter entities, and UI screens.
- `student_guardians` table created with natural keys (`student_id`, `full_name`) allowing safe bulk imports from SIS exports without duplicates. Guardian IC numbers added to enable Parent Portal IC lookup.

## 2026-08-10 — Discipline & Counseling (SSDOP/UBK), Parent Portal IC Lookup, Present Stat Card Alignment
- **Discipline & Counseling Module**: Created PostgreSQL migration `20260811000002_discipline_and_counseling.sql` establishing `discipline_records` and `counseling_records` tables with index structures, RLS policies, and summary RPC `fn_student_discipline_summary(p_student_id)`. Created `DisciplineCounselingScreen` with 4 tabs (*Kes Disiplin SSDOP*, *Sesi Kaunseling UBK*, *Peti Suara Murid*, and *Ringkasan & Analisis*). Added `disiplin` (**Guru Disiplin**) and `kaunselor` (**Guru Kaunselor**) roles with RBAC security enforcement.
- **Parent Portal IC Lookup**: Created `fn_parent_portal_data_by_ic(p_ic_number)` allowing guardians to access real-time child attendance & merit progress by keying in their MyKad / IC number (`/#/parent`), adding direct shortcut button on main `SignInScreen`.
- **Dashboard Stat Card Alignment**: Updated `fn_attendance_day_summary` to include `cuti_sakit` and `urusan_rasmi` under present count breakdown (`328 Total Present: 320 Hadir • 7 MC • 1 Rasmi`) matching filter chip counts 100%.

## 2026-08-11 — Student Portal & Student Voice (Suara Murid), High-Tech Landing Page
- **Student Portal & Student Voice**: Created `StudentPortalScreen` at route `/#/student` authenticated securely via **Student Name Tag QR Code camera scan or QR token entry** (eliminating IC impersonation). Created `student_voice_submissions` table and `fn_student_portal_data_by_qr(p_qr_token)` RPC querying `public.qr_tokens`. Allows students to track attendance %, merit points, and submit **Suara Murid** feedback or anti-bullying reports with optional **Anonymous (Sulit/Rahsia)** protection.
- **Peti Suara Murid (Teacher Inbox)**: Integrated student voice submission inbox into `DisciplineCounselingScreen` where UBK, Discipline, and Admin staff can respond to student voices and post official action notes.
- **SMK Sungai Damit & D2C Project Public Web Landing Page**: Created `SchoolLandingScreen` at root `/#/` and `/#/landing` with a high-tech, futuristic aesthetic (deep navy & cosmic violet gradient, glassmorphic floating header bar, pulsing system status dot, neon cyan-gold typography, 3 Aras Intervensi grid, 4-step daily merit routine, whole-school T1–T5 scope, official school leadership list, and subtle portal launchpad buttons).

## 2026-08-17 — School Announcements (Discipline & Counseling UBK) & Student Portal Pengumuman Tab
- **Database Migration (`20260817000001_school_announcements.sql`)**: Created `school_announcements` table and updated `fn_student_portal_data_by_qr` RPC to automatically include live published announcements in student portal payloads.
- **Relocated Special Announcement Composer**: Removed ad-hoc announcement composer card from `ReportsScreen`.
- **Dual Announcement Composers in Disiplin & Kaunseling (`/#/discipline-counseling`)**: Added **Pengumuman Disiplin** composer in Tab 1 (*Kes Disiplin SSDOP*) and **Pengumuman Kaunseling (UBK)** composer in Tab 2 (*Sesi Kaunseling UBK*). Teachers can compose announcements, optionally attach a student, publish directly to the student portal database, and copy text for WhatsApp/PIBG.
- **Portal Murid Tab 1 (📢 Pengumuman)**: Added **📢 Pengumuman** as the **1st Tab** (before *Kemajuan Saya*) in `StudentPortalScreen` (`/#/student`) displaying live Discipline and Counseling announcements.
