# Reproducibility scope

This is a reproducible evaluation record with partially reproducible execution. Preserved artifacts support audit and partial reruns, but they do not support a claim of byte-identical or fully controlled reproduction.

## A. Auditable and reconstructible

The following can be inspected and cross-checked from this repository:

- prompts and recorded seeds;
- raw, blind, and recovered outputs where preserved;
- final mappings, case order, and review order;
- the campaign harnesses used for the later runs;
- preserved per-case `llama-bench` logs for the clean unattended quantization run and Q6 context run;
- the benchmark environment summary and consolidated throughput summary;
- the campaign ledger, derived TSV with per-row provenance, and repository manifest.

The historical rankings can be reconstructed from the ledger and mappings. Their claimed frozen-before-reveal timing is narrative campaign provenance, not independently timestamped or cryptographically verifiable evidence.

## B. Partially reproducible execution

The later Q4/Q8 rerun, three-way campaign, reasoning ablation, and throughput harness survive as scripts. A new run can follow the same broad commands, prompts, model identifiers, seeds, and nominal parameters, subject to the gaps below. New outputs, random candidate labels, UUIDs, and timings should not be expected to match byte-for-byte.

## C. Ledger-only observations

No separate raw logs survived for:

- Q4 thread scaling;
- Q4 context scaling;
- the earlier active-use Q6 measurement.

Their consolidated numbers remain recorded observations in `RESULTS.md` and are labeled `ledger_only_no_raw` in `results/results.tsv`. They cannot be independently reconstructed from raw measurements in this repository.

## Unrecorded or unavailable execution state

- Immutable hashes/revisions of the exact GGUF files were not recorded.
- The fully resolved chat template and runtime settings were not captured.
- The initial quality harness and commands for the ledger-only series are not available.
- The cache/download procedure required before using `--offline` was not documented.
- Individual throughput repetitions were not retained; only the aggregate rows in the logs are available.
- Complete power, CPU-frequency, background-load, and thermal control was not recorded. CPU temperature was manually observed reaching roughly 55 °C under sustained 100% utilization, with no observed value above that. This was not continuously logged or synchronized with individual benchmark runs. The observations showed no evident sign of throttling, but they do not establish causality or constitute formal thermal control.
- `shuf` and UUID generation had no recorded RNG seed. Historical final orders and IDs survive, but reruns will generate different ones.
- Complete generation stop reasons and token counts were not preserved for every quality output.

`environment/README.md` records the benchmark-relevant system and build configuration. `experiments/throughput/20260911-072256/SUMMARY.md` consolidates aggregate measurements supported by the eight individual throughput logs. Per-repetition measurements are unavailable.

## Artifact integrity checks

- `MANIFEST.sha256` covers every study file except itself and Git metadata; run `./scripts/verify-manifest.sh` from the repository root to verify it.
- `./scripts/validate-results.py` checks the schema and 69 data rows in `results/results.tsv`, validates referenced evidence, and verifies the preserved malformed results artifact by SHA-256.
- The three-way and reasoning-ablation `mapping.sha256` files verify their corresponding `mapping.tsv` files. Their `cases_order.tsv` and `review_order.txt` files permit completeness and permutation checks against the case and blind-output sets.
- The recorded three-way and reasoning-ablation aggregate ranks are arithmetically consistent with the ranking lists and revealed mappings.
- `experiments/reasoning-ablation/20260912-044934/RECOVERY.md` records the exact raw line spans and SHA-256 digests used to verify the post hoc C/D recovery files.

## Minimal path for later harnesses

Use a separate working directory; do not point a rerun at the preserved evidence tree.

1. Check out `llama.cpp` commit `91f6a6cf361385700bbe15981f0f39909df77498` under `<WORK_ROOT>/llama.cpp` and build CPU Release with `GGML_NATIVE=ON`.
2. Arrange the included prompts at `<WORK_ROOT>/quality/20260911-143133/prompts`, for example with a symlink to this repository's `prompts/` directory.
3. Populate a compatible local Hugging Face/`llama.cpp` cache for the model identifiers used by the script. The historical procedure is unknown; the scripts use `--offline` and will fail if the required files are not already available.
4. Set `MINICPM5_BENCH_ROOT=<WORK_ROOT>`.
5. Run or adapt one of `scripts/historical/rerun-quality-invalid.sh`, `run-quality-3way.sh`, `run-reasoning-ablation.sh`, or `run-bench-suite.fish` from this repository.
6. Treat the resulting run as a new replication. Record exact GGUF hashes, resolved runtime/chat-template settings, RNG seeds, stop reasons, individual repetitions, and system-load controls if stronger reproducibility is required.

This path reproduces the surviving protocol shape; it does not promise identical inference text, ordering, or performance measurements.
