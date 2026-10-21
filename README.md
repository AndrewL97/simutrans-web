# Simutrans WebAssembly (GitHub Pages)

This repository is a **porting/build scaffold**, not a claim that upstream Simutrans currently builds unchanged under Emscripten. Simutrans has an SDL2 backend, but a browser build also needs Emscripten-specific compiler/linker flags, filesystem initialization, and validation of the upstream build's POSIX/library assumptions.

## Intended pipeline

1. Fetch upstream `simutrans/simutrans`.
2. Install Emscripten SDK and its SDL2 port.
3. Configure and attempt a WebAssembly build.
4. Stage the executable, web shell and a pakset.
5. Publish static files with GitHub Pages.

Upstream build instructions: https://github.com/simutrans/simutrans  
Emscripten filesystem docs: https://emscripten.org/docs/api_reference/Filesystem-API.html  
SDL2/Emscripten notes: https://wiki.libsdl.org/SDL2/README-emscripten

## Repository layout

- `.github/workflows/pages.yml` — CI build/deploy pipeline.
- `scripts/build.sh` — source checkout and Emscripten build/staging.
- `web/index.html` — browser shell with fullscreen and persistent IndexedDB filesystem setup.

## Important: first build is an integration test

The upstream Makefile and dependencies may need porting changes. In particular, `BACKEND=sdl2` alone does not guarantee that SDL2 is linked using Emscripten's `-sUSE_SDL=2`, or that zlib, bzip2 and FreeType resolve to Emscripten-compatible libraries. The script deliberately fails if it cannot locate a WebAssembly output instead of deploying a misleading empty page.

The first CI run should be treated as a diagnostic build. Fix compile/link errors in a maintained patch or fork; do not silently fall back to a native Linux executable.

## Pakset and licensing

Simutrans needs a compatible pakset to be playable. The workflow supports a separately downloadable ZIP through the `PAKSET_URL` repository variable. Configure it to a direct HTTPS ZIP URL for a pakset you are permitted to redistribute. If unset, the build will still stage the web runtime but the game may not start without game data.

Paksets have their own licenses; do not assume the source-code license grants permission to redistribute their graphics or sounds.

## Setup

1. Copy these files into `AndrewL97/simutrans-web`.
2. In the repository settings, enable **Pages → GitHub Actions** as the deployment source.
3. Optionally add a repository variable named `PAKSET_URL` containing a direct HTTPS URL to a legally redistributable pakset ZIP.
4. Push to the default branch, or run the workflow manually.
5. Inspect the `Build WebAssembly` step. If upstream needs porting changes, fix those before expecting a playable deployment.

GitHub Pages only serves static files. It cannot host a multiplayer server or provide server-side save storage. Browser saves are stored locally in that browser profile.
