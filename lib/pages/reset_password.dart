import 'package:fitnora/animations.dart';
import 'package:fitnora/components/alert.dart';
import 'package:fitnora/components/dialog.dart';
import 'package:fitnora/components/text_field.dart';
import 'package:fitnora/pages/login.dart';
import 'package:fitnora/services/api_service.dart';
import 'package:flutter/material.dart';

class ResetPasswordPage extends StatefulWidget {
  final String verificationToken;
  const ResetPasswordPage({super.key, required this.verificationToken});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final FocusNode passwordNode = FocusNode();
  final FocusNode retypePasswordNode = FocusNode();

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController retypPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureRetypePassword = true;

  bool isLoading = false;

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
              SizedBox(
                width: double.infinity,
                child: Text(
                  "Reset Password",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 25,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Enter the new password for your account.",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),

              const SizedBox(height: 30),

              AppTextField(
                controller: passwordController,
                hintText: "New Password",
                focusNode: passwordNode,
                keyboardType: TextInputType.visiblePassword,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white54,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                onSubmitted: (_) {
                  String password = passwordController.text.trim();
                  if (password.length < 6) {
                    showMessageDialog(
                      context,
                      "Password must be at least 6 characters",
                    );
                    FocusScope.of(context).requestFocus(passwordNode);
                    return;
                  }
                  FocusScope.of(context).requestFocus(retypePasswordNode);
                },
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: retypPasswordController,
                hintText: "Re-Type New Password",
                focusNode: retypePasswordNode,
                keyboardType: TextInputType.visiblePassword,
                obscureText: _obscureRetypePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureRetypePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.white54,
                  ),
                  onPressed: () => setState(
                    () => _obscureRetypePassword = !_obscureRetypePassword,
                  ),
                ),
                onSubmitted: (_) {
                  String password = passwordController.text.trim();
                  String reType = retypPasswordController.text.trim();

                  if (password != reType) {
                    showMessageDialog(context, "Passwords do not match");
                    FocusScope.of(context).requestFocus(passwordNode);
                    return;
                  }
                },
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: isLoading ? null : resetPassword,
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
                          "Reset Password",
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
      ),
    );
  }

  void goBack(bool didPop, dynamic result) async {
    if (didPop) return;

    final exit = await showConfirmDialog(
      context,
      title: "Do you want to stop password reset?",
      content: "if you stop now, you'll lose any progress you've made.",
      trueText: "STOP PASSWORD RESET",
      falseText: "CONTINUE",
    );

    if (!mounted) return;

    if (exit == true) {
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> resetPassword() async {
    String newPassword = passwordController.text.trim();
    String reTypePassword = retypPasswordController.text.trim();

    if (newPassword != reTypePassword) {
      showMessageDialog(context, "Password Mismatch.");
      return;
    }

    final response = await ApiService.post("/resetpassword", {
      "verification_token": widget.verificationToken,
      "new_password": newPassword
    });

    if (!mounted) return;

    if (response.statusCode == 0) {
      showMessageDialog(context, "No internet connection");
      return;
    }

    // Server error
    if (!response.isSuccess) {
      showMessageDialog(
        context,
        response.data?["message"] ?? "Failed to reset password. Try Again Later.",
      );
      return;
    }
    
    Navigator.pushAndRemoveUntil(context, AppRoutes.slideFromRight(LoginPage()), (route) => false);
  }
}
