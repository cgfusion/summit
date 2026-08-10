# ATTENDANCE.md — Dare to Change (D2C)

> **Status: informational.** This document captures the current attendance model, how it relates to MOEIS / legacy school systems, and future options (export API, assembly QR). It is **not** a build ticket. Do not implement the future sections unless Raizal explicitly asks.

Related code: `app/lib/features/attendance/`, RPCs in `API.md` §Attendance, pipeline notes in `PROJECT.md` §7 #1 and `DATABASE.md`.

---

## 1. What D2C attendance is today

D2C attendance does **not** pull live data from MOEIS, idMe, or the school's older online attendance system.

Current sources of truth inside D2C:

| Path | How it works | Canonical write |
|---|---|---|
| **QR scan** | Staff phone/camera scans student QR pass → `attendance_logs` insert → trigger derives `attendance_days` | Scan pipeline |
| **Manual entry** | Staff marks a student (or a class roster) via Manual Attendance UI → `fn_manual_attendance_set` | Manual RPC |

Both land in `attendance_days` (one row per student per school day). Merit and reports read from that derived state.

---

## 2. Exception-based manual capture (current operational model)

For **class / bulk manual entry**, D2C uses an **exception-based** model:

- Every student on the roster defaults to **Hadir (Present)**.
- The teacher only changes students who are exceptions, for example:
  - `tidak_hadir` — Absent
  - `cuti_sakit` — Medical leave
  - `urusan_rasmi` — Official duty
  - other approved non-present statuses as supported by `AttendanceStatus`
- Example: 500 students, 12 exceptions entered → remaining 488 stay Hadir.

This is intentional. It is much faster than marking every student Present/Absent one-by-one, and it is currently the practical data-entry workflow for D2C alongside QR scanning.

**UI note:** `ManualAttendanceScreen` bulk mode already initializes each roster row to `AttendanceStatus.hadir` and reports how many were left Hadir vs marked otherwise.

### Why this is not redundant with MOEIS

MOEIS may already have attendance features. That does **not** make D2C attendance redundant today:

- D2C solves a **school-side capture and workflow** problem (fast exception entry + QR + merit/discipline program).
- Until an official KPM-authorized integration exists, D2C remains the operational attendance store for this program.

---

## 3. Current product decision (as of 2026-08-11)

**For now, D2C remains the fast exception-based capture system.**

That means:

- Keep default-Hadir manual/bulk entry as the primary non-scan workflow.
- Do **not** rip out manual attendance because MOEIS exists.
- Do **not** switch the default product mode to “Absent until scanned at assembly” yet.
- QR scan remains available and valuable; it is not being removed.
- External sync (MOEIS/idMe) stays future work.

---

## 4. Relationship to other systems

### MOEIS / idMe

- **Today:** no authorized API pull into D2C; no push from D2C to MOEIS/idMe.
- **Future possibility A — `MOEIS → D2C`:** if KPM provides an official data-sharing mechanism, D2C could import authoritative attendance and reduce manual entry.
- **Future possibility B — `D2C → external`:** D2C can expose a stable export/API so authorized partners (idMe/MOEIS/other school systems) can consume finalized attendance later.

Do not assume ministry systems will call a D2C API without a formal agreement. Build readiness; do not bet the product on one direction only.

### Older school attendance system

- Exists online as a **separate legacy** system.
- Not treated as D2C’s authoritative source.
- Not known (from current product knowledge) to be connected to MOEIS or idMe for D2C’s purposes.
- Keep wording cautious: “not known to be connected,” not “proven disconnected,” unless verified.

### Authority wording

Until an official integration exists:

- D2C attendance is the **operational** source for the D2C / Dare to Change program.
- It is **not automatically** the KPM/legal attendance record unless school/KPM policy says so.

---

## 5. Future option — assembly / entrance QR as main school attendance

### Observed school practice (external / legacy pattern)

The existing school attendance practice uses **phone camera** scanning:

