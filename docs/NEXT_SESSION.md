# NEXT_SESSION.md — Dare to Change (D2C)

> **Read this file first, every session.** It's the only one in `docs/` that goes stale on a timescale of days rather than weeks — update it before you end your session so the next agent isn't starting cold.

## Current Milestone

**All planned features through the Parent Portal are shipped, deployed, and live-verified.** This includes: attendance pipeline, merit scoring, dashboard analytics (with user-customizable, drag-or-button reorderable layout), reports, settings, student enrollment status, parent/guardian contact management (with a real bulk-imported dataset — 1078 guardians across 598 students), and an unauthenticated Parent Portal.

The **AI Development Kit** (`docs/PROJECT.md` through this file) was just written in this session as a deliberate handoff artifact — it did not exist before this session.

## Current Task

**Finishing and committing the AI Development Kit.** By the time you're reading this, that should be done — check `git log -1` and `git status`. If `docs/PROJECT.md` through `docs/NEXT_SESSION.md` (12 files) exist and are committed, this task is complete and **there is no other in-flight work**. If `git status` shows the `docs/` folder as untracked/uncommitted, finish that first (see "Warnings" below — this repo auto-pushes to `main` with no PR review, per established project convention, but only after `flutter analyze`/`flutter test` pass for any *code* change; documentation-only commits don't need that gate).

## Files Currently Being Edited

None, if the above check passes. If you're resuming mid-documentation-write, the 12 files are:
`docs/PROJECT.md`, `docs/ARCHITECTURE.md`, `docs/DATABASE.md`, `docs/API.md`, `docs/COMPONENTS.md`, `docs/UI_GUIDELINES.md`, `docs/CODING_STANDARDS.md`, `docs/AI_RULES.md`, `docs/TASKS.md`, `docs/CHANGELOG.md`, `docs/KNOWN_ISSUES.md`, `docs/NEXT_SESSION.md` (this file).

## Expected Outcome

A clean `main` branch, deployed and live at `https://cgfusion.github.io/summit/`, with:
- Every feature in `CHANGELOG.md` working as described (last live-verified 2026-08-11 for the Parent Portal — the newest feature).
- A `docs/` folder any new agent (or the project's actual human collaborator) can read in ~5 minutes to become fully productive without re-deriving context from git history or conversation logs.

## Known Blockers

None for shipped work. Two **deliberately blocked** future items exist (see `TASKS.md` §Blocked):
- **T-025** (real parent/student login) — blocked on a product decision (SMS provider budget vs. email-collection step). Do not start this without the user explicitly choosing a direction.
- **T-026** (mentor/PRS case-tracking module) — blocked on a scoping conversation; no existing table shape fits this need.

## Next 5 Recommended Tasks

In rough priority order (see `TASKS.md` for the full backlog with dependencies/complexity):

1. **T-030 — Parent Portal hardening** (rate limit or access log). The highest-risk accepted trade-off currently live in production (see `KNOWN_ISSUES.md` KI-001). Worth raising with the user proactively even if not asked, given it's genuinely public-internet-reachable.
2. **T-027 — Absence cron**. `attendance_days.source = 'system_cron'` is fully modeled in the schema (the scan trigger's `ON CONFLICT` clause already assumes it exists) but nothing populates it — a student who never scans and is never manually marked simply has *no row* for that day, silently absent from every period-summary denominator. This is a real, currently-live data-quality gap, not just a nice-to-have.
3. **T-032 — Test coverage for the two highest-risk areas** (enrollment-status ripple, attendance scan pipeline). These are the two places a silent regression would be most consequential and least likely to be caught by manual click-through testing.
4. **T-028 — Extract shared `dateOnly()` helper**. Small, safe, good "warm-up" task to build familiarity with the codebase's repository-impl files.
5. **T-031 — Enforce one-primary-guardian-per-student**. Small, matches an existing pattern (`qr_tokens`' partial unique index) exactly — low-risk, good second task.

If the user has a specific new feature request instead, **follow `AI_RULES.md` §5 (the full ship loop) and §8 (design-decision discipline) before writing any code** — several of this project's best decisions came from asking a clarifying question before building (see `PROJECT.md` §7 for the pattern: Dashboard reorder interaction, enrollment-status ripple scope, Parent Portal auth method were all clarified via structured questions first).

## Warnings

- **There is no staging environment.** Every `supabase db push` hits production. Read `AI_RULES.md` §0-2 before touching any migration.
- **This repo pushes directly to `main`, no PR workflow, no review gate beyond `flutter analyze`/`flutter test` passing.** This is an established, confirmed convention for this specific repo (not a shortcut being taken) — do not propose introducing a PR workflow unless explicitly asked.
- **GitHub Pages caching is aggressive and will make a working deploy look broken.** Always `curl` the deployed bundle for a unique string from your change before concluding a live-verification failure is a real bug. See `AI_RULES.md` §6.
- **Two attendance-rate denominator conventions coexist deliberately** (fixed-period vs. elapsed-days) — see `KNOWN_ISSUES.md` KI-002. Do not "fix" this without understanding both `PROJECT.md` §7 #3 and the migration header comments in `20260806000001_attendance_period_summary.sql` first.
- **`ReorderableListView` drag handles are unreliable on iPad Safari.** If you build any new drag-and-drop UI, pair it with an explicit non-drag interaction (buttons) from the start — don't rediscover this the hard way (see `KNOWN_ISSUES.md` KI-011, `COMPONENTS.md`).
- **The Parent Portal RPC (`fn_parent_portal_data`) is the one function in the schema reachable without authentication.** Treat adding a second `anon`-reachable function as a security-review-worthy decision, not a routine one — see `AI_RULES.md` §7.
- **Source Excel files (XEA4402 export, QR merge result) live outside this git repo** at `D:\Summit\System\docs\` — if this project moves to a different machine, the two generator scripts' `DOCS_DIR` constant needs updating, and the source files themselves need to be transferred separately (they are not committed, and should not be — they contain real student PII).
- **Keep this file current.** Before ending your session: update "Current Task," "Files Currently Being Edited," and re-check whether any of the "Next 5" items got done and should be replaced.
