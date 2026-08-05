# UI_GUIDELINES.md — Dare to Change (D2C)

> The design system as it actually exists in `core/theme/app_theme.dart` and the conventions repeated across screens — not an aspirational spec. Where the app deviates screen-to-screen, that's noted rather than smoothed over.

## Color System

Defined entirely in `core/theme/app_theme.dart`. Both light and dark themes are seeded from **one color** via Material 3's `ColorScheme.fromSeed`.

| Token | Value | Usage |
|---|---|---|
| `AppTheme.seedColor` | `#228B22` (forest green) | `ColorScheme.fromSeed(seedColor:)` for both light and dark — the source of every Material-derived color (primary, secondary, surface, etc.) |
| `AppTheme.gradientEndColor` | `#0F5C3A` | Paired with `seedColor` in `heroGradient` |
| `AppTheme.heroGradient` | linear, top-left→bottom-right, `[seedColor, gradientEndColor]` | Sign-in screen background, sidebar header background |
| `AppTheme.lightScaffoldBackground` | `#F5FAF6` (very pale green-white) | Light-mode scaffold background |
| `AppTheme.darkScaffoldBackground` | `#0B0F1D` (near-black navy) | Dark-mode scaffold background |
| `AppTheme.darkPageGradient` | `[#0B0F1D, #121A2E, #17122B]` | **Dashboard screen only**, dark mode only — every other screen uses the plain `darkScaffoldBackground` |
| `AppTheme.darkCardColor` | `#141B2E` | Dark-mode `CardThemeData.color` |

**Status colors** (not tokenized centrally — each enum/screen defines its own switch statement; see `CODING_STANDARDS.md` for the "why isn't this shared" note):

| Meaning | Color | Where |
|---|---|---|
| Present/On-time/Active/Good | `Colors.green` | `AttendanceStatus.hadir`, `EnrollmentStatus.active` |
| Late/Suspended/Warning | `Colors.orange` | `AttendanceStatus.lewat`, `EnrollmentStatus.suspended` |
| Absent/Expelled/Error | `Colors.red` | `AttendanceStatus.tidakHadir`, `EnrollmentStatus.expelled` |
| Excused-sick/Transferred/Info | `Colors.blue` | `AttendanceStatus.cutiSakit`, `EnrollmentStatus.transferredOut` |
| Official-business/Graduated | `Colors.purple` | `AttendanceStatus.urusanRasmi`, `EnrollmentStatus.graduated` |
| Withdrawn | `Colors.brown` | `EnrollmentStatus.withdrawn` |
| Deceased | `Colors.blueGrey` | `EnrollmentStatus.deceased` |

