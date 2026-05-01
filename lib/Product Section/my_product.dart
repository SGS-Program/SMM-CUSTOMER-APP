import 'package:customer_smm/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'product_details_screen.dart';

class MyProductScreen extends StatefulWidget {
  const MyProductScreen({super.key});

  @override
  State<MyProductScreen> createState() => _MyProductScreenState();
}

class _MyProductScreenState extends State<MyProductScreen> {
  List<dynamic> products = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ Get session data from SharedPreferences
      final String cid = prefs.getString('cid') ?? '';
      final String cusId = prefs.getString('cus_id') ?? '';

      if (cid.isEmpty || cusId.isEmpty) {
        if (mounted) {
          setState(() {
            errorMessage = "Session expired. Please login again.";
            isLoading = false;
          });
        }
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://erpsmart.in/total/api/m_api/'),
      );

      request.fields.addAll({
        'type': '7003',
        'cid': cid,
        'device_id': '123',
        'lt': '123',
        'ln': '987',
        'cus_id': cusId,
      });

      debugPrint("🔍 REQUEST: ${request.fields}");

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("🔍 STATUS: ${response.statusCode}");
      debugPrint("🔍 BODY: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body.trim());
        final bool isError =
            jsonData['error'] == true || jsonData['error'] == "true";

        if (!isError) {
          final List<dynamic> rawOrders = jsonData['data'] ?? [];
          List<Map<String, dynamic>> flattenedProducts = [];

          for (var order in rawOrders) {
            final items = order['items'];
            if (items is List) {
              for (var item in items) {
                flattenedProducts.add({
                  'pname': item['pname']?.toString() ?? 'Unnamed Product',
                  'qty': item['qty']?.toString() ?? '0',
                  'date': item['date']?.toString() ?? '',
                  'order_id': order['id']?.toString() ?? 'N/A',
                  'pimage':
                      item['pimage']?.toString() ??
                      item['photo']?.toString() ??
                      '',
                });
              }
            }
          }

          if (mounted) {
            setState(() {
              products = flattenedProducts;
              isLoading = false;
              if (products.isEmpty) {
                errorMessage = "No products found for this account.";
              }
            });

            // Precache first few images in background
            Future.microtask(() {
              if (!mounted) return;
              final imagesToPrecache = products
                  .map((p) => p['pimage']?.toString() ?? '')
                  .where((url) => url.isNotEmpty && url.startsWith('http'))
                  .take(10)
                  .toList();

              for (final url in imagesToPrecache) {
                precacheImage(CachedNetworkImageProvider(url), context);
              }
            });
          }
        } else {
          if (mounted) {
            setState(() {
              errorMessage =
                  jsonData['message'] ??
                  jsonData['error_msg'] ??
                  "No Data Found";
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = "Server Error: ${response.statusCode}";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Product Error: $e");
      if (mounted) {
        setState(() {
          errorMessage = "Network error. Please check your connection.";
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          "My Product",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: _buildSearchBar(),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? _buildErrorWidget()
                : products.isEmpty
                ? const Center(child: Text("No products found"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final item = products[index];
                      final String pname = item['pname'] ?? 'Unknown';
                      final String qty = item['qty'] ?? '0';
                      String dateStr = item['date'] ?? '';

                      if (dateStr.isNotEmpty) {
                        try {
                          final d = DateTime.parse(dateStr);
                          dateStr = "${d.day} ${_getMonth(d.month)} ${d.year}";
                        } catch (_) {}
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailsScreen(product: item),
                              ),
                            );
                          },
                          child: _buildProductCard(
                            title: pname,
                            subtitle: "Order ID: ${item['order_id']}",
                            units: "$qty Units",
                            date: dateStr.isNotEmpty ? dateStr : "N/A",
                            lastService: "Installed",
                            imagePath: item['pimage'] ?? "",
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? "Failed to fetch data",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: fetchProducts,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonth(int m) {
    const months = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[m];
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
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

  Widget _buildProductCard({
    required String title,
    required String subtitle,
    required String units,
    required String date,
    required String lastService,
    required String imagePath,
  }) {
    return Container(
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
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Center(
                    child: imagePath.isNotEmpty
                        ? (imagePath.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: imagePath,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      _buildNoImagePlaceholder(),
                                )
                              : Image.asset(
                                  imagePath,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildNoImagePlaceholder(),
                                ))
                        : _buildNoImagePlaceholder(),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withAlpha(20),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  units,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
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
                    Text(
                      lastService,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
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

  Widget _buildNoImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_not_supported_outlined,
          size: 40,
          color: Colors.grey.shade300,
        ),
        const SizedBox(height: 4),
        Text(
          "No Image",
          style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey.shade400),
        ),
      ],
    );
  }
}
