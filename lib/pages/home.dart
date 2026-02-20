import 'package:fitnora/animations.dart';
import 'package:fitnora/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hello World"),
      ),
      body: Center(
        child: ElevatedButton(onPressed: () async {
          final box = await Hive.box("auth");
          box.delete("access_token");
          
          Navigator.pushReplacement(context, AppRoutes.slideFromRight(LoginPage()));
        }, child: const Text("Logout",)),
      ),
    );
  }
}