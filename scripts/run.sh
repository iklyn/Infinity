#!/usr/bin/env bash
# Kills any running instance and launches the debug build.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP="$PROJECT_DIR/build/Infinity.app"

if [[ ! -d "$APP" ]]; then
  echo "App not found at $APP"
  echo "Run 'bash scripts/build.sh debug' first."
  exit 1
fi

# Kill previous run
pkill -x Infinity 2>/dev/null || true
sleep 0.3

echo "▶ Launching $APP"
open "$APP"
