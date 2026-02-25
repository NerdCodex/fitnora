import 'package:flutter/material.dart';

class ElevatedBoxButton extends StatelessWidget {
  final String text;
  final IconData iconData;
  final VoidCallback? onTap;
  const ElevatedBoxButton({super.key, required this.text, required this.iconData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 60,
        child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
          icon: Icon(iconData),
          label: Text(
            text,
            style: TextStyle(fontFamily: "poppins"),
          ),
        ),
      ),
    );
  }
}
