#!/usr/bin/env python3
import csv
import hashlib
import sys
from pathlib import Path


EXPECTED_HEADER = [
    "group",
    "item",
    "variant",
    "value",
    "unit",
    "notes",
    "provenance",
    "evidence",
]
PROVENANCE = {
    "raw_log_and_ledger",
    "ledger_only_no_raw",
    "ledger_plus_run_metadata",
    "ledger",
}
ORIGINAL_SHA256 = "99f7858910e2148b56ba2319c06f7e1080bd28190140bd9be9d9fdd9f02d5097"


def main() -> int:
    repo = Path(__file__).resolve().parents[1]
    result_path = repo / "results" / "results.tsv"
    original_path = repo / "results" / "results.source-original.tsv"

    original_bytes = original_path.read_bytes()
    if hashlib.sha256(original_bytes).hexdigest() != ORIGINAL_SHA256:
        raise ValueError("historical source-original SHA-256 changed")
    if b"\t" in original_bytes:
        raise ValueError("historical source-original unexpectedly contains tabs")

    with result_path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if reader.fieldnames != EXPECTED_HEADER:
            raise ValueError(f"unexpected header: {reader.fieldnames!r}")

        rows = list(reader)

    if len(rows) != 69:
        raise ValueError(f"expected 69 data rows, got {len(rows)}")

    seen = set()
    for line_number, row in enumerate(rows, start=2):
        if None in row:
            raise ValueError(f"line {line_number}: extra columns")
        required = ("group", "item", "variant", "value", "unit", "provenance", "evidence")
        missing = [name for name in required if not row[name]]
        if missing:
            raise ValueError(f"line {line_number}: empty required fields: {missing}")
        if row["provenance"] not in PROVENANCE:
            raise ValueError(f"line {line_number}: invalid provenance {row['provenance']!r}")

        key = (row["group"], row["item"], row["variant"])
        if key in seen:
            raise ValueError(f"line {line_number}: duplicate key {key!r}")
        seen.add(key)

        if row["item"] != "head_to_head":
            try:
                float(row["value"])
            except ValueError as exc:
                raise ValueError(f"line {line_number}: non-numeric value {row['value']!r}") from exc

        for evidence_item in row["evidence"].split("; "):
            path_text = evidence_item.split(" section", 1)[0].split(" sections", 1)[0]
            if path_text.endswith((".md", ".log", ".tsv")) and not (repo / path_text).is_file():
                raise ValueError(f"line {line_number}: missing evidence file {path_text!r}")

        if row["provenance"] == "raw_log_and_ledger":
            log_path = repo / row["evidence"].split("; ", 1)[0]
            matched = False
            for line in log_path.read_text(encoding="utf-8").splitlines():
                cells = [cell.strip() for cell in line.split("|")]
                if len(cells) >= 4 and cells[-3] == row["item"] and cells[-2].startswith(row["value"] + " ±"):
                    matched = True
                    break
            if not matched:
                raise ValueError(
                    f"line {line_number}: item/value pair not found in raw log: "
                    f"{row['item']}={row['value']}"
                )

    print(f"OK: {result_path.relative_to(repo)} has {len(rows)} valid data rows and 8 columns")
    print(f"OK: historical source-original SHA-256 is {ORIGINAL_SHA256} and it contains no tabs")
    return 0


if __name__ == "__main__":
    sys.exit(main())
