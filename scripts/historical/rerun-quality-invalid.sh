#!/usr/bin/env bash
set -euo pipefail

BENCH_ROOT="${MINICPM5_BENCH_ROOT:?Set MINICPM5_BENCH_ROOT to the local benchmark workspace}"
ROOT="$BENCH_ROOT/llama.cpp"
CLI="$ROOT/build-cpu/bin/llama-cli"

# Prompts from the previous suite
OLD="$BENCH_ROOT/quality/20260911-143133/prompts"

RUN_ID="$(date +%Y%m%d-%H%M%S)"
OUT="$BENCH_ROOT/quality-rerun/$RUN_ID"
RAW="$OUT/raw"
BLIND="$OUT/blind"
MAPPING="$OUT/mapping.tsv"

mkdir -p "$RAW" "$BLIND"

echo -e "test\tA\tB\tseed" > "$MAPPING"

declare -A REPO
declare -A QUANT

REPO[q4]="openbmb/MiniCPM5-2B-GGUF"
QUANT[q4]="Q4_K_M"

REPO[q8]="openbmb/MiniCPM5-2B-GGUF"
QUANT[q8]="Q8_0"

run_model() {
    local MODEL="$1"
    local PROMPT="$2"
    local OUTPUT="$3"
    local SEED="$4"

    "$CLI" \
        -hf "${REPO[$MODEL]}:${QUANT[$MODEL]}" \
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
    local RAWFILE="$1"
    local BLINDFILE="$2"

    sed -E \
        -e 's#openbmb/MiniCPM5-2B-GGUF:Q4_K_M#[MODEL_REDACTED]#g' \
        -e 's#openbmb/MiniCPM5-2B-GGUF:Q8_0#[MODEL_REDACTED]#g' \
        -e 's#Q4_K - Medium#[QUANT_REDACTED]#g' \
        -e 's#Q8_0#[QUANT_REDACTED]#g' \
        "$RAWFILE" > "$BLINDFILE"
}

run_test() {
    local NUM="$1"
    local NAME="$2"
    local SEED="$3"
    local PROMPT="$OLD/${NUM}_${NAME}.txt"

    if (( RANDOM % 2 )); then
        A=q4
        B=q8
    else
        A=q8
        B=q4
    fi

    echo
    echo "========================================"
    echo "$NUM $NAME"
    echo "seed = $SEED"
    echo "========================================"

    echo "Running A..."
    run_model "$A" "$PROMPT" "$RAW/${NUM}_${NAME}_A.txt" "$SEED"

    echo "Running B..."
    run_model "$B" "$PROMPT" "$RAW/${NUM}_${NAME}_B.txt" "$SEED"

    make_blind \
        "$RAW/${NUM}_${NAME}_A.txt" \
        "$BLIND/${NUM}_${NAME}_A.txt"

    make_blind \
        "$RAW/${NUM}_${NAME}_B.txt" \
        "$BLIND/${NUM}_${NAME}_B.txt"

    echo -e "${NUM}_${NAME}\t${A}\t${B}\t${SEED}" >> "$MAPPING"

    echo "Done."
}

# Same seeds used originally
run_test 03 scheduling 51003
run_test 05 python_intervals 51005
run_test 07 ptbr 51007
run_test 08 architecture 51008

echo
echo "========================================"
echo " RERUN COMPLETE"
echo "========================================"
echo
echo "Blind outputs:"
echo "$BLIND"
echo
echo "Mapping:"
echo "$MAPPING"
echo
echo "DO NOT share mapping.tsv yet."
