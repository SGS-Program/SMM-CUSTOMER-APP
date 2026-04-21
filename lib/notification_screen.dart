import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2CB9E5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notification",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSectionHeader("Today"),
          const SizedBox(height: 15),
          _buildNotificationCard(
            icon: Icons.build_outlined,
            title: "Issue Update",
            subtitle: "Complaint TKT#com-771",
            body: "Your complaint regarding \"breaker product\" has been assigned to support team",
            showCall: true,
          ),
          const SizedBox(height: 15),
          _buildNotificationCard(
            icon: Icons.local_shipping_outlined,
            title: "Logistic",
            subtitle: "Out For delivery DSP-10234",
            body: "Rajest has been picked up the jaw crusher. estimated delivery 12April 2026 before 6PM",
            showCall: true,
            iconColor: Colors.redAccent,
          ),
          const SizedBox(height: 25),
          _buildSectionHeader("Yesterday"),
          const SizedBox(height: 15),
          _buildNotificationCard(
            icon: Icons.local_shipping_outlined,
            title: "Service",
            subtitle: "Stone breaker delivered",
            body: "Confirming Delivery of order #98421 at factory site",
            showCall: false,
            showRateButton: true,
            iconColor: Colors.redAccent,
          ),
          const SizedBox(height: 15),
          _buildNotificationCard(
            icon: Icons.local_shipping_outlined,
            title: "Logistic",
            subtitle: "Out For delivery DSP-10234",
            body: "Rajest has been picked up the jaw crusher. estimated delivery 12April 2026 before 6PM",
            showCall: true,
            iconColor: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String body,
    bool showCall = false,
    bool showRateButton = false,
    Color iconColor = Colors.black,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: Colors.black.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
              if (showCall)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32), // Dark Green
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call, color: Colors.white, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: const Color(0xFF8B6B21), // Muted gold/brown
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          if (showRateButton) ...[
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFBDC2C7), // Grey
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "rate a service",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
