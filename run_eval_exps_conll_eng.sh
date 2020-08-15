#!/usr/bin/env bash
set -euo pipefail

trap "exit" INT TERM
trap "kill 0" EXIT

mkdir -p exp_{logs,models}

export OMP_NUM_THREADS=1
configfile=$1
for seed in {0..9}; do
  name=$(basename "${configfile%.config}")
  logbase=exp_logs/${name}.${seed}
  logfile=${logbase}.log
  tsv=${logbase}.tsv
  model_prefix=exp_models/${name}.${seed}
  python -u main.py --cpu --config "$configfile" --random-seed "$seed" --output-tsv "$tsv" --model-prefix "$model_prefix" &> "$logfile" &
done
wait
