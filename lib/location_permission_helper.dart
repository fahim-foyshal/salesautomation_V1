import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'dart:io';

class LocationPermissionHelper {
  // Request foreground location permission
  static Future<bool> requestForegroundLocationPermission() async {
    var status = await Permission.location.request();
    return status.isGranted;
  }

  // Check if background location permission is granted
  static Future<bool> hasBackgroundLocationPermission() async {
    return await Permission.locationAlways.isGranted;
  }

  // Show dialog to guide user to settings for background location
  static void showBackgroundLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Background Location Required'),
          content: const Text(
            'This app needs access to location when in the background. '
            'Please select "Allow all the time" in the next screen.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Open Location Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // Open location settings directly
  static Future<void> openLocationSettings() async {
    if (Platform.isAndroid) {
      // Try to open app-specific location permission settings
      // This should take you directly to the app's permission page
      await openAppSettings();
    } else {
      // For iOS, this opens the app's settings in the Settings app
      await AppSettings.openAppSettings();
    }
  }

  // Complete location permission flow
  static Future<void> requestLocationPermissions(BuildContext context) async {
    // First request foreground permission
    bool hasForeground = await requestForegroundLocationPermission();

    if (hasForeground) {
      // Check if we have background permission
      bool hasBackground = await hasBackgroundLocationPermission();

      // If we don't have background permission, guide the user
      if (!hasBackground) {
        showBackgroundLocationDialog(context);
      }
    }
  }
}
