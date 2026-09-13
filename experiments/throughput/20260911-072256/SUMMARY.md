# Consolidated throughput summary

This summary consolidates the throughput campaign. The eight individual `llama-bench` logs in this directory are the measurement evidence for the aggregate values below.

## Benchmark configuration

- Backend: CPU
- Runtime threads: 2
- `llama.cpp` build: `91f6a6c` (tag `b10883`; full commit `91f6a6cf361385700bbe15981f0f39909df77498`)
- Main quantization cases: `-p 512 -n 128 -t 2 -r 7 --delay 2`
- Q6 context case: `-p 2048,4096 -n 128 -t 2 -r 5 --delay 2`
- Run condition recorded by the campaign: clean unattended run, with the competing Ollama runtime stopped

Only aggregate means and standard deviations survive in the individual logs; per-repetition measurements were not preserved.

## Execution order and aggregate results

| Order | Case | Source | Quantization | Model size | Test | Mean ± SD (tok/s) | Evidence |
|---:|---|---|---|---:|---|---:|---|
| 1 | `official-Q4_K_M` | OpenBMB | Q4_K_M | 1.45 GiB | pp512 | 19.79 ± 0.41 | `official-Q4_K_M.log` |
| 1 | `official-Q4_K_M` | OpenBMB | Q4_K_M | 1.45 GiB | tg128 | 9.08 ± 0.02 | `official-Q4_K_M.log` |
| 2 | `bartowski-Q4_K_M` | Bartowski | Q4_K_M | 1.50 GiB | pp512 | 18.85 ± 0.04 | `bartowski-Q4_K_M.log` |
| 2 | `bartowski-Q4_K_M` | Bartowski | Q4_K_M | 1.50 GiB | tg128 | 8.67 ± 0.06 | `bartowski-Q4_K_M.log` |
| 3 | `bartowski-IQ4_XS` | Bartowski | IQ4_XS | 1.36 GiB | pp512 | 21.83 ± 0.04 | `bartowski-IQ4_XS.log` |
| 3 | `bartowski-IQ4_XS` | Bartowski | IQ4_XS | 1.36 GiB | tg128 | 6.98 ± 0.02 | `bartowski-IQ4_XS.log` |
| 4 | `bartowski-Q5_K_M` | Bartowski | Q5_K_M | 1.78 GiB | pp512 | 10.06 ± 0.01 | `bartowski-Q5_K_M.log` |
| 4 | `bartowski-Q5_K_M` | Bartowski | Q5_K_M | 1.78 GiB | tg128 | 6.49 ± 0.07 | `bartowski-Q5_K_M.log` |
| 5 | `bartowski-Q6_K` | Bartowski | Q6_K | 1.96 GiB | pp512 | 12.81 ± 0.03 | `bartowski-Q6_K.log` |
| 5 | `bartowski-Q6_K` | Bartowski | Q6_K | 1.96 GiB | tg128 | 7.20 ± 0.01 | `bartowski-Q6_K.log` |
| 6 | `bartowski-Q3_K_M` | Bartowski | Q3_K_M | 1.15 GiB | pp512 | 11.49 ± 0.04 | `bartowski-Q3_K_M.log` |
| 6 | `bartowski-Q3_K_M` | Bartowski | Q3_K_M | 1.15 GiB | tg128 | 8.26 ± 0.01 | `bartowski-Q3_K_M.log` |
| 7 | `official-Q8_0` | OpenBMB | Q8_0 | 2.49 GiB | pp512 | 15.67 ± 0.20 | `official-Q8_0.log` |
| 7 | `official-Q8_0` | OpenBMB | Q8_0 | 2.49 GiB | tg128 | 6.04 ± 0.02 | `official-Q8_0.log` |
| 8 | `bartowski-Q6_K-context` | Bartowski | Q6_K | 1.96 GiB | pp2048 | 11.89 ± 0.02 | `bartowski-Q6_K-context.log` |
| 8 | `bartowski-Q6_K-context` | Bartowski | Q6_K | 1.96 GiB | pp4096 | 10.85 ± 0.01 | `bartowski-Q6_K-context.log` |
| 8 | `bartowski-Q6_K-context` | Bartowski | Q6_K | 1.96 GiB | tg128 | 7.19 ± 0.01 | `bartowski-Q6_K-context.log` |
