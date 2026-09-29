#!/bin/bash
# Item 1b, part 2: the mod-traps agent (traps-32c-24h-gen063) playing itself at 4096 sims
# under its OWN rules (two-blast-four-bomb). No cross-ruleset flag, since this is the game it
# was trained on. ~29 h for 6,144, as for job 13.
#
# Resumable: finished chunks are skipped. If the time limit hits, resubmit unchanged.
#
#SBATCH --job-name=d52-an-traps-traps
#SBATCH --account=stf
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32          # this is what gives one process 32 cores
#SBATCH --mem=32G
#SBATCH --time=01-12:00:00
#SBATCH --output=/gscratch/stf/asagil/duel52_outputs/14-analysis-traps-traps/slurm-%j.out

cd "$SLURM_SUBMIT_DIR" && source run-plans/2026-09-29/slurm/lib.sh
use_conda
OUT="$OUT_ROOT/14-analysis-traps-traps"
banner

GAMES=${GAMES:-6144}
# Rendered at the end; see 10-analysis-best-canonical.sbatch for what card-value measures.
CARD_VALUE_GAMES=${CARD_VALUE_GAMES:-2000}

exec python -m duel52.analysis \
    --dir "$OUT/analysis" --binary ./target/release/duel52 \
    --config configs/rules/two-blast-four-bomb.toml \
    --dataset two-blast-four-bomb-4096 \
    --agents netmcts:models/duel52-traps-32c-24h-gen063.d52nn@4096 \
    --games "$GAMES" --chunk 1024 --seed 1 \
    --threads 32 --eval-batch 32 --encoding-slots 21 \
    --card-value-games "$CARD_VALUE_GAMES"
