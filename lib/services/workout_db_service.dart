import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fitnora/services/constants.dart';

class WorkoutDatabaseService {
  static Database? _db;
  static final WorkoutDatabaseService instance =
      WorkoutDatabaseService._constructor();

  WorkoutDatabaseService._constructor();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = join(
      await getDatabasesPath(),
      local_db_folder,
      'workout.db',
    );

    return openDatabase(
      dbPath,
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // exercise table
    await db.execute('''
      CREATE TABLE exercise (
        exercise_id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_image TEXT,
        exercise_name TEXT NOT NULL,
        exercise_equipment TEXT NOT NULL,
        exercise_type TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE routine (
        routine_id INTEGER PRIMARY KEY AUTOINCREMENT,
        routine_name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE routine_exercise (
        routine_exercise_id INTEGER PRIMARY KEY AUTOINCREMENT,
        routine_id INTEGER,
        exercise_id INTEGER,
        exercise_order INTEGER NOT NULL,

        FOREIGN KEY (routine_id) REFERENCES routine(routine_id) ON DELETE CASCADE,
        
        FOREIGN KEY (exercise_id) REFERENCES exercise(exercise_id) ON DELETE CASCADE,

        UNIQUE (routine_id, exercise_order)
      );
    ''');
  }

  Future<void> addExercise(
    String exerciseImage,
    String exerciseName,
    String exerciseEquipment,
    String exerciseType,
  ) async {
    final db = await database;
    await db.insert('exercise', {
      'exercise_image': exerciseImage,
      'exercise_name': exerciseName,
      'exercise_equipment': exerciseEquipment,
      'exercise_type': exerciseType,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getExercises() async {
    final db = await database;

    return await db.query(
      'exercise',
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'exercise_id DESC',
    );
  }

  Future<Map<String, dynamic>?> getExercise(String exerciseId) async {
    final db = await database;
    final result = await db.query(
      'exercise',
      where: "exercise_id = ?",
      whereArgs: [int.parse(exerciseId)],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<void> updateExercise(
    String exerciseId,
    String exerciseImage,
    String exerciseName,
    String exerciseEquipment,
    String exerciseType,
  ) async {
    final db = await database;

    await db.update(
      'exercise',
      {
        'exercise_image': exerciseImage,
        'exercise_name': exerciseName,
        'exercise_equipment': exerciseEquipment,
        'exercise_type': exerciseType,
      },
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
    );
  }

  // Routine
  Future<void> addRoutine(Map<String, dynamic> routineData) async {
    final db = await database;
    await db.transaction((txn) async {
      // Insert routine
      final routineId = await txn.insert('routine', {
        'routine_name': routineData['routine_name'],
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Insert routine exercises
      final exercises = routineData['exercises'] as List<Map<String, dynamic>>;

      for (final ex in exercises) {
        await txn.insert('routine_exercise', {
          'routine_id': routineId,
          'exercise_id': ex['exercise_id'],
          'exercise_order': ex['exercise_order'] + 1,
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> getRoutinesWithExercises() async {
    final db = await database;

    final routines = await db.query('routine', orderBy: 'created_at DESC');

    final List<Map<String, dynamic>> result = [];

    for (final routine in routines) {
      final exercises = await db.rawQuery(
        '''
      SELECT e.exercise_name
      FROM routine_exercise re
      JOIN exercise e ON e.exercise_id = re.exercise_id
      WHERE re.routine_id = ?
      ORDER BY re.exercise_order ASC
      LIMIT 4
    ''',
        [routine['routine_id']],
      );

      result.add({
        'routine_id': routine['routine_id'],
        'routine_name': routine['routine_name'],
        'exercises': exercises.map((e) => e['exercise_name']).toList(),
      });
    }

    return result;
  }

  Future<void> updateRoutine({
    required int routineId,
    required Map<String, dynamic> data,
  }) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.update(
        'routine',
        {'routine_name': data['routine_name']},
        where: 'routine_id = ?',
        whereArgs: [routineId],
      );

      await txn.delete(
        'routine_exercise',
        where: 'routine_id = ?',
        whereArgs: [routineId],
      );

      for (final ex in data['exercises']) {
        await txn.insert('routine_exercise', {
          'routine_id': routineId,
          'exercise_id': ex['exercise_id'],
          'exercise_order': ex['exercise_order'],
        });
      }
    });
  }

   Future<Map<String, dynamic>> getRoutineForEdit(int routineId) async {
    final db = await database;

    // 1. Get routine metadata
    final routineResult = await db.query(
      'routine',
      where: 'routine_id = ?',
      whereArgs: [routineId],
      limit: 1,
    );

    if (routineResult.isEmpty) {
      throw Exception('Routine not found: $routineId');
    }

    final routine = routineResult.first;

    // 2. Get exercises with order + exercise details
    final exercises = await db.rawQuery(
      '''
    SELECT
      re.exercise_id,
      re.exercise_order,
      e.exercise_name,
      e.exercise_equipment,
      e.exercise_type,
      e.exercise_image
    FROM routine_exercise re
    INNER JOIN exercise e
      ON e.exercise_id = re.exercise_id
    WHERE re.routine_id = ?
    ORDER BY re.exercise_order ASC
  ''',
      [routineId],
    );

    // 3. Return editor-ready payload
    return {
      'routine_id': routineId,
      'routine_name': routine['routine_name'],
      'exercises': exercises,
    };
  }
}
