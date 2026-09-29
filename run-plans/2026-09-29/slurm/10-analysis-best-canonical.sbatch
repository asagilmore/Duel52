#!/bin/bash
# Item 1a/1b: 32c-24h-best playing itself at 4096 sims, canonical rules. 1a and 1b share this corpus.
#
# Estimated ~0.064 games/sec on 32 cores, so 6,144 games is ~27 h. Six chunks of 1,024, each
# ~4.4 h, because every game of a chunk is in flight at once and they finish together.
# See the run plan for the derivation.
#
# Resumable: a finished chunk has a meta.json and is skipped on a re-run, and a killed chunk
# has none and is replayed. If the time limit hits, resubmit this file unchanged. For MORE
# games afterwards, raise GAMES and resubmit, and only the new chunks are played.
#
#SBATCH --job-name=d52-an-best-canon
#SBATCH --account=stf
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32          # this is what gives one process 32 cores
#SBATCH --mem=32G
#SBATCH --time=01-12:00:00
#SBATCH --output=/gscratch/stf/asagil/duel52_outputs/10-analysis-best-canonical/slurm-%j.out

# Find the checkout from wherever this was submitted: the submit directory if it lies inside
# one, else the directory the script itself lives in. ($0 is slurm's spooled copy, so scontrol
# is what knows the original path.) Stop here if neither is a checkout, rather than running on.
set -euo pipefail
REPO=$(git -C "$SLURM_SUBMIT_DIR" rev-parse --show-toplevel 2>/dev/null \
    || git -C "$(dirname "$(scontrol show job "$SLURM_JOB_ID" | sed -n 's/^ *Command=\([^ ]*\).*/\1/p')")" rev-parse --show-toplevel)
cd "$REPO" && source run-plans/2026-09-29/slurm/lib.sh
use_conda
OUT="$OUT_ROOT/10-analysis-best-canonical"
banner

GAMES=${GAMES:-6144}

# --chunk 1024 = 32 threads x 32 in flight, so the eval batch is never clamped (CLAUDE.md,
# "Size the chunk so the batch is not clamped").
#
# --card-value-games: after the last chunk, the document is rendered, and `duel52 card-value`
# runs once per checkpoint in the dataset. It swaps each rank into a fixed position's hand and
# reads the value head. It uses its own positions and no search, so it does not depend on this
# corpus or on @4096, and it takes minutes, not hours. 2,000 positions rather than the default
# 400 roughly halves its error bars. The laptop render must pass the same number, or it
# recomputes at 400.
CARD_VALUE_GAMES=${CARD_VALUE_GAMES:-2000}

exec python -m duel52.analysis \
    --dir "$OUT/analysis" --binary ./target/release/duel52 \
    --dataset split-4096 \
    --agents netmcts:models/duel52-32c-24h-best.d52nn@4096 \
    --games "$GAMES" --chunk 1024 --seed 1 \
    --threads 32 --eval-batch 32 --encoding-slots 21 \
    --card-value-games "$CARD_VALUE_GAMES"
