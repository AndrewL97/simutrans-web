#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${RUNNER_TEMP:-/tmp}/simutrans-wasm-source"
DIST="$ROOT/dist"

rm -rf "$WORK" "$DIST"
mkdir -p "$DIST"

: "${SOURCE_REPOSITORY:=https://github.com/simutrans/simutrans.git}"
: "${SOURCE_REF:=master}"

echo "Fetching Simutrans source: $SOURCE_REPOSITORY ($SOURCE_REF)"
git clone --depth 1 --branch "$SOURCE_REF" "$SOURCE_REPOSITORY" "$WORK"
cd "$WORK"

# Emscripten supplies SDL2 as a port, but upstream's Makefile may not
# automatically add -sUSE_SDL=2. Keep these flags visible in CI logs.
# This is a baseline attempt; upstream Makefile/dependency integration may
# require a small maintained patch once actual compiler diagnostics are known.
cat > config.default <<'CONFIG'
BACKEND = sdl2
COLOUR_DEPTH = 16
OSTYPE = linux
OPTIMISE = 1
CONFIG

# Try the upstream make build with Emscripten. `-sUSE_SDL=2` requests the
# Emscripten SDL2 port. FLAGS is an upstream Makefile variable; LDFLAGS is
# passed through for the final link. Build errors should fail this workflow.
set +e
emmake make -j2 \
  CFG=default \
  "FLAGS=-sUSE_SDL=2 -sUSE_FREETYPE=1 -sUSE_BZIP2=1 -sUSE_ZLIB=1 -sALLOW_MEMORY_GROWTH=1" \
  "LDFLAGS=-sUSE_SDL=2 -sUSE_FREETYPE=1 -sUSE_BZIP2=1 -sUSE_ZLIB=1 -sALLOW_MEMORY_GROWTH=1 -sMAXIMUM_MEMORY=2GB"
BUILD_STATUS=$?
set -e

if [[ $BUILD_STATUS -ne 0 ]]; then
  cat >&2 <<'MSG'
ERROR: Upstream Simutrans did not build with this baseline Emscripten configuration.
This scaffold is not a verified upstream port. Review the first compiler/linker error,
then patch the upstream Makefile/dependencies or maintain an Emscripten-specific fork.
Do not deploy a native executable as a substitute.
MSG
  exit "$BUILD_STATUS"
fi

# Locate the generated Emscripten JavaScript launcher. A valid browser build
# should have a .js file paired with a .wasm file; native executables are rejected.
JS_FILE="$(find build -type f -name '*.js' -print -quit 2>/dev/null || true)"
WASM_FILE="$(find build -type f -name '*.wasm' -print -quit 2>/dev/null || true)"
if [[ -z "$JS_FILE" || -z "$WASM_FILE" ]]; then
  echo "ERROR: Build succeeded but no .js/.wasm pair was found. The upstream Makefile likely needs an Emscripten-specific output target." >&2
  find build -maxdepth 4 -type f -print | head -n 100 || true
  exit 1
fi

cp "$JS_FILE" "$DIST/simutrans.js"
cp "$WASM_FILE" "$DIST/simutrans.wasm"

# Copy data files if the upstream source tree contains any. A real deployment
# should use a pinned, legally redistributable pakset rather than source assets.
if [[ -n "${PAKSET_URL:-}" ]]; then
  mkdir -p "$DIST/game"
  curl --fail --location --retry 3 "$PAKSET_URL" -o "$RUNNER_TEMP/pakset.zip"
  unzip -q "$RUNNER_TEMP/pakset.zip" -d "$DIST/game"
else
  echo "PAKSET_URL is unset; game data will not be bundled."
fi

cp "$ROOT/web/index.html" "$DIST/index.html"
touch "$DIST/.nojekyll"
echo "Staged WebAssembly site in $DIST"





