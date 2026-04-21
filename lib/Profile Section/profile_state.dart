import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String city;
  final String imagePath;

  UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.imagePath,
  });
}

class ProfileState {
  // Singleton instance
  static final ProfileState _instance = ProfileState._internal();
  factory ProfileState() => _instance;
  ProfileState._internal() {
    loadProfile(); // Initial load
  }

  // ValueNotifier to track profile changes
  final ValueNotifier<UserProfile> profileNotifier = ValueNotifier<UserProfile>(
    UserProfile(
      name: "Loading...",
      email: "loading...",
      phone: "loading...",
      city: "loading...",
      imagePath: "assets/profile.png",
    ),
  );

  /// Load profile from SharedPreferences
  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    // Retrieve stored data
    final name = prefs.getString('name') ?? "User";
    final email = prefs.getString('email') ?? "N/A";
    final phone = prefs.getString('mobile') ?? "N/A";
    final city = prefs.getString('address') ?? "N/A";
    final imagePath = prefs.getString('profile_image') ?? "assets/profile.png";

    profileNotifier.value = UserProfile(
      name: name,
      email: email,
      phone: phone,
      city: city,
      imagePath: imagePath,
    );
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String city,
    String? imagePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Update SharedPreferences
    await prefs.setString('name', name);
    await prefs.setString('email', email);
    await prefs.setString('mobile', phone);
    await prefs.setString('address', city);
    if (imagePath != null) {
      await prefs.setString('profile_image', imagePath);
    }

    // Update state
    profileNotifier.value = UserProfile(
      name: name,
      email: email,
      phone: phone,
      city: city,
      imagePath: imagePath ?? profileNotifier.value.imagePath,
    );
  }

  /// Fetch profile data dynamically from API
  Future<bool> fetchProfileFromApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cid = prefs.getString('cid') ?? '';
      final mobile = prefs.getString('mobile') ?? '';
      final deviceId = prefs.getString('device_id') ?? '123';
      final lt = prefs.getString('lt') ?? '0.0';
      final ln = prefs.getString('ln') ?? '0.0';

      final token = prefs.getString('token') ?? '';

      if (cid.isEmpty || mobile.isEmpty) return false;

      final response = await http
          .post(
            Uri.parse("https://erpsmart.in/total/api/m_api/"),
            body: {
              "type": "5000",
              "cid": cid,
              "token": token,
              "mobile": mobile,
              "device_id": deviceId,
              "lt": lt,
              "ln": ln,
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] == false || data['error'] == "false") {
          // Update state and persistence
          await updateProfile(
            name: data['name']?.toString() ?? profileNotifier.value.name,
            email: data['email']?.toString() ?? profileNotifier.value.email,
            phone: data['mobile']?.toString() ?? profileNotifier.value.phone,
            city: data['address']?.toString() ?? profileNotifier.value.city,
            imagePath: profileNotifier.value.imagePath,
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("❌ Error fetching profile: $e");
      return false;
    }
  }
}
