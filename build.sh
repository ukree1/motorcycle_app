#!/usr/bin/env bash
set -e

git clone https://github.com/flutter/flutter.git --depth 1 -b stable /tmp/flutter
export PATH="/tmp/flutter/bin:$PATH"

flutter --version
flutter config --enable-web
flutter pub get
flutter build web --release
