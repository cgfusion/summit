# CODING_STANDARDS.md — Dare to Change (D2C)

> The conventions this codebase actually follows, observed from ~20 migrations and ~70 Dart files built consistently across one long build session. Match these, don't introduce a competing style.

## Naming Conventions

See `UI_GUIDELINES.md` §Naming Convention for widget/file/provider naming. Additionally:

- **Domain entities**: nouns, `PascalCase`, immutable (`class Student { const Student({...}); final String id; ... }`), always with a `factory X.fromMap(Map<String, dynamic> map)` constructor for Supabase row deserialization. No `toMap()`/serialization-to-DB method on entities that are read-only from the client (e.g. `Student` has no `toMap` — writes go through named RPC params, not entity serialization).
- **Enums with a DB round-trip**: always three members — `fromDb(String) → Enum` (static factory, throws `ArgumentError` on unknown value), `dbValue` (getter, the exact Postgres `text` value), `label` (getter, display string). See `AttendanceStatus` and `EnrollmentStatus` for the canonical shape — **copy this exactly** for any new status/category enum backed by a `text check(...)` column.
- **Record types over classes for simple tuples**: `typedef DateRange = ({DateTime from, DateTime to})` is a Dart 3 record, not a class — used whenever a lightweight, comparable (`==` works structurally on records) value pair is needed and a full entity class would be overkill.
- **SQL**: `snake_case` throughout — table names plural (`students`, `attendance_days`), function names verb-first with `fn_` prefix for client-facing RPCs (see `UI_GUIDELINES.md`), column names never abbreviated except well-established domain terms already in the school's own vocabulary (`ic_number`, not `icn`).

## Folder Conventions

Strict three-layer, feature-first (see `PROJECT.md` §5 for the tree). Rules that are **never violated** across the whole codebase:
1. `domain/` has **zero** imports of `flutter/material.dart`, `supabase_flutter`, or any `data`/`presentation` file. Pure Dart only.
2. `data/repositories/*_repository_impl.dart` imports `supabase_flutter` and its own feature's `domain/`. It does **not** import `presentation/` (no repository imports Riverpod).
3. `presentation/providers/*.dart` imports `flutter_riverpod`, its feature's `domain/` and `data/`. It does **not** import `presentation/screens/` (providers never import widgets) — **except** the one documented cross-feature exception (`colorForEnrollmentStatus`, imported by `parent_portal`'s **screen**, not its provider — see `COMPONENTS.md`).
4. `presentation/screens/*.dart` imports its own feature's `domain/entities` and `presentation/providers`, plus `core/` (theme, layout, router) freely. Cross-feature screen imports are rare and always of another feature's `domain/entities` or the one flagged exception, never another feature's `presentation/providers` or `data/`.

**One repository interface + one implementation per feature.** No feature has ever needed two implementations of the same interface (no fake/test double exists) — the `SupabaseClient? client` constructor param exists for that possibility but is unused today.

## File Organization

- One primary public class per file, filename matches (`snake_case` of the `PascalCase` class).
- Small, tightly-coupled private widgets live in the **same file** as their parent screen, not split out — `dashboard_screen.dart` is 1500+ lines and contains ~25 private widget classes; this is the established norm, not something to "refactor into smaller files" unprompted. Splitting is only warranted when a widget becomes genuinely reusable across files (promote it to a new file **and** update `COMPONENTS.md`).
- Migrations: one file per logical change, timestamp-prefixed (`YYYYMMDDHHMMSS_description.sql`), **never edited after being applied to production** — a correction is always a new migration (`create or replace function`, `alter table add column`, etc.), never a hand-edit of an old migration file. The one exception is `20260806000002_attendance_period_summary_expand.sql`, which used `drop function if exists ...; create function ...` because the return-table shape itself changed (column additions require this in Postgres when using `create function` rather than `create or replace function` with a compatible signature).

## SOLID Principles (as applied here, not textbook)

