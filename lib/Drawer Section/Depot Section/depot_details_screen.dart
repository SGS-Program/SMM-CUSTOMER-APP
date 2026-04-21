import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DepotDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> depotData;
  const DepotDetailsScreen({super.key, required this.depotData});

  @override
  State<DepotDetailsScreen> createState() => _DepotDetailsScreenState();
}

class _DepotDetailsScreenState extends State<DepotDetailsScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _depotData;

  @override
  void initState() {
    super.initState();
    _depotData = widget.depotData;
    _fetchDepotDetails();
  }

  Future<void> _fetchDepotDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final cid = prefs.getString('cid') ?? '';
      final cusId = prefs.getString('cus_id') ?? '';
      final deviceId = prefs.getString('device_id') ?? '123';
      final lt = prefs.getString('lt') ?? '123';
      final ln = prefs.getString('ln') ?? '987';

      final response = await http
          .post(
            Uri.parse('https://erpsmart.in/total/api/m_api/'),
            body: {
              'type': '7007',
              'cid': cid,
              'device_id': deviceId,
              'lt': lt,
              'ln': ln,
              'cus_id': cusId,
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['error'] == false &&
            jsonData['data'] != null &&
            (jsonData['data'] as List).isNotEmpty) {
          setState(() {
            _depotData = jsonData['data'][0];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = jsonData['message'] ?? 'No data found';
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
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--';
    try {
      final parts = time.split(':');
      if (parts.length < 2) return time;
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '$hour:${minute}$period';
    } catch (_) {
      return time;
    }
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '--';
    try {
      final dt = DateTime.parse(date);
      const months = [
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
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return date;
    }
  }

  void _openImageViewer(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullImageViewerScreen(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
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
          "Depot Details",
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
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Info Card
                    _buildMainInfoCard(),

                    const SizedBox(height: 16),

                    // Time & Personnel Card
                    _buildTimePersonnelCard(),

                    const SizedBox(height: 16),

                    // Narrative Cards
                    _buildNarrativeCard(
                      title: "Work Done",
                      content: _depotData!['work_done'] ?? '--',
                      titleColor: Colors.green.shade700,
                    ),

                    const SizedBox(height: 16),

                    _buildNarrativeCard(
                      title: "Next Action",
                      content: _depotData!['next_action'] ?? '--',
                      titleColor: Colors.green.shade700,
                    ),

                    const SizedBox(height: 25),

                    Text(
                      "Timeline status",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Timeline Items
                    _buildTimelineSection(),

                    const SizedBox(height: 20),

                    // Bottom Alert
                    _buildBottomAlert(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMainInfoCard() {
    final data = _depotData!;
    final imageUrl = data['upload_img'] ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            "Ticket ID",
            "#tk${data['ticket_id'] ?? '--'}",
            isBold: true,
          ),
          _buildDetailRow(
            "Customer Name",
            data['cust_name'] ?? '--',
            isBold: true,
          ),
          _buildDetailRow(
            "Product Name",
            data['pro_name'] ?? '--',
            isBold: true,
          ),
          _buildDetailRow("Issue", data['issue'] ?? '--', isBold: true),
          _buildStatusRow("Status", data['stus'] ?? '--'),
          _buildDetailRow(
            "Spare Name",
            data['spare_name'] ?? '--',
            isBold: true,
          ),
          _buildDetailRow(
            "Quantity",
            data['quantity']?.toString() ?? '--',
            isBold: true,
          ),

          const SizedBox(height: 15),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Uploaded image",
                style: GoogleFonts.outfit(fontSize: 15, color: Colors.black54),
              ),
              const Spacer(),
              GestureDetector(
                onTap: imageUrl.isNotEmpty
                    ? () => _openImageViewer(imageUrl)
                    : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 120,
                          height: 90,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 120,
                              height: 90,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePersonnelCard() {
    final data = _depotData!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            "Work Start Time",
            _formatTime(data['wrk_strt_tym']),
            isBold: true,
          ),
          _buildDetailRow(
            "Work End Time",
            _formatTime(data['wrk_end_tym']),
            isBold: true,
          ),
          _buildDetailRow("Date", _formatDate(data['date']), isBold: true),
          _buildDetailRow("Work Done", data['wrk_done'] ?? '--', isBold: true),
          _buildDetailRow(
            "Updated By",
            data['update_by'] ?? '--',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNarrativeCard({
    required String title,
    required String content,
    required Color titleColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
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

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 15, color: Colors.black54),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 15, color: Colors.black54),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    final data = _depotData!;
    final requestDate = data['request_date'];
    final expectedDate = data['expected_date'];

    return Column(
      children: [
        _buildTimelineItem(
          title: "Complaint Raised",
          subtitle: requestDate != null && requestDate.toString().isNotEmpty
              ? _formatDate(requestDate.toString())
              : "Pending",
          icon: Icons.check_circle,
          iconColor: requestDate != null && requestDate.toString().isNotEmpty
              ? Colors.green
              : Colors.grey.shade400,
          isLast: false,
          isActive: requestDate != null && requestDate.toString().isNotEmpty,
        ),
        _buildTimelineItem(
          title: "Technician visit completed",
          subtitle: expectedDate != null && expectedDate.toString().isNotEmpty
              ? _formatDate(expectedDate.toString())
              : "Pending",
          icon: Icons.check_circle,
          iconColor: expectedDate != null && expectedDate.toString().isNotEmpty
              ? Colors.green
              : Colors.grey.shade400,
          isLast: false,
          isActive: expectedDate != null && expectedDate.toString().isNotEmpty,
        ),
        _buildTimelineItem(
          title: "Quality check",
          subtitle: "",
          icon: Icons.check_circle,
          iconColor: Colors.grey.shade400,
          isLast: false,
          isActive: false,
        ),
        _buildTimelineItem(
          title: "Ready for delivery",
          subtitle: "Labelling for dispatch",
          icon: Icons.check_circle,
          iconColor: Colors.grey.shade400,
          isLast: false,
          isActive: false,
        ),
        _buildTimelineItem(
          title: "Delivered and serviced",
          subtitle: "Handover to customer",
          icon: Icons.check_circle,
          iconColor: Colors.grey.shade400,
          isLast: true,
          isActive: false,
        ),
      ],
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
              Icon(icon, color: iconColor, size: 24),
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
                      color: isActive ? Colors.black : Colors.grey.shade600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAlert() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECB3).withAlpha(150),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Call delivery agent. Button will enable Only after if the the product is ready to deliver",
              style: GoogleFonts.outfit(
                color: Colors.orange.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      width: 120,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 24,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 4),
          Text(
            "No Image",
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            "available",
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullImageViewerScreen extends StatelessWidget {
  final String imageUrl;

  const _FullImageViewerScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Image Preview",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2CB9E5)),
              );
            },
            errorBuilder: (context, error, stackTrace) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.broken_image, color: Colors.white54, size: 64),
                const SizedBox(height: 12),
                Text(
                  "Failed to load image",
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
