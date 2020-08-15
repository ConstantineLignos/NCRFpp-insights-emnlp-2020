#!/usr/bin/env bash
set -euo pipefail

LOGDIR=exp_logs
OUT=$LOGDIR/merged.tsv
# Write to a temp path that doesn't end in TSV first to avoid matching the input glob
TMP_OUT=$OUT.tmp

rm -f "$OUT"
# Take the header from the first TSV
first_file=$(find "$LOGDIR" -name "*.tsv" | head -n 1)
python mark_best_epoch.py "$first_file" | head -n 1 > "$TMP_OUT"
for f in "$LOGDIR"/*.tsv; do
  python mark_best_epoch.py "$f" | tail -n +2  >> "$TMP_OUT"
done
mv "$TMP_OUT" "$OUT"
