import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Future<Database> initDB() async {
    final path = await getDatabasesPath();
    return openDatabase(
      join(path, 'absensi.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE absensi (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            photoPath TEXT,
            latitude REAL,
            longitude REAL,
            timestamp TEXT
          )
        ''');
      },
      version: 1,
    );
  }

  static Future<int> insertAbsensi(Map<String, dynamic> data) async {
    final db = await initDB();
    return await db.insert('absensi', data);
  }

  static Future<List<Map<String, dynamic>>> getAllAbsensi() async {
    final db = await initDB();
    return await db.query('absensi', orderBy: 'timestamp DESC');
  }
}
