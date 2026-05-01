import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class WarrantyDetailsScreen extends StatelessWidget {
  final dynamic warrantyData;
  const WarrantyDetailsScreen({super.key, this.warrantyData});

  Future<void> _launchURL(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not launch PDF viewer.")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;

    final productItems = warrantyData?['items'] as List?;
    final firstItem = (productItems != null && productItems.isNotEmpty) ? productItems[0] : null;
    final String productName = firstItem?['pname'] ?? "N/A";
    final String invoiceNo = warrantyData?['invoice_no'] ?? "N/A";
    final String status = warrantyData?['warranty_status'] ?? "N/A";
    final String daysRemainingStr = warrantyData?['days_remaining'] ?? "0 days remaining";
    final String startDate = warrantyData?['date'] ?? "N/A";
    final String endDate = warrantyData?['warranty_expiry'] ?? "N/A";
    final String pdfUrl = warrantyData?['pdf_url'] ?? "";

    // Parse days remaining for calculation
    int daysRemaining = 0;
    try {
      daysRemaining = int.parse(daysRemainingStr.split(' ')[0]);
    } catch (e) {
      daysRemaining = 0;
    }

    // Assuming a standard 12-month (365 days) warranty for progress bar
    int totalDays = 365; 
    int monthsRemaining = (daysRemaining / 30).ceil();
    int monthsCompleted = ((totalDays - daysRemaining) / 30).floor();
    if (monthsCompleted < 0) monthsCompleted = 0;
    if (monthsRemaining > 12) monthsRemaining = 12;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2CB9E5),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Warranty Details",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Top Dark Card
            _buildTopDarkCard(productName, invoiceNo, status, daysRemainingStr, startDate, endDate),

            // Progress Indicators
            _buildWarrantyTimeline(monthsRemaining, monthsCompleted),

            // Coverage Details Card
            _buildCoverageDetails(),

            // Expired Secondary Card
            if (status.toLowerCase() == "expired")
              _buildExpiredCard(productName, endDate),

            const SizedBox(height: 20),

            // View Warranty Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (pdfUrl.isNotEmpty) {
                      _launchURL(context, pdfUrl);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No Warranty PDF available.")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2CB9E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "View Warranty",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTopDarkCard(String name, String invoice, String status, String remaining, String start, String end) {
    bool isActive = status.toLowerCase() == "active";
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF002F3C),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Machine",
                style: GoogleFonts.outfit(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            isActive ? remaining : "Expired",
            style: GoogleFonts.outfit(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDateInfo("Start Date", start),
              _buildDateInfo("End Date", end, alignRight: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(String label, String date, {bool alignRight = false}) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
        ),
        Text(
          date,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWarrantyTimeline(int monthsRemaining, int monthsCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: monthsCompleted > 0 ? const Color(0xFF4CAF50) : Colors.grey,
                size: 28,
              ),
              Expanded(
                child: Container(
                  height: 4, 
                  color: monthsCompleted > 6 ? const Color(0xFF4CAF50) : const Color(0xFF2CB9E5)
                ),
              ),
              Icon(
                Icons.access_time_filled,
                color: monthsRemaining > 0 ? const Color(0xFF4CAF50) : Colors.grey,
                size: 40,
              ),
              Expanded(
                child: Container(height: 4, color: const Color(0xFF2CB9E5)),
              ),
              const Icon(
                Icons.calendar_month,
                color: Color(0xFF2CB9E5),
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            monthsRemaining > 0 ? "In Warranty" : "Warranty Expired",
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          if (monthsRemaining > 0)
            Text(
              "$monthsRemaining Months More to Complete",
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$monthsCompleted Months Completed",
                style: GoogleFonts.outfit(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "$monthsRemaining Months Remaining",
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2CB9E5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: monthsCompleted,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(6),
                      bottomLeft: const Radius.circular(6),
                      topRight: monthsRemaining == 0 ? const Radius.circular(6) : Radius.zero,
                      bottomRight: monthsRemaining == 0 ? const Radius.circular(6) : Radius.zero,
                    ),
                  ),
                ),
              ),
              if (monthsRemaining > 0)
                Expanded(
                  flex: monthsRemaining,
                  child: Container(
                    height: 12, 
                    decoration: BoxDecoration(
                      color: const Color(0xFF2CB9E5),
                      borderRadius: BorderRadius.only(
                        topRight: const Radius.circular(6),
                        bottomRight: const Radius.circular(6),
                        topLeft: monthsCompleted == 0 ? const Radius.circular(6) : Radius.zero,
                        bottomLeft: monthsCompleted == 0 ? const Radius.circular(6) : Radius.zero,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Coverage Details",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          _buildCoverageItem(
            Icons.check,
            Colors.green,
            "Mechanical Parts (excl. wear parts)",
          ),
          const Divider(),
          _buildCoverageItem(
            Icons.check,
            Colors.green,
            "Labour & Technician Visit",
          ),
          const Divider(),
          _buildCoverageItem(
            Icons.check,
            Colors.green,
            "Electrical Components (motor)",
          ),
          const Divider(),
          _buildCoverageItem(
            Icons.close,
            Colors.red,
            "Wear Parts (jaws, Liners)",
            isExcluded: true,
          ),
          const Divider(),
          _buildCoverageItem(
            Icons.close,
            Colors.red,
            "Accidental Damage",
            isExcluded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageItem(
    IconData icon,
    Color color,
    String title, {
    bool isExcluded = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: isExcluded ? Colors.grey : Colors.black87,
                fontWeight: isExcluded ? FontWeight.normal : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredCard(String name, String endDate) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.outfit(
              color: const Color(0xFF2CB9E5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Warranty Expired",
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Expired $endDate",
            style: GoogleFonts.outfit(color: Colors.red, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
