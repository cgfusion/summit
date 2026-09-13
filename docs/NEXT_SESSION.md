# NEXT_SESSION.md — Dare to Change (D2C)

> **Read this file first, every session.** It's the only one in `docs/` that goes stale on a timescale of days rather than weeks — update it before you end your session so the next agent isn't starting cold.
>
> **This file was rewritten 2026-09-13** after ~11 commits (2026-08-16 to 2026-08-18) shipped without a matching docs update, and the previous version of this file's "Known Blockers: None" was itself inaccurate (T-025 was, and still is, genuinely unresolved). If you're an agent picking this project back up: **before trusting anything in `docs/` at face value, run `git log --oneline -20` and compare against the dates below** — this project has been edited by multiple concurrent sessions before, more than once, without either one seeing the other's commits, and it produces exactly this kind of staleness.

## Current Milestone

**Every planned feature has shipped and is live at `https://d2csummit.online/`**, including three modules built *after* the last full docs pass: Special Announcements, the Landing Page "Cyber" redesign, the D2C AI Assistant, and Sudut Info.

1. **Attendance Pipeline & Daily Status Derivation**: QR scan intake, manual entry/backfill, session-aware cutoffs (`pagi`/`petang`).
2. **Merit Module**: 4-point daily merit scoring, class leaderboards, recognition awards.
3. **Dashboard & Analytics**: stat cards, attendance trend, heatmap, KPI overview, drill-downs.
4. **Discipline & Counseling**: SSDOP case tracking, UBK counseling sessions, Peti Suara Murid inbox, Special Announcements, Sudut Info — 5 tabs at `/discipline-counseling`. **The `disiplin`/`kaunselor` RBAC this module's own docs describe is a UI convention only, not enforced in Postgres** — see `KNOWN_ISSUES.md` KI-015.
5. **Parent Portal**: token-link (`/parent/:token`) and MyKad/IC lookup (`/parent`) for guardians.
6. **Student Portal & Student Voice**: QR Name Tag login (`/student`), personal progress, live staff announcements (Tab 1), and Suara Murid feedback/bullying reports (with an *intended* anonymity option — see the blocker below, it isn't actually private).
7. **Public Landing Page**: "Cyber" redesign with a real photo hero, a live Sudut Info carousel, and an AI Assistant FAB — see `LANDING_PAGE.md`.
8. **D2C AI Assistant**: chat dialog on the Landing Page. **Branded "GEMINI INTELLIGENCE" but is 100% local rule-based in production** — no API key has ever been wired to it. See `KNOWN_ISSUES.md` KI-016.
9. **D2C User Manual**: `docs/MANUAL_PENGGUNA_D2C.md`/`.docx` — end-user documentation, a different audience from this `docs/` kit.

## Current Task

**None in flight for features.** The open item is the security fix flagged below — surface it to Raizal before starting unrelated work, don't silently fix it mid-way through something else.

## Top Priority — Not a Docs Task, a Real Bug

**`student_voice_submissions` grants the public `anon` role unrestricted `select`** (`using (true)`, no filter). Anyone holding the project's public anon key — trivially extractable from the deployed client — can read every student voice submission, including the `message`/`subject` text of reports marked `is_anonymous = true` (anti-bullying/safety reports). The Student Portal UI promises these are "Sulit / Rahsia," which is currently false. See `KNOWN_ISSUES.md` KI-014 for the fix (drop `anon` from the `select` policy, keep it on `insert`). **Flag this to Raizal before doing anything else in this codebase if you're reading this fresh** — it's more urgent than any feature request.

## Files Recently Modified (as of 2026-08-18, last code commit before this docs pass)

- `lib/features/landing/presentation/screens/school_landing_screen.dart` — full Cyber redesign
- `lib/core/widgets/d2c_ai_assistant_dialog.dart`, `lib/core/services/d2c_ai_assistant_service.dart` — new
- `lib/core/widgets/rich_text_toolbar_widget.dart` — new
- `lib/features/discipline_counseling/` — Sudut Info tab, Special Announcement composer + management list, image upload (screen-level, not repository)
- `lib/features/student_portal/` — Tab 1 "Pengumuman"
- `supabase/migrations/20260817000001` through `20260818000002`
- `docs/` — this docs-catch-up pass (2026-09-13): `DATABASE.md`, `API.md`, `COMPONENTS.md`, `PROJECT.md`, `TASKS.md`, `CHANGELOG.md`, `KNOWN_ISSUES.md`, `DISCIPLINE_AND_COUNSELING.md` (rewritten), `LANDING_PAGE.md` (rewritten), `STUDENT_PORTAL_AND_VOICE.md`, `NEXT_SESSION.md` (this file)

## Expected Outcome

A clean `main` branch, deployed and live at `https://d2csummit.online/`, with:
- Every feature in `CHANGELOG.md` working as described.
- A `docs/` folder kept up to date — **verify this claim yourself with `git log` before trusting it**, given the history above.

## Known Blockers

Three **deliberately blocked** future items (see `TASKS.md` §Blocked), plus the security item above (which is not "blocked," it just needs doing):

- **T-025** (real parent/student login, replacing the token/IC-lookup Parent Portal) — blocked on a product decision: SMS-provider budget for phone OTP, or a parent-email collection step (the SIS export has no email field). Still unresolved as of 2026-08-12's reconfirmation; nothing since has changed this.
- **T-026** (mentor/PRS case-tracking module) — blocked on a scoping conversation; no existing table shape fits.
- **KI-014** (student voice confidentiality) — not "blocked," just not yet done. See above.

## Next Recommended Tasks

In rough priority order:

1. **Fix KI-014** (`student_voice_submissions` anon read) — see `KNOWN_ISSUES.md` for the exact policy change needed.
2. **T-029** — persist `themeModeProvider` selection via `shared_preferences`.
3. **Decide on KI-015** — if `disiplin`/`kaunselor` RBAC is meant to be real, that's a `profiles.role` schema change + new RLS policies, not a small fix; scope it deliberately rather than bolting it on.
4. **Decide on KI-016** — either wire a real Gemini API key through `--dart-define` if genuine LLM answers are wanted, or soften the "GEMINI INTELLIGENCE" branding to match what it actually is.

If the user has a specific new feature request instead, **follow `AI_RULES.md` §5 (the full ship loop) and §8 (design-decision discipline) before writing any code**, and **update this file and `CHANGELOG.md`/`TASKS.md` in the same session you ship in** — the gap this docs pass just closed was caused by exactly the opposite habit.

## Warnings

- **There is no staging environment.** Every `supabase db push` hits production. Read `AI_RULES.md` §0-2 before touching any migration.
- **This repo pushes directly to `main`, no PR workflow.** Established convention, not a shortcut.
- **GitHub Pages caching is aggressive.** Always `curl` the deployed bundle for a unique string before concluding a live-verification failure is real. See `AI_RULES.md` §6.
- **Two attendance-rate denominator conventions coexist deliberately** (fixed-period vs. elapsed-days) — see `KNOWN_ISSUES.md` KI-002.
- **`ReorderableListView` drag handles are unreliable on iPad Safari** — pair any new drag UI with a non-drag fallback from the start.
- **This repo has been edited by concurrent sessions before, more than once, without coordination.** If you're about to write a task ID, a CHANGELOG date, or a "this is not implemented yet" claim, `grep` for it first — see `TASKS.md`'s own correction note for what happens when that doesn't happen.
- **Source Excel files (XEA4402, QR merge) live outside this repo** at `D:\Summit\System\docs\` — real student PII, never commit them.
- **Keep this file current.** Before ending your session: update "Current Task," "Files Recently Modified," and re-check whether any "Next Recommended Tasks" item got done.
