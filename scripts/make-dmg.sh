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
# signature. Command-line overrides beat Signing.local.xcconfig, so empty
# APP_GROUP_ID also keeps team out of LCAppGroupID in Info.plist.
# AdHoc.entitlements drops App Group: widget cannot read it without team, and
# group ID without team prefix may trigger macOS 15+ access prompt.
# Inject flag off even in Release: Xcode adds get-task-allow to every ad-hoc
# build, and teammates' copies need no debugger attach.
xcodebuild \
  -project "$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  build \
  DEVELOPMENT_TEAM= \
  CODE_SIGN_IDENTITY=- \
  APP_GROUP_ID= \
  CODE_SIGN_ENTITLEMENTS="$PWD/Config/AdHoc.entitlements" \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO

APP="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"

# Guard against leaks before anything ships: no team, no network, no group.
# Output captured first: grep -q exiting early could SIGPIPE codesign under
# pipefail. Entitlements on stdout only, so bundle path cannot false-match.
for bundle in "$APP" "$APP"/Contents/PlugIns/*.appex; do
  info="$(codesign -dv "$bundle" 2>&1)"
  if ! grep -qx 'TeamIdentifier=not set' <<<"$info"; then
    echo "error: $bundle carries a team identifier" >&2
    exit 1
  fi
  entitlements="$(codesign -d --entitlements - --xml "$bundle" 2>/dev/null)"
  if grep -qE 'network|application-groups' <<<"$entitlements"; then
    echo "error: $bundle has network or application-groups entitlement" >&2
    exit 1
  fi
done

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR" dist
ditto "$APP" "$STAGE_DIR/$APP_NAME.app"
ln -s /Applications "$STAGE_DIR/Applications"

hdiutil create \
  -volname "Layoff Countdown" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "DMG: $PWD/$DMG_PATH"
