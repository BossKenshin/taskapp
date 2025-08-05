import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  // Singleton instance
  static final DatabaseService _instance = DatabaseService._constructor();
  factory DatabaseService() => _instance;
  DatabaseService._constructor();

  static Database? _db;

  // Table and column names
  static const _taskTable = 'tasks';
  static const _taskId = 'id';
  static const _taskName = 'name';
  static const _taskDescription = 'description';
  static const _taskStatus = 'status';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbDirPath = await getDatabasesPath();
    final dbPath = join(dbDirPath, 'task_database.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_taskTable (
            $_taskId INTEGER PRIMARY KEY AUTOINCREMENT,
            $_taskName TEXT NOT NULL,
            $_taskDescription TEXT NOT NULL,
            $_taskStatus INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> closeDatabase() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  Future<void> addTask(String name, String description, int status) async {
    final db = await database;
    await db.insert(
      _taskTable,
      {
        _taskName: name,
        _taskDescription: description,
        _taskStatus: status, // 0 = incomplete
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTask(int id, String name, String description, int status) async {
    final db = await database;
    await db.update(
      _taskTable,
      {
        _taskName: name,
        _taskDescription: description,
        _taskStatus: status,
      },
      where: '$_taskId = ?',
      whereArgs: [id],
    );
  }


  Future<List<Map<String, dynamic>>> getTasks() async {
    final db = await database;
    return await db.query(_taskTable);
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete(
      _taskTable,
      where: '$_taskId = ?',
      whereArgs: [id],
    );
  }

  // Optional: Mark task as complete/incomplete
  Future<void> updateTaskStatus(int id, int status) async {
    final db = await database;
    await db.update(
      _taskTable,
      {_taskStatus: status},
      where: '$_taskId = ?',
      whereArgs: [id],
    );
  }
}
