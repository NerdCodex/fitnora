import 'package:fitnora/animations.dart';
import 'package:fitnora/components/text_field.dart';
import 'package:fitnora/pages/signup/otp.dart';
import 'package:fitnora/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:fitnora/components/alert.dart';

class EmailVerification extends StatefulWidget {
  const EmailVerification({super.key});

  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton()),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              child: Text(
                "What's your email?",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 25,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Enter the email where you can be contacted. No one see this on your profile.",
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,),
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

    final response = await ApiService.post("/email", {"user_email": email});

    if (!context.mounted) return;

    setState(() {
      isLoading = false;
    });

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
      AppRoutes.slideFromRight(OtpPage(email: email, purpose: "email_verification",)),
    );
  }
}
