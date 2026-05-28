#!/bin/bash
# Run this from inside gridpack_production/ before building tarballs.
# Collects all libraries that fdgen and starlight need into ./lib/
 
mkdir -p lib
 
echo "=== Collecting private AFS libraries for fdgen ==="
libs=$(ldd ./fdgen | grep -E '/afs/cern.ch/user/d/dyano' | awk '{print $3}')
for lib in $libs; do
    if [ -f "$lib" ]; then
        echo "  Copying $lib"
        cp -L "$lib" ./lib/
    fi
done
 
echo ""
echo "=== Collecting private AFS libraries for starlight ==="
libs=$(ldd ./starlight | grep -E '/afs/cern.ch/user/d/dyano' | awk '{print $3}')
for lib in $libs; do
    if [ -f "$lib" ]; then
        echo "  Copying $lib"
        cp -L "$lib" ./lib/
    fi
done
 
echo ""
echo "=== Copying essential ROOT 6.22 runtime libs ==="
ROOT_LIB_DIR="/afs/cern.ch/user/d/dyano/Tools/root_6.22/lib"
if [ -d "$ROOT_LIB_DIR" ]; then
    for lib in libThread libRIO libCore libMathCore libNet libRint; do
        cp -L $ROOT_LIB_DIR/${lib}.so* ./lib/ 2>/dev/null && echo "  Copied ${lib}" || echo "  Warning: ${lib} not found"
    done
else
    echo "  Warning: ROOT lib dir not found: $ROOT_LIB_DIR"
fi
 
echo ""
echo "=== Hunting for libtbb (needed by fdgen at runtime) ==="
# ldd often misses libtbb because it's loaded dynamically
# Search in common system locations
TBB_FOUND=0
for search_path in \
    /usr/lib64 \
    /usr/lib \
    /lib64 \
    /lib \
    /afs/cern.ch/user/d/dyano/Tools/root_6.22/lib \
    $(dirname $(ldd ./fdgen | grep libtbb | awk '{print $3}') 2>/dev/null)
do
    if [ -f "$search_path/libtbb.so.2" ]; then
        echo "  Found libtbb.so.2 in $search_path"
        cp -L "$search_path/libtbb.so.2" ./lib/
        TBB_FOUND=1
        break
    fi
done
 
if [ $TBB_FOUND -eq 0 ]; then
    # Try locating it anywhere on the system
    TBB_PATH=$(find /usr /lib /afs/cern.ch/user/d/dyano/Tools -name "libtbb.so.2" 2>/dev/null | head -1)
    if [ -n "$TBB_PATH" ]; then
        echo "  Found libtbb.so.2 at $TBB_PATH"
        cp -L "$TBB_PATH" ./lib/
        TBB_FOUND=1
    fi
fi
 
if [ $TBB_FOUND -eq 0 ]; then
    echo "  ERROR: libtbb.so.2 not found anywhere on this system!"
    echo "  Try: scram tool info tbb   (inside a CMSSW environment)"
    echo "  Or:  find / -name 'libtbb.so.2' 2>/dev/null"
fi
 
echo ""
echo "=== Verifying full ldd output for fdgen ==="
echo "  (any line showing 'not found' needs to be fixed before packaging)"
ldd ./fdgen | grep -E "not found|=> /" | while read line; do
    if echo "$line" | grep -q "not found"; then
        echo "  MISSING: $line"
    fi
done
 
echo ""
echo "=== Final lib/ contents ==="
ls -lh lib/
