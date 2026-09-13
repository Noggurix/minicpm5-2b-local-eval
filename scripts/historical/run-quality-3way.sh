#!/usr/bin/env bash
set -euo pipefail

BENCH_ROOT="${MINICPM5_BENCH_ROOT:?Set MINICPM5_BENCH_ROOT to the local benchmark workspace}"
ROOT="$BENCH_ROOT/llama.cpp"
CLI="$ROOT/build-cpu/bin/llama-cli"

PROMPTS="$BENCH_ROOT/quality/20260911-143133/prompts"

RUN_ID="$(date +%Y%m%d-%H%M%S)"
OUT="$BENCH_ROOT/quality-3way/$RUN_ID"

RAW="$OUT/raw"
BLIND="$OUT/blind"
MAPPING="$OUT/mapping.tsv"
CASES="$OUT/cases.tsv"
ORDER="$OUT/cases_order.tsv"

mkdir -p "$RAW" "$BLIND"

echo -e "case_id\ttest\tseed\tA\tB\tC" > "$MAPPING"

# ============================================================
# 3 tests × 3 new seeds
# ============================================================

cat > "$CASES" <<'CASES'
03_scheduling	63127
03_scheduling	74291
03_scheduling	85643
07_ptbr	61781
07_ptbr	73517
07_ptbr	89107
08_architecture	64849
08_architecture	77383
08_architecture	92507
CASES

# Test order is also randomized.
shuf "$CASES" > "$ORDER"


get_repo() {
    case "$1" in
        q4)
            echo "openbmb/MiniCPM5-2B-GGUF"
            ;;
        q6)
            echo "bartowski/MiniCPM5-2B-GGUF"
            ;;
        q8)
            echo "openbmb/MiniCPM5-2B-GGUF"
            ;;
    esac
}

get_quant() {
    case "$1" in
        q4)
            echo "Q4_K_M"
            ;;
        q6)
            echo "Q6_K"
            ;;
        q8)
            echo "Q8_0"
            ;;
    esac
}


run_model() {
    local MODEL="$1"
    local PROMPT="$2"
    local OUTPUT="$3"
    local SEED="$4"

    local REPO
    local QUANT

    REPO="$(get_repo "$MODEL")"
    QUANT="$(get_quant "$MODEL")"

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
        --reasoning on \
        --reasoning-budget 600 \
        -st \
        --simple-io \
        --no-display-prompt \
        --no-show-timings \
        --color off \
        --log-disable \
        -p "$(cat "$PROMPT")" \
        > "$OUTPUT" 2>&1
}


make_blind() {
    local INPUT="$1"
    local OUTPUT="$2"
    local TMP="$OUTPUT.tmp"

    # Remove the entire llama.cpp header.
    # The blind file begins with the generated reasoning.
    if grep -q '^\[Start thinking\]' "$INPUT"; then
        awk '
            /^\[Start thinking\]/ { started=1 }
            started { print }
        ' "$INPUT" > "$TMP"
    else
        cp "$INPUT" "$TMP"
    fi

    # Second protection layer in case the model/runtime
    # accidentally mentions a quantization.
    sed -E \
        -e 's#openbmb/MiniCPM5-2B-GGUF#[MODEL_REDACTED]#g' \
        -e 's#bartowski/MiniCPM5-2B-GGUF#[MODEL_REDACTED]#g' \
        -e 's#Q4_K_M#[QUANT_REDACTED]#g' \
        -e 's#Q4_K - Medium#[QUANT_REDACTED]#g' \
        -e 's#Q6_K#[QUANT_REDACTED]#g' \
        -e 's#Q8_0#[QUANT_REDACTED]#g' \
        "$TMP" > "$OUTPUT"

    rm "$TMP"
}


while IFS=$'\t' read -r TEST SEED; do

    # Random opaque ID.
    CASE_ID="$(cut -d- -f1 /proc/sys/kernel/random/uuid)"

    PROMPT="$PROMPTS/${TEST}.txt"

    if [[ ! -f "$PROMPT" ]]; then
        echo "ERROR: prompt not found: $PROMPT"
        exit 1
    fi

    # New independent permutation for EACH case.
    mapfile -t PERM < <(
        printf '%s\n' q4 q6 q8 | shuf
    )

    MODEL_A="${PERM[0]}"
    MODEL_B="${PERM[1]}"
    MODEL_C="${PERM[2]}"

    echo
    echo "========================================"
    echo "CASE: $CASE_ID"
    echo "TEST: $TEST"
    echo "SEED: $SEED"
    echo "========================================"

    echo "Running candidate A..."
    run_model \
        "$MODEL_A" \
        "$PROMPT" \
        "$RAW/${CASE_ID}_A.txt" \
        "$SEED"

    echo "Running candidate B..."
    run_model \
        "$MODEL_B" \
        "$PROMPT" \
        "$RAW/${CASE_ID}_B.txt" \
        "$SEED"

    echo "Running candidate C..."
    run_model \
        "$MODEL_C" \
        "$PROMPT" \
        "$RAW/${CASE_ID}_C.txt" \
        "$SEED"

    make_blind \
        "$RAW/${CASE_ID}_A.txt" \
        "$BLIND/${CASE_ID}_A.txt"

    make_blind \
        "$RAW/${CASE_ID}_B.txt" \
        "$BLIND/${CASE_ID}_B.txt"

    make_blind \
        "$RAW/${CASE_ID}_C.txt" \
        "$BLIND/${CASE_ID}_C.txt"

    echo -e \
        "${CASE_ID}\t${TEST}\t${SEED}\t${MODEL_A}\t${MODEL_B}\t${MODEL_C}" \
        >> "$MAPPING"

done < "$ORDER"


# ============================================================
# A THIRD randomization:
# order in which files will be presented for review.
# ============================================================

find "$BLIND" \
    -maxdepth 1 \
    -type f \
    -name '*.txt' \
    -printf '%f\n' \
    | shuf \
    > "$OUT/review_order.txt"


# Hash to record that the mapping did not change.
sha256sum "$MAPPING" > "$OUT/mapping.sha256"


echo
echo "========================================"
echo " 3-WAY QUALITY SUITE COMPLETE"
echo "========================================"
echo
echo "Blind:"
echo "$BLIND"
echo
echo "Review order:"
echo "$OUT/review_order.txt"
echo
echo "Secret mapping:"
echo "$MAPPING"
echo
echo "DO NOT open or share mapping.tsv yet."
