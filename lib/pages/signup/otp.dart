import 'dart:async';

import 'package:fitnora/animations.dart';
import 'package:fitnora/components/alert.dart';
import 'package:fitnora/components/dialog.dart';
import 'package:fitnora/pages/reset_password.dart';
import 'package:fitnora/pages/signup/user_details.dart';
import 'package:fitnora/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class OtpPage extends StatefulWidget {
  final String email;
  final String purpose;
  const OtpPage({super.key, required this.email, required this.purpose});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController otpController = TextEditingController();
  bool _isLoading = false;
  int _resendSeconds = 0;
  Timer? _timer;

  void _startResendTimer() {
    _resendSeconds = 60;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _resendSeconds--;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: goBack,
      child: Scaffold(
        appBar: AppBar(leading: BackButton()),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter the confirmation code",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),

              const SizedBox(height: 8),
              const Text(
                "To confirm your account, enter the 6-digit code we sent to your email.",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 40),

              Pinput(
                controller: otpController,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                length: 6,
                keyboardType: TextInputType.number,
                defaultPinTheme: PinTheme(
                  width: 45,
                  height: 60,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                ),
                focusedPinTheme: PinTheme(
                  width: 45,
                  height: 60,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue, width: 1.4),
                  ),
                ),
                onCompleted: (pin) {
                  print(pin);
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : verifyOtp,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Verify"),
                ),
              ),

              Center(
                child: TextButton(
                  onPressed: _resendSeconds > 0 ? null : resendOTP,
                  child: Text(
                    _resendSeconds > 0
                        ? "Resend in ${_resendSeconds}s"
                        : "Resend Code",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void goBack(bool didPop, dynamic result) async {
    if (didPop) return;

    final exit = await showConfirmDialog(
      context,
      title: "Do you want to stop creating your account?",
      content: "if you stop now, you'll lose any progress you've made.",
      trueText: "STOP CREATING ACCOUNT",
      falseText: "CONTINUE CREATING ACCOUNT",
    );

    if (exit == true) {
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    // ValidationC
    if (otp.isEmpty || otp.length < 6) {
      showMessageDialog(context, "Enter a valid OTP");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await ApiService.post("/otp", {
      "user_email": widget.email,
      "otp": otp,
      "purpose": widget.purpose,
    });

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // Network error
    if (response.statusCode == 0) {
      showMessageDialog(context, "No internet connection");
      return;
    }

    // Server error
    if (!response.isSuccess) {
      showMessageDialog(
        context,
        response.data?["message"] ?? "Failed to verify OTP",
      );
      return;
    }

    // Extract verification token
    final verificationToken = response.data?["verification_token"];

    if (verificationToken == null) {
      showMessageDialog(context, "Invalid server response");
      return;
    }

    // Success → Navigate
    if (widget.purpose == "password_reset") {
      Navigator.pushReplacement(
        context,
        AppRoutes.slideFromRight(
          ResetPasswordPage(
            verificationToken: verificationToken,
          ),
        ),
      );
      return;
    } 
    Navigator.pushReplacement(
      context,
      AppRoutes.slideFromRight(
        UserDetailsPage(
          verificationToken: verificationToken,
          email: widget.email,
        ),
      ),
    );
  }

  Future<void> resendOTP() async {
    final url = widget.purpose == "password_reset"
        ? "/forgotpassword"
        : "/email";

    final response = await ApiService.post(url, {"user_email": widget.email});

    if (!context.mounted) return;

    if (response.statusCode == 0) {
      showMessageDialog(context, "No internet connection");
      return;
    }

    if (!response.isSuccess) {
      showMessageDialog(
        context,
        response.data?["message"] ?? "Failed to send OTP",
      );
      return;
    }

    _startResendTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text("Resend Request was successful.")),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    super.dispose();
  }
}
