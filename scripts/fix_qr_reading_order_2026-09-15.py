"""Correction #2 for the 2026-09-15 QR token migration.

Raizal scanned a real physical card (ADDY AERAYYAN ARASSH BIN ANNUAR's) and
it resolved to a different student (JANE SHERLYN JOHNSON) -- proof the
"authoritative" `results_named.csv` recovery file used in
generate_seed_sql_2026-09-15.py was ALSO wrong, not just the XEA4402 file's
own QR Token column.

Root cause, confirmed by direct pixel-level inspection: results_named.csv
was built by decoding each class page's QR codes with a library (pyzbar)
that returns detections in whatever order its internal algorithm finds
them -- NOT top-to-bottom/left-to-right reading order -- and then zipping
that raw decode order directly against the class's alphabetically-sorted
name list. On every 3x3-grid page this produces the *exact reverse* of the
correct top-to-bottom, left-to-right pairing (verified precisely: the true
reading order for "1 CITRA" page 1 is
[jbJGQ0d,72od2K8,8vzHYEW,2TZPL1u,oZp6Ftm,oRWdHeq,Rm4ikD6,ThGsnAR,vnJDnJ7],
and results_named.csv lists that exact sequence reversed). This explains
the observed real-world mismatch exactly: ADDY's real card encodes
jbJGQ0d..., which results_named.csv had filed under JANE SHERLYN JOHNSON.

Fix: decode every PNG in D:\\Summit\\System\\qr_recovery\\NewQR\\qr_output
directly (pyzbar), cluster detections into rows by y-proximity, sort each
row left-to-right, concatenate a class's pages in page-number order to
get the TRUE reading order, and pair that -- position for position --
against results_named.csv's existing (File, No., Full Name) sequence for
that class. Only the QR Code column is replaced; names/ordering are kept
as-is since that bug was isolated to the QR/name pairing, not the roster
transcription itself. All 21 classes / 609 rows resolved with a 1:1 count
match and zero duplicate tokens (see this script's own printed output).

This does NOT touch classes/students -- only qr_tokens, using the same
name-matching (with the same 7 spelling fixups + 1 new-student case) and
the same two-phase revoke-then-upsert-on-token approach as
generate_seed_sql_2026-09-15.py, for the same reason (most "wrong" tokens
are swaps of values already in the table).

Read-only against source files; writes review SQL under supabase/seed/.
Does not connect to any database -- review the generated SQL before applying.

Run: python scripts/fix_qr_reading_order_2026-09-15.py
"""

from __future__ import annotations

import csv
import os
from collections import defaultdict
from pathlib import Path

from PIL import Image
from pyzbar.pyzbar import decode as zbar_decode

REPO_ROOT = Path(__file__).resolve().parent.parent
SEED_DIR = REPO_ROOT / "supabase" / "seed"
SEED_DIR.mkdir(parents=True, exist_ok=True)

QR_RECOVERY_FILE = Path(r"D:\Summit\System\qr_recovery\NewQR\qr_output\results_named.csv")
PNG_DIR = Path(r"D:\Summit\System\qr_recovery\NewQR\qr_output")

# Live database roster, dumped read-only via `supabase db query --linked`
# immediately before running this script (see the session notes / CHANGELOG
# for the exact query). Re-dump before re-running if the roster has changed.
ROSTER_DUMP = REPO_ROOT / "scripts" / "_current_roster.json"

# Same 7 confirmed spelling-variant fixups as generate_seed_sql_2026-09-15.py.
NAME_FIXUPS = {
    "ASHWAL ZULSHAFY BIN JIPIN": "ASHWAL ZULSHAFY BIN JAIPIN",
    "MOHAMMAD AADAM ISKANDAR ALFIAN BIN ABDULLAH": "MOHD ADAAM ISKANDAR ALFIYAN BIN ABDULLAH",
    "FATIMAH AIRA BINTI ADBULLAH": "FATIMAH AIRA BINTI ABDULLAH",
    "DANI DANELIA SINPA": "DANI DANELLA SINPA",
    "MELVIORYNA SERENA KANAM": "MELVIORYNA SERENA KANAM @ MANUEL",
    "SHERRY TAN BOBBY": "SHERRY",
    "MOHAMAD SHAFIAN BIN JIPIN": "MOHAMAD SHAFIAN BIN JAIPIN",
}
NEW_STUDENT_IDS = {
    "MARSELO HARTONO JUNAIRY": 181201071978,
}

ROW_CLUSTER_TOLERANCE_PX = 50


def sql_str(value) -> str:
    return "'" + str(value).replace("'", "''") + "'"


