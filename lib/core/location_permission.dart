import 'package:permission_handler/permission_handler.dart';

/// Runtime location access that backs `navigator.geolocation` inside the WebView.
///
/// Android grants WebView geolocation only when the host app already holds the
/// system permission, so the two requests have to be chained.
abstract final class LocationPermission {
  /// Returns `true` when the app may read the device location.
  ///
  /// Safe to call repeatedly: only an undecided permission triggers a dialog.
  static Future<bool> ensureGranted() async {
    PermissionStatus status = await Permission.locationWhenInUse.status;
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied || status.isRestricted) return false;

    status = await Permission.locationWhenInUse.request();
    return status.isGranted || status.isLimited;
  }

  /// Opens the OS settings page so the user can lift a "don't ask again" block.
  static Future<bool> openSettings() => openAppSettings();
}
