#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="ClipboardBar"
DEST="${APP_NAME}.app"
CONTENTS="${DEST}/Contents"
MACOS="${CONTENTS}/MacOS"

rm -rf "$DEST"
mkdir -p "$MACOS" "${CONTENTS}/Resources"

echo "Generating app icon..."
ICON_TMP="$(mktemp -d)"
swift Scripts/make_icon.swift "$ICON_TMP"
cp "$ICON_TMP/AppIcon.icns" "${CONTENTS}/Resources/AppIcon.icns"
rm -rf "$ICON_TMP"

echo "Compiling..."
swiftc -O -target arm64-apple-macosx14.0 \
  -parse-as-library \
  Sources/${APP_NAME}App.swift Sources/AppDelegate.swift Sources/ClipboardModel.swift Sources/MenuBarView.swift \
  -o "${MACOS}/${APP_NAME}"

cat > "${CONTENTS}/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>ClipboardBar</string>
    <key>CFBundleDisplayName</key>
    <string>ClipboardBar</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.ClipboardBar</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>ClipboardBar</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

touch "${CONTENTS}/PkgInfo" 2>/dev/null || true

codesign --force --sign - "$DEST" 2>/dev/null || true

echo "Built ${DEST}"

