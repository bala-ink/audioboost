#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DEVELOPER_DIRECTORY="$(xcode-select -p 2>/dev/null || true)"

if [[ "$DEVELOPER_DIRECTORY" != *CommandLineTools* ]]; then
  exec swift test "$@"
fi

CLT_FRAMEWORKS="/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
CLT_LIBS="/Library/Developer/CommandLineTools/Library/Developer/usr/lib"
CLT_TESTING_PLUGINS="/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing"

BUILD_ARGS=(--build-tests)
for argument in "$@"; do
  if [[ "$argument" == "--enable-code-coverage" ]]; then
    BUILD_ARGS+=(--enable-code-coverage)
  fi
done

swift build "${BUILD_ARGS[@]}"

BIN_PATH="$(swift build --show-bin-path)"
BUNDLE="$BIN_PATH/AudioBoostPackageTests.xctest/Contents/MacOS/AudioBoostPackageTests"

if [[ ! -f "$BUNDLE" ]]; then
  echo "error: test bundle not found at $BUNDLE" >&2
  exit 1
fi

LOADER="$BIN_PATH/audioboost-test-loader"
LOADER_SOURCE="$ROOT/scripts/TestLoader.swift"

if [[ ! -x "$LOADER" || "$LOADER_SOURCE" -nt "$LOADER" || "${BASH_SOURCE[0]}" -nt "$LOADER" ]]; then
  swiftc -parse-as-library -swift-version 5 \
    -F "$CLT_FRAMEWORKS" \
    -plugin-path "$CLT_TESTING_PLUGINS" \
    -framework Testing \
    -Xlinker -rpath -Xlinker "$CLT_FRAMEWORKS" \
    -Xlinker -rpath -Xlinker "$CLT_LIBS" \
    "$LOADER_SOURCE" \
    -o "$LOADER"
fi

TEST_BUNDLE_PATH="$BUNDLE" "$LOADER" --testing-library swift-testing "$@"
