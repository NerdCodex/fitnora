import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:date_field/date_field.dart';
import 'package:fitnora/components/alert.dart';
import 'package:fitnora/components/dialog.dart';
import 'package:fitnora/components/text_field.dart';
import 'package:fitnora/services/api_service.dart';
import 'package:flutter/material.dart';

class UpdateProfilePage extends StatefulWidget {
  final Map<String, dynamic> details;
  const UpdateProfilePage({super.key, required this.details});

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final FocusNode fullNameNode = FocusNode();
  final TextEditingController fullNameController = TextEditingController();

  int selected = 1;
  String gender = 'Male';
  DateTime? selectedDob;

  // ===== Original values =====
  String _originalName = "";
  String _originalGender = "";
  DateTime? _originalDob;

  @override
  void initState() {
    super.initState();

    // Load original values
    _originalName = widget.details["user_fullname"] ?? "";
    _originalGender = widget.details["gender"] ?? "Male";

    final dobString = widget.details["user_dob"];

    if (dobString != null && dobString.toString().isNotEmpty) {
      _originalDob = DateTime.parse(dobString);
      selectedDob = _originalDob;
    }

    fullNameController.text = _originalName;
    gender = _originalGender;

    selected = gender == 'Male'
        ? 1
        : gender == 'Female'
        ? 2
        : 3;
  }

  // ===== Change Detection =====
  bool get _hasChanges {
    final nameChanged = fullNameController.text.trim() != _originalName;

    final genderChanged = gender != _originalGender;

    final dobChanged =
        (selectedDob?.toIso8601String().split('T').first ?? "") !=
        (_originalDob?.toIso8601String().split('T').first ?? "");

    return nameChanged || genderChanged || dobChanged;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: goBack,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => goBack(false, null)),
          title: const Text("Edit Profile"),
          actions: [
            TextButton(
              onPressed: saveProfile,
              child: const Text("Save", style: TextStyle(color: Colors.blue)),
            ),
          ],
          actionsPadding: EdgeInsets.only(right: 10),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 20, 16),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  "Your profile details are shown below, edit it accordingly.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),
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
                  },
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    "Date of Birth",
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
                    mode: DateTimeFieldPickerMode.date,
                    initialValue: selectedDob,
                    onChanged: (DateTime? value) {
                      setState(() {
                        selectedDob = value;
                      });
                    },
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    initialPickerDateTime: selectedDob ?? DateTime(2000),
                    decoration: InputDecoration(
                      hintText: "Date of birth",
                      suffixIcon: const Icon(
                        Icons.calendar_today,
                        color: Colors.white54,
                        size: 18,
                      ),
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
                      color: Colors.transparent,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== Back Logic =====
  void goBack(bool didPop, dynamic result) async {
    if (didPop) return;

    // No changes → pop immediately
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    // Changes exist → confirm
    final exit = await showConfirmDialog(
      context,
      title: "Discard changes?",
      content: "You have unsaved changes. Do you want to leave?",
      trueText: "DISCARD",
      falseText: "STAY",
    );

    if (exit == true && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> saveProfile() async {
    // Validation
    if (fullNameController.text.trim().isEmpty) {
      showMessageDialog(context, "Enter your full name.");
      FocusScope.of(context).requestFocus(fullNameNode);
      return;
    }

    // If nothing changed
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    // Build request body (only changed fields)
    final Map<String, dynamic> data = {};

    if (fullNameController.text.trim() != _originalName) {
      data["user_fullname"] = fullNameController.text.trim();
    }

    if (gender != _originalGender) {
      data["gender"] = gender;
    }

    final originalDobStr =
        _originalDob?.toIso8601String().split('T').first ?? "";
    final selectedDobStr =
        selectedDob?.toIso8601String().split('T').first ?? "";

    if (selectedDobStr != originalDobStr && selectedDob != null) {
      data["user_dob"] = selectedDobStr; // YYYY-MM-DD
    }

    // Show loading
    showLoadingDialog(context);

    final response = await ApiService.post(
      "/user/update",
      data,
      withAuth: true,
    );

    if (!mounted) return;
    Navigator.pop(context); // close loading

    // Network error
    if (response.statusCode == 0) {
      showMessageDialog(context, "No Internet connection.");
      return;
    }

    // Unauthorized
    if (response.statusCode == 401) {
      showMessageDialog(context, "Session expired.");
      Navigator.pop(context);
      return;
    }

    // Success
    if (response.statusCode == 200) {
      showMessageDialog(context, "Profile updated successfully.", () {
        Navigator.pop(context, true);
      });

      // Update originals (important to avoid false change detection)
      _originalName = fullNameController.text.trim();
      _originalGender = gender;
      _originalDob = selectedDob;

      return;
    }

    // Other errors
    showMessageDialog(context, response.data?["error"] ?? "Update failed");
  }

  @override
  void dispose() {
    fullNameController.dispose();
    fullNameNode.dispose();
    super.dispose();
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }
}
