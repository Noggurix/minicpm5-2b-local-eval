# Qualitative ranking audit

This qualitative audit was performed after mappings had been revealed. It does not change, normalize, or rerun the historical responses and does not alter any recorded ranking.

## Judging rubric recorded for the campaign

The qualitative review used this general priority order:

1. factual/technical correctness;
2. completeness;
3. instruction following;
4. clarity/fluency;
5. hallucination resistance where applicable.

No numeric weights were used. Rankings were qualitative reviewer judgments from this campaign, not standardized benchmark scores.

**A higher rank means preferred relative to the other responses in that case, not necessarily technically correct.**

## Non-uniform reasoning-ablation extraction

The reasoning-ablation candidates were not all reduced using one semantically equivalent “final answer” rule:

- some OFF outputs contained visible elaboration before `</think>`; `0ef06443_A` is a preserved example;
- post-`[End thinking]` content length varied greatly across ON candidates, so retaining that region exposed very different amounts of drafting/repetition;
- `recovered/0ef06443_B.txt` begins with the residual prompt fragment `### END_OF ... (truncated)`;
- recovered files therefore do not always represent an equivalent semantic slice across candidates;
- the inconsistency could have influenced judgments of discipline, verbosity, completeness, and clarity.

Normalization and reranking are intentionally not attempted because mappings are now known.

For architecture case `f13a93e0`, C/D were presented to the evaluator before reveal through identity-stripped excerpts of their raws beginning at raw line 25, excluding the model/quantization headers. That chronology is part of the procedure record, but no independent timestamped artifact proves it. It must not be described as cryptographically verifiable blinding.

## Selected post-reveal annotations

These selected cases document interpretation-critical errors; they are not a new score set or an exhaustive regrading.

| Case ID | Campaign / test | Recorded ranking | Completion status | Main objective issue observed | Basis presented during evaluation | Audit status |
|---|---|---|---|---|---|---|
| `404b19ec` | three-way / scheduling | B > A > C | B contains a final answer; A and C are visibly incomplete | B's displayed worker-2 schedule overlaps E and D, while its prose gives inconsistent D timings. Its favorable relative rank does not make the schedule valid. | `blind/404b19ec_{A,B,C}.txt` | Post-reveal annotation; ranking unchanged. |
| `51990477` | three-way / scheduling | B > A > C | C is incomplete; A/B also show truncation at the captured tail | C assigns task C to 6–9 despite the prompt specifying duration 5. | `blind/51990477_{A,B,C}.txt` | Post-reveal annotation; ranking unchanged. |
| `0ef06443` | ablation / scheduling | A > C > B > D | A has a compact extracted answer; other candidates retain much larger or contaminated spans | Extraction is non-uniform: OFF candidate A elaborates before `</think>` in raw, and recovered B contains residual prompt text. | recovered files materialized from raws | Post-reveal extraction annotation; no reranking. |
| `d857b405` | ablation / false premise | B > C > A > D | Responses are present | Even the relative winner did not identify the fabricated premise; all candidates failed this task according to the ledger. | non-empty blind files | Post-reveal annotation; ranking unchanged. |
| `f13a93e0` | ablation / architecture | D > A > C > B | C/D contain direct final answers; A/B retain much larger post-thinking material | Winner D incorrectly claims exactly-once execution from database state plus provider idempotency. | A/B: intermediate recovered files; C/D: identity-stripped raw excerpts beginning at line 25 | Post-reveal annotation; ranking unchanged. |

The table illustrates why relative rank aggregates cannot be read as absolute correctness rates or as proof that one reasoning setting generally improves answer quality.
