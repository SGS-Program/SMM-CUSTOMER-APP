import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileImageWidget extends StatelessWidget {
  final String name;
  final String imagePath;
  final String? localPreviewPath;
  final double radius;
  final double fontSize;
  final Color? bordercolor;

  const ProfileImageWidget({
    super.key,
    required this.name,
    required this.imagePath,
    this.localPreviewPath,
    this.radius = 50,
    this.fontSize = 24,
    this.bordercolor,
  });

  @override
  Widget build(BuildContext context) {
    // Check if we have a local preview or a saved image
    final bool hasPreview =
        localPreviewPath != null && localPreviewPath!.isNotEmpty;
    final bool hasSavedImage =
        imagePath.isNotEmpty &&
        !imagePath.contains('assets/profile.png') &&
        (imagePath.startsWith('assets') || File(imagePath).existsSync());

    if (hasPreview || hasSavedImage) {
      final ImageProvider provider;
      if (hasPreview) {
        provider = FileImage(File(localPreviewPath!));
      } else if (imagePath.startsWith('assets')) {
        provider = AssetImage(imagePath);
      } else {
        provider = FileImage(File(imagePath));
      }

      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: bordercolor ?? Colors.white, width: 2),
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: provider,
        ),
      );
    } else {
      // Show Initials
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: bordercolor ?? Colors.white, width: 2),
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: _getBackgroundColor(name),
          child: Text(
            _getInitials(name),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        ),
      );
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "U";
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color _getBackgroundColor(String name) {
    if (name.trim().isEmpty) return Colors.blue;

    final List<Color> colors = [
      const Color(0xFF4285F4), // Blue
      const Color(0xFFEA4335), // Red
      const Color(0xFFFBBC05), // Yellow
      const Color(0xFF34A853), // Green
      const Color(0xFF673AB7), // Purple
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF009688), // Teal
      const Color(0xFFF06292), // Pink
      const Color(0xFFFF7043), // Orange
      const Color(0xFF795548), // Brown
    ];

    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }

    return colors[hash.abs() % colors.length];
  }
}
