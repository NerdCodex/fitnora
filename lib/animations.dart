import 'package:flutter/material.dart';

class AppRoutes {
  static Route<T> slideFromRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.ease,
          ),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
}
