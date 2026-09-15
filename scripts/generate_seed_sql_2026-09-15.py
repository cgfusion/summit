"""One-off migration for the 2026-09-15 XEA4402 refresh + QR card recovery.

Two source files, deliberately NOT cross-trusted for QR tokens:
  - XEA4402 Keseluruhan Murid as of 2026-09-15.xlsx -- whole-school student
    master (614 -> 609 students; also has its own "QR Token" column, but that
    column was found to disagree with the recovery file below on ~half its
    rows -- it was pasted in without reliably matching student identity, so
    it is used here ONLY for student master fields, never for tokens).
  - D:\\Summit\\System\\qr_recovery\\NewQR\\qr_output\\results_named.csv --
    the actual QR-recovery scan output, grouped by class PDF + row number +
    full name + QR code. Zero duplicate names, zero duplicate QR codes,
    structurally clean -- this is the authoritative token source.

Matching results_named.csv -> students is done by exact full_name, with 7
manually-verified spelling-variant fixups (typos between the two sources,
confirmed via fuzzy match + manual review) and one row (MARSELO HARTONO
JUNAIRY, student_id 181201071978) for a student who exists in the new
XEA4402 master but not yet in the `students` table -- the student-upsert
step below creates them before the token insert runs.

Token-conflict handling (confirmed with Raizal 2026-09-15): 224 of the 252
currently-active tokens differ from this authoritative mapping (only 25
already match) -- the current data's original QR_Master_Merge_Result-based
import had the same "matched by row order, not by identity" flaw. This
script:
  - inserts a fresh active token for any student who doesn't have one yet
    (360, including the one brand-new student)
  - REVOKES the existing active token and inserts the new one as active,
    for any student whose authoritative token differs from their current
    one (mirrors the app's own reissue pattern in
    attendance_repository_impl.dart: status='revoked'+revoked_at, then a
    fresh active row -- never delete/overwrite a token row in place)
  - leaves already-matching tokens untouched
  - does NOT touch the 3 existing active tokens whose student_id doesn't
    appear in the new master file at all (per Raizal: no preference
    expressed, defaulting to not inferring a departure from a missing row)

Read-only against both source files; writes review SQL under supabase/seed/.
Does not connect to any database -- review the generated SQL before applying.

Run: python scripts/generate_seed_sql_2026-09-15.py
"""

from __future__ import annotations

import csv
import datetime as dt
from pathlib import Path

import openpyxl

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_DIR = Path(r"D:\Summit\System\docs")
SEED_DIR = REPO_ROOT / "supabase" / "seed"
SEED_DIR.mkdir(parents=True, exist_ok=True)

STUDENT_MASTER_FILE = DOCS_DIR / "XEA4402 Keseluruhan Murid as of 2026-09-15.xlsx"
QR_RECOVERY_FILE = Path(r"D:\Summit\System\qr_recovery\NewQR\qr_output\results_named.csv")

TINGKATAN_WORD_TO_NUM = {
    "SATU": 1,
    "DUA": 2,
    "TIGA": 3,
    "EMPAT": 4,
    "LIMA": 5,
    "ENAM": 6,
}

# recovery-file name -> correct master-file name, for the 7 confirmed typos
# (e.g. JIPIN/JAIPIN, ADAAM/AADAM) between the scan-recovery transcription
# and the SIS master export. Manually verified via fuzzy match + class
# cross-reference -- see the session notes / CHANGELOG entry for this date.
NAME_FIXUPS = {
    "ASHWAL ZULSHAFY BIN JIPIN": "ASHWAL ZULSHAFY BIN JAIPIN",
    "MOHAMMAD AADAM ISKANDAR ALFIAN BIN ABDULLAH": "MOHD ADAAM ISKANDAR ALFIYAN BIN ABDULLAH",
    "FATIMAH AIRA BINTI ADBULLAH": "FATIMAH AIRA BINTI ABDULLAH",
    "DANI DANELIA SINPA": "DANI DANELLA SINPA",
    "MELVIORYNA SERENA KANAM": "MELVIORYNA SERENA KANAM @ MANUEL",
    "SHERRY TAN BOBBY": "SHERRY",
    "MOHAMAD SHAFIAN BIN JIPIN": "MOHAMAD SHAFIAN BIN JAIPIN",
}


