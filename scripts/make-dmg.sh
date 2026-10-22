#!/usr/bin/env bash
# Build Release app and pack it into dist/LayoffCountdown.dmg for teammates.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="LayoffCountdown"
BUILD_DIR="build"
STAGE_DIR="$BUILD_DIR/dmg"
DMG_PATH="dist/$APP_NAME.dmg"

# Committed .xcodeproj is enough unless project.yml changed. Fresh clone may
# have newer project.yml by mtime only, so missing xcodegen is not fatal.
if [[ project.yml -nt "$APP_NAME.xcodeproj/project.pbxproj" ]]; then
  if command -v xcodegen >/dev/null 2>&1; then
    xcodegen generate
  else
    echo "warning: project.yml newer than $APP_NAME.xcodeproj but xcodegen not installed; using committed project" >&2
  fi
fi

# Always ad-hoc: Personal Team signing embeds Apple ID name and team ID in
# signature. Command-line overrides beat Signing.local.xcconfig. No
# get-task-allow: teammates' copies need no debugger attach.
xcodebuild \
  -project "$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  build \
  DEVELOPMENT_TEAM= \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR" dist
cp -R "$BUILD_DIR/Build/Products/Release/$APP_NAME.app" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

hdiutil create \
  -volname "Layoff Countdown" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "DMG: $PWD/$DMG_PATH"
