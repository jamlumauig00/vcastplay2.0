import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<void> requestPermissions() async {
    // Check for platform
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      // For Android versions below 30, request storage permission
      if (sdkInt < 30) {
        await Permission.storage.request();
      }
    }

    // Request permissions for both iOS and Android
    await [
      Permission.photos,        // iOS
      Permission.mediaLibrary,  // iOS
      Permission.microphone,    // Audio recording
      Permission.location,      // Location access
      Permission.camera,        // Camera access
    ].request();
  }

  static Future<bool> isPermissionGranted(Permission permission) async {
    return await permission.status.isGranted;
  }
}
