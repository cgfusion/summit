# DISCIPLINE_AND_COUNSELING.md — Disiplin & Kaunseling (SSDOP/UBK) Module

> **Rewritten 2026-09-13.** The previous version of this file carried a banner claiming this module was "informational / scoping input... explicitly not being implemented yet." **That was wrong even at the time it was written** — the module had already shipped in full on 2026-08-10 (`56358ae`), before that banner was added on 2026-08-12, due to two sessions editing this repo concurrently without either one seeing the other's commits. This file now documents what is actually live in production at `/discipline-counseling`.

Related: `TASKS.md` T-039 (module), T-041 (Peti Suara Murid), T-043/T-047/T-048 (Special Announcements, management list, Sudut Info); `DATABASE.md` (`discipline_records`, `counseling_records`, `school_announcements`, `sudut_info_posts`); `STUDENT_PORTAL_AND_VOICE.md` (the student-facing side of Peti Suara Murid and Pengumuman); `KNOWN_ISSUES.md` KI-014/KI-015/KI-017.

---

## 1. Overview

`DisciplineCounselingScreen` (`features/discipline_counseling/presentation/screens/discipline_counseling_screen.dart`), route `/discipline-counseling`, reachable from the sidebar by any signed-in staff member. Five tabs:

| Tab | Purpose |
|---|---|
| **Kes Disiplin (SSDOP)** | Log/browse disciplinary infractions (`discipline_records`) |
| **Sesi Kaunseling (UBK)** | Log/browse counseling sessions (`counseling_records`) |
| **Peti Suara Murid** | Read & respond to student submissions from the Student Portal (`student_voice_submissions`) |
| **Sudut Info** | Author scheduled informational posts shown on the public Landing Page and Student Portal (`sudut_info_posts`) |
| **Ringkasan & Analisis** | Summary/analytics view over the above |

The tab also hosts the **Special Announcement** composers (one per category, "disiplin"/"kaunseling") that write to `school_announcements` and appear live in the Student Portal's "Pengumuman" tab, plus a management list to view/edit/unpublish/delete past announcements.

## 2. Roles & Access Control — documented intent vs. what's actually enforced

The original scoping intent (still the UI's mental model) was three roles:

| Role Code | Role Name | Intended Access |
|---|---|---|
| `disiplin` | **Guru Disiplin** | Log disciplinary infractions, issue warnings, assign severity, refer to UBK |
| `kaunselor` | **Guru Bimbingan & Kaunseling (UBK)** | Log counseling sessions, private outcome notes, session types, follow-up status |
| `admin` | **Pentadbir (Pengetua / PK HEM)** | Full access to both, plus reports and staff role assignment |

**As actually shipped, none of this is enforced at the database level.** `profiles.role` only has three values (`admin`/`teacher`/`staff` — see `DATABASE.md`), and every RLS policy on `discipline_records`, `counseling_records`, `school_announcements`, and `sudut_info_posts` is `to authenticated using (true)` — **any signed-in staff member can read/write any of these**, not just a `disiplin`/`kaunselor`-equivalent account. The route itself also has no role gate (consistent with the rest of the app — role differentiation elsewhere happens via RLS, not route guards, and here it doesn't happen at all). See `KNOWN_ISSUES.md` KI-015. Treat the RBAC table above as **intended UI convention**, not an enforced boundary — if a scoping conversation about this module comes up, this gap is worth surfacing.

## 3. Kes Disiplin (SSDOP)

Backed by `discipline_records` (see `DATABASE.md` for full column list). Fields are free text (no DB `check` constraints — validation, where it exists, is UI-only):

- **Categories** (UI-offered): Ponteng Sekolah/Kelas, Tingkah Laku Kurang Sopan, Kekemasan Diri/Pakaian, Buli/Gaduh, Vandalism/Harta Benda, Rokok/Vape, Lain-lain.
- **Severity**: Ringan / Sederhana / Berat.
- **Action Taken**: Nasihat/Amaran Lisan, Surat Amaran 1/2/3, Denda/Khidmat Masyarakat, Gantung Sekolah, Rujukan UBK. **The string `'Surat Amaran%'` is pattern-matched by `fn_student_discipline_summary` to compute the Student Detail sheet's "active warning" badge** — don't rename this convention without updating that function.
- **Status**: dalam_siasatan / dirujuk_ubk / selesai.
- A discipline record can be the origin of a `counseling_records` row via "Rujukan UBK" (`counseling_records.discipline_record_id`).

## 4. Sesi Kaunseling (UBK)

Backed by `counseling_records`. Session types: Individu / Kelompok / Ibu Bapa. Focus areas: Sahsiah & Disiplin / Peningkatan Akademik / Bimbingan Kerjaya / Psikososial & Kesejahteraan Minda. `outcome_notes` is a free-text private note field — readable by any staff member per §2 above, not restricted to counselors.

## 5. Peti Suara Murid (Teacher Inbox)

The staff-side view of student submissions made via the Student Portal's Suara Murid tab (`student_voice_submissions` — see `STUDENT_PORTAL_AND_VOICE.md` for the student-facing flow and categories). Staff here can:
- Read all submissions, with anonymous ones showing `SULIT / RAHSIA (ANONYMOUS)` in place of the student's name/class in the UI.
- Update `status` (baru → dalam_tindakan → selesai) and write `response_notes`, visible back to the student in their own portal.

**Important**: the anonymity shown in this UI is a *display* convention only. The underlying table is directly readable by anyone with the public anon key regardless of this screen — see `KNOWN_ISSUES.md` KI-014, the highest-priority open issue in this project as of this writing.

## 6. Sudut Info

Scheduled informational posts, backed by `sudut_info_posts`. Authored here, displayed on:
- The public Landing Page's hero-section Sudut Info card (a manual-advance carousel — see `LANDING_PAGE.md` §4).
- The Student Portal (via `fn_active_sudut_info_posts()`).

Fields: `category` (disiplin/kaunseling/sahsiah/sekolah/umum), `title`, `content` (rich HTML authored via `RichTextToolbarWidget` — see `COMPONENTS.md`), optional `image_url` (uploaded to the `sudut-info-banners` Storage bucket via `file_picker`, or a manually-entered URL — see `DATABASE.md` Storage Buckets), `managed_by` (display attribution text), and a **scheduling window** (`valid_from`/`valid_until`) — a post only appears publicly once `valid_from` has passed and before `valid_until` (or indefinitely if `valid_until` is null). `is_published` is a separate draft/live toggle on top of the schedule.

Management: full CRUD plus an unpublish toggle, all in the Sudut Info tab. Image upload/delete for this feature is called directly from the screen against Supabase Storage, bypassing the repository layer — see `KNOWN_ISSUES.md` KI-017.

## 7. Special Announcements

Backed by `school_announcements` (category `disiplin` or `kaunseling`), authored via a composer in this screen and optionally scoped to one student (`target_student_id`) or broadcast to everyone (`null`). Appears live in the Student Portal's "Pengumuman" tab (Tab 1) via `fn_student_portal_data_by_qr`'s `announcements` field, filtered to `is_published = true` and (broadcast or targeted at the calling student). A management list in this screen lets staff view/edit/unpublish/delete past announcements. This superseded the earlier ad hoc "copy WhatsApp text" composer built for the PIBG reports feature (`TASKS.md` T-037) — that feature is unrelated and still exists separately in Reports.

## 8. Ringkasan & Analisis

A summary/analytics tab over the discipline and counseling data — not documented in further detail here; read the tab's build method directly if you need its exact contents, as it's presentation-only (no new backend surface beyond what's already covered above).
