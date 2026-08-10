# API.md — Dare to Change (D2C)

> There is no custom REST/GraphQL backend. The "API" is Supabase PostgREST: direct table operations (`.from(table).select/insert/update/delete()`, RLS-gated) and RPC calls (`.rpc('fn_name', params: {...})`, for anything with real logic). This document covers every RPC function and every direct-table operation the Flutter app performs, organized by feature.

**Base URL**: `{SUPABASE_URL}/rest/v1/` (table ops) and `{SUPABASE_URL}/rest/v1/rpc/{fn_name}` (RPC), both via `supabase_flutter`'s `SupabaseClient` — no raw HTTP calls exist in the codebase.

**Authentication header conventions** (all handled internally by `supabase_flutter`, not written by hand anywhere in this codebase):
- `apikey`: the anon key, always sent.
- `Authorization: Bearer <jwt>`: the signed-in user's session JWT, when one exists. Absent → requests run as Postgres role `anon`; present → role `authenticated` with `auth.uid()` resolvable.

**Error codes**: Supabase/PostgREST does not use custom HTTP-level error codes here. Every failure surfaces to Dart as a `PostgrestException` with a `message` field — either a Postgres RLS-violation message (blocked write) or the literal text of a `raise exception 'message'` inside a `plpgsql` function. There is no error-code enum in this codebase; **the message string is the contract**. See each entry below for the exact text an AI agent should expect/match against.

---

## Authentication

### Sign in (staff)
- **Call**: `Supabase.instance.client.auth.signInWithPassword(email: ..., password: ...)`
- **File**: `features/auth/presentation/screens/sign_in_screen.dart`
- **Auth required**: none (this *is* the auth call)
- **Response**: `AuthResponse` with `.session` populated on success.
- **Errors**: `AuthException` — wrong credentials, unconfirmed email, etc. Surfaced inline on the sign-in form.
- **Downstream effect**: `GoRouterRefreshStream` (wraps `auth.onAuthStateChange`) triggers the router's `redirect` re-evaluation, bouncing `/sign-in` → `/`.

### Sign out
- **Call**: `Supabase.instance.client.auth.signOut()`
- **Called from**: `_AccountFooter` (`app_shell.dart`), `_AccountMenuButton` (`dashboard_screen.dart`).
- **Auth required**: an active session (no-op otherwise).

---

## Students (`features/student`)

### `getStudents({classId?, searchQuery?, activeOnly = true})`
- **Table op**: `SELECT` on `students`, embedding `classes(name)`.
- **Columns selected**: `id, student_id, full_name, ic_number, ic_type, date_of_birth, gender, study_status, enrolled_at, class_joined_at, class_id, classes(name), enrollment_status, enrollment_status_reason, enrollment_status_date`.
- **Filters applied**: `.eq('class_id', classId)` if given; `.eq('enrollment_status', 'active')` if `activeOnly` (**default true** — every existing caller gets active-only unless it explicitly opts out); `.or('full_name.ilike.%q%,ic_number.ilike.%q%')` if a search query is given; always `.order('full_name')`.
- **Auth required**: staff (RLS `students_select_staff`).
- **Errors**: `PostgrestException` if not staff (empty result, not an exception — RLS `SELECT` filters silently, it does not raise).
- **Example**:
  ```dart
  final students = await ref.read(studentRepositoryProvider)
      .getStudents(classId: someClassId, activeOnly: false); // include suspended/expelled/etc.
  ```

### `getByStudentId(int studentId)` / `getById(String id)`
- **Table op**: same select shape as above, `.eq('student_id', ...)` / `.eq('id', ...)`, `.maybeSingle()`.
- **Auth required**: staff.

### `updateEnrollmentStatus({studentId, status, reason?, effectiveDate})`
- **RPC**: `fn_update_student_status(p_student_id uuid, p_status text, p_reason text default null, p_date date default current_date)`
- **Response**: `void`.
- **Auth required**: `is_admin()` — **not** just staff. Non-admin call raises `'not authorized'`.
- **Errors**:
  - `'not authorized'` — caller is not an admin.
  - `'invalid status: %'` — `status.dbValue` not one of `active/suspended/expelled/transferred_out/withdrawn/deceased/graduated`.