def parse_tingkatan(value: str) -> int:
    word = value.strip().upper().removeprefix("TINGKATAN").strip()
    if word not in TINGKATAN_WORD_TO_NUM:
        raise ValueError(f"Unrecognised TAHUN/TINGKATAN value: {value!r}")
    return TINGKATAN_WORD_TO_NUM[word]


def parse_ddmmyyyy(value) -> "dt.date | None":
    if value in (None, ""):
        return None
    if isinstance(value, dt.datetime):
        return value.date()
    if isinstance(value, dt.date):
        return value
    return dt.datetime.strptime(str(value).strip(), "%d-%m-%Y").date()


def sql_str(value) -> str:
    if value is None:
        return "NULL"
    return "'" + str(value).replace("'", "''") + "'"


def sql_date(value: "dt.date | None") -> str:
    if value is None:
        return "NULL"
    return f"'{value.isoformat()}'"


def sql_int(value) -> str:
    if value is None:
        return "NULL"
    return str(int(value))


def load_students():
    wb = openpyxl.load_workbook(STUDENT_MASTER_FILE, data_only=True, read_only=True)
    ws = wb["Worksheet"]

    classes: dict[str, dict] = {}
    students: list[dict] = []
    by_name: dict[str, dict] = {}

    for row in ws.iter_rows(min_row=7, values_only=True):
        student_id = row[1]
        if student_id is None:
            continue

        class_name = row[10]
        tingkatan = row[9]
        guru_kelas = row[15]

        if class_name not in classes:
            classes[class_name] = {
                "form_level": parse_tingkatan(tingkatan),
                "homeroom_teacher_name": guru_kelas or None,
            }

        s = {
            "student_id": int(student_id),
            "full_name": row[2],
            "ic_number": str(row[3]) if row[3] is not None else None,
            "ic_type": row[4],
            "date_of_birth": parse_ddmmyyyy(row[5]),
            "study_status": row[6],
            "enrolled_at": parse_ddmmyyyy(row[7]),
            "class_joined_at": parse_ddmmyyyy(row[8]),
            "gender": row[16],
            "class_name": class_name,
        }
        students.append(s)
        by_name[str(row[2]).strip().upper()] = s

    wb.close()
    return classes, students, by_name


