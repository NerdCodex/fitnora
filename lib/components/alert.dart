import 'package:flutter/material.dart';

void showMessageDialog(
  BuildContext context,
  String message,
  [VoidCallback? onOk]
) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onOk?.call();
            },
            child: const Text("OK", style: TextStyle(color: Colors.blue)),
          ),
        ],
      );
    },
  );
}
