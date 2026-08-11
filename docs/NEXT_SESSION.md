# NEXT_SESSION.md — Dare to Change (D2C)

> **Read this file first, every session.** It's the only one in `docs/` that goes stale on a timescale of days rather than weeks — update it before you end your session so the next agent isn't starting cold.

## Current Milestone

**All major school modules are 100% shipped, deployed, and verified live on production (`https://d2csummit.online/`).** 

This includes:
1. **Attendance Pipeline & Daily Status Derivation**: QR scan intake, manual entry/backfill, session-aware cutoffs (`pagi`/`petang`).
2. **Merit Module**: 4-point daily merit scoring (`hadir`, `tepat masa`, `kembali rehat`, `kekal sesi`), class leaderboards, recognition awards.
3. **Dashboard & Analytics**: 6 stat cards (`Present: 328 breakdown`), attendance trend, heatmap, worst-5 class toggle, KPI overview.
4. **Discipline & Counseling (SSDOP/UBK)**: Full SSDOP case tracking, UBK counseling sessions, RBAC for `disiplin` (**Guru Disiplin**) & `kaunselor` (**Guru Kaunselor**) staff roles, Peti Suara Murid inbox (`/discipline-counseling`).
5. **Parent Portal**: Unauthenticated MyKad / IC lookup (`/#/parent`) for guardians to view child attendance & merit progress.
6. **Student Portal & Student Voice (Suara Murid)**: Unauthenticated QR Name Tag camera scan / QR token lookup (`/#/student`), personal progress, and confidential anti-bullying / feedback reporting box.
7. **Public Web Landing Page**: High-tech futuristic school landing page (`/#/` and `/#/landing`) showcasing the **Dare to Change (D2C)** project for whole-school **Tingkatan 1–5**, official school motto (*ONE TEAM ONE DREAM, TERUS MARA MENAWAN 7SUMMITs*), 3 Aras Intervensi, and subtle portal launchpad buttons.

## Current Task

**None in flight.** All code, database migrations, and documentation are committed, tested (`21/21` unit & widget tests passing), and deployed.

## Files Recently Modified

- `lib/features/landing/presentation/screens/school_landing_screen.dart` (Public Web Landing Page)
- `lib/features/student_portal/` (Student Portal & Suara Murid entities, repository, providers, screen)
- `lib/features/discipline_counseling/` (SSDOP & UBK records, Peti Suara Murid inbox)
- `lib/core/router/app_router.dart` (Routes for `/`, `/landing`, `/parent`, `/student`, `/discipline-counseling`)
- `supabase/migrations/20260811000002` to `20260811000006` (SQL tables & RPC functions)
- `docs/` (`PROJECT.md`, `CHANGELOG.md`, `STUDENT_PORTAL_AND_VOICE.md`, `LANDING_PAGE.md`, `DISCIPLINE_AND_COUNSELING.md`, `NEXT_SESSION.md`)

## Expected Outcome

A clean `main` branch, deployed and live at `https://d2csummit.online/`, with:
- All features in `CHANGELOG.md` working as described.
- A `docs/` folder kept up to date.

## Known Blockers

None. All database migrations (`20260811000006`) are pushed to Supabase (`uslcbhozuyyfnencttol`).
