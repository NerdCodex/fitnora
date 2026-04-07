import 'package:fitnora/animations.dart';
import 'package:fitnora/components/alert.dart';
import 'package:fitnora/main.dart';
import 'package:fitnora/pages/loading.dart';
import 'package:fitnora/pages/login.dart';
import 'package:fitnora/pages/profile/update_profile.dart';
import 'package:fitnora/pages/profile/notification_settings.dart';
import 'package:fitnora/pages/reset_password.dart';
import 'package:fitnora/services/api_service.dart';
import 'package:fitnora/services/backup_service.dart';
import 'package:fitnora/services/notification_service.dart';
import 'package:fitnora/services/user_session.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:fitnora/services/pdf_report_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SettingsHeader extends StatelessWidget {
  final String text;
  const SettingsHeader({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.black, // Subtle dark grey background
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey, fontSize: 14),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          tileColor: const Color(0xFF121212),
          leading: Icon(icon, color: Colors.white, size: 24),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          subtitle: subtitle != null && subtitle!.isNotEmpty
              ? Text(
                  subtitle!,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                )
              : null,
          trailing: const Icon(
            Icons.chevron_right,
            color: Colors.grey,
            size: 20,
          ),
          onTap: onTap,
        ),
        const Divider(color: Colors.white24, height: 1, thickness: 0.5),
      ],
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _lastBackup = "";
  String _lastRestore = "";

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final box = Hive.box("auth");
    setState(() {
      _lastBackup = box.get("last_backup_date", defaultValue: "") as String;
      _lastRestore = box.get("last_restore_date", defaultValue: "") as String;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings"), leading: BackButton()),
      body: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 4),
          SettingsHeader(text: "Account"),

          const SizedBox(height: 4),
          SettingsTile(
            icon: Icons.person_2_outlined,
            title: "Profile",
            onTap: updateProfile,
          ),
          SettingsTile(
            icon: Icons.lock_outline,
            title: "Reset Password",
            onTap: resetPassword,
          ),
          SettingsTile(
            icon: Icons.notifications_active_outlined,
            title: "Notifications",
            onTap: () {
              Navigator.push(
                context,
                AppRoutes.slideFromRight(const NotificationSettingsPage()),
              );
            },
          ),

          const SizedBox(height: 40),
          SettingsHeader(text: "Preferences"),

          SettingsTile(
            icon: Icons.backup_outlined,
            title: "Backup",
            subtitle: _lastBackup.isNotEmpty ? "Last backup: $_lastBackup" : null,
            onTap: handleBackup,
          ),
          SettingsTile(
            icon: Icons.downloading_outlined,
            title: "Restore Backup",
            subtitle: _lastRestore.isNotEmpty ? "Last restore: $_lastRestore" : null,
            onTap: handleRestore,
          ),
          SettingsTile(
            icon: Icons.picture_as_pdf_outlined,
            title: "Export Report (PDF)",
            onTap: _showPdfExportSheet,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: logout,
              style: TextButton.styleFrom(
                foregroundColor: Colors.red, // Text color
                splashFactory: InkRipple.splashFactory,
                overlayColor: Colors.red.withOpacity(0.2), // Splash color
              ),
              child: const Text("Logout", style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPdfExportSheet() async {
    DateTime? startDate;
    DateTime? endDate;
    bool allData = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Export PDF Report", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  
                  CheckboxListTile(
                    title: const Text("Export All Data (Ignore dates)", style: TextStyle(color: Colors.white)),
                    value: allData,
                    activeColor: Colors.blueAccent,
                    onChanged: (val) {
                      if (val != null) setSheetState(() => allData = val);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  if (!allData) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.date_range, size: 18),
                            label: Text(startDate == null ? "Start Date" : "${startDate!.day}/${startDate!.month}/${startDate!.year}"),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) setSheetState(() => startDate = picked);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.date_range, size: 18),
                            label: Text(endDate == null ? "End Date" : "${endDate!.day}/${endDate!.month}/${endDate!.year}"),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate ?? startDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) setSheetState(() => endDate = picked);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.blueAccent,
                       padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      if (!allData && (startDate == null || endDate == null)) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a valid date range.")));
                        return;
                      }
                      
                      Navigator.pop(context);
                      
                      try {
                        showDialog(
                          context: context, 
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator())
                        );

                        int? sMs, eMs;
                        if (!allData) {
                          sMs = DateTime(startDate!.year, startDate!.month, startDate!.day).millisecondsSinceEpoch;
                          eMs = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59).millisecondsSinceEpoch;
                        }

                        final data = await WorkoutDatabaseService.instance.getReportData(sMs, eMs);
                        await PdfReportService.generateAndSharePdf(data);
                        
                        if (context.mounted) Navigator.pop(context);
                      } catch(e) {
                        if (context.mounted) Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    },
                    child: const Text("Generate PDF", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Future<void> handleBackup() async {
    final confirm = await showConfirmationDialog(context, "Warning", "Backing up will overwrite your previously uploaded backup on the server. Do you want to continue?");
    if (confirm != true) return;

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoadingScreen()),
    );

    final success = await BackupService.backup();

    if (!mounted) return;
    Navigator.pop(context);

    if (success) {
      _loadHistory();
      showMessageDialog(context, "Backup Successful");
    } else {
      showMessageDialog(context, "Backup Failed. Please try again later.");
    }
  }

  Future<void> handleRestore() async {
    final confirm = await showConfirmationDialog(context, "Warning", "Restoring a backup will flush out your current local data and replace it. Do you want to continue?");
    if (confirm != true) return;

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoadingScreen()),
    );

    final success = await BackupService.restore();

    if (!mounted) return;
    Navigator.pop(context);

    if (success) {
      showMessageDialog(context, "Restore Successful. Restarting app...", () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Fitnora()),
          (route) => false,
        );
      });
    } else {
      showMessageDialog(context, "Restore Failed. Please try again later.");
    }
  }

  Future<void> logout() async {
    // Cancel all notifications
    await NotificationService().cancelAllNotifications();

    // Close per-user settings box
    final settingsBoxName = UserSession().settingsBoxName;
    if (Hive.isBoxOpen(settingsBoxName)) {
      await Hive.box(settingsBoxName).close();
    }

    // Close the database
    await WorkoutDatabaseService.instance.closeDb();

    // Clear user session
    UserSession().clear();

    // Remove auth data
    final box = Hive.box("auth");
    await box.delete("access_token");
    await box.delete("user_email");

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      AppRoutes.slideFromRight(LoginPage()),
      (route) => false,
    );
  }

  Future<void> updateProfile() async {
    // Show loading screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoadingScreen()),
    );

    final response = await ApiService.get("/user/profile", withAuth: true);

    if (!mounted) return;

    // Remove loading screen
    Navigator.pop(context);

    if (response.statusCode == 0) {
      showMessageDialog(
        context,
        "No Internet: Please check your internet connection.",
      );
      return;
    }

    if (response.statusCode == 401) {
      showMessageDialog(context, "Session Expired", logout);
      return;
    }

    if (response.statusCode == 200) {
      Navigator.push(
        context,
        AppRoutes.slideFromRight(
          UpdateProfilePage(details: response.data ?? {}),
        ),
      );
      return;
    }

    showMessageDialog(
      context,
      response.data?["message"] ?? "Something went wrong",
    );
  }

  Future<void> resetPassword() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoadingScreen()),
    );

    final response = await ApiService.get("/user/updatepassword", withAuth: true);

    if (!mounted) return;

    // Remove loading screen
    Navigator.pop(context);

    if (response.statusCode == 0) {
      showMessageDialog(
        context,
        "No Internet: Please check your internet connection.",
      );
      return;
    }

    if (response.statusCode == 401) {
      showMessageDialog(context, "Session Expired", logout);
      return;
    }

    if (response.statusCode == 200) {
      Navigator.push(
        context,
        AppRoutes.slideFromRight(
          ResetPasswordPage(verificationToken: response.data?["verification_token"],),
        ),
      );
      return;
    }

    showMessageDialog(
      context,
      response.data?["message"] ?? "Something went wrong",
    );
  }
}