def true_reading_order(png_path: Path) -> list[str]:
    img = Image.open(png_path)
    dets = zbar_decode(img)
    items = [(d.rect.top, d.rect.left, d.data.decode()) for d in dets]
    items.sort(key=lambda x: x[0])
    clusters: list[list[tuple[int, int, str]]] = []
    for top, left, val in items:
        for cluster in clusters:
            if abs(cluster[0][0] - top) < ROW_CLUSTER_TOLERANCE_PX:
                cluster.append((top, left, val))
                break
        else:
            clusters.append([(top, left, val)])
    clusters.sort(key=lambda c: c[0][0])
    ordered: list[str] = []
    for cluster in clusters:
        cluster.sort(key=lambda x: x[1])
        ordered.extend(v for _, _, v in cluster)
    return ordered


def build_corrected_mapping() -> list[dict]:
    with QR_RECOVERY_FILE.open(encoding="utf-8-sig") as f:
        rows = list(csv.DictReader(f))

    by_file: dict[str, list[dict]] = defaultdict(list)
    for r in rows:
        by_file[r["File"]].append(r)

    corrected: list[dict] = []
    for class_file, names in by_file.items():
        base = class_file.replace(".pdf", "")
        page = 1
        full_order: list[str] = []
        while True:
            p = PNG_DIR / f"{base}_page{page}.png"
            if not p.exists():
                break
            full_order.extend(true_reading_order(p))
            page += 1

        if len(full_order) != len(names):
            raise ValueError(
                f"{class_file}: found {len(full_order)} QR codes across pages but "
                f"{len(names)} names -- needs manual review, not auto-corrected."
            )

        for n, tok in zip(names, full_order):
            corrected.append({"full_name": n["Full Name"].strip(), "token": tok})

    tokens = [c["token"] for c in corrected]
    if len(set(tokens)) != len(tokens):
        raise ValueError("Duplicate tokens in corrected mapping -- aborting, needs manual review.")

    return corrected


def load_roster() -> dict[str, dict]:
    import json

    with ROSTER_DUMP.open(encoding="utf-8") as f:
        lines = f.readlines()
    data = json.loads("".join(lines[1:]))  # first line is CLI's "Initialising login role..."
    return {r["full_name"].strip().upper(): r for r in data["rows"]}


def main():
    corrected = build_corrected_mapping()
    print(f"Corrected mapping: {len(corrected)} rows, {len({c['token'] for c in corrected})} unique tokens")

    by_name = load_roster()

    resolved: list[dict] = []
    for c in corrected:
        name = c["full_name"].strip().upper()
        if name in NEW_STUDENT_IDS:
            resolved.append({"student_id": NEW_STUDENT_IDS[name], "token": c["token"]})
            continue
        lookup_name = NAME_FIXUPS.get(name, name)
        roster_row = by_name.get(lookup_name)
        if roster_row is None:
            raise ValueError(f"Unresolved name: {name!r} -- needs a NAME_FIXUPS entry or roster refresh.")
        resolved.append({"student_id": roster_row["student_id"], "token": c["token"]})

    out_path = SEED_DIR / "fix_qr_reading_order_2026-09-15.sql"
    with out_path.open("w", encoding="utf-8") as f:
        f.write("-- Generated by scripts/fix_qr_reading_order_2026-09-15.py -- do not hand-edit, regenerate instead.\n")
        f.write("-- Corrects the qr_tokens migration applied earlier the same day (supabase/seed/seed_data_2026-09-15.sql),\n")
        f.write("-- which used results_named.csv's QR-Code-to-name pairing as-is; that pairing was reversed per page\n")
        f.write("-- (pyzbar decode order != visual reading order). See this script's own docstring for the full story.\n\n")
        f.write(f"-- Corrected rows: {len(resolved)}\n\n")
        f.write("begin;\n\n")
        f.write("-- phase 1: revoke each student's current (still-wrong) active token\n")
        for r in resolved:
            sid = r["student_id"]
            tok = sql_str(r["token"])
            f.write(
                "update public.qr_tokens set status = 'revoked', revoked_at = now() "
                f"where student_id = (select id from public.students where student_id = {sid}) "
                f"and status = 'active' and token <> {tok};\n"
            )
        f.write("\n-- phase 2: upsert each corrected token onto the correct student\n")
        for r in resolved:
            sid = r["student_id"]
            tok = sql_str(r["token"])
            f.write(
                "insert into public.qr_tokens (student_id, token, status) values "
                f"((select id from public.students where student_id = {sid}), {tok}, 'active') "
                "on conflict (token) do update set "
                "student_id = excluded.student_id, status = 'active', revoked_at = null;\n"
            )
        f.write("\ncommit;\n")

    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