**Dashboard category palette** (`AppTheme.categoryPalette`, 12 `(bg, accent)` pairs, cycled by index for the Home screen's tile grid): pastel-light background + saturated accent, e.g. Classes = `(#E8EEFF, #3B5BDB)` blue, Students = `(#E3F6EC, #12805C)` teal, Attendance = `(#EAF7E9, #2F9E44)` green, Merit = `(#FFF4DE, #E8A400)` amber, Rewards = `(#FDE9F1, #D6336C)` pink, Reports = `(#E6FBFA, #0C8599)` cyan, Dashboard = `(#E9F3FF, #1864AB)` deep blue. Full list in `app_theme.dart` lines 59-72 — treat these as fixed brand colors per feature, not arbitrary.

**Dark-mode glow**: `AppTheme.glow(Color color)` returns a single soft `BoxShadow` (28% alpha, 24px blur, -6px spread) behind a card — the dashboard's "neon accent" look, applied only in dark mode (`if (!isDark) return card; return Container(decoration: BoxDecoration(boxShadow: AppTheme.glow(color)), child: card);`).

## Typography

No custom font family — Material 3's default (Roboto on most platforms) via `useMaterial3: true`. No custom `TextTheme` overrides beyond what `ColorScheme.fromSeed` implies. Text sizing follows Material 3's default type scale (`headlineSmall`, `titleLarge`, `titleMedium`, `titleSmall`, `bodyMedium`, `bodySmall`) accessed via `Theme.of(context).textTheme.*`, always with `.copyWith(fontWeight: FontWeight.bold)` for emphasis rather than a distinct "bold" text style token.

## Spacing

No spacing-scale constants (`AppSpacing.sm`, etc. do not exist). Spacing is ad hoc `SizedBox(height: N)` / `EdgeInsets.all(N)` per-widget, with an informal convention:
- **4** — tight (icon-to-text gaps)
- **8** — related-element gaps (label to value)
- **12–16** — card internal padding, section gaps
- **20–24** — page-level padding, major section breaks

`Card` internal padding is `EdgeInsets.all(12)` or `EdgeInsets.all(16)` depending on content density (compact list rows use 12, stat cards use 14-16).

## Card Styles

Global `CardThemeData` (both themes): `elevation: 0`, `borderRadius: circular(20)`. Light mode: `color: Colors.white`, no border. Dark mode: `color: darkCardColor` (`#141B2E`), plus a subtle `BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4))` — dark cards get an outline since there's no elevation/shadow to separate them from the dark background.

`ChipThemeData`: `shape: StadiumBorder()`, `side: BorderSide.none` — every `Chip`/`ChoiceChip`/`ActionChip` in the app is a stadium (fully rounded) pill.

`FilledButtonThemeData` / `OutlinedButtonThemeData`: `borderRadius: circular(12)`, `padding: symmetric(horizontal: 20, vertical: 14)` — consistent across both themes.

`AppBarTheme`: `backgroundColor: Colors.transparent`, `elevation: 0`, `centerTitle: false` — app bars blend into the page background rather than reading as a distinct bar.

## Animations

**No custom animation system** — no `AnimationController`s, no custom transitions, no `Hero` widgets anywhere in the codebase. Motion comes entirely from Flutter/Material defaults: `ReorderableListView`'s built-in drag animation, `AnimatedSwitcher`-free `.when()` state swaps (loading→data transitions are instant, no crossfade), default page-route transitions from `go_router`/`MaterialApp.router`. If asked to "add a transition," there is no existing pattern to extend — it would be new territory.

## Theme

Three-state theme mode: `ThemeMode.system` (default) → `ThemeMode.light` → `ThemeMode.dark` → back to `system`, cycled via `AppTheme.nextThemeMode()`, triggered by a toggle `IconButton` present on **every** top-level screen's AppBar (icon changes via `AppTheme.iconFor(mode)`: auto/light/dark icons). State lives in `themeModeProvider` (`StateProvider<ThemeMode>`), app-lifetime (not `.autoDispose`), **not persisted** — resets to `system` on page reload (no `shared_preferences`/localStorage wiring for this; see `KNOWN_ISSUES.md`).

Both `AppTheme.light()` and `AppTheme.dark()` **must be updated in parallel** whenever a themed property changes — there is no "compute dark from light" derivation; they're two independent `ThemeData` builders that happen to share the same seed color and shape constants.

## Responsive Rules

Single breakpoint constant: `_sidebarBreakpoint = 720.0` (in `core/layout/app_shell.dart`) — below it, `LayoutMode.auto` shows the plain mobile layout (tile-grid Home, no persistent sidebar); at/above it, the sidebar appears. This can be overridden per-user via the sidebar header's cycle toggle (`LayoutMode.sidebar` forces it on regardless of width, `LayoutMode.compact` forces it off).

The **Dashboard's own internal grid** (`_DashboardGrid`) has a *separate*, finer breakpoint ladder computed independently in `dashboard_screen.dart`'s `LayoutBuilder`: 4 columns ≥1300px, 3 columns ≥950px, 2 columns ≥620px, else 1. This is unrelated to the sidebar breakpoint — a screen can be in sidebar mode (≥720px) while the dashboard grid itself is still only showing 2 columns (620-950px available *after* the sidebar's 260px is subtracted).

`_TopStatsRow`'s stat-card `Wrap` has its own third breakpoint ladder (6 cards/row ≥1300px, 3 ≥900px, 2 ≥500px, else 1) — **three independent breakpoint systems coexist on one screen**. This is not an oversight to "unify" without understanding why — each was tuned for its own content's minimum comfortable width.

Mobile-specific device detection (`resize_window` preset `mobile` in dev tooling) also emulates touch input, which matters for the `ReorderableListView` drag-handle reliability issue (see `KNOWN_ISSUES.md`) — always test drag-and-drop UI at both preset sizes, not just narrow width.

## Icons

Material Icons only (`uses-material-design: true`), always the `_outlined` variant for nav/AppBar icons where available (`Icons.dashboard_outlined`, `Icons.people_outline`, `Icons.fact_check_outlined`, etc.) — filled icons are reserved for *active/selected* state (e.g. a selected sidebar tile) or semantic emphasis (`Icons.warning_amber_rounded` for compliance banners, unfilled would undersell the warning). No custom icon font/SVG icon set.

## Naming Convention

- **Files**: `snake_case.dart`, one primary public class per file named to match (`dashboard_screen.dart` → `DashboardScreen`).
- **Widgets**: `PascalCase`, private screen-local widgets prefixed `_` (e.g. `_StatCard`, `_GreetingHeader`) — see `COMPONENTS.md` for the reuse implications of this.
- **Providers**: `camelCase` + `Provider` suffix, named after what they expose, not how (`studentsProvider`, not `studentsFutureProvider`); a filter/local-UI-state provider is named after the concept it holds (`studentIncludeInactiveProvider`, `dashboardReferenceDateProvider`).
- **Repository methods**: verb-first, matching REST-ish semantics even though nothing is REST (`getStudents`, `addGuardian`, `updateEnrollmentStatus`, `deleteGuardian`) — never `fetchX`/`retrieveX`/`loadX` inconsistently; `get` is the one verb for all reads.
- **SQL functions**: `fn_` prefix, `snake_case`, always `public.fn_verb_noun` (`fn_update_student_status`, `fn_class_attendance_summary`). Helper/security functions omit the prefix (`is_admin`, `is_staff`, `touch_updated_at`) — the `fn_` prefix specifically marks "an RPC the Flutter client calls," not "any Postgres function."

## Dashboard Standards

The Dashboard (`dashboard_screen.dart`, the largest single file in the app) is the closest thing to a canonical "reference implementation" for this app's visual conventions. If in doubt about how a new data-heavy screen should look, match its patterns:
- Every metric gets a `_StatCard` or `_ChartCard`, never a bare `Text` widget floating on the page background.
- Every chart card has a title in `titleSmall` + `bold`, an optional `trailing` control (switch/toggle) inline with the title — never a separate settings row below the chart.
- Loading states inside a card show a `CircularProgressIndicator` **inside the card's existing bounds** (not a full-card skeleton, not a page-level spinner) — the card shell always renders immediately, only its content area shows loading.
- The user-customizable layout (`DashboardLayoutController`) is the one screen in the app with persisted per-user UI state — this is intentionally **not** a pattern extended to every list/filter elsewhere (e.g. `studentIncludeInactiveProvider` resets every session); only the Dashboard's card *order* is considered worth persisting.
