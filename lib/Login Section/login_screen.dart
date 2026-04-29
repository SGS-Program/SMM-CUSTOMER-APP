import 'dart:convert';

import 'otp_verification_screen.dart';
import 'package:customer_smm/utils/device_services.dart';
import 'package:customer_smm/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _lt;
  String? _ln;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _fetchDeviceInfo();
  }

  Future<void> _fetchDeviceInfo() async {
    final deviceData = await DeviceServices.getAndStoreDeviceInfo();
    if (mounted) {
      setState(() {
        _lt = deviceData['lt'];
        _ln = deviceData['ln'];
        _deviceId = deviceData['device_id'];
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _validateAndSubmit() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      _showError("Please enter a valid 10-digit mobile number");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Ensure Device Info is fetched if not already
      if (_lt == null || _ln == null || _deviceId == null || _lt == '0.0' || _ln == '0.0') {
        final deviceData = await DeviceServices.getAndStoreDeviceInfo();
        _lt = deviceData['lt'];
        _ln = deviceData['ln'];
        _deviceId = deviceData['device_id'];
      }

      final ln = _ln ?? '0.0';
      final lt = _lt ?? '0.0';
      final deviceId = _deviceId ?? '123';

      if (ln == '0.0' || lt == '0.0') {
        setState(() => _isLoading = false);
        if (mounted) {
          DeviceServices.showLocationRequiredPopup(context, onRetry: () {
            _fetchDeviceInfo();
          });
        }
        return;
      }

      debugPrint("🔍 DEVICE INFO FOR LOGIN");
      debugPrint(" Device ID : $deviceId");
      debugPrint(" Latitude : $lt");
      debugPrint(" Longitude : $ln");
      debugPrint("========================================");

      final prefs = await SharedPreferences.getInstance();

      final response = await http
          .post(
            Uri.parse("https://erpsmart.in/total/api/m_api/"),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              "type": "5000",
              "ln": ln,
              "lt": lt,
              "device_id": deviceId,
              "mobile": phone,
            },
          )
          .timeout(const Duration(seconds: 15));

      debugPrint("🔍 API Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['error'] == false || data['error'] == "false") {
          final String cid = data['cid']?.toString() ?? '';
          await prefs.setString('cid', cid);

          final String cusId = data['cus_id']?.toString() ?? '';
          if (cusId.isNotEmpty) {
            await prefs.setString('cus_id', cusId);
          } else {
            await prefs.remove('cus_id');
          }

          final String userName = data['name']?.toString() ?? '';
          if (userName.isNotEmpty) {
            await prefs.setString('name', userName);
          } else {
            await prefs.remove('name');
          }

          final String compName = data['comp_name']?.toString() ?? '';
          if (compName.isNotEmpty) {
            await prefs.setString('comp_name', compName);
          } else {
            await prefs.remove('comp_name');
          }

          await prefs.setString('token', data['token']?.toString() ?? '');
          await prefs.setString('otp', data['otp']?.toString() ?? '');
          await prefs.setString('mobile', phone);
          await prefs.setString('lt', lt);
          await prefs.setString('ln', ln);
          await prefs.setString('device_id', deviceId);
          await prefs.setString('user_data', response.body);

          debugPrint("✅ OTP SENT SUCCESSFULLY - Stored Data:");
          debugPrint(" cid       : $cid");
          debugPrint(" cus_id    : $cusId");
          debugPrint(" name      : $userName");
          debugPrint(" comp_name : $compName");
          debugPrint(" mobile    : $phone");
          debugPrint(" device_id : $deviceId");
          debugPrint(" lt        : $lt");
          debugPrint(" ln        : $ln");
          debugPrint(" otp       : ${data['otp']}");
          debugPrint("===========================================");

          if (mounted) {
            _showOTPBottomSheet(
              phone: phone,
              cid: cid,
              ln: ln,
              lt: lt,
              deviceId: deviceId,
              otp: data['otp']?.toString() ?? '',
            );
          }
        } else {
          _showError(
            data['error_msg'] ?? data['message'] ?? "Failed to send OTP",
          );
        }
      } else {
        _showError("Server error (${response.statusCode}). Please try again.");
      }
    } catch (e) {
      debugPrint("❌ Login Error: $e");
      _showError("Connection error. Please check your internet.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showOTPBottomSheet({
    required String phone,
    required String cid,
    required String ln,
    required String lt,
    required String deviceId,
    required String otp,
  }) {
    final loginContext = context;

    showModalBottomSheet(
      context: loginContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => OtpVerificationSheet(
        phoneNumber: "+91 $phone",
        mobile: phone,
        cid: cid,
        ln: ln,
        lt: lt,
        deviceId: deviceId,
        otp: otp,
        onVerify: () {
          debugPrint("✅ Verification successful, navigating to Dashboard");
          Navigator.of(sheetContext).pop();
          if (mounted) {
            Navigator.of(loginContext).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const CustomBottomNav()),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildBackgroundShapes(screenWidth, screenHeight),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.1),
                    Center(
                      child: Container(
                        height: screenHeight * 0.3,
                        child: Image.asset(
                          'assets/login.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.mobile_friendly,
                                size: 100,
                                color: Colors.blue,
                              ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    Text(
                      "Enter Your Mobile Number",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 15),
                          Text(
                            "+ 91",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 2,
                            height: 25,
                            color: const Color(0xFF2CB9E5).withOpacity(0.5),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              onChanged: (value) {
                                setState(() {});
                              },
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              decoration: const InputDecoration(
                                hintText: "Enter your phone number",
                                border: InputBorder.none,
                                counterText: "",
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _validateAndSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _phoneController.text.length == 10
                              ? const Color(0xFF30BDEC)
                              : const Color(0xFFB9EAF7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                "Get OTP",
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    Column(
                      children: [
                        Text(
                          "By Continuing you agree to our",
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            "Terms and Conditions",
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF38C2E9),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.05),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundShapes(double width, double height) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: height * 0.30,
          child: CustomPaint(painter: TopShapePainter()),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: height * 0.35,
          child: CustomPaint(painter: BottomShapePainter()),
        ),
      ],
    );
  }
}

class TopShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bluePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF81D4FA), Color(0xFF2CB9E5)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final mainPath = Path();
    mainPath.moveTo(size.width * 0.3, 0);
    mainPath.lineTo(size.width, 0);
    mainPath.lineTo(size.width, size.height * 0.8);
    mainPath.close();
    canvas.drawPath(mainPath, bluePaint);

    final pillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB3E5FC), Color(0xFF4FC3F7)],
      ).createShader(Rect.fromLTWH(0, 0, size.width * 0.3, size.height));

    canvas.save();
    canvas.translate(-size.width * 0.1, size.height * 0.2);
    canvas.rotate(-0.75);
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width * 0.3, size.height * 1.2),
      Radius.circular(size.width * 0.15),
    );
    canvas.drawRRect(pillRect, pillPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BottomShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bluePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFF81D4FA), Color(0xFF2CB9E5)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final mainPath = Path();
    mainPath.moveTo(0, size.height * 0.2);
    mainPath.lineTo(0, size.height);
    mainPath.lineTo(size.width * 0.7, size.height);
    mainPath.close();
    canvas.drawPath(mainPath, bluePaint);

    final pillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB3E5FC), Color(0xFF4FC3F7)],
      ).createShader(Rect.fromLTWH(0, 0, size.width * 0.3, size.height));

    canvas.save();
    canvas.translate(size.width * 0.8, size.height * 0.4);
    canvas.rotate(-0.75);
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width * 0.3, size.height * 1.2),
      Radius.circular(size.width * 0.15),
    );
    canvas.drawRRect(pillRect, pillPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
