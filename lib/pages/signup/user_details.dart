import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:fitnora/animations.dart';
import 'package:fitnora/components/alert.dart';
import 'package:fitnora/components/dialog.dart';
import 'package:fitnora/components/text_field.dart';
import 'package:fitnora/pages/home.dart';
import 'package:fitnora/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:date_field/date_field.dart';
import 'package:hive/hive.dart';

class UserDetailsPage extends StatefulWidget {
  final String verificationToken;
  final String email;
  const UserDetailsPage({super.key, required this.verificationToken, required this.email});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final FocusNode fullNameNode = FocusNode();
  final FocusNode passwordNode = FocusNode();
  final FocusNode retypePasswordNode = FocusNode();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController retypPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureRetypePassword = true;

  int selected = 1;
  String gender = 'Male';

  bool _isLoading = false;
  DateTime? selectedDob;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: goBack,
      child: Scaffold(
        appBar: AppBar(leading: BackButton()),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 20, 16),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Enter the details",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                  ),
                ),

                const SizedBox(height: 8),
                const Text(
                  "To create your account, enter the details properly.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 40),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    "Full Name",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                AppTextField(
                  controller: fullNameController,
                  hintText: "Full Name",
                  focusNode: fullNameNode,
                  onSubmitted: (_) {
                    if (fullNameController.text.isEmpty) {
                      showMessageDialog(context, "Enter your full name.");
                      FocusScope.of(context).requestFocus(fullNameNode);
                      return;
                    }
                    FocusScope.of(context).requestFocus(passwordNode);
                  },
                ),
                const SizedBox(height: 8),
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
                  hintText: "Password",
                  focusNode: passwordNode,
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
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    "Re-Type Password",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                AppTextField(
                  controller: retypPasswordController,
                  hintText: "Re-Type Password",
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
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    "Date of birth",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DateTimeFormField(
                    mode: DateTimeFieldPickerMode.date, // ← Date only
                    onChanged: (DateTime? value) {
                      setState(() {
                        selectedDob = value;
                      });
                    },

                    firstDate: DateTime(1900), // DOB range
                    lastDate: DateTime.now(), // No future dates

                    initialPickerDateTime: DateTime(2000),

                    decoration: InputDecoration(
                      hintText: "Date of birth",
                      suffixIcon: const Icon(
                        Icons.calendar_today,
                        color: Colors.white54,
                        size: 18,
                      ),
                      // Remove default Material fill
                      filled: false,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),

                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    "Gender",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: CustomSlidingSegmentedControl<int>(
                    initialValue: selected,
                    isStretch: true,
                    children: const {
                      1: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Male',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      2: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Female',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      3: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Others',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    },

                    decoration: BoxDecoration(
                      color: Colors.transparent, // container handles background
                      borderRadius: BorderRadius.circular(12),
                    ),

                    thumbDecoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),

                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,

                    onValueChanged: (value) {
                      setState(() {
                        selected = value;
                        gender = value == 1
                            ? 'Male'
                            : value == 2
                            ? 'Female'
                            : 'Others';
                      });
                    },
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : signUp,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,),
                          )
                        : const Text("Sign Up"),
                  ),
                ),
              ],
            ),
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
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> signUp() async {
    String name = fullNameController.text.trim();
    String reTypePassword = retypPasswordController.text.trim();

    if (selectedDob == null) {
      showMessageDialog(context, "Please select date of birth");
      return;
    }

    String dob =
        "${selectedDob!.year.toString().padLeft(4, '0')}-"
        "${selectedDob!.month.toString().padLeft(2, '0')}-"
        "${selectedDob!.day.toString().padLeft(2, '0')}";

    setState(() {
      _isLoading = true;
    });

    final response = await ApiService.post("/signup", {
      "user_email": widget.email,
      "user_fullname": name,
      "password": reTypePassword,
      "user_dob": dob,
      "gender": gender,
      "verification_token": widget.verificationToken
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
        response.data?["message"] ?? "Failed to sign up user. Try Again Later.",
      );
      return;
    }

    final accessToken = response.data?["access_token"];

    if (accessToken == null) {
      showMessageDialog(context, "Invalid server response");
      return;
    }

    final box = Hive.box('auth');
    box.put("access_token", accessToken);
    Navigator.pushAndRemoveUntil(context, AppRoutes.slideFromRight(HomePage()), (route) => false);
  }


  @override
  void dispose() {
    fullNameNode.dispose();
    passwordNode.dispose();
    retypePasswordNode.dispose();

    fullNameController.dispose();
    passwordController.dispose();
    retypPasswordController.dispose();

    super.dispose();
  }
}
