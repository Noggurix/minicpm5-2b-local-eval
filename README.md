# MiniCPM5-2B Local Evaluation

A local evaluation of OpenBMB MiniCPM5-2B with `llama.cpp` on CPU-only
hardware, covering quantization throughput, thread and context scaling,
qualitative quantization comparisons, and an exploratory reasoning ON/OFF
ablation.

The study was run on an Intel Core i3-6006U (2 cores / 4 threads, AVX2) with
approximately 20 GB of DDR4 memory.

## At a glance

| Item | Value |
|---|---|
| Model | OpenBMB MiniCPM5-2B |
| Runtime | `llama.cpp` b10883 |
| Hardware | Intel Core i3-6006U, 2C/4T |
| Main thread count | 2 |
| Fast local profile | Q4_K_M + reasoning OFF |
| Quality-oriented local profile | Q8_0 + reasoning OFF |
| Q4_K_M generation throughput | ~9.08 tok/s |
| Q8_0 generation throughput | ~6.04 tok/s |

The throughput figures above are `llama-bench` tg128 measurements from the
clean unattended run. They do not measure reasoning ON/OFF speed or
end-to-end request latency.

## Key findings

- **Official Q4_K_M had the highest generation throughput in the clean
  unattended battery.** It reached approximately 19.79 tok/s for pp512 and
  9.08 tok/s for tg128 on the tested system. IQ4_XS had the highest pp512
  prompt-processing throughput in that battery.

- **Q8_0 became the quality-oriented local preference.** In the nine-case
  Q4/Q6/Q8 comparison, Q8 had a mean rank of 1.67 and no last-place finishes.
  These were relative qualitative rankings, not correctness scores.

- **Q6_K did not justify its cost as the default on this hardware.** It showed
  some favorable scheduling results, but its aggregate quality/performance
  trade-off was weaker for the intended local use.

- **Reasoning OFF received higher relative ranks in the small exploratory ablation.**
  OFF was preferred to ON by 3–1 within both Q4 and Q8 across four prompts.
  The sample is too small and the extraction procedure too uneven to support
  a general claim that reasoning OFF improves quality.

- **The model repeatedly accepted a fabricated Python feature premise.**
  The tested `quantumcache` / PEP 8124 prompt produced invented APIs and
  semantics instead of rejection of the false premise. This is a task-specific
  failure, not a general hallucination-rate estimate.

- **The tested technical pt-BR task was inconsistent.** Some seeds were
  acceptable, while others showed mixed languages, corrupted words, unnatural
  grammar, or incorrect concurrency explanations.

The complete measurements, rankings, interpretation, and caveats are in
[`RESULTS.md`](RESULTS.md).

## What was evaluated

The campaign included:

- quantization throughput across Q3_K_M, Q4_K_M, IQ4_XS, Q5_K_M, Q6_K,
  and Q8_0;
- Q4_K_M thread scaling from 1 to 4 threads;
- context-scaling measurements;
- an initial Q4_K_M vs Q8_0 quality comparison;
- a protocol-corrected rerun of incomplete cases;
- a blinded Q4_K_M vs Q6_K vs Q8_0 qualitative comparison;
- an exploratory Q4/Q8 reasoning ON/OFF ablation;
- custom tasks covering structured output, arithmetic, scheduling, coding,
  false-premise resistance, pt-BR technical explanation, architecture, and
  prompt injection.

This is a small custom local evaluation, not a standardized academic benchmark
suite.

## Repository structure

| Path | Contents |
|---|---|
| [`RESULTS.md`](RESULTS.md) | Consolidated measurements, rankings, interpretation, and limitations |
| [`docs/RUNS.md`](docs/RUNS.md) | Index of the major quality campaigns |
| [`docs/QUALITATIVE_AUDIT.md`](docs/QUALITATIVE_AUDIT.md) | Ranking rubric, extraction asymmetries, and post-reveal annotations |
| [`docs/REPRODUCIBILITY.md`](docs/REPRODUCIBILITY.md) | Reproducibility scope, missing execution state, and rerun guidance |
| `experiments/throughput/` | Throughput summary and preserved benchmark logs |
| `experiments/initial-q4-q8/` | Initial Q4/Q8 comparison |
| `experiments/q4-q8-rerun/` | Protocol-corrected rerun |
| `experiments/q4-q6-q8-blind/` | Three-way blinded quantization campaign |
| `experiments/reasoning-ablation/` | Reasoning ON/OFF campaign and recovery artifacts |
| `prompts/` | Original evaluation prompts |
| `results/` | Machine-readable consolidated results |
| `scripts/historical/` | Campaign harnesses used for the later runs |
| `environment/` | Benchmark-relevant system and build information |

## Reproducibility

The repository supports three different levels of reconstruction.

**Audit and reconstruction.** Preserved prompts, outputs, mappings, recorded
orders, benchmark logs, consolidated results, and integrity hashes can be
inspected and cross-checked.

**Partial execution reproduction.** The later campaign harnesses and seeds
survive, but exact GGUF hashes, fully resolved runtime state, some RNG state,
and other execution details were not recorded well enough for byte-identical
replay.

**Ledger-only observations.** Separate raw logs did not survive for Q4 thread
scaling, Q4 context scaling, or the earlier active-use Q6 measurement. Those
values remain recorded observations in the consolidated study records.

See [`docs/REPRODUCIBILITY.md`](docs/REPRODUCIBILITY.md) for the complete gap
list and a minimal rerun path.

## Methodological limitations

- one physical test machine;
- one low-power Skylake-class CPU;
- small qualitative sample sizes;
- temperature 1.0 for the quality comparisons;
- custom tasks rather than a standardized benchmark suite;
- qualitative relative rankings without numeric rubric weights;
- incomplete outputs in parts of the initial Q4/Q8 campaign;
- an identity leak in the initial blind comparison;
- non-uniform answer extraction in the reasoning ablation;
- incomplete preservation of some runtime and benchmark state.

The reasoning-ablation extraction issue is documented in detail in
[`docs/QUALITATIVE_AUDIT.md`](docs/QUALITATIVE_AUDIT.md) and
[`experiments/reasoning-ablation/20260912-044934/RECOVERY.md`](experiments/reasoning-ablation/20260912-044934/RECOVERY.md).

## Running the preserved harnesses

The recorded environment used:

- `llama.cpp` tag `b10883`;
- commit `91f6a6cf361385700bbe15981f0f39909df77498`;
- CPU-only Release build;
- `GGML_NATIVE=ON`;
- 2 runtime threads for the main comparisons.

Models, binaries, build trees, and caches are not included.

Set `MINICPM5_BENCH_ROOT` to a separate working directory before adapting one
of the campaign scripts. The preserved scripts represent the executed
protocols rather than a polished benchmark framework.

## Integrity

`MANIFEST.sha256` covers every study file except the manifest itself and Git
metadata.

Verify it from the repository root with:

```bash
sha256sum -c MANIFEST.sha256
```

Machine-readable consolidated results can also be validated with:

```bash
./scripts/validate-results.py
```

## License

Original material authored for this repository is licensed under Apache-2.0 to
the extent the repository authors are entitled to license it.

See [`LICENSE`](LICENSE) and [`docs/LICENSING.md`](docs/LICENSING.md) for the
license text and scope.
