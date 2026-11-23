/// Picks the shell that matches the build target.
///
/// * Native (Android / iOS): `web_app_screen.dart`, a full WebView shell.
/// * Web: `web_redirect_screen.dart`, a hand-off to the live app URL.
library;

export 'web_app_screen.dart'
    if (dart.library.js_interop) 'web_redirect_screen.dart';
