# Consolidated results files

`results.source-original.tsv` is the byte-for-byte historical results artifact. Despite its extension, it contains no tab delimiters and is not a valid TSV. Its SHA-256 is `99f7858910e2148b56ba2319c06f7e1080bd28190140bd9be9d9fdd9f02d5097`.

`results.tsv` is the machine-readable derivation. It has eight tab-delimited columns:

- `group`, `item`, `variant`, `value`, and `unit` describe the observation;
- `notes` retains qualifications such as standard deviation or approximation;
- `provenance` distinguishes raw-backed rows from ledger-only observations;
- `evidence` points to the supporting artifacts already present in this repository.

The `ledger_only_no_raw` provenance is used for Q4 thread scaling, Q4 context scaling, and the earlier active-use Q6 observation because separate raw logs did not survive. Those rows are recorded observations, not reconstructions of absent data.

Validate both files with:

```bash
./scripts/validate-results.py
```
