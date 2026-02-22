import 'package:fitnora/animations.dart';
import 'package:fitnora/components/alert.dart';
import 'package:fitnora/components/text_field.dart';
import 'package:fitnora/pages/signup/otp.dart';
import 'package:fitnora/services/api_service.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton()),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: Text(
                "Forgot Password",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 25,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Enter your email to reset your password.",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),

            const SizedBox(height: 30),

            AppTextField(hintText: "Email", controller: emailController),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: isLoading ? null : goNext,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Next",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> goNext() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showMessageDialog(context, "Enter the email");
      return;
    }

    setState(() {
      isLoading = true;
    });

    final response = await ApiService.post("/forgotpassword", {"user_email": email});

    if (!context.mounted) return;

    setState(() {
      isLoading = false;
    });

    if (!mounted) return;

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

    Navigator.pushReplacement(
      context,
      AppRoutes.slideFromRight(OtpPage(email: email, purpose: "password_reset",)),
    );
  }
}