- **Single Responsibility**: one repository per feature, one entity per concept, one provider per data need. Screens are allowed to be large (they compose many small private widgets) — SRP is enforced at the *class* level, not the *file* level.
- **Open/Closed**: SQL functions are extended via `create or replace function` with the *same signature* wherever possible (adding a `WHERE` clause, a new computed column at the end of a `RETURNS TABLE`) rather than breaking callers. When a breaking signature change is unavoidable (e.g. `fn_attendance_period_summary`'s scope-tier expansion), it's a `DROP ... CREATE` in its own migration with a header comment explaining why the additive path wasn't possible.
- **Liskov Substitution**: every `*RepositoryImpl` is used exclusively through its `abstract interface class` — Riverpod providers type as `Provider<FooRepository>`, never `Provider<FooRepositoryImpl>`, so a substitute implementation is a drop-in by construction.
- **Interface Segregation**: repository interfaces are narrow and feature-scoped — there is no god `DatabaseRepository`. `StudentRepository` has grown to ~12 methods (students + guardians + enrollment status) because those are genuinely one feature's concerns, not because interfaces are left broad by default.
- **Dependency Inversion**: `presentation` depends on `domain` abstractions (`abstract interface class FooRepository`), never on `data`'s concrete `FooRepositoryImpl` — the only place a concrete impl is named is inside its own `Provider<FooRepository>((ref) => FooRepositoryImpl(...))` constructor call.

## Clean Architecture Rules

- **No use-case/interactor layer.** A Riverpod provider *is* the use case — `studentsProvider` directly calls `repository.getStudents(...)`. Do not introduce a `GetStudentsUseCase` class; it would be pure ceremony in this codebase's actual complexity level.
- **Business logic that spans rows lives in SQL, not Dart.** If you find yourself writing a `for` loop over a fetched list to compute a total/rate/grouping in a repository or provider, that's a strong signal it should be a SQL function instead (see `ARCHITECTURE.md` §4 "rule of thumb").
- **Entities never carry behavior beyond simple derived getters.** `ParentPortalData` has getters like `attendanceWeekRate` (`present / total * 100`, guarding divide-by-zero) — this is fine (pure, no I/O, no side effects). An entity method that calls a repository or mutates other entities would not fit this codebase's pattern.

## Riverpod Rules

- **No `riverpod_generator`/code generation** — every provider is hand-written `final xProvider = Provider<T>((ref) => ...)`. Do not introduce `@riverpod` annotations without a deliberate, discussed migration — it would create two competing provider styles in one codebase.
- **`.autoDispose` by default** on every data-fetching provider (`FutureProvider.autoDispose`, `FutureProvider.autoDispose.family`). Only app-lifetime singleton state (`themeModeProvider`, `layoutModeProvider`) omits it.
- **`.family` for anything parameterized** — a provider that needs an argument (a date, a token, a student id) is always `.family`, never a provider that's manually re-constructed or wrapped in a `StateProvider<Params>` + derived provider pair.
- **Mutations invalidate, they don't patch.** After any write, the call site does `ref.invalidate(theRelevantProvider)` (or the specific `.family` instance) to force a clean refetch. No provider manually merges/patches its own cached state after a mutation — the one exception is `DashboardLayoutController` (a `StateNotifier`), which updates local state optimistically *and* persists in the background, specifically because that one interaction (drag-reorder) needs to feel instant.
- **`StateNotifierProvider` is reserved for optimistic-update-with-background-sync cases**, not used as a general "provider with a controller" pattern. If a new feature doesn't need optimistic UI, use `FutureProvider` + explicit `ref.invalidate` instead, even if it means an extra network round-trip before the UI updates.

## Flutter Best Practices Observed

- `ConsumerWidget`/`ConsumerStatefulWidget` throughout — never `StatefulWidget` + a manually-wired `ProviderScope.containerOf` or similar workaround.
- Dialogs use `StatefulBuilder` inside `showDialog`'s `builder` for local form state, rather than extracting a separate `StatefulWidget` — this is consistent across every add/edit dialog in the app (see `COMPONENTS.md` guardian-form-dialog note).
- `context.mounted` is checked after every `await` before touching `context` again inside an async callback (`if (dialogContext.mounted) Navigator.pop(dialogContext);`).
- No `GlobalKey<FormState>`/`Form` widget usage anywhere — validation is manual (`if (controller.text.trim().isEmpty) { setState(...); return; }`), consistent with "no shared form-validation library" (`COMPONENTS.md`).
- Records (`({DateTime from, DateTime to})`, `(IconData, String)`) are used freely as lightweight typed tuples wherever a full class would be overkill — this is idiomatic to the Dart 3.12 SDK constraint this project targets; don't downgrade to positional-arg workarounds for older Dart.

## Supabase Best Practices Observed

- **Every table has RLS enabled**, no exceptions, from the very first migration. A new table without `alter table ... enable row level security` immediately after `create table` is a bug, not an oversight to fix later.
- **`security definer` functions always start with an explicit authorization check** (`if not is_admin() then raise exception ...`) as their first executable statement — RLS does not protect a `security definer` function's internals; the function's own code is the boundary.
- **Views that should respect RLS use `with (security_invoker = true)`** — `merit_student_daily` is the only view in the schema and gets this exactly once; if you add a second view, don't forget it (see `DATABASE.md`'s warning under Views).
- **`create or replace function`** is preferred over `drop + create` whenever the signature allows it, to avoid needing to re-`grant execute` (grants persist across `create or replace` for the same signature, but not across a `drop`).
- **Every migration is verified against live data before being considered complete** — via `supabase db query --linked`, often simulating a specific role/user with `set local role authenticated; set local request.jwt.claim.sub = '<uuid>';` (or `set local role anon;` for public-RPC testing). This is not optional polish; see `AI_RULES.md`.
- **Seed/bulk-data scripts are idempotent via `ON CONFLICT ... DO UPDATE`**, keyed on a real unique constraint added specifically to support the reimport (e.g. `student_guardians`'s `(student_id, full_name)` unique index was added *for* `scripts/generate_guardian_seed_sql.py`'s re-runnability, not incidentally).

