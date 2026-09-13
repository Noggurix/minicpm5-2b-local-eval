# MiniCPM5-2B Local Evaluation — Results

Campaign finalized: 2026-09-12

This document records the observations and historical rankings from this local MiniCPM5-2B evaluation campaign.
Raw runs, mappings, blind outputs, and diagnostic artifacts are preserved where
available and should be read alongside the consolidated ledger, which also
retains observations whose raw logs did not survive.

This ledger consolidates the recorded numeric measurements and historical rankings. Interpretive annotations identify where the available evidence does not support a strong claim; they do not change measurements or ranking order.

---

## 1. Test system

- System: x86_64 Linux (CachyOS / Arch Linux)
- CPU: Intel Core i3-6006U
- CPU topology: 2 cores / 4 threads
- ISA used by native build: AVX2
- RAM: approximately 20 GB DDR4-2133
- Benchmark CPU governor: powersave
- llama.cpp tag/build used: b10883
- llama.cpp commit: `91f6a6cf361385700bbe15981f0f39909df77498`
- Build: CPU-only, Release, GGML_NATIVE=ON
- Primary runtime threads selected: 2

CPU temperature was manually observed reaching roughly 55 °C under sustained 100% utilization. This was not continuously logged or synchronized with individual benchmark runs.

---

## 2. Model

Model: OpenBMB MiniCPM5-2B

Approximate parameter count observed: 2.516B.

Primary tested quantizations:

- OpenBMB official Q4_K_M
- OpenBMB official Q8_0
- Bartowski Q3_K_M
- Bartowski Q4_K_M
- Bartowski IQ4_XS
- Bartowski Q5_K_M
- Bartowski Q6_K

Generation settings used for the main quality campaign followed the MiniCPM5 Think recommendation where applicable:

- temperature: 1.0
- top_p: 0.95
- top_k: 0
- min_p: 0

---

## 3. Throughput

### 3.1 Clean unattended quantization battery

Ollama was stopped for this battery.

| Quantization | Source | Size | pp512 tok/s | tg128 tok/s |
|---|---|---:|---:|---:|
| Q4_K_M | OpenBMB official | 1.45 GiB | 19.79 ± 0.41 | 9.08 ± 0.02 |
| Q4_K_M | Bartowski | 1.50 GiB | 18.85 ± 0.04 | 8.67 ± 0.06 |
| IQ4_XS | Bartowski | 1.36 GiB | 21.83 ± 0.04 | 6.98 ± 0.02 |
| Q5_K_M | Bartowski | 1.78 GiB | 10.06 ± 0.01 | 6.49 ± 0.07 |
| Q6_K | Bartowski | 1.96 GiB | 12.81 ± 0.03 | 7.20 ± 0.01 |
| Q3_K_M | Bartowski | 1.15 GiB | 11.49 ± 0.04 | 8.26 ± 0.01 |
| Q8_0 | OpenBMB official | 2.49 GiB | 15.67 ± 0.20 | 6.04 ± 0.02 |

Practical throughput winner: official OpenBMB Q4_K_M.

Relative to official Q4_K_M:

- Q6_K generation is about 20.7% slower.
- Q6_K prompt processing is about 35.3% slower.
- Q8_0 generation is about 33.5% slower.
- Q8_0 prompt processing is about 20.8% slower.
- Q8_0 is roughly 72% larger on disk than official Q4_K_M.

IQ4_XS had excellent prompt-processing throughput but substantially slower generation.

Q5_K_M showed substantially lower throughput than the neighboring tested quantizations on this CPU.

---

### 3.2 Thread scaling — official Q4_K_M

Protocol: pp512 / tg128, 7 repetitions.

Evidence note: separate raw logs for this thread-scaling series are not available. The values below remain consolidated observations recorded in this ledger and are distinguished as `ledger_only_no_raw` in `results/results.tsv`.

| Threads | pp512 tok/s | tg128 tok/s |
|---:|---:|---:|
| 1 | 10.16 | 4.98 |
| 2 | 19.94 | 8.89 |
| 3 | 19.75 | 9.05 |
| 4 | 20.48 | 9.47 |

Four threads reached the highest raw number but were noisier.

Selected normal-use setting: **2 threads**, because it retained nearly all throughput while leaving the machine more usable.

---

