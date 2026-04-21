import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WarrantyDetailsScreen extends StatelessWidget {
  const WarrantyDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;

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
            _buildTopDarkCard(),

            // Progress Indicators
            _buildWarrantyTimeline(),

            // Coverage Details Card
            _buildCoverageDetails(),

            // Expired Secondary Card
            _buildExpiredCard(),

            const SizedBox(height: 20),
            
            // Download Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2CB9E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Download Warranty",
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

  Widget _buildTopDarkCard() {
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
                style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Active",
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Jaw Crusher - JC 500",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Expires In 284 Days",
            style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDateInfo("Start Date", "01 JAN 2025"),
              _buildDateInfo("End Date", "31 DEC 2026", alignRight: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(String label, String date, {bool alignRight = false}) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
        ),
        Text(
          date,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWarrantyTimeline() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
              Expanded(
                child: Container(height: 4, color: const Color(0xFF4CAF50)),
              ),
              const Icon(Icons.access_time_filled, color: Color(0xFF4CAF50), size: 40),
              Expanded(
                child: Container(height: 4, color: const Color(0xFF2CB9E5)),
              ),
              const Icon(Icons.calendar_month, color: Color(0xFF2CB9E5), size: 28),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            "In Warranty",
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            "6 Months More to Complete",
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
                "6 Months Completed",
                style: GoogleFonts.outfit(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              Text(
                "6 Months Remaining",
                style: GoogleFonts.outfit(color: const Color(0xFF2CB9E5), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(6), bottomLeft: Radius.circular(6)),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  height: 12,
                  color: const Color(0xFF2CB9E5),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
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
          _buildCoverageItem(Icons.check, Colors.green, "Mechanical Parts (excl. wear parts)"),
          const Divider(),
          _buildCoverageItem(Icons.check, Colors.green, "Labour & Technician Visit"),
          const Divider(),
          _buildCoverageItem(Icons.check, Colors.green, "Electrical Components (motor)"),
          const Divider(),
          _buildCoverageItem(Icons.close, Colors.red, "Wear Parts (jaws, Liners)", isExcluded: true),
          const Divider(),
          _buildCoverageItem(Icons.close, Colors.red, "Accidental Damage", isExcluded: true),
        ],
      ),
    );
  }

  Widget _buildCoverageItem(IconData icon, Color color, String title, {bool isExcluded = false}) {
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

  Widget _buildExpiredCard() {
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
            "Cone Crusher . CC-200",
            style: GoogleFonts.outfit(color: const Color(0xFF2CB9E5), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            "Warranty Expired",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            "Expired 15 Mar 2025",
            style: GoogleFonts.outfit(color: Colors.red, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
