#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

BENCH_ROOT="${MINICPM5_BENCH_ROOT:?Set MINICPM5_BENCH_ROOT to the local benchmark workspace}"
ROOT="$BENCH_ROOT/llama.cpp"
CLI="$ROOT/build-cpu/bin/llama-cli"
PROMPTS="$BENCH_ROOT/quality/20260911-143133/prompts"

RUN_ID="$(date +%Y%m%d-%H%M%S)"
OUT="$BENCH_ROOT/reasoning-ablation/$RUN_ID"

RAW="$OUT/raw"
BLIND="$OUT/blind"
MAPPING="$OUT/mapping.tsv"
CASES="$OUT/cases.tsv"
ORDER="$OUT/cases_order.tsv"

mkdir -p "$RAW" "$BLIND"

echo -e "case_id\ttest\tseed\tA\tB\tC\tD" > "$MAPPING"

# One new seed per domain.
# If a result is ambiguous, repeat ONLY that domain later.
cat > "$CASES" <<'CASES'
03	314159
06	271828
07	161803
08	141421
CASES

shuf "$CASES" > "$ORDER"


resolve_prompt() {
    local PREFIX="$1"
    local MATCHES=( "$PROMPTS"/"${PREFIX}"_*.txt )

    if (( ${#MATCHES[@]} != 1 )); then
        echo "ERROR: expected exactly 1 prompt for prefix $PREFIX" >&2
        printf 'Found:\n' >&2
        printf '  %s\n' "${MATCHES[@]}" >&2
        exit 1
    fi

    printf '%s\n' "${MATCHES[0]}"
}


get_repo() {
    case "$1" in
        q4_on|q4_off)
            echo "openbmb/MiniCPM5-2B-GGUF"
            ;;
        q8_on|q8_off)
            echo "openbmb/MiniCPM5-2B-GGUF"
            ;;
    esac
}


get_quant() {
    case "$1" in
        q4_on|q4_off)
            echo "Q4_K_M"
            ;;
        q8_on|q8_off)
            echo "Q8_0"
            ;;
    esac
}


get_reasoning() {
    case "$1" in
        q4_on|q8_on)
            echo "on"
            ;;
        q4_off|q8_off)
            echo "off"
            ;;
    esac
}


run_model() {
    local CONFIG="$1"
    local PROMPT_FILE="$2"
    local OUTPUT="$3"
    local SEED="$4"

    local REPO
    local QUANT
    local REASONING

    REPO="$(get_repo "$CONFIG")"
    QUANT="$(get_quant "$CONFIG")"
    REASONING="$(get_reasoning "$CONFIG")"

    local REASONING_ARGS=()

    if [[ "$REASONING" == "on" ]]; then
        REASONING_ARGS=(
            --reasoning on
            --reasoning-budget 600
        )
    else
        REASONING_ARGS=(
            --reasoning off
        )
    fi

    # The sentinel is intentional.
    # It allows prompt/response separation without depending
    # on the number of header lines.
    local PROMPT
    PROMPT="$(cat "$PROMPT_FILE")"
    PROMPT+=$'\n\n### END_OF_USER_PROMPT_7F31A9 ###'

    "$CLI" \
        -hf "$REPO:$QUANT" \
        --offline \
        -c 8192 \
        -t 2 \
        -tb 2 \
        -n 2400 \
        --temp 1.0 \
        --top-p 0.95 \
        --top-k 0 \
        --min-p 0 \
        -s "$SEED" \
        "${REASONING_ARGS[@]}" \
        -st \
        --simple-io \
        --no-show-timings \
        --color off \
        --log-disable \
        -p "$PROMPT" \
        > "$OUTPUT" 2>&1
}


make_blind() {
    local INPUT="$1"
    local OUTPUT="$2"

    local TMP="$OUTPUT.tmp"

    # 1. Discard the header and prompt.
    # 2. Discard the reasoning block if present.
    # 3. Keep only what was presented as the final answer.
    awk '
        BEGIN {
            after_prompt = 0
            in_reasoning = 0
        }

        /### END_OF_USER_PROMPT_7F31A9 ###/ {
            after_prompt = 1
            next
        }

        !after_prompt {
            next
        }

        /^\[Start thinking\]$/ {
            in_reasoning = 1
            next
        }

        /^\[End thinking\]$/ {
            in_reasoning = 0
            next
        }

        in_reasoning {
            next
        }

        /^<\/think>$/ {
            next
        }

        /^Exiting\.\.\.$/ {
            next
        }

        {
            print
        }
    ' "$INPUT" > "$TMP"

    # Additional protection against accidental identity leakage.
    sed -E \
        -e 's#openbmb/MiniCPM5-2B-GGUF#[MODEL_REDACTED]#g' \
        -e 's#Q4_K_M#[QUANT_REDACTED]#g' \
        -e 's#Q4_K - Medium#[QUANT_REDACTED]#g' \
        -e 's#Q8_0#[QUANT_REDACTED]#g' \
        -e 's#reasoning[ =:]+on#reasoning=[REDACTED]#Ig' \
        -e 's#reasoning[ =:]+off#reasoning=[REDACTED]#Ig' \
        "$TMP" > "$OUTPUT"

    rm "$TMP"
}


while IFS=$'\t' read -r TEST SEED; do

    CASE_ID="$(cut -d- -f1 /proc/sys/kernel/random/uuid)"
    PROMPT_FILE="$(resolve_prompt "$TEST")"

    # New A/B/C/D permutation for EACH case.
    mapfile -t PERM < <(
        printf '%s\n' \
            q4_on \
            q4_off \
            q8_on \
            q8_off \
        | shuf
    )

    A="${PERM[0]}"
    B="${PERM[1]}"
    C="${PERM[2]}"
    D="${PERM[3]}"

    echo
    echo "========================================"
    echo "CASE: $CASE_ID"
    echo "TEST: $TEST"
    echo "SEED: $SEED"
    echo "========================================"

    for LABEL in A B C D; do
        CONFIG="${!LABEL}"

        echo "Running candidate $LABEL..."

        run_model \
            "$CONFIG" \
            "$PROMPT_FILE" \
            "$RAW/${CASE_ID}_${LABEL}.txt" \
            "$SEED"

        make_blind \
            "$RAW/${CASE_ID}_${LABEL}.txt" \
            "$BLIND/${CASE_ID}_${LABEL}.txt"
    done

    echo -e \
        "${CASE_ID}\t${TEST}\t${SEED}\t${A}\t${B}\t${C}\t${D}" \
        >> "$MAPPING"

done < "$ORDER"


# Random global review order.
find "$BLIND" \
    -maxdepth 1 \
    -type f \
    -name '*.txt' \
    -printf '%f\n' \
    | shuf \
    > "$OUT/review_order.txt"

sha256sum "$MAPPING" > "$OUT/mapping.sha256"


echo
echo "========================================"
echo " REASONING ABLATION COMPLETE"
echo "========================================"
echo
echo "Run:"
echo "$OUT"
echo
echo "Blind:"
echo "$BLIND"
echo
echo "Raw:"
echo "$RAW"
echo
echo "Secret mapping:"
echo "$MAPPING"
echo
echo "DO NOT open mapping.tsv yet."
