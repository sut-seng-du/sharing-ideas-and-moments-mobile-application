import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/message.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('messages.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      if (!(await _columnExists(db, 'messages', 'category'))) {
        await db.execute('ALTER TABLE messages ADD COLUMN category TEXT');
      }
    }
    if (oldVersion < 3) {
      // 1. Create categories table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');

      // Add default categories if table is empty
      final categoryCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM categories'));
      if (categoryCount == 0) {
        final defaultCategories = ["Idea", "Moment", "Note", "Important"];
        for (final category in defaultCategories) {
          await db.insert('categories', {'name': category});
        }
      }

      // 2. Migrate imagePath to imagePaths
      if (!(await _columnExists(db, 'messages', 'imagePaths'))) {
        await db.execute('ALTER TABLE messages ADD COLUMN imagePaths TEXT');
        
        // Check if old column exists before migrating
        if (await _columnExists(db, 'messages', 'imagePath')) {
          final messages = await db.query('messages');
          for (final msg in messages) {
            final id = msg['id'];
            final oldPath = msg['imagePath'] as String?;
            if (oldPath != null) {
              final newPaths = jsonEncode([oldPath]);
              await db.update('messages', {'imagePaths': newPaths}, where: 'id = ?', whereArgs: [id]);
            }
          }
        }
      }
    }
  }

  Future<bool> _columnExists(Database db, String table, String column) async {
    final List<Map<String, dynamic>> columns = await db.rawQuery('PRAGMA table_info($table)');
    return columns.any((element) => element['name'] == column);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';

    await db.execute('''
CREATE TABLE messages (
  id $idType,
  title $textType,
  content $textType,
  imagePaths $textNullable,
  category $textNullable,
  createdAt $textType
)
''');

    await db.execute('''
CREATE TABLE categories (
  id $idType,
  name $textType UNIQUE
)
''');

    // Add default categories
    final defaultCategories = ["Idea", "Moment", "Note", "Important"];
    for (final category in defaultCategories) {
      await db.insert('categories', {'name': category});
    }
  }

  Future<int> insertMessage(Message message) async {
    final db = await instance.database;
    return await db.insert('messages', message.toMap());
  }

  Future<List<Message>> getAllMessages() async {
    final db = await instance.database;
    final result = await db.query('messages', orderBy: 'createdAt DESC');
    return result.map((json) => Message.fromMap(json)).toList();
  }

  Future<Message?> getMessage(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'messages',
      columns: ['id', 'title', 'content', 'imagePaths', 'category', 'createdAt'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Message.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> updateMessage(Message message) async {
    final db = await instance.database;
    final result = await db.update(
      'messages',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
    await _cleanupUnusedCategories();
    return result;
  }

  Future<int> deleteMessage(int id) async {
    final db = await instance.database;
    final result = await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _cleanupUnusedCategories();
    return result;
  }

  Future<void> deleteMultipleMessages(List<int> ids) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      for (final id in ids) {
        await txn.delete(
          'messages',
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
    await _cleanupUnusedCategories();
  }

  Future<List<Message>> searchMessages(String query, {String? category}) async {
    final db = await instance.database;
    String whereClause = '(title LIKE ? OR content LIKE ?)';
    List<dynamic> whereArgs = ['%$query%', '%$query%'];

    if (category != null) {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }

    final result = await db.query(
      'messages',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => Message.fromMap(json)).toList();
  }

  Future<List<String>> getCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((json) => json['name'] as String).toList();
  }

  Future<int> insertCategory(String name) async {
    final db = await instance.database;
    return await db.insert('categories', {'name': name}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _cleanupUnusedCategories() async {
    final db = await instance.database;
    final primaryCategories = ["Idea", "Moment", "Note", "Important"];
    
    // De-duplicate: Delete from categories table if NOT primary AND NOT used in any message
    await db.execute('''
      DELETE FROM categories 
      WHERE name NOT IN (${primaryCategories.map((e) => "'$e'").join(',')})
      AND name NOT IN (SELECT DISTINCT category FROM messages WHERE category IS NOT NULL)
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
