# KNOWN_ISSUES.md — Dare to Change (D2C)

> Real bugs, accepted trade-offs, technical debt, and workarounds — kept separate so an agent doesn't waste time "fixing" a deliberate decision, or ships a fix that duplicates an already-known root cause. Each entry says which category it is.

## Bugs (genuinely broken, not yet fixed)

*(None currently tracked as open at time of writing. Other specific bugs found during development — the iPad Safari drag-handle failure, the heatmap `StateError` crash, the chart x-axis label repeat, the y-axis interval overlap, the field-rename breakage after `AttendancePeriodSummary` rework, the Parent IC Lookup silent-render bug, the `student_voice_submissions` anon-read exposure (formerly KI-014, fixed and verified live in production 2026-09-14 via `supabase/migrations/20260914000001_restrict_student_voice_read.sql`), and the Sudut Info scheduling timezone bug (formerly KI-018, fixed 2026-09-14 — see below) — were fixed in the same session they were found or shortly after; see `CHANGELOG.md` for the fix history.)*

## Fixed (kept for history — see `CHANGELOG.md` for the exact commit)

### KI-019 (fixed 2026-09-15): 540 of the 609 whole-school QR tokens were mis-linked by a reversed QR-decode order — twice
- **What was broken**: the whole-school QR rollout (see `DATABASE.md`'s `qr_tokens` entry, `TASKS.md` T-052) went through two bad datasets before landing on a correct one.
  1. The original 252-token dataset (9 D2C classes) had 224 tokens linked to the wrong student — an old import matched two spreadsheets by row position, not identity.
  2. The "fix" for that (`results_named.csv`, a class-sheet QR-recovery scan output) was **itself wrong on 540 of 609 rows** — the tool that built it decoded each page's QR codes with pyzbar, which returns detections in an internal algorithm order, not top-to-bottom reading order, then zipped that raw order directly against the alphabetically-sorted name list. This reversed the QR-to-name pairing on every page.
- **How it was caught**: Raizal physically scanned a real card (ADDY AERAYYAN ARASSH BIN ANNUAR's) and got a different student back (JANE SHERLYN JOHNSON). This is the only reason #2 above was caught in the same session — a same-database re-query would never have revealed it, since the wrong mapping was internally self-consistent (unique tokens, no orphans, no collisions).
- **The actual fix**: decode the source PNGs (`D:\Summit\System\qr_recovery\NewQR\qr_output\*.png`) directly (`pyzbar` + `PIL`), cluster each page's detections into rows by y-coordinate proximity, sort left-to-right within each row, concatenate pages in order, and pair that true reading order against the existing (already-correct) alphabetical name list. `scripts/fix_qr_reading_order_2026-09-15.py` / `supabase/seed/fix_qr_reading_order_2026-09-15.sql`.
- **The methodological lesson, not just the bug**: a claim of "verified" for an identity-matching migration must mean checked against an **independent, external** source — a real physical card, a human confirming a name, something outside the database being written to. Re-querying the same database you just wrote to (even via the "real" production RPC, as was done here the first time) only proves internal consistency: the data can be perfectly self-consistent (unique tokens, correct joins, no orphans) and still be systematically wrong, if the *input* to the migration was wrong in a way that doesn't produce contradictions. Watch for this specific failure mode whenever a script pairs two independently-produced lists (image-decoded values, OCR output, two separate exports) by *position/order* rather than by a shared identity key — reading order is not guaranteed by any of: file iteration order, image-detection library output order, or "the order two humans happened to list things in." If a future migration pairs data by position again, either verify the position assumption directly (as done here, by inspecting raw pixel coordinates) or get an independent, real-world spot check before considering it done.
- **If this class of bug resurfaces**: check whether the new data was produced by decoding/detecting multiple items from one image or document and assuming a reading order — that assumption is exactly what failed twice in this incident.

### KI-018 (fixed 2026-09-14): Sudut Info `valid_from`/`valid_until` scheduling was corrupted by a timezone mismatch
- **What was broken**: the composer's date/time picker (`discipline_counseling_screen.dart`, `_validFrom`/`_validUntil`) produces a **local** `DateTime` (Malaysia, UTC+8), and `createSudutInfoPost`/`updateSudutInfoPost` (`discipline_counseling_repository_impl.dart`) called `.toIso8601String()` on it directly — with no `.toUtc()` first. That serializes the local wall-clock digits with no `Z`/offset suffix, and Postgres's `timestamptz` column interprets a bare digit-string as UTC, silently storing the instant **~8 hours later** than intended. `getSudutInfoPosts`'s `onlyActive` query built its own `nowStr` the same broken way, which only "cancels out" the bias when the composer and the viewer share the exact same device timezone at the exact same moment — not a safe assumption, and empirically it didn't hold: both currently-published test posts were confirmed via direct SQL (`valid_from` vs. Postgres's true `now()`) to be scheduled hours into the future, so neither showed on the Student/Parent Portal login screens shipped the same day.
- **Fix**: `.toUtc().toIso8601String()` in all three places — `createSudutInfoPost`'s `valid_from`/`valid_until`, `updateSudutInfoPost`'s `valid_from`/`valid_until`, and `getSudutInfoPosts`'s `nowStr`. The read-side entity getters (`SudutInfoPost.isCurrentlyActive`/`isScheduled`/`statusLabel`/etc.) were already correct — they parse the DB's own explicit-offset ISO string via `DateTime.parse(...).toLocal()`, which round-trips correctly regardless of viewer timezone; only the write/query-boundary serialization was broken.
- **Data correction**: the two already-published rows (`84a36462…` "Kehadiran Ke Sekolah", `fc501082…` "Berani Berubah") had their `valid_from` corrected by `- interval '8 hours'` via direct SQL, moving them back to their true originally-intended instant (both then fell before Postgres's real `now()`, confirming they were meant to publish immediately, not hours later). Verified live: both now render correctly on the Parent/Student login screens with no further data patching needed.
- **Not touched**: `updated_at` writes elsewhere in the same repository file (`discipline_records`/`counseling_records`/`school_announcements`) use the identical `DateTime.now().toIso8601String()` (no `.toUtc()`) pattern, but are audit-trail-only fields never compared against "now" in a filter — lower-impact, out of scope for this fix, not separately tracked.

## Accepted Trade-offs (not bugs — do not "fix" without a product conversation)

### KI-001: Parent Portal has no rate limiting, link expiry, or access audit log
- **What**: `fn_parent_portal_data` is callable by anyone with a valid `access_token` (a UUID), as many times as they like, forever (until the guardian's link is regenerated by staff).
- **Why accepted**: no SMS/email-verified login was feasible without new infrastructure/budget; the token is 122 bits of entropy (unguessable by brute force), and the data behind it is limited to one student's attendance/merit/enrollment status — a bounded, considered exposure, not an oversight.
- **If asked to harden**: see `TASKS.md` T-030 and `DATABASE.md` Future Migration Notes for a proposed schema. Do not add rate limiting without first confirming whether Supabase's own project-level rate limits are considered sufficient — this may already be "good enough" for the school's risk tolerance.

### KI-002: Two different denominator conventions for "attendance rate" coexist by design
- **What**: `fn_attendance_period_summary` (Dashboard, Class Summary) uses a **fixed full-period** denominator; `fn_student_period_summary` (At-Risk Students, Merit Class Summary's merit %) uses an **elapsed/actual-recorded-days** denominator. The same student's "week attendance rate" can differ meaningfully between these two screens.
- **Why accepted**: each convention is correct for its own purpose (progress-tracking vs. current-standing) — see `PROJECT.md` §7 #3. This was reasoned through explicitly, not an inconsistency to unify.
- **Risk**: a future agent (or a confused staff member) might report this as a bug. It isn't. Read the migration header comments in `20260806000001_attendance_period_summary.sql` before touching either function.

### KI-003: `fn_recent_activity` does not filter by enrollment status
- **What**: A student's last scan/manual-entry/award still appears in the Dashboard's Recent Activity feed even after they've been marked expelled/suspended/etc.
- **Why accepted**: this is an audit-log-style feed, not a roster — hiding a just-expelled student's last actions would hide exactly the context an admin might want ("what did they do right before this").

### KI-004: `enrollment_status` write is admin-only; guardian contacts are staff-writable
- **What**: Changing a student's enrollment status requires `is_admin()`; adding/editing/removing a guardian contact only requires `is_staff()`.
- **Why accepted**: deliberate distinction — enrollment status is a disciplinary/administrative decision, guardian contact info is routine upkeep any teacher should be able to correct (e.g. an updated phone number).

## Technical Debt

### KI-005: `dateOnly(DateTime)` is duplicated across ~8 files
- **Where**: private top-level function in `dashboard_screen.dart`, and repeated (slightly differently named/shaped in a couple of cases) inside most `*_repository_impl.dart` files that need to strip time-of-day before sending a date to Postgres.
- **Impact**: low (each copy is one line, behavior is identical everywhere), but it's a real duplication. See `TASKS.md` T-028.
- **Do not** fix this opportunistically mid-unrelated-feature-work — it touches many files for a cosmetic win; do it as its own small, reviewable change.

### KI-006: `isar` / `isar_flutter_libs` / `path_provider` are unused dependencies
- **Where**: `pubspec.yaml`. Confirmed via `grep -rl "isar" app/lib` returning nothing.
- **Impact**: dead weight in the dependency tree, slightly larger build, no functional impact. Implies an offline-cache plan that was scoped early and never built.
- **Do not** silently remove these without flagging it (someone may have future offline-mode plans) — but also don't build on top of them assuming they're wired up; they are not initialized anywhere (`main.dart` has no Isar setup). See `TASKS.md` T-033.

### KI-007: No shared loading/error/empty-state widget
- **Where**: every `AsyncValue.when(...)` call site writes its own `CircularProgressIndicator()` / `Text('Failed to load: $error')` inline.
- **Impact**: low visual inconsistency risk (they're all similar by convention, see `CODING_STANDARDS.md`), but genuinely no abstraction exists if asked to "make loading states consistent" — that request implies new work, not a bug fix.

### KI-008: No RLS-partial-unique-index enforcing "one primary guardian per student"
- **Where**: `student_guardians.is_primary` is a plain boolean, unlike `qr_tokens.status='active'`'s partial-unique-index pattern.
- **Impact**: currently possible (not prevented) to mark two guardians "primary" for the same student. No UI bug results (the app just shows both with a "Primary" chip), but it's an unenforced invariant. See `TASKS.md` T-031.

### KI-009: No automated test coverage beyond one smoke test
- **Where**: `app/test/widget_test.dart` only, checks `MissingConfigApp` renders.
- **Impact**: real — every feature ships on `flutter analyze` + manual live-browser verification alone. A regression in an untouched screen from an unrelated change would not be caught automatically. See `CODING_STANDARDS.md` §Testing Expectations and `TASKS.md` T-032.

### KI-017: Sudut Info image upload/delete bypasses the repository layer
- **Where**: `discipline_counseling_screen.dart` calls `Supabase.instance.client.storage.from('sudut-info-banners')` directly (upload + remove) rather than going through `DisciplineCounselingRepository`, which has no storage-related methods at all. Every other Supabase interaction in the app goes through a repository — this is the one exception.
- **Impact**: low today (it works), but if `DisciplineCounselingRepositoryImpl` is ever swapped/mocked for testing, storage calls won't be captured by that seam. Worth folding into the repository if this feature gets touched again.

### KI-010: Theme mode selection is not persisted
- **Where**: `themeModeProvider` (`StateProvider<ThemeMode>`, default `system`) has no `shared_preferences`/localStorage backing.
- **Impact**: a user who explicitly picks Dark mode has it reset to `system` (following OS/browser preference) on every page reload. Minor UX papercut, not a data-integrity issue. See `TASKS.md` T-029.

## Performance Notes

- **No pagination anywhere.** `getStudents()` fetches the full active roster (~600 rows) in one call; every dashboard/report function scans the full relevant table range server-side. At current data volume (~614 students, a few months of daily attendance) this is fine; if the school's data grows by an order of magnitude (multi-year history, larger enrollment), several of these queries (`fn_attendance_streaks`'s student × school-day cross join especially) would need revisiting before they become slow.
- **`fn_attendance_streaks`** does a `cross join` between every student and every distinct recorded school day — this is the single most expensive query in the schema shape-wise. Fine today; worth profiling if attendance history grows substantially.
- **No caching layer anywhere** — every screen navigation refetches from Supabase. Given `.autoDispose` on most providers, revisiting a screen always re-queries. This is consistent with "no offline/local-cache plan" (see KI-006) and hasn't been a reported problem.

## Temporary Workarounds (currently in place, not necessarily permanent)

### KI-011: Dashboard reorder ships both drag-and-drop AND up/down buttons
- **Not itself a workaround for a bug** — it's the *permanent* fix for KI-noted-elsewhere (iPad Safari drag-handle failure), documented here so it's clear **both interaction methods must be kept**; removing the buttons because "drag works now" would reintroduce the original bug for iPad users. See `PROJECT.md` §7 #6, `COMPONENTS.md`.

### KI-012: Client-side enrollment-status guard in `qr_scan_screen.dart` duplicates server-side enforcement conceptually, but is NOT enforced at the same layer as `fn_manual_attendance_set`
- **What**: `recordScan()` (the `attendance_logs` insert behind a QR scan) has **no server-side enrollment-status check** — only the Dart client checks `student.enrollmentStatus == EnrollmentStatus.active` before calling it. Contrast with manual entry, where `fn_manual_attendance_set` enforces this server-side and cannot be bypassed.
- **Risk**: a modified/malicious client (or a future code path that calls `recordScan` without going through `qr_scan_screen.dart`'s guard) could record a scan for an inactive student.
- **If asked to harden**: this would need either a new trigger-level check on `attendance_logs` insert, or moving the check into `handle_attendance_scan()` (reject/no-op the derived `attendance_days` write when the student isn't active) — the latter is probably cleaner since it keeps `attendance_logs` a pure append-only log while stopping the *derived* effect.

### KI-015: Discipline & Counseling, Announcements, and Sudut Info RLS is staff-wide, not role-gated to `disiplin`/`kaunselor`
- **What**: `discipline_records`, `counseling_records`, `school_announcements`, and `sudut_info_posts` all use `for all ... to authenticated using (true) with check (true)` write policies. `DISCIPLINE_AND_COUNSELING.md` describes a specific RBAC model (`disiplin`, `kaunselor`, `admin` roles with distinct permissions), but nothing in the database — or, as far as verified, the route/screen layer — actually enforces it. Any signed-in staff member (any `profiles.role`) can read/write any discipline case, private counseling outcome note, announcement, or Sudut Info post.
- **Why accepted for now, not flagged as urgent like KI-014**: this matches the existing "any staff" pattern already used for `student_guardians` and `attendance_day_exceptions` — it's permissive-by-default, not exposed to the public internet (`anon` has no write access to any of these four tables). The gap is between the *documented* RBAC story and the *enforced* one, not a public-facing leak.
- **If asked to harden**: would need `profiles.role` widened beyond `admin`/`teacher`/`staff` to include `disiplin`/`kaunselor` (or a separate roles table), plus RLS policies keyed on it — this is a real schema change, not a one-line fix. Counseling `outcome_notes` in particular (private clinical-style notes) is the column most worth restricting first if this is ever prioritized.

### KI-016: The "D2C AI Assistant" is 100% local rule-based in production — its Gemini integration has never been wired up
- **What**: `D2CAiAssistantService.askAi()` (`core/services/d2c_ai_assistant_service.dart`) calls Google's Gemini API only `if (apiKey != null && apiKey!.isNotEmpty)`. `D2CAiAssistantDialog` instantiates the service as `D2CAiAssistantService()` — **no `apiKey` argument, ever** — and `.github/workflows/deploy-web.yml` passes no `GEMINI_API_KEY`/similar `--dart-define`. Every response the assistant gives, in production, comes from `_generateSmartLocalResponse()`, a keyword-matching lookup table over ~10 known topics.
- **Why this matters**: the dialog's own header UI reads "GEMINI INTELLIGENCE • ONLINE," which overstates what's actually happening — it's not calling any LLM, and cannot answer anything outside its hardcoded keyword branches (falls back to a generic "here's an overview" response otherwise). Not a security issue, but a documentation/expectations issue: don't assume "the AI assistant" can handle novel questions the way a real LLM integration would.
- **If asked to wire up real Gemini**: needs an actual API key threaded through as a `--dart-define` secret (same pattern as `SUPABASE_ANON_KEY`) and passed to `D2CAiAssistantDialog`'s `D2CAiAssistantService(apiKey: ...)` constructor call — currently that plumbing simply doesn't exist end-to-end.

### KI-013 (FIXED 2026-09-14): Supabase Auth Site URL / Redirect URLs allowlist was stuck on the old github.io domain
- **What it was**: Hosting moved from `https://cgfusion.github.io/summit/` to `https://d2csummit.online/` back in August, but the hosted Supabase project's Auth → URL Configuration (`site_url`, `uri_allow_list`) was never updated to match — confirmed via `GET /v1/projects/uslcbhozuyyfnencttol/config/auth` on the Management API, which showed both still set to the dead `github.io` URL as of 2026-09-14.
- **Impact while broken**: invite-staff and set-password (password reset) email links were generated against the wrong URL — either 400ing or bouncing to the dead domain, for as long as this went unnoticed (from the domain migration on ~2026-08-12 through the fix date).
- **Fix applied**: `PATCH /v1/projects/uslcbhozuyyfnencttol/config/auth` with `site_url: https://d2csummit.online` and `uri_allow_list: https://d2csummit.online,https://d2csummit.online/**`. Verified via the same GET afterward — both fields now correctly reflect the custom domain. This was a live production config change, not a code/migration change — nothing to find in `supabase/migrations/` for this one.