- **Sidang pagi:** roughly **06:00–07:30**
- **Sidang petang:** same method during afternoon assembly time

This is assembly-window phone scanning, not necessarily a permanent turnstile gate.

### Fit with D2C

D2C already has working QR scan (`/attendance/scan`, `mobile_scanner`, QR pass registration). That is a strong technical foundation, but **assembly-as-main-attendance is a different capture mode** from today’s exception-based classroom entry:

| Mode | Default | Teacher action |
|---|---|---|
| **Classroom exception (current)** | Present / Hadir | Enter exceptions only |
| **Assembly QR (future)** | Absent / unmarked until scanned | Scan during window; exceptions (MC, urusan rasmi) override |

**Do not mix these defaults in one session.** If assembly mode is built later, keep it as an explicit session type (e.g. `SIDANG_PAGI` / `SIDANG_PETANG`) with its own window and finalize rules.

### Still needed before calling assembly mode “ready”

Informational checklist only — not current work:

- Timed session open/close for pagi/petang windows
- Finalize unscanned students as `tidak_hadir` (while preserving pre-entered leave exceptions)
- Optional late rules after window end
- Offline / peak-load behavior for morning rush
- Anti-replay / QR pass hygiene if used as school-wide authoritative capture

---

## 6. Future option — Attendance Export API (info draft)

Goal: keep exception-based capture now, but design so D2C can later **provide** attendance to external systems.

### Design rules

1. Export **resolved** attendance (`attendance_days`), not raw UI exception state.
2. Include how the status was set (`source`: scan / manual / system_cron / future import).
3. Version from day one (`/v1/...`) if a public/partner HTTP surface is ever added.
4. Private/partner only — never anonymous public access to student attendance lists.
5. Prefer finalized/complete school days for partner consumers.

### Suggested domain statuses (map from D2C)

| D2C / DB | Export-oriented code |
|---|---|
| `hadir` | `PRESENT` |
| `lewat` | `LATE` |
| `tidak_hadir` | `ABSENT` |
| `cuti_sakit` | `CUTI_SAKIT` |
| `urusan_rasmi` | `URUSAN_RASMI` |

### Suggested endpoints (not implemented)

```http
GET /v1/attendance?school_date=YYYY-MM-DD&class_id=...
GET /v1/attendance/exceptions?school_date=YYYY-MM-DD
GET /v1/students/{student_id}/attendance?from=...&to=...
GET /v1/exports/attendance?from=...&to=...&format=json
```

Today the real “API” remains Supabase PostgREST + RPCs (`API.md`). Any partner HTTP façade would be a **new** surface on top of `attendance_days`, not a replacement for the Flutter app’s current calls.

### Example resolved row shape (draft)

```json
{
  "student_id": "STD10021",
  "school_date": "2026-08-11",
  "status": "ABSENT",
  "source": "EXCEPTION_ENTRY",
  "first_scan_at": null,
  "external_ids": {
    "idme": null,
    "moeis": null,
    "school_local": null
  }
}
```

Reserve `external_ids` even if null today so partner onboarding does not break the schema later.

### Security notes for any future partner API

- AuthN/AuthZ with school/role scoping
- Audit logging of partner reads
- Rate limits
- No PII in URLs/logs beyond necessity
- Explicit onboarding — not a public open API

---

## 7. Summary for agents

| Topic | Current stance |
|---|---|
| Source of attendance data | D2C QR scan + manual/exception entry |
| Pull from MOEIS / legacy | No |
| Manual bulk default | Hadir; enter exceptions only |
| Product focus now | Keep exception-based capture |
| Assembly QR as main school attendance | Future option; QR tech exists; mode rules not built |
| Export API for idMe/MOEIS | Future option; draft shape above only |
| Treat D2C attendance as redundant | No |

If asked to implement assembly mode or an export API, re-read this file, confirm scope with Raizal, then follow `AI_RULES.md` ship loop — do not silently change the default-Hadir classroom model.
