#!/usr/bin/env bash
# Build Release app and pack two DMGs into build/:
#   LayoffCountdown-unsigned.dmg  ad-hoc, no builder identity: safe to share.
#   LayoffCountdown.dmg           signed with $SIGN_IDENTITY: for your own Macs only.
# The signed one is skipped with a warning when no identity is set.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="LayoffCountdown"
BUILD_DIR="build"
STAGE_DIR="$BUILD_DIR/dmg"
APP="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
UNSIGNED_DMG="$BUILD_DIR/$APP_NAME-unsigned.dmg"
SIGNED_DMG="$BUILD_DIR/$APP_NAME.dmg"

SIGN_IDENTITY="${SIGN_IDENTITY:-}"

# Committed .xcodeproj is enough unless project.yml changed. Fresh clone may
# have newer project.yml by mtime only, so missing xcodegen is not fatal.
if [[ project.yml -nt "$APP_NAME.xcodeproj/project.pbxproj" ]]; then
  if command -v xcodegen >/dev/null 2>&1; then
    xcodegen generate
  else
    echo "warning: project.yml newer than $APP_NAME.xcodeproj but xcodegen not installed; using committed project" >&2
  fi
fi

make_dmg() { # <dmg path>
  rm -rf "$STAGE_DIR"
  mkdir -p "$STAGE_DIR"
  ditto "$APP" "$STAGE_DIR/$APP_NAME.app"
  ln -s /Applications "$STAGE_DIR/Applications"
  hdiutil create \
    -volname "Layoff Countdown" \
    -srcfolder "$STAGE_DIR" \
    -ov \
    -format UDZO \
    "$1"
  echo "DMG: $PWD/$1"
}

# --- Unsigned: always ad-hoc. Personal Team signing embeds Apple ID name and team ID in
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

make_dmg "$UNSIGNED_DMG"

# --- Signed: real identity and App Group, so the widget reads app settings.
if [[ -z "$SIGN_IDENTITY" ]]; then
  echo "warning: SIGN_IDENTITY not set; skipping signed DMG" >&2
  exit 0
fi

# Team ID is the OU of the signing certificate. DEVELOPMENT_TEAM overrides it.
TEAM="${DEVELOPMENT_TEAM:-$(security find-certificate -c "$SIGN_IDENTITY" -p \
  | openssl x509 -noout -subject -nameopt multiline | awk '/organizationalUnitName/ {print $3}')}"
if [[ -z "$TEAM" ]]; then
  echo "error: no team ID for '$SIGN_IDENTITY'; set DEVELOPMENT_TEAM" >&2
  exit 1
fi

# Project uses automatic signing, which rejects a full certificate name: pass
# only its type ("Apple Development"); the team picks the certificate.
# APP_GROUP_ID and entitlements come from Signing.xcconfig / project.yml here.
# -allowProvisioningUpdates lets Xcode fetch the App Group profile.
xcodebuild \
  -project "$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  -allowProvisioningUpdates \
  build \
  DEVELOPMENT_TEAM="$TEAM" \
  CODE_SIGN_IDENTITY="${SIGN_IDENTITY%%:*}" \
  APP_GROUP_ID="$TEAM.com.layoffcountdown.shared"

for bundle in "$APP" "$APP"/Contents/PlugIns/*.appex; do
  codesign --verify --strict "$bundle"
done

make_dmg "$SIGNED_DMG"
echo "Signed DMG carries your team ID: do not share it."
