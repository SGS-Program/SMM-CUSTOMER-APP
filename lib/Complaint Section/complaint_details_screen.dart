import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ComplaintDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;

  const ComplaintDetailsScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailsScreen> createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen>
    with TickerProviderStateMixin {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  String? _invoicePdfUrl;
  String? _performaPdfUrl;
  bool _isLoadingPdfUrls = true;
  bool _isUpdatingStatus = false;
  Map<String, dynamic>? _fullComplaintData;

  // Happy Code Card flip animation
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFlipped = false;
  bool _showFrontSide = true;

  @override
  void initState() {
    super.initState();

    // Initialize flip animation controller
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _flipAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(
              begin: 0.0,
              end: math.pi / 2,
            ).chain(CurveTween(curve: Curves.easeIn)),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: -math.pi / 2,
              end: 0.0,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 50,
          ),
        ]).animate(_flipController)..addListener(() {
          // Switch face at the midpoint
          if (_flipController.value >= 0.5 && _showFrontSide) {
            setState(() => _showFrontSide = false);
          } else if (_flipController.value < 0.5 && !_showFrontSide) {
            setState(() => _showFrontSide = true);
          }
        });

    final photoUrl = widget.complaint['photo']?.toString();
    if (photoUrl != null && photoUrl.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        precacheImage(CachedNetworkImageProvider(photoUrl), context);
      });
    }
    _fetchComplaintData();
  }

  void _toggleHappyCode() {
    if (_flipController.isAnimating) return;
    if (!_isFlipped) {
      _flipController.forward();
      setState(() => _isFlipped = true);
    } else {
      _flipController.reverse();
      setState(() => _isFlipped = false);
    }
  }

  Future<void> _fetchComplaintData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cid = prefs.getString('cid');
      final String? cusId = prefs.getString('cus_id');
      final String? token = prefs.getString('token');
      final String? deviceId = prefs.getString('device_id');
      final String? ltVal = prefs.getString('lt');
      final String? lnVal = prefs.getString('ln');

      final url = Uri.parse('https://erpsmart.in/total/api/m_api/');

      final response = await http
          .post(
            url,
            body: {
              'type': '7004',
              'cid': cid ?? '44555666',
              'token': token ?? '',
              'device_id': deviceId ?? '123',
              'lt': ltVal ?? '123',
              'ln': lnVal ?? '987',
              'cus_id': cusId ?? '143',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] == false && data['data'] != null) {
          final List complaints = data['data'];
          final currentId = widget.complaint['id']?.toString();

          final currentComplaint = complaints.firstWhere(
            (c) => c['id']?.toString() == currentId,
            orElse: () => null,
          );

          if (currentComplaint != null) {
            setState(() {
              _invoicePdfUrl = currentComplaint['invoice_pdf_url'];
              _performaPdfUrl = currentComplaint['performa_pdf_url'];
              _fullComplaintData = currentComplaint;
              _isLoadingPdfUrls = false;
            });
          } else {
            setState(() => _isLoadingPdfUrls = false);
          }
        } else {
          setState(() => _isLoadingPdfUrls = false);
        }
      } else {
        setState(() => _isLoadingPdfUrls = false);
      }
    } catch (e) {
      debugPrint("Error fetching complaint data: $e");
      setState(() => _isLoadingPdfUrls = false);
    }
  }



  Future<void> _updateSparesStatus() async {
    setState(() => _isUpdatingStatus = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cid = prefs.getString('cid');
      final String? uid = prefs.getString('uid');
      final String? roleId = prefs.getString('role_id');
      final String? token = prefs.getString('token');
      final String? deviceId = prefs.getString('device_id');
      final String? ltVal = prefs.getString('lt');
      final String? lnVal = prefs.getString('ln');
      final String? ticketId = widget.complaint['id']?.toString();

      final url = Uri.parse('https://erpsmart.in/total/api/m_api/');

      final response = await http
          .post(
            url,
            body: {
              'type': '5040',
              'cid': cid ?? '44555666',
              'uid': uid ?? '5',
              'role_id': roleId ?? '2',
              'token': token ?? '',
              'device_id': deviceId ?? '123',
              'lt': ltVal ?? '0.0',
              'ln': lnVal ?? '0.0',
              'ticket_id': ticketId ?? '0',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['error'] == false) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message'] ?? "Spares Received & Status updated successfully",
              ),
              backgroundColor: const Color(0xFF43A047),
            ),
          );
          // Refresh the data to reflect updated status
          _fetchComplaintData();
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? "Failed to update status"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Server error. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  Future<void> _launchURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty || urlString == "null") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("PDF URL not available")));
      return;
    }

    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error opening PDF: $e")));
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
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
        if (!mounted) return;
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

      final response = await http
          .post(
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
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
            _buildDetailsCard(complaint)
                .animate()
                .fade(duration: 400.ms)
                .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),

            // Invoice Buttons
            if (!_isLoadingPdfUrls &&
                (_invoicePdfUrl != null || _performaPdfUrl != null))
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                child: Row(
                  children: [
                    if (_invoicePdfUrl != null &&
                        _invoicePdfUrl != "null" &&
                        _invoicePdfUrl!.isNotEmpty)
                      Expanded(
                        child: _buildPdfButton(
                          label: "View Invoice",
                          icon: Icons.picture_as_pdf,
                          color: const Color(0xFF2CB9E5),
                          onTap: () => _launchURL(_invoicePdfUrl),
                        ),
                      ),
                    if (_invoicePdfUrl != null &&
                        _performaPdfUrl != null &&
                        _invoicePdfUrl != "null" &&
                        _performaPdfUrl != "null" &&
                        _invoicePdfUrl!.isNotEmpty &&
                        _performaPdfUrl!.isNotEmpty)
                      const SizedBox(width: 10),
                    if (_performaPdfUrl != null &&
                        _performaPdfUrl != "null" &&
                        _performaPdfUrl!.isNotEmpty)
                      Expanded(
                        child: _buildPdfButton(
                          label: "View Performa Invoice",
                          icon: Icons.receipt_long,
                          color: const Color(0xFFFF9800),
                          onTap: () => _launchURL(_performaPdfUrl),
                        ),
                      ),
                  ],
                ),
              ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0),

            // Happy Code Card with Flip Animation
            _buildHappyCodeCard(complaint)
                .animate()
                .fade(delay: 200.ms)
                .slideY(begin: 0.2, end: 0)
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                  duration: 800.ms,
                ),

            // Spares Received Button
            _buildSparesButton(),

            // Timeline Section
            _buildTimelineSection(
              complaint,
            ).animate().fade(delay: 300.ms).slideY(begin: 0.1, end: 0),

            // Technician Details Card - Only if assigned or completed
            if (isAssigned)
              _buildTechnicianCard(
                complaint,
              ).animate().fade(delay: 400.ms).slideY(begin: 0.1, end: 0),

            // Rating & Feedback Section - Only for Completed Complaints
            if (isCompleted)
              _buildRatingFeedbackSection()
                  .animate()
                  .fade(delay: 500.ms)
                  .slideY(begin: 0.1, end: 0),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// Happy Code flip card
  Widget _buildHappyCodeCard(Map<String, dynamic> complaint) {
    final happyCode = (complaint['hpy_code']?.toString() ?? '').isEmpty
        ? 'N/A'
        : complaint['hpy_code'].toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: GestureDetector(
        onTap: _toggleHappyCode,
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_flipAnimation.value),
              child: _showFrontSide
                  ? _buildHappyCodeFront()
                  : _buildHappyCodeBack(happyCode),
            );
          },
        ),
      ),
    );
  }

  /// Front face: "Tap to reveal" prompt
  Widget _buildHappyCodeFront() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                  "Tap to reveal",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.touch_app_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .scaleXY(
                begin: 1.0,
                end: 1.18,
                duration: 700.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .scaleXY(
                begin: 1.18,
                end: 1.0,
                duration: 700.ms,
                curve: Curves.easeInOut,
              ),
        ],
      ),
    );
  }

  /// Back face: actual Happy Code with shimmer
  Widget _buildHappyCodeBack(String happyCode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A91B8), Color(0xFF2CB9E5)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2CB9E5).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
                      happyCode,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(
                      duration: 2000.ms,
                      color: Colors.white.withOpacity(0.4),
                    ),
              ],
            ),
          ),
          // Tap again hint
          GestureDetector(
            onTap: _toggleHappyCode,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flip_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
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
    return Hero(
      tag: 'complaint_card_${complaint['id']}',
      child: Container(
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
                    ? CachedNetworkImage(
                        imageUrl: complaint['photo'],
                        width: 100,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const _ShimmerBox(width: 100, height: 80),
                        errorWidget: (context, url, error) =>
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
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Center(
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

  Widget _buildPdfButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection(Map<String, dynamic> complaint) {
    final status = (complaint['status'] ?? '').toString().toLowerCase();

    bool isInProgress =
        status == "assigned" || status == "on the way" || status == "completed";
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
            isLineActive: isInProgress,
            index: 0,
          ),
          _buildTimelineItem(
            title: "In Progress",
            subtitle:
                "Assigned to technician\n${_formatDateTime(complaint['assign_date'])}",
            icon: Icons.info,
            iconColor: Colors.green,
            isLast: false,
            isActive: isInProgress,
            isLineActive: isOnTheWay,
            index: 1,
          ),
          _buildTimelineItem(
            title: "On the Way",
            subtitle: "Technician is on the way to your location",
            icon: Icons.directions_bike_rounded,
            iconColor: Colors.green,
            isLast: false,
            isActive: isOnTheWay,
            isLineActive: isCompleted,
            index: 2,
          ),
          _buildTimelineItem(
            title: "Resolved",
            subtitle:
                "Complaint resolved successfully\n${_formatDateTime(complaint['resolved_date'])}",
            icon: Icons.hourglass_empty,
            iconColor: Colors.green,
            isLast: true,
            isActive: isCompleted,
            index: 4,
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
    bool? isLineActive,
    int index = 0,
  }) {
    bool lineActive = isLineActive ?? isActive;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
                builder: (context, value, child) {
                  return Icon(
                    icon,
                    color: Color.lerp(Colors.grey.shade300, iconColor, value),
                    size: 24,
                  );
                },
              ),
              if (!isLast)
                Expanded(
                  child: _AnimatedTimelineLine(
                    index: index,
                    iconColor: iconColor,
                    isActive: lineActive,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
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

  Widget _buildSparesButton() {
    final complaint = _fullComplaintData ?? widget.complaint;
    final statusIdStr = complaint['status_id']?.toString() ?? '0';
    final statusId = int.tryParse(statusIdStr) ?? 0;
    final bool isReceived = statusId >= 9;

    // Show button if status_id > 5
    if (statusId <= 5) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isReceived
                ? [const Color(0xFF43A047), const Color(0xFF2E7D32)]
                : [const Color(0xFF66BB6A), const Color(0xFF43A047)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF43A047).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: (_isUpdatingStatus || isReceived)
              ? null
              : () {
                  _updateSparesStatus();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isReceived ? Icons.verified_rounded : Icons.inventory_2_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _isUpdatingStatus
                    ? "Updating..."
                    : (isReceived ? "Spares Already Received" : "Mark Spares Received"),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ).animate().fade(delay: 150.ms).slideY(begin: 0.2, end: 0).shimmer(
        delay: 1000.ms,
        duration: 2000.ms,
        color: Colors.white.withOpacity(0.2),
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

class _AnimatedTimelineLine extends StatefulWidget {
  final int index;
  final Color iconColor;
  final bool isActive;

  const _AnimatedTimelineLine({
    required this.index,
    required this.iconColor,
    required this.isActive,
  });

  @override
  State<_AnimatedTimelineLine> createState() => _AnimatedTimelineLineState();
}

class _AnimatedTimelineLineState extends State<_AnimatedTimelineLine> {
  bool _startAnimation = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      Future.delayed(Duration(milliseconds: 400 + (widget.index * 500)), () {
        if (mounted) {
          setState(() => _startAnimation = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      tween: Tween(begin: 0.0, end: _startAnimation ? 1.0 : 0.0),
      builder: (context, value, child) {
        return Container(
          width: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [widget.iconColor, Colors.grey.shade200],
              stops: [value, value],
            ),
          ),
        );
      },
    );
  }
}
