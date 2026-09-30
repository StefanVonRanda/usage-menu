#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Building release binary…"
swift build -c release

BIN=".build/release/UsageMenuApp"
APP=".build/UsageMenu.app"

echo "==> Bundling $APP…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/UsageMenuApp"
cp "Info.plist" "$APP/Contents/Info.plist"
echo "APPL????" > "$APP/Contents/PkgInfo"

# Ad-hoc sign so it launches without Gatekeeper complaints locally
codesign --force --deep --sign - "$APP" 2>/dev/null || true

echo "==> Done: $APP"
echo "Run with: open $APP"
echo "Optional: cp -R $APP /Applications/UsageMenu.app"