def load_qr_recovery(by_name: dict[str, dict]):
    tokens: list[dict] = []
    with QR_RECOVERY_FILE.open(encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for r in reader:
            name = r["Full Name"].strip().upper()
            token = r["QR Code"].strip()
            lookup_name = NAME_FIXUPS.get(name, name)
            master = by_name.get(lookup_name)
            if master is None:
                raise ValueError(f"Unresolved recovery-file name: {name!r} (class file {r['File']})")
            tokens.append({"student_id": master["student_id"], "full_name": master["full_name"], "token": token})
    return tokens


def main():
    classes, students, by_name = load_students()
    qr_tokens = load_qr_recovery(by_name)

    out_path = SEED_DIR / "seed_data_2026-09-15.sql"
    with out_path.open("w", encoding="utf-8") as f:
        f.write("-- Generated by scripts/generate_seed_sql_2026-09-15.py -- do not hand-edit, regenerate instead.\n")
        f.write(f"-- Sources: {STUDENT_MASTER_FILE.name} (student master), {QR_RECOVERY_FILE} (QR tokens)\n")
        f.write(f"-- Students: {len(students)}, Classes: {len(classes)}, QR tokens (authoritative, name-matched): {len(qr_tokens)}\n\n")

        f.write("begin;\n\n")

        f.write("-- classes\n")
        for name, c in sorted(classes.items()):
            f.write(
                "insert into public.classes (name, form_level, homeroom_teacher_name) values "
                f"({sql_str(name)}, {c['form_level']}, {sql_str(c['homeroom_teacher_name'])}) "
                "on conflict (name) do update set form_level = excluded.form_level, "
                "homeroom_teacher_name = excluded.homeroom_teacher_name;\n"
            )

        f.write("\n-- students\n")
        for s in students:
            f.write(
                "insert into public.students "
                "(student_id, full_name, ic_number, ic_type, date_of_birth, gender, study_status, "
                "enrolled_at, class_joined_at, class_id) values ("
                f"{sql_int(s['student_id'])}, {sql_str(s['full_name'])}, {sql_str(s['ic_number'])}, "
                f"{sql_str(s['ic_type'])}, {sql_date(s['date_of_birth'])}, {sql_str(s['gender'])}, "
                f"{sql_str(s['study_status'])}, {sql_date(s['enrolled_at'])}, {sql_date(s['class_joined_at'])}, "
                f"(select id from public.classes where name = {sql_str(s['class_name'])})"
                ") on conflict (student_id) do update set "
                "full_name = excluded.full_name, ic_number = excluded.ic_number, ic_type = excluded.ic_type, "
                "date_of_birth = excluded.date_of_birth, gender = excluded.gender, "
                "study_status = excluded.study_status, enrolled_at = excluded.enrolled_at, "
                "class_joined_at = excluded.class_joined_at, class_id = excluded.class_id;\n"
            )

        f.write(
            "\n-- qr_tokens: two-phase fix, from the name-matched QR recovery file (NOT the\n"
            "-- XEA4402 file's own QR Token column, which disagrees with this on ~half its\n"
            "-- rows). The cards themselves were never reissued -- most of the 224 changes\n"
            "-- below are the SAME physical token values already in the table, just correctly\n"
            "-- re-linked to the student each card actually belongs to (the original import\n"
            "-- matched two spreadsheets by row order, not identity, and scrambled ~224 of\n"
            "-- them). Because so many of these are pairwise/cyclic swaps of tokens that\n"
            "-- already exist in the table (not fresh values), a plain revoke-then-insert\n"
            "-- fails on the `token` unique constraint (a revoked row still holds its token\n"
            "-- text). So:\n"
            "--   Phase 1: revoke each student's current active row IF their authoritative\n"
            "--     token differs from it -- this only frees their own 'one active token per\n"
            "--     student' slot, it does not touch the token text itself.\n"
            "--   Phase 2: upsert on the `token` unique constraint -- if that exact token text\n"
            "--     already has a row (however it's currently linked), repoint it to the\n"
            "--     correct student and reactivate it; otherwise insert it fresh. Phase 1\n"
            "--     having already run for every affected student guarantees phase 2 never\n"
            "--     creates two simultaneous active rows for the same student.\n"
            "-- Students not present in this file at all are never referenced below, so their\n"
            "-- existing tokens are untouched.\n"
        )
        f.write("\n-- phase 1: revoke each changed student's current (wrong) active token\n")
        for t in qr_tokens:
            sid = sql_int(t["student_id"])
            tok = sql_str(t["token"])
            f.write(
                "update public.qr_tokens set status = 'revoked', revoked_at = now() "
                f"where student_id = (select id from public.students where student_id = {sid}) "
                f"and status = 'active' and token <> {tok};\n"
            )
        f.write("\n-- phase 2: upsert each authoritative token onto the correct student\n")
        for t in qr_tokens:
            sid = sql_int(t["student_id"])
            tok = sql_str(t["token"])
            f.write(
                "insert into public.qr_tokens (student_id, token, status) values "
                f"((select id from public.students where student_id = {sid}), {tok}, 'active') "
                "on conflict (token) do update set "
                "student_id = excluded.student_id, status = 'active', revoked_at = null;\n"
            )

        f.write("\ncommit;\n")

    print(f"Classes: {len(classes)}")
    print(f"Students: {len(students)}")
    print(f"QR tokens (authoritative): {len(qr_tokens)}")
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
