import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/activity.dart';
import '../models/time_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Database version - increment this when schema changes
  static const int _databaseVersion = 2;
  static const String _databaseName = 'trackmywork.db';

  // Table names
  static const String tableActivities = 'activities';
  static const String tableTimeEntries = 'time_entries';

  // Common column names
  static const String columnId = 'id';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  // Activities table columns
  static const String columnName = 'name';
  static const String columnColor = 'color';
  static const String columnIcon = 'icon';
  static const String columnIsArchived = 'is_archived';
  static const String columnIsDefault = 'isDefault';

  // Time entries table columns
  static const String columnActivityId = 'activity_id';
  static const String columnStartTime = 'start_time';
  static const String columnEndTime = 'end_time';
  static const String columnNotes = 'notes';
  static const String columnIsBillable = 'is_billable';

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Public method to initialize the database
  Future<Database> initDatabase() async {
    return await _initDatabase();
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Create activities table
    await db.execute('''
      CREATE TABLE $tableActivities (
        $columnId TEXT PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnColor INTEGER NOT NULL,
        $columnIcon TEXT NOT NULL,
        $columnIsArchived INTEGER NOT NULL DEFAULT 0,
        $columnIsDefault INTEGER NOT NULL DEFAULT 0,
        $columnCreatedAt TEXT NOT NULL,
        $columnUpdatedAt TEXT NOT NULL
      )
    ''');

    // Create time entries table
    await db.execute('''
      CREATE TABLE $tableTimeEntries (
        $columnId TEXT PRIMARY KEY,
        $columnActivityId TEXT NOT NULL,
        $columnStartTime TEXT NOT NULL,
        $columnEndTime TEXT,
        $columnNotes TEXT,
        $columnIsBillable INTEGER NOT NULL DEFAULT 0,
        $columnCreatedAt TEXT NOT NULL,
        $columnUpdatedAt TEXT NOT NULL,
        FOREIGN KEY ($columnActivityId) REFERENCES $tableActivities ($columnId) ON DELETE CASCADE
      )
    ''');
    
    // Create index for faster queries
    await db.execute(
      'CREATE INDEX idx_time_entries_activity_id ON $tableTimeEntries ($columnActivityId)'
    );
    
    await db.execute(
      'CREATE INDEX idx_time_entries_start_time ON $tableTimeEntries ($columnStartTime)'
    );
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add isDefault column to activities table if upgrading from version 1
      await db.execute('ALTER TABLE $tableActivities ADD COLUMN $columnIsDefault INTEGER NOT NULL DEFAULT 0');
    }
  }

  // ACTIVITIES CRUD OPERATIONS

  // Insert a new activity
  Future<void> insertActivity(Activity activity) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final activityMap = activity.toJson();
    activityMap[columnCreatedAt] = now;
    activityMap[columnUpdatedAt] = now;
    
    await db.insert(
      tableActivities,
      activityMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insert multiple activities
  Future<void> insertActivities(List<Activity> activities) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    
    for (var activity in activities) {
      final activityMap = activity.toJson();
      activityMap[columnCreatedAt] = now;
      activityMap[columnUpdatedAt] = now;
      
      batch.insert(
        tableActivities,
        activityMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  // Get all activities
  Future<List<Activity>> getAllActivities() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableActivities,
      orderBy: '$columnName ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Activity.fromJson(maps[i]);
    });
  }

  // Get activities
  Future<List<Activity>> getActivities({bool includeArchived = false}) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableActivities,
      where: includeArchived ? null : '$columnIsArchived = ?',
      whereArgs: includeArchived ? null : [0],
      orderBy: '$columnName ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Activity.fromJson(maps[i]);
    });
  }

  // Get activity by ID
  Future<Activity?> getActivity(String id) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableActivities,
      where: '$columnId = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return Activity.fromJson(maps.first);
  }

  // Update an activity
  Future<void> updateActivity(Activity activity) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final activityMap = activity.toJson();
    activityMap[columnUpdatedAt] = now;
    
    await db.update(
      tableActivities,
      activityMap,
      where: '$columnId = ?',
      whereArgs: [activity.id],
    );
  }

  // Delete an activity
  Future<void> deleteActivity(String id) async {
    final db = await database;
    
    await db.delete(
      tableActivities,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // TIME ENTRIES CRUD OPERATIONS

  // Insert a new time entry
  Future<void> insertTimeEntry(TimeEntry timeEntry) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final timeEntryMap = timeEntry.toJson();
    timeEntryMap[columnCreatedAt] = now;
    timeEntryMap[columnUpdatedAt] = now;
    
    await db.insert(
      tableTimeEntries,
      timeEntryMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insert multiple time entries
  Future<void> insertTimeEntries(List<TimeEntry> timeEntries) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    
    for (var entry in timeEntries) {
      final timeEntryMap = entry.toJson();
      timeEntryMap[columnCreatedAt] = now;
      timeEntryMap[columnUpdatedAt] = now;
      
      batch.insert(
        tableTimeEntries,
        timeEntryMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  // Get all time entries
  Future<List<TimeEntry>> getAllTimeEntries() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableTimeEntries,
      orderBy: '$columnStartTime DESC',
    );
    
    return List.generate(maps.length, (i) {
      return TimeEntry.fromJson(maps[i]);
    });
  }

  // Get time entries for a specific day
  Future<List<TimeEntry>> getTimeEntriesForDay(DateTime date) async {
    final db = await database;
    
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableTimeEntries,
      where: '($columnStartTime BETWEEN ? AND ?) OR ($columnEndTime BETWEEN ? AND ?) OR ($columnStartTime <= ? AND $columnEndTime >= ?)',
      whereArgs: [
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: '$columnStartTime ASC',
    );
    
    return List.generate(maps.length, (i) {
      return TimeEntry.fromJson(maps[i]);
    });
  }

  // Get time entries for a date range
  Future<List<TimeEntry>> getTimeEntriesForDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    
    final startOfRange = DateTime(startDate.year, startDate.month, startDate.day);
    final endOfRange = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableTimeEntries,
      where: '($columnStartTime BETWEEN ? AND ?) OR ($columnEndTime BETWEEN ? AND ?) OR ($columnStartTime <= ? AND $columnEndTime >= ?)',
      whereArgs: [
        startOfRange.toIso8601String(),
        endOfRange.toIso8601String(),
        startOfRange.toIso8601String(),
        endOfRange.toIso8601String(),
        startOfRange.toIso8601String(),
        endOfRange.toIso8601String(),
      ],
      orderBy: '$columnStartTime ASC',
    );
    
    return List.generate(maps.length, (i) {
      return TimeEntry.fromJson(maps[i]);
    });
  }

  // Get time entries for a specific activity
  Future<List<TimeEntry>> getTimeEntriesForActivity(String activityId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableTimeEntries,
      where: '$columnActivityId = ?',
      whereArgs: [activityId],
      orderBy: '$columnStartTime DESC',
    );
    
    return List.generate(maps.length, (i) {
      return TimeEntry.fromJson(maps[i]);
    });
  }

  // Get a specific time entry by ID
  Future<TimeEntry?> getTimeEntry(String id) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableTimeEntries,
      where: '$columnId = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return TimeEntry.fromJson(maps.first);
  }

  // Update a time entry
  Future<void> updateTimeEntry(TimeEntry timeEntry) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final timeEntryMap = timeEntry.toJson();
    timeEntryMap[columnUpdatedAt] = now;
    
    await db.update(
      tableTimeEntries,
      timeEntryMap,
      where: '$columnId = ?',
      whereArgs: [timeEntry.id],
    );
  }

  // Delete a time entry
  Future<void> deleteTimeEntry(String id) async {
    final db = await database;
    
    await db.delete(
      tableTimeEntries,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Delete all time entries
  Future<void> deleteAllTimeEntries() async {
    final db = await database;
    await db.delete(tableTimeEntries);
  }

  // Get the latest time entry
  Future<TimeEntry?> getLatestTimeEntry() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableTimeEntries,
      orderBy: '$columnStartTime DESC',
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return TimeEntry.fromJson(maps.first);
  }

  // Get ongoing time entry (where endTime is null)
  Future<TimeEntry?> getOngoingTimeEntry() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableTimeEntries,
      where: '$columnEndTime IS NULL',
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return TimeEntry.fromJson(maps.first);
  }

  // Close the database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
