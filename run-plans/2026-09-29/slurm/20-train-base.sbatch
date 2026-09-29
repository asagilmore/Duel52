#!/bin/bash
# Item 2: the base (shared-deck) rules, 24 h from scratch on 32 cores.
# configs/train-24h-32c-base.toml has the reasoning.
#
# **Resubmitting.** The loop saves each game as it finishes, and on SIGTERM (which slurm sends
# at the time limit, or on preemption) it stops at the next safe point. Resubmitting continues
# INSIDE the interrupted generation, bit-for-bit. The script adds --resume by itself when the
# run directory already holds a run.
#
# ⚠️ `hours` counts from the start of EACH invocation, so a resumed run gets another full 24 h
# unless told otherwise. On a resubmit, pass what is left:
#     sbatch --export=ALL,HOURS=9.5 run-plans/2026-09-29/slurm/20-train-base.sbatch
# Elapsed so far is the sum of the per-generation `seconds` in
# /gscratch/stf/asagil/duel52_outputs/20-train-base/base-32c/log.jsonl
# (the plan has a one-liner for it).
#
# The time limit is 36 h, not 24. The loop checks the clock only between generations, and the
# mod-traps run under the same config logged ~25.4 h of generations. Past 24 h it just finishes
# the one in flight.
#
#SBATCH --job-name=d52-train-base
#SBATCH --account=stf
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32          # this is what gives one process 32 cores
#SBATCH --mem=32G
#SBATCH --time=01-12:00:00
#SBATCH --output=/gscratch/stf/asagil/duel52_outputs/20-train-base/slurm-%j.out

# Find the checkout from wherever this was submitted: the submit directory if it lies inside
# one, else the directory the script itself lives in. ($0 is slurm's spooled copy, so scontrol
# is what knows the original path.) Stop here if neither is a checkout, rather than running on.
set -euo pipefail
REPO=$(git -C "$SLURM_SUBMIT_DIR" rev-parse --show-toplevel 2>/dev/null \
    || git -C "$(dirname "$(scontrol show job "$SLURM_JOB_ID" | sed -n 's/^ *Command=\([^ ]*\).*/\1/p')")" rev-parse --show-toplevel)
cd "$REPO" && source run-plans/2026-09-29/slurm/lib.sh
use_conda
OUT="$OUT_ROOT/20-train-base"
banner

CONFIG=configs/train-24h-32c-base.toml
RUN_DIR="$OUT/base-32c"

python -m duel52.train check --config "$CONFIG"

EXTRA=()
# The trainer refuses a non-empty run directory without --resume, so that is the test.
if [ -d "$RUN_DIR" ] && [ -n "$(ls -A "$RUN_DIR")" ]; then
    echo "resuming $RUN_DIR"
    EXTRA+=(--resume)
fi
if [ -n "${HOURS:-}" ]; then
    EXTRA+=(--hours "$HOURS")
fi

exec python -m duel52.train run --config "$CONFIG" --run-dir "$RUN_DIR" "${EXTRA[@]}"
