import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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
      version: 1,
      onCreate: _createDB,
    );
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
  imagePath $textNullable,
  createdAt $textType
)
''');
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
      columns: ['id', 'title', 'content', 'imagePath', 'createdAt'],
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
    return db.update(
      'messages',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<int> deleteMessage(int id) async {
    final db = await instance.database;
    return await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
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
  }

  Future<List<Message>> searchMessages(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'messages',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => Message.fromMap(json)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
