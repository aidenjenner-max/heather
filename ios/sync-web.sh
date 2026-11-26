#!/bin/sh
# Copies the latest web app into the iOS project, leaving out website-only features
# (payments, Facebook sign-in, placeholder video) — see make-ios-web.py.
# Run from anywhere after rebuilding index.html (python3 build.py).
set -e
cd "$(dirname "$0")/.."
cp words.json apple-touch-icon.png privacy.html support.html terms.html ios/Heather/Web/
python3 ios/make-ios-web.py
echo "Copied the web app into ios/Heather/Web. Build again in Xcode to include it."
