#!/bin/bash

VERSION="$1"
ENABLED_MODULES="$2"
MODULE_TO_INSTALL="$3"
CHILDLESS="$4"

# Check if MODULE_TO_INSTALL is in ENABLED_MODULES
if [[ " $ENABLED_MODULES " =~ " $MODULE_TO_INSTALL " ]]; then
    CMD="unity-hub install-modules --version \"$VERSION\" --module \"$MODULE_TO_INSTALL\""
    if [[ "$CHILDLESS" != "childless" ]]; then
        CMD="$CMD --childModules"
    fi
    echo "Running: $CMD"
    $CMD
else
    echo "Module '$MODULE_TO_INSTALL' is not enabled. Skipping installation."
fi
