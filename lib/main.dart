import 'package:fitnora/pages/home.dart';
import 'package:fitnora/pages/loading.dart';
import 'package:fitnora/pages/login.dart';
import 'package:fitnora/theme.dart';
import 'package:fitnora/services/notification_service.dart';
import 'package:fitnora/services/user_session.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('auth');

  await NotificationService().init();

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
      future: _initApp(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoadingScreen();
        }
        return snapshot.data! ? const HomePage() : const LoginPage();
      },
    );
  }

  Future<bool> _initApp() async {
    final box = Hive.box('auth');
    final token = box.get('access_token');
    final email = box.get('user_email');

    if (token != null && email != null) {
      // User is logged in — init per-user session and settings
      await UserSession().init(email);
      await UserSession().openSettingsBox();
      return true;
    }
    return false;
  }
}

