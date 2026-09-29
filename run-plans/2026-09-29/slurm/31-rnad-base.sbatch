#!/bin/bash
# Item 3: R-NaD on the base (shared-deck) rules, 24 h on one GPU with 40 GB.
# SUBMIT FROM THE `rnad` CHECKOUT: configs/rnad-24h-base.toml exists only on that branch.
#
# Same as 30-rnad-canonical.sbatch apart from the config. That config is
# `encoding_slots = 34` (the base deck's legality bound), which makes every tensor ~2.5x wider.
# The estimated peak is ~15 GB against the canonical run's measured 6 GB, well inside 40 GB.
# If it does run out of memory, set `learner_chunk = 12000` in the config and resubmit.
# Gradients accumulate exactly, so that changes speed only.
#
# Adjust --gres to the cluster's name for a 40 GB card, e.g. --gres=gpu:a100:1.
#
#SBATCH --job-name=d52-rnad-base
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --gres=gpu:1
#SBATCH --mem=64G
#SBATCH --time=1-03:00:00
#SBATCH --output=slurm-logs/%x-%j.out

# Find the checkout from wherever this was submitted: the submit directory if it lies inside
# one, else the directory the script itself lives in. ($0 is slurm's spooled copy, so scontrol
# is what knows the original path.) Stop here if neither is a checkout, rather than running on.
set -euo pipefail
REPO=$(git -C "$SLURM_SUBMIT_DIR" rev-parse --show-toplevel 2>/dev/null \
    || git -C "$(dirname "$(scontrol show job "$SLURM_JOB_ID" | sed -n 's/^ *Command=\([^ ]*\).*/\1/p')")" rev-parse --show-toplevel)
cd "$REPO" && source run-plans/2026-09-29/slurm/lib.sh
banner

CONFIG=configs/rnad-24h-base.toml
RUN_DIR=runs/rnad-24h-base

.venv/bin/python -m duel52.rnad check --config "$CONFIG"

EXTRA=()
if [ -f "$RUN_DIR/state.pt" ]; then
    echo "resuming $RUN_DIR"
    EXTRA+=(--resume)
else
    .venv/bin/python -m duel52.rnad bench --config "$CONFIG" --steps 5
fi

exec .venv/bin/python -m duel52.rnad run --config "$CONFIG" --run-dir "$RUN_DIR" "${EXTRA[@]}"
