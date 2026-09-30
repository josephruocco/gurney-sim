# Gurney Journey artwork

The user’s sketch is the character reference: sleepy line eyes, a simple hemispherical nose, rounded, slightly chubby cylindrical hospital gown, stubby hands and short cylindrical legs with rounded nubs, and a few short hairs. The default skin is warm peach.

`mascot.js` is the single source for the patient, gurney, and base lighting. The game uses these meshes directly in lying and standing poses. The title image and app icon are renders of those same meshes. No generated illustration is used in the final assets.

## Regenerate

1. Run `python3 scripts/render-art-server.py` from the repository.
2. Open `http://127.0.0.1:8765/scripts/render-art.html` in a WebGL browser. It renders and saves the transparent title image and opaque icon master to `assets` through the localhost-only server.
3. Run `python3 scripts/prepare-art.py` to produce the native app icon, favicon, and Apple touch icon.
4. Run `python3 scripts/prepare-ios.py` to update the offline iOS bundle.

The renderer and game both use the pinned Three.js 0.160.0 library. Runtime level lighting can vary by environment; character geometry and materials stay shared.
