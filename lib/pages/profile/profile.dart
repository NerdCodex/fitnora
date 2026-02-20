
import 'package:fitnora/animations.dart';
import 'package:fitnora/pages/profile/settings.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(onPressed: () {
            Navigator.push(context, AppRoutes.slideFromRight(SettingsPage()));
          }, icon: Icon(Icons.settings))
        ],
      ),
      body: Center(
        child: const Text("Profile Page"),
      ),
    );
  }
}