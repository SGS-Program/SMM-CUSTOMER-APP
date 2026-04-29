import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../dashboard.dart';
import '../raise_complaint_screen.dart';
import '../Product Section/my_product.dart';
import '../Complaint Section/my_complaints_screen.dart';

class CustomBottomNav extends StatefulWidget {
  const CustomBottomNav({super.key});

  // Static method to easily change index from child screens if needed
  static void changeIndex(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_CustomBottomNavState>();
    state?.updateIndex(index);
  }

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  int _currentIndex = 0;
  final ValueNotifier<int> _complaintsRefreshNotifier = ValueNotifier<int>(0);

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),
      const RaiseComplaintScreen(),
      const MyProductScreen(),
      MyComplaintsScreen(refreshNotifier: _complaintsRefreshNotifier),
    ];
  }

  void updateIndex(int index) {
    if (index == 3) {
      _complaintsRefreshNotifier.value++;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: _buildCustomBottomNav(),
      ),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF2CB9E5)),
      child: SafeArea(
        child: Container(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.grid_view_outlined, "Dashboard"),
              _buildNavItem(1, Icons.chat_bubble_outline, "Raise Complaint"),
              _buildNavItem(
                2,
                Icons.production_quantity_limits_outlined,
                "Product",
              ),
              _buildNavItem(3, Icons.assignment_outlined, "My Complaint"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => updateIndex(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    _complaintsRefreshNotifier.dispose();
    super.dispose();
  }
}
