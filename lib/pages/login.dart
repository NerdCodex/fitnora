import 'package:fitnora/animations.dart';
import 'package:fitnora/components/alert.dart';
import 'package:fitnora/components/text_field.dart';
import 'package:fitnora/pages/forgot_password.dart';
import 'package:fitnora/pages/home.dart';
import 'package:fitnora/pages/signup/email_verification.dart';
import 'package:fitnora/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;

  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    emailFocus.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Image.asset("assets/logo.png", height: 280)),

                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    "Email",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                AppTextField(
                  controller: emailController,
                  focusNode: emailFocus,
                  hintText: "Email",
                  keyboardType: TextInputType.emailAddress,
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(passwordFocus),
                ),

                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    "Password",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                AppTextField(
                  controller: passwordController,
                  focusNode: passwordFocus,
                  hintText: "Password",
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white54,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 44,

                  child: ElevatedButton(
                    onPressed: _isLoading ? null : logIn,
                    child:  _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,),
                        )
                      : const Text("Log in"),
                  ),
                ),

                const SizedBox(height: 15),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, AppRoutes.slideFromRight(ForgotPasswordPage()));
                    },
                    style: ButtonStyle(
                      overlayColor: MaterialStateProperty.all(
                        Colors.white12, // custom splash for text button
                      ),
                    ),
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 40),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(context, AppRoutes.slideFromRight(EmailVerification()));
            },
            child: const Text(
              "Create new account",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> logIn() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessageDialog(context, "Email and Password cannot be empty.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await ApiService.post("/signin", {
      "user_email": email,
      "password": password
    });

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 0) {
      showMessageDialog(context, "No internet connection");
      return;
    }

    // Server error
    if (!response.isSuccess) {
      showMessageDialog(
        context,
        response.data?["message"] ?? "Failed to authenticate the credentials.",
      );
      return;
    }

    final accessToken = response.data?["access_token"];

    if (accessToken == null) {
      showMessageDialog(context, "Invalid server response");
      return;
    }

    final box = Hive.box('auth');
    await box.put("access_token", accessToken);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, AppRoutes.slideFromRight(HomePage()), (route) => false);
  }
}
