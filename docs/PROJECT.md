# PROJECT.md — Dare to Change (D2C)

> Read this file first. It orients you to what this project is and why it exists. For "what do I do right now," go to `NEXT_SESSION.md` instead.

## 1. Project Vision

**Dare to Change (D2C)** is a purpose-built attendance, discipline, and merit-recognition system for **SMK Sungai Damit**, a Malaysian secondary school (Sekolah Menengah Kebangsaan). It replaces paper attendance registers and ad hoc discipline tracking with a QR-card-based scan system, a rule-derived daily merit score, and a set of reporting/leaderboard tools for teachers, admins, and (as of the latest feature) parents.

The system exists to serve a specific school's **"Dare to Change" behavioural program** (1 Aug – 31 Oct 2026, per `KK D2C.docx`, the program's founding document — not in this repo, but referenced throughout code comments and migration headers). The program's core idea: attendance and basic discipline (on time, returns from recess, stays till end of session) earn daily points; those points roll up into class and individual leaderboards and recognition awards.

This is **not** a generic multi-tenant SaaS product — it is single-school software, hardcoded to one school's org structure (Tingkatan 1–5, two sessions `pagi`/`petang`, specific class names like "1 CITRA"). Do not add multi-tenancy abstractions unless explicitly asked.

## 2. Product Purpose

For a school administrator or teacher, D2C answers:
- *Who is at school right now, and were they on time?* (QR scan → attendance status)
- *Who hasn't been marked today?* (Dashboard compliance banner)
- *How is this class/student doing over a week/month/year?* (Period summaries, KPI trends)
- *Who deserves recognition, and who needs intervention?* (Leaderboards, At-Risk Students, Chronic Latecomers)
- *What do I do about a student who's been expelled/suspended/transferred?* (Enrollment status)
- *How do I reach a student's parent, and can they see their child's status without me doing the work?* (Guardian contacts + Parent Portal)

## 3. Core Modules

| Module | Feature folder | Responsibility |
|---|---|---|
| **Attendance** | `features/attendance` | QR scan intake, manual keyin/backfill (exception-based bulk: default Hadir), daily status derivation, QR card registration — see `ATTENDANCE.md` for current model vs MOEIS / future export / assembly QR |
| **Student** | `features/student` | Student roster, enrollment status (active/expelled/etc.), parent/guardian contacts |
| **Class Management** | `features/class_management` | Class roster (read-only from the app's perspective — classes are seeded from the school's SIS export) |
| **Merit** | `features/merit` | Daily merit scoring (derived from attendance + exceptions + bonus), class/student period summaries, rewards/recognition log |
| **Dashboard** | `features/dashboard` | Analytics home screen: stat cards, charts, leaderboards, heatmap, KPI gauges, user-customizable layout |
| **Reports** | `features/reports` | KPI trend dashboard (attendance rate, repeat absence, at-risk students, chronic latecomers, leave-type breakdown) per the program's own KPI section |
| **Settings** | `features/settings` | Program period, merit component toggles, session cutoff times, staff account management |
| **Parent Portal** | `features/parent_portal` | Unauthenticated, token-gated read-only view of one student's status, for parents/guardians |
| **Auth** | `features/auth` | Staff sign-in (Supabase Auth, email/password) |

## 4. Technology Stack

