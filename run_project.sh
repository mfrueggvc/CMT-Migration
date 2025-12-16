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
    echo "=== Windows detected - locating MATLAB automatically ==="
    IS_WINDOWS=true

    
    MATLAB_EXE_WIN="$(cmd.exe /c "where matlab 2>nul" | head -n 1 | tr -d '\r')"

    
    if [[ -z "$MATLAB_EXE_WIN" ]]; then
        MATLAB_EXE_WIN="$(cmd.exe /c "dir /b /s \"C:\Program Files\MATLAB\R*\bin\matlab.exe\" 2>nul" | head -n 1 | tr -d '\r')"
    fi
    if [[ -z "$MATLAB_EXE_WIN" ]]; then
        MATLAB_EXE_WIN="$(cmd.exe /c "dir /b /s \"C:\Program Files (x86)\MATLAB\R*\bin\matlab.exe\" 2>nul" | head -n 1 | tr -d '\r')"
    fi

    if [[ -z "$MATLAB_EXE_WIN" ]]; then
        echo "ERROR: MATLAB not found. Install MATLAB or add it to Windows PATH."
        exit 1
    fi

    echo "Using MATLAB: $MATLAB_EXE_WIN"

else
    echo "=== Unix/Linux/Mac detected ==="
    IS_WINDOWS=false
fi


# ---- 1) MATLAB preprocessing ----
echo "=== STEP 1: MATLAB preprocessing ==="

if [[ "$IS_WINDOWS" == true ]]; then
    # Windows: Use -r with explicit exit + log output
    cmd.exe /c "\"$MATLAB_EXE_WIN\" -batch \"cd('$(cygpath -w "$SCRIPT_DIR" | tr -d '\r' | sed 's/\\/\\\\/g')'); addpath(genpath(pwd)); run('matlab/preprocessing/run_preprocessing.m');\""

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
   cmd.exe /c "\"$MATLAB_EXE_WIN\" -batch \"cd('$(cygpath -w "$SCRIPT_DIR" | tr -d '\r' | sed 's/\\/\\\\/g')'); addpath(genpath(pwd)); run('matlab/model/run_model.m');\""

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
   cmd.exe /c "\"$MATLAB_EXE_WIN\" -batch \"cd('$(cygpath -w "$SCRIPT_DIR" | tr -d '\r' | sed 's/\\/\\\\/g')'); addpath(genpath(pwd)); run('matlab/plots/run_plot_migration_results.m');\""

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
