import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
          "Help and support",
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
            // Quick Service Section
            _buildQuickServiceGrid(),

            const SizedBox(height: 20),

            // FAQ Section
            _buildFAQSection(),

            const SizedBox(height: 30),

            // Bottom Contact Button
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
                    "Contact Support",
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

  Widget _buildQuickServiceGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Service",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSupportCard(
                  color: const Color(0xFF8B9BF6),
                  icon: Icons.headset_mic_outlined,
                  title: "Call Support",
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildSupportCard(
                  color: const Color(0xFFA5E9F7),
                  icon: Icons.email_outlined,
                  title: "Email Support",
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildSupportCard(
                  color: const Color(0xFFFFBCCB),
                  icon: Icons.chat_outlined,
                  title: "Live Chat",
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildSupportCard(
                  color: const Color(0xFFA7F6A8),
                  icon: Icons.help_outline_rounded,
                  title: "FAQs",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard({required Color color, required IconData icon, required String title}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.black87.withAlpha(150)),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: const BoxDecoration(
              color: Color(0xFFF1FDF1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, color: Colors.black87),
                const SizedBox(width: 15),
                Text(
                  "Frequently Asked Question",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          _buildFAQItem("How do I track my machine's service schedule?"),
          _buildFAQItem("What should I do if the machine stops unexpectedly?"),
          _buildFAQItem("How can I Download my warranty certificate?"),
          _buildFAQItem("Where can I find the user manual for JC-500>"),
          _buildFAQItem("How do I request genuine spare parts?"),
          _buildFAQItem("What is covered under my current warrenty plan?"),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        leading: const Text("•", style: TextStyle(fontSize: 20)),
        trailing: const Icon(Icons.keyboard_arrow_down),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "You can find this information in the service history section of your product details page.",
              style: GoogleFonts.outfit(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}
