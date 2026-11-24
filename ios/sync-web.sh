#!/bin/sh
# Copies the latest web app into the iOS project.
# Run from anywhere after rebuilding index.html (python3 build.py).
set -e
cd "$(dirname "$0")/.."
cp index.html words.json apple-touch-icon.png privacy.html support.html ios/Heather/Web/
echo "Copied the web app into ios/Heather/Web. Build again in Xcode to include it."
