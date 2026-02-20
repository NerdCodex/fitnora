
import 'package:flutter/material.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({super.key});

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text("Edit Profile"),
        actionsPadding: EdgeInsets.fromLTRB(0, 0, 10, 0),
        actions: [
          TextButton(onPressed: () {}, child: const Text("Save", style: TextStyle(color: Colors.blue),))
        ],
      ),
    );
  }
}