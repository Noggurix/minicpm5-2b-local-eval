#!/usr/bin/env fish

if not set -q MINICPM5_BENCH_ROOT
    echo "ERROR: set MINICPM5_BENCH_ROOT to the local benchmark workspace."
    exit 1
end

set ROOT "$MINICPM5_BENCH_ROOT/llama.cpp"
cd $ROOT; or exit 1

set BENCH ./build-cpu/bin/llama-bench
set RUN_ID (date +%Y%m%d-%H%M%S)
set OUT "$MINICPM5_BENCH_ROOT/results/$RUN_ID"
set ALL $OUT/ALL_RESULTS.md

mkdir -p $OUT

echo "========================================"
echo " MiniCPM5-2B benchmark suite"
echo " Run: $RUN_ID"
echo "========================================"

# Avoid a competing model runtime.
if pgrep -x ollama >/dev/null
    echo
    echo "ERROR: Ollama is still running."
    echo "Stop it first with: sudo systemctl stop ollama"
    exit 1
end

# Free space: abort if less than ~12 GiB is available.
set FREE_KB (df -Pk ~ | awk 'NR==2 {print $4}')
if test $FREE_KB -lt 12582912
    echo
    echo "ERROR: less than ~12 GiB is available."
    df -h ~
    exit 1
end

# Environment metadata.
begin
    echo "# MiniCPM5-2B benchmark suite"
    echo
    echo "Run: "(date -Is)
    echo
    echo '```text'
    echo "=== LLAMA.CPP ==="
    $ROOT/build-cpu/bin/llama-cli --version
    echo
    echo "Git tag: "(git describe --tags --exact-match 2>/dev/null)
    echo "Git commit: "(git rev-parse HEAD)
    echo
    echo "=== CPU ==="
    lscpu | grep -E 'Model name|CPU\(s\)|Core|Thread'
    echo
    echo "=== GOVERNOR ==="
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null
    echo
    echo "=== MEMORY ==="
    free -h
    echo
    echo "=== DISK ==="
    df -h ~
    echo '```'
    echo
end > $ALL

function run_case
    set LABEL $argv[1]
    set REPO  $argv[2]
    set QUANT $argv[3]

    echo
    echo "========================================"
    echo " START: $LABEL"
    echo " "(date -Is)
    echo "========================================"

    begin
        echo
        echo "## $LABEL"
        echo
        echo "Started: "(date -Is)
        echo
    end >> $ALL

    $BENCH \
        -hf "$REPO:$QUANT" \
        -p 512 \
        -n 128 \
        -t 2 \
        -r 7 \
        --delay 2 \
        -o md \
        2>&1 | tee "$OUT/$LABEL.log" | tee -a $ALL

    set RC $pipestatus[1]

    echo >> $ALL
    echo "Exit code: $RC" >> $ALL
    echo "Finished: "(date -Is) >> $ALL
    echo >> $ALL

    if test $RC -ne 0
        echo "WARNING: $LABEL failed (exit $RC). Continuing."
    else
        echo "DONE: $LABEL"
    end

    # Ensure complete separation between consecutive processes.
    sleep 10
end


# ============================================================
# 1. Known official baseline.
#    It should already be cached.
# ============================================================

run_case \
    official-Q4_K_M \
    openbmb/MiniCPM5-2B-GGUF \
    Q4_K_M


# ============================================================
# 2. Same Q4_K_M format, but using the Bartowski/imatrix quant.
#    Useful for comparison with the official Q4.
# ============================================================

run_case \
    bartowski-Q4_K_M \
    bartowski/MiniCPM5-2B-GGUF \
    Q4_K_M


# ============================================================
# 3. Smaller alternative ~4-bit quantization.
# ============================================================

run_case \
    bartowski-IQ4_XS \
    bartowski/MiniCPM5-2B-GGUF \
    IQ4_XS


# ============================================================
# 4. Middle of the quantization range.
# ============================================================

run_case \
    bartowski-Q5_K_M \
    bartowski/MiniCPM5-2B-GGUF \
    Q5_K_M


# ============================================================
# 5. High fidelity / possible sweet spot.
# ============================================================

run_case \
    bartowski-Q6_K \
    bartowski/MiniCPM5-2B-GGUF \
    Q6_K


# ============================================================
# 6. Much more aggressive quantization.
#    Measures the throughput gain below Q4.
# ============================================================

run_case \
    bartowski-Q3_K_M \
    bartowski/MiniCPM5-2B-GGUF \
    Q3_K_M


# ============================================================
# 7. Official near-lossless quantization.
#    It should already be cached.
# ============================================================

run_case \
    official-Q8_0 \
    openbmb/MiniCPM5-2B-GGUF \
    Q8_0


# ============================================================
# 8. Q6_K context scaling.
# ============================================================

echo
echo "========================================"
echo " START: Q6_K context scaling"
echo " "(date -Is)
echo "========================================"

begin
    echo
    echo "## bartowski-Q6_K-context"
    echo
    echo "Started: "(date -Is)
    echo
end >> $ALL

$BENCH \
    -hf bartowski/MiniCPM5-2B-GGUF:Q6_K \
    -p 2048,4096 \
    -n 128 \
    -t 2 \
    -r 5 \
    --delay 2 \
    -o md \
    2>&1 | tee "$OUT/bartowski-Q6_K-context.log" | tee -a $ALL

set RC $pipestatus[1]

echo >> $ALL
echo "Exit code: $RC" >> $ALL
echo "Finished: "(date -Is) >> $ALL


# ============================================================
# FINAL
# ============================================================

echo
echo "========================================"
echo " SUITE COMPLETE"
echo " "(date -Is)
echo "========================================"
echo
echo "Individual results:"
echo "$OUT"
echo
echo "Aggregate file:"
echo "$ALL"

begin
    echo
    echo "# Final system state"
    echo
    echo '```text'
    free -h
    echo
    sensors 2>/dev/null
    echo '```'
end >> $ALL
