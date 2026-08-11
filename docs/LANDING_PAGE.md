# LANDING_PAGE.md — SMK Sungai Damit & D2C Project Landing Page

This document describes the design, layout, content structure, and technical implementation of the public web landing page for **SMK Sungai Damit, Tamparuli, Sabah**.

---

## 1. Overview & Route Configuration

- **Primary Route**: **`/#/`** and **`/#/landing`**
- **Screen Widget**: `SchoolLandingScreen` (`lib/features/landing/presentation/screens/school_landing_screen.dart`)
- **Access Level**: Public (unauthenticated by design, no login required to view).

---

## 2. Design Aesthetics & Visual Identity

The landing page features a **futuristic, high-tech digital school aesthetic**:
- **Color Palette**: Deep space navy (`#0F172A`, `#0B132B`), cosmic violet (`#1E1B4B`), cyan tech accents (`#38BDF8`), and amber gold (`#FDE047`).
- **Glassmorphism**: Translucent floating header with `BackdropFilter` backdrop blur.
- **Micro-Animations & Glow Effects**: Pulsing live system status dot (`🟢 TAMPARULI • D2C SYSTEM ONLINE`), glowing gradient hero headline, and interactive card elevation.

---

## 3. Official Content Integration (Ref: `KK D2C.docx`)

All textual content directly aligns with the founding document `KK D2C.docx` stored in `docs/references/KK_D2C.docx`:

### Core Branding:
- **School**: SEKOLAH MENENGAH KEBANGSAAN SUNGAI DAMIT, TAMPARULI, SABAH
- **School Motto**: *"ONE TEAM ONE DREAM, TERUS MARA MENAWAN 7SUMMITs"*
- **Program Name**: **PROGRAM KEHADIRAN DARE TO CHANGE (D2C)**
- **Theme**: *"Hadir Hari Ini, Menang Esok Hari"*
- **Tagline**: *"Saya Hadir, Saya Kekal, Saya Berjaya!"*
- **Scope**: Seluruh Warga Sekolah — Tingkatan 1, 2, 3, 4 & 5.

### 5 Main Page Sections:
1. **Hero Spotlight**: High-impact D2C banner, motto pill, and system quick triggers.
2. **Mengenai D2C & High-Tech Metrics**: Program narrative and 4 key metric counters (Whole School T1-T5, 100% Digital Scan, 4 Daily Merit Points, 3 Intervention Levels).
3. **3 Aras Intervensi Grid**:
   - *Aras 1 (Universal)*: Universal daily tracking, 4 merit points, class challenges.
   - *Aras 2 (Bersasar)*: Targeted UBK/PRS mentor check-ins & 5-day return plan.
   - *Aras 3 (Intensif)*: Intensive home visits (Ziarah Cakna) & principal meetings.
4. **Daily Merit Routine**: Step 01 to Step 04 breakdown (+1 point per routine).
5. **Jawatankuasa Induk**: Principal (Pn. Fauziah Binti Mahrop), PK HEM, PK Pentadbiran, PK Kokum, PK Petang, and Setiausaha UBK.

---

## 4. Portal Access Launchpad ("Not Too Apparent")

Subtle portal entry shortcuts are accessible via:
1. **Header Dropdown**: Tapping **`PORTAL AKSES ▾`** in the top navigation bar.
2. **Bottom Portal Launchpad Section**:
   - 🔐 **Portal Guru / Pentadbir**: Links to `/#/sign-in`
   - 👨‍👩‍👧‍👦 **Portal Ibu Bapa**: Links to `/#/parent`
   - 🎓 **Portal Murid**: Links to `/#/student`
