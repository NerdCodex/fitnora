import 'package:fitnora/animations.dart';
import 'package:fitnora/components/elevated_boxbutton.dart';
import 'package:fitnora/pages/workout/exercises/view_exercises.dart';
import 'package:fitnora/pages/workout/routine/create_routine.dart';
import 'package:fitnora/pages/workout/routine/routine_card.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:flutter/material.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  bool routinesExpanded = true;
  List<Map<String, dynamic>> _routines = [];
  bool _loadingRoutines = true;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

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
                // ================= BUTTON ROW =================
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

                const SizedBox(height: 28),

                // ================= ROUTINE SECTION =================
                GestureDetector(
                  onTap: () {
                    setState(() {
                      routinesExpanded = !routinesExpanded;
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "My Routines",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        routinesExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),

                if (routinesExpanded) ...[
                  const SizedBox(height: 16),

                  if (_loadingRoutines)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_routines.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          "No routines yet",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _routines.map((routine) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: RoutineCard(
                            routine: routine,

                            // ================= START =================
                            onStart: () {
                              // You can implement session start later
                            },

                            // ================= EDIT =================
                            onEdit: () async {
                              Navigator.pop(context);
                              await Navigator.push(
                                context,
                                AppRoutes.slideFromRight(
                                  CreateRoutinePage(
                                    routineId: routine["routine_id"],
                                  ),
                                ),
                              );
                              await _loadRoutines();
                            },

                            // ================= DELETE =================
                            onDelete: () async {
                              Navigator.pop(context);
                              // await WorkoutDatabaseService.instance
                              //     .deleteRoutine(routine["routine_id"]);
                              await _loadRoutines();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= LOAD ROUTINES =================
  Future<void> _loadRoutines() async {
    try {
      final data = await WorkoutDatabaseService.instance
          .getRoutinesWithExercises();

      setState(() {
        _routines = data;
        _loadingRoutines = false;
      });
    } catch (e, s) {
      debugPrint("LOAD ROUTINES ERROR: $e");
      debugPrint("$s");

      setState(() {
        _loadingRoutines = false;
      });
    }
  }

  // ================= NAVIGATION =================
  void goExercises() {
    Navigator.push(context, AppRoutes.slideFromRight(ViewExercisesPage()));
  }

  void goCreateRoutine() async {
    await Navigator.push(
      context,
      AppRoutes.slideFromRight(CreateRoutinePage()),
    );
    await _loadRoutines();
  }
}