import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'warranty_details_screen.dart';

class MyWarrantyScreen extends StatefulWidget {
  const MyWarrantyScreen({super.key});

  @override
  State<MyWarrantyScreen> createState() => _MyWarrantyScreenState();
}

class _MyWarrantyScreenState extends State<MyWarrantyScreen> {
  List<dynamic> _warrantyData = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchWarrantyData();
  }

  Future<void> _fetchWarrantyData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cid = prefs.getString('cid') ?? '';
      final String uid = prefs.getString('uid') ?? '';
      final String roleId = prefs.getString('role_id') ?? '';
      final String cusId = prefs.getString('cus_id') ?? '';
      final String token = prefs.getString('token') ?? '';
      final String deviceId = prefs.getString('device_id') ?? '';
      final String lt = prefs.getString('lt') ?? '';
      final String ln = prefs.getString('ln') ?? '';

      final response = await http
          .post(
            Uri.parse("https://erpsmart.in/total/api/m_api/"),
            body: {
              "type": "7012",
              "cid": cid,
              "device_id": deviceId,
              "lt": lt,
              "ln": ln,
              "cus_id": cusId,
              "token": token,
              "role_id": roleId,
              "uid": uid,
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] == false) {
          setState(() {
            _warrantyData = data['data'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching warranty: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _warrantyData.where((item) {
      final items = item['items'] as List?;
      final pname = (items != null && items.isNotEmpty)
          ? items[0]['pname']?.toString().toLowerCase() ?? ""
          : "";
      return pname.contains(_searchQuery.toLowerCase());
    }).toList();

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
          "My Warranty",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: _buildSearchBar(),
          ),

          // Product List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2CB9E5)),
                  )
                : filteredData.isEmpty
                ? Center(
                    child: Text(
                      "No Data Available",
                      style: GoogleFonts.outfit(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final item = filteredData[index];
                      final productItems = item['items'] as List?;
                      final firstItem =
                          (productItems != null && productItems.isNotEmpty)
                          ? productItems[0]
                          : null;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: _buildWarrantyCard(
                          context,
                          title: firstItem?['pname'] ?? "N/A",
                          subtitle: item['invoice_no'] ?? "N/A",
                          date: item['warranty_expiry'] ?? "N/A",
                          lastService: " ${item['date'] ?? 'N/A'}",
                          status: item['warranty_status'] ?? "N/A",
                          imageUrl: firstItem?['product_image'] ?? "",
                          fullData: item,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey.shade400, size: 22),
          hintText: "search a product",
          hintStyle: GoogleFonts.outfit(
            color: Colors.grey.shade400,
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildWarrantyCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String date,
    required String lastService,
    required String status,
    required String imageUrl,
    required dynamic fullData,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WarrantyDetailsScreen(warrantyData: fullData),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(strokeWidth: 2),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.precision_manufacturing_outlined,
                            size: 40,
                          ),
                        )
                      : const Icon(
                          Icons.precision_manufacturing_outlined,
                          size: 40,
                          color: Color(0xFF2CB9E5),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 15),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: status.toLowerCase() == "active"
                              ? Colors.green.withAlpha(40)
                              : Colors.red.withAlpha(40),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: status.toLowerCase() == "active"
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    date,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFFFFB300),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          lastService,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
