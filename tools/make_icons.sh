#!/usr/bin/env bash
# Renders the app icon from the brand SVGs and regenerates the launcher
# icons (Android, iOS). The drawing lives in assets/brand/ — edit
# the SVGs there, then run: tools/make_icons.sh
#
# Needs Google Chrome (headless) to draw the SVGs; set CHROME to its
# binary if it isn't in the usual macOS place.
set -euo pipefail
cd "$(dirname "$0")/.."

CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"

render() { # <svg> <png>
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars \
    --default-background-color=00000000 --window-size=1024,1024 \
    --screenshot="$PWD/$2" "file://$PWD/$1" >/dev/null 2>&1
  echo "rendered $2"
}

# Full square on cream (iOS, Android before 8.0).
render assets/brand/app-icon.svg assets/icons/app_icon.png
# Android 8.0+ adaptive icon: Bolubi alone, inside the 66dp safe circle,
# over the cream background colour set in pubspec.yaml.
render assets/brand/app-icon-foreground.svg assets/icons/app_icon_foreground.png

dart run flutter_launcher_icons