- **Side effect**: also sets `enrollment_status_changed_by = auth.uid()`, `enrollment_status_changed_at = now()`.
- **Example**:
  ```dart
  await ref.read(studentRepositoryProvider).updateEnrollmentStatus(
    studentId: student.id,
    status: EnrollmentStatus.expelled,
    reason: 'Disciplinary case #123',
    effectiveDate: DateTime.now(),
  );
  ref.invalidate(studentsProvider); // caller's responsibility — no auto-invalidation
  ```

### `getGuardians(String studentId)`
- **Table op**: `SELECT *` on `student_guardians` where `student_id = ...`, ordered `is_primary desc, full_name`.
- **Auth required**: staff.
- **Response fields**: includes `access_token` — **this is sensitive** (it's the parent-portal link secret); the returned `StudentGuardian.accessToken` should only ever be used to build/copy a link, never logged or displayed raw in a list.

### `addGuardian({studentId, fullName, relationship?, icNumber?, phone?, email?, isPrimary=false, isEmergencyContact=false, notes?})`
- **Table op**: `INSERT` into `student_guardians`.
- **Auth required**: staff (`student_guardians_write_staff` — note this is `is_staff()`, not `is_admin()`).
- **Errors**: unique-constraint violation if `(studentId, fullName)` already exists for that student — surfaces as a `PostgrestException` with a Postgres constraint-violation message (not custom text).
- **Note**: `access_token` is **not** settable here — it defaults server-side to `gen_random_uuid()`.

### `updateGuardian({guardianId, fullName, relationship?, icNumber?, phone?, email?, isPrimary=false, isEmergencyContact=false, notes?})`
- **Table op**: `UPDATE student_guardians ... WHERE id = guardianId`.
- **Auth required**: staff.
- **Note**: does not touch `access_token`; use `regenerateGuardianToken` for that.

### `deleteGuardian(String guardianId)`
- **Table op**: `DELETE FROM student_guardians WHERE id = guardianId`.
- **Auth required**: staff.

### `regenerateGuardianToken(String guardianId)`
- **RPC**: `fn_regenerate_guardian_token(p_guardian_id uuid)`
- **Response**: `uuid` (the new token, as `String` in Dart).
- **Auth required**: staff (`is_staff()`). Raises `'not authorized'` otherwise.
- **Effect**: the guardian's **old** parent-portal link stops working immediately (token is overwritten, not appended).
- **Example**:
  ```dart
  final newToken = await ref.read(studentRepositoryProvider).regenerateGuardianToken(guardian.id);
  final link = '${Uri.base.origin}${Uri.base.path}#/parent/$newToken';
  await Clipboard.setData(ClipboardData(text: link));
  ```

---

## Attendance (`features/attendance`)

### `resolveQrToken(String token)`
- **Table op**: `SELECT status, students!inner(...)` on `qr_tokens` where `token = ...` and `status = 'active'`, `.maybeSingle()`.
- **Response**: `Student?` — `null` if the token doesn't exist or isn't active (**unrecognised card** flow, not an error).
- **Auth required**: staff.
- **Caller must additionally check** `student.enrollmentStatus == EnrollmentStatus.active` **client-side** before recording a scan (`qr_scan_screen.dart`) — resolving a token for an inactive student is allowed (so staff can see who the card belongs to), but recording attendance for them is rejected.

### `recordScan({studentId, deviceLabel?})`
- **Table op**: `INSERT` into `attendance_logs`. Triggers `handle_attendance_scan()` server-side — see `DATABASE.md` for the full pipeline.
- **Response**: `AttendanceLog` (the inserted row).
- **Auth required**: staff.
- **No client-side guard against inactive students at the DB level for this specific insert** — `attendance_logs` itself has no enrollment-status check; the check happens in `qr_scan_screen.dart` *before* calling this. If you add a new caller of `recordScan`, you must add the same guard yourself — it is not enforced server-side for this path (contrast with `fn_manual_attendance_set`, which *does* enforce it server-side).

### `getAttendanceForDate({date, classId?})`
- **Table op**: `SELECT ..., students!inner(full_name, class_id)` on `attendance_days` where `school_date = date`, optional `.eq('students.class_id', classId)`.
- **Auth required**: staff.
- **Note**: this is a **historical view** — it does not filter by current `enrollment_status`, since a past date's attendance for a since-expelled student is still real history.

### `getAttendanceForStudentOnDate({studentId, date})`
- Same shape as above, single-row, `.maybeSingle()`.

### `registerToken({studentId, token, printedClassSnapshot?})` / `reissueToken(...)`
- **Table ops**: checks for an existing active-token owner first (`_findActiveTokenOwner`), then either inserts (register) or revokes-then-inserts (reissue).
- **Response**: `RegisterQrResult` — a sealed set of `RegisterQrSuccess` / `RegisterQrTokenTaken(ownerName)` / `RegisterQrStudentHasToken`. **Not exceptions** — these are modeled as return values so the UI can branch without try/catch.
- **Auth required**: staff.

### `setManualAttendance({studentId, schoolDate, status, time?, note?})`
- **RPC**: `fn_manual_attendance_set(p_student_id, p_school_date, p_status, p_time default null, p_note default null)`
- **Response**: `void`.
- **Auth required**: staff (`is_staff()`).
- **Errors**:
  - `'not authorized'` — not staff.
  - `'invalid status: %'` — status not one of `hadir/lewat/tidak_hadir/cuti_sakit/urusan_rasmi`.
  - `'student not found'` — no `students` row for that id.
  - `'student is not active (enrollment_status: %)'` — **the real enforcement point** for "don't mark attendance for an expelled/inactive student." This is server-side and cannot be bypassed by the client.
- **Behavior detail**: if `p_time` is omitted for `hadir`/`lewat`, the function defaults to that student's class/weekday cutoff from `session_cutoff_times` (falls back to `'07:00:00'` if no match) — so a bare "mark as hadir" reads as on-time rather than an arbitrary clock value.
- **Example**:
  ```dart
  await ref.read(attendanceRepositoryProvider).setManualAttendance(
    studentId: student.id,
    schoolDate: DateTime.now(),
    status: AttendanceStatus.tidakHadir,
    note: 'Sick, informed by parent',
  );
  ```

---

## Merit (`features/merit`)

### `getProgramPeriod()`
- **Table op**: `SELECT program_start_date, program_end_date FROM attendance_settings WHERE id = 1`.
- **Auth required**: staff.

### `getDailyMerit({date, classId?})`
- **Table op**: `SELECT * FROM merit_student_daily WHERE school_date = date [AND class_id = classId]`.
- **Auth required**: staff (enforced by the underlying tables' RLS, via `security_invoker`).

### `setException({studentId, date, lateToClass, missedRecessReturn, leftEarly})`
- **Table op**: `UPSERT` into `attendance_day_exceptions` if any flag is `true`; **DELETE** the row if all three are `false` (no row = all points earned, the table's whole design principle — never leaves an all-false row lying around).
- **Auth required**: staff.

### `addBonus({studentId, date, points, reason?})`
- **Table op**: `INSERT` into `merit_bonus_points`.
- **Auth required**: staff for insert (RLS: `merit_bonus_points_staff_insert`); note `update`/`delete` on this table are admin-only, but this method only ever inserts.

### `getStudentSummary({from, to, classId?})`
- **RPC**: `fn_student_period_summary(p_from, p_to, p_class_id default null)`
- **Response**: list of `{student_id, full_name, class_id, total_points, max_points, pct, full_attendance, days_present, days_absent}`.
- **Auth required**: staff (view/table RLS via invoker).
- **Denominator convention**: `max_points = days_present + days_absent (elapsed, recorded days) × merit_max_points` — **elapsed-days**, not fixed-period. See `PROJECT.md` #3 for why this differs from `fn_attendance_period_summary`.
- **Excludes non-active students** (added `20260809000001`).

### `getClassSummary({from, to})`
- **RPC**: `fn_class_period_summary(p_from, p_to)`
- **Response**: list of `{class_id, class_name, total_points, max_points, pct, missed_recess_return_count, missed_recess_return_rate}`.
- **Excludes non-active students.**

### `logAward({category, scopeType, studentId?, classId?, periodStart, periodEnd, note?})`
- **Table op**: `INSERT` into `merit_awards`.
- **Response**: `bool` — `true` if inserted, **`false` (not an exception) if the unique dedupe index rejected it** (same category/scope/period already logged). The repository catches the specific unique-violation and returns `false` rather than propagating.
- **Auth required**: staff.
- **Validation**: `category` must be one of the 6 allowed values; `scopeType` must pair correctly with exactly one of `studentId`/`classId` non-null (DB check constraint — a mismatch raises a generic constraint-violation `PostgrestException`, not custom text).

### `getAwards({periodStart, periodEnd})` / `getTotalAwardsCount()`
- **Table ops**: straightforward `SELECT`/`count` on `merit_awards`.

---

## Class Management (`features/class_management`)

### `getClasses()` / `getById(String id)`
- **Table op**: plain `SELECT * FROM classes [WHERE id = ...]`.
- **Auth required**: staff. No write methods exist in this repository — classes are read-only from the app.

---

## Dashboard (`features/dashboard`)

All of the following are `stable` RPCs, staff-only (RLS via invoker), no side effects. See `DATABASE.md` for exact SQL and column shapes; this section covers the Dart-facing contract only.

| Method | RPC | Notes |
|---|---|---|
| `getAttendanceDaySummary(date)` | `fn_attendance_day_summary` | Called twice by `_TopStatsRow` (today, yesterday) for delta arrows |
| `getDailyAttendanceTrend({from, to})` | `fn_daily_attendance_trend` | |
| `getDailyMeritTrend({from, to})` | `fn_daily_merit_trend` | |
| `getClassAttendanceSummary({from, to})` | `fn_class_attendance_summary` | Called with `from == to == today` to find classes with zero recorded attendance (`recorded_count == 0`) — no separate function exists for this; it's a client-side filter on the same call |
| `getAttendanceStreaks({limit = 10})` | `fn_attendance_streaks` | |
| `getRecentActivity({limit = 15})` | `fn_recent_activity` | Does **not** exclude inactive students |
| `getKpiOverview({from, to})` | `fn_kpi_overview` | |
| `getAttendancePeriodSummary(referenceDate)` | `fn_attendance_period_summary` | Fixed-period denominator |
| `getChronicLatecomers({referenceDate, windowDays=7, minLate=3})` | `fn_chronic_latecomers` | |
| `getLeaveTypeBreakdown({from, to})` | `fn_leave_type_breakdown` | |
| `getDashboardLayout()` | `SELECT dashboard_layout FROM profiles WHERE id = auth.uid()` (direct table op, not RPC) | Returns `DashboardLayout.defaultLayout` if `null`/no session |
| `saveDashboardLayout(DashboardLayout)` | `fn_update_dashboard_layout(p_layout jsonb)` | Fire-and-forget from `DashboardLayoutController._apply` — local state updates optimistically before the RPC resolves |

**Example — dashboard layout round-trip**:
```dart
final layout = await ref.read(dashboardRepositoryProvider).getDashboardLayout();
// layout.statsOrder / layout.chartsOrder — lists of card ids, reconciled against
// DashboardLayout.default* so newly shipped cards still appear even for a user
// with a stale saved order.
await ref.read(dashboardRepositoryProvider).saveDashboardLayout(
  layout.copyWith(statsOrder: reordered),
);
```

---

## Reports (`features/reports`)

### `getWeeklyKpiTrend({from, to, session?})`
- **RPC**: `fn_weekly_kpi_trend(p_from, p_to, p_session default null)`
- **Response**: list of `{week_start, total_records, present_count, late_count, attendance_rate, missed_recess_count, repeat_absent_students}`.
- **`session`**: `'pagi'`/`'petang'`/`null` (whole school). Note this is a *class* session filter, unrelated to auth sessions.

---

## Settings (`features/settings`)

| Method | Operation | Auth | Notes |
|---|---|---|---|
| `getSchoolSettings()` | `SELECT` on `attendance_settings WHERE id=1` | staff | |
| `updateProgramPeriod({start, end})` | `UPDATE attendance_settings` | admin (RLS) | |
| `updateMeritSettings({...6 params})` | `UPDATE attendance_settings` | admin (RLS) | Toggles the 5 merit-component booleans + max points |
| `getCutoffTimes()` | `SELECT * FROM session_cutoff_times ORDER BY session, day_of_week` | staff | |
| `updateCutoffTime({session, dayOfWeek, cutoffTime})` | `UPDATE session_cutoff_times WHERE session=... AND day_of_week=...` | admin (RLS) | |
| `getStaff()` | `SELECT id, full_name, role FROM profiles ORDER BY full_name` | staff | |
| `upsertStaffByEmail({email, fullName, role})` | **RPC** `fn_upsert_staff_by_email(p_email, p_full_name, p_role)` | admin (checked inside the function) | Errors: `'Only admins can manage staff accounts.'`, `'Invalid role: %'`, `'No account found for email %. They must sign up first.'` — the person **must already have signed in at least once** (a `auth.users` row must exist) before they can be granted a `profiles` role; there is no invite-email flow |
| `updateStaffRole({profileId, role})` | `UPDATE profiles SET role=... WHERE id=...` | admin (RLS) | |
| `removeStaff({profileId})` | `DELETE FROM profiles WHERE id=...` | admin (RLS) | Revokes app access; **does not** delete the underlying `auth.users` login |

---

## Parent Portal (`features/parent_portal`) — the only unauthenticated surface

### `getPortalData(String token)`
- **RPC**: `fn_parent_portal_data(p_token uuid)`
- **Auth required**: **none.** Granted to both `anon` and `authenticated`. This is the one function in the entire schema designed to be called with no session.
- **Request**: `{'p_token': token}` — a string that must parse as a UUID (invalid UUID format raises a generic Postgres cast error, not custom text; a syntactically-valid-but-unknown UUID returns `null`, not an error — see below).
- **Response** (`jsonb`, `null` if the token doesn't match any `student_guardians.access_token`):
  ```json
  {
    "student": {
      "full_name": "string",
      "class_name": "string | null",
      "enrollment_status": "active | suspended | expelled | transferred_out | withdrawn | deceased | graduated",
      "enrollment_status_reason": "string | null",
      "enrollment_status_date": "YYYY-MM-DD | null"
    },
    "attendance_recent": [{ "date": "YYYY-MM-DD", "status": "hadir | lewat | tidak_hadir | cuti_sakit | urusan_rasmi" }, /* up to 30, newest first */],
    "attendance_week": { "present": 0, "total_days": 5 },
    "attendance_month": { "present": 0, "total_days": 21 },
    "merit_month": { "total_points": 0, "days_recorded": 0, "max_points_per_day": 10 }
  }
  ```
- **Security model**: the function looks up `student_id` from the token, then builds the entire response scoped to that one `student_id` — no other table or student is ever reachable through this path. **No distinction is made between "invalid token" and "valid token with no data"** — both cases where applicable return either `null` (bad token) or a fully-populated-but-zeroed response (valid token, e.g. a brand-new student with no attendance yet); this is deliberate, to avoid a validity oracle.
- **Client usage** (`parent_portal_screen.dart`, reached via the unauthenticated route `/parent/:token`):
  ```dart
  final data = await ref.watch(parentPortalDataProvider(token).future);
  if (data == null) {
    // show "This link isn't valid anymore" — do NOT distinguish reasons
  }
  ```
- **Rate limiting / abuse**: **none implemented.** Any caller with a valid `apikey` header (the public anon key, embedded in the client build) can call this function as fast as they like for any token they can guess/obtain. See `KNOWN_ISSUES.md`.

---

## Future / informational — Attendance Export API (not implemented)

> Draft only. See `ATTENDANCE.md` §6. Do not build unless explicitly requested.

D2C may later expose **resolved** `attendance_days` to authorized external systems (idMe/MOEIS/partners) while keeping today's exception-based capture. Suggested shape (conceptual — not present in this codebase):

- `GET /v1/attendance?school_date=...&class_id=...`
- `GET /v1/attendance/exceptions?school_date=...`
- `GET /v1/students/{student_id}/attendance?from=...&to=...`
- `GET /v1/exports/attendance?from=...&to=...`

Until then, the live attendance API remains the Supabase table ops + RPCs documented in §Attendance above.
