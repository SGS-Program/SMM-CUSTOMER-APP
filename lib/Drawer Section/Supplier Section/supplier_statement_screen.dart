import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SupplierStatementScreen extends StatefulWidget {
  const SupplierStatementScreen({super.key});

  @override
  State<SupplierStatementScreen> createState() =>
      _SupplierStatementScreenState();
}

class _SupplierStatementScreenState extends State<SupplierStatementScreen> {
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
          "Supplier statement",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  // Supplier Info Card
                  _buildSupplierInfoCard(),
                  const SizedBox(height: 20),

                  // Outstanding Balance Card
                  _buildBalanceCard(),
                  const SizedBox(height: 20),

                  // Filter Row
                  _buildFilterRow(),
                  const SizedBox(height: 25),

                  // Statement Table
                  _buildStatementTable(),
                ],
              ),
            ),
          ),

          // Bottom Buttons
          _buildBottomButtons(padding),
        ],
      ),
    );
  }

  Widget _buildSupplierInfoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.business, color: Colors.blueGrey, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SMM Power solution",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                // Text(
                //   "SUP-00045",
                //   style: GoogleFonts.outfit(
                //     fontSize: 14,
                //     color: Colors.grey.shade600,
                //   ),
                // ),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.phone_outlined, "98765 54310"),
                const SizedBox(height: 5),
                _buildInfoRow(
                  Icons.email_outlined,
                  "info@srivenkateshwara.com",
                ),
                const SizedBox(height: 5),
                _buildInfoRow(
                  Icons.location_on_outlined,
                  "123, Main Road, Trichy - 620001",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.green),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 15,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Outstanding Balance",
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                "₹ 4,25,430.00",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "( Payable )",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.lightGreenAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 10),
                Text(
                  "DD-MM-YEAR",
                  style: GoogleFonts.outfit(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Select Transaction",
                  style: GoogleFonts.outfit(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatementTable() {
    return Column(
      children: [
        // Table Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Row(
            children: [
              _buildHeaderCell("Date", 1.5),
              _buildHeaderCell("Ref.no", 2.0),
              _buildHeaderCell("Transaction", 2.5, align: TextAlign.right),
              _buildHeaderCell("Balance", 2.0, align: TextAlign.right),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Divider(color: Colors.grey.shade200, height: 1),

        // Table Rows
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 10,
          separatorBuilder: (context, index) =>
              Divider(color: Colors.grey.shade100, height: 1),
          itemBuilder: (context, index) {
            final isEven = index % 2 == 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
              child: Row(
                children: [
                  _buildDataCell("01/03/26", 1.5),
                  _buildDataCell("INV-000125", 2.0),
                  _buildDataCell(
                    isEven ? "+ ₹ 4,25,430.00" : "- ₹ 4,25,430.00",
                    2.5,
                    color: isEven ? Colors.green : Colors.red,
                    align: TextAlign.right,
                  ),
                  _buildDataCell(
                    "₹ 4,2500",
                    2.0,
                    color: Colors.green,
                    align: TextAlign.right,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeaderCell(
    String text,
    double flex, {
    TextAlign align = TextAlign.left,
  }) {
    return Expanded(
      flex: (flex * 10).toInt(),
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.outfit(
          fontSize: 16,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDataCell(
    String text,
    double flex, {
    Color color = Colors.black87,
    TextAlign align = TextAlign.left,
  }) {
    return Expanded(
      flex: (flex * 10).toInt(),
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.outfit(
          fontSize: 14,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomButtons(double padding) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2CB9E5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Download",
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2CB9E5),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2CB9E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Share Statement",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
