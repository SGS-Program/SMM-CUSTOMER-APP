import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DispatchmentDetailsScreen extends StatefulWidget {
  final int dispatchId;
  const DispatchmentDetailsScreen({super.key, required this.dispatchId});

  @override
  State<DispatchmentDetailsScreen> createState() =>
      _DispatchmentDetailsScreenState();
}

class _DispatchmentDetailsScreenState extends State<DispatchmentDetailsScreen> {
  bool _isInvoiceExpanded = false;

  // API state
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _dispatchData;

  @override
  void initState() {
    super.initState();
    _fetchDispatchDetails();
  }

  Future<void> _fetchDispatchDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cid = prefs.getString('cid') ?? '';
      final cusId = prefs.getString('cus_id') ?? '';

      if (cid.isEmpty || cusId.isEmpty) {
        setState(() {
          _errorMessage = "Session expired. Please login again.";
          _isLoading = false;
        });
        return;
      }

      final uri = Uri.parse('https://erpsmart.in/total/api/m_api/');
      final response = await http.post(
        uri,
        body: {
          'type': '7005',
          'cid': cid,
          'device_id': '123',
          'lt': '123',
          'ln': '987',
          'cus_id': cusId,
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['error'] == false && json['data'] != null) {
          final List data = json['data'];
          final match = data.firstWhere(
            (item) => item['id'] == widget.dispatchId,
            orElse: () => data.isNotEmpty ? data[0] : null,
          );
          setState(() {
            _dispatchData = match != null
                ? Map<String, dynamic>.from(match)
                : null;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = json['message'] ?? 'Failed to fetch dispatch data';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty || raw.startsWith('0000')) return 'N/A';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty || raw.startsWith('0000')) return 'N/A';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${months[dt.month]} ${dt.day}, ${dt.year} at $hour:${minute}$ampm';
    } catch (_) {
      return raw;
    }
  }

  String _transportModeLabel(dynamic mode) {
    switch (mode.toString()) {
      case '0':
        return 'Express delivery';
      case '1':
        return 'Standard delivery';
      case '2':
        return 'Economy delivery';
      default:
        return 'Express delivery';
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

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
          "Dispatchment Details",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 22,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2CB9E5)),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _fetchDispatchDetails();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2CB9E5),
                      ),
                      child: Text(
                        'Retry',
                        style: GoogleFonts.outfit(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image with Date Overlay
                  _buildProductImageHeader(),

                  // Logistic Section
                  _buildSectionHeader("Logistic"),
                  _buildLogisticCard(),

                  // View Invoice Button & Dropdown
                  _buildInvoiceSection(),

                  // Timeline status Section
                  _buildSectionHeader("Timeline status"),
                  _buildTimelineStatus(),

                  // Product Received Button
                  _buildProductReceivedButton(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildProductReceivedButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: ElevatedButton(
        onPressed: () {
          // Add functionality here
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Product Received marked successfully!"),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2CB9E5),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          "Product Received",
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildProductImageHeader() {
    final imageUrl = _dispatchData?['image'];
    final expDelivery = _formatDate(_dispatchData?['exp_delivery']?.toString());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: imageUrl != null && imageUrl.toString().isNotEmpty
                ? Image.network(
                    imageUrl.toString(),
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 220,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF2CB9E5),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        _buildNoImagePlaceholder(),
                  )
                : _buildNoImagePlaceholder(),
          ),
          Positioned(
            bottom: 15,
            left: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(180),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Expected delivery $expDelivery",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            "No Image Available",
            style: GoogleFonts.outfit(
              color: Colors.grey.shade500,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 25,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5722),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticCard() {
    final tranMode = _transportModeLabel(_dispatchData?['tran_mode'] ?? 0);
    final dateOfTran = _formatDate(_dispatchData?['date_of_tran']?.toString());
    final contactPerson =
        _dispatchData?['contact_person_name']?.toString() ?? 'N/A';
    final contactMobile =
        _dispatchData?['contact_person_mobile']?.toString() ?? 'N/A';
    final expDelivery = _formatDate(_dispatchData?['exp_delivery']?.toString());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildLogisticRow("Mode of Transport", tranMode),
          const SizedBox(height: 12),
          _buildLogisticRow("Date of Transport", dateOfTran),
          const SizedBox(height: 12),
          _buildLogisticRow("Contact Person", contactPerson),
          const SizedBox(height: 12),
          _buildLogisticRow("Mobile Number", contactMobile),
          const SizedBox(height: 12),
          _buildLogisticRow("Expected Delivery", expDelivery),
        ],
      ),
    );
  }

  Widget _buildLogisticRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 15),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isInvoiceExpanded = !_isInvoiceExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        ),
        if (_isInvoiceExpanded) _buildInvoiceDropdown(),
      ],
    );
  }

  Widget _buildInvoiceDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

          // Section 4: Summary Calculation
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
      decoration: const BoxDecoration(color: Color(0xFF2CB9E5)),
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

  Widget _buildTimelineStatus() {
    final expDelivery = _dispatchData?['exp_delivery']?.toString();
    final disTime = (_dispatchData?['dtime'] ?? _dispatchData?['dis_time'])?.toString();
    final deliAddr = _dispatchData?['deli_addrs']?.toString() ?? 'N/A';

    final expDeliveryFormatted = _formatDate(expDelivery);
    final disTimeFormatted = _formatDate(disTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        children: [
          _buildTimelineItem(
            icon: Icons.access_time_outlined,
            iconColor: Colors.grey,
            title: "Expected date",
            subtitle: "delivery agent will reach you\n$expDeliveryFormatted",
            isLast: false,
            isCurrent: false,
            titleColor: Colors.grey,
          ),
          _buildTimelineItem(
            icon: Icons.local_shipping_outlined,
            iconColor: Colors.grey,
            title: "Dispatched",
            subtitle: "$deliAddr\n$disTimeFormatted",
            isLast: true,
            isCurrent: false,
            titleColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool isLast = false,
    bool isCurrent = true,
    Color? titleColor,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(icon, color: iconColor, size: 28),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade300),
                ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: titleColor ?? Colors.black,
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
}