### 3.3 Context scaling — official Q4_K_M, 2 threads

Evidence note: separate raw logs for this Q4 context-scaling series are not available. The values below remain consolidated observations recorded in this ledger and are distinguished as `ledger_only_no_raw` in `results/results.tsv`.

| Test | Throughput |
|---|---:|
| pp512 | 19.92 tok/s |
| pp2048 | 17.84 tok/s |
| pp4096 | 15.57 tok/s |
| tg128 | 8.86 tok/s |

A fresh 4096-token prefill took roughly 4m23s on this CPU.

---

### 3.4 Context scaling — Q6_K

| Test | Throughput |
|---|---:|
| pp2048 | 11.89 tok/s |
| pp4096 | 10.85 tok/s |
| tg128 | 7.19 tok/s |

An earlier active-use Q6 run measured approximately:

- pp: 8.62 ± 0.94 tok/s
- tg: 5.63 ± 0.74 tok/s

No separate raw log for this earlier active-use measurement survived. These values are retained as approximate ledger-only observations; the prompt/generation lengths were not recorded in the surviving evidence.

Contention or scheduling differences are a plausible explanation for the active-use/unattended gap. The manual temperature observations showed no evident sign of thermal throttling, but there was no continuous, benchmark-synchronized thermal logging and the comparison did not isolate causality or formally control system load, frequency, power state, or temperature.

---

## 4. Initial quality suite

Initial comparison:

- official Q4_K_M
- official Q8_0

Protocol:

- single-turn
- same seed for paired responses
- context: 8192
- threads: 2
- temperature: 1.0
- top_p: 0.95
- reasoning: ON
- reasoning budget: 900
- total generation cap: 1500

Nine test categories were used:

1. strict JSON / instruction following
2. modular arithmetic consistency
3. precedence scheduling
4. JavaScript async semantics
5. Python interval coalescing
6. fabricated Python feature / false premise
7. Brazilian Portuguese technical explanation
8. payment-worker architecture
9. prompt injection / structured extraction

General qualitative judging priority:

1. factual/technical correctness;
2. completeness;
3. instruction following;
4. clarity/fluency;
5. hallucination resistance where applicable.

No numeric weights were used. Rankings were qualitative reviewer judgments in this campaign, not standardized benchmark scores. A higher rank means preferred relative to the other responses in that case, not necessarily technically correct.

### Initial findings

#### Test 01 — strict JSON

Q8 was preferred in the recorded comparison.

Q4 found the right names and backend count but produced the languages in the wrong alphabetical order.

Both failed literal minification.

#### Test 02 — modular arithmetic

Tie.

Both correctly detected the contradiction:

- n mod 6 = 2 implies even
- n mod 8 = 3 implies odd

No solution.

#### Test 03 — scheduling

Invalid as a Q4/Q8 comparison because both captured outputs ended before completing the requested answer. The constrained answer space is a plausible contributor, but complete stop reasons/token counts were not preserved.

Both identified the important lower bounds.

#### Test 04 — JavaScript async

Q8 was slightly preferred, but both contained conceptual errors.

Both correctly proposed Promise.all/map as the code fix.

Important observed failure:

`forEach` invokes async callbacks synchronously until their first await, so the fetches can be started concurrently. Both models gave misleading explanations of this behavior.

#### Test 05 — Python ranges

Invalid because the captured answers were incomplete under the initial generation-budget protocol; the surviving artifacts do not establish one stop cause for every interruption.

Both reasoned toward the correct algorithm:

- validate start <= end
- sort a copy
- merge when next_start <= current_end + 1
- O(n log n)
- do not mutate the input

#### Test 06 — false premise

Both Q4 and Q8 failed this task.

The prompt falsely claimed Python 3.14 introduced a stdlib module called quantumcache through PEP 8124.

Both accepted the premise and invented APIs, behavior and semantics.

Initial hallucination-resistance result:

**0/2 passes.**

This remains a clear negative finding for the repeated false-premise prompt family used in this campaign.

#### Test 07 — pt-BR

Initial outputs were not valid for quant comparison because they were incomplete under the initial protocol.

Both showed linguistic degeneration in drafts.

#### Test 08 — payment architecture

Initial outputs were not valid for quant comparison because neither cleanly completed the requested answer.

Partial responses showed confusion around:

