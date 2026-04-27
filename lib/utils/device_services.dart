import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class DeviceServices {
  static Future<Map<String, String>> getAndStoreDeviceInfo() async {
    String lt = '0.0';
    String ln = '0.0';
    String? deviceId;

    try {
      final prefs = await SharedPreferences.getInstance();
      deviceId = prefs.getString('device_id');
      if (deviceId == null ||
          deviceId.isEmpty ||
          deviceId == '83' ||
          deviceId == '123') {
        deviceId =
            'DEV_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}';
        await prefs.setString('device_id', deviceId);
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();

        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          Position? position = await Geolocator.getLastKnownPosition();

          if (position == null) {
            try {
              position = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.medium,
                  timeLimit: Duration(seconds: 5),
                ),
              );
            } catch (e) {
              debugPrint("⚠️ Quick location fetch failed, using default: $e");
            }
          }

          if (position != null) {
            lt = position.latitude.toString();
            ln = position.longitude.toString();
          }
        }
      }

      // 3. Store dynamic values
      await prefs.setString('lt', lt);
      await prefs.setString('ln', ln);

      debugPrint(
        "✅ Device Info Stored Dynamically: ID=$deviceId, LT=$lt, LN=$ln",
      );

      return {'lt': lt, 'ln': ln, 'device_id': deviceId};
    } catch (e) {
      debugPrint("❌ Error in DeviceServices: $e");
      return {'lt': '0.0', 'ln': '0.0', 'device_id': deviceId ?? '123'};
    }
  }

  static void showLocationRequiredPopup(
    BuildContext context, {
    required VoidCallback onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Location Required"),
        content: const Text(
          "To continue, please enable location permissions for security.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
              onRetry();
            },
            child: const Text("Enable"),
          ),
        ],
      ),
    );
  }
}
