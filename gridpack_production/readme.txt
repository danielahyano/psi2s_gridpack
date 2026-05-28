###############################################################################
# PSI(2S) GRIDPACK PRODUCTION GUIDE
# -----------------------------------------------------------------------------
# This README explains how to configure, run, and package the STARlight+EvtGen 
# pipeline for CMS Monte Carlo production.
###############################################################################

1. DIRECTORY STRUCTURE
----------------------
Ensure your working directory contains:
- starlight (Binary)
- fdgen (Binary)
- runcmsgrid.sh (The production script)
- convert_SL2LHE.C (ROOT macro)
- mini.pdl (Particle Data List)
- DECAYMU.DEC / DECAYE.DEC (Decay cards)
- lib/ (Directory containing necessary shared libraries)
- configs/ (Directory containing slight_coherent.in, slight_incoherent.in)

2. CONFIGURING THE PHYSICS (slight.in)
--------------------------------------
The script 'runcmsgrid.sh' looks for a file specifically named 'slight.in'.
The script will AUTOMATICALLY calculate the Gamma energy based on COLL_E.

STEP-BY-STEP:
a) Copy your template: cp configs/slight_coherent.in ./slight.in
b) Ensure the 'slight.in' contains the line: COLL_E = 5362
c) The script will handle N_EVENTS, RND_SEED, and BEAM_1_GAMMA/BEAM_2_GAMMA.

3. CHANGING DECAY MODES (Muon vs. Electron)
-------------------------------------------
The decay channel is controlled by a hardcoded variable in 'runcmsgrid.sh'.

STEP-BY-STEP:
a) Open 'runcmsgrid.sh'.
b) Locate the variable: MODE=0
c) Change the integer:
   - MODE=0 for DIMUON (Decays using DECAYMU.DEC)
   - MODE=1 for DIELECTRON (Decays using DECAYE.DEC)
d) Save the file.

4. CREATING THE TARBALL
-----------------------
For CMS Grid production, compress the directory into a .tar.gz file.
IMPORTANT: Exclude logs and old outputs to keep the size small.

Run this command:
tar --exclude='*.out' --exclude='*.log' --exclude='*.lhe' --exclude='*.tar.gz' --exclude='configs' -czvf psi2s_coh_mumu_v1.tar.gz ./*

5. RUNNING MANUALLY (For Testing)
---------------------------------
To test before zipping:
   ./runcmsgrid.sh [NEVENTS] [RANDOM_SEED]

Example:
   ./runcmsgrid.sh 100 1

Check 'cmsgrid_final.lhe' afterward to verify event counts.

6. CMSSW INTEGRATION
--------------------
In your Python fragment:
- Set 'numberOfParameters = cms.uint32(1)' (for NEVENTS) or (2) if passing SEED.
- Point the 'args' path to your new .tar.gz file.
###############################################################################
