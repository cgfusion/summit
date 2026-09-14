# LANDING_PAGE.md — SMK Sungai Damit & D2C Project Landing Page

This document describes the design, layout, content structure, and technical implementation of the public web landing page for **SMK Sungai Damit, Tamparuli, Sabah**.

> **Rewritten 2026-09-13** to match the actual shipped "Cyber" redesign (`e9cddef` "redesign to match reference mockup UI 100% exactly", `ebbbe06` real photo hero). The previous version of this file described an earlier iteration whose classes have all since been replaced (`_Tech*` → `_Cyber*`); it also predated the AI Assistant and Sudut Info features entirely.

---

## 1. Overview & Route Configuration

- **Primary Route**: `/#/` and `/#/landing`
- **Screen Widget**: `SchoolLandingScreen` (`lib/features/landing/presentation/screens/school_landing_screen.dart`) — a `StatefulWidget` (not `Consumer`; the state class holds `GlobalKey`s per section for scroll-to-section nav and hosts a floating action button).
- **Access Level**: Public, unauthenticated by design — exempted from the router's auth redirect alongside `/parent*` and `/student*` (see `app_router.dart`).

## 2. Page Structure (top to bottom)

| # | Section | Widget | Notes |
|---|---|---|---|
| — | Floating navbar | `_FloatingGlassHeader` | `Positioned` over everything, `BackdropFilter` glass blur. Nav text links (`Jadual Timeline`, `Mengenai D2C`, `3 Aras Intervensi`, `Sistem Merit`, `Jawatankuasa`) only render above 960px width; below that only the `PORTAL AKSES ▾` dropdown shows |
| 1 | Hero Spotlight | `_CyberHeroSpotlight` (`StatelessWidget`) | Real photo background, single-column layout: badge + headline/CTAs only. **No longer has a Sudut Info card** — removed 2026-09-14, see §4 |
| 2 | Timeline Program | `_CyberTimelineSection` | "Jadual Pelaksanaan D2C 2026" — same 3-stop launch/ongoing/close structure as before |
| 3 | Overview & Metrics | `_CyberOverviewSection` / `_CyberMetricCard` | Program narrative + 4 metric cards (Tingkatan, Digital %, Merit points, Aras count) |
| 4 | 3 Aras Intervensi | `_CyberLevelsSection` / `_CyberLevelCard` | Universal / Bersasar / Intensif |
| 5 | Merit Routine | `_CyberMeritSection` / `_CyberMeritTile` | 4-step daily merit routine |
| 6 | Leadership | `_CyberLeadershipSection` / `_CyberLeaderTile` | Jawatankuasa Induk |
| 7 | Portal Launchpad | `_CyberPortalLaunchpadSection` / `_CyberLaunchpadCard` | Guru/Pentadbir, Ibu Bapa, Murid |
| — | Footer | `_CyberFooter` | |
| — | **AI Assistant FAB** | `FloatingActionButton.extended` on the `Scaffold`, always visible | "PEMBANTU AI" — opens `D2CAiAssistantDialog.show(context)` (see `COMPONENTS.md`, `KNOWN_ISSUES.md` KI-016) |

## 3. Design Aesthetics & Visual Identity

- **Color Palette**: unchanged from the original design — deep space navy (`#0F172A`/`#090D16`/background `#060913` dark / `#0B1222` light), cosmic violet (`#1E1B4B`), cyan tech accent (`#38BDF8`), amber gold (`#FDE047`).
- **Hero background**: `AssetImage('assets/images/school_front.jpg')` (a real photo of the school building), rendered at `opacity: 0.28` behind the hero content — **new since the original build**, which used a pure gradient with no photo.
- **Glassmorphism**: floating header (`BackdropFilter`, `sigmaX/Y: 14`) unchanged in spirit from the original.
- **AI Assistant FAB**: cyan (`#38BDF8`) `FloatingActionButton.extended`, black text/icon, always docked bottom-right regardless of scroll position.

## 4. Sudut Info — removed from this page (2026-09-14)

This page **used to** have a live Sudut Info carousel card in the hero's right column (a two-column layout, `_CyberHeroSpotlight` as a `ConsumerStatefulWidget` watching `activeSudutInfoPostsProvider`, with an `_activeInfoIndex`-driven prev/next carousel and a "Lihat Semua Makluman" button). Per Raizal (2026-09-14): Sudut Info is meant for students/parents specifically, not the general public, so it was removed from this page entirely and the hero reverted to a single-column `StatelessWidget` with no Riverpod dependency.

Sudut Info now lives exclusively in the Student Portal and Parent Portal — each shows only the posts targeted at its own audience (`murid` / `ibu_bapa` / `kedua_dua`), on **both** the pre-login screen and the post-login view. See `STUDENT_PORTAL_AND_VOICE.md` §6 and `DISCIPLINE_AND_COUNSELING.md` §6 for the current implementation. **Every other line in this file describing this page as static branding copy is still accurate** — removing Sudut Info means the Landing Page now has *zero* live data-driven elements.

## 5. Official Content Integration (Ref: `KK D2C.docx`)

Unchanged from the original build — all textual branding content aligns with the founding document `KK D2C.docx`:

- **School**: SEKOLAH MENENGAH KEBANGSAAN SUNGAI DAMIT, TAMPARULI, SABAH
- **School Motto**: *"ONE TEAM ONE DREAM, TERUS MARA MENAWAN 7SUMMITs"*
- **Program Name**: **PROGRAM KEHADIRAN DARE TO CHANGE (D2C)**
- **Theme**: *"Hadir Hari Ini, Menang Esok Hari"*
- **Tagline**: *"Saya Hadir, Saya Kekal, Saya Berjaya!"*
- **Scope**: Seluruh Warga Sekolah — Tingkatan 1, 2, 3, 4 & 5.
- **Jawatankuasa Induk**: Pn. Fauziah Binti Mahrop (Pengerusi/Pengetua), plus 4 Naib Pengerusi and a Setiausaha — see the Leadership section for full names/titles, unchanged from the original list.

## 6. Portal Access Launchpad

Two entry points, same as before:
1. **Header Dropdown** (`PORTAL AKSES ▾`): Portal Guru & Pentadbir (`/#/sign-in`), Portal Ibu Bapa (`/#/parent`), Portal Murid (`/#/student`).
2. **Bottom Portal Launchpad Section**: the same three destinations as full cards with a description line each.

## 7. What changed from the original ("`_Tech*`") build

For anyone diffing against an old memory of this file or an old commit: the entire widget tree was renamed `_Tech*` → `_Cyber*` and substantially reworked in `e9cddef`/`ebbbe06`/`4e2d717`/`be53e36` (2026-08-16 to 2026-08-17). Net changes: real photo hero background, the hero split into a two-column layout with a live Sudut Info card replacing what used to be static content, the AI Assistant FAB added, and nav items reordered to lead with "Jadual Timeline". The underlying page structure (7 sections + footer) and all branding copy are otherwise the same in spirit.
