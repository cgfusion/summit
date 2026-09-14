# STUDENT_PORTAL_AND_VOICE.md — Student Portal & Student Voice (Suara Murid)

This document describes the design, architecture, security model, and implementation of the **Student Portal & Student Voice (Suara Murid)** module in the Dare to Change (D2C) system.

---

## 1. Overview

The **Student Portal** is a student-facing interface accessible at route **`/#/student`** (and `/#/student/:token`). Six tabs, in order:

1. **Pengumuman** — Read Live Announcements (added `20260817000001`): staff-published `school_announcements`, either broadcast to the whole school or targeted at that one student — see §5 below.
2. **Kemajuan Saya** — View Personal Progress: attendance rate %, recorded days present/absent, total merit points earned, and unlocked badges.
3. **Suara Murid** — Submit Student Voice: suggestions for school improvement, learning feedback, anti-bullying & safety reports (with optional anonymity), or request private UBK counseling sessions. Also where a student tracks past submission status and reads official responses from **Guru Kaunselor** and **Guru Disiplin**.
4. **Inspirasi** — a static motivational quote card, plus (added 2026-09-14) a live feed of Sudut Info posts targeted at `audience = murid` — see §6 below. The same feed is **also** shown on the pre-login QR/token entry screen (added 2026-09-14, later same day) so visitors who never log in still see it.
5. **SAFE** — the SAFE anti-bullying questionnaire, added `20260915000001` — see §7 below.
6. **Saringan Minda Sihat** — a gate in front of the Ministry of Education's (KPM) official external mental-health screening, added 2026-09-14 — see §8 below.

The `TabBar` is **not scrollable** (changed 2026-09-14, same day this 6th tab was added): each label wraps onto up to 2 lines via a custom `_wrappingTab()` helper (icon + small `Text` with `maxLines: 2`), so all 6 tabs stay visible on one row at any screen width instead of requiring a horizontal scroll to reach the later ones.

---

## 2. Authentication & Security Model (QR Name Tag)

> [!IMPORTANT]
> **Why IC Entry Was Rejected**:
> To prevent students from impersonating peers using IC numbers, authentication strictly relies on the student's **physical QR Name Tag**.

### Authentication Flow:
1. **Camera QR Scan**: The student taps **"IMBAS KAD QR NAME TAG"** and scans their physical name tag using their phone/tablet/laptop camera.
2. **Token Code Input**: Alternatively, the student can type the 8-character token code printed on their physical name tag.
3. **Database Verification**: The system calls `fn_student_portal_data_by_qr(p_qr_token)` on Supabase, which queries `public.qr_tokens` where `status = 'active'`.

---

## 3. Suara Murid Categories & Anonymity

| Category Code | Malay Label | Description | Anonymity Option |
|---|---|---|---|
| `cadangan_sekolah` | Cadangan Penambahbaikan Sekolah | Ideas to improve school facilities or activities | Yes |
| `maklum_balas_pembelajaran` | Maklum Balas Pembelajaran & Kelas | Feedback on classroom subjects or study environment | Yes |
| `aduan_buli_keselamatan` | Aduan Buli & Keselamatan Murid | Reports regarding cyberbullying, physical bullying, or safety concerns | **Yes (Highly Recommended)** |
| `permohonan_kaunseling` | Permohonan Sesi Kaunseling UBK | Request for a private 1-on-1 counseling session with UBK teacher | Optional |

### Database Table: `public.student_voice_submissions`
- `id` (uuid, primary key)
- `student_id` (uuid references students(id) — set to NULL if `is_anonymous = true`)
- `category` (text)
- `is_anonymous` (boolean)
- `subject` (text)
- `message` (text)
- `status` (text: `'baru'`, `'dalam_tindakan'`, `'selesai'`)
- `response_notes` (text)
- `responded_by` (uuid references profiles(id))
- `created_at` (timestamptz)

---

## 4. Teacher Review Interface (Peti Suara Murid)

In the **Disiplin & Kaunseling** module (`/discipline-counseling`), authorized staff (**Guru Kaunselor**, **Guru Disiplin**, and **Admin**) have a dedicated tab: **Peti Suara Murid**.

- Teachers can read all incoming student submissions.
- For anonymous entries, student name & class are strictly hidden as `SULIT / RAHSIA (ANONYMOUS)`.
- Teachers can update the status (*Dalam Tindakan*, *Selesai*) and type an official response note that the student can view in their portal.

**"Any staff", not role-gated**: as with the rest of the Discipline & Counseling module, this is a UI convention, not an enforced boundary — see `DISCIPLINE_AND_COUNSELING.md` §2.

**Fixed 2026-09-14 (was KI-014)**: the "SULIT / RAHSIA" hiding described above used to be a UI-only convention — the underlying `student_voice_submissions` table granted `select` `to authenticated, anon using (true)`, so anyone holding the project's public anon key could read every submission's full `subject`/`message` text directly via PostgREST, bypassing this screen entirely. That policy has since been replaced with `authenticated`-only `select` (`supabase/migrations/20260914000001_restrict_student_voice_read.sql`), verified live in production. The UI hiding now sits on top of an actual enforced boundary, not instead of one.

## 5. Live Announcements (Tab 1, "Pengumuman")

