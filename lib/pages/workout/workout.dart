import 'package:fitnora/animations.dart';
import 'package:fitnora/components/elevated_boxbutton.dart';
import 'package:fitnora/pages/workout/exercises/view_exercises.dart';
import 'package:fitnora/pages/workout/routine/create_routine.dart';
import 'package:fitnora/pages/workout/routine/routine_card.dart';
import 'package:fitnora/pages/workout/session/start_session.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:flutter/material.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  bool routinesExpanded = true;
  bool sessionsExpanded = true;
  List<Map<String, dynamic>> _routines = [];
  List<Map<String, dynamic>> _sessions = [];
  bool _loadingRoutines = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadRoutines();
    await _loadSessions();
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
                _buildCollapsibleHeader(
                  "My Routines",
                  routinesExpanded,
                  () => setState(() => routinesExpanded = !routinesExpanded),
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
                            onStart: () => _startSession(routine),
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
                            onDelete: () async {
                              Navigator.pop(context);
                              await WorkoutDatabaseService.instance
                                  .deleteRoutine(routine["routine_id"]);
                              await _loadRoutines();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                ],

                const SizedBox(height: 28),

                // ================= SESSIONS SECTION =================
                _buildCollapsibleHeader(
                  "Workout Sessions",
                  sessionsExpanded,
                  () => setState(() => sessionsExpanded = !sessionsExpanded),
                ),

                if (sessionsExpanded) ...[
                  const SizedBox(height: 12),

                  if (_sessions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          "No sessions recorded yet",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._sessions.map((s) => _buildSessionTile(s)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= COLLAPSIBLE HEADER =================

  Widget _buildCollapsibleHeader(String title, bool expanded, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white10,
                shape: BoxShape.circle,
              ),
              child: Icon(
                expanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SESSION TILE =================

  Widget _buildSessionTile(Map<String, dynamic> session) {
    final dt = DateTime.fromMillisecondsSinceEpoch(session['started_at'] as int);
    final dateStr =
        "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    final runtime = session['completed_at'] != null
        ? " · ${((session['completed_at'] - session['started_at']) / 60000).toStringAsFixed(0)} min"
        : " · In Progress";

    return Dismissible(
      key: ValueKey('sess_${session['session_id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await WorkoutDatabaseService.instance.deleteSession(session['session_id'] as int);
        _loadSessions();
      },
      child: GestureDetector(
        onTap: () {
          _openSession(session['session_id'] as int, session['routine_name'] as String? ?? "Workout");
        },
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.fitness_center, color: Colors.blueAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session['routine_name'] ?? "Workout",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$dateStr$runtime",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ================= DATA LOADING =================

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

  Future<void> _loadSessions() async {
    final sessions = await WorkoutDatabaseService.instance.getSessionHistory();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
    });
  }

  // ================= ACTIONS =================

  Future<void> _startSession(Map<String, dynamic> routine) async {
    final sessionId = await WorkoutDatabaseService.instance
        .startSession(routine["routine_id"]);

    if (!mounted) return;

    await Navigator.push(
      context,
      AppRoutes.slideFromRight(
        StartSessionPage(
          sessionId: sessionId,
          routineName: routine["routine_name"],
        ),
      ),
    );
    await _loadData();
  }

  Future<void> _openSession(int sessionId, String routineName) async {
    await Navigator.push(
      context,
      AppRoutes.slideFromRight(
        StartSessionPage(routineName: routineName, sessionId: sessionId),
      ),
    );
    await _loadSessions();
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