# Disiplin & Kaunseling (SSDOP/SSDM & UBK) Reference Document

> **Status: informational / scoping input.** Tracked as `TASKS.md` T-041, in the Blocked table alongside T-026 — same reason: no existing table models infractions, severity, actions-taken, or counseling sessions, and no existing role maps to `disiplin`/`kaunselor`. This document is reference material for that future scoping conversation, **not** a build ticket or a schema. Explicitly not being implemented yet (Raizal, 2026-08-12) — do not start migrations or UI from this file alone.

## 📌 Overview
This document serves as the operational and technical reference for the **Disiplin & Kaunseling (SSDOP/UBK)** module in the D2C Summit system.

---

## 👥 Roles & Access Control (RBAC)

| Role Code | Role Name | System Access |
|---|---|---|
| `disiplin` | **Guru Disiplin** | Full access to log disciplinary infractions, issue warning letters, assign severity levels, and refer students to UBK. |
| `kaunselor` | **Guru Bimbingan & Kaunseling (UBK)** | Full access to log counseling sessions, record private outcome notes, track session types, and update follow-up statuses. |
| `admin` | **Pentadbir (Pengetua / PK HEM)** | Full administrative access to both Disiplin and Kaunseling modules, reports, and staff role assignments. |

---

## 📋 Disciplinary Infraction Categories (SSDOP)
1. **Ponteng Sekolah / Kelas**: Absence without valid excuse.
2. **Tingkah Laku Kurang Sopan**: Disrespectful behavior towards teachers or peers.
3. **Kekemasan Diri / Pakaian**: Grooming, uniform, or hair infractions.
4. **Buli / Gaduh**: Physical or verbal bullying, fighting.
5. **Vandalism / Harta Benda**: Damage to school property.
6. **Rokok / Vape**: Smoking or vaping on school premises.
7. **Lain-lain**: Miscellaneous infractions.

### Severity Levels
- **Ringan** (Light)
- **Sederhana** (Medium)
- **Berat** (Severe)

### Standard Actions Taken
- Nasihat / Amaran Lisan
- Surat Amaran 1
- Surat Amaran 2
- Surat Amaran 3
- Denda / Khidmat Masyarakat
- Gantung Sekolah
- Rujukan UBK

---

## 🧠 Guidance & Counseling (UBK)

### Session Types
- **Individu**: Individual counseling.
- **Kelompok**: Group counseling.
- **Ibu Bapa**: Joint session with parents/guardians.

### Focus Areas
- **Sahsiah & Disiplin**: Personality & behavioral intervention.
- **Peningkatan Akademik**: Academic guidance & motivation.
- **Bimbingan Kerjaya**: Career guidance & pathways.
- **Psikososial & Kesejahteraan Minda**: Emotional & psychological well-being.

---

## 📁 Storing Reference Documents
Any additional Word documents (`.docx`), PDFs, or official school circulars can be placed in:
`docs/references/`
