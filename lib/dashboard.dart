import 'package:customer_smm/Drawer%20Section/Warranty%20Section/my_warranty.dart';
import 'package:customer_smm/Profile%20Section/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'Drawer Section/Depot Section/depot_report_screen.dart';
import 'widgets/drawer_screen.dart';
import 'raise_complaint_screen.dart';
import 'notification_screen.dart';
import 'Complaint Section/my_complaints_screen.dart';
import 'package:customer_smm/widgets/bottom_nav.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int openTickets = 0;
  int inProgressTickets = 0;
  int closedTickets = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _reProfileFetch();
    RaiseComplaintScreen.fetchInitialData();
    _fetchTicketStats();
  }

  Future<void> _reProfileFetch() async {
    await ProfileState().loadProfile();
    if (ProfileState().profileNotifier.value.name == "User" ||
        ProfileState().profileNotifier.value.name == "Loading...") {
      await ProfileState().fetchProfileFromApi();
    }
  }

  Future<void> _fetchTicketStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cid = prefs.getString('cid') ?? '';
      final cusId = prefs.getString('cus_id') ?? '';
      final deviceId = prefs.getString('device_id') ?? '123';
      final lt = prefs.getString('lt') ?? '0.0';
      final ln = prefs.getString('ln') ?? '0.0';

      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('https://erpsmart.in/total/api/m_api/'),
        body: {
          'type': '7006',
          'cid': cid,
          'token': token,
          'device_id': deviceId,
          'lt': lt,
          'ln': ln,
          'cus_id': cusId,
        },
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] == false) {
          setState(() {
            openTickets = int.tryParse(data['open_tickets'].toString()) ?? 0;
            inProgressTickets = int.tryParse(data['inprocess'].toString()) ?? 0;
            closedTickets =
                int.tryParse((data['resolved'] ?? data['closed']).toString()) ??
                0;
            isLoading = false;
          });
        } else {
          if (mounted) setState(() => isLoading = false);
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTab = screenWidth > 600;
    final horizontalPadding = isTab ? 40.0 : 20.0;

    return Scaffold(
      drawer: const CustomAppDrawer(),
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                MediaQuery.paddingOf(context).top + 15,
                horizontalPadding,
                25,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF2CB9E5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Scaffold.of(context).openDrawer(),
                          child: Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: isTab ? 32 : 28,
                          ),
                        ),
                        ValueListenableBuilder<UserProfile>(
                          valueListenable: ProfileState().profileNotifier,
                          builder: (context, profile, child) {
                            return Row(
                              children: [
                                Text(
                                  "Hi ${profile.name}!",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: isTab ? 20 : 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "👋",
                                  style: TextStyle(fontSize: isTab ? 20 : 18),
                                ),
                              ],
                            );
                          },
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.notifications_none,
                              color: const Color(0xFF2CB9E5),
                              size: isTab ? 24 : 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          title: "Open Tickets",
                          value: isLoading ? "—" : "$openTickets",
                          iconWidget: _buildTicketIcon(),
                          valueColor: const Color(0xFFFF7043),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          title: "Resolved",
                          value: isLoading ? "—" : "$closedTickets",
                          iconWidget: _buildClosedIcon(),
                          valueColor: const Color(0xFFC62828),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  (() {
                    int total = openTickets + inProgressTickets + closedTickets;
                    double progress = total > 0
                        ? (inProgressTickets / total)
                        : 0.0;
                    return _buildProgressCard(
                      title: "In Progress",
                      value: isLoading ? "—" : "$inProgressTickets",
                      progress: isLoading ? 0.0 : progress,
                      progressLabel: isLoading
                          ? "Loading..."
                          : (total > 0
                                ? "${(progress * 100).toInt()}% of total tickets"
                                : "No tickets found"),
                      iconWidget: _buildInProgressIcon(),
                    );
                  })(),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Quick actions",
                      style: GoogleFonts.outfit(
                        fontSize: isTab ? 24 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Raise Complaint Card
                    _buildQuickActionCard(
                      icon: _buildRocketIcon(),
                      title: "Raise Complaint",
                      subtitle: "Report issue instantly",
                      onTap: () {
                        CustomBottomNav.changeIndex(context, 1);
                      },
                    ),
                    const SizedBox(height: 15),

                    // Small actions Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallActionCard(
                            icon: _buildToolsIcon(),
                            title: "Deport Report",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const DepotReportScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildSmallActionCard(
                            icon: _buildWarrantyIcon(),
                            title: "Check Warranty",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const MyWarrantyScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // My Complaint Card
                    _buildWideActionCard(
                      icon: _buildMyComplaintIcon(),
                      title: "My Complaint",
                      onTap: () {
                        CustomBottomNav.changeIndex(context, 3);
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required Widget iconWidget,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          iconWidget,
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D47A1),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard({
    required String title,
    required String value,
    required double progress,
    required String progressLabel,
    required Widget iconWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              iconWidget,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0D47A1),
                  ),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFB300),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.blue.shade50,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2CB9E5),
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  progressLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required Widget iconWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          iconWidget,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0D47A1),
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1976D2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required Widget icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 15),
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
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallActionCard({
    required Widget icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 125,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            SizedBox(height: 40, child: icon),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildWideActionCard({
    required Widget icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 15),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade800,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketIcon() {
    return Image.asset(
      'assets/tickets.png',
      width: 40,
      height: 40,
      fit: BoxFit.contain,
    );
  }

  Widget _buildClosedIcon() {
    return Image.asset(
      'assets/resolved.png',
      width: 40,
      height: 40,
      fit: BoxFit.contain,
    );
  }

  Widget _buildInProgressIcon() {
    return Image.asset(
      'assets/progress.png',
      width: 50,
      height: 50,
      fit: BoxFit.contain,
    );
  }

  Widget _buildResolvedIcon() {
    return Image.asset(
      'assets/resolved.png',
      width: 40,
      height: 40,
      fit: BoxFit.contain,
    );
  }

  Widget _buildRocketIcon() {
    return Stack(
      children: [
        Container(width: 45, height: 45, color: Colors.white),
        const Icon(
          Icons.rocket_launch_rounded,
          color: Color(0xFFEA4335),
          size: 40,
        ),
      ],
    );
  }

  Widget _buildToolsIcon() {
    return const Icon(
      Icons.handyman_rounded,
      color: Color(0xFFFFB300),
      size: 38,
    );
  }

  Widget _buildWarrantyIcon() {
    return const Icon(
      Icons.verified_user_rounded,
      color: Color(0xFF4CAF50),
      size: 38,
    );
  }

  Widget _buildMyComplaintIcon() {
    return Image.asset(
      'assets/my_complaint.png',
      width: 75,
      height: 50,
      fit: BoxFit.contain,
    );
  }
}
