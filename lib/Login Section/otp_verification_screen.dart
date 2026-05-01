import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_autofill/sms_autofill.dart';

class OtpVerificationSheet extends StatefulWidget {
  final String phoneNumber;
  final String mobile;
  final String cid;
  final String ln;
  final String lt;
  final String deviceId;
  final String otp;
  final VoidCallback onVerify;

  const OtpVerificationSheet({
    super.key,
    required this.phoneNumber,
    required this.mobile,
    required this.cid,
    required this.ln,
    required this.lt,
    required this.deviceId,
    required this.otp,
    required this.onVerify,
  });

  @override
  State<OtpVerificationSheet> createState() => _OtpVerificationSheetState();
}

class _OtpVerificationSheetState extends State<OtpVerificationSheet> with CodeAutoFill {
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  Future<void> _startListening() async {
    await SmsAutoFill().listenForCode();
    debugPrint("📥 SMS Listener Started...");
    final signature = await SmsAutoFill().getAppSignature;
    debugPrint("🔑 Local App Signature for SMS: $signature");
  }

  @override
  void codeUpdated() {
    if (code != null && code!.isNotEmpty) {
      debugPrint("📱 SMS OTP Received: $code");
      String numericOtp = code!.replaceAll(RegExp(r'[^0-9]'), '');
      if (numericOtp.length == 6) {
        for (int i = 0; i < 6; i++) {
          _controllers[i].text = numericOtp[i];
        }
        _verifyOtp();
      }
    }
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    unregisterListener();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_isLoading) return;

    final rawOtp = _controllers.map((c) => c.text.trim()).join();
    final otp = rawOtp.replaceAll(RegExp(r'[^0-9]'), '');

    debugPrint(
      "🔢 RAW OTP collected: '$rawOtp' | cleaned OTP: '$otp' | length: ${otp.length}",
    );

    if (otp.length != 6) {
      _showError("Please enter complete 6-digit OTP");
      return;
    }

    setState(() => _isLoading = true);

    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      final cid = widget.cid;
      final ln = widget.ln;
      final lt = widget.lt;
      final deviceId = widget.deviceId;
      final mobile = widget.mobile;

      debugPrint("══════════════════════════════════════════════");
      debugPrint("🔑 OTP entered by user : '$otp'");
      debugPrint(
        "📤 Params → mobile:$mobile | cid:'$cid' | device_id:$deviceId",
      );
      debugPrint("══════════════════════════════════════════════");

      // ✅ SINGLE CORRECT API CALL (WITH CID)
      final response = await http
          .post(
            Uri.parse("https://erpsmart.in/total/api/m_api/"),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: {
              "type": "5004",
              "cid": cid,
              "ln": ln,
              "lt": lt,
              "device_id": deviceId,
              "mobile": mobile,
              "otp": otp,
            },
          )
          .timeout(const Duration(seconds: 20));

      debugPrint("🔍 OTP Verify Response: ${response.body}");
      debugPrint("🔍 Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['error'] == false || data['error'] == "false") {
          final prefs = await SharedPreferences.getInstance();
          final String existingCusId = prefs.getString('cus_id') ?? '';

          await prefs.setString('token', data['token']?.toString() ?? '');
          await prefs.setString('user_id', data['user_id']?.toString() ?? '');
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('verify_response', response.body);

          final String verifiedCusId = data['cus_id']?.toString() ?? '';
          final String finalCusId = verifiedCusId.isNotEmpty
              ? verifiedCusId
              : existingCusId;
          if (finalCusId.isNotEmpty) {
            await prefs.setString('cus_id', finalCusId);
          }

          final String verifiedCid = data['cid']?.toString() ?? '';
          final String finalCid = verifiedCid.isNotEmpty ? verifiedCid : cid;
          if (finalCid.isNotEmpty) {
            await prefs.setString('cid', finalCid);
          }

          final String name = data['name']?.toString() ?? '';
          if (name.isNotEmpty) {
            await prefs.setString('name', name);
          }

          final String address = data['address']?.toString() ?? '';
          await prefs.setString('address', address);

          final String mobileFromServer = data['mobile']?.toString() ?? '';
          if (mobileFromServer.isNotEmpty) {
            await prefs.setString('mobile', mobileFromServer);
          }

          final String compName = data['comp_name']?.toString() ?? '';
          if (compName.isNotEmpty) {
            await prefs.setString('comp_name', compName);
          }

          debugPrint("✅ Verification Successful");

          if (mounted) {
            widget.onVerify();
          }
        } else {
          _showError(
            data['message'] ?? data['error_msg'] ?? "OTP verification failed",
          );
        }
      } else {
        _showError("Server error (${response.statusCode}). Please try again.");
      }
    } catch (e) {
      debugPrint("❌ Verification Error: $e");
      _showError("Connection error. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    final scale = screenWidth / 360;

    return Container(
      padding: EdgeInsets.fromLTRB(
        25 * scale,
        30 * scale,
        25 * scale,
        MediaQuery.of(context).viewInsets.bottom + 20 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30 * scale),
          topRight: Radius.circular(30 * scale),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Verify with OTP",
              style: GoogleFonts.outfit(
                fontSize: 22 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 15 * scale),
            Image.asset(
              'assets/otp.png',
              height: 130 * scale,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.security,
                size: 80,
                color: Color(0xFF2CB9E5),
              ),
            ),
            SizedBox(height: 20 * scale),
            Text(
              "Waiting to automatically detect an OTP sent to",
              style: GoogleFonts.outfit(
                color: Colors.grey.shade600,
                fontSize: 14 * scale,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.outfit(
                  fontSize: 14 * scale,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: "${widget.phoneNumber}. ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: "Wrong Number?",
                    style: const TextStyle(
                      color: Color(0xFF2CB9E5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30 * scale),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return Container(
                  width: 45 * scale,
                  height: 52 * scale,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10 * scale),
                    border: Border.all(
                      color: const Color(0xFF2CB9E5).withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: GoogleFonts.outfit(
                      fontSize: 22 * scale,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    readOnly: _isLoading,
                    decoration: const InputDecoration(
                      counterText: "",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      setState(() {});
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            SizedBox(height: 12 * scale),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Resend OTP",
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2CB9E5),
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "00:57",
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2CB9E5).withOpacity(0.6),
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 40 * scale),

            SizedBox(
              width: double.infinity,
              height: 55 * scale,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _controllers.every((c) => c.text.isNotEmpty)
                      ? const Color(0xFF30BDEC)
                      : const Color(0xFFB9EAF7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30 * scale),
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
                        "Verify",
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 15 * scale),
          ],
        ),
      ),
    );
  }
}
