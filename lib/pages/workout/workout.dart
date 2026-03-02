import 'package:fitnora/animations.dart';
import 'package:fitnora/components/elevated_boxbutton.dart';
import 'package:fitnora/pages/workout/exercises/view_exercises.dart';
import 'package:fitnora/pages/workout/routine/create_routine.dart';
import 'package:flutter/material.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Workout")),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ElevatedBoxButton(
                      text: "New Routine",
                      iconData: Icons.paste_outlined,
                      onTap: goCreateRoutine,
                    ),
                    const SizedBox(width: 12),
                    ElevatedBoxButton(
                      text: "Exercises",
                      iconData: Icons.accessibility,
                      onTap: goExercises,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void goExercises() {
    Navigator.push(context, AppRoutes.slideFromRight(ViewExercisesPage()));
  }

  void goCreateRoutine() {
    Navigator.push(context, AppRoutes.slideFromRight(CreateRoutinePage()));
  }
}
