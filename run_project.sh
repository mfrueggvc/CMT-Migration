#!/usr/bin/env bash
set -euo pipefail

# Always run from project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== PROJECT ROOT ==="
pwd
echo

# ---- Folders ----
RAW_DIR="data/raw"
PROCESSED_DIR="data/processed"
GT_DIR="data/ground_truth"
PRED_DIR="results/predictions"
EVAL_DIR="results/evaluation"

mkdir -p "$PROCESSED_DIR" "$PRED_DIR" "$EVAL_DIR"

# ---- Files ----
TRUTH_CSV="$GT_DIR/NetMigration_SouthAmerica_1990_2019.csv"
PRED_CSV="$PRED_DIR/predicted_migration_all_countries.csv"
OUT_CSV="$EVAL_DIR/out.csv"

run_matlab() {
    local script_path="$1"
    local log_name="$2"

    echo "Executing MATLAB script: $script_path"

    # Windows (Git Bash)
    if command -v matlab.exe >/dev/null 2>&1; then
        matlab.exe -batch "cd('$(cygpath -w "$SCRIPT_DIR")'); addpath(genpath(pwd)); run('$script_path');" \
          2>&1 | tee "${log_name}.log"
        return
    fi

    # Linux / macOS / university machines (EXPECTED: matlab-2021b)
    if command -v matlab-2021b >/dev/null 2>&1; then
        matlab-2021b -batch "cd('$SCRIPT_DIR'); addpath(genpath(pwd)); run('$script_path');" \
          2>&1 | tee "${log_name}.log"
        return
    fi

    echo "ERROR: matlab-2021b not found in PATH."
    echo "This project requires MATLAB R2021b."
    echo "Please load MATLAB or add it to PATH, e.g.:"
    echo "  export PATH=\"/usr/local/MATLAB/R2021b/bin:\$PATH\""
    exit 1
}

# ---- 1) MATLAB preprocessing ----
echo "=== STEP 1: MATLAB preprocessing ==="
run_matlab "matlab/preprocessing/run_preprocessing.m" "matlab_preprocessing"

if [[ ! -f "$PROCESSED_DIR/GDP_SouthAmerica_1990_2019.csv" ]]; then
    echo "ERROR: Preprocessing failed - check matlab_preprocessing.log"
    cat matlab_preprocessing.log 2>/dev/null || echo "No log file"
    exit 1
fi

echo "✓ Preprocessing completed"
echo

# ---- 2) MATLAB model ----
echo "=== STEP 2: MATLAB model ==="
run_matlab "matlab/model/run_model.m" "matlab_model"

if [[ ! -f "$PRED_CSV" ]]; then
    echo "ERROR: Model failed - check matlab_model.log"
    cat matlab_model.log 2>/dev/null || echo "No log file"
    exit 1
fi

echo "✓ Model completed"
echo

# ---- 3) C comparison ----
echo "=== STEP 3: C comparison ==="

C_SRC="c/run_comparison.c"
C_BIN="c/run_comparison"

# Windows uses .exe
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    C_BIN="c/run_comparison.exe"
fi

if [[ ! -f "$C_SRC" ]]; then
    echo "ERROR: Missing $C_SRC"
    exit 1
fi

echo "Compiling C program..."
gcc -O2 -Wall -Wextra -o "$C_BIN" "$C_SRC" -lm

if [[ ! -f "$C_BIN" ]]; then
    echo "ERROR: Compilation failed"
    exit 1
fi

if [[ ! -f "$TRUTH_CSV" ]]; then
    echo "ERROR: Missing ground truth: $TRUTH_CSV"
    echo "Update TRUTH_CSV in run_project.sh (line 23)"
    exit 1
fi

echo "Running comparison..."
"$C_BIN" "$TRUTH_CSV" "$PRED_CSV" "$OUT_CSV"

if [[ ! -f "$EVAL_DIR/summary_out.csv" ]]; then
    echo "ERROR: Comparison failed"
    exit 1
fi

echo "✓ Comparison completed"
echo

# ---- 4) MATLAB plots ----
echo "=== STEP 4: MATLAB plots ==="
run_matlab "matlab/plots/run_plot_migration_results.m" "matlab_plots"

echo "✓ Plots generated"
echo

# ---- Summary ----
echo "=== ✓ PROJECT COMPLETED SUCCESSFULLY ==="
echo ""
echo "Output files:"
echo "  • Processed data:  $PROCESSED_DIR/"
echo "  • Predictions:     $PRED_DIR/"
echo "  • Evaluation:      $EVAL_DIR/"
echo "  • Graphs:          $EVAL_DIR/Graphs/"
echo ""
echo "Log files: matlab_preprocessing.log, matlab_model.log, matlab_plots.log"