Added `20260817000001` alongside `school_announcements` (see `DATABASE.md`). `fn_student_portal_data_by_qr` returns an `announcements` array in its response, filtered server-side to `is_published = true` and (`target_student_id is null` — broadcast to everyone — `or target_student_id = <the calling student>`). Each entry carries `category` (`disiplin`/`kaunseling`), `title`, `content`, `author_name`, `target_student_name` (null for broadcasts), and `created_at`. This is a **read-only, live-synced** feed — a staff member publishing a new announcement in the Discipline & Counseling composer appears here on the student's next portal load, no separate subscription/polling mechanism, just a fresh RPC call per visit.

This is distinct from **Sudut Info** (`sudut_info_posts`, see §6 below) — a separate, schedule-windowed content type with optional images and audience targeting. Announcements (this section) have no scheduling window, no image support, and no audience split (student-facing only — there is no parent-facing announcements feed).

## 6. Sudut Info (Tab "Inspirasi")

The "Inspirasi" tab shows a static motivational quote card, followed (if any exist) by a live list of currently-active `sudut_info_posts` where `audience` is `murid` or `kedua_dua` (added 2026-09-14 — see `DISCIPLINE_AND_COUNSELING.md` §6, `DATABASE.md`'s `sudut_info_posts` entry). If there are no active posts targeted at students, only the static quote shows — the tab never looks empty/broken. Each post card shows its category chip, optional image, title, content, and `managed_by` attribution.

**The same audience=`murid` feed is also rendered on `_StudentAuthView`** — the pre-login screen shown before a QR/token is submitted (added 2026-09-14, `_StudentLoginSudutInfoSection` in `student_portal_screen.dart`). Raizal clarified the same day that the QR codes printed on posters point straight at this login screen, so anyone who scans one but never logs in was missing Sudut Info entirely under the Inspirasi-tab-only placement. Both placements coexist — the login screen for walk-up visitors, the tab for logged-in students revisiting it.

**Sudut Info used to be shown on the public Landing Page** (no login required, same content for everyone). It was moved to the Student/Parent Portals specifically, and split by audience, on 2026-09-14 per Raizal — the public Landing Page no longer references Sudut Info at all.

## 7. SAFE Questionnaire (Tab "SAFE")

The **SAFE (School Anti-Bullying Framework for Empowerment)** questionnaire — 12 Likert-scale (1-5) items across 3 fixed sections (Pengetahuan & Kesedaran Antibuli / Amalan Sekolah Penyayang / Peranan PRS), added `20260915000001`. Source instrument: `docs/SOAL_SELIDIK_PENILAIAN_PROGRAM_SCHOOL_ANTIBULLIYING_FRAMEWORK.docx`.

- **First visit / not yet submitted**: shows the full 12-question form (`_SafeQuestionnaireForm`), one Likert row (1-5 buttons) per question, grouped under its section heading. Submitting all 12 calls `fn_submit_safe_questionnaire` via the student's QR token — no separate login step, same identity model as the rest of the portal.
- **Already submitted**: shows a results view instead (`_SafeQuestionnaireResultView`) — total score, percentage, level (Rendah/Sederhana/Tinggi), a "Memahami" (>=75%) verdict, and a per-section score breakdown. A "Kemaskini Jawapan" button re-opens the form pre-filled with the student's previous answers.
- **Resubmission overwrites, it doesn't append**: `safe_questionnaire_responses.student_id` is unique, and the submit RPC does `on conflict (student_id) do update`. There is no history of a student's earlier answers once they update — only the latest submission is ever stored.
- **Scoring**: `percent = total_score / 60 * 100` — **not** `/40`, despite that being the formula written in the source `.docx`. This was confirmed with Raizal as a documentation error in the source material (12 items × 5 points max = 60, not 40); see `DATABASE.md` for the full explanation. Levels come from the percentage (`<50% rendah`, `50-74% sederhana`, `>=75% tinggi`/`memahami`), not from the source's raw-score bands (which don't tile cleanly onto 12 items anyway).
- **Staff view**: aggregated results and an individual-response drill-down live in the Discipline & Counseling module's "Soal Selidik SAFE" tab, not here — see `DISCIPLINE_AND_COUNSELING.md` §8.

## 8. Saringan Minda Sihat (Tab "Saringan Minda Sihat")

A consent gate in front of an **external, third-party** screening — the Ministry of Education's (KPM) official mental-health screening at `https://sepkm.com/msihatmenengah`. Added 2026-09-14, per Raizal's exact spec. This is **not** a D2C feature with its own data model — there is no table, no RPC, and nothing is recorded server-side about whether a student completed it or even opened the link.

- **`_MindaSihatTab`** (`student_portal_screen.dart`, `StatefulWidget`): shows the 3 required instructions (Arahan) verbatim, a "SAYA FAHAM" `CheckboxListTile`, and a "SARINGAN MINDA SIHAT" button.
- **The button is disabled** (`onPressed: null`) until the checkbox is ticked — purely client-side `_understood` bool state, not persisted anywhere. Unchecking it (or leaving and re-entering the tab) resets the gate; there is no "already acknowledged" memory.
- **On press (once enabled)**: opens the external URL via `url_launcher`'s `launchUrl(uri, webOnlyWindowName: '_blank')`, which on Flutter Web calls `window.open(url, '_blank', 'noopener,noreferrer')` — a new tab, not a navigation away from the portal. `url_launcher` was added as a new direct dependency (`pubspec.yaml`) for this; it existed only transitively before.
- **If asked to add tracking/reporting** (e.g. "which students have done the screening"): that is new scope, not implied by the current feature — there is deliberately no student-side record of completion, since KPM's own site presumably tracks that on its end.
