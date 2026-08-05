# COMPONENTS.md — Dare to Change (D2C)

> **Important context before using this file**: this codebase has **no shared `widgets/` library**. There is no `lib/shared/` or `lib/common/widgets/` directory. Reusable UI is either (a) a small number of genuinely cross-file **public** widgets/functions living in `core/` or a feature's `presentation/screens/` file and imported elsewhere, or (b) **private, screen-local** widgets (leading underscore) that are only reusable *within* their own file by copy-paste or promotion. Both categories are documented below — check the "Scope" column before assuming you can `import` something.

## Cross-File Reusable (public, safe to import)

### `HomeBackButton`
- **File**: `core/layout/app_shell.dart`
- **Scope**: public, imported by **every** feature screen except Dashboard/Home (11+ usages: Classes, Students, Attendance, Scan QR, Manual Attendance, Register QR, Merit, Class Summary, Rewards, Reports, Settings — plus Dashboard itself as of the mobile-nav fix).
- **Purpose**: Guaranteed way back to `/home` from any screen when there's no persistent sidebar (mobile/narrow layout). Does **not** rely on Flutter's default AppBar back-arrow behavior, which silently disappears whenever `Navigator.canPop()` is false (deep link, page reload, hash-route entry) — a real bug this widget was built specifically to fix.
- **Inputs**: none (`const HomeBackButton()`).
- **Outputs**: none — side-effecting `onPressed`.
- **Dependencies**: `go_router`'s `context.canPop()`/`context.pop()`/`context.go()`.
- **Behavior**: `context.canPop() ? context.pop() : context.go('/home')`.
- **Example**:
  ```dart
  appBar: AppBar(leading: const HomeBackButton(), title: const Text('Students')),
  ```