## Error Handling

See `ARCHITECTURE.md` §9 for the full strategy table. Summary rules:
- Repository methods **do not catch exceptions** — they let `PostgrestException`/`AuthException` propagate untouched.
- `FutureProvider`s need no explicit try/catch — Riverpod wraps a thrown error into `AsyncValue.error` automatically.
- Only **mutation call sites inside dialogs/forms** wrap calls in `try/catch`, surfacing `error.toString()` inline via `setDialogState(() => errorText = 'Failed to X: $error')`. Never a separate error dialog/toast for this category of failure.
- SQL `raise exception` message text is user-facing (shown verbatim in the UI) — write these as if a non-technical staff member will read them, not as internal debug strings.

## Logging

**None.** No `logger`/`print`/analytics SDK is wired into this app anywhere. Debugging happens via the browser console (Flutter's own uncaught-exception output) and manual live verification. If asked to "add logging," there is no existing convention to extend.

## Testing Expectations

**Minimal, by design so far** — one smoke test exists: `app/test/widget_test.dart`, which pumps `MissingConfigApp` and asserts the "Missing Supabase configuration" message renders when `Env.isConfigured` is false. There is:
- **No widget test** for any feature screen.
- **No unit test** for any repository, provider, or entity.
- **No integration test** against a real/mocked Supabase instance.

**The actual correctness gate for this project is**: `flutter analyze` (must report zero issues) + `flutter test` (the one smoke test must pass) + **live manual verification in a real browser** (Claude in Chrome or equivalent) after every deploy, including exercising the actual user flow (click through the feature, confirm the data shown matches what was independently verified via `supabase db query --linked`). This is heavier-weight than automated tests in some ways (it catches real deploy/caching/RLS issues automated tests wouldn't) and lighter in others (no regression suite — a change can silently break an unrelated screen with nothing catching it). **Do not claim a feature is "tested" based on `flutter analyze` passing alone** — that only proves it compiles.
