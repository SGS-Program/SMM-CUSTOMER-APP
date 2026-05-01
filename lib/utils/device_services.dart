import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_autofill/sms_autofill.dart';

class DeviceServices {
  static Future<Map<String, String?>> getAndStoreDeviceInfo() async {
    String? lt;
    String? ln;
    String? deviceId;

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceInfo = DeviceInfoPlugin();

      // 1. Get Device ID
      try {
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor;
        }
      } catch (e) {
        debugPrint("❌ DEVICE ID ERROR: $e");
      }

      if (deviceId != null) {
        await prefs.setString('device_id', deviceId);
      } else {
        deviceId = prefs.getString('device_id');
      }

      // 2. Get Location
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.deniedForever) {
          debugPrint("❌ Location permissions are permanently denied.");
        }

        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          
          if (!serviceEnabled) {
            debugPrint("⚠️ Location services are disabled. Prompting user...");
            // You might want to show a dialog here to ask user to enable GPS
          }

          Position? pos;
          try {
            pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 15),
              ),
            );
          } catch (e) {
            debugPrint("⚠️ High accuracy failed, trying medium: $e");
            try {
              pos = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.medium,
                  timeLimit: Duration(seconds: 10),
                ),
              );
            } catch (e2) {
              debugPrint("❌ Medium accuracy also failed: $e2");
            }
          }

          if (pos != null) {
            lt = pos.latitude.toStringAsFixed(6);
            ln = pos.longitude.toStringAsFixed(6);
            await prefs.setString('lt', lt);
            await prefs.setString('ln', ln);
          }
        }
      } catch (e) {
        debugPrint("❌ LOCATION ERROR: $e");
      }

      debugPrint(
        "✅ Device Info Attempted: ID=$deviceId, LT=$lt, LN=$ln",
      );

      return {
        'lt': lt,
        'ln': ln,
        'device_id': deviceId
      };
    } catch (e) {
      debugPrint("❌ Error in DeviceServices: $e");
      return {'lt': null, 'ln': null, 'device_id': deviceId};
    }
  }

  static Future<String> getAppSignature() async {
    try {
      final signature = await SmsAutoFill().getAppSignature;
      debugPrint("🟢 APP SIGNATURE: $signature");
      return signature;
    } catch (e) {
      debugPrint("❌ Error getting app signature: $e");
      return "";
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
