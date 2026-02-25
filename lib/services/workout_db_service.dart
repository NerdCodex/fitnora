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
      version: 2,
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
        exercise_id INTEGERm
        exercise_order INTEGER NOT NULL,

        FOREIGN KEY (routine_id) REFERENCES routine(routine_id) ON DELETE CASCADE,
        
        FOREIGN KEY (exercise_id) REFERENCES routine(exercise_id) ON DELETE CASCADE,

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
    });
  }

  Future<List<Map<String, dynamic>>> getExercises() async {
    final db = await database;
    return db.query('exercise', orderBy: 'exercise_id DESC');
  }
}
