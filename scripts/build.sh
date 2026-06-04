#!/usr/bin/env bash
# Build Infinity.app using swiftc (no Xcode required).
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SDK=$(xcrun --sdk macosx --show-sdk-path)
BUILD_DIR="$PROJECT_DIR/build"
APP="$BUILD_DIR/Infinity.app"
EXE="$APP/Contents/MacOS/Infinity"

mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources/Fonts"

SOURCES=(
  "$PROJECT_DIR/Infinity/Models/TimerItem.swift"
  "$PROJECT_DIR/Infinity/Utils/Extensions.swift"
  "$PROJECT_DIR/Infinity/Utils/SoundManager.swift"
  "$PROJECT_DIR/Infinity/Utils/TimeFormatter.swift"
  "$PROJECT_DIR/Infinity/ViewModels/TimerStore.swift"
  "$PROJECT_DIR/Infinity/InfinityApp.swift"
  "$PROJECT_DIR/Infinity/AppDelegate.swift"
  "$PROJECT_DIR/Infinity/Views/ContentView.swift"
  "$PROJECT_DIR/Infinity/Views/TimerRowView.swift"
  "$PROJECT_DIR/Infinity/Views/AddTimerView.swift"
  "$PROJECT_DIR/Infinity/Views/SettingsView.swift"
)

echo "▶  Compiling…"
swiftc "${SOURCES[@]}" \
  -sdk "$SDK" \
  -target arm64-apple-macosx13.0 \
  -parse-as-library \
  -framework AppKit \
  -framework SwiftUI \
  -framework Combine \
  -framework ServiceManagement \
  -Onone -g \
  -o "$EXE"

echo "▶  Bundling…"

# Info.plist — substitute Xcode build variables
cp "$PROJECT_DIR/Infinity/Info.plist" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable Infinity"              "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.kalyan.infinity"   "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName Infinity"                    "$APP/Contents/Info.plist"

# Fonts
cp "$PROJECT_DIR/Infinity/Fonts/"*.ttf "$APP/Contents/Resources/Fonts/"

# Alarm sound
mkdir -p "$APP/Contents/Resources"
cp "$PROJECT_DIR/Infinity/Sounds/alarm.mp3" "$APP/Contents/Resources/"

# App icon
cp "$PROJECT_DIR/Infinity/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

# Ad-hoc sign so macOS will run it
codesign --force --sign - "$EXE"

echo ""
echo "✓  $APP"
