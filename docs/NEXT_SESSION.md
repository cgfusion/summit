# NEXT_SESSION.md — Dare to Change (D2C)

> **Read this file first, every session.** It's the only one in `docs/` that goes stale on a timescale of days rather than weeks — update it before you end your session so the next agent isn't starting cold.

## Current Milestone

**All planned features through the Recommended Next Steps (T-027, T-028, T-030, T-031, T-032) are shipped, deployed, and verified.** This includes: attendance pipeline, merit scoring, dashboard analytics, reports, settings, student enrollment status, parent/guardian contact management, unauthenticated Parent Portal, WhatsApp PIBG report generator, Parent Portal access logging & rate limiting, primary guardian partial unique index, absence cron SQL helper, shared `dateOnly` utilities, and automated unit test suite.

## Current Task

**None in flight.** All 5 recommended next steps are completed and verified with zero static analysis issues and clean unit test suite execution.

## Files Currently Being Edited

None.

## Expected Outcome

A clean `main` branch, deployed and live at `https://d2csummit.online/`, with:
- Every feature in `CHANGELOG.md` working as described.
- A `docs/` folder kept up to date.

## Known Blockers

None for shipped work. Two **deliberately blocked** future items exist (see `TASKS.md` §Blocked):
- **T-025** (real parent/student login) — blocked on a product decision (SMS provider budget vs. email-collection step).
- **T-026** (mentor/PRS case-tracking module) — blocked on a scoping conversation; no existing table shape fits this need.

## Next Recommended Tasks

In rough priority order:

1. **T-029 — Persist themeModeProvider selection**: Use `shared_preferences` to preserve theme preference across page reloads.
2. **T-033 — Offline Cache Audit**: Decide whether to keep or remove the unused `isar` dependency in `pubspec.yaml`.
3. **T-035 — File Upload / Storage Bucket**: Scoping if student photo or document attachments are requested.

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
