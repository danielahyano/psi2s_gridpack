#!/bin/bash
# Usage: ./test_gridpack.sh [tarball] [nevents] [seed]
#
# Untars the gridpack into a temporary directory, runs runcmsgrid.sh,
# and reports success or failure. The temp directory is cleaned up
# automatically unless the run fails (so you can inspect the output).
#
# Example:
#   ./test_gridpack.sh productions/psi2s_coh_mumu_v1.tar.gz 10 1

TARBALL=$1
NEVENTS=${2:-10}   # default to 10 events for a quick test
SEED=${3:-1}

if [ -z "$TARBALL" ]; then
  echo "Usage: ./test_gridpack.sh [tarball] [nevents] [seed]"
  exit 1
fi

if [ ! -f "$TARBALL" ]; then
  echo "Error: Tarball not found: $TARBALL"
  exit 1
fi

# Create a temp directory next to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMPDIR="$SCRIPT_DIR/test_run_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$TMPDIR"

echo ""
echo "============================================================"
echo "  Testing : $TARBALL"
echo "  NEVENTS : $NEVENTS"
echo "  SEED    : $SEED"
echo "  Workdir : $TMPDIR"
echo "============================================================"

# Untar
echo ""
echo ">>> Unpacking..."
tar -xzf "$TARBALL" -C "$TMPDIR"
if [ $? -ne 0 ]; then
  echo "Error: Failed to untar $TARBALL"
  exit 1
fi

echo ">>> Contents of test directory:"
ls -lh "$TMPDIR"

# Run
echo ""
echo ">>> Running runcmsgrid.sh..."
cd "$TMPDIR"
bash runcmsgrid.sh "$NEVENTS" "$SEED"
RUN_EXIT=$?

echo ""
if [ $RUN_EXIT -eq 0 ]; then
  echo "============================================================"
  echo "  TEST PASSED"
  echo "  Output: $TMPDIR/cmsgrid_final.lhe"
  # Print a quick event count as sanity check
  NEVENTS_OUT=$(grep -c "<event>" "$TMPDIR/cmsgrid_final.lhe" 2>/dev/null || echo "unknown")
  echo "  Events in LHE: $NEVENTS_OUT"
  echo "============================================================"
  # Cleanup on success
  echo ""
  echo ">>> Cleaning up $TMPDIR"
  rm -rf "$TMPDIR"
else
  echo "============================================================"
  echo "  TEST FAILED (exit code $RUN_EXIT)"
  echo "  Leaving $TMPDIR intact for inspection."
  echo "============================================================"
  exit 1
fi
