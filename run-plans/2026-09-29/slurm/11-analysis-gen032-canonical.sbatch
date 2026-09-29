#!/bin/bash
# Item 1a: lane-gen032 playing itself at 4096 sims, canonical rules.
#
# lane 128x3 has half the trunk of the 128x6 nets, so it runs about twice as fast. That is
# ~0.13 games/sec, and 12,288 games is ~26 h in twelve ~2.2 h chunks. It shares deals with the
# other split-4096 columns up to seed 3,072, since every job starts at seed 1.
#
# Resumable: finished chunks are skipped. If the time limit hits, resubmit unchanged.
#
#SBATCH --job-name=d52-an-gen032-canon
#SBATCH --account=stf
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32          # this is what gives one process 32 cores
#SBATCH --mem=32G
#SBATCH --time=01-12:00:00
#SBATCH --output=/gscratch/stf/asagil/duel52_outputs/11-analysis-gen032-canonical/slurm-%j.out

# Find the checkout from wherever this was submitted: the submit directory if it lies inside
# one, else the directory the script itself lives in. ($0 is slurm's spooled copy, so scontrol
# is what knows the original path.) Stop here if neither is a checkout, rather than running on.
set -euo pipefail
REPO=$(git -C "$SLURM_SUBMIT_DIR" rev-parse --show-toplevel 2>/dev/null \
    || git -C "$(dirname "$(scontrol show job "$SLURM_JOB_ID" | sed -n 's/^ *Command=\([^ ]*\).*/\1/p')")" rev-parse --show-toplevel)
cd "$REPO" && source run-plans/2026-09-29/slurm/lib.sh
use_conda
OUT="$OUT_ROOT/11-analysis-gen032-canonical"
banner

GAMES=${GAMES:-12288}
# Rendered at the end; see 10-analysis-best-canonical.sbatch for what card-value measures.
CARD_VALUE_GAMES=${CARD_VALUE_GAMES:-2000}

exec python -m duel52.analysis \
    --dir "$OUT/analysis" --binary ./target/release/duel52 \
    --dataset split-4096 \
    --agents netmcts:models/duel52-split-lane-gen032.d52nn@4096 \
    --games "$GAMES" --chunk 1024 --seed 1 \
    --threads 32 --eval-batch 32 --encoding-slots 21 \
    --card-value-games "$CARD_VALUE_GAMES"