- **Client**: Flutter Web (Dart SDK `^3.12.2`), deployed as a static SPA.
- **State management**: Riverpod 2 (`flutter_riverpod: ^2.6.1`) — hand-written providers, no code generation.
- **Routing**: `go_router: ^15.1.2`, hash-based URL strategy (works on GitHub Pages without server-side rewrites).
- **Backend**: Supabase (Postgres + PostgREST + Auth + RLS). No custom backend server — all business logic lives in Postgres functions (`fn_*`) or client-side Dart.
- **Charts**: `fl_chart: ^1.2.0`.
- **QR scanning**: `mobile_scanner: ^7.4.0`.
- **Hosting**: GitHub Pages, auto-deployed via GitHub Actions on push to `main`, served at the custom domain `https://d2csummit.online/` (CNAME set via the `deploy-web.yml` workflow's `peaceiris/actions-gh-pages` step; app built with `--base-href /`).
- **Local dev DB tooling**: Supabase CLI (`supabase db push`, `supabase db query --linked`) — **no local Postgres/Docker is used**; every migration is pushed and verified directly against the **production** database (see `AI_RULES.md` — there is no staging environment).
- **Dead dependency**: `isar` + `isar_flutter_libs` + `path_provider` are in `pubspec.yaml` but **unused** anywhere in `app/lib`. Leftover from an early offline-cache plan that was never implemented. See `KNOWN_ISSUES.md`.

## 5. Folder Structure

```
summit/                            <- git repo root
├── app/                           <- Flutter application
│   ├── lib/
│   │   ├── main.dart              <- entry point, Supabase.initialize, MissingConfigApp fallback
│   │   ├── app.dart                <- MaterialApp.router, theme wiring
│   │   ├── core/
│   │   │   ├── config/env.dart     <- --dart-define reader (SUPABASE_URL/SUPABASE_ANON_KEY)
│   │   │   ├── providers/supabase_provider.dart
│   │   │   ├── router/             <- app_router.dart + hash-change listenable (web history sync)
│   │   │   ├── theme/app_theme.dart
│   │   │   └── layout/app_shell.dart <- responsive sidebar/mobile shell, HomeBackButton
│   │   └── features/
│   │       └── <feature>/
│   │           ├── domain/
│   │           │   ├── entities/
│   │           │   ├── repositories/       <- abstract interfaces
│   │           │   └── value_objects/      <- (merit only: DateRange)
│   │           ├── data/
│   │           │   └── repositories/       <- Supabase-backed implementations
│   │           └── presentation/
│   │               ├── providers/          <- Riverpod providers
│   │               └── screens/
│   ├── test/                       <- one smoke test (widget_test.dart)
│   └── pubspec.yaml
├── supabase/
│   ├── migrations/                 <- chronological *.sql files, source of truth for the schema
│   └── seed/                       <- seed_data.sql (initial import), guardians_seed.sql, review CSVs
├── scripts/
│   ├── generate_seed_sql.py        <- reads XEA4402 + QR export xlsx, writes supabase/seed/seed_data.sql
│   └── generate_guardian_seed_sql.py <- reads XEA4402, writes supabase/seed/guardians_seed.sql
├── docs/                           <- THIS AI Development Kit (you are here)
└── .github/workflows/              <- "Deploy Web to GitHub Pages" CI
```

Every feature follows the **same three-layer shape** (`domain` / `data` / `presentation`). There is no `core` business logic layer beyond routing/theme/shell — feature repositories talk to Supabase directly.

## 6. Current Architecture

Clean Architecture, feature-first, deliberately lightweight (no use-case/interactor layer — repositories are called directly from Riverpod providers). See `ARCHITECTURE.md` for full diagrams and data flow.

- **Domain**: pure Dart entities + abstract repository interfaces. No Flutter or Supabase imports.
- **Data**: one `<Feature>RepositoryImpl` per feature, wrapping `SupabaseClient`. Talks to Postgres either via `.from(table).select/insert/update/delete()` (simple CRUD, RLS-gated) or `.rpc(function_name, params)` (anything with real logic — cutoff-time computation, cross-table aggregation, security-definer privilege escalation).
- **Presentation**: Riverpod `Provider`/`FutureProvider`/`StateProvider`/`StateNotifierProvider` per screen's needs, consumed by `ConsumerWidget`/`ConsumerStatefulWidget` screens.
- **Business logic lives in Postgres, not Dart**, wherever it involves aggregation, cross-table joins, or anything security-sensitive (role checks, token validation). The Flutter layer is intentionally "dumb" — it renders what the RPC/query returns and re-fetches after writes.

## 7. Major Design Decisions

1. **Attendance is a two-table pipeline, not a single write.** `attendance_logs` is an append-only raw scan log; a DB trigger (`handle_attendance_scan`) derives/upserts the canonical `attendance_days` row (one per student per school day), computing `hadir`/`lewat` against `session_cutoff_times`. The app never writes `attendance_days` directly for scans — only for manual entry (via `fn_manual_attendance_set`, admin/staff-gated) or the (currently unimplemented) absence cron. **Manual/bulk capture is exception-based** (roster defaults to Hadir; staff only mark Absents / Cuti Sakit / Urusan Rasmi / etc.). D2C does not currently pull attendance from MOEIS or the older school attendance system — see `ATTENDANCE.md`.
2. **Merit points are 100% derived, not stored as a ledger.** `merit_student_daily` is a `security_invoker` **view** over `attendance_days` + `attendance_day_exceptions` + `merit_bonus_points`, computed live. There is no `merit_ledger` table — "recalculating" merit is just re-querying the view. Each of the 4 components (hadir, tepat masa, kembali rehat, kekal sesi) plus bonus is individually toggleable via `attendance_settings`, and a disabled component always reads 0 regardless of underlying data.
3. **"Full period" denominators for period-summary reports are deliberately fixed, not elapsed-so-far.** `fn_attendance_period_summary`'s week/month/year rates use the period's *total* school-day count as the denominator throughout the period (so a rate reads as "progress toward 100%", not "rate among days recorded"). This is a specific, explicit teacher request — see the migration header comment in `20260806000001_attendance_period_summary.sql`. **Do not silently "fix" this to use elapsed days** — it would be wrong for its actual purpose. Contrast this with `fn_student_period_summary` (used by At-Risk Students, Class Merit Summary), which deliberately uses **elapsed/actual-recorded-days** as the denominator — the correct convention for "how has this student performed so far." Keep these two conventions distinct; do not unify them.
4. **Non-active students vanish from every current-facing query, not just the roster list.** `enrollment_status` (active/suspended/expelled/transferred_out/withdrawn/deceased/graduated) filters out of `getStudents()` (default `activeOnly: true`), and out of 6 SQL aggregation functions (`fn_class_attendance_summary`, `fn_attendance_streaks`, `fn_attendance_period_summary`, `fn_chronic_latecomers`, `fn_student_period_summary`, `fn_class_period_summary`) — but **not** `fn_recent_activity` (an audit-log feed, deliberately still shows a just-expelled student's last actions) and **not** historical `attendance_days` reads (viewing a past date's roster). Historical data is never deleted or hidden; only *current-roster* queries filter.
5. **The Dashboard's card layout is user-customizable and persisted server-side**, not local-only. `profiles.dashboard_layout jsonb` stores an ordered list of card IDs per user, written via a security-definer RPC (`fn_update_dashboard_layout`) because direct `profiles` writes are otherwise admin-only.
6. **Reordering UI uses both drag-and-drop AND up/down buttons, not drag alone.** `ReorderableListView`'s drag handle only reliably renders/works on platforms Flutter detects as desktop; on iPad Safari it silently degrades to whole-tile long-press dragging, which loses the gesture race against the sheet's own scrollable and shows no handle at all. Up/down buttons are the **guaranteed-everywhere** fallback and must not be removed even if drag "seems to work" in testing.
7. **The Parent Portal is unauthenticated by design, gated only by an unguessable per-guardian token**, not a real login. The guardian data imported from the school's SIS export has phone/IC numbers but no verified emails, and there is no SMS provider budget — so a magic-link pattern (`profiles`-free, `access_token uuid` on `student_guardians`) was chosen deliberately over building real parent accounts. This is a known, accepted security trade-off (see `AI_RULES.md` and `KNOWN_ISSUES.md`) — anyone with the link can view that one student's data; there is no rate-limiting or expiry.
8. **Every RPC that's reachable without a staff session is server-side scoped to exactly one entity**, never returns a list, and is granted to `anon` explicitly and individually — the default posture for new tables/functions is "staff-only via RLS", and public/anon access is an opt-in exception, not a default.

## 8. Coding Philosophy

- **Business logic in SQL when it involves aggregation or cross-table joins.** Dart repositories are thin wrappers around `.rpc()`/`.from()` calls — no client-side aggregation of data that a SQL function could compute.
- **No premature abstraction.** No generic "BaseRepository", no use-case layer, no dependency-injection framework beyond Riverpod's own `Provider`. Each feature's repository interface is written for exactly what that feature needs today.
- **Every migration is verified against live production data before being considered done.** `supabase db push` then `supabase db query --linked "<test query>"` (often with `set local role authenticated; set local request.jwt.claim.sub = '<real-uuid>';` to simulate a specific user's RLS context, or `set local role anon;` for public-RPC testing) — never mocked data. See `AI_RULES.md` for the exact discipline.
- **Every feature ships through the full loop**: migration → live-verify → Flutter code → `flutter analyze` (must be clean) → `flutter test` → commit → push → poll GitHub Actions → live-verify in a real browser (Claude in Chrome / equivalent), including a hard cache-bust reload (GH Pages + Flutter's own caching layers are notoriously sticky — see `KNOWN_ISSUES.md`).
- **Comments explain WHY, never WHAT.** Every non-obvious migration and function carries a header comment explaining the *reasoning* (a specific teacher request, a subtle denominator convention, a security trade-off) — read these before changing behavior; they are load-bearing context, not decoration.
- **Bilingual UI where the school's own vocabulary is Malay.** Attendance statuses (`Hadir`/`Lewat`/`Tidak Hadir`/`Cuti Sakit`/`Urusan Rasmi`) and enrollment statuses (`"Active / Aktif"`, `"Expelled / Dibuang Sekolah"`, etc.) are shown in both languages; general UI chrome is English.

## 9. Important Constraints

- **Single school, hardcoded structure.** Tingkatan 1–5, sessions `pagi`/`petang`, class names come verbatim from the SIS export. Do not generalize into a multi-school schema without being asked.
- **No local Postgres.** Docker isn't available in this dev environment (Windows without elevated privileges) — `supabase db push --local` will fail silently on the migrations-catalog cache step (a harmless warning) but succeeds against `--linked` (production). There is no staging/dev database — every migration lands directly on production. Be conservative; verify with read queries before/after any destructive change.
- **No CI test suite beyond one smoke test.** `flutter test` runs `app/test/widget_test.dart` only (checks the missing-config screen renders). There is no integration/widget test coverage for actual features — manual live-browser verification is the only correctness check beyond `flutter analyze`.
- **GitHub Pages caching is aggressive and multi-layered.** `main.dart.js` is served with `Cache-Control: max-age=600`, and CDN edge nodes can independently lag by up to that TTL — a hard-reloaded browser can still show stale JS for several minutes after a successful deploy even with correct cache-clearing. Don't conclude "the code is wrong" from a stale-looking live check without cross-verifying via `curl` against the deployed bundle first.
- **`ReorderableListView` drag handles are unreliable on iPad Safari** inside nested scrollables — always pair drag with an explicit alternative interaction (see Dashboard rearrange).
- **The Parent Portal has no rate limiting, no link expiry, and no audit log of who viewed a link.** This is accepted, not a bug — see design decision #7 above and `KNOWN_ISSUES.md`.

## 10. Reusable Components

See `COMPONENTS.md` for full documentation. Highlights:
- `HomeBackButton` (`core/layout/app_shell.dart`) — every non-Dashboard/non-Home screen's AppBar `leading`, guarantees a way back to `/home` in mobile (no-sidebar) mode.
- `_ChartCard` / `_DashboardGrid` / `_StatCard` (`dashboard_screen.dart`) — the Dashboard's card grid primitives, driven by the user's saved `DashboardLayout`.
- `PeriodPicker` (`merit/presentation/screens/period_picker.dart`) — shared date-range picker used by Reports and Merit Class Summary.
- `colorForEnrollmentStatus` (`student/presentation/screens/student_detail_sheet.dart`) — the canonical status→color mapping, reused by the Parent Portal screen.

## 11. Future Roadmap

Explicitly deferred, not built (do not assume these exist):
- **Real parent/student login** (phone OTP or email/password) — needs an SMS provider account or a parent-email data-collection step first. See design decision #7.
- **Mentor/PRS assignment + case-tracking module** — 2 of the program's 5 official KPIs (mentor coverage, follow-up timeliness) depend on this and are explicitly not faked; `reports_screen.dart`'s `_UnavailableKpiNote` documents this gap in the UI itself.
- **Absence cron** — `attendance_days.source = 'system_cron'` is modeled in the schema (and the scan trigger's `on conflict` clause specifically only overwrites `system_cron`-sourced rows) but no scheduled job populates it yet. A student who never scans and is never manually marked simply has no `attendance_days` row for that day (silently absent from all period summaries, not counted as `tidak_hadir`).
- **Offline/local caching** — `isar` is installed but unused; if ever pursued, decide deliberately rather than resuming the dead dependency blindly (re-audit whether it's still the right choice).
- **Multi-guardian relationship de-duplication** — the guardian import is keyed on `(student_id, full_name)`; a guardian who is Penjaga 1 for two siblings gets two separate `student_guardians` rows (by design — no cross-student guardian entity exists).
- **MOEIS / idMe attendance sync** — no authorized pull or push today. Possible later as `MOEIS → D2C` and/or `D2C → external` export; see `ATTENDANCE.md`.
- **Attendance Export API for partners** — informational draft only in `ATTENDANCE.md` §6; not implemented. Current API surface remains Supabase PostgREST/RPCs (`API.md`).
- **Assembly / entrance QR as main school attendance** (`sidang pagi` / `sidang petang` phone-camera windows) — QR scan tech already exists in D2C, but default-Absent-until-scanned session rules are **not** the current product mode. For now D2C stays exception-based (default Hadir). See `ATTENDANCE.md` §3 and §5.
