/// Single source of truth for everything that identifies the app.
abstract final class AppConfig {
  /// Shown under the launcher icon and in the app bar.
  static const String appName = 'FIZ OA System';

  /// Owner of the brand, used in the about dialog and the web launcher.
  static const String companyName = 'Faiza';

  /// The live web app that both the Android build and the web build serve.
  static const String appUrl = 'https://www.fizbd.com/fizPriceApp/';

  /// Display form of the host, shown as a subtitle in the app bar.
  static const String appHost = 'www.fizbd.com';

  /// Must match the `version` field in pubspec.yaml.
  static const String version = '1.0.1';

  static const String logoAsset = 'assets/images/logo.png';
}
