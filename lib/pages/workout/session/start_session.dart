import 'dart:io';

import 'package:fitnora/animations.dart';
import 'package:fitnora/components/alert.dart';
import 'package:fitnora/components/dialog.dart';
import 'package:fitnora/pages/workout/routine/select_exercise.dart';
import 'package:fitnora/services/constants.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:flutter/foundation.dart';
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
  bool _isCompleted = false;
  bool _hasChanges = false;

  DateTime _sessionDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();

  final List<int> _addedSetIds = [];
  final List<int> _addedSessionExerciseIds = [];

  @override
  void initState() {
    super.initState();
    _loadSessionInfo();
  }

  Future<void> _loadSessionInfo() async {
    final history = await WorkoutDatabaseService.instance.getSessionHistory();
    final existing = history.where((s) => s['session_id'] == widget.sessionId).toList();

    if (existing.isNotEmpty) {
      _isCompleted = true;
      final session = existing.first;
      
      final startedAt = session['started_at'] as int;
      final startDt = DateTime.fromMillisecondsSinceEpoch(startedAt);
      _sessionDate = startDt;
      _startTime = TimeOfDay.fromDateTime(startDt);

      if (session['completed_at'] != null) {
        final endDt = DateTime.fromMillisecondsSinceEpoch(session['completed_at'] as int);
        _endTime = TimeOfDay.fromDateTime(endDt);
      } else {
        _endTime = TimeOfDay.now();
      }
    } else {
      // New session from DB (in_progress) 
      final db = await WorkoutDatabaseService.instance.database;
      final sessionRows = await db.query('workout_session', where: 'session_id = ?', whereArgs: [widget.sessionId]);
      if (sessionRows.isNotEmpty) {
        final startedAt = sessionRows.first['started_at'] as int;
        final startDt = DateTime.fromMillisecondsSinceEpoch(startedAt);
        _sessionDate = startDt;
        _startTime = TimeOfDay.fromDateTime(startDt);
        _endTime = TimeOfDay.now();
      }
    }

    await _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      final rawData = await WorkoutDatabaseService.instance.getSessionExercises(widget.sessionId);

      // Deep copy on a background isolate to avoid jank
      final data = await compute(_deepCopyExercises, rawData);

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

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _pickDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: Colors.blue, surface: Colors.grey.shade900),
        ),
        child: child!,
      ),
    );
    if (dt != null && dt != _sessionDate) {
      setState(() {
        _sessionDate = dt;
        _markChanged();
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final tm = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: Colors.blue, surface: Colors.grey.shade900),
        ),
        child: child!,
      ),
    );
    if (tm != null) {
      setState(() {
        if (isStart) {
          _startTime = tm;
        } else {
          _endTime = tm;
        }
        _markChanged();
      });
    }
  }

  /// Returns true if start time is strictly before end time.
  bool _validateTimes() {
    final startDt = DateTime(_sessionDate.year, _sessionDate.month, _sessionDate.day, _startTime.hour, _startTime.minute);
    final endDt = DateTime(_sessionDate.year, _sessionDate.month, _sessionDate.day, _endTime.hour, _endTime.minute);
    if (startDt.isAtSameMomentAs(endDt) || startDt.isAfter(endDt)) {
      showMessageDialog(context, "Start time must be before end time.");
      return false;
    }
    return true;
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
            if (_isCompleted)
              TextButton(
                onPressed: _hasChanges ? _saveSession : null,
                child: Text(
                  "Save",
                  style: TextStyle(color: _hasChanges ? Colors.blue : Colors.grey),
                ),
              )
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildMetadataCard(),
                  Expanded(
                    child: _exercises.isEmpty
                        ? const Center(
                            child: Text(
                              "No exercises in this session",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: _exercises.length + 1, // +1 for Add Exercise button
                            itemBuilder: (context, index) {
                              if (index == _exercises.length) {
                                // "Add Exercise" button at bottom
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: TextButton.icon(
                                      onPressed: _showAddExercisePicker,
                                      icon: const Icon(Icons.add_circle_outline, size: 20),
                                      label: const Text("Add Exercise"),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.blue,
                                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return _ExerciseCard(
                                exercise: _exercises[index],
                                onAddSet: (seId) => _addNewSet(index, seId),
                                onSetChanged: (setIndex, setData) => _updateSetInfo(index, setIndex, setData),
                                onDeleteSet: (setIndex, setId) => _deleteSet(index, setIndex, setId),
                                onDeleteExercise: () => _deleteExercise(index),
                              );
                            },
                          ),
                  ),
                ],
              ),
        bottomNavigationBar: _loading || _isCompleted
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildMetadataCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Date
          GestureDetector(
            onTap: _pickDate,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Date", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  "${_sessionDate.day.toString().padLeft(2, '0')}/${_sessionDate.month.toString().padLeft(2, '0')}/${_sessionDate.year}",
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                )
              ],
            ),
          ),
          Container(width: 1, height: 30, color: Colors.white12),
          // Start Time
          GestureDetector(
            onTap: () => _pickTime(true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Start", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  _startTime.format(context),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                )
              ],
            ),
          ),
          Container(width: 1, height: 30, color: Colors.white12),
          // End Time
          GestureDetector(
            onTap: () => _pickTime(false),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("End", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  _endTime.format(context),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= STATE MUTATION =================

  Future<void> _addNewSet(int exerciseIndex, int sessionExerciseId) async {
    // We add to DB to get an ID quickly, but we mark it as added so we delete on discard
    final setId = await WorkoutDatabaseService.instance.addSessionSet(sessionExerciseId);
    _addedSetIds.add(setId);

    final ex = _exercises[exerciseIndex];
    final sets = ex['sets'] as List<Map<String, dynamic>>;
    
    // Add default empty set to memory
    setState(() {
      sets.add({
        'set_id': setId,
        'session_exercise_id': sessionExerciseId,
        'set_order': sets.length + 1,
        'weight': 0.0,
        'value': 0,
        'is_completed': 0,
      });
      _markChanged();
    });
  }

  void _updateSetInfo(int exerciseIndex, int setIndex, Map<String, dynamic> newSetData) {
    _exercises[exerciseIndex]['sets'][setIndex] = newSetData;
    _markChanged();
  }

  Future<void> _deleteSet(int exerciseIndex, int setIndex, int setId) async {
    await WorkoutDatabaseService.instance.deleteSessionSet(setId);
    _addedSetIds.remove(setId);

    setState(() {
      final sets = _exercises[exerciseIndex]['sets'] as List<Map<String, dynamic>>;
      sets.removeAt(setIndex);
      // Re-number remaining sets
      for (int i = 0; i < sets.length; i++) {
        sets[i]['set_order'] = i + 1;
      }
      _markChanged();
    });
  }

  Future<void> _deleteExercise(int exerciseIndex) async {
    final ex = _exercises[exerciseIndex];
    final seId = ex['session_exercise_id'] as int;

    final confirm = await showConfirmDialog(
      context,
      title: "Remove Exercise?",
      content: "Remove \"${ex['exercise_name']}\" from this session? This won't delete the exercise itself.",
      trueText: "REMOVE",
      falseText: "CANCEL",
    );
    if (confirm != true) return;

    await WorkoutDatabaseService.instance.deleteSessionExercise(seId);
    _addedSessionExerciseIds.remove(seId);

    setState(() {
      _exercises.removeAt(exerciseIndex);
      _markChanged();
    });
  }

  // ================= ADD EXERCISE =================

  Future<void> _showAddExercisePicker() async {
    final existingIds = _exercises.map((e) => e['exercise_id'] as int).toSet();

    final result = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      AppRoutes.slideFromRight(
        SelectExercisePage(alreadySelectedIds: existingIds),
      ),
    );

    if (result == null || result.isEmpty) return;

    for (final exercise in result) {
      await _addExerciseToSession(exercise);
    }

    // Reload to get the default sets created by addSessionExercise
    await _loadExercises();
  }

  Future<void> _addExerciseToSession(Map<String, dynamic> exercise) async {
    final exerciseId = exercise['exercise_id'] as int;
    final seId = await WorkoutDatabaseService.instance.addSessionExercise(widget.sessionId, exerciseId);
    _addedSessionExerciseIds.add(seId);
    _markChanged();
  }

  // After all exercises added, reload to get the default sets
  // (called once after the picker returns, handled by _showAddExercisePicker ending with _loadExercises)

  // ================= SAVE DATA =================

  Future<void> _flushToDB() async {
    // Save metadata
    final startDt = DateTime(_sessionDate.year, _sessionDate.month, _sessionDate.day, _startTime.hour, _startTime.minute);
    final endDt = DateTime(_sessionDate.year, _sessionDate.month, _sessionDate.day, _endTime.hour, _endTime.minute);

    await WorkoutDatabaseService.instance.completeSession(
      widget.sessionId,
      startedAt: startDt.millisecondsSinceEpoch,
      completedAt: endDt.millisecondsSinceEpoch,
    );

    // Save in-memory sets to DB
    for (final ex in _exercises) {
      final sets = ex['sets'] as List<Map<String, dynamic>>;
      for (final s in sets) {
        await WorkoutDatabaseService.instance.updateSessionSet(
          setId: s['set_id'],
          weight: (s['weight'] as num).toDouble(),
          value: s['value'] as int,
          isCompleted: (s['is_completed'] as int) == 1,
        );
      }
    }
  }

  Future<void> _finishWorkout() async {
    if (!_validateTimes()) return;

    final confirm = await showConfirmDialog(
      context,
      title: "Finish Workout?",
      content: "Mark this session as completed?",
      trueText: "FINISH",
      falseText: "CONTINUE",
    );

    if (confirm != true || !mounted) return;

    await _flushToDB();

    if (!mounted) return;
    showMessageDialog(context, "Workout completed!", () {
      Navigator.pop(context, true);
    });
  }

  Future<void> _saveSession() async {
    if (!_hasChanges) return;
    if (!_validateTimes()) return;

    await _flushToDB();

    if (!mounted) return;
    showMessageDialog(context, "Changes saved!", () {
      Navigator.pop(context, true);
    });
  }

  // ================= BACK =================

  void _onBack(bool didPop, dynamic result) async {
    if (didPop) return;

    if (!_hasChanges) {
      if (!_isCompleted) {
        // Abandon totally untouched new session silently
        await WorkoutDatabaseService.instance.deleteSession(widget.sessionId);
      }
      if (mounted) Navigator.pop(context, true);
      return;
    }

    final String title = _isCompleted ? "Discard changes?" : "Abandon workout?";
    final String msg = _isCompleted 
        ? "You have unsaved changes. Discard them?"
        : "If you leave now, this session will be deleted.";
    final String confirmBtn = _isCompleted ? "DISCARD" : "ABANDON";

    final exit = await showConfirmDialog(
      context,
      title: title,
      content: msg,
      trueText: confirmBtn,
      falseText: "CONTINUE",
    );

    if (exit == true) {
      // Discard changes
      if (!_isCompleted) {
        await WorkoutDatabaseService.instance.deleteSession(widget.sessionId);
      } else {
        // Rollback any exercises and sets created during editing
        for (final id in _addedSessionExerciseIds) {
          await WorkoutDatabaseService.instance.deleteSessionExercise(id);
        }
        for (final id in _addedSetIds) {
          await WorkoutDatabaseService.instance.deleteSessionSet(id);
        }
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }
}

// ================================================================
//  EXERCISE CARD (internal widget)
// ================================================================

class _ExerciseCard extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final Function(int sessionExerciseId) onAddSet;
  final Function(int setIndex, Map<String, dynamic> updatedData) onSetChanged;
  final Function(int setIndex, int setId) onDeleteSet;
  final VoidCallback onDeleteExercise;

  const _ExerciseCard({
    required this.exercise,
    required this.onAddSet,
    required this.onSetChanged,
    required this.onDeleteSet,
    required this.onDeleteExercise,
  });

  @override
  Widget build(BuildContext context) {
    final sets = (exercise['sets'] as List<Map<String, dynamic>>?) ?? [];

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
              _ExerciseAvatar(imageName: exercise['exercise_image'] as String?),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise['exercise_name'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      "${exercise['exercise_equipment']} · ${exercise['exercise_type']}",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDeleteExercise,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                tooltip: "Remove from session",
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Table Header
          Row(
            children: [
              const SizedBox(width: 40, child: Text("SET", style: _headerStyle)),
              const Expanded(child: Center(child: Text("KG", style: _headerStyle))),
              Expanded(child: Center(child: Text(exercise['exercise_type'] == "seconds" ? "SECS" : "REPS", style: _headerStyle))),
              const SizedBox(width: 48, child: Center(child: Text("✓", style: _headerStyle))),
            ],
          ),

          const SizedBox(height: 8),

          // Set Rows
          ...sets.asMap().entries.map((entry) {
            return _SetRow(
              key: ValueKey('set_${entry.value['set_id']}'),
              setNumber: entry.key + 1,
              setData: entry.value,
              exerciseType: exercise['exercise_type'] as String? ?? 'reps',
              onChanged: (newData) => onSetChanged(entry.key, newData),
              onDelete: () => onDeleteSet(entry.key, entry.value['set_id'] as int),
            );
          }),

          // Add Set Button
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => onAddSet(exercise['session_exercise_id']),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Add Set"),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ),
        ],
      ),
    );
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
  final String exerciseType;
  final Function(Map<String, dynamic>) onChanged;
  final VoidCallback onDelete;

  const _SetRow({
    super.key,
    required this.setNumber,
    required this.setData,
    required this.exerciseType,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController _weightCtrl;
  late TextEditingController _valueCtrl;
  late bool _completed;

  @override
  void initState() {
    super.initState();
    _initVals();
  }

  @override
  void didUpdateWidget(covariant _SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reinitialize when it's a completely different set (e.g. reorder)
    if (oldWidget.setData['set_id'] != widget.setData['set_id']) {
      _weightCtrl.dispose();
      _valueCtrl.dispose();
      _initVals();
    }
  }

  void _initVals() {
    final w = widget.setData['weight'] as num? ?? 0;
    final r = widget.setData['value'] as int? ?? 0;
    _weightCtrl = TextEditingController(text: w > 0 ? w.toString() : '');
    _valueCtrl = TextEditingController(text: r > 0 ? r.toString() : '');
    _completed = (widget.setData['is_completed'] as int? ?? 0) == 1;
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  void _dispatchChange() {
    final weight = double.tryParse(_weightCtrl.text) ?? 0.0;
    final value = int.tryParse(_valueCtrl.text) ?? 0;

    final newData = {
      ...widget.setData,
      'weight': weight,
      'value': value,
      'is_completed': _completed ? 1 : 0,
    };
    widget.onChanged(newData);
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_set_${widget.setData['set_id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 20),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: Container(
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
                  style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
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
                  onChanged: (_) => _dispatchChange(),
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
                  controller: _valueCtrl,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: widget.exerciseType == "seconds" ? "0s" : "0",
                    hintStyle: const TextStyle(color: Colors.white24),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (_) => _dispatchChange(),
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: IconButton(
                onPressed: () {
                  setState(() => _completed = !_completed);
                  _dispatchChange();
                },
                icon: Icon(
                  _completed ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: _completed ? Colors.green : Colors.white38,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
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

// ================================================================
//  TOP-LEVEL FUNCTION FOR COMPUTE ISOLATE
// ================================================================

/// Deep-copies exercise + set data. Runs in a background isolate via compute().
List<Map<String, dynamic>> _deepCopyExercises(List<Map<String, dynamic>> rawData) {
  final List<Map<String, dynamic>> result = [];
  for (var ex in rawData) {
    final sets = (ex['sets'] as List).cast<Map<String, dynamic>>();
    result.add({
      ...ex,
      'sets': sets.map((s) => Map<String, dynamic>.from(s)).toList(),
    });
  }
  return result;
}
