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
      version: 5,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ==================== EXERCISE ====================
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

    // ==================== ROUTINE ====================
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

    // ==================== WORKOUT SESSION ====================
    await db.execute('''
      CREATE TABLE workout_session (
        session_id INTEGER PRIMARY KEY AUTOINCREMENT,
        routine_id INTEGER,
        started_at INTEGER NOT NULL,
        completed_at INTEGER,
        status TEXT NOT NULL DEFAULT 'in_progress',

        FOREIGN KEY (routine_id) REFERENCES routine(routine_id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE session_exercise (
        session_exercise_id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        exercise_order INTEGER NOT NULL,

        FOREIGN KEY (session_id) REFERENCES workout_session(session_id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercise(exercise_id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE session_set (
        set_id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_exercise_id INTEGER NOT NULL,
        set_order INTEGER NOT NULL,
        weight REAL NOT NULL DEFAULT 0,
        reps INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0,

        FOREIGN KEY (session_exercise_id) REFERENCES session_exercise(session_exercise_id) ON DELETE CASCADE
      );
    ''');

    // ==================== BODY MEASUREMENT ====================
    await db.execute('''
      CREATE TABLE body_measurement (
        measurement_id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL,
        height REAL,
        body_fat REAL,
        chest REAL,
        waist REAL,
        hips REAL,
        measured_at INTEGER NOT NULL
      );
    ''');

    // ==================== FOOD TRACKING ====================
    await db.execute('''
      CREATE TABLE food_item (
        food_id INTEGER PRIMARY KEY AUTOINCREMENT,
        food_name TEXT NOT NULL,
        calories REAL NOT NULL DEFAULT 0,
        protein REAL NOT NULL DEFAULT 0,
        carbs REAL NOT NULL DEFAULT 0,
        fat REAL NOT NULL DEFAULT 0,
        serving_size TEXT NOT NULL DEFAULT '1 serving',
        created_at INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE meal_log (
        meal_log_id INTEGER PRIMARY KEY AUTOINCREMENT,
        food_id INTEGER NOT NULL,
        meal_type TEXT NOT NULL,
        servings REAL NOT NULL DEFAULT 1,
        logged_at INTEGER NOT NULL,

        FOREIGN KEY (food_id) REFERENCES food_item(food_id) ON DELETE CASCADE
      );
    ''');
  }

  // ==================== MIGRATION ====================
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS workout_session (
          session_id INTEGER PRIMARY KEY AUTOINCREMENT,
          routine_id INTEGER,
          started_at INTEGER NOT NULL,
          completed_at INTEGER,
          status TEXT NOT NULL DEFAULT 'in_progress',
          FOREIGN KEY (routine_id) REFERENCES routine(routine_id) ON DELETE SET NULL
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS session_exercise (
          session_exercise_id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id INTEGER NOT NULL,
          exercise_id INTEGER NOT NULL,
          exercise_order INTEGER NOT NULL,
          FOREIGN KEY (session_id) REFERENCES workout_session(session_id) ON DELETE CASCADE,
          FOREIGN KEY (exercise_id) REFERENCES exercise(exercise_id) ON DELETE CASCADE
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS session_set (
          set_id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_exercise_id INTEGER NOT NULL,
          set_order INTEGER NOT NULL,
          weight REAL NOT NULL DEFAULT 0,
          reps INTEGER NOT NULL DEFAULT 0,
          is_completed INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (session_exercise_id) REFERENCES session_exercise(session_exercise_id) ON DELETE CASCADE
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS body_measurement (
          measurement_id INTEGER PRIMARY KEY AUTOINCREMENT,
          weight REAL,
          height REAL,
          body_fat REAL,
          chest REAL,
          waist REAL,
          hips REAL,
          measured_at INTEGER NOT NULL
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS food_item (
          food_id INTEGER PRIMARY KEY AUTOINCREMENT,
          food_name TEXT NOT NULL,
          calories REAL NOT NULL DEFAULT 0,
          protein REAL NOT NULL DEFAULT 0,
          carbs REAL NOT NULL DEFAULT 0,
          fat REAL NOT NULL DEFAULT 0,
          serving_size TEXT NOT NULL DEFAULT '1 serving',
          created_at INTEGER NOT NULL
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS meal_log (
          meal_log_id INTEGER PRIMARY KEY AUTOINCREMENT,
          food_id INTEGER NOT NULL,
          meal_type TEXT NOT NULL,
          servings REAL NOT NULL DEFAULT 1,
          logged_at INTEGER NOT NULL,
          FOREIGN KEY (food_id) REFERENCES food_item(food_id) ON DELETE CASCADE
        );
      ''');
    }
  }

  // ================================================================
  //  EXERCISE METHODS (existing)
  // ================================================================

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

  /// Soft-delete an exercise (hide from lists but preserve session history).
  Future<void> softDeleteExercise(int exerciseId) async {
    final db = await database;
    await db.update(
      'exercise',
      {'is_deleted': 1},
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
    );
  }

  /// Hard-delete an exercise permanently.
  Future<void> hardDeleteExercise(int exerciseId) async {
    final db = await database;
    await db.delete(
      'exercise',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
    );
  }

  /// Check if an exercise has any session data.
  Future<bool> hasExerciseSessions(int exerciseId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM session_exercise WHERE exercise_id = ?',
      [exerciseId],
    );
    return (result.first['cnt'] as int) > 0;
  }

  /// Delete all session data (session_exercise + cascaded session_set) for an exercise.
  Future<void> deleteSessionsByExerciseId(int exerciseId) async {
    final db = await database;
    // session_set has ON DELETE CASCADE from session_exercise, so just delete session_exercise rows
    await db.delete(
      'session_exercise',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
    );
  }

  // ================================================================
  //  ROUTINE METHODS (existing)
  // ================================================================

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

  Future<void> deleteRoutine(int routineId) async {
    final db = await database;
    await db.delete(
      'routine',
      where: 'routine_id = ?',
      whereArgs: [routineId],
    );
  }

  // ================================================================
  //  WORKOUT SESSION METHODS
  // ================================================================

  /// Start a new workout session from a routine.
  /// Copies routine_exercises into session_exercises and creates one
  /// default empty set per exercise.
  Future<int> startSession(int routineId) async {
    final db = await database;

    return await db.transaction((txn) async {
      // 1. Create the session record
      final sessionId = await txn.insert('workout_session', {
        'routine_id': routineId,
        'started_at': DateTime.now().millisecondsSinceEpoch,
        'status': 'in_progress',
      });

      // 2. Copy exercises from the routine
      final routineExercises = await txn.rawQuery(
        '''
        SELECT re.exercise_id, re.exercise_order
        FROM routine_exercise re
        WHERE re.routine_id = ?
        ORDER BY re.exercise_order ASC
        ''',
        [routineId],
      );

      for (final re in routineExercises) {
        final seId = await txn.insert('session_exercise', {
          'session_id': sessionId,
          'exercise_id': re['exercise_id'],
          'exercise_order': re['exercise_order'],
        });

        // Create one default empty set per exercise
        await txn.insert('session_set', {
          'session_exercise_id': seId,
          'set_order': 1,
          'weight': 0,
          'reps': 0,
          'is_completed': 0,
        });
      }

      return sessionId;
    });
  }

  /// Get all session exercises with their sets for a given session.
  Future<List<Map<String, dynamic>>> getSessionExercises(int sessionId) async {
    final db = await database;

    final exercises = await db.rawQuery(
      '''
      SELECT
        se.session_exercise_id,
        se.exercise_id,
        se.exercise_order,
        e.exercise_name,
        e.exercise_equipment,
        e.exercise_type,
        e.exercise_image
      FROM session_exercise se
      JOIN exercise e ON e.exercise_id = se.exercise_id
      WHERE se.session_id = ?
      ORDER BY se.exercise_order ASC
      ''',
      [sessionId],
    );

    final List<Map<String, dynamic>> result = [];

    for (final ex in exercises) {
      final sets = await db.query(
        'session_set',
        where: 'session_exercise_id = ?',
        whereArgs: [ex['session_exercise_id']],
        orderBy: 'set_order ASC',
      );

      result.add({
        ...ex,
        'sets': sets,
      });
    }

    return result;
  }

  /// Add a new set to a session exercise.
  Future<int> addSessionSet(int sessionExerciseId) async {
    final db = await database;

    // Get the next set order
    final maxOrder = await db.rawQuery(
      'SELECT COALESCE(MAX(set_order), 0) as max_order FROM session_set WHERE session_exercise_id = ?',
      [sessionExerciseId],
    );
    final nextOrder = (maxOrder.first['max_order'] as int) + 1;

    return await db.insert('session_set', {
      'session_exercise_id': sessionExerciseId,
      'set_order': nextOrder,
      'weight': 0,
      'reps': 0,
      'is_completed': 0,
    });
  }

  /// Update a specific set (weight, reps, completion).
  Future<void> updateSessionSet({
    required int setId,
    required double weight,
    required int reps,
    required bool isCompleted,
  }) async {
    final db = await database;
    await db.update(
      'session_set',
      {
        'weight': weight,
        'reps': reps,
        'is_completed': isCompleted ? 1 : 0,
      },
      where: 'set_id = ?',
      whereArgs: [setId],
    );
  }

  /// Delete a specific set.
  Future<void> deleteSessionSet(int setId) async {
    final db = await database;
    await db.delete(
      'session_set',
      where: 'set_id = ?',
      whereArgs: [setId],
    );
  }

  /// Complete a workout session.
  Future<void> completeSession(int sessionId) async {
    final db = await database;
    await db.update(
      'workout_session',
      {
        'completed_at': DateTime.now().millisecondsSinceEpoch,
        'status': 'completed',
      },
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Abandon a workout session.
  Future<void> abandonSession(int sessionId) async {
    final db = await database;
    await db.update(
      'workout_session',
      {
        'completed_at': DateTime.now().millisecondsSinceEpoch,
        'status': 'abandoned',
      },
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Get session history (completed + abandoned).
  Future<List<Map<String, dynamic>>> getSessionHistory() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        ws.*, 
        r.routine_name,
        COALESCE(SUM(ss.weight * ss.reps), 0) AS total_volume,
        SUM(CASE WHEN ss.is_completed = 1 THEN 1 ELSE 0 END) AS total_sets
      FROM workout_session ws
      LEFT JOIN routine r ON r.routine_id = ws.routine_id
      LEFT JOIN session_exercise se ON se.session_id = ws.session_id
      LEFT JOIN session_set ss ON ss.session_exercise_id = se.session_exercise_id
      WHERE ws.status != 'in_progress'
      GROUP BY ws.session_id
      ORDER BY ws.started_at DESC
    ''');
  }

  /// Delete a workout session and cascade delete its exercises and sets.
  Future<void> deleteSession(int sessionId) async {
    final db = await database;
    await db.delete(
      'workout_session',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  // ================================================================
  //  BODY MEASUREMENT METHODS
  // ================================================================

  Future<void> addMeasurement(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('body_measurement', {
      'weight': data['weight'],
      'height': data['height'],
      'body_fat': data['body_fat'],
      'chest': data['chest'],
      'waist': data['waist'],
      'hips': data['hips'],
      'measured_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getMeasurements() async {
    final db = await database;
    return await db.query(
      'body_measurement',
      orderBy: 'measured_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getLatestMeasurement() async {
    final db = await database;
    final result = await db.query(
      'body_measurement',
      orderBy: 'measured_at DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> deleteMeasurement(int measurementId) async {
    final db = await database;
    await db.delete(
      'body_measurement',
      where: 'measurement_id = ?',
      whereArgs: [measurementId],
    );
  }

  Future<Map<String, dynamic>?> getMeasurement(int measurementId) async {
    final db = await database;
    final result = await db.query(
      'body_measurement',
      where: 'measurement_id = ?',
      whereArgs: [measurementId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> updateMeasurement(Map<String, dynamic> data) async {
    final db = await database;
    await db.update(
      'body_measurement',
      {
        'weight': data['weight'],
        'height': data['height'],
        'body_fat': data['body_fat'],
        'chest': data['chest'],
        'waist': data['waist'],
        'hips': data['hips'],
      },
      where: 'measurement_id = ?',
      whereArgs: [data['measurement_id']],
    );
  }

  // ================================================================
  //  FOOD TRACKING METHODS
  // ================================================================

  Future<void> addFoodItem(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('food_item', {
      'food_name': data['food_name'],
      'calories': data['calories'],
      'protein': data['protein'],
      'carbs': data['carbs'],
      'fat': data['fat'],
      'serving_size': data['serving_size'],
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> updateFoodItem(Map<String, dynamic> data) async {
    final db = await database;
    await db.update(
      'food_item',
      {
        'food_name': data['food_name'],
        'calories': data['calories'],
        'protein': data['protein'],
        'carbs': data['carbs'],
        'fat': data['fat'],
        'serving_size': data['serving_size'],
      },
      where: 'food_id = ?',
      whereArgs: [data['food_id']],
    );
  }

  Future<void> deleteFoodItem(int foodId) async {
    final db = await database;
    await db.delete(
      'food_item',
      where: 'food_id = ?',
      whereArgs: [foodId],
    );
  }

  Future<List<Map<String, dynamic>>> getFoodItems() async {
    final db = await database;
    return await db.query(
      'food_item',
      orderBy: 'food_name ASC',
    );
  }

  Future<List<Map<String, dynamic>>> searchFoodItems(String query) async {
    final db = await database;
    return await db.query(
      'food_item',
      where: 'food_name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'food_name ASC',
    );
  }

  Future<void> logMeal(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('meal_log', {
      'food_id': data['food_id'],
      'meal_type': data['meal_type'],
      'servings': data['servings'],
      'logged_at': data['logged_at'] ?? DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Get all meal logs for a specific day (by date string YYYY-MM-DD).
  Future<List<Map<String, dynamic>>> getMealsByDate(DateTime date) async {
    final db = await database;

    final startOfDay = DateTime(date.year, date.month, date.day)
        .millisecondsSinceEpoch;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999)
        .millisecondsSinceEpoch;

    return await db.rawQuery('''
      SELECT ml.*, fi.food_name, fi.calories, fi.protein, fi.carbs, fi.fat, fi.serving_size
      FROM meal_log ml
      JOIN food_item fi ON fi.food_id = ml.food_id
      WHERE ml.logged_at BETWEEN ? AND ?
      ORDER BY ml.logged_at DESC
    ''', [startOfDay, endOfDay]);
  }

  Future<void> deleteMealLog(int mealLogId) async {
    final db = await database;
    await db.delete(
      'meal_log',
      where: 'meal_log_id = ?',
      whereArgs: [mealLogId],
    );
  }

  /// Get daily nutrition summary for a date.
  Future<Map<String, double>> getDailyNutritionSummary(DateTime date) async {
    final db = await database;

    final startOfDay = DateTime(date.year, date.month, date.day)
        .millisecondsSinceEpoch;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999)
        .millisecondsSinceEpoch;

    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(fi.calories * ml.servings), 0) as total_calories,
        COALESCE(SUM(fi.protein * ml.servings), 0) as total_protein,
        COALESCE(SUM(fi.carbs * ml.servings), 0) as total_carbs,
        COALESCE(SUM(fi.fat * ml.servings), 0) as total_fat
      FROM meal_log ml
      JOIN food_item fi ON fi.food_id = ml.food_id
      WHERE ml.logged_at BETWEEN ? AND ?
    ''', [startOfDay, endOfDay]);

    if (result.isNotEmpty) {
      return {
        'calories': (result.first['total_calories'] as num).toDouble(),
        'protein': (result.first['total_protein'] as num).toDouble(),
        'carbs': (result.first['total_carbs'] as num).toDouble(),
        'fat': (result.first['total_fat'] as num).toDouble(),
      };
    }

    return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
  }

  /// Get daily nutrition totals grouped by day for charting.
  Future<List<Map<String, dynamic>>> getNutritionHistory() async {
    final db = await database;
    // Group meals by day, summing up macros (servings = grams/100 now)
    return await db.rawQuery('''
      SELECT
        (ml.logged_at / 86400000) as day_key,
        MIN(ml.logged_at) as logged_at,
        COALESCE(SUM(fi.calories * ml.servings), 0) as total_calories,
        COALESCE(SUM(fi.protein * ml.servings), 0) as total_protein,
        COALESCE(SUM(fi.carbs * ml.servings), 0) as total_carbs,
        COALESCE(SUM(fi.fat * ml.servings), 0) as total_fat
      FROM meal_log ml
      JOIN food_item fi ON fi.food_id = ml.food_id
      GROUP BY day_key
      ORDER BY day_key ASC
    ''');
  }
}
