import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ComplaintDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;

  const ComplaintDetailsScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailsScreen> createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
  bool _isInvoiceExpanded = false;
  int _rating = 0; // 0 to 5 stars
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final photoUrl = widget.complaint['photo']?.toString();
    if (photoUrl != null && photoUrl.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        precacheImage(NetworkImage(photoUrl), context);
      });
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) return;

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cid = prefs.getString('cid');
      final String? cusId = prefs.getString('cus_id');

      if (cid == null || cusId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Missing user data. Please login again."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final String feedback = _feedbackController.text.trim();
      final fromId =
          widget.complaint['from_id']?.toString() ??
          widget.complaint['id']?.toString() ??
          '12';

      final String? token = prefs.getString('token');
      final String? deviceId = prefs.getString('device_id');
      final String? ltVal = prefs.getString('lt');
      final String? lnVal = prefs.getString('ln');

      final url = Uri.parse('https://erpsmart.in/total/api/m_api/');

      final response = await http.post(
        url,
        body: {
          'type': '7009',
          'cid': cid,
          'token': token ?? '',
          'device_id': deviceId ?? '123',
          'lt': ltVal ?? '0.0',
          'ln': lnVal ?? '0.0',
          'cus_id': cusId,
          'from_id': fromId,
          'rating': _rating.toString(),
          'feedback': feedback.isEmpty ? 'No feedback provided' : feedback,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['error'] == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Review submitted successfully"),
              backgroundColor: Color(0xFF2CB9E5),
            ),
          );

          // Reset form
          setState(() {
            _rating = 0;
            _feedbackController.clear();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? "Failed to submit review"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Server error. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaint = widget.complaint;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isCompleted =
        (complaint['status'] ?? '').toString().toLowerCase() == 'completed';
    final isAssigned =
        (complaint['status'] ?? '').toString().toLowerCase() == 'assigned' ||
        (complaint['status'] ?? '').toString().toLowerCase() == 'on the way' ||
        isCompleted;

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
          "Complaints Details",
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Details Card
            _buildDetailsCard(complaint),

            // Happy Code Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2CB9E5), Color(0xFF1A91B8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2CB9E5).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.vpn_key_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Your Happy Code",
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            (complaint['hpy_code']?.toString() ?? '').isEmpty
                                ? 'N/A'
                                : complaint['hpy_code'].toString(),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "VALID",
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // View Invoice Section
            // _buildInvoiceSection(),

            // Timeline Section
            _buildTimelineSection(complaint),

            // Technician Details Card - Only if assigned or completed
            if (isAssigned) _buildTechnicianCard(complaint),

            // Rating & Feedback Section - Only for Completed Complaints
            if (isCompleted) _buildRatingFeedbackSection(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingFeedbackSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF2CB9E5).withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "How was your experience?",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Rate the service you received",
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: index < _rating
                          ? const Color(0xFFFFC107)
                          : Colors.grey.shade400,
                      size: 42,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Feedback Text Field
            Text(
              "Share your feedback",
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Type Your Service Experience...",
                hintStyle: GoogleFonts.outfit(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2CB9E5),
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _rating > 0 && !_isSubmitting ? _submitReview : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2CB9E5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Submit Feedback",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================== Existing Methods (Completely Unchanged) ======================

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == "null") return "N/A";
    try {
      DateTime dt = DateTime.parse(dateStr);
      const months = [
        "",
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December",
      ];
      String month = months[dt.month];
      String day = dt.day.toString();
      String year = dt.year.toString();
      int hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      String minute = dt.minute.toString().padLeft(2, '0');
      String period = dt.hour >= 12 ? "PM" : "AM";

      return "$month $day, $year at $hour:$minute $period";
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildDetailsCard(Map<String, dynamic> complaint) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow("Name", complaint['name'] ?? 'N/A', isBold: true),
          _buildDetailRow(
            "Product",
            complaint['product'] ?? 'N/A',
            isBold: true,
          ),
          _buildDetailRow(
            "Complaint title",
            complaint['complaint_title'] ?? 'N/A',
            isBold: true,
          ),
          _buildDetailRow(
            "Preferred Visit date",
            complaint['date'] ?? 'N/A',
            isBold: true,
          ),
          _buildDetailRow(
            "Complaint ID",
            "#tk${complaint['id'] ?? '000'}",
            isBold: true,
          ),
          _buildDetailRow(
            "Ticket Raised date",
            complaint['request_date'] ?? 'N/A',
            isBold: true,
          ),

          const Divider(height: 30, thickness: 1, color: Colors.black12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  "Address",
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(
                  complaint['address'] ?? 'N/A',
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Text(
            "Attached Photos / Videos",
            style: GoogleFonts.outfit(fontSize: 15, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              if (complaint['photo'] != null &&
                  complaint['photo'].toString().isNotEmpty) {
                _showFullScreenImage(context, complaint['photo']);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child:
                  complaint['photo'] != null &&
                      complaint['photo'].toString().isNotEmpty
                  ? Image.network(
                      complaint['photo'],
                      width: 100,
                      height: 80,
                      fit: BoxFit.cover,
                      cacheWidth: 200,
                      cacheHeight: 160,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const _ShimmerBox(width: 100, height: 80);
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Description",
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            complaint['description'] ?? 'No description provided',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 100,
      height: 80,
      color: Colors.grey.shade300,
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.9),
              ),
            ),
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isInvoiceExpanded = !_isInvoiceExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECB3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_outlined, color: Colors.black87),
                  const SizedBox(width: 12),
                  Text(
                    "View Invoice",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isInvoiceExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
          ),
          if (_isInvoiceExpanded) _buildInvoiceDropdown(),
        ],
      ),
    );
  }

  Widget _buildInvoiceDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInvoiceSectionHeader("Invoice Summary"),
          _buildInvoiceContentRow("Invoice Number", "INV-2026-001"),
          _buildInvoiceContentRow("Order ID", "ORD-55892"),
          _buildInvoiceContentRow("Invoice Date", "10 May 2026"),
          _buildInvoiceContentRow("Payment Status", "Paid", isPaid: true),
          _buildInvoiceSectionHeader("Seller Details"),
          _buildInvoiceContentRow("Company Name", "ABC Machinery Pvt ltd"),
          _buildInvoiceContentRow("GST Number", "33ABCDE1234FGH"),
          _buildInvoiceContentRow("Contact", "+91 98745 12345"),
          _buildInvoiceContentRow("Email", "support@gmail.com"),
          _buildInvoiceSectionHeader("Product / Service"),
          _buildProductDetailRow("Breaker", value: "₹1,50,000", qty: "Qty(1)"),
          _buildProductDetailRow("Service", value: "₹1000"),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF2CB9E5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "₹1,50,000",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSummaryCalculationRow("Subtotal", "₹1,50,000"),
                _buildSummaryCalculationRow("GST(18%)", "₹27,900"),
                _buildSummaryCalculationRow("Delivery charge", "₹2000"),
                _buildSummaryCalculationRow("Discount", "-₹5,000"),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Amount",
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2CB9E5),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "₹1,79,900",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF2CB9E5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      width: double.infinity,
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildInvoiceContentRow(
    String label,
    String value, {
    bool isPaid = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          isPaid
              ? Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                )
              : Text(
                  value,
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

  Widget _buildProductDetailRow(
    String label, {
    required String value,
    String? qty,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          if (qty != null)
            Expanded(
              child: Text(
                qty,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCalculationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
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

  Widget _buildTimelineSection(Map<String, dynamic> complaint) {
    final status = (complaint['status'] ?? '').toString().toLowerCase();
    
    bool isInProgress = status == "assigned" || status == "on the way" || status == "completed";
    bool isOnTheWay = status == "on the way" || status == "completed";
    bool isCompleted = status == "completed";

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Timeline status",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          _buildTimelineItem(
            title: "Complaint Raised",
            subtitle: _formatDateTime(complaint['request_date']),
            icon: Icons.check_circle,
            iconColor: Colors.green,
            isLast: false,
            isActive: true,
          ),
          _buildTimelineItem(
            title: "In Progress",
            subtitle:
                "Assigned to technician\n${_formatDateTime(complaint['assign_date'])}",
            icon: Icons.info,
            iconColor: Colors.green,
            isLast: false,
            isActive: isInProgress,
          ),
          _buildTimelineItem(
            title: "On the Way",
            subtitle: "Technician is on the way to your location",
            icon: Icons.directions_bike,
            iconColor: Colors.green,
            isLast: false,
            isActive: isOnTheWay,
          ),
          _buildTimelineItem(
            title: "Expected date",
            subtitle:
                "Technician to reach you\n${_formatDateTime(complaint['expected_date'])}",
            icon: Icons.hourglass_empty,
            iconColor: Colors.green,
            isLast: false,
            isActive: isCompleted,
          ),
          _buildTimelineItem(
            title: "Resolved",
            subtitle:
                "Complaint resolved successfully\n${_formatDateTime(complaint['resolved_date'])}",
            icon: Icons.hourglass_empty,
            iconColor: Colors.green,
            isLast: true,
            isActive: isCompleted,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isLast,
    bool isActive = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                icon,
                color: isActive ? iconColor : Colors.grey.shade300,
                size: 24,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isActive ? Colors.black : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianCard(Map<String, dynamic> complaint) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF2CB9E5).withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2CB9E5).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF2CB9E5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Technician Details",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            "Name",
            (complaint['tech_name']?.toString() ?? '').isNotEmpty
                ? complaint['tech_name'].toString()
                : 'N/A',
            isBold: true,
          ),
          _buildDetailRow(
            "Mobile",
            (complaint['tech_mobile']?.toString() ?? '').isNotEmpty
                ? complaint['tech_mobile'].toString()
                : 'N/A',
            isBold: true,
          ),
          _buildDetailRow(
            "Email",
            (complaint['tech_email']?.toString() ?? '').isNotEmpty
                ? complaint['tech_email'].toString()
                : 'N/A',
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  const _ShimmerBox({required this.width, required this.height});
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300.withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
