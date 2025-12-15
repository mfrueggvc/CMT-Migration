#!/usr/bin/env bash
set -euo pipefail

# Always run from project root (directory containing this script)
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

# ---- Detect OS for MATLAB execution ----
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    echo "=== Windows detected - using alternative MATLAB execution ==="
    MATLAB_CMD="matlab.exe -nosplash -nodesktop -wait -r"
    IS_WINDOWS=true
else
    echo "=== Unix/Linux/Mac detected ==="
    MATLAB_CMD="matlab -batch"
    IS_WINDOWS=false
fi

# ---- 1) MATLAB preprocessing ----
echo "=== STEP 1: MATLAB preprocessing ==="

if [[ "$IS_WINDOWS" == true ]]; then
    # Windows: Use -r with explicit exit + log output
    matlab.exe -nosplash -nodesktop -wait -r "try; addpath(fullfile(pwd,'matlab','preprocessing')); run_preprocessing; catch e; fprintf('ERROR: %s\n', e.message); for i=1:length(e.stack); fprintf('  %s (line %d)\n', e.stack(i).file, e.stack(i).line); end; end; exit" 2>&1 | tee matlab_preprocessing.log
    
    # Check if preprocessing succeeded by verifying output files
    if [[ ! -f "$PROCESSED_DIR/GDP_SouthAmerica_1990_2019.csv" ]]; then
        echo "ERROR: Preprocessing failed - check matlab_preprocessing.log"
        echo "Attempting to display log:"
        cat matlab_preprocessing.log || echo "Could not read log file"
        exit 1
    fi
else
    # Unix/Mac: Use -batch (cleaner)
    $MATLAB_CMD "addpath(fullfile(pwd,'matlab','preprocessing')); run_preprocessing"
fi

echo "Preprocessing completed successfully."
echo

# ---- 2) MATLAB model ----
echo "=== STEP 2: MATLAB model ==="

if [[ "$IS_WINDOWS" == true ]]; then
    matlab.exe -nosplash -nodesktop -wait -r "try; addpath(fullfile(pwd,'matlab','model')); run_model; catch e; fprintf('ERROR: %s\n', e.message); for i=1:length(e.stack); fprintf('  %s (line %d)\n', e.stack(i).file, e.stack(i).line); end; end; exit" 2>&1 | tee matlab_model.log
    
    if [[ ! -f "$PRED_CSV" ]]; then
        echo "ERROR: Model execution failed - check matlab_model.log"
        cat matlab_model.log || echo "Could not read log file"
        exit 1
    fi
else
    $MATLAB_CMD "addpath(fullfile(pwd,'matlab','model')); run_model"
fi

echo "Model completed successfully."
echo

# Sanity checks
if [[ ! -f "$PRED_CSV" ]]; then
    echo "ERROR: Missing predictions file: $PRED_CSV"
    exit 1
fi

if [[ ! -f "$TRUTH_CSV" ]]; then
    echo "ERROR: Missing ground truth file: $TRUTH_CSV"
    echo "Please update TRUTH_CSV in run_project.sh (line 25)."
    exit 1
fi

# ---- 3) C comparison ----
echo "=== STEP 3: C comparison ==="

C_SRC="c/run_comparison.c"
C_BIN="c/run_comparison"

# Windows uses .exe extension
if [[ "$IS_WINDOWS" == true ]]; then
    C_BIN="c/run_comparison.exe"
fi

if [[ ! -f "$C_SRC" ]]; then
    echo "ERROR: Missing C source: $C_SRC"
    exit 1
fi

echo "Compiling C program..."
gcc -O2 -Wall -Wextra -o "$C_BIN" "$C_SRC" -lm

if [[ ! -f "$C_BIN" ]]; then
    echo "ERROR: Compilation failed"
    exit 1
fi

echo "Running comparison..."
"$C_BIN" "$TRUTH_CSV" "$PRED_CSV" "$OUT_CSV"
echo

if [[ ! -f "$EVAL_DIR/summary_out.csv" ]]; then
    echo "ERROR: Missing summary file: $EVAL_DIR/summary_out.csv"
    exit 1
fi

# ---- 4) MATLAB plots ----
echo "=== STEP 4: MATLAB plots ==="

if [[ "$IS_WINDOWS" == true ]]; then
    matlab.exe -nosplash -nodesktop -wait -r "try; addpath(fullfile(pwd,'matlab','plots')); run_plot_migration_results; catch e; fprintf('ERROR: %s\n', e.message); for i=1:length(e.stack); fprintf('  %s (line %d)\n', e.stack(i).file, e.stack(i).line); end; end; exit" 2>&1 | tee matlab_plots.log
else
    $MATLAB_CMD "addpath(fullfile(pwd,'matlab','plots')); run_plot_migration_results"
fi

echo "Plots generated successfully."
echo

# ---- Summary ----
echo "=== DONE ==="
echo "Processed data:   $PROCESSED_DIR"
echo "Predictions:      $PRED_DIR"
echo "Evaluation CSVs:  $EVAL_DIR (out.csv, summary_out.csv)"
echo "Plots:            $EVAL_DIR/Graphs"
echo
echo "Project completed successfully!"

if [[ "$IS_WINDOWS" == true ]]; then
    echo
    echo "Log files created:"
    echo "  - matlab_preprocessing.log"
    echo "  - matlab_model.log"
    echo "  - matlab_plots.log"
fi
