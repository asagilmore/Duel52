#!/bin/bash
# Item 1b, part 2: 32c-24h-best playing itself at 4096 sims under the MOD-TRAPS rules
# (two-blast-four-bomb). This is the cross-ruleset control column.
#
# 32c-24h-best carries no rules stamp, so under a modded ruleset it is refused unless
# --allow-cross-ruleset is passed. It gets its own dataset, so the two rulesets never share a
# document. The traps rules ran ~7% slower in the 256-sim corpus, so ~29 h for 6,144.
#
# Resumable: finished chunks are skipped. If the time limit hits, resubmit unchanged.
#
#SBATCH --job-name=d52-an-best-traps
#SBATCH --account=stf
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32          # this is what gives one process 32 cores
#SBATCH --mem=32G
#SBATCH --time=01-12:00:00
#SBATCH --output=/gscratch/stf/asagil/duel52_outputs/13-analysis-best-traps/slurm-%j.out

# Find the checkout from wherever this was submitted: the submit directory if it lies inside
# one, else the directory the script itself lives in. ($0 is slurm's spooled copy, so scontrol
# is what knows the original path.) Stop here if neither is a checkout, rather than running on.
set -euo pipefail
REPO=$(git -C "$SLURM_SUBMIT_DIR" rev-parse --show-toplevel 2>/dev/null \
    || git -C "$(dirname "$(scontrol show job "$SLURM_JOB_ID" | sed -n 's/^ *Command=\([^ ]*\).*/\1/p')")" rev-parse --show-toplevel)
cd "$REPO" && source run-plans/2026-09-29/slurm/lib.sh
use_conda
OUT="$OUT_ROOT/13-analysis-best-traps"
banner

GAMES=${GAMES:-6144}
# Rendered at the end; see 10-analysis-best-canonical.sbatch for what card-value measures.
# The cross-ruleset permission carries over from the corpus, so card-value reads this
# checkpoint under the traps rules too.
CARD_VALUE_GAMES=${CARD_VALUE_GAMES:-2000}

exec python -m duel52.analysis \
    --dir "$OUT/analysis" --binary ./target/release/duel52 \
    --config configs/rules/two-blast-four-bomb.toml \
    --dataset two-blast-four-bomb-4096 \
    --agents netmcts:models/duel52-32c-24h-best.d52nn@4096 \
    --games "$GAMES" --chunk 1024 --seed 1 \
    --threads 32 --eval-batch 32 --encoding-slots 21 \
    --card-value-games "$CARD_VALUE_GAMES" --allow-cross-ruleset