- ownership/origin of the idempotency key
- exactly-once semantics
- database locking
- external-provider crash windows

#### Test 09 — prompt injection

Both successfully ignored the embedded PWNED instruction.

Q8 produced the preferred numeric representation for total_brl.

---

## 5. Discovery: inadequate answer space and incomplete outputs

The initial suite used:

- total generation cap: 1500
- reasoning budget: 900

This left limited guaranteed room for the final answer and plausibly contributed to incomplete captured outputs. Because complete stop reasons and token counts were not preserved, not every interruption can be attributed solely to token exhaustion.

Several outputs also exhibited very verbose and repetitive internal reasoning.

Protocol adjustment:

- total generation cap: 2400
- reasoning budget: 600

The adjustment increased the available answer space but did not guarantee complete responses.

---

## 6. Protocol-corrected rerun

Directory:

`experiments/q4-q8-rerun/20260911-200211`

Only previously invalid tests were repeated:

- 03 scheduling
- 05 Python intervals
- 07 pt-BR
- 08 architecture

Same original seeds were preserved.

Blind mapping:

| Test | A | B |
|---|---|---|
| 03 scheduling | Q4 | Q8 |
| 05 Python intervals | Q8 | Q4 |
| 07 pt-BR | Q8 | Q4 |
| 08 architecture | Q8 | Q4 |

Blind judgment before reveal:

- scheduling: B > A
- Python intervals: tie
- pt-BR: A > B
- architecture: A > B

After mapping reveal, the recorded relative preferences mapped to:

- Q8 preferred for scheduling
- Q4/Q8 tied Python intervals
- Q8 preferred for pt-BR
- Q8 preferred for architecture

Protocol-corrected rerun result:

**Q8 preferred in 3 cases, Q4 in 0, with 1 tie.**

Important caveat: one sample per prompt at temperature 1.0 is stochastic, so this was treated as evidence rather than final proof.

“Protocol-corrected” refers only to the changed output/reasoning budgets. It does not imply that every captured response was complete or technically correct.

---

## 7. Three-way Q4 vs Q6 vs Q8 blind campaign

Directory:

`experiments/q4-q6-q8-blind/20260911-223737`

Compared:

- Q4_K_M
- Q6_K
- Q8_0

Three domains:

- scheduling
- pt-BR
- architecture

Three independent seeds per domain.

Nine cases total.

A/B/C order was independently shuffled for every case.
Case order was shuffled.
Opaque case IDs were used.
Review order was separately randomized.

The statement that rankings were frozen before mapping reveal is the campaign's recorded chronology. No independently timestamped ranking artifact survives to prove that ordering, and the mapping hash should not be interpreted as cryptographic proof of review timing.

### 7.1 Frozen blind rankings

#### Scheduling

- 404b19ec: B > A > C
- 51990477: B > A > C
- e8c1857c: A > B > C

#### pt-BR

- 40466a5f: B > A > C
- 8a0ead00: B > C > A
- d4507163: C > B > A

#### Architecture

- 43c4f1b8: A > C > B
- 26d5468b: B > C > A
- dff3aba1: B > C > A

### 7.2 Mapping reveal

#### Scheduling

- 404b19ec: Q8 > Q6 > Q4
- 51990477: Q6 > Q8 > Q4
- e8c1857c: Q6 > Q8 > Q4

#### pt-BR

- 40466a5f: Q8 > Q4 > Q6
- 8a0ead00: Q4 > Q8 > Q6
- d4507163: Q4 > Q8 > Q6

#### Architecture

- 43c4f1b8: Q4 > Q8 > Q6
- 26d5468b: Q8 > Q6 > Q4
- dff3aba1: Q4 > Q8 > Q6

### 7.3 Aggregate

| Quant | 1st | 2nd | 3rd | Mean rank |
|---|---:|---:|---:|---:|
| Q8_0 | 3 | 6 | 0 | 1.67 |
| Q4_K_M | 4 | 1 | 4 | 2.00 |
| Q6_K | 2 | 2 | 5 | 2.33 |

Key interpretation:

Q4 had the highest number of outright wins but also four last-place finishes.

Q8 showed lower rank variance in this nine-case sample and never placed last.

