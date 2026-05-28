#!/bin/bash

# 1. Create the local lib folder if it doesn't exist
mkdir -p lib

# 2. Get the list of all libraries fdgen needs that are currently pointing to your private 'Tools' or 'afs' folders
# Then copy them into ./lib
echo "Searching for private libraries..."

libs=$(ldd ./fdgen | grep -E '/afs/cern.ch/user/d/dyano' | awk '{print $3}')

for lib in $libs; do
    if [ -f "$lib" ]; then
        echo "Copying $lib to ./lib/"
        cp -L "$lib" ./lib/
    fi
done

# 3. Special check for ROOT-specific libraries that ldd might have missed but fdgen needs at runtime
# (This ensures we get the 6.22 versions)
ROOT_LIB_DIR="/afs/cern.ch/user/d/dyano/Tools/root_6.22/lib"
if [ -d "$ROOT_LIB_DIR" ]; then
    echo "Copying essential ROOT 6.22 runtime libs..."
    cp -L $ROOT_LIB_DIR/libThread.so* ./lib/
    cp -L $ROOT_LIB_DIR/libRIO.so* ./lib/
    cp -L $ROOT_LIB_DIR/libCore.so* ./lib/
fi

echo "Done. Verifying ./lib content:"
ls -lh lib/
