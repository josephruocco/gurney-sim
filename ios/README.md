# Gurney Journey for iOS

A landscape iPhone/iPad app that runs the existing Three.js game in a native WKWebView. The game and Three.js 0.160.0 are bundled for offline play. Scores use the web view's persistent local storage.

## Run

1. Open `ios/Gurney.xcodeproj` in Xcode.
2. Choose the Gurney scheme and an iPhone simulator, then Run.
3. For a physical iPhone, select your development team under Signing & Capabilities, choose a unique bundle identifier if needed, select the connected phone, and Run.

## Update the game

`index.html` at the repository root is the source of truth. After editing it, run:

```sh
python3 scripts/prepare-ios.py
```

Commit the regenerated `ios/Gurney/Web` files with the source change. The script replaces the CDN module import with the checked-in Three.js build; no network access is needed to build or play. The vendored library's MIT license is included in the app bundle.

## Verify a build

```sh
xcodebuild -project ios/Gurney.xcodeproj -scheme Gurney \
  -sdk iphonesimulator -configuration Debug \
  -derivedDataPath /tmp/gurney-ios-build CODE_SIGNING_ALLOWED=NO build
```

Touch controls support steering, forward/reverse, braking, and boost. Forward/reverse also control airborne pitch. Menus scroll on short screens. Switching apps pauses play; tap Resume when returning.

This is a development app, not an App Store submission. Distribution still needs signing, device performance testing, screenshots, and App Store metadata/review.

The character, bed, and lighting are shared in `assets/mascot.js`. See `assets/ARTWORK.md` for rendering the title artwork and icon from those exact game models. Run `python3 scripts/prepare-art.py`, then `python3 scripts/prepare-ios.py` after rendering.
