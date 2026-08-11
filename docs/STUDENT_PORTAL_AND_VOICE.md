# STUDENT_PORTAL_AND_VOICE.md — Student Portal & Student Voice (Suara Murid)

This document describes the design, architecture, security model, and implementation of the **Student Portal & Student Voice (Suara Murid)** module in the Dare to Change (D2C) system.

---

## 1. Overview

The **Student Portal** is a student-facing interface accessible at route **`/#/student`** (and `/#/student/:token`). It allows students of SMK Sungai Damit to:
1. **View Personal Progress**: Track personal attendance rate %, recorded days present/absent, total merit points earned, and unlocked badges.
2. **Submit Student Voice (Suara Murid)**: Voice suggestions for school improvement, learning feedback, anti-bullying & safety reports (with optional anonymity), or request private UBK counseling sessions.
3. **Track Submission Status**: Follow up on past submissions to read official responses from **Guru Kaunselor** and **Guru Disiplin**.

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
