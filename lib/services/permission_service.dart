import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  static const _prefKey = 'permissions_requested_v1';

  /// Returns true if we already asked the user for permissions before.
  static Future<bool> hasRequestedBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  /// Mark that we have requested permissions at least once.
  static Future<void> markRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }

  /// Request all permissions the app needs.
  /// Returns a map of Permission → PermissionStatus.
  static Future<Map<Permission, PermissionStatus>> requestAll() async {
    final permissions = <Permission>[
      Permission.camera,
      Permission.photos,          // gallery (iOS) / READ_MEDIA_IMAGES (Android 13+)
      Permission.storage,         // storage (Android < 13)
      Permission.notification,    // push notifications
    ];

    final statuses = await permissions.request();
    await markRequested();
    return statuses;
  }

  /// Check if the essential permissions (camera + gallery) are granted.
  static Future<bool> areEssentialGranted() async {
    final camera = await Permission.camera.isGranted;
    final photos = await Permission.photos.isGranted;
    final storage = await Permission.storage.isGranted;
    return camera && (photos || storage);
  }

  /// Get the current status of each permission.
  static Future<Map<Permission, PermissionStatus>> currentStatuses() async {
    return {
      Permission.camera: await Permission.camera.status,
      Permission.photos: await Permission.photos.status,
      Permission.storage: await Permission.storage.status,
      Permission.notification: await Permission.notification.status,
    };
  }

  /// Open app settings so the user can manually grant denied permissions.
  static Future<bool> openSettings() => openAppSettings();
}
