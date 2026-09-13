# STUDENT_PORTAL_AND_VOICE.md — Student Portal & Student Voice (Suara Murid)

This document describes the design, architecture, security model, and implementation of the **Student Portal & Student Voice (Suara Murid)** module in the Dare to Change (D2C) system.

---

## 1. Overview

The **Student Portal** is a student-facing interface accessible at route **`/#/student`** (and `/#/student/:token`). It allows students of SMK Sungai Damit to:
1. **View Personal Progress**: Track personal attendance rate %, recorded days present/absent, total merit points earned, and unlocked badges.
2. **Read Live Announcements** (Tab 1, "Pengumuman", added `20260817000001`): staff-published `school_announcements` from the Discipline & Counseling module, either broadcast to the whole school or targeted at that one student — see §5 below.
3. **Submit Student Voice (Suara Murid)**: Voice suggestions for school improvement, learning feedback, anti-bullying & safety reports (with optional anonymity), or request private UBK counseling sessions.
4. **Track Submission Status**: Follow up on past submissions to read official responses from **Guru Kaunselor** and **Guru Disiplin**.

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

**Confidentiality gap (KI-014, see `KNOWN_ISSUES.md`)**: the "SULIT / RAHSIA" hiding described above happens only in this screen's UI. The underlying `student_voice_submissions` table grants `select` `to authenticated, anon using (true)` — anyone holding the project's public anon key can read every submission's full `subject`/`message` text directly via PostgREST, bypassing this screen entirely. Treat this as the highest-priority open issue in the codebase, not a documentation nuance.

## 5. Live Announcements (Tab 1, "Pengumuman")

Added `20260817000001` alongside `school_announcements` (see `DATABASE.md`). `fn_student_portal_data_by_qr` returns an `announcements` array in its response, filtered server-side to `is_published = true` and (`target_student_id is null` — broadcast to everyone — `or target_student_id = <the calling student>`). Each entry carries `category` (`disiplin`/`kaunseling`), `title`, `content`, `author_name`, `target_student_name` (null for broadcasts), and `created_at`. This is a **read-only, live-synced** feed — a staff member publishing a new announcement in the Discipline & Counseling composer appears here on the student's next portal load, no separate subscription/polling mechanism, just a fresh RPC call per visit.

This is distinct from **Sudut Info** (`sudut_info_posts`), which is a separate, schedule-windowed content type shown on both this portal and the public Landing Page — see `DISCIPLINE_AND_COUNSELING.md` §6 and `LANDING_PAGE.md` §4. Announcements (this section) have no scheduling window and no image support; Sudut Info has both.
