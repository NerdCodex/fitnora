import 'package:fitnora/animations.dart';
import 'package:fitnora/pages/workout/exercises/create_exercise.dart';
import 'package:flutter/material.dart';

class ViewExercisesPage extends StatefulWidget {
  const ViewExercisesPage({super.key});

  @override
  State<ViewExercisesPage> createState() => _ViewExercisesPageState();
}

class _ViewExercisesPageState extends State<ViewExercisesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exercises"),
        actions: [
          TextButton(
            onPressed: openCreatePage,
            child: const Text("Create", style: TextStyle(color: Colors.blue)),
          ),
        ],
        actionsPadding: EdgeInsets.only(right: 10),
      ),
    );
  }

  void openCreatePage() {
    Navigator.push(context, AppRoutes.slideFromRight(CreateExercisePage()));
  }
}
