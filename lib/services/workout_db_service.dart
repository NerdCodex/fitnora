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
      version: 3,
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
        is_deleted INTEGER DEFAULT 0,
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
      whereArgs: [exerciseId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }
}
