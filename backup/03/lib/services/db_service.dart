import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  static Database? _db;

  static Future<Database> getDB() async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'absensi.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          nip TEXT,
          email TEXT UNIQUE,
          password TEXT,
          photo TEXT
        )
      ''');
        await db.execute('''
        CREATE TABLE attendance(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER,
          date TEXT,
          time TEXT,
          location TEXT,
          photo TEXT
        )
      ''');
      },
    );
    return _db!;
  }

  // User CRUD
  static Future<int> registerUser(
    String name,
    String nip,
    String email,
    String password,
  ) async {
    final db = await getDB();
    return await db.insert('users', {
      'name': name,
      'nip': nip,
      'email': email,
      'password': password,
      'photo': '',
    });
  }

  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    final db = await getDB();
    final res = await db.query(
      'users',
      where: 'email=? AND password=?',
      whereArgs: [email, password],
    );
    return res.isNotEmpty ? res.first : null;
  }

  static Future<void> updateProfile(
    int userId,
    String name,
    String nip,
    String photo,
  ) async {
    final db = await getDB();
    await db.update(
      'users',
      {'name': name, 'nip': nip, 'photo': photo},
      where: 'id=?',
      whereArgs: [userId],
    );
  }

  // Attendance
  static Future<void> saveAttendance(
    int userId,
    String date,
    String time,
    String location,
    String photoPath,
  ) async {
    final db = await getDB();
    await db.insert('attendance', {
      'userId': userId,
      'date': date,
      'time': time,
      'location': location,
      'photo': photoPath,
    });
  }

  static Future<List<Map<String, dynamic>>> getAttendance(int userId) async {
    final db = await getDB();
    return await db.query('attendance', where: 'userId=?', whereArgs: [userId]);
  }
}
