#!/usr/bin/env bash
set -euo pipefail

# Always run from project root (directory containing this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== PROJECT ROOT ==="
pwd
echo

# ---- Folders (do not rename here; rename in repo if needed) ----
RAW_DIR="data/raw"
PROCESSED_DIR="data/processed"
GT_DIR="data/ground_truth"
PRED_DIR="results/predictions"
EVAL_DIR="results/evaluation"

mkdir -p "$PROCESSED_DIR" "$PRED_DIR" "$EVAL_DIR"

# ---- Files (YOU must set truth filename) ----
# Ground truth (wide format: Year,Argentina,...)
TRUTH_CSV="$GT_DIR/<<TRUTH_FILE_NAME.csv>>"

# Model output (created by run_model.m)
PRED_CSV="$PRED_DIR/predicted_migration_all_countries.csv"

# C comparator outputs
OUT_CSV="$EVAL_DIR/out.csv"
# summary will be auto-created by C as: $EVAL_DIR/summary_out.csv

# ---- 1) MATLAB preprocessing ----
echo "=== STEP 1: MATLAB preprocessing ==="
matlab -batch "addpath(fullfile(pwd,'matlab','preprocessing')); run_preprocessing"
echo

# ---- 2) MATLAB model ----
echo "=== STEP 2: MATLAB model ==="
matlab -batch "addpath(fullfile(pwd,'matlab','model')); run_model"
echo

# Sanity checks
if [[ ! -f "$PRED_CSV" ]]; then
  echo "ERROR: Missing predictions file: $PRED_CSV"
  exit 1
fi

if [[ ! -f "$TRUTH_CSV" ]]; then
  echo "ERROR: Missing ground truth file: $TRUTH_CSV"
  echo "Fix TRUTH_CSV in run_project.sh (<<TRUTH_FILE_NAME.csv>>)."
  exit 1
fi

# ---- 3) C comparison ----
echo "=== STEP 3: C comparison ==="

C_SRC="c/run_comparison.c"
C_BIN="c/run_comparison"

if [[ ! -f "$C_SRC" ]]; then
  echo "ERROR: Missing C source: $C_SRC"
  exit 1
fi

gcc -O2 -Wall -Wextra -o "$C_BIN" "$C_SRC" -lm

"$C_BIN" "$TRUTH_CSV" "$PRED_CSV" "$OUT_CSV"
echo

if [[ ! -f "$EVAL_DIR/summary_out.csv" ]]; then
  echo "ERROR: Missing summary file: $EVAL_DIR/summary_out.csv"
  exit 1
fi

# ---- 4) MATLAB plots ----
echo "=== STEP 4: MATLAB plots ==="
matlab -batch "addpath(fullfile(pwd,'matlab','plots')); run_plots"
echo

echo "=== DONE ==="
echo "Processed data:   $PROCESSED_DIR"
echo "Predictions:      $PRED_DIR"
echo "Evaluation CSVs:  $EVAL_DIR (out.csv, summary_out.csv)"
echo "Plots:            $EVAL_DIR/Generated_Graphs (or whatever your run_plots uses)"
