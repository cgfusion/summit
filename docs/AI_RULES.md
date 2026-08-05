# AI_RULES.md — Dare to Change (D2C)

> This document is written **for AI agents**, not humans. It is a set of hard constraints and a workflow discipline, derived from how this project has actually been built across dozens of shipped features. Violating these is how you break production — there is no staging environment to catch you first.

## 0. There Is No Staging. Production Is the Only Database.

Every `supabase db push` targets the **linked production project** directly. There is no local Postgres (Docker isn't available in this dev environment), no staging Supabase project, no dry-run mode. Every migration you write will run against real student data (~614 students, real names, real IC numbers, real phone numbers as of the guardian import) the moment you push it.

**Consequence**: be conservative. Prefer additive migrations (`add column`, `create function`) over destructive ones (`drop column`, `drop table`). If a migration must be destructive, read the data first (`SELECT count(*)`, spot-check real rows) before writing the migration that touches it.

## 1. Schema & API Stability

- **Never rename an existing table or column** without a clear instruction to do so and a migration that handles the rename safely (`alter table ... rename column`, not drop+recreate, which loses data).
- **Never break a `fn_*` function's existing signature** if it's still called from the deployed Flutter app — client and server deploy independently (Flutter deploys via GitHub Actions on a `git push`; the SQL migration deploys the moment you run `supabase db push`), so there is a window where old client code calls a function you're mid-edit on. Prefer `create or replace function` with the **same parameter list**, adding new optional params with defaults at the end, over a breaking signature change. If a breaking change truly is needed, ship the SQL migration and the matching Flutter change in the same commit/session — never leave them out of sync.
- **Never remove a column that Flutter code still selects.** Grep `app/lib` for the column name before dropping it (`grep -rn "column_name" app/lib`).
- **Preserve backward compatibility for anything reachable without a staff session.** `fn_parent_portal_data`'s response shape is consumed by parents who may have an old cached page open — changing its JSON shape without also handling the old shape gracefully (or accepting a brief breakage window) is a real, live-user-facing risk, unlike an internal admin tool.

## 2. Verify Every Migration Against Live Data — Never Trust "It Should Work"

This is the single most important operational habit in this project. The pattern, every time:

```bash
# 1. Write the migration file under supabase/migrations/, timestamp-prefixed.
# 2. Push it.
SUPABASE_ACCESS_TOKEN=<token> supabase db push
# 3. Verify with a REAL query against REAL data, simulating the actual caller's role.
SUPABASE_ACCESS_TOKEN=<token> supabase db query --linked "
  set local role authenticated;
  set local request.jwt.claim.sub = '<a real profiles.id from a live query>';
  select public.fn_whatever(...);
"
# For anon-reachable functions (Parent Portal only, currently):
SUPABASE_ACCESS_TOKEN=<token> supabase db query --linked "
  set local role anon;
  select public.fn_parent_portal_data('<real token>'::uuid);
"
```

- **Never mock data to test a migration.** Fetch a real id (`select id from students where enrollment_status='active' limit 1`) and use it.
- **Test both the happy path and the rejection path.** For every new guard (e.g. "inactive students can't have attendance marked"), verify the guard actually rejects — flip a real (test) record's status, confirm the write fails with the expected message, then **flip it back** before moving on. Don't leave test-mutated production data behind.
- **Clean up test writes.** If you `insert`/`update` a real row to test something, `delete`/revert it in the same session before considering the task done — this project's history has several examples of inserting a throwaway `student_guardians` row, verifying, then explicitly deleting it and resetting the student's status back to `'active'`.
- **`Docker Desktop`/local `--local` push will emit a harmless warning** ("failed to inspect docker image... elevated privileges") on `db push` — this is expected in this environment and does not mean the push against `--linked` failed. Read the actual push output ("Applying migration... Finished") to confirm success, don't treat the Docker warning as an error.

## 3. Search Before You Create

- **Grep for an existing repository/entity/provider before writing a new one.** This codebase has exactly one repository per feature — if you're about to write `StudentDetailRepository` because `StudentRepository` "feels too big," you're wrong; extend the existing one (it already has 12+ methods spanning students, guardians, and enrollment status — that's the established granularity).
- **Grep for an existing SQL function before writing a new one that does almost the same thing.** `fn_class_attendance_summary` already powers three different UI surfaces (Top/Worst class leaderboards, the "missing attendance today" banner) via different client-side filters on the same query — check whether an existing function's output already contains what you need before adding a new one.
- **Check `COMPONENTS.md` before writing a new widget.** If a dialog, card, or list pattern you need already exists (even privately, screen-local), copy its shape rather than inventing a new one — this codebase has exactly one dialog pattern, one card-grid pattern, one status-badge pattern; a second competing pattern for the same job is a code smell here specifically.
- **Never duplicate a `dateOnly`/date-formatting helper into a 9th file** without at least checking whether this is finally the moment to extract a shared one (see `KNOWN_ISSUES.md` — this is flagged tech debt, not an invitation to add a 10th copy).

## 4. Never Duplicate Widgets, Services, or Repositories

- **One `*RepositoryImpl` per feature, always.** If you're tempted to write a second implementation of an existing interface, you almost certainly want to add a method to the existing one instead.
- **One canonical status→color/label mapping per enum.** `colorForEnrollmentStatus` exists in exactly one place and is imported cross-feature specifically to avoid a second copy — do the same for any new status enum's color mapping rather than re-deriving it in a new screen.
- **Widgets**: before writing a new `_StatCard`-shaped or `_ChartCard`-shaped widget, check whether the existing private one in `dashboard_screen.dart` can be reused by promoting it to a shared file, rather than writing a third near-identical card widget in a new screen.

## 5. The Full Ship Loop (do not skip steps)

Every feature, every time, in this order:
1. **Design/clarify** — if the request has genuine open design decisions (auth method, data scope, UI pattern with real trade-offs), ask the user via a structured question **before** writing code. This project's history shows this pays off repeatedly (e.g., the Parent Portal's login-method question avoided building an SMS-OTP flow with no SMS provider account).
2. **Migration** (if schema/RPC changes are needed) → push → live-verify (see §2).
3. **Flutter code**: entity → repository interface → repository impl → provider → UI, in that order (domain outward — see `CODING_STANDARDS.md` layer rules).
4. **`flutter analyze`** — must report **zero issues** before proceeding. Fix, don't suppress with `// ignore:`.
5. **`flutter test`** — must pass.
6. **Commit + push to `main`** — this repo has no PR/review workflow; commits go directly to `main` and auto-deploy via GitHub Actions on push (confirmed project convention — do not propose a PR workflow for this repo unless explicitly asked).
7. **Poll GitHub Actions** (`gh api` or the REST API directly) until the run for your commit SHA shows `status: completed`.
8. **Live-verify in a real browser** against `https://cgfusion.github.io/summit/` — click through the actual feature, don't just confirm the page loads. **Hard-reload** (`Ctrl+Shift+R`) before judging — see §6, caching is aggressive here.

## 6. Caching Will Lie to You — Don't Conclude "It's Broken" Too Fast

This project has hit this repeatedly. Before reporting a live-verification failure as a real bug:
1. `curl -s <deployed-url>/main.dart.js | grep "<a unique string from your new code>"` — confirms the **server** has your build. If this fails, the deploy genuinely didn't ship (check GitHub Actions logs). If it succeeds, the bug is in the browser's cache, not your code.
2. Hard-reload (`Ctrl+Shift+R`) the specific tab you're checking — a plain reload can serve a cached `main.dart.js` even on a URL never visited before, because GitHub Pages serves it with `Cache-Control: max-age=600` and this is a per-URL, not per-tab, cache.
3. If still stale, close the tab and open a **genuinely fresh** one — some caching layers (service worker Cache Storage) survive a hard-reload.
4. If *still* stale after that, it may be **CDN edge-node propagation lag** (different network paths hit different Fastly PoPs with independent TTLs) — wait a few minutes and retry rather than assuming the deploy failed. This has been observed to resolve itself within the 10-minute cache TTL with no code change.
5. **Never "fix" working code because a stale cache made it look broken.** Verify via `curl` against the deployed bundle first, every time, before touching source.

## 7. Security Rules

- **`security definer` functions must check authorization as their first statement.** `if not is_admin() then raise exception 'not authorized'; end if;` (or `is_staff()`, matching the intended access level) — this is the actual security boundary for these functions, RLS does not apply inside them.
- **Never grant `execute` on a function to `anon` without deliberately designing it to be safe for anyone on the internet to call.** Currently exactly one function (`fn_parent_portal_data`) is `anon`-reachable, and it is scoped so tightly (one token → one student, no other table reachable) that this was a careful, reviewed decision — not a default. If you add a second `anon`-reachable function, apply the same rigor: what's the absolute worst thing an anonymous caller with unlimited retries could do with it?
- **Never log, print, or display a `student_guardians.access_token` outside of building a share link.** It is a bearer secret — treat it like a password, not an id.
- **RLS enabled on every new table, no exceptions**, immediately after `create table`, even if you plan to "add policies later" — an RLS-disabled table with no policies is wide open to any `authenticated` user, which is worse than RLS-enabled-with-no-policies (default-deny).
- **Client-side checks are UX, not security.** A guard like `if (student.enrollmentStatus != EnrollmentStatus.active) reject` in a screen is there to fail fast with a good error message — it does not replace the server-side guard inside the RPC/trigger. If you add a client-side-only guard for something security-sensitive, you have not actually secured anything; add the server-side check too.

## 8. Design-Decision Discipline

- **Ask before building something with a real cost or security trade-off**, especially: authentication method, third-party service integration (SMS/email providers), anything that stores new PII, anything that changes who can see what data. This project's history shows `AskUserQuestion` used deliberately before the Dashboard-rearrange interaction model, the Student Status feature's ripple-effect scope, and the Parent Portal's entire auth approach — each time avoiding a wrong-sized or wrong-shaped build.
- **Don't assume multi-tenancy, generic configurability, or "future schools using this too."** This is intentionally single-school software (see `PROJECT.md` §9). Do not add a `school_id` column or tenant-scoping "just in case" unless explicitly asked.
- **Don't silently change an established, deliberately-chosen convention** (e.g. the fixed-vs-elapsed denominator distinction in `PROJECT.md` §3) because it "looks inconsistent" — read the migration header comments; inconsistency here is often intentional and documented.

## 9. Data & Import Scripts

- `scripts/generate_seed_sql.py` and `scripts/generate_guardian_seed_sql.py` are **read-only against their Excel sources** and **never connect to a database directly** — they write a `.sql` file to `supabase/seed/`, which is then applied via `supabase db query --linked --file <path>`. Keep this separation if you write a new import script; don't have a Python script talk to Postgres directly (no `psycopg2`/similar is used or installed for this purpose).
- Bulk-import SQL must be **idempotent** (`ON CONFLICT (...) DO UPDATE`) keyed on a real unique constraint added specifically to support re-running the import — see `student_guardians`'s `(student_id, full_name)` unique index.
- Source Excel files live **outside the git repo**, at `D:\Summit\System\docs\` (a sibling of, not inside, `summit/summit/`) — do not assume they're committed or portable; if handed off to a different machine, these paths need updating in the two generator scripts' `DOCS_DIR` constant.

## 10. Documentation Upkeep

- **This `docs/` folder is the AI Development Kit — keep it in sync.** If you add/change a table, function, route, or major design decision, update the relevant file(s) here in the **same session**, not as a follow-up. A stale `DATABASE.md` is worse than none, because the next agent will trust it.
- **Update `CHANGELOG.md`** with a dated entry for any shipped feature (see its format).
- **Update `TASKS.md`** — move a task from `Next`/`Future` to `Completed` when you ship it; add newly-discovered follow-up work to `Next` or `Future` rather than letting it evaporate.
- **Check `NEXT_SESSION.md` at the start of every session** — it names the current milestone, in-flight files, and known blockers. Update it before ending your session so the next agent (human or AI) isn't starting cold.
- **Check `KNOWN_ISSUES.md`** before "fixing" something that might be a documented, deliberate trade-off rather than a bug.
