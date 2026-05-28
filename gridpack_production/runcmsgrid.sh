#!/bin/bash
# Usage: ./runcmsgrid.sh [nevents] [seed]
#
# The decay card must be present in the same directory as this script,
# named exactly: decay.dec
# The build_all_gridpacks.sh wrapper handles copying the right card
# under that name before packaging the tarball.

NEVENTS=$1
SEED=$2
DECAY_CARD="decay.dec"  # fixed name — always baked into the tarball

if [ -z "$NEVENTS" ] || [ -z "$SEED" ]; then
  echo "Error: NEVENTS and SEED are required."
  echo "Usage: ./runcmsgrid.sh [nevents] [seed]"
  exit 1
fi

if [ ! -f "$DECAY_CARD" ]; then
  echo "Error: Decay card not found: $DECAY_CARD"
  echo "The tarball must contain a file named '$DECAY_CARD'."
  exit 1
fi

echo "=== runcmsgrid.sh ==="
echo "  NEVENTS    : $NEVENTS"
echo "  SEED       : $SEED"
echo "  DECAY CARD : $DECAY_CARD"
echo "====================="

# 1. Work on a copy of slight.in — never modify the original template
if [ ! -f slight.in ]; then
  echo "Error: slight.in not found in $(pwd)"
  exit 1
fi
cp slight.in slight.in.bak

# 2. Extract Energy and Calculate Gamma
COLL_E=$(grep "COLL_E" slight.in | awk '{print $3}')
if [ -z "$COLL_E" ]; then
  COLL_E=5362
  echo "Warning: COLL_E not found in slight.in, defaulting to $COLL_E GeV"
fi

GAMMA=$(echo "scale=2; ($COLL_E / 2) / 0.93827" | bc)
echo "Detected Collision Energy: $COLL_E GeV -> Calculated Gamma: $GAMMA"

# 3. Inject run parameters into slight.in
sed -i '/N_EVENTS/d'     slight.in
sed -i '/RND_SEED/d'     slight.in
sed -i '/BEAM_1_GAMMA/d' slight.in
sed -i '/BEAM_2_GAMMA/d' slight.in

echo "N_EVENTS = $NEVENTS"   >> slight.in
echo "RND_SEED = $SEED"      >> slight.in
echo "BEAM_1_GAMMA = $GAMMA" >> slight.in
echo "BEAM_2_GAMMA = $GAMMA" >> slight.in

# 4. Run STARlight
echo "Generating events with STARlight (Seed: $SEED)..."
(LD_LIBRARY_PATH=$(pwd)/lib:$LD_LIBRARY_PATH ./starlight > starlight.log)
SL_EXIT=$?

# Restore original template immediately
mv slight.in.bak slight.in

if [ $SL_EXIT -ne 0 ]; then
  echo "Error: STARlight failed. Check starlight.log."
  exit 1
fi

# 5. Run fdgen with the baked-in decay card
echo "Decaying with EvtGen (Decay card: $DECAY_CARD)..."
(
  export LD_LIBRARY_PATH=$(pwd)/lib:/lib64:/usr/lib64
  ./fdgen slight.out slight_decayed "$DECAY_CARD"
)
if [ $? -ne 0 ]; then
  echo "Error: fdgen failed."
  exit 1
fi

# 6. Convert to LHE
echo "Converting to LHE format..."
cmsEnergyDiv2=$(echo "$COLL_E / 2" | bc)

root -l -b -q "convert_SL2LHE.C+(\"slight_decayed.tx\", \"cmsgrid_final\", $cmsEnergyDiv2, $cmsEnergyDiv2)"
if [ $? -ne 0 ]; then
  echo "Error: ROOT conversion failed."
  exit 1
fi

# 7. Cleanup
rm -f starlight.log
rm -f slight.out
rm -f slight_decayed.out
rm -f slight_decayed.tx
rm -f slight_decayed.root

# 8. Final Validation
if [ -f cmsgrid_final.lhe ]; then
  echo ""
  echo "Success! cmsgrid_final.lhe is ready."
else
  echo "Error: LHE conversion failed — cmsgrid_final.lhe not produced."
  exit 1
fi
