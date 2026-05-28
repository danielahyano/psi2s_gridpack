#!/bin/bash
# Usage: ./build_all_gridpacks.sh
#
# For each job, copies the right slight.in and decay card (renamed to
# decay.dec) into gridpack_production/, then packages the tarball.
# runcmsgrid.sh always looks for a fixed filename 'decay.dec'.
#
# Directory layout expected:
#   psi2s_gridpack_work/
#   ├── build_all_gridpacks.sh
#   ├── configs/
#   │   ├── slight_coherent.in
#   │   ├── slight_incoherent.in
#   │   └── ...
#   ├── decay_cards/
#   │   ├── DECAYMU.DEC
#   │   ├── DECAYEL.DEC
#   │   ├── my_custom.DEC
#   │   └── ...
#   ├── gridpack_production/     (binaries, scripts, lib/)
#   └── productions/             (output tarballs)

set -e

###############################################################################
# CONFIGURE YOUR JOBS HERE
# Format: "slight_config:decay_card:output_name"
###############################################################################
JOBS=(
  "slight.in:DECAYMU.DEC:psi2s_coh_mumu_v1"
)
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRODUCTION_DIR="$SCRIPT_DIR/gridpack_production"
CONFIGS_DIR="$SCRIPT_DIR/configs"
DECAY_DIR="$SCRIPT_DIR/decay_cards"
OUTPUT_DIR="$SCRIPT_DIR/productions"

mkdir -p "$OUTPUT_DIR"

for DIR in "$PRODUCTION_DIR" "$CONFIGS_DIR" "$DECAY_DIR"; do
  if [ ! -d "$DIR" ]; then
    echo "Error: Required directory not found: $DIR"
    exit 1
  fi
done

###############################################################################
TOTAL=${#JOBS[@]}
COUNT=0
FAILED=()

for JOB in "${JOBS[@]}"; do
  IFS=':' read -r SLIGHT DECAY NAME <<< "$JOB"
  COUNT=$((COUNT + 1))

  echo ""
  echo "############################################################"
  echo "  Job $COUNT / $TOTAL : $NAME"
  echo "  Config     : $SLIGHT"
  echo "  Decay card : $DECAY  ->  baked in as 'decay.dec'"
  echo "############################################################"

  if [ ! -f "$CONFIGS_DIR/$SLIGHT" ]; then
    echo "Error: Config not found: $CONFIGS_DIR/$SLIGHT — skipping."
    FAILED+=("$NAME")
    continue
  fi

  if [ ! -f "$DECAY_DIR/$DECAY" ]; then
    echo "Error: Decay card not found: $DECAY_DIR/$DECAY — skipping."
    FAILED+=("$NAME")
    continue
  fi

  # Copy slight.in template
  cp "$CONFIGS_DIR/$SLIGHT" "$PRODUCTION_DIR/slight.in"

  # Copy decay card under the fixed name that runcmsgrid.sh expects
  cp "$DECAY_DIR/$DECAY" "$PRODUCTION_DIR/decay.dec"

  echo "Copied $SLIGHT -> slight.in"
  echo "Copied $DECAY  -> decay.dec"

  # Package tarball
  TARBALL="$OUTPUT_DIR/${NAME}.tar.gz"
  tar \
    --exclude='*.out' \
    --exclude='*.log' \
    --exclude='*.lhe' \
    --exclude='*.tar.gz' \
    -czvf "$TARBALL" \
    -C "$PRODUCTION_DIR" \
    .

  if [ $? -eq 0 ]; then
    SIZE=$(du -sh "$TARBALL" | cut -f1)
    echo ">>> Created: $TARBALL ($SIZE)"
  else
    echo ">>> Error: tarball creation failed for $NAME"
    FAILED+=("$NAME")
  fi

done

###############################################################################
echo ""
echo "============================================================"
echo "  DONE: $COUNT jobs processed"
echo "  Output directory: $OUTPUT_DIR"
echo ""
ls -lh "$OUTPUT_DIR"
echo ""

if [ ${#FAILED[@]} -gt 0 ]; then
  echo "  FAILED jobs:"
  for F in "${FAILED[@]}"; do
    echo "    - $F"
  done
  exit 1
else
  echo "  All jobs completed successfully."
fi
echo "============================================================"
