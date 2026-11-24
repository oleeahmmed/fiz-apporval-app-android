# FIZ OA System — Flutter app (fiz-apporval-app-android)

A Flutter wrapper around the live FIZ approval web app at
<https://www.fizbd.com/fizPriceApp/>. One code base, two targets:

| Target | Shell | What the user gets |
| --- | --- | --- |
| Android (APK) | `lib/screens/web_app_screen.dart` | Native app shell with a full WebView, brand app bar, offline handling and geolocation support |
| Web (PWA) | `lib/screens/web_redirect_screen.dart` | Opens the live app URL directly — no screen in between |

`lib/screens/home_screen.dart` picks the right shell at compile time with a
conditional export, so both builds share one entry point.

Repository: <https://github.com/oleeahmmed/fiz-apporval-app-android>

```bash
git clone https://github.com/oleeahmmed/fiz-apporval-app-android.git
cd fiz-apporval-app-android
flutter pub get
```

The repository does not contain the release keystore: `android/key.properties`
and `android/app/upload-keystore.jks` are git-ignored on purpose. A fresh clone
builds with debug signing until you add your own (see *Release signing*).

## How the web build opens the app

`web/index.html` calls `window.location.replace('https://www.fizbd.com/fizPriceApp/')`
before Flutter boots, with a `<noscript>` meta refresh as a fallback, so a visitor
lands on the live app immediately. `web_redirect_screen.dart` repeats the same
navigation for the case where the cached shell loads first, and only paints the
brand gradient while the browser switches over.

An in-page embed is not possible: the hosted app answers with
`X-Frame-Options: SAMEORIGIN`. The Android build has no such restriction because
a WebView is a real browser engine.

The site is also behind a JavaScript bot check, which is another reason every
screen loads the real URL instead of a scraped copy.

## Requirements

- Flutter 3.50+ (Dart 3.14+)
- Android SDK 36 + JDK 17/21 for the APK

## Run and build

```powershell
flutter pub get
flutter run                      # attach an Android device
flutter test                     # unit + widget tests
flutter build apk --release      # -> build\app\outputs\flutter-apk\app-release.apk (universal)
flutter build apk --release --split-per-abi  # per-CPU APKs, ~16-19 MB each
flutter build appbundle --release # -> for Google Play
flutter build web --release --no-web-resources-cdn # -> build\web
```

`--no-web-resources-cdn` bundles CanvasKit inside `build\web\canvaskit` instead of
loading it from `gstatic.com`, which keeps the web build working on slow or
filtered networks. Builds without it depend on the Google CDN.

## Android permissions

Declared in `android/app/src/main/AndroidManifest.xml`:

| Permission | Why |
| --- | --- |
| `INTERNET` | The whole app is served from `fizbd.com` |
| `ACCESS_NETWORK_STATE` | Offline banner + automatic reload when the network returns |
| `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` | Backs `navigator.geolocation` inside the WebView |
| `CAMERA`, `RECORD_AUDIO` | Backs `getUserMedia` (camera preview, photo capture) inside the WebView |

Location and camera are requested **on demand**: the first time the web page
calls `navigator.geolocation` or `getUserMedia`, Android's prompt appears and the
answer is handed back to the WebView by `_onGeolocationPrompt` and
`_onWebPermissionRequest`. Users can re-trigger either prompt from the overflow
menu → *Location access* / *Camera access*. `android.hardware.location` and
`android.hardware.camera` are marked `required="false"` so tablets without
those sensors can still install the app.

## Brand assets

Everything is generated from the source `logo.png`:

```powershell
python tool/generate_brand_assets.py      # assets/ + web favicon/PWA icons
dart run flutter_launcher_icons           # Android launcher + adaptive icon
dart run flutter_native_splash:create     # Android splash screen
```

The source logo is only 118×132 px, so it is upscaled with Lanczos resampling.
Dropping a 512 px or larger `logo.png` in the project root and re-running the
three commands above gives a visibly sharper icon set.

## Release signing

`android/key.properties` points at `android/app/upload-keystore.jks`
(alias `fizprice`). Both the keystore and `key.properties` are git-ignored —
back them up: without them you cannot ship updates to Google Play under the same
signature. If `key.properties` is missing, the build falls back to debug signing
so a clean checkout still produces an installable APK.

## Features in the shell

- Brand app bar with logo, host name, refresh and an overflow menu
  (open in browser, location access, about)
- Thin progress bar driven by real page progress
- Offline and load-failure panels with retry, plus automatic reload when the
  network comes back
- Hardware back button walks the WebView history, then "press back again to exit"
- `tel:`, `mailto:`, `sms:`, `whatsapp:`, `upi:` and `intent:` links are handed to
  the matching native app
- `target="_blank"` links are rewritten in-page so they do not get swallowed by
  the WebView's (unhandled) multi-window support
- Pull-free, chrome-free viewport: the page keeps its own scroll position

## Not covered yet

- File uploads (`<input type="file">`) and downloads triggered from the page need
  `setOnShowFileSelector` / a download listener in `web_app_screen.dart`
- Payment gateways that try to open a new window or require a camera permission