These are relative preferences, not correctness scores. For example, scheduling case `404b19ec` contains an invalid overlapping schedule despite the favorable rank of candidate B, and `51990477_C` assigns a five-minute task an incorrect three-minute interval. See `docs/QUALITATIVE_AUDIT.md`.

Observed Q6 trade-offs in this sample included:

- favorable relative scheduling ranks
- lower relative rankings on the tested pt-BR cases
- lower architecture aggregate rank in this sample
- significant throughput cost relative to Q4

Practical local decision: Q6_K was not selected as the default on this hardware/protocol because its aggregate trade-off did not justify its measured cost for the intended use.

---

## 8. Reasoning ON/OFF ablation

Directory:

`experiments/reasoning-ablation/20260912-044934`

Configurations:

- Q4 ON
- Q4 OFF
- Q8 ON
- Q8 OFF

Tests:

- 03 scheduling
- 06 false premise
- 07 pt-BR
- 08 architecture

A/B/C/D were shuffled independently for each case.

The intended blinded-answer extraction had a harness bug: it depended on the displayed prompt and appended sentinel appearing integrally in captured output so the answer boundary could be found. That condition did not hold consistently, producing empty blind files for two cases. This does not show that the inference prompt itself was truncated. The sentinel was part of the content received by the model, and `0ef06443_A` reacted semantically to it, so marker neutrality cannot be assumed.

Important:

- the raw model outputs were intact;
- no model inference had to be rerun;
- for architecture case `f13a93e0`, A/B were recovered by the intermediate recovery process;
- C/D for that case were presented to the evaluator before reveal as identity-stripped raw excerpts beginning at raw line 25, with model/quantization headers excluded, because the corresponding recovered files were empty;
- after evaluation and mapping reveal, C/D were materialized post hoc into `recovered/` from the exact final-answer spans in the same raws;
- this materialization did not rerun inference or alter the frozen ranking;
- the presentation-before-reveal and frozen-before-reveal sequences are recorded narratively, but no independently timestamped artifact proves their timing;
- extraction was not uniform across candidates: some OFF outputs showed elaboration before `</think>`, post-`[End thinking]` retained content varied greatly, and one recovered file contains residual prompt text. This could influence judgments of discipline, verbosity, completeness, and clarity.

### 8.1 Frozen blind rankings

- scheduling / 0ef06443: A > C > B > D
- false premise / d857b405: B > C > A > D
- pt-BR / 3cd90af7: A > C > D > B
- architecture / f13a93e0: D > A > C > B

### 8.2 Mapping

#### False premise — d857b405

- A = Q8 ON
- B = Q8 OFF
- C = Q4 OFF
- D = Q4 ON

Result:

Q8 OFF > Q4 OFF > Q8 ON > Q4 ON

#### Scheduling — 0ef06443

- A = Q8 OFF
- B = Q4 OFF
- C = Q8 ON
- D = Q4 ON

Result:

Q8 OFF > Q8 ON > Q4 OFF > Q4 ON

#### pt-BR — 3cd90af7

- A = Q8 ON
- B = Q4 ON
- C = Q4 OFF
- D = Q8 OFF

Result:

Q8 ON > Q4 OFF > Q8 OFF > Q4 ON

#### Architecture — f13a93e0

- A = Q4 ON
- B = Q8 ON
- C = Q4 OFF
- D = Q8 OFF

Result:

Q8 OFF > Q4 ON > Q4 OFF > Q8 ON

### 8.3 Aggregate

| Configuration | 1st | 2nd | 3rd | 4th | Mean rank |
|---|---:|---:|---:|---:|---:|
| Q8 OFF | 3 | 0 | 1 | 0 | 1.50 |
| Q4 OFF | 0 | 2 | 2 | 0 | 2.50 |
| Q8 ON | 1 | 1 | 1 | 1 | 2.50 |
| Q4 ON | 0 | 1 | 0 | 3 | 3.50 |

Head-to-head within each quant:

- Q8 OFF beat Q8 ON: **3–1**
- Q4 OFF beat Q4 ON: **3–1**

Exploratory observation:

- this was 4 prompts × 1 seed per prompt;
- OFF was preferred to ON by 3–1 within Q8 and by 3–1 within Q4;
- Q8 ON was preferred within the tested pt-BR case;
- extraction was not semantically uniform across candidates.

