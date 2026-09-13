# Post hoc recovery materialization

The historical sentinel-based blind extractor failed because it depended on the displayed prompt and appended sentinel appearing integrally in captured output. This does not establish that the inference prompt itself was truncated. The sentinel was included in the content received by the model, and `0ef06443_A` reacted semantically to it, so the marker cannot be assumed neutral. The raw outputs remained intact and no inference was rerun.

For architecture case `f13a93e0`, candidates A and B had already been materialized by the intermediate recovery process. Candidates C and D were presented to the evaluator before reveal through identity-stripped raw excerpts beginning at raw line 25, excluding the model/quantization headers, because their corresponding `recovered/` files were empty. Rankings were not changed.

After evaluation and mapping reveal, C and D were materialized post hoc from those same intact raws:

- `recovered/f13a93e0_C.txt` is exactly raw lines 43-56: from `**Database Modeling**` through the last answer sentence, excluding startup header, displayed prompt, blank separator, and `Exiting...` footer.
- `recovered/f13a93e0_D.txt` is exactly raw lines 43-51: from `**Database State:**` through the last answer sentence, with the same exclusions.

Validation used byte comparison against those selected raw spans. Checksums after materialization:

| Artifact | SHA-256 |
|---|---|
| `raw/f13a93e0_C.txt` | `19d414d364e5ceeea7cd49e06dafd869841e34e811adaa66884a7b1ad0badfe0` |
| `raw/f13a93e0_D.txt` | `eb3f25a7681e9bfdfdb1ac86a85df6bf3417dd5913b9caf1fd33c84fdcc2b71c` |
| `recovered/f13a93e0_C.txt` | `4284a017671bbcb090ba66f068662a27a820d314643a8ac4258c066f0f485003` |
| `recovered/f13a93e0_D.txt` | `41db15455dc53a51e5994cceb76e4942e9f79d73dd493bd8b65da34ae1f568ba` |

The statement that ranking preceded mapping reveal remains narrative campaign provenance. There is no independently timestamped artifact proving that temporal sequence.

Extraction was not semantically uniform across candidates. Some OFF raws included elaboration before `</think>`; ON candidates retained very different volumes after `[End thinking]`; and `recovered/0ef06443_B.txt` contains a residual prompt fragment. These differences may have influenced discipline/verbosity judgments and are not normalized post-reveal.
