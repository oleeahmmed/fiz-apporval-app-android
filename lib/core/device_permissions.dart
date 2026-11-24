import 'package:permission_handler/permission_handler.dart';

/// Runtime permissions that the embedded web app needs, requested on demand.
///
/// Android grants a WebView permission only when the host app already holds the
/// matching system permission, so every WebView prompt is answered by first
/// asking the user through the OS dialog.
abstract final class DevicePermissions {
  /// Location access behind `navigator.geolocation`.
  static Future<bool> ensureLocation() =>
      _ensure(Permission.locationWhenInUse);

  /// Camera access behind `getUserMedia` and photo capture.
  static Future<bool> ensureCamera() => _ensure(Permission.camera);

  /// Microphone access behind `getUserMedia` when a page records audio.
  static Future<bool> ensureMicrophone() => _ensure(Permission.microphone);

  /// Opens the OS settings page so the user can lift a "don't ask again" block.
  static Future<bool> openSettings() => openAppSettings();

  static Future<bool> _ensure(Permission permission) async {
    PermissionStatus status = await permission.status;
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied || status.isRestricted) return false;

    status = await permission.request();
    return status.isGranted || status.isLimited;
  }
}