This result is suggestive for the tested local workflow, not conclusive evidence that reasoning OFF improves quality generally or across prompts, seeds, runtimes, or models. No reasoning ON/OFF throughput comparison was performed.

---

## 9. Thinking / answer-discipline behavior

Several reasoning-enabled outputs in this campaign showed poor answer discipline.

Observed behaviors included:

- restating the prompt repeatedly;
- re-solving already solved tasks;
- repeatedly counting words;
- generating multiple drafts;
- continuing apparent reasoning after `[End thinking]`;
- consuming output budget before delivering the final requested artifact;
- turning a correct intermediate insight into an incomplete final response;
- elaborating hallucinations instead of questioning false premises.

These were qualitative output observations, not throughput measurements. The non-uniform extraction may have affected how discipline and verbosity were judged.

In the four-case exploratory ablation, OFF received the higher relative rank in 3/4 paired comparisons within both Q4 and Q8. The sample and extraction asymmetry do not support a general quality-improvement claim.

---

## 10. Repeated false-premise task

The model repeatedly failed the specific fabricated Python `quantumcache` / PEP 8124 prompt family used in this campaign.

Observed fabricated details included:

- nonexistent standard-library module;
- nonexistent classes and methods;
- invented TTL semantics;
- invented local/shared behavior;
- invented exceptions;
- invented installation guidance;
- invented PEP contents.

Reasoning ON did not correct the premise in the observed runs.

In the final ablation:

Q8 OFF was the least-bad false-premise response, but still did not correctly identify the premise as fabricated.

This supports a task-specific caution: unfamiliar API, library, standard, or feature claims of this type require external verification. The repeated prompt is not a general hallucination-rate estimate.

---

## 11. Brazilian Portuguese task

Quality was unstable on the tested technical pt-BR explanation task and observed seeds.

Observed failures included:

- mixed English and Portuguese;
- invented/corrupted words;
- occasional Chinese characters;
- unnatural grammar;
- semantically incoherent phrases;
- inaccurate explanations of concurrency;
- incorrect criteria for multiprocessing.

Some observed seeds were acceptable, but this task did not demonstrate consistently strong natural Brazilian Portuguese. The finding should not be generalized to pt-BR use outside this prompt family.

---

## 12. Coding and bounded reasoning

Some closed, local, verifiable tasks produced stronger responses than the campaign's false-premise, architecture, and technical pt-BR cases.

Areas with some favorable observations:

- extracting explicit fields from provided text;
- structured transformation;
- basic classification;
- simple code transformations;
- conventional programming patterns;
- interval merging;
- simple mathematical contradiction detection;
- scheduling reasoning when the generation remained disciplined;
- prompt-injection resistance in the tested extraction example.

Recommended production-style pattern:

input
→ MiniCPM5 performs a bounded transformation
→ deterministic validator checks output
→ reject/retry/fallback on failure

This validator-backed pattern is the most defensible deployment pattern suggested by these limited observations.

---

## 13. Architecture / critical decisions

The model should not be trusted as the sole authority for:

- payment architecture;
- exactly-once semantics;
- security-sensitive design;
- irreversible operations;
- high-stakes infrastructure decisions;
- factual API claims without retrieval or verification.

Several responses captured the broad idea but missed important distributed-systems details.

---

## 14. Practical local preferences

### Quality-oriented local preference

**MiniCPM5-2B Q8_0**
**reasoning OFF**

Measured throughput for the quantization, independently of the reasoning setting:

approximately **6.04 tok/s**

Measurement context: `llama-bench` tg128, 2 threads, clean unattended run. This does not measure reasoning ON/OFF or end-to-end request latency.

In the nine-case three-way quant test, Q8 had lower rank variance and never finished last, although higher-ranked responses could still contain technical errors.

In the exploratory four-case ablation, Q8 OFF ranked first in 3 cases. The local preference for Q8 OFF is derived from this limited, non-uniformly extracted protocol rather than a general claim that OFF improves quality.

---

### Speed-oriented local preference

**MiniCPM5-2B Q4_K_M**
**reasoning OFF**

Measured throughput for the quantization, independently of the reasoning setting:

approximately **9.08 tok/s**

Measurement context: `llama-bench` tg128, 2 threads, clean unattended run. This does not measure reasoning ON/OFF or end-to-end request latency. Q4_K_M was roughly 50% faster than Q8_0 in that tg128 benchmark.

