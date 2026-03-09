import 'package:fitnora/animations.dart';
import 'package:fitnora/components/alert.dart';
import 'package:fitnora/main.dart';
import 'package:fitnora/pages/loading.dart';
import 'package:fitnora/pages/login.dart';
import 'package:fitnora/pages/profile/update_profile.dart';
import 'package:fitnora/pages/reset_password.dart';
import 'package:fitnora/services/api_service.dart';
import 'package:fitnora/services/backup_service.dart';
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
            onTap: () {},
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

  Future<void> handleBackup() async {
    final confirm = await showConfirmationDialog(context, "Warning", "Backing up will overwrite your previously uploaded backup on the server. Do you want to continue?");
    if (confirm != true) return;

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
    final box = Hive.box("auth");
    await box.delete("access_token");

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
