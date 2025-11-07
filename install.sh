#!/bin/bash

set -e

echo "🔍 Detecting system architecture..."

ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    DMG_URL="https://github.com/iamsrikanthnani/pluely/releases/download/app-v0.1.6/Pluely_0.1.6_aarch64.dmg"
    ARCH_NAME="Apple Silicon (ARM64)"
elif [[ "$ARCH" == "x86_64" ]]; then
    DMG_URL="https://github.com/iamsrikanthnani/pluely/releases/download/app-v0.1.6/Pluely_0.1.6_x64.dmg"
    ARCH_NAME="Intel (x86_64)"
else
    echo "❌ Unsupported architecture: $ARCH"
    exit 1
fi

echo "✅ Detected $ARCH_NAME"
echo "⬇️  Downloading Pluely from:"
echo "$DMG_URL"

TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

DMG_FILE="pluely.dmg"
curl -L -o "$DMG_FILE" "$DMG_URL"

echo "📦 Mounting DMG..."
MOUNT_POINT=$(hdiutil attach "$DMG_FILE" -nobrowse | grep Volumes | awk '{print $3}')

if [[ -z "$MOUNT_POINT" ]]; then
    echo "❌ Failed to mount DMG."
    exit 1
fi

echo "📂 Mounted at: $MOUNT_POINT"

# Find the .app bundle inside the mounted DMG
APP_PATH=$(find "$MOUNT_POINT" -maxdepth 1 -name "*.app" | head -n 1)

if [[ -z "$APP_PATH" ]]; then
    echo "❌ No .app found in DMG."
    hdiutil detach "$MOUNT_POINT"
    exit 1
fi

echo "📲 Installing Pluely to /Applications..."
APP_NAME="Pluely.app"
TARGET_PATH="/Applications/$APP_NAME"

# If already exists, rename the new one
if [[ -d "$TARGET_PATH" ]]; then
    echo "⚠️  Existing installation detected. Renaming new one to prevent conflict..."
    TARGET_PATH="/Applications/pluely.app"
fi

cp -R "$APP_PATH" "$TARGET_PATH"

echo "🧹 Removing quarantine attributes..."
xattr -cr "$TARGET_PATH"

echo "📤 Unmounting DMG..."
hdiutil detach "$MOUNT_POINT"

echo "✅ Installation complete!"
echo "🚀 You can now open Pluely from /Applications or Spotlight."

# Optional cleanup
rm -rf "$TMP_DIR"