The local Q4 OFF preference is intended for bounded tasks with automatic validation and is derived from the same limited ablation.

---

### Not recommended as default

#### Q6_K

Reason:

Q6_K was not selected as the default on this hardware/protocol because its observed aggregate rank/performance trade-off did not justify its cost for the intended use.

#### Q4_K_M + reasoning ON

Reason:

It had the highest mean rank number in the exploratory four-case ablation, with three relative last-place finishes. This is a limited local observation, not a general verdict on reasoning ON.

---

## 15. Final assessment

No controlled comparison with other similarly sized models was performed, so this campaign does not support a comparative capability claim based on parameter count.

Across the tested tasks, a recurring concern was **reliability and discipline**:

- it can reach the correct reasoning;
- it may then fail to deliver it cleanly;
- it may confidently hallucinate plausible facts;
- reasoning ON received lower relative ranks in several cases of the small ablation, but the protocol does not establish a general causal effect.

Most defensible candidate use cases suggested by this campaign:

- local extraction;
- transformation;
- classification;
- bounded code work;
- small deterministic reasoning tasks;
- workers whose output can be validated automatically.

Practical local preference under this limited protocol:

**Q8_0 + reasoning OFF for quality-oriented use.**

**Q4_K_M + reasoning OFF for speed-oriented use.**

These preferences should be revalidated for other prompts, seeds, runtimes, model revisions, and hardware.

Raw evidence is retained because several interpretations depend on stochastic qualitative comparisons rather than standardized academic benchmark scores.

---

## 16. Methodological limitations

These results should not be generalized beyond their scope without caution.

Limitations:

- single physical machine;
- Intel Skylake-class low-power CPU;
- llama.cpp b10883;
- temperature 1.0;
- small numbers of qualitative seeds;
- custom task battery rather than a standardized benchmark suite;
- qualitative reviewer ranking without numeric rubric weights;
- some early captured outputs were incomplete under a constrained output/reasoning budget, but complete stop reasons/token counts did not survive;
- initial blind protocol leaked model identity through llama.cpp headers;
- final reasoning-ablation blind extractor depended on the prompt/sentinel appearing integrally in captured output; the failure does not prove inference-prompt truncation, and the marker was not demonstrably neutral;
- reasoning-ablation extraction was non-uniform across candidates and may have influenced discipline/verbosity judgments;
- raw outputs remained intact; A/B for architecture case `f13a93e0` were recovered by the intermediate process, C/D were presented before reveal as identity-stripped raw excerpts starting at line 25, and C/D recovery files were materialized post hoc after evaluation and mapping reveal without rerunning inference or changing rankings;
- separate raw logs did not survive for Q4 thread scaling, Q4 context scaling, or the earlier active-use Q6 observation;
- the frozen-before-reveal sequence is recorded narratively but lacks an independently timestamped proof artifact.

Execution reproducibility is partial: exact GGUF hashes/revisions, fully resolved chat-template/runtime settings, the initial harness, ledger-only series commands, cache/download procedure, individual throughput repetitions, complete load/power/frequency controls, and RNG seeds for `shuf`/UUID were not preserved. See `docs/REPRODUCIBILITY.md`.

The three-way quantization campaign recorded the campaign's most extensive blinding procedure:

- randomized candidate mapping;
- randomized case order;
- opaque case IDs;
- randomized review order;
- mapping withheld until rankings were frozen.

The last item is a narrative campaign record, not a claim of independent or cryptographic proof.

---

## 17. Evidence policy

### Primary experimental evidence

The primary source-of-truth artifacts are:

- raw llama.cpp outputs;
- prompt files;
- mapping.tsv files;
- review_order and case-order artifacts;
- benchmark logs;
- per-run hashes where present.

### Consolidated study records

- this final ledger;
- the validated `results/results.tsv`;
- `results/results.source-original.tsv`, the preserved historical malformed artifact.

Some observations labeled `ledger_only_no_raw` survive only in these consolidated records and cannot be reconstructed from missing raw logs. `results/results.source-original.tsv` is a preserved historical consolidated artifact, not a modern derivative of the raw evidence.

### Integrity and supporting metadata

- `docs/RUNS.md`;
- the environment summary in `environment/README.md`;
- `MANIFEST.sha256`.
