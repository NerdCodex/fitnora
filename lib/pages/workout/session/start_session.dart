import 'dart:async';
import 'dart:io';

import 'package:fitnora/components/alert.dart';
import 'package:fitnora/components/dialog.dart';
import 'package:fitnora/services/constants.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class StartSessionPage extends StatefulWidget {
  final int sessionId;
  final String routineName;

  const StartSessionPage({
    super.key,
    required this.sessionId,
    required this.routineName,
  });

  @override
  State<StartSessionPage> createState() => _StartSessionPageState();
}

class _StartSessionPageState extends State<StartSessionPage> {
  List<Map<String, dynamic>> _exercises = [];
  bool _loading = true;

  // Timer & State
  late Stopwatch _stopwatch;
  Timer? _timer;
  String _elapsed = "00:00";
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadSessionInfo();
  }

  Future<void> _loadSessionInfo() async {
    // Check if session is already completed
    final history = await WorkoutDatabaseService.instance.getSessionHistory();
    // getSessionHistory only returns non-in_progress. So if it's there, it's done.
    final existing = history.where((s) => s['session_id'] == widget.sessionId).toList();
    
    if (existing.isNotEmpty) {
      _isCompleted = true;
      final session = existing.first;
      final startedAt = session['started_at'] as int;
      final completedAt = session['completed_at'] as int?;
      if (completedAt != null) {
        final d = Duration(milliseconds: completedAt - startedAt);
        _elapsed = "${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
      }
    } else {
      _isCompleted = false;
      _stopwatch = Stopwatch()..start();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          final d = _stopwatch.elapsed;
          _elapsed =
              "${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
        });
      });
    }

    await _loadExercises();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!_isCompleted) _stopwatch.stop();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      final data = await WorkoutDatabaseService.instance
          .getSessionExercises(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _exercises = data;
        _loading = false;
      });
    } catch (e) {
      debugPrint("LOAD SESSION ERROR: $e");
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.routineName),
          leading: BackButton(onPressed: () => _onBack(false, null)),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    _elapsed,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _exercises.isEmpty
                ? const Center(
                    child: Text(
                      "No exercises in this session",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: _exercises.length,
                    itemBuilder: (context, index) {
                      return _ExerciseCard(
                        exercise: _exercises[index],
                        onUpdate: _loadExercises,
                      );
                    },
                  ),
        bottomNavigationBar: _loading || _isCompleted
            ? null
            : SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _finishWorkout,
                      child: const Text(
                        "Finish Workout",
                        style: TextStyle(fontSize: 16, fontFamily: "Poppins"),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // ================= FINISH =================

  Future<void> _finishWorkout() async {
    final confirm = await showConfirmDialog(
      context,
      title: "Finish Workout?",
      content: "Mark this session as completed?",
      trueText: "FINISH",
      falseText: "CONTINUE",
    );

    if (confirm != true) return;

    await WorkoutDatabaseService.instance.completeSession(widget.sessionId);

    if (!mounted) return;
    showMessageDialog(context, "Workout completed! 💪", () {
      Navigator.pop(context, true);
    });
  }

  // ================= BACK =================

  void _onBack(bool didPop, dynamic result) async {
    if (didPop) return;

    if (_isCompleted) {
      if (mounted) {
        Navigator.pop(context, true);
      }
      return;
    }

    final exit = await showConfirmDialog(
      context,
      title: "Abandon workout?",
      content:
          "If you leave now, this session will be saved as abandoned.",
      trueText: "ABANDON",
      falseText: "CONTINUE",
    );

    if (exit == true) {
      await WorkoutDatabaseService.instance.abandonSession(widget.sessionId);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }
}

// ================================================================
//  EXERCISE CARD (internal widget)
// ================================================================

class _ExerciseCard extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final VoidCallback onUpdate;

  const _ExerciseCard({required this.exercise, required this.onUpdate});

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final sets = (ex['sets'] as List<Map<String, dynamic>>?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise Header
          Row(
            children: [
              _ExerciseAvatar(imageName: ex['exercise_image'] as String?),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex['exercise_name'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "${ex['exercise_equipment']} · ${ex['exercise_type']}",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Table Header
          Row(
            children: [
              const SizedBox(width: 40, child: Text("SET", style: _headerStyle)),
              const Expanded(
                child: Center(
                  child: Text("KG", style: _headerStyle),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(ex['exercise_type'] == "seconds" ? "SECS" : "REPS", style: _headerStyle),
                ),
              ),
              const SizedBox(width: 48, child: Center(child: Text("✓", style: _headerStyle))),
            ],
          ),

          const SizedBox(height: 8),

          // Set Rows
          ...sets.asMap().entries.map((entry) {
            final setData = entry.value;
            return _SetRow(
              setNumber: entry.key + 1,
              setData: setData,
              onUpdate: widget.onUpdate,
              exerciseType: ex['exercise_type'] as String? ?? 'reps',
            );
          }),

          // Add Set Button
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _addSet(ex['session_exercise_id']),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Add Set"),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addSet(int sessionExerciseId) async {
    await WorkoutDatabaseService.instance.addSessionSet(sessionExerciseId);
    widget.onUpdate();
  }
}

const _headerStyle = TextStyle(
  color: Colors.grey,
  fontSize: 12,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.5,
);

// ================================================================
//  SET ROW (internal widget)
// ================================================================

class _SetRow extends StatefulWidget {
  final int setNumber;
  final Map<String, dynamic> setData;
  final VoidCallback onUpdate;
  final String exerciseType;

  const _SetRow({
    required this.setNumber,
    required this.setData,
    required this.onUpdate,
    required this.exerciseType,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;
  late bool _completed;

  @override
  void initState() {
    super.initState();
    final w = widget.setData['weight'] as num? ?? 0;
    final r = widget.setData['reps'] as int? ?? 0;
    _weightCtrl = TextEditingController(text: w > 0 ? w.toString() : '');
    _repsCtrl = TextEditingController(text: r > 0 ? r.toString() : '');
    _completed = (widget.setData['is_completed'] as int? ?? 0) == 1;
  }

  @override
  void didUpdateWidget(covariant _SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.setData['set_id'] != widget.setData['set_id']) {
      final w = widget.setData['weight'] as num? ?? 0;
      final r = widget.setData['reps'] as int? ?? 0;
      _weightCtrl.text = w > 0 ? w.toString() : '';
      _repsCtrl.text = r > 0 ? r.toString() : '';
      _completed = (widget.setData['is_completed'] as int? ?? 0) == 1;
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save({bool? toggleComplete}) async {
    final weight = double.tryParse(_weightCtrl.text) ?? 0;
    final reps = int.tryParse(_repsCtrl.text) ?? 0;

    if (toggleComplete != null) {
      _completed = toggleComplete;
    }

    await WorkoutDatabaseService.instance.updateSessionSet(
      setId: widget.setData['set_id'] as int,
      weight: weight,
      reps: reps,
      isCompleted: _completed,
    );

    if (toggleComplete != null) {
      widget.onUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _completed ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Center(
              child: Text(
                "${widget.setNumber}",
                style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _weightCtrl,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: "0",
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (_) => _save(),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _repsCtrl,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.exerciseType == "seconds" ? "0s" : "0",
                  hintStyle: const TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (_) => _save(),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: () {
                setState(() {
                  _completed = !_completed;
                });
                _save(toggleComplete: _completed);
              },
              icon: Icon(
                _completed
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: _completed ? Colors.green : Colors.white38,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
//  EXERCISE AVATAR (internal widget)
// ================================================================

class _ExerciseAvatar extends StatelessWidget {
  final String? imageName;
  const _ExerciseAvatar({this.imageName});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _resolve(),
      builder: (context, snapshot) {
        final file = snapshot.data;
        return CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF1E1E1E),
          backgroundImage: file != null ? FileImage(file) : null,
          child: file == null
              ? ClipOval(
                  child: Image.asset(
                    "assets/dumbell.png",
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                )
              : null,
        );
      },
    );
  }

  Future<File?> _resolve() async {
    if (imageName == null || imageName!.isEmpty) return null;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$local_images/$imageName');
    return file.existsSync() ? file : null;
  }
}
