import 'package:fitnora/animations.dart';
import 'package:fitnora/components/alert.dart';
import 'package:fitnora/pages/loading.dart';
import 'package:fitnora/pages/login.dart';
import 'package:fitnora/pages/profile/update_profile.dart';
import 'package:fitnora/services/api_service.dart';
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
  final VoidCallback onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
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
            onTap: () {},
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
            onTap: () {},
          ),
          SettingsTile(
            icon: Icons.downloading_outlined,
            title: "Restore Backup",
            onTap: () {},
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
      Navigator.push(context, AppRoutes.slideFromRight(UpdateProfilePage(details: response.data ?? {})));
      return;
    }

    showMessageDialog(
      context,
      response.data?["message"] ?? "Something went wrong",
    );
  }
}
