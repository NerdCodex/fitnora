import 'package:fitnora/pages/home.dart';
import 'package:fitnora/pages/loading.dart';
import 'package:fitnora/pages/login.dart';
import 'package:fitnora/theme.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('auth');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitnora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const Fitnora(),
    );
  }
}

class Fitnora extends StatelessWidget {
  const Fitnora({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Hive.openBox('auth'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoadingScreen();
        }

        final box = Hive.box('auth');
        final token = box.get('access_token');

        return token != null ? const HomePage() : const LoginPage();
      },
    );
  }
}

