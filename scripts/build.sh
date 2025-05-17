#!/usr/bin/env bash

set_env_var() {
    local name="$1"
    local value="$2"
    export "$name=$value"
    echo "$name=$value" >> $GITHUB_ENV
}

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
    
    set_env_var "UNITY_SERIAL" $UNITY_SERIAL
fi

# Extract the android keystore file
if [ ! -z "$ANDROID_KEYSTORE_BASE64" ]; then
    if [ -z "$ANDROID_KEYSTORE_NAME" ]; then
        echo "ANDROID_KEYSTORE_NAME not set, using default keystore.jks"
        ANDROID_KEYSTORE_NAME="keystore.jks"
    else
        echo "Using custom keystore name: $ANDROID_KEYSTORE_NAME"
    fi

    echo "Storing keystore file to $ANDROID_KEYSTORE_NAME"
    echo "$ANDROID_KEYSTORE_BASE64" | base64 --decode > "$ANDROID_KEYSTORE_NAME"
    set_env_var "ANDROID_KEYSTORE_NAME" $ANDROID_KEYSTORE_NAME
fi

# Set a bunch of defaults
if [ -z "$PROJECT_PATH" ]; then
    PROJECT_PATH="."
    set_env_var "PROJECT_PATH" $PROJECT_PATH
fi
echo "PROJECT PATH: $PROJECT_PATH"

if [ -z "$SKIP_ACTIVATION" ]; then
    SKIP_ACTIVATION="false"
    set_env_var "SKIP_ACTIVATION" $SKIP_ACTIVATION
fi
echo "SKIP_ACTIVATION: $SKIP_ACTIVATION"

if [ -z "$MANUAL_EXIT" ]; then
    MANUAL_EXIT="false"
    set_env_var "MANUAL_EXIT" $MANUAL_EXIT
fi
echo "MANUAL_EXIT: $MANUAL_EXIT"

if [ -z "$ENABLE_GPU" ]; then
    ENABLE_GPU="false"
    set_env_var "ENABLE_GPU" $ENABLE_GPU
fi
echo "ENABLE_GPU: $ENABLE_GPU"

if [ -z "$ENABLE_GRAPHICS" ]; then
    ENABLE_GRAPHICS="false"
    set_env_var "ENABLE_GRAPHICS" $ENABLE_GRAPHICS
fi
echo "ENABLE_GRAPHICS: $ENABLE_GRAPHICS"

# Android Defaults
if [ -z "$ANDROID_VERSION_CODE" ]; then
    ANDROID_VERSION_CODE="129"
    set_env_var "ANDROID_VERSION_CODE" $ANDROID_VERSION_CODE
fi
echo "ANDROID_VERSION_CODE: $ANDROID_VERSION_CODE"

if [ -z "$ANDROID_EXPORT_TYPE" ]; then
    ANDROID_EXPORT_TYPE="androidPackage"
    set_env_var "ANDROID_EXPORT_TYPE" $ANDROID_EXPORT_TYPE
fi
echo "ANDROID_EXPORT_TYPE: $ANDROID_EXPORT_TYPE"

if [ -z "$ANDROID_SYMBOL_TYPE" ]; then
    ANDROID_SYMBOL_TYPE="none"
    set_env_var "ANDROID_SYMBOL_TYPE" $ANDROID_SYMBOL_TYPE
fi
echo "ANDROID_SYMBOL_TYPE: $ANDROID_SYMBOL_TYPE"

# Configure the final custom parameters
CUSTOM_PARAMETERS="$CUSTOM_PARAMETERS"
if [ "$ENABLE_GRAPHICS" = "false" ]; then
    CUSTOM_PARAMETERS="$CUSTOM_PARAMETERS -nographics"
fi
set_env_var "CUSTOM_PARAMETERS" $CUSTOM_PARAMETERS

# Run the build
source /entrypoint.sh