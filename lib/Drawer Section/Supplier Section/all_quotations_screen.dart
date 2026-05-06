import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AllQuotationsScreen extends StatefulWidget {
  const AllQuotationsScreen({super.key});

  @override
  State<AllQuotationsScreen> createState() => _AllQuotationsScreenState();
}

class _AllQuotationsScreenState extends State<AllQuotationsScreen> {
  String _selectedFilter = "ALL";

  final List<Map<String, dynamic>> _quotations = [
    {
      "title": "L2 Managed Switch - 48 Port",
      "invoice": "INV-2023-0042",
      "price": "₹4,200.00",
      "date": "3 Apr 2026",
      "status": "Paid",
      "statusColor": Colors.green,
    },
    {
      "title": "L2 Managed Switch - 48 Port",
      "invoice": "INV-2023-0042",
      "price": "₹4,200.00",
      "date": "3 Apr 2026",
      "status": "Pending",
      "statusColor": const Color(0xFFC0CA33),
    },
    {
      "title": "L2 Managed Switch - 48 Port",
      "invoice": "INV-2023-0042",
      "price": "₹4,200.00",
      "date": "3 Apr 2026",
      "status": "Draft",
      "statusColor": Colors.blue,
    },
    {
      "title": "L2 Managed Switch - 48 Port",
      "invoice": "INV-2023-0042",
      "price": "₹4,200.00",
      "date": "3 Apr 2026",
      "status": "Pending",
      "statusColor": const Color(0xFFC0CA33),
    },
    {
      "title": "L2 Managed Switch - 48 Port",
      "invoice": "INV-2023-0042",
      "price": "₹4,200.00",
      "date": "3 Apr 2026",
      "status": "Paid",
      "statusColor": Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2CB9E5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "All Quotation",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 15),
              ),
              child: Text(
                "+ NEW",
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2CB9E5),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.fromLTRB(padding, 20, padding, 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey.shade400),
                  hintText: "Search Invoice or Customer...",
                  hintStyle: GoogleFonts.outfit(
                    color: Colors.grey.shade400,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // Filters
          _buildFilters(),
          const SizedBox(height: 15),

          // Quotation List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: padding),
              itemCount: _quotations.length,
              itemBuilder: (context, index) {
                return _buildQuotationCard(_quotations[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ["ALL", "SEND", "PENDING", "DRAFT"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2CB9E5)
                      : const Color(0xFFB2DFDB).withAlpha(100),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuotationCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'],
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['invoice'],
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data['price'],
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data['date'],
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: data['statusColor'],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  data['status'],
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
