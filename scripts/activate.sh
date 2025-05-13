#!/usr/bin/env bash

# Convert the UNITY_LICENSE to a UNITY_SERIAL
if [ -z "$UNITY_SERIAL" ] && [ ! -z "$UNITY_LICENSE" ]; then
    echo "Extracting serial from license file"
    UNITY_SERIAL=$(echo "$UNITY_LICENSE" | grep -oP '(?<=<DeveloperData Value=")[^"]+' || echo "")
    if [ ! -z "$UNITY_SERIAL" ]; then
        echo "Found serial in license file"
    fi

    echo "$UNITY_SERIAL" | base64 -d >/tmp/serial_decoded
    UNITY_SERIAL=$(dd if=/tmp/serial_decoded bs=1 skip=4 2>/dev/null)
    rm /tmp/serial_decoded
fi
export UNITY_SERIAL="$UNITY_SERIAL"

# Activate the script.
if [ "$SKIP_ACTIVATION" != "true" ]; then
  source /steps/activate.sh

  # If we didn't activate successfully, exit with the exit code from the activation step.
  if [[ $UNITY_EXIT_CODE -ne 0 ]]; then
    exit $UNITY_EXIT_CODE
  fi

  export SKIP_ACTIVATION="true"
else
  echo "Skipping activation"
fi