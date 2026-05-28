# \psi(2S) Gridpack Production Guide
### STARlight + EvtGen pipeline for CMS Monte Carlo production.
*Last updated: May 2026*

---

## 1. Directory Structure

Your working directory (psi2s_gridpack_work/) should look like this:

```
psi2s_gridpack_work/
├── build_all_gridpacks.sh     # Master build script — run this to produce tarballs
├── test_gridpack.sh           # Test script — untars and runs a gridpack locally
├── README.md                  # This file
│
├── configs/                   # Your slight.in templates (one per physics config)
│   ├── slight_coherent.in
│   ├── slight_incoherent.in
│   └── ...
│
├── decay_cards/               # Your .DEC decay cards (one per decay mode)
│   ├── DECAYMU.DEC
│   ├── DECAYEL.DEC
│   └── my_custom.DEC
│
├── gridpack_production/       # Binaries and scripts — the contents of each tarball
│   ├── runcmsgrid.sh          # Production run script (called by CMS)
│   ├── starlight              # STARlight binary
│   ├── fdgen                  # EvtGen decay binary
│   ├── convert_SL2LHE.C       # ROOT macro for LHE conversion
│   ├── evt.pdl                # Particle Data List
│   ├── lib/                   # Shared libraries
│   └── slight.in              # Overwritten at build time — do not edit manually
│
└── productions/               # Output tarballs (created automatically)
    ├── psi2s_coh_mumu_v1.tar.gz
    ├── psi2s_coh_elel_v1.tar.gz
    └── ...
```

---

## 2. How It Works

Each gridpack tarball is a self-contained package. When CMS unpacks and runs it, it calls:

```
./runcmsgrid.sh [nevents] [seed]
```

Everything the script needs is baked into the tarball:
* slight.in: The physics configuration for STARlight.
* decay.dec: The decay card for EvtGen (always this fixed filename).
* All binaries: starlight, fdgen, convert_SL2LHE.C, lib/.

Note: The variation between gridpacks (different configs, different decay modes) is handled entirely by build_all_gridpacks.sh before packaging. runcmsgrid.sh itself is always identical across all tarballs.

---

## 3. Producing Gridpacks

* STEP 1: Add your slight.in templates to configs/
    * Keep N_EVENTS, RND_SEED, BEAM_1_GAMMA, and BEAM_2_GAMMA out of these files. The run script injects them automatically at runtime.
    * Make sure COLL_E is set, e.g.: COLL_E = 5362
* STEP 2: Add your decay cards to decay_cards/
    * Any .DEC file you want to use goes here.
    * The build script will copy the correct one into the tarball as decay.dec.
* STEP 3: Define your jobs in build_all_gridpacks.sh
    * Open build_all_gridpacks.sh and edit the JOBS array.
    * Each job is one line formatted as: "slight_config:decay_card:output_name"

```
    JOBS=(
      "slight_coherent.in:DECAYMU.DEC:psi2s_coh_mumu_v1"
      "slight_coherent.in:DECAYEL.DEC:psi2s_coh_elel_v1"
      "slight_incoherent.in:DECAYMU.DEC:psi2s_incoh_mumu_v1"
      "slight_coherent.in:my_custom.DEC:psi2s_coh_custom_v1"
    )
```
* STEP 4: Run the build script
```
    chmod +x build_all_gridpacks.sh
    ./build_all_gridpacks.sh
```
    Tarballs will be written directly to the productions/ directory.

---

## 4. Testing a Gridpack

Before submitting to the grid, test locally with a small number of events:

```
chmod +x test_gridpack.sh
./test_gridpack.sh productions/psi2s_coh_mumu_v1.tar.gz 10 1
#                                                       ^  ^
#                                                 nevents  seed
```

The test script will:
1. Untar the gridpack into a timestamped temporary directory.
2. Run runcmsgrid.sh with the given nevents and seed.
3. Report the number of events in the output LHE file.
4. Clean up automatically on success.

If the test fails: The script leaves the temporary directory intact so you can inspect logs:
* starlight.log: STARlight output (if it was produced before cleanup).
* slight.in: Check if injected parameters look correct.
* decay.dec: Verify the correct decay card was baked in.

---

## 5. What runcmsgrid.sh Does (Step-by-Step)

1. Reads COLL_E from slight.in and calculates BEAM_GAMMA = (COLL_E / 2) / 0.93827
2. Makes a working copy of slight.in and injects N_EVENTS, RND_SEED, and BEAM_GAMMA.
3. Runs STARlight -> produces slight.out.
4. Restores the original slight.in template immediately after STARlight finishes.
5. Runs fdgen with decay.dec -> produces slight_decayed.txt.
6. Runs ROOT macro convert_SL2LHE.C -> produces cmsgrid_final.lhe.
7. Cleans up all intermediate files.
8. Validates that cmsgrid_final.lhe was successfully produced.

---

## 6. Configuring the Physics (slight.in templates)

* Store all templates in configs/.
* Do NOT include N_EVENTS, RND_SEED, BEAM_1_GAMMA, or BEAM_2_GAMMA — these are injected automatically by runcmsgrid.sh at runtime.
* COLL_E must be present; if missing, it defaults to 5362 GeV with a warning.

Example minimal template:
```
COLL_E = 5362
W_MAX = 100.0
W_MIN = 2.0
... (other STARlight parameters)
```

---

## 7. Creating the Tarball Manually

If you need to package a single gridpack by hand rather than using the master build script, run this from inside gridpack_production/:

```
tar --exclude='*.out' --exclude='*.log' --exclude='*.lhe'     --exclude='*.tar.gz'     -czvf ../productions/my_gridpack.tar.gz ./*
```
Make sure slight.in and decay.dec are already in place before running this.

---

## 8. CMSSW Integration

In your Python configuration fragment:
* Point the gridpack path to your .tar.gz file.
* Set numberOfParameters = cms.uint32(2) (for NEVENTS and SEED).
* The fragment will automatically call: ./runcmsgrid.sh [nevents] [seed]

The fdgen file is created from https://github.com/danielahyano/decayPsi2S
