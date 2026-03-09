import 'package:fitnora/animations.dart';
import 'package:fitnora/components/elevated_boxbutton.dart';
import 'package:fitnora/pages/workout/exercises/view_exercises.dart';
import 'package:fitnora/pages/workout/routine/create_routine.dart';
import 'package:fitnora/pages/workout/routine/routine_card.dart';
import 'package:fitnora/pages/workout/session/start_session.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

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

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  double _maxVolume = 1;

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

                // ================= SESSIONS SECTION =================
                _buildCollapsibleHeader(
                  "Workout Sessions",
                  sessionsExpanded,
                  () => setState(() => sessionsExpanded = !sessionsExpanded),
                ),

                if (sessionsExpanded) ...[
                  const SizedBox(height: 12),
                  // ================= HEATMAP CALENDAR =================
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: CalendarFormat.week,
                      availableCalendarFormats: const {
                        CalendarFormat.week: 'Week',
                      },
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: Colors.white70),
                        weekendStyle: TextStyle(color: Colors.white70),
                      ),
                      calendarStyle: const CalendarStyle(
                        outsideDaysVisible: false,
                        defaultTextStyle: TextStyle(color: Colors.white),
                        weekendTextStyle: TextStyle(color: Colors.white),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) =>
                            _buildCalendarCell(day, isSelected: false),
                        todayBuilder: (context, day, focusedDay) =>
                            _buildCalendarCell(
                              day,
                              isSelected: false,
                              isToday: true,
                            ),
                        selectedBuilder: (context, day, focusedDay) =>
                            _buildCalendarCell(day, isSelected: true),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ================= SELECTED DAY SESSIONS =================
                  ..._getSessionsForDay(
                    _selectedDay ?? DateTime.now(),
                  ).map((s) => _buildSessionTile(s)),
                  if (_getSessionsForDay(
                    _selectedDay ?? DateTime.now(),
                  ).isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          "No sessions on this date",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ],

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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= COLLAPSIBLE HEADER =================

  Widget _buildCollapsibleHeader(
    String title,
    bool expanded,
    VoidCallback onTap,
  ) {
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
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CALENDAR HELPERS =================

  List<Map<String, dynamic>> _getSessionsForDay(DateTime day) {
    return _sessions.where((s) {
      final dt = DateTime.fromMillisecondsSinceEpoch(s['started_at'] as int);
      return isSameDay(dt, day);
    }).toList();
  }

  Widget _buildCalendarCell(
    DateTime day, {
    required bool isSelected,
    bool isToday = false,
  }) {
    final daySessions = _getSessionsForDay(day);
    double dailyVolume = 0;
    for (var s in daySessions) {
      dailyVolume += (s['total_volume'] as num?)?.toDouble() ?? 0;
    }

    // Heatmap color logic
    Color bgColor = Colors.transparent;
    Color textColor = Colors.white;

    if (isSelected) {
      bgColor = Colors.blue;
      textColor = Colors.white;
    } else if (dailyVolume > 0) {
      // Scale opacity purely based on max volume (from 0.2 to 0.8)
      double intensity = (dailyVolume / _maxVolume).clamp(0.0, 1.0);
      double opacity = 0.2 + (intensity * 0.6);
      bgColor = Colors.blueAccent.withValues(alpha: opacity);
      textColor = Colors.white;
    } else if (isToday) {
      textColor = Colors.blue;
    }

    final hasSession = daySessions.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: isToday && !isSelected ? Border.all(color: Colors.blue) : null,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: textColor,
              fontWeight: isSelected || isToday
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          if (hasSession) ...[
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.blueAccent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================= SESSION TILE =================

  Widget _buildSessionTile(Map<String, dynamic> session) {
    final dt = DateTime.fromMillisecondsSinceEpoch(
      session['started_at'] as int,
    );
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
        await WorkoutDatabaseService.instance.deleteSession(
          session['session_id'] as int,
        );
        _loadSessions();
      },
      child: GestureDetector(
        onTap: () {
          _openSession(
            session['session_id'] as int,
            session['routine_name'] as String? ?? "Workout",
          );
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
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.blueAccent,
                  size: 20,
                ),
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
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
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
    double maxV = 1;
    for (var s in sessions) {
      final v = (s['total_volume'] as num?)?.toDouble() ?? 0;
      if (v > maxV) maxV = v;
    }

    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _maxVolume = maxV;
    });
  }

  // ================= ACTIONS =================

  Future<void> _startSession(Map<String, dynamic> routine) async {
    final sessionId = await WorkoutDatabaseService.instance.startSession(
      routine["routine_id"],
      startedAt: _selectedDay,
    );

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