### `AppShell`
- **File**: `core/layout/app_shell.dart`
- **Scope**: public, wraps every route inside the router's `ShellRoute`.
- **Purpose**: Responsive layout switch — persistent sidebar (`_Sidebar`, private) above 720px width (or when `LayoutMode.sidebar` is forced), plain pass-through of `child` below that (or `LayoutMode.compact`). This is the **only** place screen-width breakpoints are decided; individual screens don't re-derive layout mode.
- **Inputs**: `currentPath` (String, from `GoRouterState.matchedLocation`, drives the active sidebar highlight), `child` (Widget, the routed screen).
- **Dependencies**: `layoutModeProvider` (`StateProvider<LayoutMode>`), `currentProfileProvider` (for the sidebar's account footer).
- **Related enum**: `LayoutMode { auto, sidebar, compact }` — cycled via the sidebar header's toggle icon (`AppShell.next(mode)`).

### `PeriodPicker`
- **File**: `features/merit/presentation/screens/period_picker.dart`
- **Scope**: public, imported by `reports_screen.dart` and `merit_class_summary_screen.dart`.
- **Purpose**: Row of quick-select chips (This week / Last week / This month / custom range picker).
- **Inputs**: `range` (`DateRange` — see below), `onChanged` (`ValueChanged<DateRange>`).
- **Outputs**: calls `onChanged` with a new range; does not manage its own state (fully controlled component).
- **Dependencies**: `showDateRangePicker` (Flutter built-in), the free functions `thisWeekRange()`/`lastWeekRange()`/`thisMonthRange()` (also exported from this file, ISO-week Monday-start convention).
- **Related type**: `typedef DateRange = ({DateTime from, DateTime to})` (`features/merit/domain/value_objects/date_range.dart`) — a Dart record type, used across Merit, Reports, and Dashboard for any "date range" parameter. **Reuse this typedef rather than inventing a new range shape** if you add a date-range feature.
- **Example**:
  ```dart
  late DateRange _range = thisWeekRange();
  // ...
  PeriodPicker(range: _range, onChanged: (range) => setState(() => _range = range)),
  ```

### `colorForEnrollmentStatus(EnrollmentStatus status)`
- **File**: `features/student/presentation/screens/student_detail_sheet.dart`
- **Scope**: public top-level function, imported by `parent_portal_screen.dart` (`show colorForEnrollmentStatus` import) and used internally by `student_list_screen.dart`'s status badges.
- **Purpose**: The single canonical status→color mapping (active=green, suspended=orange, expelled=red, transferredOut=blue, withdrawn=brown, deceased=blueGrey, graduated=purple). **Do not re-derive this mapping elsewhere** — import it.
- **Inputs**: `EnrollmentStatus` enum value.
- **Outputs**: `Color`.
- **Note on cross-feature import**: this is the *one* documented exception to "features only import each other's domain layer, never presentation" (see `ARCHITECTURE.md` §3) — flagged here so it isn't accidentally "fixed" into a duplicate.

### `showStudentDetailSheet(BuildContext context, Student student)`
- **File**: `features/student/presentation/screens/student_detail_sheet.dart`
- **Scope**: public function, the entry point for the whole enrollment-status + guardians bottom sheet.
- **Purpose**: `showModalBottomSheet` wrapper around `_StudentDetailSheet` (private). Called from `student_list_screen.dart`'s `ListTile.onTap`.
- **Inputs**: `context`, `student` (`Student` entity).
- **Outputs**: `Future<void>` (resolves when the sheet is dismissed).

### `AppTheme` static members
- **File**: `core/theme/app_theme.dart`
- **Scope**: public, imported wherever theme-aware colors/icons are needed.
- **Members**:
  - `AppTheme.light()` / `AppTheme.dark()` → `ThemeData`, wired into `MaterialApp.router` in `app.dart`.
  - `AppTheme.glow(Color color) → List<BoxShadow>` — the dark-mode neon-glow effect wrapped around stat cards (`Container(decoration: BoxDecoration(boxShadow: AppTheme.glow(color)))`).
  - `AppTheme.categoryPalette` — `List<(Color bg, Color accent)>`, 12 entries, one per Home-screen dashboard tile category, cycled by index.
  - `AppTheme.iconFor(ThemeMode)` / `AppTheme.labelFor(ThemeMode)` / `AppTheme.nextThemeMode(ThemeMode)` — the Auto→Light→Dark→Auto theme toggle cycle logic.
  - `themeModeProvider` — `StateProvider<ThemeMode>` (also declared in this file, not inside the `AppTheme` class), default `ThemeMode.system`.

---

## Screen-Local Reusable Patterns (private — `_`-prefixed, not importable)

These are documented because they represent **the established pattern to copy** if you build a similar UI elsewhere — not because you can `import` them. If a new screen needs a "stat card grid," look at this pattern in `dashboard_screen.dart` first rather than inventing a new one.

### `_ChartCard` / `_DashboardGrid` / `_StatCard`
- **File**: `features/dashboard/presentation/screens/dashboard_screen.dart`
- **`_ChartCard({title, child, trailing?})`**: the uniform card shell for every chart/leaderboard on the Dashboard — title row (with optional trailing control, e.g. a toggle switch) + content area. Every chart widget on the Dashboard is wrapped in one of these.
- **`_DashboardGrid({columns, children})`**: thin wrapper around `GridView.count` (`shrinkWrap: true`, `NeverScrollableScrollPhysics`, `childAspectRatio: 1.15`) — the column count is computed once in `DashboardScreen.build` via a `LayoutBuilder` breakpoint ladder (4/3/2/1 columns at 1300/950/620px) and passed down.
- **`_StatCard({icon, color, label, value, delta, deltaSuffix, lowerIsBetter, loading})`**: the top-row "Attendance Today / Present / Late / ..." cards, with a colored icon circle, a value, and a delta-vs-yesterday arrow (green/red based on `lowerIsBetter`). Wrapped in `AppTheme.glow()` in dark mode.
- **If you need a new dashboard-style stat/chart card elsewhere** (e.g. a future feature's own mini-dashboard), copy this triad rather than trying to import private classes — or, if reuse becomes frequent, that's a signal to promote them into a new `core/widgets/` file (does not currently exist).

### `_RearrangeDashboardSheet` / `_CatalogOrderList`
- **File**: `features/dashboard/presentation/screens/dashboard_screen.dart`
- **Purpose**: The Dashboard's drag-and-drop **and** up/down-button card reordering UI. `_CatalogOrderList` is the reusable half — takes an ordered `List<String>` of ids, a `Map<String, (IconData, String)>` catalog, and an `onMove(oldIndex, newIndex)` callback; renders a `ReorderableListView` (`buildDefaultDragHandles: true`, forced on for cross-platform reliability) **plus** explicit up/down `IconButton`s per row (the iPad-Safari-safe fallback — see `PROJECT.md` design decision #6, `KNOWN_ISSUES.md`).
- **If you ever need reorderable-list UI elsewhere, copy `_CatalogOrderList`'s dual-interaction pattern, not a plain `ReorderableListView`.**

### `_GuardianCard` / guardian form dialogs
- **File**: `features/student/presentation/screens/student_detail_sheet.dart`
- **Purpose**: The Add/Edit Parent-Guardian `AlertDialog` pattern (`StatefulBuilder` + local `TextEditingController`s + inline `errorText` + try/catch around the save call). This is the established dialog pattern across the whole app — see also `settings_screen.dart`'s `_showAddStaffDialog`, which uses the identical shape (title, `Column` of `TextField`s, inline error `Text`, `Cancel`/`Save` actions with the save button doing `try { await repo.mutate(...); ref.invalidate(...); Navigator.pop(...) } catch (e) { setDialogState(...) }`). **Copy this shape for any new "add/edit a small record" dialog** rather than inventing a new form pattern.

### `_LeaveTypeBar`, `_WeekRow`, `_KpiCard`
- **File**: `features/reports/presentation/screens/reports_screen.dart`
- Small presentational bar-chart-as-`Stack`-of-`Container`s widgets (a grey background bar + a `FractionallySizedBox`-clipped colored foreground bar). This hand-rolled bar pattern (not `fl_chart`) is used wherever a single inline proportion needs showing without the overhead of a full chart widget — copy it for similar "one bar, one number" UI rather than reaching for `fl_chart`.

---

## Non-Widget Reusable Utilities

| Name | File | Purpose |
|---|---|---|
| `_dateOnly(DateTime)` | repeated in **many** files (`dashboard_screen.dart`, `*_repository_impl.dart` files) as a private top-level function | Strips time-of-day, returns `DateTime(y, m, d)`. **Duplicated across ~8 files**, not shared — see `KNOWN_ISSUES.md` / `CODING_STANDARDS.md`. If touching date handling, be aware there is no single canonical `dateOnly` helper. |
| `thisWeekRange()` / `lastWeekRange()` / `thisMonthRange()` | `period_picker.dart` | ISO-week (Monday-start) range helpers, public, reused by Merit/Reports/Dashboard for default period selection. |
| `_niceInterval(double maxValue)` | `dashboard_screen.dart` | Rounds a chart axis max to a "nice" 1/2/5×10ⁿ interval so `fl_chart` y-axis labels don't overlap. Private to this file; copy if building a new chart with the same overlap problem elsewhere. |
| `EnrollmentStatus` enum (+ `.dbValue`/`.label`/`.shortLabel`/`.fromDb()`) | `features/student/domain/entities/enrollment_status.dart` | The canonical bilingual status enum — **the pattern to copy** for any future enum needing a DB string ↔ Dart enum ↔ display label round-trip (see also `AttendanceStatus` in `attendance/domain/entities/attendance_status.dart`, which follows the identical shape). |

## What Does *Not* Exist (don't assume)

- No shared `AppButton`/`AppCard`/`AppTextField` design-system widget set — every screen uses stock Material widgets (`ElevatedButton`, `Card`, `TextField`) styled by the global `ThemeData` in `app_theme.dart`.
- No shared form-validation library — validation is inline (`if (text.trim().isEmpty) setState(() => errorText = '...')`).
- No shared loading/error/empty-state widget — every `.when(data:, loading:, error:)` branch writes its own `CircularProgressIndicator()`/`Text('Failed to load: $error')` inline. If you're asked to "make loading states consistent," this is genuinely not built yet, not a broken abstraction.
