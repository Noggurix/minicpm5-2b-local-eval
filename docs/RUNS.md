# MiniCPM5-2B Local Evaluation — Run Index

This file indexes the major quality runs in the study.

## Initial quality suite

Path:

`experiments/initial-q4-q8/20260911-143133-responses`

Purpose:

Initial Q4_K_M vs Q8_0 quality comparison.

Important caveats:

- blind protocol was compromised because llama.cpp startup output exposed model identity;
- total generation cap 1500 with reasoning budget 900 left limited answer space and several captured outputs were incomplete; complete stop reasons/token counts were not recorded for every output.

The initial run is retained as historical evidence.

---

## Protocol-corrected invalid-test rerun

Path:

`experiments/q4-q8-rerun/20260911-200211`

Purpose:

Repeat tests 03, 05, 07 and 08 using:

- total output 2400
- reasoning budget 600
- same original seeds

Recorded relative result:

Q8 was preferred in 3 tests; 1 tie.

“Protocol-corrected” refers to the increased total output and reduced reasoning budget. It does not mean that every response was complete or technically correct; the change did not guarantee completion.

---

## Three-way quantization campaign

Path:

`experiments/q4-q6-q8-blind/20260911-223737`

Purpose:

Compare Q4_K_M vs Q6_K vs Q8_0 across:

- scheduling
- pt-BR
- architecture

Three seeds per domain.

Recorded blind procedure:

- randomized candidate mapping for every case;
- randomized case order;
- opaque case IDs;
- independently randomized review order;
- campaign record: mapping was withheld until ranking was frozen.

The frozen-before-reveal ordering is recorded narratively in the campaign ledger. No independently timestamped ranking artifact is available, and the mapping hash does not independently prove review timing.

Aggregate:

- Q8: mean rank 1.67; never last
- Q4: mean rank 2.00
- Q6: mean rank 2.33

These are relative ranks, not correctness scores. Higher-ranked candidates could still contain technical errors; see `docs/QUALITATIVE_AUDIT.md`.

---

## Reasoning ablation

Path:

`experiments/reasoning-ablation/20260912-044934`

Purpose:

Compare:

- Q4 ON
- Q4 OFF
- Q8 ON
- Q8 OFF

Tests:

- scheduling
- false premise
- pt-BR
- architecture

Sample size: 4 prompts × 1 seed per prompt.

Important harness issue:

The extractor depended on the displayed prompt and appended sentinel appearing integrally in captured output. That condition did not hold consistently, producing empty blind files for two cases. This does not prove the inference prompt was truncated. The sentinel was included in model input and at least one output reacted to it, so neutrality cannot be assumed.

Raw files are intact.

For architecture case `f13a93e0`, A/B were recovered by the intermediate recovery process. C/D were presented to the evaluator before reveal as identity-stripped raw excerpts beginning at raw line 25, with model/quantization headers excluded, because the corresponding recovered files remained empty. After evaluation and mapping reveal, exact C/D final-answer spans were materialized post hoc into `recovered/` from those same raws. No inference was rerun and the ranking was not changed.

Extraction was not uniform across candidates: some OFF outputs contained elaboration before `</think>`, post-`[End thinking]` retained content varied greatly, and one recovered file contains residual prompt text. This may have affected judgments of discipline/verbosity.

The campaign ledger records that rankings were frozen before mapping reveal, but there is no independently timestamped artifact proving that sequence.

Aggregate:

- Q8 OFF mean rank 1.50
- Q4 OFF mean rank 2.50
- Q8 ON mean rank 2.50
- Q4 ON mean rank 3.50

OFF was preferred to ON in 3 of 4 paired cases for both Q4 and Q8.

This is an exploratory observation, not conclusive evidence that reasoning OFF generally improves quality. No reasoning ON/OFF throughput comparison was performed.

---

## Practical local preferences

Quality-oriented:

`Q8_0 + reasoning OFF`

Speed-oriented:

`Q4_K_M + reasoning OFF`

These preferences derive from this limited protocol and should be revalidated elsewhere. See `RESULTS.md` for the complete interpretation.
