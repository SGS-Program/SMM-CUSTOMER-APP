import 'dart:convert';
import 'package:customer_smm/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'complaint_details_screen.dart';

class MyComplaintsScreen extends StatefulWidget {
  final ValueNotifier<int>? refreshNotifier;
  const MyComplaintsScreen({super.key, this.refreshNotifier});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  String selectedFilter = "All";
  final List<String> filters = [
    "All",
    "Pending",
    "Opened",
    "Assigned",
    "On the Way",
    "Completed",
  ];

  List<Map<String, dynamic>> allComplaints = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCachedComplaints().then((_) {
      _fetchComplaints(showLoading: allComplaints.isEmpty);
    });

    widget.refreshNotifier?.addListener(_handleRefresh);
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_handleRefresh);
    super.dispose();
  }

  void _handleRefresh() {
    if (mounted) {
      _fetchComplaints(showLoading: false);
    }
  }

  Future<void> _loadCachedComplaints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString('cached_complaints');
      if (cachedData != null) {
        final List<dynamic> decoded = json.decode(cachedData);
        if (mounted) {
          setState(() {
            allComplaints = decoded
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Load cached complaints error: $e");
    }
  }

  Future<void> _fetchComplaints({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final String cid = prefs.getString('cid') ?? '';
      final String cusId = prefs.getString('cus_id') ?? '';
      final String deviceId = prefs.getString('device_id') ?? '123';
      final String lt = prefs.getString('lt') ?? '123';
      final String ln = prefs.getString('ln') ?? '987';

      final response = await http
          .post(
            Uri.parse("https://erpsmart.in/total/api/m_api/"),
            body: {
              "type": "7004",
              "cid": cid,
              "device_id": deviceId,
              "lt": lt,
              "ln": ln,
              "cus_id": cusId,
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] == false) {
          final List<dynamic> raw = data['data'] ?? [];
          if (mounted) {
            setState(() {
              allComplaints = raw.map((item) {
                String formattedDate = '';
                try {
                  final dt = DateTime.parse(item['preferred visit date'] ?? '');
                  const months = [
                    '',
                    'Jan',
                    'Feb',
                    'Mar',
                    'Apr',
                    'May',
                    'Jun',
                    'Jul',
                    'Aug',
                    'Sep',
                    'Oct',
                    'Nov',
                    'Dec',
                  ];
                  formattedDate =
                      '${dt.day.toString().padLeft(2, '0')} ${months[dt.month]} ${dt.year}';
                } catch (_) {
                  formattedDate = item['preferred visit date'] ?? '';
                }

                final engineer = item['engineer'];
                final hasEngineer = engineer != null && engineer is Map;

                return {
                  "id": item['id']?.toString() ?? '',
                  "name": item['customer_id']?.toString() ?? '',
                  "product": item['product_id']?.toString() ?? '',
                  "description": item['Description']?.toString() ?? '',
                  "date": formattedDate,
                  "status": item['status']?.toString() ?? '',
                  "address": item['address']?.toString() ?? '',
                  "photo": item['photo']?.toString() ?? '',
                  "audio": item['audio']?.toString() ?? '',
                  "complaint_title": item['complaint title']?.toString() ?? '',
                  "remarks": item['remarks']?.toString() ?? '',
                  "request_date": item['request_date']?.toString() ?? '',
                  "assign_date": item['assign_date']?.toString() ?? '',
                  "expected_date": item['expected_date']?.toString() ?? '',
                  "resolved_date": item['resolved_date']?.toString() ?? '',
                  "tech_name": hasEngineer
                      ? engineer['tech_name']?.toString() ?? ''
                      : '',
                  "tech_mobile": hasEngineer
                      ? engineer['tech_mobile']?.toString() ?? ''
                      : '',
                  "tech_email": hasEngineer
                      ? engineer['tech_email']?.toString() ?? ''
                      : '',
                  "engineer": item['engineer'],
                  "hpy_code": item['hpy_code']?.toString() ?? '',
                };
              }).toList();
              _isLoading = false;
            });

            // Precache first few images in background
            Future.microtask(() {
              if (!mounted) return;
              final imagesToPrecache = allComplaints
                  .map((c) => c['photo']?.toString() ?? '')
                  .where((url) => url.isNotEmpty)
                  .take(10)
                  .toList();

              for (final url in imagesToPrecache) {
                precacheImage(CachedNetworkImageProvider(url), context);
              }
            });

            // Save to cache
            final prefs = await SharedPreferences.getInstance();
            prefs.setString('cached_complaints', json.encode(allComplaints));
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = data['message'] ?? 'Failed to fetch complaints';
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Server error. Please try again.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Fetch complaints error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTab = MediaQuery.of(context).size.width > 600;

    // Filter logic
    final filteredComplaints = selectedFilter == "All"
        ? allComplaints
        : allComplaints
              .where(
                (c) =>
                    c["status"].toString().toLowerCase() ==
                    selectedFilter.toLowerCase(),
              )
              .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2CB9E5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => CustomBottomNav.changeIndex(context, 0),
        ),
        title: Text(
          "My Complaints",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: filters
                    .map((filter) => _buildFilterChip(filter))
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Complaints List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2CB9E5)),
                  )
                : _errorMessage.isNotEmpty
                ? _buildErrorState()
                : filteredComplaints.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: const Color(0xFF2CB9E5),
                    onRefresh: () => _fetchComplaints(showLoading: false),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredComplaints.length,
                      itemBuilder: (context, index) {
                        final complaint = filteredComplaints[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ComplaintDetailsScreen(
                                  complaint: complaint,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 15.0),
                            child: _buildComplaintCard(
                              name: complaint["name"],
                              product: complaint["product"],
                              description: complaint["description"],
                              date: complaint["date"],
                              status: complaint["status"],
                              isTab: isTab,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_late_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          Text(
            "No $selectedFilter Complaints Found",
            style: GoogleFonts.outfit(
              fontSize: 18,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            _errorMessage,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _fetchComplaints(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2CB9E5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              "Retry",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2CB9E5) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF2CB9E5), width: 1.5),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.white : const Color(0xFF2CB9E5),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // Helper to get status colors
  Map<String, Color> _getStatusColors(String status) {
    String s = status.toLowerCase();
    switch (s) {
      case "pending":
        return {"bg": const Color(0xFFFFE0B2), "text": const Color(0xFFFB8C00)};
      case "opened":
        return {"bg": const Color(0xFFB3E5FC), "text": const Color(0xFF039BE5)};
      case "assigned":
        return {"bg": const Color(0xFFE1BEE7), "text": const Color(0xFF8E24AA)};
      case "on the way":
        return {"bg": const Color(0xFFE0F7FA), "text": const Color(0xFF0097A7)};
      case "completed":
        return {"bg": const Color(0xFFC8E6C9), "text": const Color(0xFF43A047)};
      default:
        return {"bg": Colors.grey.shade200, "text": Colors.grey};
    }
  }

  Widget _buildComplaintCard({
    required String name,
    required String product,
    required String description,
    required String date,
    required String status,
    required bool isTab,
  }) {
    final colors = _getStatusColors(status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors["bg"],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.outfit(
                    color: colors["text"],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            product,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: const Color(0xFF43A047),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.black.withAlpha(180),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            date,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
