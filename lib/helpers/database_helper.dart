import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../providers/story_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDB('stories.db');
      return _database!;
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(
        path,
        version: 4,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
        onOpen: (db) async {
          // Verify the database is working
          await db.rawQuery('SELECT 1');
        },
      );
    } catch (e) {
      throw Exception('Failed to initialize database at path: $e');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE stories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          childName TEXT NOT NULL,
          childAge INTEGER NOT NULL,
          language TEXT NOT NULL DEFAULT 'en',
          gender TEXT NOT NULL DEFAULT 'boy'
        )
      ''');
    } catch (e) {
      throw Exception('Failed to create database tables: $e');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for child information
      await db.execute('''
        ALTER TABLE stories ADD COLUMN childName TEXT NOT NULL DEFAULT 'Unknown';
      ''');
      await db.execute('''
        ALTER TABLE stories ADD COLUMN childAge INTEGER NOT NULL DEFAULT 0;
      ''');
    }
    if (oldVersion < 3) {
      // Add language column
      await db.execute('''
        ALTER TABLE stories ADD COLUMN language TEXT NOT NULL DEFAULT 'en';
      ''');
    }
    if (oldVersion < 4) {
      // Add gender column
      await db.execute('''
        ALTER TABLE stories ADD COLUMN gender TEXT NOT NULL DEFAULT 'boy';
      ''');
    }
  }

  Future<int> insertStory(Story story) async {
    try {
      final db = await database;
      return await db.insert('stories', {
        'title': story.title,
        'content': story.content,
        'createdAt': story.createdAt.toIso8601String(),
        'childName': story.childName,
        'childAge': story.childAge,
        'language': story.language,
        'gender': story.gender,
      });
    } catch (e) {
      throw Exception('Failed to insert story: $e');
    }
  }

  Future<List<Story>> getAllStories() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'stories',
        orderBy: 'createdAt DESC',
      );

      return maps
          .map((map) => Story(
                id: map['id'],
                title: map['title'],
                content: map['content'],
                createdAt: DateTime.parse(map['createdAt']),
                childName: map['childName'],
                childAge: map['childAge'],
                language: map['language'] ?? 'en',
                gender: map['gender'] ?? 'boy',
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get stories: $e');
    }
  }

  Future<void> deleteStory(int id) async {
    try {
      final db = await database;
      await db.delete(
        'stories',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete story: $e');
    }
  }
}
