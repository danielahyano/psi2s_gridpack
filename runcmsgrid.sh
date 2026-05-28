#!/bin/bash
# Usage: ./runcmsgrid.sh [nevents] [seed]

NEVENTS=$1
SEED=$2
MODE=0 # mode 0 is for muon, 1 is electron


# 1. Environment Setup
#export LD_LIBRARY_PATH=$(pwd)/lib:$LD_LIBRARY_PATH
#export EvtPDL=$(pwd)/evt.pdl
# 2. Extract Energy and Calculate Gamma
# This looks for COLL_E in your slight.in and pulls the number
COLL_E=$(grep "COLL_E" slight.in | awk '{print $3}')

# If COLL_E isn't found, default to 5362
if [ -z "$COLL_E" ]; then
  COLL_E=5362
fi

# Calculate Gamma: (COLL_E / 2) / proton_mass
# using 'bc' for floating point math
GAMMA=$(echo "scale=2; ($COLL_E / 2) / 0.93827" | bc)
echo "Detected Collision Energy: $COLL_E GeV -> Calculated Gamma: $GAMMA"

# 3. Update slight.in 
# 3. Create a CLEAN config for this run
# We strip out the problematic variables and re-add them clearly
sed -i '/N_EVENTS/d' slight.in
sed -i '/RND_SEED/d' slight.in
sed -i '/BEAM_1_GAMMA/d' slight.in
sed -i '/BEAM_2_GAMMA/d' slight.in

echo "N_EVENTS = $NEVENTS" >> slight.in
echo "RND_SEED = $SEED" >> slight.in
echo "BEAM_1_GAMMA = $GAMMA" >> slight.in
echo "BEAM_2_GAMMA = $GAMMA" >> slight.in
# 4. Run STARlight
echo "Generating events with STARlight (Seed: $SEED)..."
#./starlight > starlight.log
(LD_LIBRARY_PATH=$(pwd)/lib:$LD_LIBRARY_PATH ./starlight > starlight.log)
# 5. Run fdgen (Decay)
# We take 'slight.out' and produce 'slight_decayed.out'
echo "Decaying with EvtGen (Mode: $MODE)..."
#./fdgen slight.out slight_decayed $MODE
(
   export LD_LIBRARY_PATH=$(pwd)/lib:/lib64:/usr/lib64
   ./fdgen slight.out slight_decayed $MODE
)
# 6. Convert to LHE
echo "Converting to LHE format..."
cmsEnergyDiv2=$COLL_E/2

# Note: convert_SL2LHE.C needs to be in your gridpack folder
# It will read 'slight_decayed.out' and create 'cmsgrid_final.lhe'
root -l -b -q "convert_SL2LHE.C+(\"slight_decayed.tx\", \"cmsgrid_final\", $cmsEnergyDiv2, $cmsEnergyDiv2)"

rm -f starlight.log
rm -f slight.out
rm -f slight_decayed.out
rm -f slight_decayed.tx
rm -f slight_decayed.root
# DO NOT delete cmsgrid_final.lhe — that's your prize!
# 7. Final Validation
if [ -f cmsgrid_final.lhe ]; then
    echo "Success! cmsgrid_final.lhe is ready."
else
    echo "Error: LHE conversion failed."
    exit 1
fi
